//
//  UMPCampus.m
//  University Maps
//
//  Created by psytronx on 8/31/14.
//  Copyright (c) 2014 Logical Dimension. All rights reserved.
//

#import "UMPCampus.h"

@implementation UMPCampus

- (NSString *)description {
    return [NSString stringWithFormat: @"{ id = %ld; state = %@; campusName = %@; campusName = %@; centerLat = %f; centerLong = %f; spanLat = %f; spanLong = %f; wikipediaUrl = %@",
            (long)self.id, self.state, self.campusName, self.campusCode, self.centerLat, self.centerLong, self.spanLat, self.spanLong, self.wikipediaUrl];
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:self.id forKey:@"id"];
    [aCoder encodeObject:self.state forKey:@"state"];
    [aCoder encodeObject:self.campusName forKey:@"campusName"];
    [aCoder encodeObject:self.campusCode forKey:@"campusCode"];
    [aCoder encodeDouble:self.centerLat forKey:@"centerLat"];
    [aCoder encodeDouble:self.centerLong forKey:@"centerLong"];
    [aCoder encodeDouble:self.spanLat forKey:@"spanLat"];
    [aCoder encodeDouble:self.spanLong forKey:@"spanLong"];
    [aCoder encodeObject:self.wikipediaUrl forKey:@"wikipediaUrl"];
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        _id = [aDecoder decodeIntegerForKey:@"id"];
        _state = [aDecoder decodeObjectForKey:@"state"];
        _campusName = [aDecoder decodeObjectForKey:@"campusName"];
        _campusCode = [aDecoder decodeObjectForKey:@"campusCode"];
        _centerLat = [aDecoder decodeDoubleForKey:@"centerLat"];
        _centerLong = [aDecoder decodeDoubleForKey:@"centerLong"];
        _spanLat = [aDecoder decodeDoubleForKey:@"spanLat"];
        _spanLong = [aDecoder decodeDoubleForKey:@"spanLong"];
        _wikipediaUrl = [aDecoder decodeObjectForKey:@"wikipediaUrl"];
    }
    return self;
}

@end
