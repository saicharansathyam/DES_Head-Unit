cmake_minimum_required(VERSION 3.16)
project(ivi-compositor VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS
    Core
    Gui
    Qml
    Quick
    WaylandCompositor
    DBus
)

# Create resources from qml.qrc
qt_add_resources(RESOURCES qml.qrc)

# Create executable
add_executable(ivi-compositor
    main.cpp
    dbus_manager.h
    dbus_manager.cpp
    ${RESOURCES}
)

# Link libraries
target_link_libraries(ivi-compositor PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::WaylandCompositor
    Qt6::DBus
)

# Compiler flags
target_compile_options(ivi-compositor PRIVATE
    -Wall
    -Wextra
)

# Installation
install(TARGETS ivi-compositor
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
