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
@property (nonatomic, strong) id observer;
@end

@implementation LaunchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    if ([self testReachibility]){
        [UMPDataSource sharedInstance];
        
        // Now, we wait for response...
        self.observer = [[NSNotificationCenter defaultCenter] addObserverForName:LoadDataSucceeded object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            _dataDidLoad = YES;
            [self considerMovingToNextViewController];
        }];
        
        // Also, trigger time delay, so that user is forced to stare at our beautiful LD logo for at least a second
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            _timeDelayPassed = YES;
            [self considerMovingToNextViewController];
        });
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self.observer];
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
        NSLog(@"There IS NO internet connection");
        NSString *title = @"Internet required for this app.";
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:@"Please turn on your device's internet connection." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return false;
    } else {
        NSLog(@"There IS internet connection");
        return true;
    }
    
}



@end
