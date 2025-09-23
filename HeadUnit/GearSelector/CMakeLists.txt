cmake_minimum_required(VERSION 3.16)
project(GearSelector LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.4 REQUIRED COMPONENTS Core Quick DBus)

# Create the executable
add_executable(appGearSelector
    main.cpp
    gs_handler.cpp
    gs_handler.h
)

# Create a resource file for QML
qt_add_resources(appGearSelector "qml"
    PREFIX "/"
    FILES
        Main.qml
)

# Link libraries
target_link_libraries(appGearSelector
    Qt6::Core
    Qt6::Quick
    Qt6::DBus
)

# Set compile definitions
target_compile_definitions(appGearSelector
    PRIVATE $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>
)