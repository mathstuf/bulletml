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
        ${data_srcs}
        _all.d
        _test.d)
    add_test(
        NAME    bulletml_data
        COMMAND test_bulletml_data)
endif ()
