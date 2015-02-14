//
//  ViewController.h
//  QRCodeReader
//
//  Created by Steven Shatz on 2/14/15.
//  Copyright (c) 2015 Steven Shatz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate>

@property (weak, nonatomic) IBOutlet UIView *viewPreview;           // video container view

@property (weak, nonatomic) IBOutlet UILabel *lblStatus;            // status label

@property (weak, nonatomic) IBOutlet UIBarButtonItem *bbitemStart;  // start button (on toolbar)

- (IBAction)startStopReading:(id)sender;

@end

