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
@property (nonatomic, strong) UMPLocation* selectedLocation;
@property (nonatomic, strong) CLLocation* userCLLocation;
@end

@implementation MapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"Map";
    
    // Setup location manager
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
    if (authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
        
        [self.locationManager startUpdatingLocation];
        self.mapView.showsUserLocation = YES;
        
    }
    
    // Add tracking button to toolbar (this needs to be done programmatically; not available in Storyboard)
    MKUserTrackingBarButtonItem *trackingButton = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.mapView];
    NSMutableArray *items = [[NSMutableArray alloc] initWithArray:self.toolbar.items];
    [items insertObject:trackingButton atIndex:0];
    [self.toolbar setItems:items];
    
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

#pragma mark - CLLocationManagerDelegate methods
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)authorizationStatus{
    if (authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
        
        [self.locationManager startUpdatingLocation];
        self.mapView.showsUserLocation = YES;
        
    }
}

// Keep track of user's location
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    self.userCLLocation = [locations lastObject]; // The last object has latest user location
}

#pragma mark - MKMapViewDelegate methods

- (MKAnnotationView *) mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>) annotation
{
    MKPinAnnotationView *newAnnotation = [[MKPinAnnotationView alloc]     initWithAnnotation:annotation reuseIdentifier:@"pinLocation"];
    
    newAnnotation.canShowCallout = YES;
    
    UIButton *directionsButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    newAnnotation.rightCalloutAccessoryView = directionsButton;
    
    return newAnnotation;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{

    NSInteger index = [self.mapView.annotations indexOfObject:view.annotation];
    self.selectedLocation = (UMPLocation *)self.locations[index];
    NSLog(@"directions pressed. location: %@", self.selectedLocation.name);
    
    // Setup UIActionSheet
    UIActionSheet *actionSheet = [UIActionSheet alloc];
    // Determine if Google maps app is available
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]]) {
        
        actionSheet = [actionSheet initWithTitle:@"These will exit the app"
                                        delegate:self
                               cancelButtonTitle:@"Cancel"
                          destructiveButtonTitle:nil
                               otherButtonTitles:@"Directions in Apple Maps", @"Directions in Google Maps", nil];
        
//        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"comgooglemaps://?center=40.765819,-73.975866&zoom=14&views=traffic"]];
        
    } else {
        
        NSLog(@"Can't use comgooglemaps://");
        actionSheet = [actionSheet initWithTitle:@"This will exit the app"
                                        delegate:self
                               cancelButtonTitle:@"Cancel"
                          destructiveButtonTitle:nil
                               otherButtonTitles:@"Directions in Apple Maps", nil];
        
    }
    
    actionSheet.tag = 0; // Todo - use enum
    [actionSheet showInView:[self.view window]];
    
}

// This method is used to animate pin drop for custom pin
- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    MKAnnotationView *aV;
    
    for (aV in views) {
        
        // Don't pin drop if annotation is user location
        if ([aV.annotation isKindOfClass:[MKUserLocation class]]) {
            continue;
        }
        
        // Don't pin drop if there's more than 10 locations. Would take too long
        if ([self.locations count] > 10){
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
            // If only one location, show annotation automatically
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

// ======================================================================
#pragma mark - UIActionSheetDelegate Methods
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == 0){
        // DIRECTIONS
        
        if (buttonIndex == [actionSheet cancelButtonIndex]){
            return; // Cancel
        }
        
        if (!self.selectedLocation){
            NSLog(@"Error. The app should never get here. 'self.selectedLocation' was not assigned.");
            return;
        }
        
        // form the complete url by reading the partial url saved by calloutAccessoryControlTapped
        NSString *url_full;
        if (buttonIndex == 0) {
            NSLog(@"Directions in Apple Maps");
            NSString *saddr = [NSString stringWithFormat:@"%f,%f", self.userCLLocation.coordinate.latitude, self.userCLLocation.coordinate.longitude];
            NSString *daddr = [NSString stringWithFormat:@"%f,%f", self.selectedLocation.latitude, self.selectedLocation.longitude];
//            url_full = [[NSString alloc] initWithFormat:@"%@&dirflg=w", self.url_prefix];
        } else if (buttonIndex == 1) {
            NSLog(@"Directions in Google Maps");
//            url_full = [[NSString alloc] initWithFormat:@"%@&dirflg=d", self.url_prefix];
        } else {
            NSLog(@"Error. The app should never get here.");
            return;
        }
        
//        // form complete url
//        NSURL *url = [NSURL URLWithString:url_full];
//        
//        // call gMap
//        [[UIApplication sharedApplication] openURL:url];
    }
    
    // -------------------------------------------------
    
//    else if (actionSheet.tag == 1){
//        // SHARE LOCATION
//        
//        if (buttonIndex == [actionSheet cancelButtonIndex]){
//            return; // well... coz the user cancelled...
//        }
//        
//        // call various compose views
//        if (buttonIndex == 0) {
//            NSLog(@"button 0");
//            
//            Class smsClass = (NSClassFromString(@"MFMessageComposeViewController"));
//            //			if (smsClass != nil && [MFMessageComposeViewController canSendText]) {
//            //				MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
//            //				controller.body = text;
//            //				controller.recipients = [NSArray arrayWithObjects: nil];
//            //				controller.messageComposeDelegate = self;
//            //				[self presentModalViewController:controller animated:YES];
//            //				[controller release];
//            //			}
//            
//            // Note: iOS 3.x doesn't have MFMessageComposeViewController. smsClass == nil checks for this.
//            if (smsClass == nil || ![MFMessageComposeViewController canSendText]){
//                NSString *title = [[NSString alloc] initWithString:@"SMS not setup"];
//                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:@"This feature is disabled because your SMS has not been set up yet." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//                [alert show];
//                [alert release];
//                [title release];
//                return;
//            }
//            // Proceed with SMS
//            MFMessageComposeViewController *vc = [[MFMessageComposeViewController alloc] init];
//            // set up body
//            NSString *url = [[NSString alloc] initWithFormat:@"http://maps.google.com/maps?q=My_Location@%g,%g", self.userLat, self.userLong];
//            vc.body = url;
//            vc.messageComposeDelegate = self;
//            [self presentModalViewController:vc animated:YES];
//            [vc release];
//            
//        } else if (buttonIndex == 1) {
//            NSLog(@"button 1");
//            // check to see if email sending is enabled.
//            if (![MFMailComposeViewController canSendMail]){
//                NSString *title = [[NSString alloc] initWithString:@"Email not setup"];
//                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:@"This feature is disabled because your email has not been set up yet." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//                [alert show];
//                [alert release];
//                [title release];
//                return;
//            }
//            // Email
//            MFMailComposeViewController *vc = [[MFMailComposeViewController alloc] init];
//            vc.mailComposeDelegate = self;
//            // set up subject
//            // ref: http://iphonedevelopertips.com/cocoa/date-formatters-examples-take-2.html
//            // ref: http://unicode.org/reports/tr35/tr35-6.html#Date_Format_Patterns
//            NSDate *today = [NSDate date];
//            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
//            [dateFormat setDateFormat:@"hh:mm a MMM dd z"];
//            NSString *subject = [[NSString alloc] initWithFormat:@"My Location (%@)", [dateFormat stringFromDate:today]];
//            [vc setSubject:subject];
//            [subject release];
//            [dateFormat release];
//            // set up body
//            NSMutableString *body = [[NSMutableString alloc] init];
//            NSString *body1 = [[NSString alloc] initWithFormat:@"<br><br>My location is at ( %g , %g )<br><br>", self.userLat, self.userLong];
//            NSString *body2 = [[NSString alloc] initWithString:@"You can click on the following link to see it on google map.<br>"];
//            NSString *body3 = [[NSString alloc] initWithFormat:@"<a href=http://maps.google.com/maps?q=MyLocation@%g,%g>( %g , %g )</a><br><br><br>", self.userLat, self.userLong, self.userLat, self.userLong];
//            NSString *body4 = [[NSString alloc] initWithString:@"This service is brought to you by <a href=http://www.logicaldimension.com>Logical Dimension</a>."];
//            [body appendString:body1];
//            [body appendString:body2];
//            [body appendString:body3];
//            [body appendString:body4];
//            [body1 release];
//            [body2 release];
//            [body3 release];
//            [body4 release];
//            [vc setMessageBody:body isHTML:YES];
//            //[vc.navigationBar setBarStyle:UIBarStyleBlack];
//            vc.navigationBar.tintColor=[UIColor colorWithRed:0/256.0 green:87/256.0 blue:61/256.0 alpha:1.0];
//            
//            [self presentModalViewController:vc animated:YES];
//            [vc release];
//        } else {
//            NSLog(@"what the... how did you get here???");
//            return;
//        }
//    }
//    
    
}

#pragma mark - Toolbar methods

- (IBAction)mapTypeSegmentedControlValueChanged:(UISegmentedControl *)sender {
    
    NSInteger mapType = sender.selectedSegmentIndex;
    NSLog(@"MapViewController: updateMapType: selectedSegmentIndex : %ld", mapType);
    
    // refresh the map view
    if (mapType == 0){
        [self.mapView setMapType:MKMapTypeHybrid];
    }else if (mapType == 1){
        [self.mapView setMapType:MKMapTypeStandard];
    }else if (mapType == 2){
        [self.mapView setMapType:MKMapTypeSatellite];
    }
    
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
