set(elements_srcs
    _element.d

    accel.d
    action.d
    bullet.d
    bulletml.d
    changedirection.d
    changespeed.d
    direction.d
    fire.d
    horizontal.d
    oref.d
    param.d
    repeat.d
    speed.d
    term.d
    times.d
    vanish.d
    vertical.d
    wait.d)

add_library(bulletml_elements STATIC
    ${elements_srcs})
set_target_properties(bulletml_data
    PROPERTIES
        ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
set_target_properties(bulletml_elements
    PROPERTIES
        ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
install(
    TARGETS     bulletml_elements
    EXPORT      bulletml
    DESTINATION lib
    COMPONENT   runtime)
