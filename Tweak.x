// --- Tweak.xm ---
#import <UIKit/UIKit.h>


%hook CAMViewfinderViewController

- (BOOL)_shouldUseZoomControlInsteadOfSlider {
    return YES;
}

%end


%hook CAMCaptureCapabilities


- (bool)isZoomPlatterSupported               { return YES; }
- (long long)zoomDialStyle                   { return 1;   }
- (bool)allowDynamicShutterZoom              { return YES; }
- (bool)isCTMSupported                       { return YES; }
- (bool)isCTMSupportSupressed                { return NO;  }
- (bool)deviceSupportsCTM                    { return YES; }


- (bool)sfCameraFontSupported                { return YES; }
- (bool)isLivePhotoAutoModeSupported         { return YES; }
- (bool)isExposureSliderSupported            { return YES; }


- (bool)isQuickVideoConfigurationSupported   { return YES; }
- (bool)isQuickVideoConfigurationSupportedForMode:(long long)arg1 device:(long long)arg2 {
    return YES;
}


- (bool)arePortraitEffectsSupported          { return YES; }
- (long long)supportedPortraitLightingVersion { return 2;  }
- (bool)_backStageLightPortaitEffectsSupported { return YES; }
- (bool)isBackLiveStageLightSupported        { return YES; }
- (bool)isPortraitEffectIntensitySupported   { return YES; }
- (bool)isLivePreviewSupportedForLightingType:(long long)arg1 devicePosition:(long long)arg2 {
    return YES;
}
- (bool)isDepthEffectApertureSupported       { return YES; }


- (bool)areFrontPortraitEffectsSupported     { return YES; }
- (bool)isFrontLiveStageLightSupported       { return YES; }
- (bool)_frontStageLightPortraitEffectsSupported { return YES; }


- (bool)isSoftwareDepthSupported             { return YES; }
- (bool)isMonocularDepthSupported            { return YES; }
- (bool)isPortraitModeSupported              { return YES; }
- (bool)isPortraitModeAvailable              { return YES; }


- (bool)isHighKeyPortraitSupported           { return YES; }


- (long long)numberOfSupportedPortraitLightingEffects { return 6; }


- (bool)isImageAnalysisSupported             { return YES; }
- (bool)isImageAnalysisButtonAlwaysVisible   { return YES; }
- (bool)isSpatialOverCaptureSupported        { return YES; }
- (bool)isBackSpatialOverCaptureSupported    { return YES; }


- (bool)isBack4k60VideoSupported             { return YES; }
- (bool)isBack1080p240Supported              { return YES; }
- (bool)isBack4k24VideoSupported             { return YES; }

%end


%hook CAMUserPreferences

- (bool)shouldUseVolumeUpBurst           { return YES; }
- (bool)isPhotoOverCaptureEnabled        { return YES; }
- (bool)isOverCapturePreviewEnabled      { return YES; }
- (bool)isImageAnalysisEnabled           { return YES; }
- (bool)isPortraitModeEnabled            { return YES; }
- (bool)portraitModePersisted            { return YES; }

%end


%hook AVCaptureDeviceFormat

- (float)minSimulatedAperture                  { return 1.4f;   }
- (float)maxSimulatedAperture                  { return 16.0f;  }
- (float)defaultSimulatedAperture              { return 4.5f;   }
- (float)minPortraitLightingEffectStrength     { return 0.0f;   }
- (float)maxPortraitLightingEffectStrength     { return 100.0f; }
- (float)defaultPortraitLightingEffectStrength { return 50.0f;  }


- (BOOL)isDepthDataDeliverySupported            { return YES; }
- (BOOL)isPortraitEffectsMatteDeliverySupported { return YES; }

%end


%hook CAMPortraitModeManager

- (bool)isLightingEffectAvailable:(long long)effectIndex {
    return YES;
}
- (bool)isLightingEffectLivePreviewAvailable:(long long)effectIndex {
    return YES;
}
- (long long)defaultLightingEffect {
    return 1; // Studio Light
}

%end


%hook CAMCaptureController

- (bool)_shouldSuppressPortraitModeForHardwareConfiguration {
    return NO;
}

%end


%hook CAMPortraitViewController

- (bool)shouldShowLightingEffectPicker       { return YES; }
- (bool)shouldShowApertureControl            { return YES; }
- (bool)shouldShowLightingIntensityControl   { return YES; }

%end
