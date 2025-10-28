cmake_minimum_required(VERSION 3.16)
project(GearSelector VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Quick)

qt_add_executable(GearSelector
    main.cpp
)

qt_add_qml_module(GearSelector
    URI gearselector
    VERSION 1.0
    QML_FILES Main_Test.qml
    RESOURCE_PREFIX /
    NO_RESOURCE_TARGET_PATH
)

target_link_libraries(GearSelector PRIVATE
    Qt6::Core
    Qt6::Quick
)

install(TARGETS GearSelector
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
