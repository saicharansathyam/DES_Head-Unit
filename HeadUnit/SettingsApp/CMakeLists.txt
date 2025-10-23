cmake_minimum_required(VERSION 3.16)

project(SettingsApp VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS
    Core
    Gui
    Qml
    Quick
    DBus
    Bluetooth
)

# Source files
set(SOURCES
    main.cpp
    settingsmanager.cpp
    wifimanager.cpp
    bluetoothmanager.cpp
)

# Header files
set(HEADERS
    settingsmanager.h
    wifimanager.h
    bluetoothmanager.h
)

# Create resources file
qt_add_resources(RESOURCES qml.qrc)

# Create executable
add_executable(Settings
    ${SOURCES}
    ${HEADERS}
    ${RESOURCES}
)

# Link libraries
target_link_libraries(Settings PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::DBus
    Qt6::Bluetooth
)

# Compiler flags
target_compile_options(Settings PRIVATE
    -Wall
    -Wextra
)

# Installation
install(TARGETS Settings
    RUNTIME DESTINATION bin
)
