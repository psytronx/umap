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

extern NSString *const LoadDataFailed;
extern NSString *const LoadDataSucceeded;

@interface UMPDataSource : NSObject

@property (nonatomic, strong, readonly) NSArray *locations; // Locations data
@property (nonatomic, strong, readonly) UMPCampus *campus; // Campus data. After init, stays constant

+ (instancetype) sharedInstance;

@end
