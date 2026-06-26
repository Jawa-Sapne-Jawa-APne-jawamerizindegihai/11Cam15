#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Vision/Vision.h>
#import <CoreImage/CoreImage.h>
#import <Photos/Photos.h>
#import <objc/runtime.h>

// =====================================================================
// PART 1 — Existing capability/UI hooks (kept, they're working fine)
// =====================================================================

%hook CAMViewfinderViewController
-(BOOL)_shouldUseZoomControlInsteadOfSlider {
    return TRUE; //TESTED
}
%end

%hook CAMCaptureCapabilities

-(bool)isZoomPlatterSupported { return TRUE; }  //TESTED
-(long long)zoomDialStyle { return 1; }
-(bool)allowDynamicShutterZoom { return TRUE; } //TESTED
-(bool)isExposureSliderSupported { return YES; }
-(bool)sfCameraFontSupported { return YES; }

-(bool)isCTMSupported { return TRUE; }
-(bool)isCTMSupportSupressed { return NO; }
-(bool)deviceSupportsCTM { return FALSE; }
-(bool)isLivePhotoAutoModeSupported { return TRUE; } //TESTED
-(bool)isImageAnalysisSupported { return TRUE; }  //TESTED
-(bool)isImageAnalysisButtonAlwaysVisible { return TRUE; }  //TESTED

-(bool)isSpatialOverCaptureSupported { return TRUE; }   //TESTED
-(bool)isBackSpatialOverCaptureSupported { return TRUE; }  //TESTED

-(bool)isBack4k24VideoSupported { return YES; }
-(bool)isBack4k30VideoSupported { return YES; }
-(bool)isBack4k60VideoSupported { return YES; }
-(bool)isBack1080p240Supported { return YES; }
-(long long)back1080pMaxFPS { return 240; }

-(bool)isQuickVideoConfigurationSupported { return YES; }
-(bool)isQuickVideoConfigurationSupportedForMode:(long long)arg1 device:(long long)arg2 { return YES; }
-(bool)interactiveVideoFormatControlSupported { return YES; }
-(bool)interactiveVideoFormatControlAlwaysEnabled { return YES; }

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

// NOTE: left the native portrait flags returning YES below — they're
// harmless, but on this hardware they don't drive anything functional
// because Apple's monocular depth path needs calibration data the 8
// was never shipped with. The real effect now lives in Part 2.
-(bool)isPortraitModeSupported { return TRUE; }
-(bool)isPortraitModeAvailable { return TRUE; }
-(bool)arePortraitEffectsSupported { return YES; }
-(long long)supportedPortraitLightingVersion { return 2; }
-(long long)numberOfSupportedPortraitLightingEffects { return 6; }
-(bool)isHighKeyPortraitSupported { return YES; }
-(bool)isSoftwareDepthSupported { return YES; }
-(bool)isMonocularDepthSupported { return YES; }

%end

%hook CAMUserPreferences
-(bool)shouldUseVolumeUpBurst { return YES; }
-(bool)isPhotoOverCaptureEnabled { return TRUE; }  //TESTED
-(bool)isOverCapturePreviewEnabled { return TRUE; }  //TESTED
-(bool)isImageAnalysisEnabled { return TRUE; }  //TESTED
%end

%hook AVCaptureDeviceFormat
-(float)minSimulatedAperture { return 1.4; }
-(float)maxSimulatedAperture { return 16; }
-(float)defaultSimulatedAperture { return 4.5; }
-(float)minPortraitLightingEffectStrength { return 0; }
-(float)maxPortraitLightingEffectStrength { return 100; }
-(float)defaultPortraitLightingEffectStrength { return 50; }
%end


// =====================================================================
// PART 2 — PortraitFX: a self-contained synthetic portrait pipeline.
//
// Doesn't touch AVDepthData / Apple's stereo pipeline at all. Flow:
//   1. A floating button injected into the viewfinder lets you arm/
//      disarm FX and cycle the lighting style.
//   2. We watch the Photos library (PHPhotoLibraryChangeObserver —
//      fully public API) for the photo Camera.app is about to save.
//   3. When one lands while FX is armed, we run Vision person
//      segmentation, composite a blur (or stylized background) with
//      CoreImage, and write the result back as a new asset.
//
// This is the same shape PortraitXI uses: post-process + re-save,
// rather than fighting the native capability gate.
// =====================================================================

static BOOL kPortraitFXArmed = NO;
static NSInteger kPortraitFXStyleIndex = 0;
static NSArray<NSString *> *kPortraitFXStyleNames;
static NSMutableSet<NSString *> *kPortraitFXOwnAssetIDs; // assets *we* created — never reprocess these

typedef NS_ENUM(NSInteger, PortraitFXStyle) {
    PortraitFXStyleNatural = 0,
    PortraitFXStyleStudio,
    PortraitFXStyleContour,
    PortraitFXStyleStage,
    PortraitFXStyleStageMono,
    PortraitFXStyleHighKeyMono,
};

@interface PortraitFXEngine : NSObject <PHPhotoLibraryChangeObserver>
+ (instancetype)shared;
- (void)processRecentAssetIfNeeded;
@end

@implementation PortraitFXEngine

+ (instancetype)shared {
    static PortraitFXEngine *s = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [PortraitFXEngine new]; });
    return s;
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    if (!kPortraitFXArmed) return;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [self processRecentAssetIfNeeded];
    });
}

// Finds the most recent photo asset (captured in the last ~10s) that
// we didn't create ourselves, and runs the FX pipeline on it.
- (void)processRecentAssetIfNeeded {
    PHFetchOptions *opts = [PHFetchOptions new];
    opts.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    opts.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeImage];
    opts.fetchLimit = 3;

    PHFetchResult<PHAsset *> *result = [PHAsset fetchAssetsWithOptions:opts];
    [result enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
        if ([kPortraitFXOwnAssetIDs containsObject:asset.localIdentifier]) return;
        NSTimeInterval age = -[asset.creationDate timeIntervalSinceNow];
        if (age > 10.0) { *stop = YES; return; } // too old, not the shot we're after

        static NSMutableSet<NSString *> *inFlight;
        if (!inFlight) inFlight = [NSMutableSet new];
        if ([inFlight containsObject:asset.localIdentifier]) return;
        [inFlight addObject:asset.localIdentifier];

        PHImageRequestOptions *imgOpts = [PHImageRequestOptions new];
        imgOpts.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        imgOpts.networkAccessAllowed = NO;
        imgOpts.synchronous = NO;

        [[PHImageManager defaultManager] requestImageDataAndOrientationForAsset:asset
                                                                          options:imgOpts
                                                                    resultHandler:^(NSData *imageData, NSString *dataUTI, CGImagePropertyOrientation orientation, NSDictionary *info) {
            if (!imageData) { [inFlight removeObject:asset.localIdentifier]; return; }
            CIImage *source = [CIImage imageWithData:imageData options:@{ kCIImageProperties: info ?: @{} }];
            if (!source) { [inFlight removeObject:asset.localIdentifier]; return; }
            source = [source imageByApplyingOrientation:orientation];

            UIImage *finalImage = [self renderPortraitFXForImage:source style:(PortraitFXStyle)kPortraitFXStyleIndex];
            if (finalImage) {
                [self saveProcessedImage:finalImage];
            }
            [inFlight removeObject:asset.localIdentifier];
        }];
        *stop = YES; // only ever process the single newest unprocessed shot
    }];
}

// The actual effect: Vision segmentation + CoreImage compositing.
- (UIImage *)renderPortraitFXForImage:(CIImage *)source style:(PortraitFXStyle)style {
    CGRect extent = source.extent;

    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCIImage:source options:@{}];
    VNGeneratePersonSegmentationRequest *segRequest = [VNGeneratePersonSegmentationRequest new];
    segRequest.qualityLevel = VNGeneratePersonSegmentationRequestQualityLevelAccurate;
    segRequest.outputPixelFormat = kCVPixelFormatType_OneComponent8;

    NSError *error = nil;
    [handler performRequests:@[segRequest] error:&error];
    if (error || segRequest.results.count == 0) return nil;

    VNPixelBufferObservation *maskObs = segRequest.results.firstObject;
    CIImage *mask = [CIImage imageWithCVPixelBuffer:maskObs.pixelBuffer];
    // Mask comes out smaller than source — scale it back up to match.
    CGFloat sx = extent.size.width  / mask.extent.size.width;
    CGFloat sy = extent.size.height / mask.extent.size.height;
    mask = [mask imageByApplyingTransform:CGAffineTransformMakeScale(sx, sy)];

    // Soften the mask edge slightly so the cutout doesn't look pasted-on.
    mask = [mask imageByApplyingFilter:@"CIGaussianBlur" withInputParameters:@{ kCIInputRadiusKey: @1.5 }];

    CIImage *foreground = source;
    CIImage *background;

    switch (style) {
        case PortraitFXStyleStage:
        case PortraitFXStyleStageMono: {
            background = [[CIImage imageWithColor:[CIColor colorWithRed:0 green:0 blue:0]] imageByCroppingToRect:extent];
            break;
        }
        case PortraitFXStyleHighKeyMono: {
            background = [[CIImage imageWithColor:[CIColor colorWithRed:1 green:1 blue:1]] imageByCroppingToRect:extent];
            break;
        }
        default: {
            // Natural / Studio / Contour all use a blurred version of
            // the real background — that part *is* a faithful depth-of-
            // field effect, just driven by a 2D mask instead of stereo depth.
            background = [source imageByApplyingFilter:@"CIGaussianBlur" withInputParameters:@{ kCIInputRadiusKey: @14 }];
            background = [background imageByCroppingToRect:extent]; // blur expands extent, crop back
            break;
        }
    }

    // Style-specific tweaks to the foreground subject.
    switch (style) {
        case PortraitFXStyleStudio: {
            foreground = [foreground imageByApplyingFilter:@"CIExposureAdjust" withInputParameters:@{ @"inputEV": @0.35 }];
            break;
        }
        case PortraitFXStyleContour: {
            foreground = [foreground imageByApplyingFilter:@"CIUnsharpMask" withInputParameters:@{ @"inputRadius": @2.5, @"inputIntensity": @0.6 }];
            foreground = [foreground imageByApplyingFilter:@"CIColorControls" withInputParameters:@{ @"inputContrast": @1.12 }];
            break;
        }
        case PortraitFXStyleStageMono: {
            foreground = [foreground imageByApplyingFilter:@"CIColorControls" withInputParameters:@{ @"inputSaturation": @0.0, @"inputContrast": @1.15 }];
            break;
        }
        case PortraitFXStyleHighKeyMono: {
            foreground = [foreground imageByApplyingFilter:@"CIColorControls" withInputParameters:@{ @"inputSaturation": @0.0, @"inputBrightness": @0.08 }];
            break;
        }
        default: break; // Natural, Stage: no change to the subject itself
    }

    CIFilter *blend = [CIFilter filterWithName:@"CIBlendWithMask"];
    [blend setValue:foreground forKey:kCIInputImageKey];
    [blend setValue:background forKey:kCIInputBackgroundImageKey];
    [blend setValue:mask forKey:kCIInputMaskImageKey];
    CIImage *composited = blend.outputImage ?: foreground;

    static CIContext *ctx;
    if (!ctx) ctx = [CIContext contextWithOptions:nil];
    CGImageRef cg = [ctx createCGImage:composited fromRect:extent];
    if (!cg) return nil;
    UIImage *result = [UIImage imageWithCGImage:cg];
    CGImageRelease(cg);
    return result;
}

- (void)saveProcessedImage:(UIImage *)image {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *req = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        // (intentionally not capturing the placeholder synchronously here —
        // we tag the asset on the next library-change callback instead,
        // see note below)
        (void)req;
    } completionHandler:^(BOOL success, NSError *error) {
        if (!success) return;
        // Re-fetch the newest asset to grab its localIdentifier and mark
        // it as ours so we never try to re-process our own output.
        PHFetchOptions *opts = [PHFetchOptions new];
        opts.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
        opts.fetchLimit = 1;
        PHAsset *newest = [PHAsset fetchAssetsWithOptions:opts].firstObject;
        if (newest) {
            if (!kPortraitFXOwnAssetIDs) kPortraitFXOwnAssetIDs = [NSMutableSet new];
            [kPortraitFXOwnAssetIDs addObject:newest.localIdentifier];
        }
    }];
}

@end


// --- UI: a small floating control on the viewfinder ---

@interface PortraitFXButton : UIButton
@end

%hook CAMViewfinderViewController

- (void)viewDidLoad {
    %orig;

    if (!kPortraitFXStyleNames) {
        kPortraitFXStyleNames = @[@"Natural", @"Studio", @"Contour", @"Stage", @"Stage Mono", @"High-Key Mono"];
    }

    UIButton *toggle = [UIButton buttonWithType:UIButtonTypeSystem];
    toggle.frame = CGRectMake(self.view.bounds.size.width - 96, 60, 88, 32);
    toggle.backgroundColor = [UIColor colorWithWhite:0 alpha:0.45];
    toggle.layer.cornerRadius = 8;
    toggle.tintColor = [UIColor whiteColor];
    [toggle setTitle:@"FX: Off" forState:UIControlStateNormal];
    toggle.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    toggle.tag = 90001;
    [toggle addTarget:self action:@selector(portraitFX_toggleArmed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:toggle];

    UIButton *cycle = [UIButton buttonWithType:UIButtonTypeSystem];
    cycle.frame = CGRectMake(self.view.bounds.size.width - 96, 96, 88, 28);
    cycle.backgroundColor = [UIColor colorWithWhite:0 alpha:0.45];
    cycle.layer.cornerRadius = 8;
    cycle.tintColor = [UIColor whiteColor];
    [cycle setTitle:kPortraitFXStyleNames[kPortraitFXStyleIndex] forState:UIControlStateNormal];
    cycle.titleLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightRegular];
    cycle.tag = 90002;
    [cycle addTarget:self action:@selector(portraitFX_cycleStyle:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cycle];

    [PortraitFXEngine shared]; // force-init, registers as PHPhotoLibrary observer below
}

%new
- (void)portraitFX_toggleArmed:(UIButton *)sender {
    kPortraitFXArmed = !kPortraitFXArmed;
    [sender setTitle:kPortraitFXArmed ? @"FX: On" : @"FX: Off" forState:UIControlStateNormal];
    sender.backgroundColor = kPortraitFXArmed ? [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:0.85]
                                               : [UIColor colorWithWhite:0 alpha:0.45];
}

%new
- (void)portraitFX_cycleStyle:(UIButton *)sender {
    kPortraitFXStyleIndex = (kPortraitFXStyleIndex + 1) % kPortraitFXStyleNames.count;
    [sender setTitle:kPortraitFXStyleNames[kPortraitFXStyleIndex] forState:UIControlStateNormal];
}

%end


%ctor {
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:[PortraitFXEngine shared]];
}
