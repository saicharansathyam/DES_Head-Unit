cmake_minimum_required(VERSION 3.16)

project(IVI_Compositor VERSION 1.0 LANGUAGES CXX)

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
)
find_package(Qt6 REQUIRED COMPONENTS Core)
find_package(Qt6 REQUIRED COMPONENTS DBus)

# Create resources file
qt_add_resources(RESOURCES qml.qrc)

# Create executable
add_executable(headUnit
    main.cpp
    ${RESOURCES}
    qml.qrc
    dbus_manager.h dbus_manager.cpp

)

# Link libraries
target_link_libraries(headUnit PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::WaylandCompositor
)
target_link_libraries(headUnit PRIVATE Qt6::Core)
target_link_libraries(headUnit PRIVATE Qt6::DBus)

# Compiler flags
target_compile_options(headUnit PRIVATE
    -Wall
    -Wextra
)

# Installation
install(TARGETS headUnit
    RUNTIME DESTINATION bin
)

