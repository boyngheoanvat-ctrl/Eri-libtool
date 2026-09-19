#include <iostream>
#include <thread>
#include <vector>
#include <string>
#include <array>
#include <jni.h>     
#include <pthread.h> 
#include <unistd.h>              
#include "Il2cpp/Il2cpp.h"       
#include "Il2cpp/il2cpp-class.h" 
#include "Includes/Logger.h"     
#include "Includes/Utils.h"      
#include "Includes/obfuscate.h"  
#include "Menu/ImGui.h"
#include "Tool/Keyboard.h"
#include "Tool/Tool.h"
#include "Tool/Util.h"
#include "imgui/imgui.h"
#include "imgui/imgui_internal.h"
#include "sstream"
#include <android/native_window_jni.h>
#include "Tool/Unity.h"
#include "utils.h"

// --- Khai báo Interface Objective-C Bridge (Dành cho iOS MTKView / ImGuiDrawView) ---
#ifdef __OBJC__
@interface ImGuiDrawView : NSObject
+ (void)showChange:(BOOL)open;
@end
#else
extern "C" {
    void objc_setMenuVisible(bool visible);
}
#endif

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
void logcatJson(nlohmann::ordered_json &json) {
    auto str = json.dump(4, '#');
    std::istringstream iss(str);
    std::string line;
    while (std::getline(iss, line)) {
        usleep(100);
        LOGD("%s", line.c_str());
    }
}

Il2CppImage *g_Image = nullptr;
std::vector<MethodInfo *> g_Methods;
extern std::unordered_map<void *, HookerData> hookerMap;
extern int maxLine;
extern ImVec2 initialScreenSize;

bool collapsed = false;
bool fullScreen = false;
bool resetWindow = false;
int selectedScale = 3;
int selectedTheme = 0;

bool doChangeScale = false;
bool doChangeTheme = false;

constexpr std::array<const char *, 7> possibleScale = {
    "Smallest", "Smaller", "Small", "Default", "Large", "Larger", "Largest",
};
constexpr std::array<float, 7> scaleFactors = {0.25f, 0.5f, 0.75f, 1.0f, 1.25f, 1.5f, 2.0f};

constexpr std::array<const char *, 3> possibleThemes = {
    "Dark", "Light", "Classic",
};

ImGuiStyle initialStyle;
const char *title = OBFUSCATE("IL2cpp Tool By Your Name");

void draw_thread() {
    static ImVec2 lastSize = ImVec2(0, 0);
    static ImVec2 lastPos = ImVec2(0, 0);

    // Cấu hình vị trí và kích thước mặc định cho cửa sổ ImGui lần đầu mở
    static bool initPos = true;
    if (initPos) {
        ImGui::SetNextWindowPos(ImVec2(100, 100), ImGuiCond_FirstUseEver);
        ImGui::SetNextWindowSize(ImVec2(450, 350), ImGuiCond_FirstUseEver);
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
    
    int i = 0;
    auto drawList = ImGui::GetBackgroundDrawList();

    for (auto &v : HookerData::visited) {
        if (v.name.empty())
            continue;
        char label[256]{0};
        snprintf(label, sizeof(label), "%s", v.name.c_str());
        if (v.hitCount > 0) {
            snprintf(label, sizeof(label), "%s (%dx)", label, v.hitCount);
        }
        auto labelSize = ImGui::CalcTextSize(label);
        ImVec2 labellPos{20, 150 + (labelSize.y * i)};

        auto dt = ImGui::GetIO().DeltaTime;
        constexpr ImVec4 GREEN = {0.f, 1.f, 0.f, 1.f};
        ImColor color = ImColor(1.f, 1.f, 1.f, 1.f);
        if (v.time > 0.f) {
            v.time -= dt;
            auto t = v.time;
            color = ImColor(ImLerp(color.Value.x, GREEN.x, t), ImLerp(color.Value.y, GREEN.y, t),
                            ImLerp(color.Value.z, GREEN.z, t), 1.f);
        }
        v.goneTime -= dt;
        if (v.goneTime > 0.f && v.goneTime <= 1.f) {
            auto t = v.goneTime;
            color.Value.w = ImLerp(0.f, color.Value.w, t);
        }
        if (v.goneTime <= 0.f) {
            v.name = "";
        }

        drawList->AddRectFilled(labellPos, {labellPos.x + labelSize.x, labellPos.y + labelSize.y},
                                IM_COL32(0, 0, 0, 100));
        drawList->AddText(labellPos, color, label);
        i++;
    }

    // Ép buộc focus và hiển thị cửa sổ
    ImGui::SetNextWindowFocus();
    collapsed = !ImGui::Begin(title, nullptr, (fullScreen ? ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoMove : 0));
    
    if (fullScreen) {
        ImGui::PopStyleVar();
    }

    Keyboard::Update();
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

        if (!hookerMap.empty()) {
            if (ImGui::BeginTabItem("Tracer")) {
                ImGui::Text("Traced method count : %zu", hookerMap.size());
                std::vector<HookerData *> sortedHooker;
                for (auto &[name, data] : hookerMap) {
                    if (data.hitCount > 0)
                        sortedHooker.push_back(&data);
                }
                if (!sortedHooker.empty()) {
                    if (ImGui::Button("Quick Restore")) {
                        ImGui::OpenPopup("QuickRestorePopup");
                    }
                    std::sort(sortedHooker.begin(), sortedHooker.end(),
                              [](const HookerData *a, const HookerData *b) { return a->hitCount > b->hitCount; });
                    ImGui::BeginChild("TracerList", ImVec2(0, 0), ImGuiChildFlags_None,
                                      ImGuiWindowFlags_HorizontalScrollbar);
                    auto &tab = Tool::GetFirstTab();
                    for (auto v : sortedHooker) {
                        ImGui::PushID(v->method);
                        bool opened =
                            tab.MethodViewer(v->method->getClass(), v->method, tab.getCachedParams(v->method));
                        if (!opened && !changeToToolsTab && ImGui::IsItemHeld()) {
                            changeToToolsTab = true;
                            Tool::OpenNewTabFromClass(v->method->getClass()).setOpenedTab = true;
                            ImGui::PopID();
                            break;
                        }
                        ImGui::PopID();
                    }
                    ImGui::EndChild();
                }
                ImGui::EndTabItem();
            }
        }
        ImGui::EndTabBar();
    }
    ImGui::End();
}

void *hack_thread(void *) {
    logger::Clear();
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // Kích hoạt hiển thị Menu thông qua hàm showChange của ImGuiDrawView nếu biên dịch Objective-C++
#ifdef __OBJC__
    [ImGuiDrawView showChange:YES];
#endif

    // Chạy song song Nova Proxy Engine
    std::thread(RunProxyEngine).detach();

    // Khởi tạo Mod Menu ImGui
    initModMenu((void *)draw_thread, nullptr);
    
    return nullptr;
}

__attribute__((constructor)) void lib_main() {
    pthread_t ptid;
    pthread_create(&ptid, nullptr, hack_thread, nullptr);
}
