cmake_minimum_required(VERSION 3.16)
project(IVI_Compositor VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Quick WaylandCompositor)

qt_add_executable(appIVI_Compositor
    main.cpp
)

qt_add_qml_module(appIVI_Compositor
    URI compositor
    VERSION 1.0
    QML_FILES Main.qml
    RESOURCE_PREFIX /
    NO_RESOURCE_TARGET_PATH
)

target_link_libraries(appIVI_Compositor PRIVATE
    Qt6::Core
    Qt6::Quick
    Qt6::WaylandCompositor
)

install(TARGETS appIVI_Compositor
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
