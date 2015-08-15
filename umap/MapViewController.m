//
//  MapViewController.m
//  UCD Map v2
//
//  Created by psytronx on 8/3/15.
//  Copyright (c) 2015 Logical Dimension. All rights reserved.
//

#import "MapViewController.h"
#import "UMPDataSource.h"
#import "UMPLocation.h"
#import "UMPCampus.h"
#import "UMPAnnotation.h"
#import "Reachability.h"
#import <Google/Analytics.h>

// Global variable, to persist chosen map type
NSInteger ChosenMapType = MKMapTypeHybrid;

@interface MapViewController ()
@property (nonatomic, strong) UMPLocation* selectedLocation;
@property (nonatomic, strong) CLLocation* userCLLocation;
@property (nonatomic, strong) id applicationDidBecomeActiveNotificationObserver;
@end

@implementation MapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Setup NSNotification observers
    self.applicationDidBecomeActiveNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        
        // If coming back from background, try testing for reachability again
        [self stepTestForReachability];
        
    }];
    
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
    
}

- (void)viewWillAppear:(BOOL)animated {
    
    // GA
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:self.title];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    
    // Setup segmented control
    self.mapView.mapType = ChosenMapType; // Restore saved state
    switch (ChosenMapType) {
        case MKMapTypeHybrid:
            self.mapTypeSegmentedControl.selectedSegmentIndex = 0;
            break;
        case MKMapTypeStandard:
            self.mapTypeSegmentedControl.selectedSegmentIndex = 1;
            break;
        case MKMapTypeSatellite:
            self.mapTypeSegmentedControl.selectedSegmentIndex = 2;
            break;
        default:
            break;
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
        
        UMPAnnotation *annotation = [[UMPAnnotation alloc] init];
        CLLocationCoordinate2D pinCoordinate;
        pinCoordinate.latitude = location.latitude;
        pinCoordinate.longitude = location.longitude;
        annotation.coordinate = pinCoordinate;
        annotation.title = location.name;
        annotation.location = location;
        
        //[myAnnotationArray addObject:annotation];
        //        [self.mapView addAnnotation:annotation];
        [self.mapView performSelector:@selector(addAnnotation:) withObject:annotation afterDelay:0.0];
        if ([self.locations count] == 1){
            // If only one location, show annotation automatically
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.8 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                if (self.mapView.annotations[0] == self.mapView.userLocation){
                    // First annotation is now user location (was inserted while drop animation was running!), so we use second annotation instead
                    [self.mapView selectAnnotation:self.mapView.annotations[1] animated:YES];
                } else {
                    [self.mapView selectAnnotation:self.mapView.annotations[0] animated:YES];
                }
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
    
    if (annotation == mapView.userLocation) return nil;
    
    MKAnnotationView *newAnnotation = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"orange marker"];
    newAnnotation.image = [UIImage imageNamed:@"orange-map-marker.png"];
    
    newAnnotation.canShowCallout = YES;
    
    UIButton *directionsButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    newAnnotation.rightCalloutAccessoryView = directionsButton;
    
    return newAnnotation;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{

    self.selectedLocation = ((UMPAnnotation *)view.annotation).location;
    NSLog(@"Annotation pressed. location: %@", self.selectedLocation.name);
    
    // GA
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:[UMPDataSource sharedInstance].campus.campusCode
                                                          action:@"map-annotation-callout-opened"
                                                           label:self.selectedLocation.name
                                                           value:nil] build]];
    
    // iOS 8+
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:self.selectedLocation.name
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]]) {
        
        UIAlertAction* googleMapsAction = [UIAlertAction actionWithTitle:@"Directions in Google Maps" style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   NSLog(@"Directions in Google Maps");
                                                                   
                                                                   // GA
                                                                   id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
                                                                   [tracker send:[[GAIDictionaryBuilder createEventWithCategory:[UMPDataSource sharedInstance].campus.campusCode
                                                                                                                         action:@"googlemaps-directions-touched"
                                                                                                                          label:self.selectedLocation.name
                                                                                                                          value:nil] build]];
                                                                   
                                                                   NSString *saddr = [NSString stringWithFormat:@"%f,%f", self.userCLLocation.coordinate.latitude, self.userCLLocation.coordinate.longitude];
                                                                   NSString *daddr = [NSString stringWithFormat:@"%f,%f", self.selectedLocation.latitude, self.selectedLocation.longitude];
                                                                   NSString *url_full = [NSString stringWithFormat:@"comgooglemaps://?saddr=%@&daddr=%@", saddr, daddr];
                                                                   // form complete url
                                                                   NSURL *url = [NSURL URLWithString:url_full];
                                                                   
                                                                   // call gMap
                                                                   [[UIApplication sharedApplication] openURL:url];
                                                               }];
        [alert addAction:googleMapsAction];
    }
    
    UIAlertAction* appleMapsAction = [UIAlertAction actionWithTitle:@"Directions in Apple Maps" style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * action) {
                                                                 
                                                                 // GA
                                                                 id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
                                                                 [tracker send:[[GAIDictionaryBuilder createEventWithCategory:[UMPDataSource sharedInstance].campus.campusCode
                                                                                                                       action:@"applemaps-directions-touched"
                                                                                                                        label:self.selectedLocation.name
                                                                                                                        value:nil] build]];
                                                                 
                                                                 // Create an MKMapItem to pass to the Maps app
                                                                 CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(self.selectedLocation.latitude, self.selectedLocation.longitude);
                                                                 MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate addressDictionary:nil];
                                                                 MKMapItem *destination = [[MKMapItem alloc] initWithPlacemark:placemark];
                                                                 [destination setName:self.selectedLocation.name];
                                                                 
                                                                 // Set the directions mode to "Driving"
                                                                 NSDictionary *launchOptions = @{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving};
                                                                 // Get the "Current User Location" MKMapItem
                                                                 MKMapItem *source = [MKMapItem mapItemForCurrentLocation];
                                                                 // Pass the current location and destination map items to the Maps app
                                                                 // Set the direction mode in the launchOptions dictionary
                                                                 [MKMapItem openMapsWithItems:@[source, destination] launchOptions:launchOptions];
                                                             }];
    [alert addAction:appleMapsAction];
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"uber://"]]) {
        UIAlertAction* uberPickupAction = [UIAlertAction actionWithTitle:@"Request Ride with Uber" style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * action) {
                                                                     
                                                                     // GA
                                                                     id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
                                                                     [tracker send:[[GAIDictionaryBuilder createEventWithCategory:[UMPDataSource sharedInstance].campus.campusCode
                                                                                                                           action:@"uber-request-touched"
                                                                                                                            label:self.selectedLocation.name
                                                                                                                            value:nil] build]];
                                                                     //                                                                     NSString *pickup = [NSString stringWithFormat:@"%f,%f", self.userCLLocation.coordinate.latitude, self.userCLLocation.coordinate.longitude];
                                                                     NSString *escapedLocationName = [self.selectedLocation.name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
                                                                     NSString *dropoff = [NSString stringWithFormat:@"&dropoff[latitude]=%f&dropoff[longitude]=%f&dropoff[nickname]=%@", self.selectedLocation.latitude, self.selectedLocation.longitude, escapedLocationName];
                                                                     NSString *url_full = [NSString stringWithFormat:@"uber://?action=setPickup&pickup=my_location%@", dropoff];
                                                                     
                                                                     // form complete url
                                                                     NSURL *url = [NSURL URLWithString:url_full];
                                                                     // call gMap
                                                                     [[UIApplication sharedApplication] openURL:url];
                                                                 }];
        [alert addAction:uberPickupAction];
        
    }

    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {}];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
    
//    DEPRECATED IN iOS 8+
//    // Setup UIActionSheet
//    UIActionSheet *actionSheet = [UIActionSheet alloc];
//    // Determine if Google maps app is available
//    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]]) {
//        
//        actionSheet = [actionSheet initWithTitle:self.selectedLocation.name
//                                        delegate:self
//                               cancelButtonTitle:@"Cancel"
//                          destructiveButtonTitle:nil
//                               otherButtonTitles:@"Directions in Apple Maps", @"Directions in Google Maps", nil];
//        
////        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"comgooglemaps://?center=40.765819,-73.975866&zoom=14&views=traffic"]];
//        
//    } else {
//        
//        NSLog(@"Can't use comgooglemaps://");
//        actionSheet = [actionSheet initWithTitle:self.selectedLocation.name
//                                        delegate:self
//                               cancelButtonTitle:@"Cancel"
//                          destructiveButtonTitle:nil
//                               otherButtonTitles:@"Directions in Apple Maps", nil];
//        
//    }
//    
//    actionSheet.tag = 0; // Todo - use enum
//    [actionSheet showInView:[self.view window]];
    
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
        [UIView animateWithDuration:0.65
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

// ======================================================================
// DEPRECATED IN iOS 8+
//#pragma mark - UIActionSheetDelegate Methods
//- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
//{
//    if (actionSheet.tag == 0){
//        // DIRECTIONS
//        
//        if (buttonIndex == [actionSheet cancelButtonIndex]){
//            return; // Cancel
//        }
//        
//        if (!self.selectedLocation){
//            NSLog(@"Error. The app should never get here. 'self.selectedLocation' was not assigned.");
//            return;
//        }
//        
//        // form the complete url by reading the partial url saved by calloutAccessoryControlTapped
//        NSString *url_full;
//        if (buttonIndex == 0) {
//            NSLog(@"Directions in Apple Maps");
//            // Check to make sure we're in iOS 6+
//            Class mapItemClass = [MKMapItem class];
//            if (mapItemClass && [mapItemClass respondsToSelector:@selector(openMapsWithItems:launchOptions:)])
//            {
//                // Create an MKMapItem to pass to the Maps app
//                CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(self.selectedLocation.latitude, self.selectedLocation.longitude);
//                MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate addressDictionary:nil];
//                MKMapItem *destination = [[MKMapItem alloc] initWithPlacemark:placemark];
//                [destination setName:self.selectedLocation.name];
//                
//                // Set the directions mode to "Driving"
//                NSDictionary *launchOptions = @{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving};
//                // Get the "Current User Location" MKMapItem
//                MKMapItem *source = [MKMapItem mapItemForCurrentLocation];
//                // Pass the current location and destination map items to the Maps app
//                // Set the direction mode in the launchOptions dictionary
//                [MKMapItem openMapsWithItems:@[source, destination] launchOptions:launchOptions];
//            }
//        } else if (buttonIndex == 1) {
//            NSLog(@"Directions in Google Maps");
//            NSString *saddr = [NSString stringWithFormat:@"%f,%f", self.userCLLocation.coordinate.latitude, self.userCLLocation.coordinate.longitude];
//            NSString *daddr = [NSString stringWithFormat:@"%f,%f", self.selectedLocation.latitude, self.selectedLocation.longitude];
//            url_full = [NSString stringWithFormat:@"comgooglemaps://?saddr=%@&daddr=%@", saddr, daddr];
////            url_full = [[NSString alloc] initWithFormat:@"%@&dirflg=d", self.url_prefix];
//        } else {
//            NSLog(@"Error. The app should never get here.");
//            return;
//        }
//        
//        // form complete url
//        NSURL *url = [NSURL URLWithString:url_full];
//
//        // call gMap
//        [[UIApplication sharedApplication] openURL:url];
//    }
//}

#pragma mark - Toolbar methods

- (IBAction)mapTypeSegmentedControlValueChanged:(UISegmentedControl *)sender {
    
    NSInteger mapType = sender.selectedSegmentIndex;
    NSLog(@"MapViewController: updateMapType: selectedSegmentIndex : %ld", mapType);
    
    // refresh the map view
    if (mapType == 0){
        ChosenMapType = MKMapTypeHybrid;
    }else if (mapType == 1){
        ChosenMapType = MKMapTypeStandard;
    }else if (mapType == 2){
        ChosenMapType = MKMapTypeSatellite;
    }
    [self.mapView setMapType:ChosenMapType];
    
}


#pragma mark - Reachability

- (void)stepTestForReachability {
    
    if ([self testReachibility]){
        NSLog(@"There is internet connection");
    }else{
        NSLog(@"There is NO internet connection");
        [self performSelector:@selector(showReachabilityErrorDialog) withObject:nil afterDelay:0.0];
    }
    
}

- (void)showReachabilityErrorDialog{
    
    NSString *title = @"Internet connectivity is required.";
    NSString *message = @"Please turn on your device's internet connection.";
    
    // iOS 8+
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
//    UIAlertAction* settingsAction = [UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault
//                                                           handler:^(UIAlertAction * action) {
//                                                               NSURL*url=[NSURL URLWithString:UIApplicationOpenSettingsURLString];
//                                                               [[UIApplication sharedApplication] openURL:url];
//                                                           }];
//    [alert addAction:settingsAction];
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
    
    // iOS 7
    // TODO Use macro
    //    UIAlertView *alertIos7 = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    //    [alertIos7 show];
    
}

- (BOOL)testReachibility {
    
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    if (networkStatus == NotReachable) {
        return false;
    } else {
        NSLog(@"There IS internet connection");
        return true;
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
