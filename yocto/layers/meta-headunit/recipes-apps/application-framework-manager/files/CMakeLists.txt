# CMakeLists.txt (Simplified for development)
cmake_minimum_required(VERSION 3.16)

project(HeadUnitAFM VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS
    Core
    DBus
)

# Create executable
add_executable(headunit-afm
    main.cpp
    application_framework_manager.h
    application_framework_manager.cpp
)

# Link libraries
target_link_libraries(headunit-afm PRIVATE
    Qt6::Core
    Qt6::DBus
)

# Compiler flags
target_compile_options(headunit-afm PRIVATE
    -Wall
    -Wextra
)

# Create logs directory at build time
file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/logs)
# Install directive
install(TARGETS headunit-afm
    RUNTIME DESTINATION bin
)
