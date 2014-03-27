add_executable(test_bulletml
    test.d)
target_link_libraries(test_bulletml
    bulletml)
add_test(
    NAME    bulletml
    COMMAND test_bulletml)
