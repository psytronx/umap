//
//  InformationViewController.m
//  UC Davis Map
//
//  Created by psytronx on 8/9/15.
//  Copyright (c) 2015 Logical Dimension. All rights reserved.
//

#import "InformationViewController.h"
#import <MessageUI/MFMailComposeViewController.h>

@interface InformationViewController ()

@end

@implementation InformationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Setup email label touch handling
    self.emailLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapLabelWithGesture:)];
    [self.emailLabel addGestureRecognizer:tapGesture];
}

- (void)didTapLabelWithGesture:(UITapGestureRecognizer *)tapGesture {
    // Email info@logicaldimension.com
    //email subject
    NSString * subject = @"Feedback";
    //recipient(s)
    NSArray * recipients = [NSArray arrayWithObjects:@"info@logicaldimension.com", nil];
    
    //create the MFMailComposeViewController
    MFMailComposeViewController * composer = [[MFMailComposeViewController alloc] init];
    composer.mailComposeDelegate = self;
    [composer setSubject:subject];
    //[composer setMessageBody:body isHTML:YES]; //if you want to send an HTML message
    [composer setToRecipients:recipients];
    
    //present it on the screen
    [self presentViewController:composer animated:YES completion:NULL];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)closePressed:(id)sender {
     [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - MFMailComposeViewControllerDelegate methods

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    // close the Mail Interface
    [self dismissViewControllerAnimated:YES completion:NULL];
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
