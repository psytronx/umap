//
//  UMPCampus.h
//  University Maps
//
//  Created by psytronx on 8/31/14.
//  Copyright (c) 2014 Logical Dimension. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UMPCampus : NSObject <NSCoding>
@property (nonatomic) NSInteger id;
@property (nonatomic, copy) NSString * campusName;
@property (nonatomic, copy) NSString * campusCode;
@property (nonatomic, copy) NSString * state;
@property (nonatomic) double centerLat;
@property (nonatomic) double centerLong;
@property (nonatomic) double spanLat;
@property (nonatomic) double spanLong;
@property (nonatomic, copy) NSString * wikipediaUrl;
@end
