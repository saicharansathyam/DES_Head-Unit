add_executable(head_unit
    main.cpp
    head-unit-app.cpp
    head-unit-app.h
)

find_package(Qt6 REQUIRED COMPONENTS Core Quick Gui)

target_include_directories(head_unit PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/head-unit)

target_link_libraries(head_unit PRIVATE Qt6::Core Qt6::Quick Qt6::Widgets Qt6::Gui)
