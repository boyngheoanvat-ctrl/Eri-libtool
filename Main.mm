#import <iostream>
#import <thread>
#import <vector>
#import <string>
#import <array>
#import <pthread.h> 
#import <unistd.h>              
#import <UIKit/UIKit.h>
#import "Esp/CaptainHook.h"
#import "Esp/ImGuiDrawView.h"
#import "Esp/MonoString.h"
#include "Esp/dbdef.h"
#import "Menu/ImGui.h"
#import "Tool/Keyboard.h"
#import "Tool/Tool.h"
#import "Tool/Util.h"
#import "imgui/imgui.h"
#import "imgui/imgui_internal.h"
#import "sstream"
#import "Tool/Unity.h"
#import "utils.h"

// --- Khai báo Interface ---
@interface JHPP : NSObject
+ (UIViewController *)currentViewController;
@end

@interface ImGuiDrawView : NSObject
@property (nonatomic, strong) UIView *view;
- (instancetype)init;
+ (void)showChange:(BOOL)open;
@end

// --- Hiện thực hóa JHPP ---
@implementation JHPP
+ (UIViewController *)currentViewController {
    UIWindow *window = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *w in scene.windows) {
                    if (w.isKeyWindow) {
                        window = w;
                        break;
                    }
                }
            }
        }
    }
    if (!window) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        window = [UIApplication sharedApplication].keyWindow;
        #pragma clang diagnostic pop
    }
    UIViewController *rootVC = window.rootViewController;
    while (rootVC.presentedViewController) {
        rootVC = rootVC.presentedViewController;
    }
    return rootVC;
}
@end

// --- Hiện thực hóa ImGuiDrawView ---
@implementation ImGuiDrawView
- (instancetype)init {
    self = [super init];
    if (self) {
        self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        self.view.userInteractionEnabled = NO;
    }
    return self;
}
+ (void)showChange:(BOOL)open {
    // Logic ẩn hiện giao diện nếu có
}
@end

// --- Quản lý giao diện với nút bấm nổi (Floating Button) ---
@interface MainLoader : NSObject
@property (nonatomic, strong) ImGuiDrawView *vna;
@property (nonatomic, strong) UIButton *menuButton;
- (void)setupFloatingButton;
- (void)toggleMenu;
@end

@implementation MainLoader

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupFloatingButton];
    }
    return self;
}

- (void)setupFloatingButton {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *mainWindow = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    for (UIWindow *w in scene.windows) {
                        if (w.isKeyWindow) { mainWindow = w; break; }
                    }
                }
            }
        }
        if (!mainWindow) {
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Wdeprecated-declarations"
            mainWindow = [UIApplication sharedApplication].keyWindow;
            #pragma clang diagnostic pop
        }

        if (mainWindow && mainWindow.rootViewController) {
            // Tạo nút bấm nổi hình tròn ở góc trái màn hình
            self.menuButton = [UIButton buttonWithType:UIButtonTypeCustom];
            self.menuButton.frame = CGRectMake(50, 100, 50, 50);
            self.menuButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:0.8];
            [self.menuButton setTitle:@"MOD" forState:UIControlStateNormal];
            [self.menuButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            self.menuButton.layer.cornerRadius = 25;
            self.menuButton.clipsToBounds = YES;
            
            // Thêm sự kiện bấm để bật/tắt menu
            [self.menuButton addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
            
            // Thêm cử chỉ kéo thả (Pan Gesture) để di chuyển nút đi bất cứ đâu
            UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
            [self.menuButton addGestureRecognizer:pan];

            [mainWindow.rootViewController.view addSubview:self.menuButton];
        }
    });
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.menuButton.superview];
    self.menuButton.center = CGPointMake(self.menuButton.center.x + translation.x, self.menuButton.center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:self.menuButton.superview];
}

- (void)toggleMenu {
    if (!_vna) {
        ImGuiDrawView *vc = [[ImGuiDrawView alloc] init];
        _vna = vc;
    }
    
    static BOOL isOpen = NO;
    isOpen = !isOpen;
    
    [ImGuiDrawView showChange:isOpen];
    
    UIWindow *mainWindow = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *w in scene.windows) {
                    if (w.isKeyWindow) { mainWindow = w; break; }
                }
            }
        }
    }
    if (!mainWindow) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        mainWindow = [UIApplication sharedApplication].keyWindow;
        #pragma clang diagnostic pop
    }
    
    if (mainWindow && mainWindow.rootViewController) {
        if (isOpen) {
            [mainWindow.rootViewController.view addSubview:_vna.view];
        } else {
            [_vna.view removeFromSuperview];
        }
    }
}

@end

// --- Phần xử lý của Nova Proxy Engine ---
void RunProxyEngine() {
    NovaProxy::ProxyUtils::ConsoleInit();
    NovaProxy::ProxyUtils::Log("Starting Nova Proxy Engine V1.4...", NovaProxy::LogLevel::INFO);
    
    if (!NovaProxy::ProxyUtils::LoadConfig("config.json")) {
        NovaProxy::ProxyUtils::Log("FATAL: Failed to read local endpoint target map.", NovaProxy::LogLevel::ERR);
        return;
    }

    uint16_t listen_port = 8443;
    NovaProxy::ProxyUtils::Log("Daemon bind attached: 127.0.0.1:" + std::to_string(listen_port), NovaProxy::LogLevel::DEBUG);
    NovaProxy::ProxyUtils::Log("Awaiting handshake intercepts from IDE extensions...", NovaProxy::LogLevel::INFO);

    bool runtime_flag = true;
    while(runtime_flag) {
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
        std::string mock_packet = "POST /v1/engines/copilot-codex/completions HTTP/1.1";
        if(NovaProxy::ProxyUtils::InterceptTrafficPattern(mock_packet)) {
             NovaProxy::ProxyUtils::Log("[ROUTING] Handshake diverted to Free-LLM model pipeline.", NovaProxy::LogLevel::INFO);
        }
        break; 
    }
}

// --- Phần xử lý của IL2CPP Mod Menu ---
bool collapsed = false;
bool fullScreen = false;
bool resetWindow = false;

const char *title = "IL2cpp Tool By Your Name";

void draw_thread() {
    static ImVec2 lastSize = ImVec2(0, 0);
    static ImVec2 lastPos = ImVec2(0, 0);

    static bool initPos = true;
    if (initPos) {
        ImGui::SetNextWindowPos(ImVec2(100, 100), 0);
        ImGui::SetNextWindowSize(ImVec2(450, 350), 0);
        initPos = false;
    }

    if (resetWindow) {
        resetWindow = false;
        if (fullScreen) {
            ImGui::SetNextWindowPos(ImVec2(0, 0));
            auto screenSize = ImGui::GetIO().DisplaySize;
            ImGui::SetNextWindowSize(screenSize);
        } else {
            ImGui::SetNextWindowPos(lastPos);
            ImGui::SetNextWindowSize(lastSize);
        }
    }
    if (fullScreen) {
        ImGui::PushStyleVar(ImGuiStyleVar_FramePadding, ImVec2(0, ImGui::GetFrameHeight()));
    }

    collapsed = !ImGui::Begin(title, nullptr, (fullScreen ? ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoMove : 0));
    
    if (fullScreen) {
        ImGui::PopStyleVar();
    }

    static bool changeToToolsTab = false;
    if (ImGui::BeginTabBar("mainTabber")) {
        if (ImGui::BeginTabItem("Tools", nullptr, changeToToolsTab ? ImGuiTabItemFlags_SetSelected : 0)) {
            changeToToolsTab = false;
            if (ImGui::Checkbox("Fullscreen", &fullScreen)) {
                if (fullScreen) {
                    lastSize = ImGui::GetWindowSize();
                    lastPos = ImGui::GetWindowPos();
                }
                resetWindow = true;
            }
            Tool::Draw();
            ImGui::EndTabItem();
        }
        ImGui::EndTabBar();
    }
    ImGui::End();
}

static MainLoader *loaderInstance = nil;

void *hack_thread(void *) {
    std::this_thread::sleep_for(std::chrono::milliseconds(2000));
    
    dispatch_async(dispatch_get_main_queue(), ^{
        loaderInstance = [[MainLoader alloc] init];
    });

    std::thread(RunProxyEngine).detach();
    initModMenu((void *)draw_thread, nullptr);
    
    return nullptr;
}

__attribute__((constructor)) void lib_main() {
    pthread_t ptid;
    pthread_create(&ptid, nullptr, hack_thread, nullptr);
}
