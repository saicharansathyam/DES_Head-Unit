cmake_minimum_required(VERSION 3.16)

project(NavigationGM VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Suppress XKB warnings on systems where it's not critical
set(CMAKE_MESSAGE_LOG_LEVEL WARNING)
set(CMAKE_WARN_DEPRECATED OFF)

# Find required packages
find_package(PkgConfig QUIET)
if(PkgConfig_FOUND)
    pkg_check_modules(XKB QUIET xkbcommon)
    if(XKB_FOUND)
        link_directories(${XKB_LIBRARY_DIRS})
    else()
        # If XKB is not found, create a dummy target to satisfy Qt6 dependencies
        if(NOT TARGET XKB::XKB)
            add_library(XKB::XKB INTERFACE IMPORTED)
        endif()
    endif()
endif()

# Find Qt6 - do NOT require Gui explicitly as Quick depends on it
find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2 VirtualKeyboard Location Positioning)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appNavigationGM
    main.cpp
)

qt_add_qml_module(appNavigationGM
    URI NavigationGM
    QML_FILES
        Main.qml
        MapView.qml
        SearchBar.qml
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appNavigationGM PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appNavigationGM
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appNavigationGM
    PRIVATE Qt6::Quick Qt6::QuickControls2 Qt6::VirtualKeyboard Qt6::Location Qt6::Positioning
)

include(GNUInstallDirs)
install(TARGETS appNavigationGM
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
