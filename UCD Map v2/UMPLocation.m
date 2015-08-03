//
//  UMPLocation.m
//
//  Created by psytronx on 8/11/14.
//  Copyright (c) 2014 Logical Dimension. All rights reserved.
//

#import "UMPLocation.h"

@implementation UMPLocation

- (instancetype) initWithDictionary:(NSDictionary *)mediaDictionary {
    self = [super init];
    
    if (self) {
        self.id = [((NSString*)mediaDictionary[@"id"]) integerValue];
        self.name = mediaDictionary[@"name"];
        self.category = mediaDictionary[@"category"];
        self.latitude = [((NSString*)mediaDictionary[@"latitude"]) doubleValue];
        self.longitude = [((NSString*)mediaDictionary[@"longitude"]) doubleValue];
    }
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat: @"{ id = %lD; name = %@; category = %@; latitude = %f; longitude = %f",
            (long)self.id, self.name, self.category, self.latitude, self.longitude];
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:self.id forKey:@"id"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.category forKey:@"category"];
    [aCoder encodeDouble:self.latitude forKey:@"latitude"];
    [aCoder encodeDouble:self.longitude forKey:@"longitude"];
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        _id = [aDecoder decodeIntegerForKey:@"id"];
        _name = [aDecoder decodeObjectForKey:@"name"];
        _category = [aDecoder decodeObjectForKey:@"category"];
        _latitude = [aDecoder decodeDoubleForKey:@"latitude"];
        _longitude = [aDecoder decodeDoubleForKey:@"longitude"];
    }
    return self;
}

- (UMPLocation *) copyWithZone: (NSZone *)zone {
    UMPLocation *location = [[UMPLocation alloc] init];
    location.id = self.id;
    location.name = self.name;
    location.category = self.category;
    location.latitude = self.latitude;
    location.longitude = self.longitude;
    return location;
}

@end
