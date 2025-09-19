cmake_minimum_required(VERSION 3.16)

project(IVI_Compositor VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Core WaylandCompositor)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appIVI_Compositor
    main.cpp
)

qt_add_qml_module(appIVI_Compositor
    URI IVI_Compositor
    VERSION 1.0
    QML_FILES
        Main.qml
        SOURCES ivi_compositor.h ivi_compositor.cpp
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appIVI_Compositor PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appIVI_Compositor
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appIVI_Compositor
    PRIVATE Qt6::Quick
    PRIVATE Qt6::Core
    PRIVATE Qt6::WaylandCompositor
)

include(GNUInstallDirs)
install(TARGETS appIVI_Compositor
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
