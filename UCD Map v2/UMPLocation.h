//
//  UMPLocation.h
//  Model for a location
//
//  Created by psytronx on 8/11/14.
//  Copyright (c) 2014 Logical Dimension. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UMPLocation : NSObject <NSCoding, NSCopying>
@property (nonatomic) NSInteger id;
@property (nonatomic, copy) NSString * name;
@property (nonatomic, copy) NSString * category;
@property (nonatomic) double latitude;
@property (nonatomic) double longitude;

- (instancetype) initWithDictionary:(NSDictionary *)mediaDictionary;

@end
