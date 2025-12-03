cmake_minimum_required(VERSION 3.16)
project(ClusterUI_0820 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Qt6 automatic MOC/UIC/RCC handling
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Find Qt6 packages
find_package(Qt6 REQUIRED COMPONENTS
    Core
    Gui
    Qml
    Quick
    DBus
)

# Optional: Qt5Compat for GraphicalEffects (if using ColorOverlay, etc.)
find_package(Qt6 COMPONENTS Qt5Compat)

message(STATUS "Qt6 version: ${Qt6_VERSION}")
message(STATUS "Qt6Core found: ${Qt6Core_FOUND}")

# Define the executable with qt_add_executable (Qt6 way)
qt_add_executable(ClusterUI_0820
    main.cpp
    PiRacerBridge.cpp
    PiRacerBridge.h
    qml.qrc  # Automatically processed by CMAKE_AUTORCC
)

# Link Qt6 libraries
target_link_libraries(ClusterUI_0820 PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::DBus
)

# Link Qt5Compat if available (for GraphicalEffects)
if(TARGET Qt6::Core5Compat)
    target_link_libraries(ClusterUI_0820 PRIVATE Qt6::Core5Compat)
    message(STATUS "Qt5Compat linked (GraphicalEffects support)")
endif()

# Set output directory
set_target_properties(ClusterUI_0820 PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
)

# Compiler warnings
if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    target_compile_options(ClusterUI_0820 PRIVATE -Wall -Wextra)
endif()

# Pi-specific optimizations for release builds
if(CMAKE_BUILD_TYPE STREQUAL "Release" AND CMAKE_CROSSCOMPILING)
    target_compile_options(ClusterUI_0820 PRIVATE -O3 -ffast-math)
endif()

# Install rule
install(TARGETS ClusterUI_0820 RUNTIME DESTINATION bin)

message(STATUS "")
message(STATUS "=== Build Configuration ===")
message(STATUS "Cross-compiling: ${CMAKE_CROSSCOMPILING}")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Qt6 automatic tools: MOC/RCC/UIC enabled")
message(STATUS "==========================")