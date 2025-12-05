cmake_minimum_required(VERSION 3.16)
project(MediaPlayer LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find required Qt packages (including VirtualKeyboard)
find_package(Qt6 6.4 REQUIRED COMPONENTS
    Core
    Gui
    Qml
    Quick
    QuickControls2
    DBus
    WebView
    VirtualKeyboard
)

# Create the executable
add_executable(MediaPlayer
    main.cpp
    mp_handler.cpp
    mp_handler.h
    ../theme_client.cpp
    ../theme_client.h
    resources.qrc
)

# Link Qt libraries (including VirtualKeyboard)
target_link_libraries(MediaPlayer PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::DBus
    Qt6::WebView
    Qt6::VirtualKeyboard
)

target_compile_definitions(MediaPlayer PRIVATE
    $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>
)
