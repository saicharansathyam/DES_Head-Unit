cmake_minimum_required(VERSION 3.16)

project(GearSelector LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.5 COMPONENTS Quick DBus REQUIRED)

qt_add_executable(appGearSelector
    main.cpp
    gs_handler.cpp
    gs_handler.h
)

qt_add_qml_module(appGearSelector
    URI GearSelector
    VERSION 1.0
    QML_FILES
        Main.qml
)

target_link_libraries(appGearSelector 
    PRIVATE 
        Qt6::Quick
        Qt6::DBus
)

target_compile_definitions(appGearSelector
    PRIVATE $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>)
