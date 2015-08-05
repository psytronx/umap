//
//  MapViewController.m
//  UCD Map v2
//
//  Created by psytronx on 8/3/15.
//  Copyright (c) 2015 Logical Dimension. All rights reserved.
//

#import "MapViewController.h"
#import "UMPLocation.h"

@interface MapViewController ()

@end

@implementation MapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Clear any existing pins
    NSArray *existingpoints = self.mapView.annotations;
    if ([existingpoints count] > 0) [self.mapView removeAnnotations:existingpoints];
    
    [self plotPins];
//    [self performSelector:@selector(plotPins) withObject:nil afterDelay:0.0];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - MKMapViewDelegate methods

//- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
//{
//    NSLog(@"viewForannotation");
//    MKAnnotationView* annotationView = nil;
//    
//    // determine the type of annotation, and produce the correct type of annotation view for it.
//    if ([annotation isMemberOfClass:[CSMapAnnotation class]]){
//        
//        CSMapAnnotation* csAnnotation = (CSMapAnnotation*)annotation;
//        NSString* identifier = @"Image";
//        
//        // RH 2/16/2011 Don't recycle pins. This results in pin image with wrong location code.
//        //		CSImageAnnotationView* imageAnnotationView = (CSImageAnnotationView*)[self.mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
//        //		if(nil == imageAnnotationView)
//        //		{
//        CSImageAnnotationView* imageAnnotationView = [[[CSImageAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier pin_image:csAnnotation.pin_image] autorelease];
//        
//        // If location has floor plans (i.e. RoomMapLocationId != 0), show button that will link to floor plans view.
//        if (csAnnotation.location.RoomMapLocationId != 0) {
//            imageAnnotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
//        }
//        
//        //Right annotation button (Direction button)
//        UIButton *btnTemp=[[UIButton alloc]init];
//        btnTemp.frame=CGRectMake(0, 20, 30, 30);
//        btnTemp.tag=123;//"BUTTON_DIRECTIONS"; //Hack! @todo create an enumeration here!
//        [btnTemp setBackgroundImage:[UIImage imageNamed:@"directions.png"] forState:UIControlStateNormal];
//        //[btnTemp addTarget:self action:@selector(showDirection:) forControlEvents:UIControlEventTouchUpInside];
//        imageAnnotationView.leftCalloutAccessoryView=btnTemp;
//        
//        //		}
//        
//        annotationView = imageAnnotationView;
//        
//        CGPoint offset;
//        offset.x = 0.0;
//        offset.y = -10.0;
//        [annotationView setCenterOffset:offset];
//        [annotationView setEnabled:YES];
//        [annotationView setCanShowCallout:YES];
//        return annotationView;
//    }else{
//        // chances are we are dealing with the blue dot
//        return nil;
//    }
//    
//}

// This method is used to animate pin drop for custom pin
- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    MKAnnotationView *aV;
    
    for (aV in views) {
        
        // Don't pin drop if annotation is user location
        if ([aV.annotation isKindOfClass:[MKUserLocation class]]) {
            continue;
        }
        
        // Check if current annotation is inside visible map rect
        MKMapPoint point =  MKMapPointForCoordinate(aV.annotation.coordinate);
        if (!MKMapRectContainsPoint(self.mapView.visibleMapRect, point)) {
            continue;
        }
        
        CGRect endFrame = aV.frame;
        
        // Move annotation out of view
        aV.frame = CGRectMake(aV.frame.origin.x,
                              aV.frame.origin.y - self.view.frame.size.height,
                              aV.frame.size.width,
                              aV.frame.size.height);
        
        // Animate drop
        [UIView animateWithDuration:0.5
                              delay:0.04*[views indexOfObject:aV]
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             
                             aV.frame = endFrame;
                             
                             // Animate squash
                         }completion:^(BOOL finished){
                             if (finished) {
                                 [UIView animateWithDuration:0.05 animations:^{
                                     aV.transform = CGAffineTransformMakeScale(1.0, 0.8);
                                     
                                 }completion:^(BOOL finished){
                                     if (finished) {
                                         [UIView animateWithDuration:0.1 animations:^{
                                             aV.transform = CGAffineTransformIdentity;
                                         }];
                                     }
                                 }];
                             }
                         }];
    }
}

// Based on self.locations, plot pins on map
- (void)plotPins{
    
    // plot locations
    double lat_max = -65535.0;
    double lat_min = 65535.0;
    double long_max = -65535.0;
    double long_min = 65535.0;
    
    for (UMPLocation *location in self.locations){
        
        // get info out of the location object
//        NSString *loc = location.name;
        
        // set pin coordinates
//        CLLocationDegrees latitude  = (CLLocationDegrees) location.latitude;
//        CLLocationDegrees longitude = (CLLocationDegrees) location.longitude;
//        CLLocation *pos = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
//        NSLog(@"%@ %lf %lf", loc, pos.coordinate.latitude, pos.coordinate.longitude);
        
//        CSMapAnnotation * annotation = [[[CSMapAnnotation alloc] initWithCoordinate:[pos coordinate]
//                                                                     annotationType:CSMapAnnotationTypeImage//CSMapAnnotationTypeEnd
//                                                                              title:loc
//                                                                          pin_image:location.image
//                                                                           location:location] autorelease];
        
        MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
        CLLocationCoordinate2D pinCoordinate;
        pinCoordinate.latitude = location.latitude;
        pinCoordinate.longitude = location.longitude;
        annotation.coordinate = pinCoordinate;
        annotation.title = location.name;
        
        //[myAnnotationArray addObject:annotation];
//        [self.mapView addAnnotation:annotation];
        [self.mapView performSelector:@selector(addAnnotation:) withObject:annotation afterDelay:0.0];
        if ([self.locations count] == 1){
            // If only one location, show annotation right away
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self.mapView selectAnnotation:[[self.mapView annotations] objectAtIndex:0] animated:YES];
            });
        }
        
        // adjust range
        if (location.latitude > lat_max){ lat_max = location.latitude; }
        if (location.latitude < lat_min){ lat_min = location.latitude; }
        if (location.longitude > long_max){ long_max = location.longitude; }
        if (location.longitude < long_min){ long_min = location.longitude; }
    }
    
    // Region and Zoom
    CLLocationCoordinate2D coord;
    MKCoordinateSpan span;
    //self.spanLat = span_latitudeDelta;
    //self.spanLong = span_longitudeDelta;
//    if (centerOnCSUS){
//        NSLog(@"centerOnCSUS is YES. Centering on CSUS label in google map.");
//        // These coordinates center on "Califonia State University - Sacramento" label in Google Maps.
//        coord.latitude = 38.561800;//7884591;
//        coord.longitude = -121.42510380074603;//-121.425708353998;
//    }
//    else{
        NSLog(@"lat_max: %g, lat_min: %g", lat_max, lat_min);
        NSLog(@"long_max: %g, long_min: %g", long_max, long_min);
        coord.latitude = (lat_max+lat_min)/2.0;//midpt
        coord.longitude = (long_max+long_min)/2.0;
//    }
    
    float zoom = 2;
    double span_latitudeDelta = (lat_max-lat_min)*zoom;
    double span_longitudeDelta = (long_max-long_min)*zoom;
    if (span_latitudeDelta == 0){
        span_latitudeDelta = 0.005;
    }
    if (span_longitudeDelta == 0){
        span_longitudeDelta = 0.005;
    }
    span = MKCoordinateSpanMake(span_latitudeDelta, span_longitudeDelta);
    MKCoordinateRegion region = MKCoordinateRegionMake(coord, span);
//    self.region = MKCoordinateRegionMake(coord, span);
    NSLog(@"Setting region at point %g %g", coord.latitude, coord.longitude);
    NSLog(@"  with span %g %g", span_latitudeDelta, span_longitudeDelta);
    
//    [self.mapView setRegion:[self.mapView regionThatFits:region] animated:true];
    [self.mapView setRegion:region animated:true];
    
//    // activate user location manager
//    self.locationManager = [[CLLocationManager alloc] init];
//    [locationManager startUpdatingLocation];
//    locationManager.delegate = self;
//    locationManager.distanceFilter = kCLDistanceFilterNone; 
//    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
//    
//    // stop activity indicator
//    [mIndicatorView stopAnimating];
//    [mIndicatorView removeFromSuperview];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
