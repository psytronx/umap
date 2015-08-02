//
//  UMPDataSource.m
//  UCD Map v2
//
//  Created by psytronx on 8/2/15.
//  Copyright (c) 2015 Logical Dimension. All rights reserved.
//

#import "UMPDataSource.h"
#import "UMPCampus.h"
#import "UMPLocation.h"

@interface UMPDataSource () {
    NSMutableArray *_locations;
}

@property (nonatomic, strong) UMPCampus* campus; // Constant for this application

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



@end
