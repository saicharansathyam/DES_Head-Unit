cmake_minimum_required(VERSION 3.16)
project(IVIHeadUnit LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Quick Gui)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

add_subdirectory(src/head-unit)
add_subdirectory(src/media-player)
add_subdirectory(src/gear-selector)
add_subdirectory(src/ambient-lighting)
add_subdirectory(src/settings)
