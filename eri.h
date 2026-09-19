#pragma once
#include <string>
#include <vector>
#include <unordered_map>

#define OBFUSCATE(x) x
#define LOGD(...) ((void)0)

namespace logger {
    inline void Clear() {}
}

namespace NovaProxy {
    #undef DEBUG
    enum class LogLevel { INFO, DEBUG, ERR };
    class ProxyUtils {
    public:
        static void ConsoleInit() {}
        static void Log(std::string msg, LogLevel level) {}
        static bool LoadConfig(std::string path) { return true; }
        static bool InterceptTrafficPattern(std::string p) { return true; }
    };
}

namespace nlohmann {
    class ordered_json {
    public:
        template<typename... Args>
        ordered_json(Args&&...) {}
        std::string dump(int w = 0, char f = ' ') { return ""; }
    };
}

struct Il2CppImage {};
struct MethodInfo { void* getClass() { return nullptr; } };
struct HookerData {
    static inline std::vector<HookerData> visited;
    std::string name;
    int hitCount = 0;
    float time = 0;
    float goneTime = 0;
    MethodInfo* method = nullptr;
};

struct ImVec2 { float x, y; ImVec2(float x=0, float y=0):x(x),y(y){} };
struct ImVec4 { float x, y, z, w; };
struct ImGuiStyle {};
struct ImColor {
    ImColor(float, float, float, float) {}
    ImColor(unsigned int) {}
    ImVec4 Value = {1,1,1,1};
};
struct ImDrawList {
    void AddRectFilled(ImVec2, ImVec2, unsigned int, float = 0.0f, int = 0) {}
    void AddText(ImVec2, ImColor, const char*) {}
};
struct ImGuiIO {
    ImVec2 DisplaySize = {1920, 1080};
    float DeltaTime = 0.016f;
};
inline float ImLerp(float a, float b, float t) { return a + (b - a) * t; }

#define IM_COL32(r,g,b,a) (0)
#define ImGuiStyleVar_FramePadding 0
#define ImGuiChildFlags_None 0
#define ImGuiWindowFlags_NoResize (1 << 0)
#define ImGuiWindowFlags_NoMove (1 << 1)
#define ImGuiWindowFlags_HorizontalScrollbar (1 << 2)
#define ImGuiTabItemFlags_SetSelected (1 << 0)

namespace ImGui {
    inline ImGuiIO& GetIO() { static ImGuiIO io; return io; }
    inline ImDrawList* GetBackgroundDrawList() { static ImDrawList list; return &list; }
    inline void SetNextWindowPos(ImVec2, int = 0, ImVec2 = ImVec2()) {}
    inline void SetNextWindowSize(ImVec2, int = 0) {}
    inline void PushStyleVar(int, ImVec2) {}
    inline void PopStyleVar(int = 1) {}
    inline ImVec2 CalcTextSize(const char*) { return ImVec2(); }
    inline bool Begin(const char*, bool* = nullptr, int = 0) { return true; }
    inline void End() {}
    inline void PushStyleColor(int, unsigned int) {}
    inline void PopStyleColor(int = 1) {}
    inline bool Checkbox(const char*, bool*) { return false; }
    inline bool Checkbox(const char*, bool* v) { return false; }
    inline void OpenPopup(const char*) {}
    inline void BeginChild(const char*, ImVec2, bool = false, int = 0) {}
    inline void EndChild() {}
    inline void PushID(void*) {}
    inline void PopID() {}
    inline bool IsItemHeld() { return false; }
    inline bool BeginTabBar(const char*, int = 0) { return false; }
    inline bool EndTabBar() {}
    inline bool BeginTabItem(const char*, bool* = nullptr, int = 0) { return false; }
    inline bool EndTabItem() { return; }
    inline bool Text(const char*, ...) { return false; }
    inline bool Button(const char*) { return false; }
    inline float GetFrameHeight() { return 0.f; }
    inline ImVec2 GetWindowSize() { return ImVec2(); }
    inline ImVec2 GetWindowPos() { return ImVec2(); }
}

inline std::unordered_map<void*, HookerData> hookerMap;
inline int maxLine = 0;
inline ImVec2 initialScreenSize;
inline void initModMenu(void*, void*) {}
struct Tool {
    static void Draw() {}
    struct Tab {
        bool MethodViewer(void*, void*, void*) { return true; }
        void* getCachedParams(void*) { return nullptr; }
        bool setOpenedTab = false;
    };
    static Tab& GetFirstTab() { static Tab t; return t; }
    static Tab& OpenNewTabFromClass(void*) { static Tab t; return t; }
};

struct Keyboard {
    static void Update() {}
};
