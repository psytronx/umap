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
}

@property (nonatomic, strong) UMPCampus *campus; // Campus data. After init, stays constant
@property (nonatomic, strong) AFHTTPRequestOperationManager *ldOperationManager;

@end

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
        
        // Check for saved data
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            // Get campus data
            NSString *path = [[NSBundle mainBundle] pathForResource:@"app-settings" ofType:@"plist"];
            NSDictionary *settings = [[NSDictionary alloc] initWithContentsOfFile:path];
            self.campus = [[UMPCampus alloc] init];
            self.campus.campusCode = settings[@"Campus Code"];
            self.campus.campusName = settings[@"Campus Name"];
            self.campus.wikipediaUrl = settings[@"Wikipedia URL"];
            
            // Load any archived data
            NSString *fullPathLocations = [self pathForFilename:NSStringFromSelector(@selector(locations))];
            NSArray *storedLocations = [NSKeyedUnarchiver unarchiveObjectWithFile:fullPathLocations];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (storedLocations.count > 0) {
                    
                    // Load locations into memory
                    NSMutableArray *mutableLocations = [storedLocations mutableCopy];
                    [self willChangeValueForKey:@"locations"];
                    _locations = mutableLocations;
                    [self didChangeValueForKey:@"locations"];
                    
                } else {
                    // There is no archived data yet, so let's get some
                    [self populateLocationsDataWithCompletionHandler:nil];
                }
            });
        });
    }
    
    return self;
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
    
    // Trigger KVO
    [self willChangeValueForKey:@"locations"];
    _locations = tmpLocations;
    [self didChangeValueForKey:@"locations"];
    
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


#pragma mark - Key/Value Observing

- (NSUInteger) countOfLocations {
    return self.locations.count;
}

- (id) objectInLocationsAtIndex:(NSUInteger)index {
    return [self.locations objectAtIndex:index];
}

- (NSArray *) locationsAtIndexes:(NSIndexSet *)indexes {
    return [self.locations objectsAtIndexes:indexes];
}

- (void) insertObject:(UMPLocation *)object inLocationsAtIndex:(NSUInteger)index {
    [_locations insertObject:object atIndex:index];
}

- (void) removeObjectFromLocationsAtIndex:(NSUInteger)index {
    [_locations removeObjectAtIndex:index];
}

- (void) replaceObjectInLocationsAtIndex:(NSUInteger)index withObject:(id)object {
    [_locations replaceObjectAtIndex:index withObject:object];
}


#pragma mark - Utils

- (NSString *) pathForFilename:(NSString *) filename {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:filename];
    return dataPath;
}


@end
