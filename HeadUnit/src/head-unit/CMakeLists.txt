set(QML_FILES
    MainCompositor.qml
)

qt_add_executable(head_unit
    main.cpp
    ${QML_FILES}
)

target_link_libraries(head_unit PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
)
