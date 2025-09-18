cmake_minimum_required(VERSION 3.16)

project(GearSelector LANGUAGES CXX)

# Enable Qt's automatic processing
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 6.5 COMPONENTS Quick REQUIRED)

set(QT_QML_GENERATE_QMLLS_INI ON)

# The executable binary
qt_add_executable(appGearSelector
    main.cpp
    gs_handler.cpp
    gs_handler.h
)

# Register QML files as a module inside the executable
qt_add_qml_module(appGearSelector
    URI GearSelector
    VERSION 1.0
    QML_FILES
        Main.qml
    RESOURCE_PREFIX /
)

target_link_libraries(appGearSelector
    PRIVATE
        Qt6::Quick
)
