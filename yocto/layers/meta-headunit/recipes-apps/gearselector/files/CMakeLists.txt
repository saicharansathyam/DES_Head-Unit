cmake_minimum_required(VERSION 3.16)
project(GearSelector LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.4 REQUIRED COMPONENTS Core Quick DBus)

add_executable(GearSelector
    main.cpp
    gs_handler.cpp
    gs_handler.h
)

# Add ONLY Main.qml to resources
qt_add_resources(GearSelector "qml"
    PREFIX "/"
    FILES
        Main.qml
)

target_link_libraries(GearSelector
    Qt6::Core
    Qt6::Quick
    Qt6::DBus
)

target_compile_definitions(GearSelector
    PRIVATE $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>
)