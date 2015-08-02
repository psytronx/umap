//
//  UMPDataSource.h
//  UCD Map v2
//
//  Created by psytronx on 8/2/15.
//  Copyright (c) 2015 Logical Dimension. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UMPDataSource : NSObject

@property (nonatomic, strong, readonly) NSArray *locations;

+ (instancetype) sharedInstance;

@end
