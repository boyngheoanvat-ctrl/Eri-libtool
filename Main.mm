// ============================================================
// Main.mm — FULL FIXED
// ============================================================
// ✅ Disable libc++ modules FIRST
#define _LIBCPP_NO_MODULES 1

// ✅ Use #include for C++ headers, not #import
#include <iostream>
#include <thread>
#include <vector>
#include <string>
#include <array>
#include <sstream>
#include <chrono>
#include <pthread.h>
#include <unistd.h>

// ✅ Use #import ONLY for Objective-C frameworks
#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <Foundation/Foundation.h>

#import "Esp/CaptainHook.h"
#import "Esp/ImGuiDrawView.h"
#import "IMGUI/imgui.h"
#import "IMGUI/imgui_impl_metal.h"
#import "IMGUI/zzz.h"
#import "Esp/MonoString.h"
#include "Esp/dbdef.h"
#include "1110/patch.h"
#include "1110/haizzz.h"
#import "linh_tinh/spam.h"
#import "Menu/ImGui.h"
#import "Tool/Keyboard.h"
#import "Tool/Tool.h"
#import "Tool/Util.h"
#import "IMGUI/imgui_internal.h"
#import "Tool/Unity.h"
#import "utils.h"

#define kWidth  [UIScreen mainScreen].bounds.size.width
#define kHeight [UIScreen mainScreen].bounds.size.height
#define kScale  [UIScreen mainScreen].scale

@interface ImGuiDrawView () <MTKViewDelegate>
@property (nonatomic, strong) id <MTLDevice> device;
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;
@end

@implementation ImGuiDrawView
#include "1110/hook.h"

uint64_t hackmapoffset;
static bool MenDeal = true;

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self) return nil;

    _device = MTLCreateSystemDefaultDevice();
    NSParameterAssert(_device);
    _commandQueue = [_device newCommandQueue];

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;

    ImGui::StyleColorsClassic();
    
    ImFont* font = io.Fonts->AddFontFromMemoryCompressedTTF(
        (void*)zzz_compressed_data,
        zzz_compressed_size,
        60.0f,
        nullptr,
        io.Fonts->GetGlyphRangesVietnamese()
    );
    
    ImGui_ImplMetal_Init(_device);
    return self;
}

+ (void)showChange:(BOOL)open { MenDeal = open; }

- (MTKView *)mtkView { return (MTKView *)self.view; }

- (void)loadView
{
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    self.view = [[MTKView alloc] initWithFrame:screenBounds];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    Spam *spam = [[Spam alloc] init];
    [spam startSpam];
    
    self.mtkView.device = self.device;
    self.mtkView.delegate = self;
    self.mtkView.clearColor = MTLClearColorMake(0, 0, 0, 0);
    self.mtkView.opaque = NO;
    self.mtkView.backgroundColor = [UIColor clearColor];
    self.mtkView.clipsToBounds = YES;
}

#pragma mark - Touch Input

- (void)updateIOWithTouchEvent:(UIEvent *)event
{
    UITouch *anyTouch = event.allTouches.anyObject;
    if (!anyTouch) return;
    
    CGPoint touchLocation = [anyTouch locationInView:self.view];
    ImGuiIO &io = ImGui::GetIO();
    io.MousePos = ImVec2(touchLocation.x, touchLocation.y);

    BOOL hasActiveTouch = NO;
    for (UITouch *touch in event.allTouches) {
        if (touch.phase != UITouchPhaseEnded && touch.phase != UITouchPhaseCancelled) {
            hasActiveTouch = YES;
            break;
        }
    }
    io.MouseDown[0] = hasActiveTouch;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { [self updateIOWithTouchEvent:event]; }
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { [self updateIOWithTouchEvent:event]; }
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { [self updateIOWithTouchEvent:event]; }
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { [self updateIOWithTouchEvent:event]; }

#pragma mark - MTKViewDelegate

- (void)drawInMTKView:(MTKView*)view
{
    ImGuiIO& io = ImGui::GetIO();
    io.DisplaySize = ImVec2(view.bounds.size.width, view.bounds.size.height);
    
    CGFloat fbs = view.window.screen.scale ?: UIScreen.mainScreen.scale;
    io.DisplayFramebufferScale = ImVec2(fbs, fbs);
    io.DeltaTime = 1.0f / (view.preferredFramesPerSecond ?: 60);

    self.view.userInteractionEnabled = MenDeal;

    MTLRenderPassDescriptor* rpd = view.currentRenderPassDescriptor;
    if (!rpd) return;

    id<MTLCommandBuffer> cb = [self.commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> enc = [cb renderCommandEncoderWithDescriptor:rpd];
    [enc pushDebugGroup:@"ImGui"];

    ImGui_ImplMetal_NewFrame(rpd);
    ImGui::NewFrame();

    ImGui::GetFont()->Scale = 15.f / ImGui::GetFont()->FontSize;

    CGFloat x = (CGRectGetWidth(view.bounds) - 400) * 0.5f;
    CGFloat y = (CGRectGetHeight(view.bounds) - 300) * 0.5f;
    ImGui::SetNextWindowPos(ImVec2(x, y), ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(ImVec2(400, 300), ImGuiCond_FirstUseEver);

    if (MenDeal)
    {
        if (ImGui::Begin("EriLibtool Menu", &MenDeal))
        {
            if (ImGui::BeginTabBar("MainTabBar"))
            {
                if (ImGui::BeginTabItem("Tools"))
                {
                    Tool::Draw();
                    ImGui::EndTabItem();
                }
                ImGui::EndTabBar();
            }
            ImGui::End();
        }
    }

    ImGui::Render();
    ImGui_ImplMetal_RenderDrawData(ImGui::GetDrawData(), cb, enc);

    [enc popDebugGroup];
    [enc endEncoding];
    [cb presentDrawable:view.currentDrawable];
    [cb commit];
}

- (void)mtkView:(MTKView*)view drawableSizeWillChange:(CGSize)size {}

@end

// Entry point
static void* hack_thread(void*)
{
    std::this_thread::sleep_for(std::chrono::milliseconds(2000));
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
        if (!window) return;
        
        ImGuiDrawView *vc = [[ImGuiDrawView alloc] init];
        [window.rootViewController addChildViewController:vc];
        [window.rootViewController.view addSubview:vc.view];
        vc.view.frame = window.rootViewController.view.bounds;
    });
    return nullptr;
}

__attribute__((constructor)) static void lib_main(void)
{
    pthread_t ptid;
    pthread_create(&ptid, nullptr, hack_thread, nullptr);
    pthread_detach(ptid);
}
