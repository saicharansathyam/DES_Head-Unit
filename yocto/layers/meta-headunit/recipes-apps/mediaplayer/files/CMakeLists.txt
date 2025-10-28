cmake_minimum_required(VERSION 3.16)
project(MediaPlayer LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.4 REQUIRED COMPONENTS Core Quick DBus Multimedia)

add_executable(MediaPlayer
    main.cpp
    mp_handler.cpp
    mp_handler.h
)

qt_add_resources(MediaPlayer "qml"
    PREFIX "/"
    FILES
        Main.qml
        Main_Test.qml
)

target_link_libraries(MediaPlayer
    PRIVATE
      Qt6::Core
      Qt6::Quick
      Qt6::DBus
      Qt6::Multimedia
)

target_compile_definitions(MediaPlayer
    PRIVATE $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>
)