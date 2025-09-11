# Enable Qt features for QML and Widgets
find_package(Qt6 6.2 COMPONENTS Quick Widgets REQUIRED)

set(QML_SOURCES
    qml/Main.qml
    qml/Dashboard.qml
    qml/MediaPlayer.qml
    qml/Settings.qml
    qml/components/MediaControl.qml
    qml/components/Navigation.qml
    qml/components/VehicleStatus.qml
    styles/Colors.qml
    styles/Fonts.qml
)

qt_add_resources(HMI_RESOURCES qml.qrc)

add_library(hmi STATIC
    ${HMI_RESOURCES}
)

target_sources(hmi PRIVATE ${QML_SOURCES})

target_link_libraries(hmi
    Qt6::Quick
    Qt6::Widgets
    common
)

target_compile_features(hmi PUBLIC cxx_std_17)
