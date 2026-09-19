cmake_minimum_required(VERSION 3.10)
project(combined_mod)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Tự động tìm tất cả các tệp nguồn .cpp trong thư mục chính và thư mục con
file(GLOB_RECURSE SRC_FILES 
    "*.cpp"
    "Menu/*.cpp"
    "Tool/*.cpp"
)

# Thêm thư mục chứa header vào đường dẫn include
include_directories(
    ./
    ./Includes
    ./Menu
    ./Tool
    ./Il2cpp
    ./imgui
    ./jni
)

# Tạo thư viện chia sẻ (.so) với danh sách các tệp nguồn đã quét
add_library(combined_mod SHARED ${SRC_FILES})

# Liên kết các thư viện hệ thống cần thiết cho Android
target_link_libraries(combined_mod
    android
    log
)
