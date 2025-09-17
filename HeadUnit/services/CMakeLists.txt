# List of all services
set(SERVICES
    gear-service
    media-service
    ambient-service
)

foreach(svc ${SERVICES})
    add_executable(${svc} ${svc}/main.cpp)

    target_link_libraries(${svc} PRIVATE Qt6::Core)

    if(UNIX)
        target_link_libraries(${svc} PRIVATE Qt6::DBus)
    endif()
endforeach()