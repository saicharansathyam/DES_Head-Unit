cmake_minimum_required(VERSION 3.16)
project(GearSelector LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.4 REQUIRED COMPONENTS Core Quick DBus)

# Create resources file
qt_add_resources(RESOURCES qml.qrc)


# Create the executable
add_executable(GearSelector
    main.cpp
    gs_handler.cpp
    gs_handler.h
    ../theme_client.cpp
    ../theme_client.h
    ${RESOURCES}
)

# Link libraries
target_link_libraries(GearSelector
    Qt6::Core
    Qt6::Quick
    Qt6::DBus
)

# Set compile definitions
target_compile_definitions(GearSelector
    PRIVATE $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>
)
