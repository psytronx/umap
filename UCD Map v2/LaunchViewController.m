//
//  LaunchViewController.m
//  UCD Map v2
//
//  Created by psytronx on 8/1/15.
//  Copyright (c) 2015 Logical Dimension. All rights reserved.
//

#import "LaunchViewController.h"
#import "UMPDataSource.h"
#import "Reachability.h"

@interface LaunchViewController (){
    BOOL _timeDelayPassed;
    BOOL _dataDidLoad;
}
@property (nonatomic, strong) id UIApplicationDidBecomeActiveNotificationObserver;
@property (nonatomic, strong) id loadDataSucceededObserver;
@property (nonatomic, strong) id loadDataFailedObserver;
@end

@implementation LaunchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Setup NSNotification observers
    self.UIApplicationDidBecomeActiveNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        
        // If coming back from background, try testing for reachability again
        [self stepTestForReachability];
        
    }];
    self.loadDataSucceededObserver = [[NSNotificationCenter defaultCenter] addObserverForName:LoadDataSucceeded object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        
        _dataDidLoad = YES;
        [self considerMovingToNextViewController];
        
    }];
    self.loadDataFailedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:LoadDataFailed object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        
        [self showDataFailedErrorDialog];
        
    }];
    
    [self stepTestForReachability];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self.loadDataSucceededObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self.loadDataFailedObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self.UIApplicationDidBecomeActiveNotificationObserver];
}

- (void)stepTestForReachability {
    
    [self.activityIndicator startAnimating];
    
    if ([self testReachibility]){
        NSLog(@"There is internet connection");
        [self setupDataSource];
    }else{
        NSLog(@"There is NO internet connection");
        [self performSelector:@selector(showReachabilityErrorDialog) withObject:nil afterDelay:0.0];
    }
    
}

- (void)showReachabilityErrorDialog{
    
    [self.activityIndicator stopAnimating];
    
    NSString *title = @"Internet connectivity is required.";
    NSString *message = @"Please turn on your device's internet connection.";
    
    // iOS 8+
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];

//    UIAlertAction* settingsAction = [UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault
//                                                          handler:^(UIAlertAction * action) {
//                                                              NSURL*url=[NSURL URLWithString:UIApplicationOpenSettingsURLString];
//                                                              [[UIApplication sharedApplication] openURL:url];
//                                                          }];
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

- (void)setupDataSource {
    
    // First call to [UMPDataSource sharedInstance] attempts to load data automatically
    UMPDataSource *datasource = [UMPDataSource sharedInstance];
    // However, the first call might have failed. If this is a re-attempt, we'll need to call loadData explicitly.
    if (datasource.state == UMPDataSourceNotReady){
        [datasource loadData];
    }
    
    // Now, wait for response. Notification observers setup in ViewDidLoad will trigger upon completion.
    
    // Also, trigger time delay, so that user is forced to stare at our beautiful LD logo for at least a second
    double delayInSeconds = 1.3;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        _timeDelayPassed = YES;
        [self considerMovingToNextViewController];
    });
}

- (void)showDataFailedErrorDialog{
    
    NSLog(@"Error: issue loading data");
    
    [self.activityIndicator stopAnimating];
    
    NSString *title = @"We are experiencing issues with our server right now.";
    NSString *message = @"We apologize for the inconvenience. Please try again later.";
    
    // iOS 8+
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                          }];
    
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
    
    // iOS 7
    // TODO Use macro
    //    UIAlertView *alertIos7 = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    //    [alertIos7 show];
    
}

- (void)considerMovingToNextViewController {
    
    // If both condtions met, move to next view controller
    if (_timeDelayPassed && _dataDidLoad){
        [self performSegueWithIdentifier:@"start" sender:self];
    }
    
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



@end
