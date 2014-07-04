set(data_srcs
    accel.d
    action.d
    bullet.d
    bulletml.d
    change.d
    changedirection.d
    changespeed.d
    direction.d
    expression.d
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

add_library(bulletml_data STATIC
    ${data_srcs})
set_target_properties(bulletml_data
    PROPERTIES
        ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
install(
    FILES       ${bulletml_srcs}
    DESTINATION "include/d/bulletml/data"
    COMPONENT   development)
install(
    TARGETS     bulletml_data
    EXPORT      bulletml
    DESTINATION lib
    COMPONENT   runtime)

if (BULLETML_ENABLE_TESTING)
    add_executable(test_bulletml_data
        expression.d

        _test.d)
    set_target_properties(test_bulletml_data
        PROPERTIES
            COMPILE_FLAGS -funittest)
    add_test(
        NAME    bulletml_data
        COMMAND test_bulletml_data)
endif ()
