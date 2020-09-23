/*
  This file is part of the Structure SDK.
  Copyright © 2019 Occipital, Inc. All rights reserved.
  http://structure.io
*/

#import "ViewController.h"
#import "ViewController+CaptureSession.h"
#import "ViewController+SLAM.h"
#import "ViewController+OpenGL.h"

#import "ViewUtilities.h"

#import <Structure/Structure.h>

#include <cmath>
#include <algorithm>

#pragma mark - ViewController Setup

@interface ViewController ()
@end

@implementation ViewController

+ (instancetype) viewController
{
    ViewController* vc = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    return vc;
}

- (void)dealloc
{
    if ([EAGLContext currentContext] == _display.context)
    {
        [EAGLContext setCurrentContext:nil];
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscapeRight;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupGL];
    
    [self setupUserInterface];
    
    [self setupMeshViewController];
    
    [self setupGestures];

    [self setupCaptureSession];
    
    [self setupSLAM];
    
    // Later, we’ll set this true if we have a device-specific calibration
    _useColorCamera = true;
    
    // Make sure we get notified when the app becomes active to start/restore the sensor state if necessary.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    [self initializeDynamicOptions];
    [self enterCubePlacementState];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // The framebuffer will only be really ready with its final size after the view appears.
    [(EAGLView *)self.view setFramebuffer];
    
    [self setupGLViewport];

    [self updateAppStatusMessage];
    
    
    // We will connect to the sensor when we receive appDidBecomeActive.
}

- (void)appDidBecomeActive
{
    // Try to connect to the Structure Sensor and stream if necessary.
    if ([self currentStateNeedsSensor])
    {
        _captureSession.streamingEnabled = YES;
    }
    
    // Abort the current scan if we were still scanning before going into background since we
    // are not likely to recover well.
    if (_slamState.scannerState == ScannerStateScanning)
    {
        [self resetButtonPressed:self];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    [self respondToMemoryWarning];
}

- (void)initializeDynamicOptions
{
    _settingsPopupView = [[SettingsPopupView alloc] initWithSettingsPopupViewDelegate:self];
    [self.view addSubview:_settingsPopupView];
    [self.view addConstraints:@[// Pin to top of view, with offset
                                [NSLayoutConstraint constraintWithItem:_settingsPopupView
                                                             attribute:NSLayoutAttributeTop
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.view
                                                             attribute:NSLayoutAttributeTop
                                                            multiplier:1.0
                                                              constant:20.0],
                                // Pin to left of view, with offset
                                [NSLayoutConstraint constraintWithItem:_settingsPopupView
                                                             attribute:NSLayoutAttributeLeft
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.view
                                                             attribute:NSLayoutAttributeLeft
                                                            multiplier:1.0
                                                              constant:30.0]]];
}

- (void)setupUserInterface
{
    // Make sure the status bar is hidden.
    [self prefersStatusBarHidden];
    
    // Fully transparent message label, initially.
    self.appStatusMessageLabel.alpha = 0;
    
    // Make sure the label is on top of everything else.
    self.appStatusMessageLabel.layer.zPosition = 100;

    self.firmwareUpdateView.layer.cornerRadius = 8.0;
    self.structureAppIcon.layer.cornerRadius = 8.0;
    [self.updateNowButton setTitleColor:[UIColor colorWithRed:0.25 green:0.73 blue:0.88 alpha:1.]
                               forState:UIControlStateNormal];

}

// Make sure the status bar is disabled (iOS 7+)
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)setupGestures
{
    // Register pinch gesture for volume scale adjustment.
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGesture:)];
    [pinchGesture setDelegate:self];
    [self.view addGestureRecognizer:pinchGesture];
}

- (void)setupMeshViewController
{
    _meshViewController = [MeshViewController viewController];
    _meshViewController.delegate = self;
    _meshViewNavigationController = [[UINavigationController alloc] initWithRootViewController:_meshViewController];
    _meshViewNavigationController.modalPresentationStyle = UIModalPresentationFullScreen;
}

- (void)presentMeshViewer:(STMesh *)mesh
{
    [_meshViewController setupGL:_display.context];
    
    _meshViewController.colorEnabled = _useColorCamera;
    _meshViewController.mesh = mesh;
    [_meshViewController setCameraProjectionMatrix:_display.depthCameraGLProjectionMatrix];
    
    // Sample a few points to estimate the volume center
    int totalNumVertices = 0;
    for( int i=0; i<mesh.numberOfMeshes; ++i )
        totalNumVertices += [mesh numberOfMeshVertices:i];
    
    // The sample step if we need roughly 1000 sample points
    int sampleStep = std::max (1.f, totalNumVertices/1000.f);
    int sampleCount = 0;
    GLKVector3 volumeCenter = GLKVector3Make(0,0,0);
    
    for( int i=0; i<mesh.numberOfMeshes; ++i )
    {
        int numVertices = [mesh numberOfMeshVertices:i];
        const GLKVector3* vertex = [mesh meshVertices:i];
        
        for( int j=0; j<numVertices; j+=sampleStep )
        {
            volumeCenter = GLKVector3Add(volumeCenter, vertex[j]);
            sampleCount++;
        }
    }
    
    if( sampleCount>0 )
        volumeCenter = GLKVector3DivideScalar(volumeCenter, sampleCount);
    
    else
        volumeCenter = GLKVector3MultiplyScalar(_slamState.volumeSizeInMeters, 0.5);
    
    [_meshViewController resetMeshCenter:volumeCenter];

    [self presentViewController:_meshViewNavigationController animated:YES completion:^{}];
}

- (void)enterCubePlacementState
{
    // Switch to the Scan button.
    self.scanButton.hidden = NO;
    self.doneButton.hidden = YES;
    self.resetButton.hidden = YES;
    
    // We'll enable the button only after we get some initial pose.
    self.scanButton.enabled = NO;
    
    // Cannot be lost in cube placement mode.
    _trackingLostLabel.hidden = YES;
    
    [_settingsPopupView enableAllSettingsDuringCubePlacement];

    _captureSession.streamingEnabled = YES;
    _captureSession.properties = STCaptureSessionPropertiesSetColorCameraAutoExposureISOAndWhiteBalance();

    _slamState.scannerState = ScannerStateCubePlacement;
     
    [self updateIdleTimer];
}

- (void)enterScanningState
{
    // This can happen if the UI did not get updated quickly enough.
    if (!_slamState.cameraPoseInitializer.lastOutput.hasValidPose)
    {
        NSLog(@"Warning: not accepting to enter into scanning state since the initial pose is not valid.");
        return;
    }
    
    // Switch to the Done button.
    self.scanButton.hidden = YES;
    self.doneButton.hidden = NO;
    self.resetButton.hidden = NO;

    [_settingsPopupView disableNonDynamicSettingsDuringScanning];

    // Prepare the mapper for the new scan.
    [self setupMapper];
    
    _slamState.tracker.initialCameraPose = _slamState.initialDepthCameraPose;
    
    // We will lock exposure during scanning to ensure better coloring.
    _captureSession.properties = STCaptureSessionPropertiesLockAllColorCameraPropertiesToCurrent();

    _slamState.scannerState = ScannerStateScanning;
}

- (void)enterViewingState
{
    // Cannot be lost in view mode.
    [self hideTrackingErrorMessage];
    
    _appStatus.statusMessageDisabled = true;
    [self updateAppStatusMessage];
    
    // Hide the Scan/Done/Reset button.
    self.scanButton.hidden = YES;
    self.doneButton.hidden = YES;
    self.resetButton.hidden = YES;
    
    _captureSession.streamingEnabled = NO;

    //if (_useColorCamera)
    //    [self stopColorCamera];
    
    [_slamState.mapper finalizeTriangleMesh];
    
    STMesh *mesh = [_slamState.scene lockAndGetSceneMesh];
    [self presentMeshViewer:mesh];
    
    [_slamState.scene unlockSceneMesh];
    
    _slamState.scannerState = ScannerStateViewing;
    
    [self updateIdleTimer];
}

#pragma mark -  Structure Sensor Management

-(BOOL)currentStateNeedsSensor
{
    switch (_slamState.scannerState)
    {
        // Initialization and scanning need the sensor.
        case ScannerStateCubePlacement:
        case ScannerStateScanning:
            return TRUE;
            
        // Other states don't need the sensor.
        default:
            return FALSE;
    }
}

#pragma mark - IMU

- (void)processDeviceMotion:(CMDeviceMotion *)motion withError:(NSError *)error
{
    if (_slamState.scannerState == ScannerStateCubePlacement)
    {
        // Update our gravity vector, it will be used by the cube placement initializer.
        _lastGravity = GLKVector3Make (motion.gravity.x, motion.gravity.y, motion.gravity.z);
    }
    
    if (_slamState.scannerState == ScannerStateCubePlacement || _slamState.scannerState == ScannerStateScanning)
    {
        // The tracker is more robust to fast moves if we feed it with motion data.
        [_slamState.tracker updateCameraPoseWithMotion:motion];
    }
}

#pragma mark - UI Callbacks

- (void) streamingSettingsDidChange:(BOOL)highResolutionColorEnabled
                     streamVGADepth:(BOOL)streamVGADepth
              depthStreamPresetMode:(STCaptureSessionPreset)depthStreamPresetMode
{
    _dynamicOptions.highResColoring = highResolutionColorEnabled;
    _dynamicOptions.depthStreamPreset = depthStreamPresetMode;
    _dynamicOptions.streamVgaDepth = streamVGADepth;
    [self setupCaptureSession];
    _captureSession.streamingEnabled = YES;
}

- (void) streamingPropertiesDidChange:(BOOL)irAutoExposureEnabled
                irManualExposureValue:(float)irManualExposureValue
                    irAnalogGainValue:(STCaptureSessionSensorAnalogGainMode)irAnalogGainValue
{
    _captureSession.properties =
    @{
      kSTCaptureSessionPropertySensorIRExposureModeKey:
          @(irAutoExposureEnabled ? STCaptureSessionSensorExposureModeAuto : STCaptureSessionSensorExposureModeLockedToCustom),
      kSTCaptureSessionPropertySensorIRExposureValueKey: @(irManualExposureValue),
      kSTCaptureSessionPropertySensorIRAnalogGainValueKey: @(irAnalogGainValue)
      };
}

- (void) trackerSettingsDidChange:(BOOL)rgbdTrackingEnabled
           improvedTrackerEnabled:(BOOL)improvedTrackerEnabled
{
    _dynamicOptions.depthAndColorTrackerIsOn = rgbdTrackingEnabled;
    _dynamicOptions.improvedTrackingIsOn = improvedTrackerEnabled;
    [self onSLAMOptionsChanged];
}

- (void) mapperSettingsDidChange:(BOOL)highResolutionMeshEnabled
           improvedMapperEnabled:(BOOL)improvedMapperEnabled
{
    _dynamicOptions.highResMapping = highResolutionMeshEnabled;
    _dynamicOptions.improvedMapperIsOn = improvedMapperEnabled;
    [self onSLAMOptionsChanged];
}

- (void)onSLAMOptionsChanged
{
    // A full reset to force a creation of a new tracker.
    [self resetSLAM];
    [self clearSLAM];
    [self setupSLAM];
    
    // Restore the volume size cleared by the full reset.
    [self adjustVolumeSize:_slamState.volumeSizeInMeters];
}

- (void)adjustVolumeSize:(GLKVector3)volumeSize
{
    // Make sure the volume size remains between 10 centimeters and 3 meters.
    volumeSize.x = keepInRange (volumeSize.x, 0.1, 3.f);
    volumeSize.y = keepInRange (volumeSize.y, 0.1, 3.f);
    volumeSize.z = keepInRange (volumeSize.z, 0.1, 3.f);
    
    _slamState.volumeSizeInMeters = volumeSize;
    
    _slamState.cameraPoseInitializer.volumeSizeInMeters = volumeSize;
    [_display.cubeRenderer adjustCubeSize:_slamState.volumeSizeInMeters];
}

- (IBAction)scanButtonPressed:(id)sender
{
// Uncomment the following lines to enable OCC writing
//    bool success = [_captureSession.occWriter startWriting:@"[AppDocuments]/Scanner.occ" appendDateAndExtension:NO];
//    if (!success)
//    {
//        NSLog(@"Could not properly start OCC writer.");
//    }
//
    [self enterScanningState];
}

- (IBAction)resetButtonPressed:(id)sender
{
    [self resetSLAM];
}

- (IBAction)doneButtonPressed:(id)sender
{
    if (_captureSession.occWriter.isWriting)
    {
        bool success = [_captureSession.occWriter stopWriting];
        if (!success)
        {
            @throw [NSException exceptionWithName:@"Scanner"
                                           reason:@"Could not properly stop OCC writer."
                                         userInfo:nil];
        }
    }

    [self enterViewingState];
}

- (IBAction)updateNowButtonPressed:(id)sender
{
    launchStructureAppOrGoToAppStore();
}

// Manages whether we can let the application sleep.
-(void)updateIdleTimer
{
    if ([self isStructureConnected] && [self currentStateNeedsSensor])
    {
        // Do not let the application sleep if we are currently using the sensor data.
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    }
    else
    {
        // Let the application sleep if we are only viewing the mesh or if no sensors are connected.
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    }
}

- (void)showTrackingMessage:(NSString*)message
{
    self.trackingLostLabel.text = message;
    self.trackingLostLabel.hidden = NO;
}

- (void)hideTrackingErrorMessage
{
    self.trackingLostLabel.hidden = YES;
}

- (void)showAppStatusMessage:(NSString *)msg
{
    _appStatus.needsDisplayOfStatusMessage = true;
    [self.view.layer removeAllAnimations];
    
    [self.appStatusMessageLabel setText:msg];
    [self.appStatusMessageLabel setHidden:NO];

    [UIView animateWithDuration:0.5f animations:^{
        self.appStatusMessageLabel.alpha = 1.0f;
    }completion:nil];
}

- (void)hideAppStatusMessage
{
    [self.view.layer removeAllAnimations];
    
    __weak ViewController *weakSelf = self;
    [UIView animateWithDuration:0.5f
                     animations:^{
                         weakSelf.appStatusMessageLabel.alpha = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         // If nobody called showAppStatusMessage before the end of the animation, do not hide it.
                         if (!self->_appStatus.needsDisplayOfStatusMessage)
                         {
                             // Could be nil if the self is released before the callback happens.
                             if (weakSelf) {
                                 [weakSelf.appStatusMessageLabel setHidden:YES];
                             }
                         }
     }];
}

-(void)updateAppStatusMessage
{
    STCaptureSessionUserInstruction userInstructions = _captureSession.userInstructions;
    
    bool needToConnectSensor = userInstructions & STCaptureSessionUserInstructionNeedToConnectSensor;
    bool needToChargeSensor = userInstructions & STCaptureSessionUserInstructionNeedToChargeSensor;
    bool needToAuthorizeColorCamera = userInstructions & STCaptureSessionUserInstructionNeedToAuthorizeColorCamera;
    bool needToUpgradeFirmware = userInstructions & STCaptureSessionUserInstructionFirmwareUpdateRequired;
    
    // If you don't want to display the overlay message when an approximate calibration
    // is available use `_captureSession.calibrationType >= STCalibrationTypeApproximate`
    bool needToRunCalibrator = userInstructions & STCaptureSessionUserInstructionNeedToRunCalibrator;
    
    [self.buyImageBG removeFromSuperview];
    [self.chargeImage removeFromSuperview];
    
    if (needToConnectSensor)
    {
        
        // Check if sensor was bought or no
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        bool bought = [prefs boolForKey:@"sensorBought"];
        
        if (bought)
        {
            [self showAppStatusMessage:_appStatus.pleaseConnectSensorMessage];
        
        } else {
            
            // Show required image
            if (self.viewAppear) {
                
                self.buyImageBG = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width * 0, self.view.frame.size.height * 0, self.view.frame.size.width * 1, self.view.frame.size.height * 1)];
                
                self.buyImage = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width * 0.3, self.view.frame.size.height * 0.42, self.view.frame.size.width * 0.4, self.view.frame.size.height * 0.2)];
                self.buyImage.image = [UIImage imageNamed:@"sensorRequired"];
                self.buyImage.contentMode = UIViewContentModeScaleAspectFit;
                self.buyImage.userInteractionEnabled = true;
                self.buyImageBG.userInteractionEnabled = true;
                UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
                [self.buyImage addGestureRecognizer:singleFingerTap];
                
                self.buyImageBG.backgroundColor = [UIColor whiteColor];
                [self.view addSubview:self.buyImageBG];
                [self.buyImageBG addSubview:self.buyImage];
                self.buyImage.layer.zPosition = 1000;
            } else {
                self.viewAppear = true;
            }
            
        }
        
        return;
    }

    if (_captureSession.sensorMode == STCaptureSessionSensorModeWakingUp)
    {
        [self showAppStatusMessage:_appStatus.sensorIsWakingUpMessage];
        return;
    }

    if (needToChargeSensor)
    {
        if (self.viewAppear) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.chargeImage = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width * 0.47, self.view.frame.size.height * 0.05, self.view.frame.size.width * 0.06, self.view.frame.size.width * 0.02)];
                self.chargeImage.image = [UIImage imageNamed:@"charge"];
                [self.view addSubview:self.chargeImage];
            });
        }
        
        [self showAppStatusMessage:_appStatus.pleaseChargeSensorMessage];
        return;
    }

    // Color camera permission issues.
    if (needToAuthorizeColorCamera)
    {
        [self showAppStatusMessage:_appStatus.needColorCameraAccessMessage];
        return;
    }

    if (_calibrationOverlay) { [_calibrationOverlay removeFromSuperview]; }
    if (needToRunCalibrator)
    {
        CalibrationOverlayType overlayType = CalibrationOverlayTypeNone;
        switch (_captureSession.calibrationType)
        {
            case STCalibrationTypeNone:
            {
                self.scanButton.enabled = NO;
                if (_captureSession.lens == STLensWideVision)
                {
                    overlayType = CalibrationOverlayTypeStrictlyRequired;
                }
                break;
            }
            case STCalibrationTypeApproximate:
            {
                self.scanButton.enabled = YES;
                overlayType = CalibrationOverlayTypeApproximate;
                break;
            }
            case STCalibrationTypeDeviceSpecific:
                // We should not ever enter this case if `needToRunCalibrator` is true
                break;
            default:
                NSLog(@"WARNING: Unknown calibration type returned from the capture session.");
                break;
        }

        const bool isIPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);

        _calibrationOverlay = [[CalibrationOverlay alloc] initWithType:overlayType];
        [self.view addSubview:_calibrationOverlay];

        // Center the calibration overlay in X
        [_calibrationOverlay.superview addConstraint:
         [NSLayoutConstraint constraintWithItem:_calibrationOverlay
                                      attribute:NSLayoutAttributeCenterX
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:_calibrationOverlay.superview
                                      attribute:NSLayoutAttributeCenterX
                                     multiplier:1.0
                                       constant:0.0]];

        if (overlayType == CalibrationOverlayTypeApproximate)
        {
            [_calibrationOverlay.superview addConstraint:
             [NSLayoutConstraint constraintWithItem:_calibrationOverlay
                                          attribute:NSLayoutAttributeBottom
                                          relatedBy:NSLayoutRelationEqual
                                             toItem:_calibrationOverlay.superview
                                          attribute:NSLayoutAttributeBottom
                                         multiplier:1.0
                                           constant:(isIPad ? -100 : -25)]];
        }
        else
        {
            [_calibrationOverlay.superview addConstraint:
             [NSLayoutConstraint constraintWithItem:_calibrationOverlay
                                          attribute:NSLayoutAttributeCenterY
                                          relatedBy:NSLayoutRelationEqual
                                             toItem:_calibrationOverlay.superview
                                          attribute:NSLayoutAttributeCenterY
                                         multiplier:1.0
                                           constant:0.0]];
        }

        if (!isIPad && overlayType != CalibrationOverlayTypeApproximate)
        {
            _calibrationOverlay.transform = CGAffineTransformMakeScale(0.85, 0.85);
        }
    }

    self.firmwareUpdateView.hidden = !needToUpgradeFirmware;

    // If we reach this point, no status to show.
    [self hideAppStatusMessage];
}

- (void) handleSingleTap:(UITapGestureRecognizer*) recognizer {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://structure.io/structure-sensor/mark-ii?utm_source=structure&utm_medium=in_app&utm_campaign=get_a_sensor"]];
}

- (void)pinchGesture:(UIPinchGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan)
    {
        if (_slamState.scannerState == ScannerStateCubePlacement)
        {
            _volumeScale.initialPinchScale = _volumeScale.currentScale / [gestureRecognizer scale];
        }
    }
    else if ([gestureRecognizer state] == UIGestureRecognizerStateChanged)
    {
        if(_slamState.scannerState == ScannerStateCubePlacement)
        {
            // In some special conditions the gesture recognizer can send a zero initial scale.
            if (!isnan (_volumeScale.initialPinchScale))
            {
                _volumeScale.currentScale = [gestureRecognizer scale] * _volumeScale.initialPinchScale;
                
                // Don't let our scale multiplier become absurd
                _volumeScale.currentScale = keepInRange(_volumeScale.currentScale, 0.01, 1000.f);
                
                GLKVector3 newVolumeSize = GLKVector3MultiplyScalar(_options.initVolumeSizeInMeters, _volumeScale.currentScale);
                
                [self adjustVolumeSize:newVolumeSize];
            }
        }
    }
}

#pragma mark - MeshViewController delegates

- (void)meshViewWillDismiss
{
    // If we are running colorize work, we should cancel it.
    if (_naiveColorizeTask)
    {
        [_naiveColorizeTask cancel];
        _naiveColorizeTask = nil;
    }
    if (_enhancedColorizeTask)
    {
        [_enhancedColorizeTask cancel];
        _enhancedColorizeTask = nil;
    }
    
    [_meshViewController hideMeshViewerMessage];
}

- (void)meshViewDidDismiss
{
    _appStatus.statusMessageDisabled = false;
    [self updateAppStatusMessage];
    
    // Reset the tracker, mapper, etc.
    [self resetSLAM];
    [self enterCubePlacementState];
}

- (void)backgroundTask:(STBackgroundTask *)sender didUpdateProgress:(double)progress
{
    if (sender == _naiveColorizeTask)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->_meshViewController showMeshViewerMessage:[NSString stringWithFormat:@"Processing: % 3d%%", int(progress*20)]];
        });
    }
    else if (sender == _enhancedColorizeTask)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->_meshViewController showMeshViewerMessage:[NSString stringWithFormat:@"Processing: % 3d%%", int(progress*80)+20]];
        });
    }
}

- (BOOL)meshViewDidRequestColorizing:(STMesh*)mesh previewCompletionHandler:(void (^)())previewCompletionHandler enhancedCompletionHandler:(void (^)())enhancedCompletionHandler
{
    if (_naiveColorizeTask) // already one running?
    {
        NSLog(@"Already one colorizing task running!");
        return FALSE;
    }

    _naiveColorizeTask = [STColorizer
                     newColorizeTaskWithMesh:mesh
                     scene:_slamState.scene
                     keyframes:[_slamState.keyFrameManager getKeyFrames]
                     completionHandler: ^(NSError *error)
                     {
                         if (error != nil) {
                             NSLog(@"Error during colorizing: %@", [error localizedDescription]);
                         }
                         else
                         {
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 previewCompletionHandler();
                                 self->_meshViewController.mesh = mesh;
                                 [self performEnhancedColorize:(STMesh*)mesh enhancedCompletionHandler:enhancedCompletionHandler];
                             });
                             self->_naiveColorizeTask = nil;
                         }
                     }
                     options:@{kSTColorizerTypeKey: @(STColorizerPerVertex),
                               kSTColorizerPrioritizeFirstFrameColorKey: @(_options.prioritizeFirstFrameColor)}
                     error:nil];
    
    if (_naiveColorizeTask)
    {
        // Release the tracking and mapping resources. It will not be possible to resume a scan after this point
        [_slamState.mapper reset];
        [_slamState.tracker reset];
    
        _naiveColorizeTask.delegate = self;
        [_naiveColorizeTask start];
        return TRUE;
    }
    
    return FALSE;
}

- (void)performEnhancedColorize:(STMesh*)mesh enhancedCompletionHandler:(void (^)())enhancedCompletionHandler
{
    _enhancedColorizeTask =[STColorizer
       newColorizeTaskWithMesh:mesh
       scene:_slamState.scene
       keyframes:[_slamState.keyFrameManager getKeyFrames]
       completionHandler: ^(NSError *error)
       {
           if (error != nil) {
               NSLog(@"Error during colorizing: %@", [error localizedDescription]);
           }
           else
           {
               dispatch_async(dispatch_get_main_queue(), ^{
                   enhancedCompletionHandler();
                   self->_meshViewController.mesh = mesh;
               });
               self->_enhancedColorizeTask = nil;
           }
       }
       options:@{kSTColorizerTypeKey: @(STColorizerTextureMapForObject),
                 kSTColorizerPrioritizeFirstFrameColorKey: @(_options.prioritizeFirstFrameColor),
                 kSTColorizerQualityKey: @(_options.colorizerQuality),
                 kSTColorizerTargetNumberOfFacesKey: @(_options.colorizerTargetNumFaces)} // 20k faces is enough for most objects.
       error:nil];
    
    if (_enhancedColorizeTask)
    {
        // We don't need the keyframes anymore now that the final colorizing task was started.
        // Clearing it now gives a chance to early release the keyframe memory when the colorizer
        // stops needing them.
        [_slamState.keyFrameManager clear];
        
        _enhancedColorizeTask.delegate = self;
        [_enhancedColorizeTask start];
    }
}


- (void) respondToMemoryWarning
{
    switch( _slamState.scannerState )
    {
        case ScannerStateViewing:
        {
            // If we are running a colorizing task, abort it
            if( _enhancedColorizeTask != nil && !_slamState.showingMemoryWarning )
            {
                _slamState.showingMemoryWarning = true;
                
                // stop the task
                [_enhancedColorizeTask cancel];
                _enhancedColorizeTask = nil;
                
                // hide progress bar
                [_meshViewController hideMeshViewerMessage];
                
                UIAlertController *alertCtrl= [UIAlertController alertControllerWithTitle:@"Memory Low"
                                                                                  message:@"Colorizing was canceled."
                                                                           preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK"
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction *action)
                                           {
                                               self->_slamState.showingMemoryWarning = false;
                                           }];
                
                [alertCtrl addAction:okAction];
                
                // show the alert in the meshViewController
                [_meshViewController presentViewController:alertCtrl animated:YES completion:nil];
            }
            
            break;
        }
        case ScannerStateScanning:
        {
            if( !_slamState.showingMemoryWarning )
            {
                _slamState.showingMemoryWarning = true;
                
                UIAlertController *alertCtrl= [UIAlertController alertControllerWithTitle:@"Memory Low"
                                                                                  message:@"Scanning will be stopped to avoid loss."
                                                                           preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK"
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction *action)
                                           {
                                               self->_slamState.showingMemoryWarning = false;
                                               [self enterViewingState];
                                           }];
                
                
                [alertCtrl addAction:okAction];
                
                // show the alert
                [self presentViewController:alertCtrl animated:YES completion:nil];
            }
            
            break;
        }
        default:
        {
            // not much we can do here
        }
    }
}
@end
