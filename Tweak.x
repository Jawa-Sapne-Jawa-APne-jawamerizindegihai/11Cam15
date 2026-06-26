#import <UIKit/UIKit.h>

// Viewfinder UI
%hook CAMViewfinderViewController
-(BOOL)_shouldUseZoomControlInsteadOfSlider {
    return YES;
}
%end

// Core Capabilities (All Modern Features)
%hook CAMCaptureCapabilities

// UI & Zoom Controls
-(bool)isZoomPlatterSupported { return YES; }
-(long long)zoomDialStyle { return 1; }
-(bool)allowDynamicShutterZoom { return TRUE; } //TESTED
-(bool)isExposureSliderSupported { return YES; }
-(bool)sfCameraFontSupported { return YES; }

// QuickTake & Live Text
-(bool)isCTMSupported { return YES; }
-(bool)isCTMSupportSupressed { return NO; }
-(bool)deviceSupportsCTM { return YES; }
-(bool)isLivePhotoAutoModeSupported { return TRUE; } //TESTED
-(bool)isImageAnalysisSupported { return TRUE; }  //TESTED
-(bool)isImageAnalysisButtonAlwaysVisible { return TRUE; }  //TESTED

// Over Capture (Spatial View Outside the Frame)
-(bool)isSpatialOverCaptureSupported { return TRUE; }   //TESTED
-(bool)isBackSpatialOverCaptureSupported { return TRUE; }  //TESTED

// Video Formats & Framerates (Up to 4K60 & 1080p240)
-(bool)isBack4k24VideoSupported { return YES; }
-(bool)isBack4k30VideoSupported { return YES; }
-(bool)isBack4k60VideoSupported { return YES; }
-(bool)isBack1080p240Supported { return YES; }
-(long long)back1080pMaxFPS { return 240; }
// -(long long)frontHighFrameRate1080pMaxFPS { return 60; }
// -(long long)backHighFrameRate1080pMaxFPS { return 240; }


-(bool)isQuickVideoConfigurationSupported { return YES; }
-(bool)isQuickVideoConfigurationSupportedForMode:(long long)arg1 device:(long long)arg2 { return YES; }
-(bool)interactiveVideoFormatControlSupported { return YES; }
-(bool)interactiveVideoFormatControlAlwaysEnabled { return YES; }

// Cinematic Mode, ProRes, HDR10 Video
-(bool)isCinematicModeSupported { return YES; }
-(bool)cinematic4KSupported { return FALSE; }
-(bool)isProResVideoSupported { return YES; }
-(bool)isProResVideoSupportedForMode:(long long)arg1 videoConfiguration:(long long)arg2 { return YES; }
-(bool)isHDR10BitVideoSupported { return YES; }
-(bool)isHDR10BitVideoSupports60FPS { return FALSE; }
-(bool)isHDR10BitVideoSupportedForVideoConfiguration:(long long)arg1 videoEncodingBehavior:(long long)arg2 { return YES; }


-(bool)isLinearDNGSupported { return YES; }
-(bool)enhancedRAWResolutionSupported { return YES; }
-(bool)enhancedHEICResolutionSupported { return YES; }
-(bool)isSuperWideAutoMacroSupported { return TRUE; }  //TESTED


%end


%hook CameraSettingsController
-(bool)isLinearDNGSupported { return YES; }
-(bool)_isMacroControlEnabled:(id)arg1 { return YES; }
%end


%hook CAMCaptureController
-(bool)_shouldSuppressPortraitModeForHardwareConfiguration { return NO; }
-(bool)_isSoftwarePortraitModeSupported { return YES; }
-(bool)_isMonocularPortraitModeSupported { return YES; }
%end


%hook CAMPortraitModeManager
-(bool)isLightingEffectAvailable:(long long)effectIndex { return YES; }
-(bool)isLightingEffectLivePreviewAvailable:(long long)effectIndex { return YES; }
-(long long)defaultLightingEffect { return 1; }
%end


%hook CAMPortraitViewController
-(bool)shouldShowLightingEffectPicker { return YES; }
-(bool)shouldShowApertureControl { return YES; }
-(bool)shouldShowLightingIntensityControl { return YES; }
%end


%hook CAMUserPreferences
-(bool)shouldUseVolumeUpBurst { return YES; } 
-(bool)isPhotoOverCaptureEnabled { return TRUE; }  //TESTED
-(bool)isOverCapturePreviewEnabled { return TRUE; }  //TESTED
-(bool)isImageAnalysisEnabled { return TRUE; }  //TESTED
%end


