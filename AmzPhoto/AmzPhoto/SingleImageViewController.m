//
//  ViewController.m
//  CoreImage
//
//  Created by  on 11-11-13.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "SingleImageViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface SingleImageViewController()

@property (strong, nonatomic) CIContext *context;
@property (strong, nonatomic) CIFilter *filter;
@property (strong, nonatomic) CIFilter *filter2;
@property (strong, nonatomic) CIFilter *filter3;
@property (retain, nonatomic) CIImage *beginImage;
@property (assign, nonatomic) UIImage *mImage;
- (void)logAllFilters;

@end

@implementation SingleImageViewController

@synthesize imgV;
@synthesize slider;
@synthesize slider2;
@synthesize slider3;
@synthesize context;
@synthesize filter;
@synthesize filter2;
@synthesize filter3;
@synthesize beginImage;
@synthesize mImage;
@synthesize youkuMenuView;
-(void)dealloc
{
    [youkuMenuView release];
    self.mImage = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle
-(id)initWithImage:(UIImage*)image
{
    if (self = [super initWithNibName:@"SingleImageViewController" bundle:nil]) {
        beginImage = [CIImage imageWithCGImage:image.CGImage];
        mImage = [[UIImage alloc]initWithCGImage:image.CGImage];
    }
    return self;
}
- (void)viewDidUnload
{
    [self setImgV:nil];
    [self setSlider:nil];
    self.context = nil;
    self.filter = nil;
    self.filter2 = nil;
    self.filter3 = nil;
    self.beginImage = nil;
    [self setSlider2:nil];
    [self setSlider3:nil];
    [super viewDidUnload];
}

- (void)showMenu:(id)sender
{
    if([youkuMenuView getisMenuHide])
    {
        [youkuMenuView  showOrHideMenu];
    }
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    // 打印所有过滤器信息
    [self logAllFilters];
    
    // 得到图片路径创建CIImage对象
    //NSString *filePath = [[NSBundle mainBundle] pathForResource:@"image" ofType:@"png"];
    //NSURL *fileNameAndPath = [NSURL fileURLWithPath:filePath];
    //beginImage = [CIImage imageWithContentsOfURL:fileNameAndPath];
    
    // 创建基于GPU的CIContext对象
    context = [CIContext contextWithOptions: nil];
    
    // 创建基于CPU的CIContext对象
    //context = [CIContext contextWithOptions: [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:kCIContextUseSoftwareRenderer]];
    
    // 创建过滤器
    filter = [CIFilter filterWithName:@"CISepiaTone"];
    filter2 = [CIFilter filterWithName:@"CIHueAdjust"];
    filter3 = [CIFilter filterWithName:@"CIStraightenFilter"];
    
    // 设置界面
    self.slider.value = 0.0;
    self.slider2.minimumValue = -3.14;
    self.slider2.maximumValue = 3.14;
    self.slider2.value = 0.0;
    self.slider3.minimumValue = -3.14;
    self.slider3.maximumValue = 3.14;
    self.slider3.value = 0.0;
    self.imgV.image = mImage;
    NSLog(@"image:%@",self.imgV.image);
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *image = [UIImage imageNamed:@"hidemenu.png"];
    button.frame = CGRectMake(0.0,self.view.frame.size.height - 16, 320,17);
    [button setBackgroundImage:image forState:UIControlStateNormal];
    [button addTarget:self action:@selector(showMenu:) forControlEvents:UIControlEventTouchDown];
    button.tag = 111;
    [self.view addSubview:button];
        
    youkuMenuView = [[HHYoukuMenuView alloc]initWithFrame:[HHYoukuMenuView getFrame]];
    [youkuMenuView setDelegate:self];
    [self.view addSubview:youkuMenuView];
    [youkuMenuView release];
    
}


- (void)logAllFilters {
    NSArray *properties = [CIFilter filterNamesInCategory:
                           kCICategoryBuiltIn];
    NSLog(@"FilterName:\n%@", properties);
    for (NSString *filterName in properties) {
        CIFilter *fltr = [CIFilter filterWithName:filterName];
        NSLog(@"%@:\n%@", filterName, [fltr attributes]);
    }
}

- (IBAction)changeValue:(id)sender 
{
    self.slider2.value = 0.0;
    self.slider3.value = 0.0;
    float slideValue = self.slider.value;
    // 设置过滤器参数
    [filter setValue:beginImage forKey:kCIInputImageKey];
    [filter setValue:[NSNumber numberWithFloat:slideValue] forKey:@"inputIntensity"];

    // 得到过滤后的图片
    CIImage *outputImage = [filter outputImage];
    
    // 转换图片
    CGImageRef cgimg = [context createCGImage:outputImage fromRect:[outputImage extent]];
    UIImage *newImg = [UIImage imageWithCGImage:cgimg];    
    // 显示图片
    [imgV setImage:newImg];
    // 释放C对象
    CGImageRelease(cgimg);

}

- (IBAction)changeValue2:(id)sender 
{
    self.slider.value = 0.0;
    self.slider3.value = 0.0;
    
    float slideValue = self.slider2.value;
    // 设置过滤器参数
    [filter2 setValue:beginImage forKey:kCIInputImageKey];
    [filter2 setValue:[NSNumber numberWithFloat:slideValue] forKey:@"inputAngle"];

    // 得到过滤后的图片
    CIImage *outputImage = [filter2 outputImage];
    // 转换图片
    CGImageRef cgimg = [context createCGImage:outputImage fromRect:[outputImage extent]];
    UIImage *newImg = [UIImage imageWithCGImage:cgimg];    
    // 显示图片
    [imgV setImage:newImg];
    // 释放C对象
    CGImageRelease(cgimg);
}

- (IBAction)changeValue3:(id)sender 
{
    self.slider.value = 0.0;
    self.slider2.value = 0.0;
    
    float slideValue = self.slider3.value;
    // 设置过滤器参数
    [filter3 setValue:beginImage forKey:kCIInputImageKey];
    [filter3 setValue:[NSNumber numberWithFloat:slideValue] forKey:@"inputAngle"];
    
    // 得到过滤后的图片
    CIImage *outputImage = [filter3 outputImage];
    // 转换图片
    CGImageRef cgimg = [context createCGImage:outputImage fromRect:[outputImage extent]];
    UIImage *newImg = [UIImage imageWithCGImage:cgimg];    
    // 显示图片
    [imgV setImage:newImg];
    // 释放C对象
    CGImageRelease(cgimg);
}

- (IBAction)loadPhoto:(id)sender 
{
    UIImagePickerController *pickerC = 
    [[UIImagePickerController alloc] init];
    pickerC.delegate = self;
    [self presentModalViewController:pickerC animated:YES];
}

- (IBAction)savePhoto:(id)sender 
{
    CIImage *saveToSave = [filter outputImage];
    CGImageRef cgImg = [context createCGImage:saveToSave fromRect:[saveToSave extent]];
    
    ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
    [library writeImageToSavedPhotosAlbum:cgImg 
                                 metadata:[saveToSave properties] 
                          completionBlock:^(NSURL *assetURL, NSError *error) {
                              CGImageRelease(cgImg);
                          }];
}

- (IBAction)resetImage:(id)sender 
{
    // 得到图片路径
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"image" ofType:@"png"];
    
    // 创建CIImage对象
    NSURL *fileNameAndPath = [NSURL fileURLWithPath:filePath];
    beginImage = [CIImage imageWithContentsOfURL:fileNameAndPath];
    
    // 设置界面
    self.slider.value = 0.0;
    self.slider2.value = 0.0;
    self.slider3.value = 0.0;
    self.imgV.image = [UIImage imageWithContentsOfFile:filePath];
}

#pragma mark UIImagePickerController Delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info 
{
    [self dismissModalViewControllerAnimated:YES];
    
    UIImage *gotImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    beginImage = [CIImage imageWithCGImage:gotImage.CGImage];
    imgV.image = gotImage;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker 
{
    [self dismissModalViewControllerAnimated:YES];    
}

#pragma mark youkuDelegate
- (void)meunButtonDown:(id)sender
{
    //share by bshare
    shareController.shareType=ShareTypeText;
    shareController=[[SHSShareViewController alloc] initWithRootViewController:self];
    shareController.sharedtitle=@"test";
    shareController.sharedText=@"test";
    //shareController.sharedURL=@"http://www.test.com";
    //shareController.sharedImageURL=@"http://a4.att.hudong.com/74/08/01300000831741129317080840244.jpg";
    shareController.sharedImage=mImage;
    
    shareController.shareType=ShareTypeTextAndImage;
    
    if(UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone)
        [shareController showShareView];
    else
        [shareController showShareViewFromRect:CGRectMake(190, 900, 1, 1)];

    //[self.navigationController popToRootViewControllerAnimated:YES];
}


@end
