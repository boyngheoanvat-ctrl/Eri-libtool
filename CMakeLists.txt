cmake_minimum_required(VERSION 3.10)
project(CombinedModProject)

set(CMAKE_CXX_STANDARD 17)

file(GLOB SOURCES "*.cpp")

add_library(combined_mod SHARED ${SOURCES})
target_include_directories(combined_mod PRIVATE .)
