//
//  UMPDataSource.m
//  UCD Map v2
//
//  Created by psytronx on 8/2/15.
//  Copyright (c) 2015 Logical Dimension. All rights reserved.
//

#import <AFNetworking.h>
#import "UMPDataSource.h"
#import "UMPCampus.h"
#import "UMPLocation.h"

@interface UMPDataSource () {
    NSMutableArray *_locations;
    UMPCampus *_campus;
}

@property (nonatomic, strong) AFHTTPRequestOperationManager *ldOperationManager;

@end

// Global placeholder strings for NSNotification
// Note: These string literals are just placeholder data. Can be anything.
NSString *const LoadDataFailed = @"LoadDataFailed";
NSString *const LoadDataSucceeded = @"LoadDataSucceeded";

@implementation UMPDataSource

+ (instancetype) sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype) init {
    self = [super init];
    
    if (self) {
        [self createOperationManager];
        [self loadCampusData];
        [self stepCheckIfDataRefreshNeeded];
    }
    
    return self;
}

- (void) loadCampusData{
    
    // Load campus data
    NSString *path = [[NSBundle mainBundle] pathForResource:@"app-settings" ofType:@"plist"];
    NSDictionary *settings = [[NSDictionary alloc] initWithContentsOfFile:path];
    _campus = [[UMPCampus alloc] init];
    _campus.campusCode = settings[@"Campus Code"];
    _campus.campusName = settings[@"Campus Name"];
    _campus.wikipediaUrl = settings[@"Wikipedia URL"];
    
    // Note: In the future, we may load this data from LD web service. This will require asynchronous code.
    
}

// Check if it's time to refresh our data
- (void) stepCheckIfDataRefreshNeeded {
    
    // Get dates via loadDates
    if (![self loadDates]){
        // First-time user. Set default values for dates.
        self.lastDataRefresh = [NSDate distantPast];
        self.lastDataRefreshCheck = [NSDate distantPast];
        self.lastServerDataChanged = [NSDate distantFuture]; // This can be anything.
    }
    
    // Check if a week has passed since last check of LD server
    int numberOfDaysSinceLastCheck = [[NSDate date] timeIntervalSinceDate:self.lastDataRefreshCheck]/86400;
    if (numberOfDaysSinceLastCheck > 7) {
        // If yes, check last server update date.
        [self checkServerLastUpdatedDate:^(NSError *error) {
            if (error) {
                // If error, log it, but then proceed as normal. No need to alert user or stop the app.
                NSLog(@"Error trying to connect with http://www.logicaldimension.com/ws/umap/1.2.1/getCampusesLastUpdateDate.json.php. Error:%@", error);
                NSLog(@"Error is not fatal. Proceeding as normal.");
                [self loadData];
            }
            // Check if self.lastDataRefresh < self.lastServerDataChanged, which was just updated by checkServerLastUpdatedDate:
            else if ([self.lastDataRefresh compare:self.lastServerDataChanged] == NSOrderedAscending){
                // If yes, refresh data from LD server
                NSLog(@"Cache is stale. Refreshing data from LD server.");
                [self loadDataWithForceWebRefreshFlag:YES];
            }
            else{
                NSLog(@"Cache is still good. Proceed as normal.");
                [self loadData];
            }
        }];
    } else {
        // Otherwise, proceed as normal
        NSLog(@"It hasn't been a week since last check. Proceed as normal.");
        [self loadData];
    }
    
}

// Load data
- (void) loadData {
    [self loadDataWithForceWebRefreshFlag:NO];
}
- (void) loadDataWithForceWebRefreshFlag: (BOOL)forceWebRefresh {
    
    // Check if there is archived data
    NSString *fullPathLocations = [self pathForFilename:NSStringFromSelector(@selector(locations))];
    NSArray *storedLocations = [NSKeyedUnarchiver unarchiveObjectWithFile:fullPathLocations];
    if (storedLocations.count && !forceWebRefresh) {
        
        // If there is, load locations from archive
        NSLog(@"Loading locations from archive on disk.");
        NSMutableArray *mutableLocations = [storedLocations mutableCopy];
        _locations = mutableLocations;
        self.state = UMPDataSourceReady;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:LoadDataSucceeded object:nil];
        });
        
    } else {
        
        self.state = UMPDataSourceLoadingData;
        
        // There is no archived data yet, so let's get some from web-service
        NSLog(@"Loading locations from LD server.");
        [self populateLocationsDataWithCompletionHandler:^(NSError *error){
            
            if (error) {
                
                // Update state
                if ([self dataExistsInDataSource]){
                    // Even if there's an error from last load, data source is usable if there's older data.
                    self.state = UMPDataSourceReady;
                } else {
                    // This is the first attempt to load data, and it errored out, so there's no older data we can use. Thus, the datasource is not ready.
                    self.state = UMPDataSourceNotReady;
                }
                
                // Post notification
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:LoadDataFailed object:error];
                });
                
            } else {
                
                // Update state
                self.state = UMPDataSourceReady;
                
                // Update last refresh date to now
                self.lastDataRefresh = [NSDate date];
                self.lastDataRefreshCheck = [NSDate date]; // Might as well bump this up too.
                [self saveDates];
                
                // Post notification
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:LoadDataSucceeded object:nil];
                });
            }
        }];
        
    }
    
}

- (void) checkServerLastUpdatedDate:(LDRequestCompletionBlock)completionHandler {
    
    NSMutableDictionary *mutableParameters = [@{@"campusCode": self.campus.campusCode} mutableCopy];
    
    [self.ldOperationManager GET:@"/ws/umap/1.2.1/getCampusesLastUpdateDate.json.php"
                      parameters:mutableParameters
                         success:^(AFHTTPRequestOperation *operation, id responseObject) {
                             if ([responseObject isKindOfClass:[NSDictionary class]]) {
                                 
                                 NSString *lastServerDataChangedString = responseObject[@"lastUpdated"];
                                 NSDateFormatter *df = [[NSDateFormatter alloc] init];
                                 [df setDateFormat:@"yyyy-MM-dd HH:mm:ss z"];
                                 self.lastServerDataChanged = [df dateFromString: lastServerDataChangedString];
                                 self.lastDataRefreshCheck = [NSDate date];
                                 [self saveDates];
                                 
                             } else {
                                 // TODO - Handle this error. For now, though, not too important. This error doesn't have any consequences.
                             }
                             
                             if (completionHandler) {
                                 completionHandler(nil);
                             }
                         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                             if (completionHandler) {
                                 completionHandler(error);
                             }
                         }];
    
}

// Check if data exists in data source
- (BOOL) dataExistsInDataSource {
    
    if (self.locations && [self.locations isKindOfClass:[NSMutableArray class]] &&
        self.campus && [self.campus isKindOfClass:[NSMutableArray class]]) {
        return YES;
    } else {
        return NO;
    }
    
}

- (void) createOperationManager {
    
    NSURL *baseURL = [NSURL URLWithString:@"http://www.logicaldimension.com/"];
    self.ldOperationManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];
    self.ldOperationManager.responseSerializer = [AFJSONResponseSerializer serializer];

}

- (void) populateLocationsDataWithCompletionHandler:(LDRequestCompletionBlock)completionHandler {

    NSMutableDictionary *mutableParameters = [@{@"campusCode": self.campus.campusCode} mutableCopy];
    
    [self.ldOperationManager GET:@"/ws/umap/1.2.1/getListOfLocations.json.php"
                             parameters:mutableParameters
                                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                    if ([responseObject isKindOfClass:[NSDictionary class]]) {
                                        [self parseLocationsDataFromFeedDictionary:responseObject];
                                    }
                                    
                                    if (completionHandler) {
                                        completionHandler(nil);
                                    }
                                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                    if (completionHandler) {
                                        completionHandler(error);
                                    }
                                }];
    
}

- (void) parseLocationsDataFromFeedDictionary:(NSDictionary *) feedDictionary {
    
    NSLog(@"%@", feedDictionary);
    NSArray *locationsFeedArray = feedDictionary[@"campusLocations"];
    
    NSMutableArray *tmpLocations = [NSMutableArray array];
    for (NSDictionary *locationDictionary in locationsFeedArray) {
        UMPLocation *location = [[UMPLocation alloc] initWithDictionary:locationDictionary];
        if (location) {
            [tmpLocations addObject:location];
        }
    }
    
    _locations = tmpLocations;
    [self saveLocations];
    
}

// Save locations to disk
- (void) saveLocations {
    
    if (self.locations.count > 0) {
        // Write the changes to disk
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *fullPath = [self pathForFilename:NSStringFromSelector(@selector(locations))];
            NSData *locationsData = [NSKeyedArchiver archivedDataWithRootObject:self.locations];
            
            NSError *dataError;
            BOOL wroteSuccessfully = [locationsData writeToFile:fullPath options:NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUnlessOpen error:&dataError];
            
            if (!wroteSuccessfully) {
                NSLog(@"Couldn't write file: %@", dataError);
            }
        });
        
    }
}

// Save dates to NSUserDefaults
- (void) saveDates {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:self.lastDataRefresh forKey:@"lastDataRefresh"];
    [defaults setObject:self.lastDataRefreshCheck forKey:@"lastDataRefreshCheck"];
    [defaults setObject:self.lastServerDataChanged forKey:@"lastServerDataChanged"];
    
    [defaults synchronize];
    
    NSLog(@"Data saved");
}

- (BOOL) loadDates {
    // Get the stored data before the view loads
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    self.lastDataRefresh = [defaults objectForKey:@"lastDataRefresh"];
    self.lastDataRefreshCheck = [defaults objectForKey:@"lastDataRefreshCheck"];
    self.lastServerDataChanged = [defaults objectForKey:@"lastServerDataChanged"];
    
    if (!self.lastDataRefresh ||
        !self.lastDataRefreshCheck){
        return NO; // This must be first time user opened app
    }else {
        return YES;
    }
}

#pragma mark - Utils

- (NSString *) pathForFilename:(NSString *) filename {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:filename];
    return dataPath;
}


@end
