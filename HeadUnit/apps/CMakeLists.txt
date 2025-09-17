# apps/CMakeLists.txt
cmake_minimum_required(VERSION 3.16)

set(APPS
    gear-selector
    media-player
    ambient-lighting
    head-unit
)

set(QRC_FILE ${CMAKE_CURRENT_SOURCE_DIR}/resources/qml.qrc)

foreach(app ${APPS})
    qt_add_executable(${app}
        ${CMAKE_CURRENT_SOURCE_DIR}/${app}/main.cpp
        ${QRC_FILE}   # shared qrc with all QML files
    )

    target_link_libraries(${app} PRIVATE
        Qt6::Core
        Qt6::Gui
        Qt6::Qml
        Qt6::Quick
    )

    if(UNIX)
        target_link_libraries(${app} PRIVATE Qt6::DBus)
    endif()

    target_compile_features(${app} PUBLIC cxx_std_17)
endforeach()

