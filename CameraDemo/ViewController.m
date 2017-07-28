//
//  ViewController.m
//  CameraDemo
//
//  Created by 王利军 on 20/7/2017.
//  Copyright © 2017 王利军. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

#import <OpenGLES/ES2/glext.h>

#import "STGLView.h"
#import "H264HwEncoderImpl.h"


#define KENCODE_FPS  20

@interface ViewController () <AVCaptureVideoDataOutputSampleBufferDelegate> {
    
    BOOL bEncoding;
    H264HwEncoderImpl *h264Encoder;
    int _iImageWidth;
    int _iImageHeight;
    CVOpenGLESTextureRef        _cvOriginalTexutre;
    CVOpenGLESTextureCacheRef   _cvTextureCache;
    
    GLuint _textureOriginalIn;
    GLuint _textureBeautifyOut;
    GLuint _textureStickerOut;
    
    UILabel *_lbInitCamera;
    UILabel *_lbOpenCamera;
    UILabel *_lbCloseCamera;
    UILabel *_lbSendRtmp;
    UILabel *_lbSwitchCamera;
    UILabel *_lbTips;
    UILabel *_lbTorchFlag;
    
}

@property (nonatomic, strong) AVCaptureSession  *captureSession;
@property (nonatomic, strong) AVCaptureDevice   *videoDevice;
@property (nonatomic, strong) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput  *videoDataOutput;
@property (nonatomic, strong) AVCaptureConnection   *videoConnection;

@property (nonatomic, strong) STGLView *preview;
@property (nonatomic, strong) EAGLContext *glRenderContext;

@property (nonatomic, strong) dispatch_queue_t videoBufferQueue;

@property (nonatomic, assign) BOOL isAppActive;
@property (nonatomic, assign) BOOL isTorched;

@end

@implementation ViewController

-(void)appWillResignAction {
    self.isAppActive = NO;
}

-(void)appWillEnterForeground{
    self.isAppActive = YES;
}
-(void)appDidBecomeActive{
    self.isAppActive = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    // Do any additional setup after loading the view, typically from a nib.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignAction) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    _iImageWidth = 720;
    _iImageHeight = 1280;
    int posY = 20;
    int btnW = 120;
    int btnH = 60;
    int posSpace = 20;
     self.isAppActive = YES;
    
    _lbTips = [[UILabel alloc] init];
    _lbTips.backgroundColor = [UIColor blueColor];
    _lbTips.frame = CGRectMake(0, posY, self.view.bounds.size.width, btnH);
    _lbTips.text = @"SomeTipsInfo";
    _lbTips.textAlignment = NSTextAlignmentCenter;
    _lbTips.userInteractionEnabled = NO;
    [self.view addSubview:_lbTips];
    posY += posSpace;
    posY += btnH;
    
    _lbInitCamera = [[UILabel alloc] init];
    _lbInitCamera.backgroundColor = [UIColor redColor];
    _lbInitCamera.frame = CGRectMake(20, posY, btnW, btnH);
    _lbInitCamera.text = @"InitCamera";
    _lbInitCamera.textAlignment = NSTextAlignmentCenter;
    _lbInitCamera.userInteractionEnabled = YES;
    [_lbInitCamera addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onInitCamera:)]];
    [self.view addSubview:_lbInitCamera];
    posY += posSpace;
    posY += btnH;
    
    _lbOpenCamera = [[UILabel alloc] init];
    _lbOpenCamera.backgroundColor = [UIColor redColor];
    _lbOpenCamera.frame = CGRectMake(20, posY, btnW, btnH);
    _lbOpenCamera.text = @"OpenCamera";
    _lbOpenCamera.textAlignment = NSTextAlignmentCenter;
    _lbOpenCamera.userInteractionEnabled = YES;
    [_lbOpenCamera addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onOpenCamera:)]];
    [self.view addSubview:_lbOpenCamera];
    posY += posSpace;
    posY += btnH;
    
    _lbSwitchCamera = [[UILabel alloc] init];
    _lbSwitchCamera.backgroundColor = [UIColor redColor];
    _lbSwitchCamera.frame = CGRectMake(20, posY, btnW, btnH);
    _lbSwitchCamera.text = @"SwitchCamera";
    _lbSwitchCamera.textAlignment = NSTextAlignmentCenter;
    _lbSwitchCamera.userInteractionEnabled = YES;
    [_lbSwitchCamera addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSwitchCamera:)]];
    [self.view addSubview:_lbSwitchCamera];
    posY += posSpace;
    posY += btnH;
    
    _lbTorchFlag = [[UILabel alloc] init];
    _lbTorchFlag.backgroundColor = [UIColor redColor];
    _lbTorchFlag.frame = CGRectMake(20, posY, btnW, btnH);
    _lbTorchFlag.text = @"TorchOnOrOff";
    _lbTorchFlag.textAlignment = NSTextAlignmentCenter;
    _lbTorchFlag.userInteractionEnabled = YES;
    [_lbTorchFlag addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTorchOnOrOff:)]];
    [self.view addSubview:_lbTorchFlag];
    posY += posSpace;
    posY += btnH;
    
    _lbCloseCamera = [[UILabel alloc] init];
    _lbCloseCamera.backgroundColor = [UIColor redColor];
    _lbCloseCamera.frame = CGRectMake(20, posY, btnW, btnH);
    _lbCloseCamera.text = @"CloseCamera";
    _lbCloseCamera.textAlignment = NSTextAlignmentCenter;
    _lbCloseCamera.userInteractionEnabled = YES;
    [_lbCloseCamera addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onCloseCamera:)]];
    [self.view addSubview:_lbCloseCamera];
    posY += posSpace;
    posY += btnH;
    
    
    _lbSendRtmp = [[UILabel alloc] init];
    _lbSendRtmp.backgroundColor = [UIColor redColor];
    _lbSendRtmp.frame = CGRectMake(20, posY, btnW, btnH);
    _lbSendRtmp.text = @"SendRtmp";
    _lbSendRtmp.textAlignment = NSTextAlignmentCenter;
    _lbSendRtmp.userInteractionEnabled = YES;
    [_lbSendRtmp addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSendRtmp:)]];
    [self.view addSubview:_lbSendRtmp];
    posY += posSpace;
    posY += btnH;
    

    self.isTorched = YES;
    self.videoBufferQueue = dispatch_queue_create("com.wanglijun.camerademo.videobuffer", NULL);

    bEncoding = NO;
    h264Encoder = [H264HwEncoderImpl alloc];
    [h264Encoder initWithConfiguration];
    
    [self setupPreview];
    [self setupMaterialRender];
}

-(EAGLContext*) getPreContext {
    return [EAGLContext currentContext];
}

-(void)setCurrentContext:(EAGLContext*)context {
    if([EAGLContext currentContext] != context) {
        [EAGLContext setCurrentContext:context];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)onInitCamera:(id)gesture{
    NSLog(@"onInitCamera............");
    [self setupCaptureSession];
}

-(void)onOpenCamera:(id)gesture{
    NSLog(@"onOpenCamera............");
    [self startCaptureSession];
}


-(void)onCloseCamera:(id)gesture{
    NSLog(@"onOpenCamera............");
    [self stopCaptureSession];
}

-(void)onSwitchCamera:(id)gesture{
    NSLog(@"onSwitchCamera............");
    [self SwitchCamera];
}

-(void)onTorchOnOrOff:(id)gesture{
    NSLog(@"onTorchOnOrOff............");
    NSError *error = nil;
    
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([captureDevice hasTorch]) {
        BOOL locked = [captureDevice lockForConfiguration:&error];
    
        if (locked) {
            if (self.isTorched) {
                captureDevice.torchMode = AVCaptureTorchModeOn;
                self.isTorched = NO;
            } else {
                captureDevice.torchMode = AVCaptureTorchModeOff;
                self.isTorched = YES;
            }
            [captureDevice unlockForConfiguration];
        }

    }
}


-(void)onSendRtmp:(id)gesture{
    NSLog(@"onOpenCamera............");
    
    if (bEncoding) {
        bEncoding = NO;
        [h264Encoder End];
    } else {
        [h264Encoder initEncode:_iImageWidth height:_iImageWidth];
        h264Encoder.delegate = self;
        bEncoding = YES;
    }
    
    //encode video
    //[self beginEncodeVideo];
    
    //send rtmp
}

void activeAndBindTexture(GLenum textureActive,
                          GLuint *textureBind,
                          Byte *sourceImage,
                          GLenum sourceFormat,
                          GLsizei iWidth,
                          GLsizei iHeight) {
    
    glActiveTexture(textureActive);
    glBindTexture(GL_TEXTURE_2D, *textureBind);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, iWidth, iHeight, 0, sourceFormat, GL_UNSIGNED_BYTE, sourceImage);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    glFlush();
}

-(void)SwitchCamera{
   self.isAppActive = NO;
    
    AVCaptureDevice *currentDevice = [self.videoDeviceInput device];
    AVCaptureDevicePosition currentPosition = [currentDevice position];
    
    
    AVCaptureDevicePosition toChangeDevicePosition=AVCaptureDevicePositionFront;
    if (currentPosition == AVCaptureDevicePositionFront) {
        toChangeDevicePosition = AVCaptureDevicePositionBack;
    }
    AVCaptureDevice *toChangeDevice;
    
    NSArray *devices = [AVCaptureDevice devices];
    for (AVCaptureDevice *device in devices) {
        NSLog(@"device info type:%@", device.deviceType);
        
        if ([device hasMediaType:AVMediaTypeVideo]) {
            NSLog(@"video device postion:%d", [device position]);
            if ([device position] == toChangeDevicePosition) {
                toChangeDevice = device;
                break;
            }
        }
    }
    
    NSError *error = nil;
    AVCaptureDeviceInput *toChangeDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:toChangeDevice error:&error];
    if (!toChangeDeviceInput || error) {
        NSLog(@"create toChangeDeviceInput device input failed.");
        return;
    }
    
    [self.captureSession beginConfiguration];
    [self.captureSession removeInput:self.videoDeviceInput];
    if ([self.captureSession canAddInput:toChangeDeviceInput]) {
        [self.captureSession addInput:toChangeDeviceInput];
        self.videoDeviceInput = toChangeDeviceInput;
        self.videoDevice = toChangeDevice;
        NSLog(@"add deviceinput successed. preposition:%d switch camera to position:%d", currentPosition, toChangeDevicePosition);
    } else {
        NSLog(@"add add deviceinput failed.");
    }
    CMTime frameDuration = CMTimeMake(1, KENCODE_FPS);
    
    if ([self.videoDevice lockForConfiguration:&error]) {
        self.videoDevice.activeVideoMinFrameDuration = frameDuration;
        self.videoDevice.activeVideoMaxFrameDuration = frameDuration;
        [self.videoDevice unlockForConfiguration];
    }
    
    [self.captureSession commitConfiguration];
    
    self.videoConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([self.videoConnection isVideoOrientationSupported]) {
        [self.videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    }
    if ([self.videoConnection isVideoMirroringSupported]) {
        [self.videoConnection setVideoMirrored:self.videoDevice.position==AVCaptureDevicePositionFront];
    }
    self.isAppActive = YES;
}

-(void)setupMaterialRender{
    //记录调用SDK之前的渲染环境以便在调用SDK之后设置回来
    EAGLContext *preContext = [self getPreContext];
    
    //创建OpenGL上下文，根据实际情况与预览使用同一个context或shareGroup
    self.glRenderContext = self.preview.context;
    
    //调用SDK之前需要切换到SDK的渲染环境
    [self setCurrentContext:self.glRenderContext];
    
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.glRenderContext, NULL, &_cvTextureCache);
    if(err) {
        NSLog(@"CVOpenGLESTextureCacheCreate %d", err);
    }
   
    //需要设为之前的渲染环境防止与其他需要GPU资源的模块冲突
    [self setCurrentContext:preContext];
}

-(BOOL)setupCaptureSession{
    self.captureSession = [[AVCaptureSession alloc] init];
    
    //根据实际需要修改,设置sessionpreset
    self.captureSession.sessionPreset = AVCaptureSessionPresetiFrame1280x720;
    
    //enum device
    NSArray *devices = [AVCaptureDevice devices];
    for (AVCaptureDevice *device in devices) {
        NSLog(@"device info type:%@", device.deviceType);
        
        if ([device hasMediaType:AVMediaTypeVideo]) {
            NSLog(@"video device postion:%d", [device position]);
            if ([device position] == AVCaptureDevicePositionFront) {
                self.videoDevice = device;
                break;
            }
        }
    }
    
    NSError *error = nil;
    self.videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.videoDevice error:&error];
    if (!self.videoDeviceInput || error) {
        NSLog(@"create video device input failed.");
        return NO;
    }
    
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    [self.videoDataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey ]];
    if (!self.videoDataOutput) {
        return NO;
    }

    [self.videoDataOutput setSampleBufferDelegate:self queue:self.videoBufferQueue];
    
    //config capture session
    [self.captureSession beginConfiguration];
    if ([self.captureSession canAddInput:self.videoDeviceInput]) {
        [self.captureSession addInput:self.videoDeviceInput];
    } else {
        NSLog(@"capture session can not add input video.");
        return NO;
    }
    
    if ([self.captureSession canAddOutput:self.videoDataOutput]) {
        [self.captureSession addOutput:self.videoDataOutput];
    } else {
        NSLog(@"capture session can not add videodataoutput.");
        return NO;
    }
    CMTime frameDuration = CMTimeMake(1, KENCODE_FPS);
    
    if ([self.videoDevice lockForConfiguration:&error]) {
        self.videoDevice.activeVideoMinFrameDuration = frameDuration;
        self.videoDevice.activeVideoMaxFrameDuration = frameDuration;
        [self.videoDevice unlockForConfiguration];
    }
    [self.captureSession commitConfiguration];
    
    self.videoConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([self.videoConnection isVideoOrientationSupported]) {
        [self.videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    }
    if ([self.videoConnection isVideoMirroringSupported]) {
        [self.videoConnection setVideoMirrored:self.videoDevice.position==AVCaptureDevicePositionFront];
    }
    
    /*
    //set preview use system api
    AVCaptureVideoPreviewLayer *previewLayer = nil;
    previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    CGRect layerRect = [[[self view ] layer ] bounds];
    [previewLayer setBounds:layerRect];
    [previewLayer setPosition:CGPointMake(CGRectGetMidX(layerRect),CGRectGetMidY(layerRect))];
    [[[self view] layer] addSublayer:previewLayer];
    */
    return YES;
}

-(void)startCaptureSession{
    if (self.captureSession && ![self.captureSession isRunning]) {
        [self.captureSession startRunning];
    }
}

-(void)stopCaptureSession{
    if (self.captureSession && [self.captureSession isRunning]) {
        [self.captureSession stopRunning];
    }
}


-(CGRect)getZoomedRectWithImageWidth:(int)width ImageHeight:(int)height InRect:(CGRect)rect ScaleToFit:(BOOL)bScaleToFit {
    CGRect rectRet = rect;
    
    float scaleX = width/CGRectGetWidth(rect);
    float scaleY = height/CGRectGetHeight(rect);
    float fScale = bScaleToFit ? fmaxf(scaleX, scaleY) : fminf(scaleX, scaleY);
    
    width /= fScale;
    height /= fScale;
    
    CGFloat fX = rect.origin.x - (width - rect.size.width) / 2.0f;
    CGFloat fY = rect.origin.y - (height - rect.size.height) / 2.0f;
    rectRet.origin.x = fX;
    rectRet.origin.y = fY;
    rectRet.size.width = width;
    rectRet.size.height = height;
    
    return rectRet;
}

-(void)setupPreview {
    CGRect displayRect = [self getZoomedRectWithImageWidth:_iImageWidth ImageHeight:_iImageHeight InRect:self.view.bounds ScaleToFit:NO];
    self.preview = [[STGLView alloc] initWithFrame:displayRect];
    [self.view insertSubview:self.preview atIndex:0];
    
}

-(void)beginEncodeVideo{
    NSInteger iSysVersion = [[[UIDevice currentDevice] systemVersion] integerValue];
    NSLog(@"ios sysversion %d.", iSysVersion);
    
    
}

- (void)gotSpsPps:(NSData*)sps pps:(NSData*)pps {
    NSLog(@"h264EncodeData: Got sps len:%d pps len:%d", (int)[sps length], (int)[pps length]);
    
}

- (void)gotEncodedData:(NSData*)data isKeyFrame:(BOOL)isKeyFrame {
    NSLog(@"h264EncodeData Got data len:%d kframe:%@", (int)[data length], isKeyFrame ? @"1" : @"0");
    
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    //if the application is not active, we do not anything
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        NSLog(@"application is not active");
        return;
    }
    
    if (!self.isAppActive) {
        NSLog(@"app is not active.");
        return;
    }

    //get pts
    CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    long lPTS = (long)(timestamp.value/(timestamp.timescale/1000));
    
    //NSLog(@"connection:%x myconnection:%x", connection, self.videoConnection);
    if (connection == self.videoConnection) {
        CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        unsigned char* pBFRAImageInput = CVPixelBufferGetBaseAddress(pixelBuffer);
        int iBytesPerRow = (int)CVPixelBufferGetBytesPerRow(pixelBuffer);
        
        int iWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
        int iHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
        size_t iTop, iLeft, iBottom, iRight = 0;
        CVPixelBufferGetExtendedPixels(pixelBuffer, &iLeft, &iRight, &iTop, &iBottom);
        
        iWidth += ((int)iLeft + (int)iRight);
        iHeight += ((int)iTop + (int)iBottom);
        iBytesPerRow += (iLeft+iRight);
        
        
        EAGLContext *preContext = [self getPreContext];
        [self setCurrentContext:self.glRenderContext];
        GLuint textureResult = 0;
        
        CVReturn cvRet = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                      _cvTextureCache,
                                                                      pixelBuffer,
                                                                      NULL,
                                                                      GL_TEXTURE_2D,
                                                                      GL_RGBA,
                                                                      iWidth,
                                                                      iHeight,
                                                                      GL_BGRA,
                                                                      GL_UNSIGNED_BYTE,
                                                                      0,
                                                                      &_cvOriginalTexutre);
        
        if (!_cvOriginalTexutre || kCVReturnSuccess != cvRet) {
            NSLog(@"CVOpenGLESTextureCacheCreateTextureFromImage %d", cvRet);
            CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
            [self setCurrentContext:preContext];
            return;
        }
        
        _textureOriginalIn = CVOpenGLESTextureGetName(_cvOriginalTexutre);
        glBindTexture(GL_TEXTURE_2D, _textureOriginalIn);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glBindTexture(GL_TEXTURE_2D, 0);
        
        textureResult = _textureOriginalIn;
        [self setCurrentContext:preContext];
        
        [self.preview renderWithTexture:textureResult
                                   size:CGSizeMake(iWidth, iHeight)
                                flipped:YES
                    applyingOrientation:1];
        glFlush();
        
        //encode video
        if (bEncoding) {
            [h264Encoder encode:sampleBuffer];
        }
        
        NSLog(@"captureOutput.......... lpts:%ld bytesPerRow:%d width:%d height:%d top:%d left:%d bottom:%d right:%d",
              lPTS, iBytesPerRow, iWidth, iHeight,iTop, iLeft, iBottom, iRight);
        
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        CVOpenGLESTextureCacheFlush(_cvTextureCache, 0);
        if (_cvOriginalTexutre) {
            CFRelease(_cvOriginalTexutre);
            _cvOriginalTexutre = NULL;
        }
    }
    
}

@end
