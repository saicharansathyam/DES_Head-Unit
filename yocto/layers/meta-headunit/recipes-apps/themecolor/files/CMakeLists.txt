cmake_minimum_required(VERSION 3.16)

project(ThemeColor VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Quick DBus)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(appThemeColor
    main.cpp
)

qt_add_qml_module(appThemeColor
    URI ThemeColor
    VERSION 1.0
    QML_FILES
        Main.qml
        ColorWheel.qml
        PreviewButton.qml
    RESOURCES
        ColorUtils.js
    SOURCES
        ThemeColorClient.h
        ThemeColorClient.cpp
)

set_target_properties(appThemeColor PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appThemeColor
    PRIVATE
    Qt6::Quick
    Qt6::DBus
    Qt6::Core
)

include(GNUInstallDirs)
install(TARGETS appThemeColor
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
