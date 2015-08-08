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
        [self loadData];
    }
    
    return self;
}

- (void) loadData {
    
    // Get campus data
    NSString *path = [[NSBundle mainBundle] pathForResource:@"app-settings" ofType:@"plist"];
    NSDictionary *settings = [[NSDictionary alloc] initWithContentsOfFile:path];
    _campus = [[UMPCampus alloc] init];
    _campus.campusCode = settings[@"Campus Code"];
    _campus.campusName = settings[@"Campus Name"];
    _campus.wikipediaUrl = settings[@"Wikipedia URL"];
    
    // Check if there is archived data
    NSString *fullPathLocations = [self pathForFilename:NSStringFromSelector(@selector(locations))];
    NSArray *storedLocations = [NSKeyedUnarchiver unarchiveObjectWithFile:fullPathLocations];
    if (storedLocations.count) {
        
        // If there is, load locations from archive
        NSMutableArray *mutableLocations = [storedLocations mutableCopy];
        _locations = mutableLocations;
        self.state = UMPDataSourceReady;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:LoadDataSucceeded object:nil];
        });
        
    } else {
        
        self.state = UMPDataSourceLoadingData;
        
        // There is no archived data yet, so let's get some from web-service
        [self populateLocationsDataWithCompletionHandler:^(NSError *error){
            
            if ([self dataExistsInDataSource]){
                self.state = UMPDataSourceReady;
                // Note: Even if there's an error from last load, data source is usable if there's older data.
            } else {
                self.state = UMPDataSourceNotReady;
            }
            
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:LoadDataFailed object:error];
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:LoadDataSucceeded object:nil];
                });
            }
        }];
        
    }
    
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

#pragma mark - Utils

- (NSString *) pathForFilename:(NSString *) filename {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:filename];
    return dataPath;
}


@end
