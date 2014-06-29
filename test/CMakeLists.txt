include(ExternalProject)

externalproject_add(bulletml-examples-data
  GIT_REPOSITORY https://github.com/dmanning23/BulletMLExamples
  GIT_TAG        master

  PREFIX            "${CMAKE_CURRENT_BINARY_DIR}/data"

  CONFIGURE_COMMAND ""
  BUILD_COMMAND     ""
  INSTALL_COMMAND   "")

include_directories("${CMAKE_SOURCE_DIR}/src")

add_executable(test_parse
  test_parse.d)
target_link_libraries(test_parse
  bulletml)
add_test(
  NAME    parse-examples-all
  COMMAND "$<TARGET_FILE:test_parse>"
          "${CMAKE_CURRENT_BINARY_DIR}/data")
