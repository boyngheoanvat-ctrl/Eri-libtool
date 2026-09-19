#import <iostream>
#import <thread>
#import <vector>
#import <string>
#import <array>
#import <pthread.h> 
#import <unistd.h>              
#import <UIKit/UIKit.h>

#import "Menu/ImGui.h"
#import "Tool/Keyboard.h"
#import "Tool/Tool.h"
#import "Tool/Util.h"
#import "imgui/imgui.h"
#import "imgui/imgui_internal.h"
#import "sstream"
#import "Tool/Unity.h"
#import "utils.h"

// --- Khai báo Interface Objective-C Bridge tích hợp Gesture & ImGuiDrawView ---
@interface JHPP : NSObject
+ (UIViewController *)currentViewController;
@end

@interface ImGuiDrawView : NSObject
- (instancetype)init;
@property (nonatomic, strong) UIView *view;
+ (void)showChange:(BOOL)open;
@end

@interface MainLoader : NSObject
@property (nonatomic, strong) ImGuiDrawView *vna;
- (void)tapIconView;
- (void)tapIconView2;
@end

@implementation MainLoader

- (void)initTapGes {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
    tap.numberOfTapsRequired = 2; 
    tap.numberOfTouchesRequired = 3; 
    
    UIViewController *currVC = [JHPP currentViewController];
    if (currVC && currVC.view) {
        [currVC.view addGestureRecognizer:tap];
    }
    [tap addTarget:self action:@selector(tapIconView)];
}

- (void)initTapGes2 {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
    tap.numberOfTapsRequired = 2; 
    tap.numberOfTouchesRequired = 2; 
    
    UIViewController *currVC = [JHPP currentViewController];
    if (currVC && currVC.view) {
        [currVC.view addGestureRecognizer:tap];
    }
    [tap addTarget:self action:@selector(tapIconView2)];
}

- (void)tapIconView {
    if (!_vna) {
        ImGuiDrawView *vc = [[ImGuiDrawView alloc] init];
        _vna = vc;
    }
    [ImGuiDrawView showChange:true];
    UIWindow *mainWindow = [UIApplication sharedApplication].keyWindow;
    if (mainWindow && mainWindow.rootViewController) {
        [mainWindow.rootViewController.view addSubview:_vna.view];
    }
}

- (void)tapIconView2 {
    if (!_vna) {
        ImGuiDrawView *vc = [[ImGuiDrawView alloc] init];
        _vna = vc;
    }
    [ImGuiDrawView showChange:false];
    UIWindow *mainWindow = [UIApplication sharedApplication].keyWindow;
    if (mainWindow && mainWindow.rootViewController) {
        [mainWindow.rootViewController.view addSubview:_vna.view];
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
    std::this_thread::sleep_for(std::chrono::milliseconds(1000));
    
    dispatch_async(dispatch_get_main_queue(), ^{
        loaderInstance = [[MainLoader alloc] init];
        [loaderInstance initTapGes];
        [loaderInstance initTapGes2];
        [loaderInstance tapIconView]; 
    });

    std::thread(RunProxyEngine).detach();
    initModMenu((void *)draw_thread, nullptr);
    
    return nullptr;
}

__attribute__((constructor)) void lib_main() {
    pthread_t ptid;
    pthread_create(&ptid, nullptr, hack_thread, nullptr);
}
