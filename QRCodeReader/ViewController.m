//
//  ViewController.m
//  QRCodeReader
//
//  Created by Steven Shatz on 2/14/15.
//  Copyright (c) 2015 Steven Shatz. All rights reserved.
//

// This requires a device with Video Camera, so it cannot be tested in the Simulator!!!

// Noteworthy References:
// - Reading QR Codes: http://www.appcoda.com/qr-code-ios-programming-tutorial/
// - Pre-iOS 8 App for iPhone and iPad: http://www.techrepublic.com/blog/software-engineer/better-code-develop-universal-apps-for-ios-devices/
// - Setting up an iOS 8 Universal App: http://www.raywenderlich.com/83276/beginning-adaptive-layout-tutorial


#import "ViewController.h"

@interface ViewController ()
    
@property (nonatomic) BOOL isReading;

@property (nonatomic, strong) AVCaptureSession *captureSession;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;

-(BOOL)startReading;
-(void)stopReading;
-(void)loadBeepSound;

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _isReading = NO;
    
    _captureSession = nil;
    
    [self loadBeepSound];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Action Methods

- (IBAction)startStopReading:(id)sender {
    NSLog(@"%s", __FUNCTION__);
    
    if (!_isReading) {
        if ([self startReading]) {
            [_bbitemStart setTitle:@"Stop"];
            [_lblStatus setText:@"Scanning for QR Code..."];
        }
    }
    else{
        [self stopReading];
        [_bbitemStart setTitle:@"Start!"];
    }
    
    _isReading = !_isReading;
}

- (BOOL)startReading {
    NSLog(@"%s", __FUNCTION__);

    NSError *error;
    
    // Set up video capture device
    
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo]; // We are capturing video as input
    
    AVCaptureDeviceInput *captureCameraInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];  // Our input device is the video camera
    if (!captureCameraInput) {
        NSLog(@"%@", [error localizedDescription]);
        return NO;
    }
    
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];    // Our output will be MetaData (from the QR Code)
    
    _captureSession = [[AVCaptureSession alloc] init];
    [_captureSession addInput:captureCameraInput];
    [_captureSession addOutput:captureMetadataOutput];
    
    // Set up async method (on its own unique queue) for retrieving a QR Code's metadata

    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("myQueue", NULL);
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];    // We want a QR Code
    
    // Show user what camera sees
    
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];   // Defines how video is displayed within AVCaptureVideoPreviewLayer bounds
    [_videoPreviewLayer setFrame:_viewPreview.layer.bounds];
    [_viewPreview.layer addSublayer:_videoPreviewLayer];
    
    // Launch our async method: start the flow of data from inputs to outputs connected to the AVCaptureSession instance.
    // This call blocks until the session object has completely started up or failed.
    // A failure to start running is reported through the AVCaptureSessionRuntimeErrorNotification mechanism.
    
    [_captureSession startRunning];
    
    return YES;
}

- (void)stopReading {
    NSLog(@"%s", __FUNCTION__);
    
    [_captureSession stopRunning];
    _captureSession = nil;
    
    [_videoPreviewLayer removeFromSuperlayer];
}

#pragma mark - AVCaptureMetadataOutputObjects Delegate Methods

// Delegates receive this message whenever the output captures and emits new objects, as specified by its metadataObjectTypes property.
// Delegates can use the provided objects in conjunction with other APIs for further processing.
// This method will be called on the dispatch queue specified by the output's metadataObjectsCallbackQueue property.
// This method may be called frequently, so it must be efficient to prevent capture performance problems, including dropped metadata objects.

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    NSLog(@"%s", __FUNCTION__);
 
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        
        NSLog(@"Number of metaDataObjects = %ld", (unsigned long)[metadataObjects count]);

        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            
            [_lblStatus performSelectorOnMainThread:@selector(setText:) withObject:[metadataObj stringValue] waitUntilDone:NO];
            
            [self performSelectorOnMainThread:@selector(stopReading) withObject:nil waitUntilDone:NO];
            
            [_bbitemStart performSelectorOnMainThread:@selector(setTitle:) withObject:@"Start!" waitUntilDone:NO];
            
            _isReading = NO;
            
            if (_audioPlayer) {
                [_audioPlayer play];
            }
        }
    }
}

#pragma mark - Sound Methods

-(void)loadBeepSound {
    NSString *beepFilePath = [[NSBundle mainBundle] pathForResource:@"beep" ofType:@"mp3"];
    NSURL *beepURL = [NSURL URLWithString:beepFilePath];
    NSError *error;
    
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:beepURL error:&error];
    if (error) {
        NSLog(@"Could not play beep file.");
        NSLog(@"%@", [error localizedDescription]);
    } else {
        [_audioPlayer prepareToPlay];
    }
}

@end
