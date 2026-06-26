#import <UIKit/UIKit.h>


%hook CAMViewfinderViewController
-(BOOL)_shouldUseZoomControlInsteadOfSlider {
    return YES;
}
%end

-(bool)isQuickVideoConfigurationSupported {
    return YES;
}
-(bool)isQuickVideoConfigurationSupportedForMode:(long long)arg1 device:(long long)arg2 {
    return YES;
}

%hook CAMCaptureCapabilities
-(bool)isZoomPlatterSupported                      { return YES; }
-(long long)zoomDialStyle                          { return 1; }
-(bool)allowDynamicShutterZoom                     { return YES; }
-(bool)isCTMSupported                              { return YES; }
-(bool)isCTMSupportSupressed                       { return NO; }
-(bool)deviceSupportsCTM                           { return YES; }
-(bool)sfCameraFontSupported                       { return YES; }
-(bool)isLivePhotoAutoModeSupported                { return YES; }
-(bool)isExposureSliderSupported                   { return YES; }


-(bool)arePortraitEffectsSupported                 { return YES; }
-(long long)supportedPortraitLightingVersion       { return 2; }
-(bool)_backStageLightPortaitEffectsSupported      { return YES; }
-(bool)isBackLiveStageLightSupported               { return YES; }
-(bool)isPortraitEffectIntensitySupported          { return YES; }
-(bool)isLivePreviewSupportedForLightingType:(long long)arg1 devicePosition:(long long)arg2 {
    return YES;
}
-(bool)isDepthEffectApertureSupported              { return YES; }
-(bool)isImageAnalysisSupported                    { return YES; }
-(bool)isImageAnalysisButtonAlwaysVisible          { return YES; }
-(bool)isSpatialOverCaptureSupported               { return YES; }
-(bool)isBackSpatialOverCaptureSupported           { return YES; }
-(bool)isBack4k60VideoSupported                    { return YES; }
-(bool)isBack1080p240Supported                     { return YES; }
-(bool)isBack4k24VideoSupported                    { return YES; }


-(bool)isHighKeyPortraitSupported                  { return YES; }
-(bool)areFrontPortraitEffectsSupported            { return YES; }
-(bool)isFrontLiveStageLightSupported              { return YES; }
-(bool)_frontStageLightPortraitEffectsSupported    { return YES; }
-(bool)isPortraitModeSupported                     { return YES; }
-(bool)isPortraitModeAvailable                     { return YES; }
-(bool)isSoftwareDepthSupported                    { return YES; }
-(bool)isMonocularDepthSupported                   { return YES; }
-(long long)numberOfSupportedPortraitLightingEffects { return 6; }
%end


%hook CAMUserPreferences
-(bool)shouldUseVolumeUpBurst        { return YES; }
-(bool)isPhotoOverCaptureEnabled     { return YES; }
-(bool)isOverCapturePreviewEnabled   { return YES; }
-(bool)isImageAnalysisEnabled        { return YES; }
-(bool)isPortraitModeEnabled         { return YES; }
-(bool)portraitModePersisted         { return YES; }
%end


%hook AVCaptureDeviceFormat
-(float)minSimulatedAperture                  { return 1.4; }
-(float)maxSimulatedAperture                  { return 16; }
-(float)defaultSimulatedAperture              { return 4.5; }
-(float)minPortraitLightingEffectStrength     { return 0; }
-(float)maxPortraitLightingEffectStrength     { return 100; }
-(float)defaultPortraitLightingEffectStrength { return 50; }

-(BOOL)isPortraitEffectsMatteDeliverySupported { return YES; }
-(BOOL)isDepthDataDeliverySupported            { return YES; }
%end


%hook CAMPortraitModeManager
-(bool)isLightingEffectAvailable:(long long)effectIndex {
    return YES;
}
-(bool)isLightingEffectLivePreviewAvailable:(long long)effectIndex {
    return YES;
}
-(long long)defaultLightingEffect {
    return 1; // Default directly to Studio Light layout
}
%end


%hook CAMCaptureController
-(bool)_isSoftwarePortraitModeSupported {
    return YES;
}
-(bool)_isMonocularPortraitModeSupported {
    return YES;
}
-(bool)_shouldSuppressPortraitModeForHardwareConfiguration {
    return NO;
}
%end


%hook CAMPortraitViewController
-(bool)shouldShowLightingEffectPicker {
    return YES;
}
-(bool)shouldShowApertureControl {
    return YES;
}
-(bool)shouldShowLightingIntensityControl {
    return YES;
}
%end
