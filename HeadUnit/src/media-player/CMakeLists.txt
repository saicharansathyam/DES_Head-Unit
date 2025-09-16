set(QML_FILES
    MediaPlayer.qml
)

qt_add_executable(media_player
    media-main.cpp
    ${QML_FILES}
)

target_link_libraries(media_player PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
)
