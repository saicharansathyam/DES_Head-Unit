cmake_minimum_required(VERSION 3.16)

project(IVI_Compositor VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_CXX_STANDARD 17)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick WaylandCompositor)

# Find Wayland libraries
find_package(PkgConfig REQUIRED)
pkg_check_modules(WAYLAND REQUIRED wayland-server wayland-client)

# Remove subdirectory additions since they cause issues
# Build them separately instead

qt_add_executable(appIVI_Compositor
    main.cpp
    ivi_compositor.cpp
    ivi_compositor.h
)

# Use the new policy so QML modules default to :/qt/qml/ as prefix (Qt 6)
qt_policy(SET QTP0001 NEW)

qt_add_qml_module(appIVI_Compositor
    URI IVI_Compositor
    VERSION 1.0
    QML_FILES
        Main.qml
        RightPanel.qml
        QML_FILES LeftPanel.qml
)

set_target_properties(appIVI_Compositor PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

# Link to QtWayland, Wayland server libraries, and other Qt modules
target_link_libraries(appIVI_Compositor
    PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::WaylandCompositor
    ${WAYLAND_LIBRARIES}
)

target_include_directories(appIVI_Compositor
    PRIVATE
    ${WAYLAND_INCLUDE_DIRS}
)

include(GNUInstallDirs)
install(TARGETS appIVI_Compositor
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
