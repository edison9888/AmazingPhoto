#import "ShowcaseFilterViewController.h"
#import <CoreImage/CoreImage.h>
#import <AssetsLibrary/AssetsLibrary.h>

#define DIAL_OFFSET_X               10
#define DIAL_OFFSET_Y               0
#define DIAL_WIDTH                  300
#define DIAL_HEIGHT                 40

@interface ShowcaseFilterViewController()
-(void)initEffectList;
@end

@implementation ShowcaseFilterViewController
@synthesize faceDetector;

#pragma dealloc
-(void)dealloc
{
    [mEffectsListData release];
    [super dealloc];
}
#pragma mark -
#pragma mark Initialization and teardown

- (IBAction)takePhoto:(id)sender;
{
    [photoCaptureButton setEnabled:NO];
    
    [videoCamera capturePhotoAsJPEGProcessedUpToFilter:filter withCompletionHandler:^(NSData *processedJPEG, NSError *error){
        
        // Save to assets library
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        //        report_memory(@"After asset library creation");
        
        [library writeImageDataToSavedPhotosAlbum:processedJPEG metadata:nil completionBlock:^(NSURL *assetURL, NSError *error2)
         {
             //             report_memory(@"After writing to library");
             if (error2) {
                 NSLog(@"ERROR: the image failed to be written");
             }
             else {
                 NSLog(@"PHOTO SAVED - assetURL: %@", assetURL);
             }
			 
             runOnMainQueueWithoutDeadlocking(^{
                 //                 report_memory(@"Operation completed");
                 [photoCaptureButton setEnabled:YES];
             });
         }];
    }];
}

- (void)loadView 
{
	CGRect mainScreenFrame = [[UIScreen mainScreen] bounds];
    
    // Yes, I know I'm a caveman for doing all this by hand
	GPUImageView *primaryView = [[GPUImageView alloc] initWithFrame:mainScreenFrame];
	primaryView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    
    photoCaptureButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    photoCaptureButton.frame = CGRectMake(round(mainScreenFrame.size.width / 2.0 - 150.0 / 2.0), mainScreenFrame.size.height - 90.0, 150.0, 40.0);
    [photoCaptureButton setTitle:@"Capture Photo" forState:UIControlStateNormal];
	photoCaptureButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [photoCaptureButton addTarget:self action:@selector(takePhoto:) forControlEvents:UIControlEventTouchUpInside];
    [photoCaptureButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    
    [primaryView addSubview:photoCaptureButton];
    
    [self initEffectList];
    
    defaultPickerView = [[CPPickerView alloc] initWithFrame:CGRectMake(DIAL_OFFSET_X, DIAL_OFFSET_Y, DIAL_WIDTH, DIAL_HEIGHT)];
    defaultPickerView.backgroundColor = [UIColor whiteColor];
    defaultPickerView.dataSource = self;
    defaultPickerView.delegate = self;
    [defaultPickerView reloadData];
    [primaryView addSubview:defaultPickerView];
    [defaultPickerView release];
    
	self.view = primaryView;	
}
-(void)initEffectList
{
    mEffectsListData= [[NSArray alloc] initWithObjects:@"Saturation",@"Contrast",@"Brightness",@"Exposure",@"RGB",@"Hue", @"Monochrome",@"False color",@"Sharpen",@"Unsharp mask",@"Gamma",@"Tone curve",@"Highlights and shadows",@"Haze",@"Histogram",@"Threshold",@"Adaptive threshold", @"Crop",@"Transform (2-D)",@"Transform (3-D)",@"Mask",@"Color invert",@"Grayscale",@"Sepia tone",@"Miss Etikate (Lookup)",@"Soft elegance (Lookup)",@"Amatorka (Lookup)",@"Pixellate",@"Polar pixellate",@"Polka dot",@"Crosshatch",@"Sobel edge detection",@"Prewitt edge detection",@"Canny edge detection",@"XY derivative",@"Harris corner detection",@"Noble corner detection",@"Shi-Tomasi feature detection",@"Image buffer",@"Sketch",@"Toon",@"Smooth toon",@"Tilt shift",@"CGA colorspace",@"3x3 convolution",@"Emboss",@"Posterize",@"Swirl",@"Bulge",@"Sphere refraction",@"Glass sphere",@"Pinch",@"Stretch",@"Dilation",@"Erosion",@"Opening",@"Closing",@"Perlin noise",@"Voroni",@"Mosaic",@"Local binary pattern",@"Chroma key (green)",@"Dissolve blend",@"Screen blend",@"Color burn blend",@"Color dodge blend",@"Add blend",@"Divide blend",@"Multiply blend",@"Overlay blend",@"Lighten blend",@"Darken blend",@"Exclusion blend",@"Difference blend",@"Subtract blend",@"Hard light blend",@"Soft light blend",@"Opacity adjustment",@"Kuwahara",@"Vignette",@"Gaussian blur",@"Fast blur",@"Median (3x3)",@"Bilateral blur",@"Box blur",@"Gaussian selective blur",@"UI element",@"Custom",@"Filter Chain",@"Filter Group",@"Face Detection",nil];
}
- (id)initWithFilterType:(GPUImageShowcaseFilterType)newFilterType;
{
    self = [super initWithNibName:@"ShowcaseFilterViewController" bundle:nil];
    if (self) 
    {
        filterType = newFilterType;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([GPUImageOpenGLESContext supportsFastTextureUpload])
    {
        NSDictionary *detectorOptions = [[NSDictionary alloc] initWithObjectsAndKeys:CIDetectorAccuracyLow, CIDetectorAccuracy, nil];
        self.faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
        faceThinking = NO;
    }
    
    [self setupFilter];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // Note: I needed to stop camera capture before the view went off the screen in order to prevent a crash from the camera still sending frames
    [videoCamera stopCameraCapture];
    
	[super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)setupFilter
{
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    //    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    facesSwitch.hidden = YES;
    facesLabel.hidden = YES;
    BOOL needsSecondImage = NO;
    
    switch (filterType)
    {
        case GPUIMAGE_SEPIA:
        {
            self.title = @"Sepia Tone";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:1.0];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            
            filter = [[GPUImageSepiaFilter alloc] init];
        }; break;
        case GPUIMAGE_PIXELLATE:
        {
            self.title = @"Pixellate";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:0.05];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:0.3];
            
            filter = [[GPUImagePixellateFilter alloc] init];
        }; break;
        case GPUIMAGE_POLARPIXELLATE:
        {
            self.title = @"Polar Pixellate";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:0.05];
            [self.filterSettingsSlider setMinimumValue:-0.1];
            [self.filterSettingsSlider setMaximumValue:0.1];
            
            filter = [[GPUImagePolarPixellateFilter alloc] init];
        }; break;
        case GPUIMAGE_POLKADOT:
        {
            self.title = @"Polka Dot";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:0.05];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:0.3];
            
            filter = [[GPUImagePolkaDotFilter alloc] init];
        }; break;
        case GPUIMAGE_CROSSHATCH:
        {
            self.title = @"Crosshatch";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:0.03];
            [self.filterSettingsSlider setMinimumValue:0.01];
            [self.filterSettingsSlider setMaximumValue:0.06];
            
            filter = [[GPUImageCrosshatchFilter alloc] init];
        }; break;
        case GPUIMAGE_COLORINVERT:
        {
            self.title = @"Color Invert";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageColorInvertFilter alloc] init];
        }; break;
        case GPUIMAGE_GRAYSCALE:
        {
            self.title = @"Grayscale";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageGrayscaleFilter alloc] init];
        }; break;
        case GPUIMAGE_MONOCHROME:
        {
            self.title = @"Monochrome";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:1.0];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            
            filter = [[GPUImageMonochromeFilter alloc] init];
            [(GPUImageMonochromeFilter *)filter setColor:(GPUVector4){0.0f, 0.0f, 1.0f, 1.f}];
        }; break;
        case GPUIMAGE_FALSECOLOR:
        {
            self.title = @"False Color";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageFalseColorFilter alloc] init];
		}; break;
        case GPUIMAGE_SOFTELEGANCE:
        {
            self.title = @"Soft Elegance (Lookup)";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageSoftEleganceFilter alloc] init];
        }; break;
        case GPUIMAGE_MISSETIKATE:
        {
            self.title = @"Miss Etikate (Lookup)";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageMissEtikateFilter alloc] init];
        }; break;
        case GPUIMAGE_AMATORKA:
        {
            self.title = @"Amatorka (Lookup)";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageAmatorkaFilter alloc] init];
        }; break;
            
        case GPUIMAGE_SATURATION:
        {
            self.title = @"Saturation";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:1.0];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:2.0];
            
            filter = [[GPUImageSaturationFilter alloc] init];
        }; break;
        case GPUIMAGE_CONTRAST:
        {
            self.title = @"Contrast";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:4.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageContrastFilter alloc] init];
        }; break;
        case GPUIMAGE_BRIGHTNESS:
        {
            self.title = @"Brightness";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:-1.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.0];
            
            filter = [[GPUImageBrightnessFilter alloc] init];
        }; break;
        case GPUIMAGE_RGB:
        {
            self.title = @"RGB";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:2.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageRGBFilter alloc] init];
        }; break;
        case GPUIMAGE_HUE:
        {
            self.title = @"Hue";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:360.0];
            [self.filterSettingsSlider setValue:90.0];
            
            filter = [[GPUImageHueFilter alloc] init];
        }; break;
        case GPUIMAGE_EXPOSURE:
        {
            self.title = @"Exposure";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:-4.0];
            [self.filterSettingsSlider setMaximumValue:4.0];
            [self.filterSettingsSlider setValue:0.0];
            
            filter = [[GPUImageExposureFilter alloc] init];
        }; break;
        case GPUIMAGE_SHARPEN:
        {
            self.title = @"Sharpen";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:-1.0];
            [self.filterSettingsSlider setMaximumValue:4.0];
            [self.filterSettingsSlider setValue:0.0];
            
            filter = [[GPUImageSharpenFilter alloc] init];
        }; break;
        case GPUIMAGE_UNSHARPMASK:
        {
            self.title = @"Unsharp Mask";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:5.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageUnsharpMaskFilter alloc] init];
            
            //            [(GPUImageUnsharpMaskFilter *)filter setIntensity:3.0];
        }; break;
        case GPUIMAGE_GAMMA:
        {
            self.title = @"Gamma";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:3.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageGammaFilter alloc] init];
        }; break;
        case GPUIMAGE_TONECURVE:
        {
            self.title = @"Tone curve";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.5];
            
            filter = [[GPUImageToneCurveFilter alloc] init];
            [(GPUImageToneCurveFilter *)filter setBlueControlPoints:[NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(0.0, 0.0)], [NSValue valueWithCGPoint:CGPointMake(0.5, 0.5)], [NSValue valueWithCGPoint:CGPointMake(1.0, 0.75)], nil]];
        }; break;
        case GPUIMAGE_HIGHLIGHTSHADOW:
        {
            self.title = @"Highlights and Shadows";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:1.0];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            
            filter = [[GPUImageHighlightShadowFilter alloc] init];
        }; break;
		case GPUIMAGE_HAZE:
        {
            self.title = @"Haze / UV";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:-0.2];
            [self.filterSettingsSlider setMaximumValue:0.2];
            [self.filterSettingsSlider setValue:0.2];
            
            filter = [[GPUImageHazeFilter alloc] init];
        }; break;
		case GPUIMAGE_HISTOGRAM:
        {
            self.title = @"Histogram";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:4.0];
            [self.filterSettingsSlider setMaximumValue:32.0];
            [self.filterSettingsSlider setValue:16.0];
            
            filter = [[GPUImageHistogramFilter alloc] initWithHistogramType:kGPUImageHistogramRGB];
        }; break;
		case GPUIMAGE_THRESHOLD:
        {
            self.title = @"Luminance Threshold";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.5];
            
            filter = [[GPUImageLuminanceThresholdFilter alloc] init];
        }; break;
		case GPUIMAGE_ADAPTIVETHRESHOLD:
        {
            self.title = @"Adaptive Threshold";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:1.0];
            [self.filterSettingsSlider setMaximumValue:20.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageAdaptiveThresholdFilter alloc] init];
        }; break;
        case GPUIMAGE_CROP:
        {
            self.title = @"Crop";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.2];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.5];
            
            filter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.0, 0.0, 1.0, 0.25)];
        }; break;
		case GPUIMAGE_MASK:
		{
            self.title = @"Mask";
            self.filterSettingsSlider.hidden = YES;
            needsSecondImage = YES;	
            
            filter = [[GPUImageMaskFilter alloc] init];
			
			[(GPUImageFilter*)filter setBackgroundColorRed:0.0 green:1.0 blue:0.0 alpha:1.0];
        }; break;
        case GPUIMAGE_TRANSFORM:
        {
            self.title = @"Transform (2-D)";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:6.28];
            [self.filterSettingsSlider setValue:2.0];
            
            filter = [[GPUImageTransformFilter alloc] init];
            [(GPUImageTransformFilter *)filter setAffineTransform:CGAffineTransformMakeRotation(2.0)];
            //            [(GPUImageTransformFilter *)filter setIgnoreAspectRatio:YES];
        }; break;
        case GPUIMAGE_TRANSFORM3D:
        {
            self.title = @"Transform (3-D)";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:6.28];
            [self.filterSettingsSlider setValue:0.75];
            
            filter = [[GPUImageTransformFilter alloc] init];
            CATransform3D perspectiveTransform = CATransform3DIdentity;
            perspectiveTransform.m34 = 0.4;
            perspectiveTransform.m33 = 0.4;
            perspectiveTransform = CATransform3DScale(perspectiveTransform, 0.75, 0.75, 0.75);
            perspectiveTransform = CATransform3DRotate(perspectiveTransform, 0.75, 0.0, 1.0, 0.0);
            
            [(GPUImageTransformFilter *)filter setTransform3D:perspectiveTransform];
		}; break;
        case GPUIMAGE_SOBELEDGEDETECTION:
        {
            self.title = @"Sobel Edge Detection";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageSobelEdgeDetectionFilter alloc] init];
        }; break;
        case GPUIMAGE_XYGRADIENT:
        {
            self.title = @"XY Derivative";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageXYDerivativeFilter alloc] init];
        }; break;
        case GPUIMAGE_HARRISCORNERDETECTION:
        {
            self.title = @"Harris Corner Detection";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.01];
            [self.filterSettingsSlider setMaximumValue:0.70];
            [self.filterSettingsSlider setValue:0.20];
            
            filter = [[GPUImageHarrisCornerDetectionFilter alloc] init];
            [(GPUImageHarrisCornerDetectionFilter *)filter setThreshold:0.20];            
        }; break;
        case GPUIMAGE_NOBLECORNERDETECTION:
        {
            self.title = @"Noble Corner Detection";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.01];
            [self.filterSettingsSlider setMaximumValue:0.70];
            [self.filterSettingsSlider setValue:0.20];
            
            filter = [[GPUImageNobleCornerDetectionFilter alloc] init];
            [(GPUImageNobleCornerDetectionFilter *)filter setThreshold:0.20];            
        }; break;
        case GPUIMAGE_SHITOMASIFEATUREDETECTION:
        {
            self.title = @"Shi-Tomasi Feature Detection";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.01];
            [self.filterSettingsSlider setMaximumValue:0.70];
            [self.filterSettingsSlider setValue:0.20];
            
            filter = [[GPUImageShiTomasiFeatureDetectionFilter alloc] init];
            [(GPUImageShiTomasiFeatureDetectionFilter *)filter setThreshold:0.20];            
        }; break;
        case GPUIMAGE_PREWITTEDGEDETECTION:
        {
            self.title = @"Prewitt Edge Detection";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImagePrewittEdgeDetectionFilter alloc] init];
        }; break;
        case GPUIMAGE_CANNYEDGEDETECTION:
        {
            self.title = @"Canny Edge Detection";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:1.0];
            
            //            [self.filterSettingsSlider setMinimumValue:0.0];
            //            [self.filterSettingsSlider setMaximumValue:0.5];
            //            [self.filterSettingsSlider setValue:0.1];
            
            filter = [[GPUImageCannyEdgeDetectionFilter alloc] init];
        }; break;
        case GPUIMAGE_LOCALBINARYPATTERN:
        {
            self.title = @"Local Binary Pattern";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:1.0];
            [self.filterSettingsSlider setMaximumValue:5.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageLocalBinaryPatternFilter alloc] init];
        }; break;
        case GPUIMAGE_BUFFER:
        {
            self.title = @"Image Buffer";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageBuffer alloc] init];
        }; break;
        case GPUIMAGE_SKETCH:
        {
            self.title = @"Sketch";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageSketchFilter alloc] init];
        }; break;
        case GPUIMAGE_TOON:
        {
            self.title = @"Toon";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageToonFilter alloc] init];
        }; break;            
        case GPUIMAGE_SMOOTHTOON:
        {
            self.title = @"Smooth Toon";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.5];
            
            filter = [[GPUImageSmoothToonFilter alloc] init];
        }; break;            
        case GPUIMAGE_TILTSHIFT:
        {
            self.title = @"Tilt Shift";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.2];
            [self.filterSettingsSlider setMaximumValue:0.8];
            [self.filterSettingsSlider setValue:0.5];
            
            filter = [[GPUImageTiltShiftFilter alloc] init];
            [(GPUImageTiltShiftFilter *)filter setTopFocusLevel:0.4];
            [(GPUImageTiltShiftFilter *)filter setBottomFocusLevel:0.6];
            [(GPUImageTiltShiftFilter *)filter setFocusFallOffRate:0.2];
        }; break;
        case GPUIMAGE_CGA:
        {
            self.title = @"CGA Colorspace";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageCGAColorspaceFilter alloc] init];
        }; break;
        case GPUIMAGE_CONVOLUTION:
        {
            self.title = @"3x3 Convolution";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImage3x3ConvolutionFilter alloc] init];
            //            [(GPUImage3x3ConvolutionFilter *)filter setConvolutionKernel:(GPUMatrix3x3){
            //                {-2.0f, -1.0f, 0.0f},
            //                {-1.0f,  1.0f, 1.0f},
            //                { 0.0f,  1.0f, 2.0f}
            //            }];
            [(GPUImage3x3ConvolutionFilter *)filter setConvolutionKernel:(GPUMatrix3x3){
                {-1.0f,  0.0f, 1.0f},
                {-2.0f, 0.0f, 2.0f},
                {-1.0f,  0.0f, 1.0f}
            }];
            
            //            [(GPUImage3x3ConvolutionFilter *)filter setConvolutionKernel:(GPUMatrix3x3){
            //                {1.0f,  1.0f, 1.0f},
            //                {1.0f, -8.0f, 1.0f},
            //                {1.0f,  1.0f, 1.0f}
            //            }];
            //            [(GPUImage3x3ConvolutionFilter *)filter setConvolutionKernel:(GPUMatrix3x3){
            //                { 0.11f,  0.11f, 0.11f},
            //                { 0.11f,  0.11f, 0.11f},
            //                { 0.11f,  0.11f, 0.11f}
            //            }];
        }; break;
        case GPUIMAGE_EMBOSS:
        {
            self.title = @"Emboss";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:5.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageEmbossFilter alloc] init];
        }; break;
        case GPUIMAGE_POSTERIZE:
        {
            self.title = @"Posterize";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:1.0];
            [self.filterSettingsSlider setMaximumValue:20.0];
            [self.filterSettingsSlider setValue:10.0];
            
            filter = [[GPUImagePosterizeFilter alloc] init];
        }; break;
        case GPUIMAGE_SWIRL:
        {
            self.title = @"Swirl";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:2.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageSwirlFilter alloc] init];
        }; break;
        case GPUIMAGE_BULGE:
        {
            self.title = @"Bulge";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:-1.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.5];
            
            filter = [[GPUImageBulgeDistortionFilter alloc] init];
        }; break;
        case GPUIMAGE_SPHEREREFRACTION:
        {
            self.title = @"Sphere Refraction";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.15];
            
            filter = [[GPUImageSphereRefractionFilter alloc] init];
            [(GPUImageSphereRefractionFilter *)filter setRadius:0.15];
        }; break;
        case GPUIMAGE_GLASSSPHERE:
        {
            self.title = @"Glass Sphere";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.15];
            
            filter = [[GPUImageGlassSphereFilter alloc] init];
            [(GPUImageGlassSphereFilter *)filter setRadius:0.15];
        }; break;
        case GPUIMAGE_PINCH:
        {
            self.title = @"Pinch";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:-2.0];
            [self.filterSettingsSlider setMaximumValue:2.0];
            [self.filterSettingsSlider setValue:0.5];
            
            filter = [[GPUImagePinchDistortionFilter alloc] init];
        }; break;
        case GPUIMAGE_STRETCH:
        {
            self.title = @"Stretch";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageStretchDistortionFilter alloc] init];
        }; break;
        case GPUIMAGE_DILATION:
        {
            self.title = @"Dilation";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageRGBDilationFilter alloc] initWithRadius:4];
		}; break;
        case GPUIMAGE_EROSION:
        {
            self.title = @"Erosion";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageRGBErosionFilter alloc] initWithRadius:4];
		}; break;
        case GPUIMAGE_OPENING:
        {
            self.title = @"Opening";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageRGBOpeningFilter alloc] initWithRadius:4];
		}; break;
        case GPUIMAGE_CLOSING:
        {
            self.title = @"Closing";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageRGBClosingFilter alloc] initWithRadius:4];
		}; break;
            
        case GPUIMAGE_PERLINNOISE:
        {
            self.title = @"Perlin Noise";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:1.0];
            [self.filterSettingsSlider setMaximumValue:30.0];
            [self.filterSettingsSlider setValue:8.0];
            
            filter = [[GPUImagePerlinNoiseFilter alloc] init];
        }; break;
        case GPUIMAGE_VORONI: 
        {
            self.title = @"Voroni";
            self.filterSettingsSlider.hidden = YES;
            
            GPUImageJFAVoroniFilter *jfa = [[GPUImageJFAVoroniFilter alloc] init];
            [jfa setSizeInPixels:CGSizeMake(1024.0, 1024.0)];
            
            sourcePicture = [[GPUImagePicture alloc] initWithImage:[UIImage imageNamed:@"voroni_points2.png"]];
            
            [sourcePicture addTarget:jfa];
            
            filter = [[GPUImageVoroniConsumerFilter alloc] init];
            
            [jfa setSizeInPixels:CGSizeMake(1024.0, 1024.0)];
            [(GPUImageVoroniConsumerFilter *)filter setSizeInPixels:CGSizeMake(1024.0, 1024.0)];
            
            [videoCamera addTarget:filter];
            [jfa addTarget:filter];
            [sourcePicture processImage];
        }; break;
        case GPUIMAGE_MOSAIC:
        {
            self.title = @"Mosaic";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.002];
            [self.filterSettingsSlider setMaximumValue:0.05];
            [self.filterSettingsSlider setValue:0.025];
            
            filter = [[GPUImageMosaicFilter alloc] init];
            [(GPUImageMosaicFilter *)filter setTileSet:@"squares.png"];
            [(GPUImageMosaicFilter *)filter setColorOn:NO];
            //[(GPUImageMosaicFilter *)filter setTileSet:@"dotletterstiles.png"];
            //[(GPUImageMosaicFilter *)filter setTileSet:@"curvies.png"]; 
            
            [filter setInputRotation:kGPUImageRotateRight atIndex:0];
            
        }; break;
        case GPUIMAGE_CHROMAKEY:
        {
            self.title = @"Chroma Key (Green)";
            self.filterSettingsSlider.hidden = NO;
            needsSecondImage = YES;	
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.4];
            
            filter = [[GPUImageChromaKeyBlendFilter alloc] init];
            [(GPUImageChromaKeyBlendFilter *)filter setColorToReplaceRed:0.0 green:1.0 blue:0.0];
        }; break;
        case GPUIMAGE_ADD:
        {
            self.title = @"Add Blend";
            self.filterSettingsSlider.hidden = YES;
            needsSecondImage = YES;
            
            filter = [[GPUImageAddBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_DIVIDE:
        {
            self.title = @"Divide Blend";
            self.filterSettingsSlider.hidden = YES;
            needsSecondImage = YES;
            
            filter = [[GPUImageDivideBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_MULTIPLY:
        {
            self.title = @"Multiply Blend";
            self.filterSettingsSlider.hidden = YES;
            needsSecondImage = YES;	
            
            filter = [[GPUImageMultiplyBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_OVERLAY:
        {
            self.title = @"Overlay Blend";
            self.filterSettingsSlider.hidden = YES;
            needsSecondImage = YES;	
            
            filter = [[GPUImageOverlayBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_LIGHTEN:
        {
            self.title = @"Lighten Blend";
            self.filterSettingsSlider.hidden = YES;
            needsSecondImage = YES;	
            
            filter = [[GPUImageLightenBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_DARKEN:
        {
            self.title = @"Darken Blend";
            self.filterSettingsSlider.hidden = YES;
            
            needsSecondImage = YES;	
            filter = [[GPUImageDarkenBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_DISSOLVE:
        {
            self.title = @"Dissolve Blend";
            self.filterSettingsSlider.hidden = NO;
            needsSecondImage = YES;	
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.5];
            
            filter = [[GPUImageDissolveBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_SCREENBLEND:
        {
            self.title = @"Screen Blend";
            self.filterSettingsSlider.hidden = YES;
            needsSecondImage = YES;	
            
            filter = [[GPUImageScreenBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_COLORBURN:
        {
            self.title = @"Color Burn Blend";
            self.filterSettingsSlider.hidden = YES;
            needsSecondImage = YES;	
            
            filter = [[GPUImageColorBurnBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_COLORDODGE:
        {
            self.title = @"Color Dodge Blend";
            self.filterSettingsSlider.hidden = YES;
            needsSecondImage = YES;	
            
            filter = [[GPUImageColorDodgeBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_EXCLUSIONBLEND:
        {
            self.title = @"Exclusion Blend";
            self.filterSettingsSlider.hidden = YES;
            needsSecondImage = YES;	
            
            filter = [[GPUImageExclusionBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_DIFFERENCEBLEND:
        {
            self.title = @"Difference Blend";
            self.filterSettingsSlider.hidden = YES;
            needsSecondImage = YES;	
            
            filter = [[GPUImageDifferenceBlendFilter alloc] init];
        }; break;
		case GPUIMAGE_SUBTRACTBLEND:
        {
            self.title = @"Subtract Blend";
            self.filterSettingsSlider.hidden = YES;
            needsSecondImage = YES;	
            
            filter = [[GPUImageSubtractBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_HARDLIGHTBLEND:
        {
            self.title = @"Hard Light Blend";
            self.filterSettingsSlider.hidden = YES;
            needsSecondImage = YES;	
            
            filter = [[GPUImageHardLightBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_SOFTLIGHTBLEND:
        {
            self.title = @"Soft Light Blend";
            self.filterSettingsSlider.hidden = YES;
            needsSecondImage = YES;	
            
            filter = [[GPUImageSoftLightBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_OPACITY:
        {
            self.title = @"Opacity Adjustment";
            self.filterSettingsSlider.hidden = NO;
            needsSecondImage = YES;	
            
            [self.filterSettingsSlider setValue:1.0];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            
            filter = [[GPUImageOpacityFilter alloc] init];
        }; break;
        case GPUIMAGE_CUSTOM:
        {
            self.title = @"Custom";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageFilter alloc] initWithFragmentShaderFromFile:@"CustomFilter"];
        }; break;
        case GPUIMAGE_KUWAHARA:
        {
            self.title = @"Kuwahara";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:3.0];
            [self.filterSettingsSlider setMaximumValue:8.0];
            [self.filterSettingsSlider setValue:3.0];
            
            filter = [[GPUImageKuwaharaFilter alloc] init];
        }; break;
            
        case GPUIMAGE_VIGNETTE:
        {
            self.title = @"Vignette";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.5];
            [self.filterSettingsSlider setMaximumValue:0.9];
            [self.filterSettingsSlider setValue:0.75];
            
            filter = [[GPUImageVignetteFilter alloc] init];
        }; break;
        case GPUIMAGE_GAUSSIAN:
        {
            self.title = @"Gaussian Blur";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:10.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageGaussianBlurFilter alloc] init];
        }; break;
        case GPUIMAGE_FASTBLUR:
        {
            self.title = @"Fast Blur";
            self.filterSettingsSlider.hidden = NO;
            [self.filterSettingsSlider setMinimumValue:1.0];
            [self.filterSettingsSlider setMaximumValue:10.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageFastBlurFilter alloc] init];
		}; break;
        case GPUIMAGE_BOXBLUR:
        {
            self.title = @"Box Blur";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageBoxBlurFilter alloc] init];
		}; break;
        case GPUIMAGE_MEDIAN:
        {
            self.title = @"Median";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageMedianFilter alloc] init];
		}; break;
        case GPUIMAGE_UIELEMENT:
        {
            self.title = @"UI Element";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageSepiaFilter alloc] init];
		}; break;
        case GPUIMAGE_GAUSSIAN_SELECTIVE:
        {
            self.title = @"Selective Blur";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:.75f];
            [self.filterSettingsSlider setValue:40.0/320.0];
            
            filter = [[GPUImageGaussianSelectiveBlurFilter alloc] init];
            [(GPUImageGaussianSelectiveBlurFilter*)filter setExcludeCircleRadius:40.0/320.0];
        }; break;
        case GPUIMAGE_BILATERAL:
        {
            self.title = @"Bilateral Blur";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:10.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageBilateralFilter alloc] init];
        }; break;
        case GPUIMAGE_FILTERGROUP:
        {
            self.title = @"Filter Group";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:0.05];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:0.3];
            
            filter = [[GPUImageFilterGroup alloc] init];
            
            GPUImageSepiaFilter *sepiaFilter = [[GPUImageSepiaFilter alloc] init];
            [(GPUImageFilterGroup *)filter addFilter:sepiaFilter];
            
            GPUImagePixellateFilter *pixellateFilter = [[GPUImagePixellateFilter alloc] init];
            [(GPUImageFilterGroup *)filter addFilter:pixellateFilter];
            
            [sepiaFilter addTarget:pixellateFilter];
            [(GPUImageFilterGroup *)filter setInitialFilters:[NSArray arrayWithObject:sepiaFilter]];
            [(GPUImageFilterGroup *)filter setTerminalFilter:pixellateFilter];
        }; break;
            
        case GPUIMAGE_FACES:
        {
            facesSwitch.hidden = NO;
            facesLabel.hidden = NO;
            
            [videoCamera rotateCamera];
            self.title = @"Face Detection";
            self.filterSettingsSlider.hidden = YES;
            
            [self.filterSettingsSlider setValue:1.0];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:2.0];
            
            filter = [[GPUImageSaturationFilter alloc] init];
            [videoCamera setDelegate:self];
            break;
        }
            
        default: filter = [[GPUImageSepiaFilter alloc] init]; break;
    }
    
    if (filterType == GPUIMAGE_FILECONFIG) 
    {
        self.title = @"File Configuration";
        pipeline = [[GPUImageFilterPipeline alloc] initWithConfigurationFile:[[NSBundle mainBundle] URLForResource:@"SampleConfiguration" withExtension:@"plist"]
                                                                       input:videoCamera output:(GPUImageView*)self.view];
        
        //        [pipeline addFilter:rotationFilter atIndex:0];
    } 
    else 
    {
        
        if (filterType != GPUIMAGE_VORONI) 
        {
            [videoCamera addTarget:filter];
        }
        
        videoCamera.runBenchmark = YES;
        GPUImageView *filterView = (GPUImageView *)self.view;
        
        if (needsSecondImage)
        {
			UIImage *inputImage;
			
			if (filterType == GPUIMAGE_MASK) 
			{
				inputImage = [UIImage imageNamed:@"mask"];
			}
            /*
             else if (filterType == GPUIMAGE_VORONI) {
             inputImage = [UIImage imageNamed:@"voroni_points.png"];
             }*/
            else {
				// The picture is only used for two-image blend filters
				inputImage = [UIImage imageNamed:@"WID-small.jpg"];
			}
			
            sourcePicture = [[GPUImagePicture alloc] initWithImage:inputImage smoothlyScaleOutput:YES];
            [sourcePicture processImage];            
            [sourcePicture addTarget:filter];
        }
        
        
        if (filterType == GPUIMAGE_HISTOGRAM)
        {
            // I'm adding an intermediary filter because glReadPixels() requires something to be rendered for its glReadPixels() operation to work
            [videoCamera removeTarget:filter];
            GPUImageGammaFilter *gammaFilter = [[GPUImageGammaFilter alloc] init];
            [videoCamera addTarget:gammaFilter];
            [gammaFilter addTarget:filter];
            
            GPUImageHistogramGenerator *histogramGraph = [[GPUImageHistogramGenerator alloc] init];
            
            [histogramGraph forceProcessingAtSize:CGSizeMake(256.0, 330.0)];
            [filter addTarget:histogramGraph];
            
            GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
            blendFilter.mix = 0.75;            
            [blendFilter forceProcessingAtSize:CGSizeMake(256.0, 330.0)];
            
            [videoCamera addTarget:blendFilter];
            [histogramGraph addTarget:blendFilter];
            
            [blendFilter addTarget:filterView];
        }
        else if ( (filterType == GPUIMAGE_HARRISCORNERDETECTION) || (filterType == GPUIMAGE_NOBLECORNERDETECTION) || (filterType == GPUIMAGE_SHITOMASIFEATUREDETECTION) )
        {
            GPUImageCrosshairGenerator *crosshairGenerator = [[GPUImageCrosshairGenerator alloc] init];
            crosshairGenerator.crosshairWidth = 15.0;
            [crosshairGenerator forceProcessingAtSize:CGSizeMake(480.0, 640.0)];
            
            [(GPUImageHarrisCornerDetectionFilter *)filter setCornersDetectedBlock:^(GLfloat* cornerArray, NSUInteger cornersDetected, CMTime frameTime) {
                [crosshairGenerator renderCrosshairsFromArray:cornerArray count:cornersDetected frameTime:frameTime];
            }];
            
            GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
            [blendFilter forceProcessingAtSize:CGSizeMake(480.0, 640.0)];
            GPUImageGammaFilter *gammaFilter = [[GPUImageGammaFilter alloc] init];
            [videoCamera addTarget:gammaFilter];
            [gammaFilter addTarget:blendFilter];
            
            [crosshairGenerator addTarget:blendFilter];
            
            [blendFilter addTarget:filterView];
        }
        else if (filterType == GPUIMAGE_UIELEMENT)
        {
            GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
            blendFilter.mix = 1.0;
            
            NSDate *startTime = [NSDate date];
            
            UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 240.0f, 320.0f)];
            timeLabel.font = [UIFont systemFontOfSize:17.0f];
            timeLabel.text = @"Time: 0.0 s";
            timeLabel.textAlignment = UITextAlignmentCenter;
            timeLabel.backgroundColor = [UIColor clearColor];
            timeLabel.textColor = [UIColor whiteColor];
            
            uiElementInput = [[GPUImageUIElement alloc] initWithView:timeLabel];
            
            [filter addTarget:blendFilter];
            [uiElementInput addTarget:blendFilter];
            
            [blendFilter addTarget:filterView];
            
            __unsafe_unretained GPUImageUIElement *weakUIElementInput = uiElementInput;
            
            [filter setFrameProcessingCompletionBlock:^(GPUImageOutput * filter, CMTime frameTime){
                timeLabel.text = [NSString stringWithFormat:@"Time: %f s", -[startTime timeIntervalSinceNow]];
                [weakUIElementInput update];
            }];
        }
        else if (filterType == GPUIMAGE_BUFFER)
        {
            
            GPUImageDifferenceBlendFilter *blendFilter = [[GPUImageDifferenceBlendFilter alloc] init];
            
            [videoCamera removeTarget:filter];
            
            GPUImageGammaFilter *gammaFilter = [[GPUImageGammaFilter alloc] init];
            [videoCamera addTarget:gammaFilter];
            [gammaFilter addTarget:blendFilter];
            [videoCamera addTarget:filter];
            
            [filter addTarget:blendFilter];
            
            [blendFilter addTarget:filterView];
        }
        else if (filterType == GPUIMAGE_OPACITY)
        {
            [sourcePicture removeTarget:filter];
            [videoCamera removeTarget:filter];
            [videoCamera addTarget:filter];
            
            GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
            blendFilter.mix = 1.0;
            [sourcePicture addTarget:blendFilter];
            [filter addTarget:blendFilter];
            
            [blendFilter addTarget:filterView];
        }
        else if ( (filterType == GPUIMAGE_SPHEREREFRACTION) || (filterType == GPUIMAGE_GLASSSPHERE) )
        {
            // Provide a blurred image for a cool-looking background
            GPUImageGaussianBlurFilter *gaussianBlur = [[GPUImageGaussianBlurFilter alloc] init];
            [videoCamera addTarget:gaussianBlur];
            gaussianBlur.blurSize = 2.0;
            
            GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
            blendFilter.mix = 1.0;
            [gaussianBlur addTarget:blendFilter];
            [filter addTarget:blendFilter];
            
            [blendFilter addTarget:filterView];
            
        }
        else 
        {
            [filter addTarget:filterView];
            
        }
    } 
    
    [videoCamera startCameraCapture];
}

#pragma mark -
#pragma mark Filter adjustments

- (IBAction)updateFilterFromSlider:(id)sender;
{
    switch(filterType)
    {
        case GPUIMAGE_SEPIA: [(GPUImageSepiaFilter *)filter setIntensity:[(UISlider *)sender value]]; break;
        case GPUIMAGE_PIXELLATE: [(GPUImagePixellateFilter *)filter setFractionalWidthOfAPixel:[(UISlider *)sender value]]; break;
        case GPUIMAGE_POLARPIXELLATE: [(GPUImagePolarPixellateFilter *)filter setPixelSize:CGSizeMake([(UISlider *)sender value], [(UISlider *)sender value])]; break;
        case GPUIMAGE_POLKADOT: [(GPUImagePolkaDotFilter *)filter setFractionalWidthOfAPixel:[(UISlider *)sender value]]; break;
        case GPUIMAGE_SATURATION: [(GPUImageSaturationFilter *)filter setSaturation:[(UISlider *)sender value]]; break;
        case GPUIMAGE_CONTRAST: [(GPUImageContrastFilter *)filter setContrast:[(UISlider *)sender value]]; break;
        case GPUIMAGE_BRIGHTNESS: [(GPUImageBrightnessFilter *)filter setBrightness:[(UISlider *)sender value]]; break;
        case GPUIMAGE_EXPOSURE: [(GPUImageExposureFilter *)filter setExposure:[(UISlider *)sender value]]; break;
        case GPUIMAGE_MONOCHROME: [(GPUImageMonochromeFilter *)filter setIntensity:[(UISlider *)sender value]]; break;
        case GPUIMAGE_RGB: [(GPUImageRGBFilter *)filter setGreen:[(UISlider *)sender value]]; break;
        case GPUIMAGE_HUE: [(GPUImageHueFilter *)filter setHue:[(UISlider *)sender value]]; break;
        case GPUIMAGE_SHARPEN: [(GPUImageSharpenFilter *)filter setSharpness:[(UISlider *)sender value]]; break;
        case GPUIMAGE_HISTOGRAM: [(GPUImageHistogramFilter *)filter setDownsamplingFactor:round([(UISlider *)sender value])]; break;
        case GPUIMAGE_UNSHARPMASK: [(GPUImageUnsharpMaskFilter *)filter setIntensity:[(UISlider *)sender value]]; break;
            //        case GPUIMAGE_UNSHARPMASK: [(GPUImageUnsharpMaskFilter *)filter setBlurSize:[(UISlider *)sender value]]; break;
        case GPUIMAGE_GAMMA: [(GPUImageGammaFilter *)filter setGamma:[(UISlider *)sender value]]; break;
        case GPUIMAGE_CROSSHATCH: [(GPUImageCrosshatchFilter *)filter setCrossHatchSpacing:[(UISlider *)sender value]]; break;
        case GPUIMAGE_POSTERIZE: [(GPUImagePosterizeFilter *)filter setColorLevels:round([(UISlider*)sender value])]; break;
        case GPUIMAGE_HAZE: [(GPUImageHazeFilter *)filter setDistance:[(UISlider *)sender value]]; break;
        case GPUIMAGE_THRESHOLD: [(GPUImageLuminanceThresholdFilter *)filter setThreshold:[(UISlider *)sender value]]; break;
        case GPUIMAGE_ADAPTIVETHRESHOLD: [(GPUImageAdaptiveThresholdFilter *)filter setBlurSize:[(UISlider*)sender value]]; break;
        case GPUIMAGE_DISSOLVE: [(GPUImageDissolveBlendFilter *)filter setMix:[(UISlider *)sender value]]; break;
        case GPUIMAGE_CHROMAKEY: [(GPUImageChromaKeyBlendFilter *)filter setThresholdSensitivity:[(UISlider *)sender value]]; break;
        case GPUIMAGE_KUWAHARA: [(GPUImageKuwaharaFilter *)filter setRadius:round([(UISlider *)sender value])]; break;
        case GPUIMAGE_SWIRL: [(GPUImageSwirlFilter *)filter setAngle:[(UISlider *)sender value]]; break;
        case GPUIMAGE_EMBOSS: [(GPUImageEmbossFilter *)filter setIntensity:[(UISlider *)sender value]]; break;
        case GPUIMAGE_CANNYEDGEDETECTION: [(GPUImageCannyEdgeDetectionFilter *)filter setBlurSize:[(UISlider*)sender value]]; break;
            //        case GPUIMAGE_CANNYEDGEDETECTION: [(GPUImageCannyEdgeDetectionFilter *)filter setLowerThreshold:[(UISlider*)sender value]]; break;
        case GPUIMAGE_HARRISCORNERDETECTION: [(GPUImageHarrisCornerDetectionFilter *)filter setThreshold:[(UISlider*)sender value]]; break;
        case GPUIMAGE_NOBLECORNERDETECTION: [(GPUImageNobleCornerDetectionFilter *)filter setThreshold:[(UISlider*)sender value]]; break;
        case GPUIMAGE_SHITOMASIFEATUREDETECTION: [(GPUImageShiTomasiFeatureDetectionFilter *)filter setThreshold:[(UISlider*)sender value]]; break;
            //        case GPUIMAGE_HARRISCORNERDETECTION: [(GPUImageHarrisCornerDetectionFilter *)filter setSensitivity:[(UISlider*)sender value]]; break;
        case GPUIMAGE_SMOOTHTOON: [(GPUImageSmoothToonFilter *)filter setBlurSize:[(UISlider*)sender value]]; break;
            //        case GPUIMAGE_BULGE: [(GPUImageBulgeDistortionFilter *)filter setRadius:[(UISlider *)sender value]]; break;
        case GPUIMAGE_BULGE: [(GPUImageBulgeDistortionFilter *)filter setScale:[(UISlider *)sender value]]; break;
        case GPUIMAGE_SPHEREREFRACTION: [(GPUImageSphereRefractionFilter *)filter setRadius:[(UISlider *)sender value]]; break;
        case GPUIMAGE_GLASSSPHERE: [(GPUImageGlassSphereFilter *)filter setRadius:[(UISlider *)sender value]]; break;
        case GPUIMAGE_TONECURVE: [(GPUImageToneCurveFilter *)filter setBlueControlPoints:[NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(0.0, 0.0)], [NSValue valueWithCGPoint:CGPointMake(0.5, [(UISlider *)sender value])], [NSValue valueWithCGPoint:CGPointMake(1.0, 0.75)], nil]]; break;
        case GPUIMAGE_HIGHLIGHTSHADOW: [(GPUImageHighlightShadowFilter *)filter setHighlights:[(UISlider *)sender value]]; break;
        case GPUIMAGE_PINCH: [(GPUImagePinchDistortionFilter *)filter setScale:[(UISlider *)sender value]]; break;
        case GPUIMAGE_PERLINNOISE:  [(GPUImagePerlinNoiseFilter *)filter setScale:[(UISlider *)sender value]]; break;
        case GPUIMAGE_MOSAIC:  [(GPUImageMosaicFilter *)filter setDisplayTileSize:CGSizeMake([(UISlider *)sender value], [(UISlider *)sender value])]; break;
        case GPUIMAGE_VIGNETTE: [(GPUImageVignetteFilter *)filter setVignetteEnd:[(UISlider *)sender value]]; break;
        case GPUIMAGE_GAUSSIAN: [(GPUImageGaussianBlurFilter *)filter setBlurSize:[(UISlider*)sender value]]; break;
        case GPUIMAGE_BILATERAL: [(GPUImageBilateralFilter *)filter setBlurSize:[(UISlider*)sender value]]; break;
        case GPUIMAGE_FASTBLUR: [(GPUImageFastBlurFilter *)filter setBlurPasses:round([(UISlider*)sender value])]; break;
            //        case GPUIMAGE_FASTBLUR: [(GPUImageFastBlurFilter *)filter setBlurSize:[(UISlider*)sender value]]; break;
        case GPUIMAGE_OPACITY:  [(GPUImageOpacityFilter *)filter setOpacity:[(UISlider *)sender value]]; break;
        case GPUIMAGE_GAUSSIAN_SELECTIVE: [(GPUImageGaussianSelectiveBlurFilter *)filter setExcludeCircleRadius:[(UISlider*)sender value]]; break;
        case GPUIMAGE_FILTERGROUP: [(GPUImagePixellateFilter *)[(GPUImageFilterGroup *)filter filterAtIndex:1] setFractionalWidthOfAPixel:[(UISlider *)sender value]]; break;
        case GPUIMAGE_CROP: [(GPUImageCropFilter *)filter setCropRegion:CGRectMake(0.0, 0.0, 1.0, [(UISlider*)sender value])]; break;
        case GPUIMAGE_TRANSFORM: [(GPUImageTransformFilter *)filter setAffineTransform:CGAffineTransformMakeRotation([(UISlider*)sender value])]; break;
        case GPUIMAGE_TRANSFORM3D:
        {
            CATransform3D perspectiveTransform = CATransform3DIdentity;
            perspectiveTransform.m34 = 0.4;
            perspectiveTransform.m33 = 0.4;
            perspectiveTransform = CATransform3DScale(perspectiveTransform, 0.75, 0.75, 0.75);
            perspectiveTransform = CATransform3DRotate(perspectiveTransform, [(UISlider*)sender value], 0.0, 1.0, 0.0);
            
            [(GPUImageTransformFilter *)filter setTransform3D:perspectiveTransform];            
        }; break;
        case GPUIMAGE_TILTSHIFT:
        {
            CGFloat midpoint = [(UISlider *)sender value];
            [(GPUImageTiltShiftFilter *)filter setTopFocusLevel:midpoint - 0.1];
            [(GPUImageTiltShiftFilter *)filter setBottomFocusLevel:midpoint + 0.1];
        }; break;
        case GPUIMAGE_LOCALBINARYPATTERN:
        {
            CGFloat multiplier = [(UISlider *)sender value];
            [(GPUImageLocalBinaryPatternFilter *)filter setTexelWidth:(multiplier / self.view.bounds.size.width)];
            [(GPUImageLocalBinaryPatternFilter *)filter setTexelHeight:(multiplier / self.view.bounds.size.height)];
        }; break;
        default: break;
    }
}

#pragma mark - Face Detection Delegate Callback
- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    if (!faceThinking) {
        CFAllocatorRef allocator = CFAllocatorGetDefault();
        CMSampleBufferRef sbufCopyOut;
        CMSampleBufferCreateCopy(allocator,sampleBuffer,&sbufCopyOut);
        [self performSelectorInBackground:@selector(grepFacesForSampleBuffer:) withObject:CFBridgingRelease(sbufCopyOut)];
    }
}

- (void)grepFacesForSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    faceThinking = TRUE;
    NSLog(@"Faces thinking");
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
	CIImage *convertedImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(__bridge NSDictionary *)attachments];
    
	if (attachments)
		CFRelease(attachments);
	NSDictionary *imageOptions = nil;
	UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
	int exifOrientation;
	
    /* kCGImagePropertyOrientation values
     The intended display orientation of the image. If present, this key is a CFNumber value with the same value as defined
     by the TIFF and EXIF specifications -- see enumeration of integer constants.
     The value specified where the origin (0,0) of the image is located. If not present, a value of 1 is assumed.
     
     used when calling featuresInImage: options: The value for this key is an integer NSNumber from 1..8 as found in kCGImagePropertyOrientation.
     If present, the detection will be done based on that orientation but the coordinates in the returned features will still be based on those of the image. */
    
	enum {
		PHOTOS_EXIF_0ROW_TOP_0COL_LEFT			= 1, //   1  =  0th row is at the top, and 0th column is on the left (THE DEFAULT).
		PHOTOS_EXIF_0ROW_TOP_0COL_RIGHT			= 2, //   2  =  0th row is at the top, and 0th column is on the right.
		PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT      = 3, //   3  =  0th row is at the bottom, and 0th column is on the right.
		PHOTOS_EXIF_0ROW_BOTTOM_0COL_LEFT       = 4, //   4  =  0th row is at the bottom, and 0th column is on the left.
		PHOTOS_EXIF_0ROW_LEFT_0COL_TOP          = 5, //   5  =  0th row is on the left, and 0th column is the top.
		PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP         = 6, //   6  =  0th row is on the right, and 0th column is the top.
		PHOTOS_EXIF_0ROW_RIGHT_0COL_BOTTOM      = 7, //   7  =  0th row is on the right, and 0th column is the bottom.
		PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM       = 8  //   8  =  0th row is on the left, and 0th column is the bottom.
	};
	BOOL isUsingFrontFacingCamera = FALSE;
    AVCaptureDevicePosition currentCameraPosition = [videoCamera cameraPosition];
    
    if (currentCameraPosition != AVCaptureDevicePositionBack)
    {
        isUsingFrontFacingCamera = TRUE;
    }
    
	switch (curDeviceOrientation) {
		case UIDeviceOrientationPortraitUpsideDown:  // Device oriented vertically, home button on the top
			exifOrientation = PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM;
			break;
		case UIDeviceOrientationLandscapeLeft:       // Device oriented horizontally, home button on the right
			if (isUsingFrontFacingCamera)
				exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
			else
				exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
			break;
		case UIDeviceOrientationLandscapeRight:      // Device oriented horizontally, home button on the left
			if (isUsingFrontFacingCamera)
				exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
			else
				exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
			break;
		case UIDeviceOrientationPortrait:            // Device oriented vertically, home button on the bottom
		default:
			exifOrientation = PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP;
			break;
	}
    
	imageOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:exifOrientation] forKey:CIDetectorImageOrientation];
    
    NSLog(@"Face Detector %@", [self.faceDetector description]);
    NSLog(@"converted Image %@", [convertedImage description]);
    NSArray *features = [self.faceDetector featuresInImage:convertedImage options:imageOptions];
    
    
    // get the clean aperture
    // the clean aperture is a rectangle that defines the portion of the encoded pixel dimensions
    // that represents image data valid for display.
    CMFormatDescriptionRef fdesc = CMSampleBufferGetFormatDescription(sampleBuffer);
    CGRect clap = CMVideoFormatDescriptionGetCleanAperture(fdesc, false /*originIsTopLeft == false*/);
    
    
    [self GPUVCWillOutputFeatures:features forClap:clap andOrientation:curDeviceOrientation];
    faceThinking = FALSE;
    
}

- (void)GPUVCWillOutputFeatures:(NSArray*)featureArray forClap:(CGRect)clap
                 andOrientation:(UIDeviceOrientation)curDeviceOrientation
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Did receive array");
        
        CGRect previewBox = self.view.frame;
        
        if (featureArray == nil && faceView) {
            [faceView removeFromSuperview];
            faceView = nil;
        }
        
        
        for ( CIFaceFeature *faceFeature in featureArray) {
            
            // find the correct position for the square layer within the previewLayer
            // the feature box originates in the bottom left of the video frame.
            // (Bottom right if mirroring is turned on)
            NSLog(@"%@", NSStringFromCGRect([faceFeature bounds]));
            
            //Update face bounds for iOS Coordinate System
            CGRect faceRect = [faceFeature bounds];
            
            // flip preview width and height
            CGFloat temp = faceRect.size.width;
            faceRect.size.width = faceRect.size.height;
            faceRect.size.height = temp;
            temp = faceRect.origin.x;
            faceRect.origin.x = faceRect.origin.y;
            faceRect.origin.y = temp;
            // scale coordinates so they fit in the preview box, which may be scaled
            CGFloat widthScaleBy = previewBox.size.width / clap.size.height;
            CGFloat heightScaleBy = previewBox.size.height / clap.size.width;
            faceRect.size.width *= widthScaleBy;
            faceRect.size.height *= heightScaleBy;
            faceRect.origin.x *= widthScaleBy;
            faceRect.origin.y *= heightScaleBy;
            
            faceRect = CGRectOffset(faceRect, previewBox.origin.x, previewBox.origin.y);
            
            if (faceView) {
                [faceView removeFromSuperview];
                faceView =  nil;
            }
            
            // create a UIView using the bounds of the face
            faceView = [[UIView alloc] initWithFrame:faceRect];
            
            // add a border around the newly created UIView
            faceView.layer.borderWidth = 1;
            faceView.layer.borderColor = [[UIColor redColor] CGColor];
            
            // add the new view to create a box around the face
            [self.view addSubview:faceView];
            
        }
    });
    
}

-(IBAction)facesSwitched:(UISwitch*)sender{
    if (![sender isOn]) {
        [videoCamera setDelegate:nil];
        if (faceView) {
            [faceView removeFromSuperview];
            faceView = nil;
        }
    }else{
        [videoCamera setDelegate:self];
        
    }
}


#pragma mark - CPPickerViewDataSource

- (NSInteger)numberOfItemsInPickerView:(CPPickerView *)pickerView
{
    return [mEffectsListData count];
}
- (NSString *)pickerView:(CPPickerView *)pickerView titleForItem:(NSInteger)item
{
    return [mEffectsListData objectAtIndex:item];//[NSString stringWithFormat:@"%i", item + 1];
}

#pragma mark - CPPickerViewDelegate

- (void)pickerView:(CPPickerView *)pickerView didSelectItem:(NSInteger)item
{
}

#pragma mark -
#pragma mark Accessors

@synthesize filterSettingsSlider = _filterSettingsSlider;

@end
