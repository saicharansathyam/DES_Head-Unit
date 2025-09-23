cmake_minimum_required(VERSION 3.16)
project(MediaPlayer LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ADD Gui, Qml, QuickControls2
find_package(Qt6 6.4 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 DBus Multimedia)

add_executable(appMediaPlayer
    main.cpp
    mp_handler.cpp
    mp_handler.h
)

qt_add_resources(appMediaPlayer "qml"
    PREFIX "/MediaPlayer"
    FILES
        Main.qml
)

# LINK QuickControls2 (and Gui/Qml)
target_link_libraries(appMediaPlayer
    PRIVATE
      Qt6::Core
      Qt6::Gui
      Qt6::Qml
      Qt6::Quick
      Qt6::QuickControls2
      Qt6::DBus
      Qt6::Multimedia
)

target_compile_definitions(appMediaPlayer
    PRIVATE $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>
)
