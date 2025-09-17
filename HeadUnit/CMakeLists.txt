cmake_minimum_required(VERSION 3.16)
project(HeadUnit LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Quick Gui Qml)

if(UNIX)
    find_package(Qt6 REQUIRED COMPONENTS DBus)
endif()

# Add subdirectories
add_subdirectory(services)
add_subdirectory(apps)