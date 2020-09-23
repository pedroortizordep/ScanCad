/*
 This file is part of the Structure SDK.
 Copyright © 2019 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#pragma once

#import <Foundation/Foundation.h>
#import <Structure/STCaptureSession+Types.h>
#import <UIKit/UIKit.h>

@protocol SettingsPopupViewDelegate

- (void) streamingSettingsDidChange:(BOOL)highResolutionColorEnabled
                     streamVGADepth:(BOOL)vgaDepthEnabled
              depthStreamPresetMode:(STCaptureSessionPreset)depthStreamPresetMode;

- (void) streamingPropertiesDidChange:(BOOL)irAutoExposureEnabled
                irManualExposureValue:(float)irManualExposureValue
                    irAnalogGainValue:(STCaptureSessionSensorAnalogGainMode)irAnalogGainValue;

- (void) trackerSettingsDidChange:(BOOL)rgbdTrackingEnabled
           improvedTrackerEnabled:(BOOL)improvedTrackerEnabled;

- (void) mapperSettingsDidChange:(BOOL)highResolutionMeshEnabled
           improvedMapperEnabled:(BOOL)improvedMapperEnabled;

@end

@interface SettingsPopupView : UIView

- (instancetype) initWithSettingsPopupViewDelegate:(id<SettingsPopupViewDelegate>)delegate;
- (void) enableAllSettingsDuringCubePlacement;
- (void) disableNonDynamicSettingsDuringScanning;

@end
