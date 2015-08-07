//
//  UMPAnnotation.m
//  UC Davis Map
//
//  Created by psytronx on 8/7/15.
//  Copyright (c) 2015 Logical Dimension. All rights reserved.
//

#import "UMPAnnotation.h"

@implementation UMPAnnotation
- (id)initWithLocation: (CLLocationCoordinate2D) coord {
    self = [super init];
    if (self) {
        _coordinate = coord;
    }
    return self;
}
@end
