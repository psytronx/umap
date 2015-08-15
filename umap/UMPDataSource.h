//
//  UMPDataSource.h
//  UCD Map v2
//
//  Created by psytronx on 8/2/15.
//  Copyright (c) 2015 Logical Dimension. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^LDRequestCompletionBlock)(NSError *error);

@class UMPCampus;

// For NSNotification
extern NSString *const LoadDataFailed;
extern NSString *const LoadDataSucceeded;

// Track state of data source. Is it usable yet?
typedef NS_ENUM(NSInteger, UMPDataSourceState){
    UMPDataSourceNotReady, // Has no data. Data source cannot be used.
    UMPDataSourceLoadingData, // Currently attempting to load data.
    UMPDataSourceReady // Has data. Data source is ready to be used.
};

@interface UMPDataSource : NSObject

@property (nonatomic, strong, readonly) NSArray *locations; // Locations data
@property (nonatomic, strong, readonly) UMPCampus *campus; // Campus data. After init, stays constant
@property (nonatomic) UMPDataSourceState state; // Track state of data source. Is it usable yet?
@property (nonatomic, strong) NSDate *lastDataRefresh; // Last time data on app was refreshed
@property (nonatomic, strong) NSDate *lastDataRefreshCheck; // Last time app checked server if data changed
@property (nonatomic, strong) NSDate *lastServerDataChanged; // Most recent change of data on the server, to the best of app's knowledge

+ (instancetype) sharedInstance;

- (void) loadData;

@end
