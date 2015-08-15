//
//  UMPAnnotation.h
//  UC Davis Map
//
//  Created by psytronx on 8/7/15.
//  Copyright (c) 2015 Logical Dimension. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class UMPLocation;

@interface UMPAnnotation : NSObject <MKAnnotation>

@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title, *subtitle;
@property (nonatomic, strong) UMPLocation *location;

- (id)initWithLocation:(CLLocationCoordinate2D)coord;

@end