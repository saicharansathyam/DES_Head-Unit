cmake_minimum_required(VERSION 3.16)
project(SettingsApp VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick DBus)

qt_add_resources(RESOURCES qml.qrc)

add_executable(settingsApp
    main.cpp
    dbus_handler.h
    dbus_handler.cpp
    ../theme_client.h
    ../theme_client.cpp
    ${RESOURCES}
)

target_link_libraries(settingsApp PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::DBus
)

target_compile_options(settingsApp PRIVATE -Wall -Wextra)

install(TARGETS settingsApp RUNTIME DESTINATION bin)
