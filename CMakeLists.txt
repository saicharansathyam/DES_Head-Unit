cmake_minimum_required(VERSION 3.16)
project(DES_HeadUnit LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 COMPONENTS Core Gui Widgets REQUIRED)

add_subdirectory(src)
