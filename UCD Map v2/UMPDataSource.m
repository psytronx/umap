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

@property (nonatomic, strong) NSString *campusCode; // Campus code. Constant for this application
@property (nonatomic, strong) UMPCampus *campus; // Campus data.
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
            
            // Get campus code
            NSString *path = [[NSBundle mainBundle] pathForResource:@"app-settings" ofType:@"plist"];
            NSDictionary *settings = [[NSDictionary alloc] initWithContentsOfFile:path];
            self.campusCode = settings[@"Campus Code"];
            
            // Load any archived data
            NSString *fullPathCampus = [self pathForFilename:NSStringFromSelector(@selector(campus))];
            UMPCampus *storedCampus = [NSKeyedUnarchiver unarchiveObjectWithFile:fullPathCampus];
            NSString *fullPathLocations = [self pathForFilename:NSStringFromSelector(@selector(locations))];
            NSArray *storedLocations = [NSKeyedUnarchiver unarchiveObjectWithFile:fullPathLocations];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (storedLocations.count > 0 && storedCampus) {
                    
                    // Load campus into memory
                    [self willChangeValueForKey:@"campus"];
                    self.campus = storedCampus;
                    [self didChangeValueForKey:@"campus"];
                    
                    // Load locations into memory
                    NSMutableArray *mutableLocations = [storedLocations mutableCopy];
                    [self willChangeValueForKey:@"locations"];
                    _locations = mutableLocations;
                    [self didChangeValueForKey:@"locations"];
                    
                } else {
                    // There is no archived data yet, so let's get some
                    [self populateDataWithCompletionHandler:nil];
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

- (void) populateDataWithCompletionHandler:(LDRequestCompletionBlock)completionHandler {

    NSMutableDictionary *mutableParameters = [@{@"campusCode": self.campusCode} mutableCopy];
    
    [self.ldOperationManager GET:@"/ws/umap/1.2.1/getListOfLocations.json.php"
                             parameters:mutableParameters
                                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                    if ([responseObject isKindOfClass:[NSDictionary class]]) {
                                        [self parseDataFromLocations:responseObject];
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

- (void) parseDataFromLocations:(NSDictionary *) feedDictionary {
    
    NSLog(@"%@", feedDictionary);
    
}

- (NSString *) pathForFilename:(NSString *) filename {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:filename];
    return dataPath;
}


@end
