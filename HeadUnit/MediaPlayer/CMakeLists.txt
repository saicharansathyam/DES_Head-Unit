cmake_minimum_required(VERSION 3.16)

project(MediaPlayer VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Multimedia QuickControls2)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appMediaPlayer
    main.cpp
    mp_handler.cpp
    mp_handler.h
)

qt_add_qml_module(appMediaPlayer
    URI MediaPlayer
    VERSION 1.0
    QML_FILES
        Main.qml
)

target_link_libraries(appMediaPlayer
    PRIVATE Qt6::Quick
    PRIVATE Qt6::Multimedia
    PRIVATE Qt6::QuickControls2
    PRIVATE Qt6::DBus
)

include(GNUInstallDirs)
install(TARGETS appMediaPlayer
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
