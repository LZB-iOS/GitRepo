//
//  PhotosViewController.m
//  NavTest
//
//  Created by 林正波 on 2021/9/14.
//  Copyright © 2021 林正波. All rights reserved.
//

#import "PhotosViewController.h"
//#import <CoreVideo/CoreVideo.h>
//#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>

#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define ScreenHeight [UIScreen mainScreen].bounds.size.height
#define ScaleW(x) 375/[UIScreen mainScreen].bounds.size.width * x

@interface PhotosViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureMetadataOutputObjectsDelegate>

// Camera
//@property (weak, nonatomic) IBOutlet UIImageView* cameraImageView;
//@property (strong, nonatomic) AVCaptureDevice* device;
//@property (strong, nonatomic) AVCaptureSession* captureSession;
//@property (strong, nonatomic) AVCaptureVideoPreviewLayer* previewLayer;
//@property (strong, nonatomic) UIImage* cameraImage;


@property (nonatomic, strong) AVCaptureSession *session;

@property (nonatomic, strong) AVCaptureOutput *videoDataOutput;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;


/// alert
@property (nonatomic, strong) UILabel *tishiLable;

@property (nonatomic, strong) UIView *groundView;


@property (nonatomic, strong) UIButton *faceBtn;
@end

@implementation PhotosViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationItem.title = @"tititii";
    
    self.view.backgroundColor = UIColor.yellowColor;
    
    [self faceDeviceInit];
//    [self setupCamera];
}

-(void)faceDeviceInit {
    NSArray *devices = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront].devices;
    AVCaptureDevice *deviceF = [devices firstObject];
    
    //2.根据输入设备创建输入对象
    AVCaptureDeviceInput*input = [[AVCaptureDeviceInput alloc] initWithDevice:deviceF error:nil];

    //3.创建原数据的输出对象
    AVCaptureMetadataOutput *metaout = [[AVCaptureMetadataOutput alloc] init];



    //4.设置代理监听输出对象输出的数据，在主线程中刷新
    [metaout setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];

    self.session = [[AVCaptureSession alloc] init];

    //5.设置输出质量(高像素输出)
    if ([self.session canSetSessionPreset:AVCaptureSessionPreset640x480]) {
       [self.session setSessionPreset:AVCaptureSessionPreset640x480];
    }

    //6.添加输入和输出到会话
    [self.session beginConfiguration];
    if ([self.session canAddInput:input]) {
       [self.session addInput:input];
    }
    if ([self.session canAddOutput:metaout]) {
       [self.session addOutput:metaout];
    }

    if ([_session canAddOutput:self.videoDataOutput]) {
          [_session addOutput:self.videoDataOutput];
    }
    [self.session commitConfiguration];
           
    //7.告诉输出对象要输出什么样的数据,识别人脸, 最多可识别10张人脸
    [metaout setMetadataObjectTypes:@[AVMetadataObjectTypeFace]];

    AVCaptureSession *session = (AVCaptureSession *)self.session;

    //8.创建预览图层
    
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _previewLayer.frame = CGRectMake((ScreenWidth-ScaleW(30))/2-ScaleW(100), ScaleW(65), ScaleW(200), ScaleW(200));
    _previewLayer.cornerRadius = 100;
    [self.groundView.layer insertSublayer:_previewLayer atIndex:0];

    //9.设置有效扫描区域(默认整个屏幕区域)（每个取值0~1, 以屏幕右上角为坐标原点）
    metaout.rectOfInterest = self.view.bounds;

    //前置摄像头一定要设置一下 要不然画面是镜像
    for (AVCaptureVideoDataOutput* output in session.outputs) {
        for (AVCaptureConnection * av in output.connections) {
           //判断是否是前置摄像头状态
           if (av.supportsVideoMirroring) {
               //镜像设置
               av.videoOrientation = AVCaptureVideoOrientationPortrait;
        //                av.videoMirrored = YES;
           }
        }
    }

    //10. 开始扫描
    [self.session startRunning];
    
}
- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (metadataObjects.count>1) {
        self.tishiLable.text = @"必须一个人进行人脸识别~";
        return;
    } else {
        for(AVMetadataObject *metaObject in metadataObjects){
              
             if([metaObject isKindOfClass:[AVMetadataFaceObject class ]] && metaObject.type == AVMetadataObjectTypeFace){
//                 if (!_successful) {
//                     if (!self.progress) {
                         //进行网络请求
//                          [self cleanupSelfReferencecleanupSelfReference];
//                     }
                     
//                 }

             } else {
                 self.tishiLable.text = @"未检测到人脸~";
             }
         }
    }
 
}
- (UIImage*)imageFromPixelBuffer:(CMSampleBufferRef)p {
    CVImageBufferRef buffer;
    buffer = CMSampleBufferGetImageBuffer(p);

    CVPixelBufferLockBaseAddress(buffer, 0);
    uint8_t *base;
    size_t width, height, bytesPerRow;
    base = (uint8_t *)CVPixelBufferGetBaseAddress(buffer);
    width = CVPixelBufferGetWidth(buffer);
    height = CVPixelBufferGetHeight(buffer);
    bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);

    CGColorSpaceRef colorSpace;
    CGContextRef cgContext;
    colorSpace = CGColorSpaceCreateDeviceRGB();
    cgContext = CGBitmapContextCreate(base, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);

    CGImageRef cgImage;
    UIImage *image;
    cgImage = CGBitmapContextCreateImage(cgContext);
    image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    CGContextRelease(cgContext);

    CVPixelBufferUnlockBaseAddress(buffer, 0);


    return image;
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];

    UIImage *img = [self imageFromPixelBuffer:sampleBuffer];
    
    [self.faceBtn setImage:img forState:UIControlStateNormal];
}


///
/*
- (void)setupCamera
{
    NSArray* devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for(AVCaptureDevice *device in devices)
    {
        if([device position] == AVCaptureDevicePositionFront)
            self.device = device;
    }

    AVCaptureDeviceInput* input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    AVCaptureVideoDataOutput* output = [[AVCaptureVideoDataOutput alloc] init];
    output.alwaysDiscardsLateVideoFrames = YES;

    dispatch_queue_t queue;
    queue = dispatch_queue_create("cameraQueue", NULL);
    [output setSampleBufferDelegate:self queue:queue];

    NSString* key = (NSString *) kCVPixelBufferPixelFormatTypeKey;
    NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
    [output setVideoSettings:videoSettings];

    self.captureSession = [[AVCaptureSession alloc] init];
    [self.captureSession addInput:input];
    [self.captureSession addOutput:output];
    [self.captureSession setSessionPreset:AVCaptureSessionPresetPhoto];

    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;

    // CHECK FOR YOUR APP
    self.previewLayer.frame = CGRectMake(0, 0, self.view.frame.size.height, self.view.frame.size.width);
    self.previewLayer.orientation = AVCaptureVideoOrientationLandscapeRight;
    // CHECK FOR YOUR APP

    [self.view.layer insertSublayer:self.previewLayer atIndex:0];   // Comment-out to hide preview layer

    [self.captureSession startRunning];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef newImage = CGBitmapContextCreateImage(newContext);

    CGContextRelease(newContext);
    CGColorSpaceRelease(colorSpace);

    self.cameraImage = [UIImage imageWithCGImage:newImage scale:1.0f orientation:UIImageOrientationDownMirrored];

    CGImageRelease(newImage);

    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
}

- (void)setupTimer
{
    NSTimer* cameraTimer = [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(snapshot) userInfo:nil repeats:YES];
}

- (void)snapshot
{
    NSLog(@"SNAPSHOT");
    self.cameraImageView.image = self.cameraImage;  // Comment-out to hide snapshot
}*/
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
