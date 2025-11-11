cmake_minimum_required(VERSION 3.16)

project(ThemeColor VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Quick DBus)

# Create QML resource file
qt_add_resources(QML_RESOURCES qml.qrc)

# Create executable
add_executable(ThemeColor
    main.cpp
    ThemeColorClient.h
    ThemeColorClient.cpp
    ${QML_RESOURCES}
    qml.qrc
)

target_link_libraries(ThemeColor
    PRIVATE
    Qt6::Quick
    Qt6::DBus
    Qt6::Core
)

# Install to applications directory
install(TARGETS ThemeColor
    RUNTIME DESTINATION /home/seame/Documents/GitHub/DES_Head-Unit/HeadUnit/applications
)
