include(ExternalProject)

set(data_base_dir "${CMAKE_CURRENT_BINARY_DIR}/data")
set(data_dir "${data_base_dir}/src/bulletml-examples-data")
externalproject_add(bulletml-examples-data
  GIT_REPOSITORY https://github.com/dmanning23/BulletMLExamples
  GIT_TAG        master

  PREFIX            "${data_base_dir}"

  CONFIGURE_COMMAND ""
  BUILD_COMMAND     ""
  INSTALL_COMMAND   "")

include_directories("${CMAKE_SOURCE_DIR}/src")

add_executable(test_parse
  test_parse.d)
target_link_libraries(test_parse
  bulletml)

add_executable(test_resolve
  test_resolve.d)
target_link_libraries(test_resolve
  bulletml)

file(GLOB_RECURSE examples
  RELATIVE "${data_dir}"
  "${data_dir}/*.xml")

foreach (example IN LISTS examples)
  string(REPLACE "/" "_" safe_example "${example}")
  string(REPLACE "[" "{" safe_example "${safe_example}")
  string(REPLACE "]" "}" safe_example "${safe_example}")

  add_test(
    NAME    "parse-${safe_example}"
    COMMAND "$<TARGET_FILE:test_parse>"
            "${data_dir}/${example}")
  add_test(
    NAME    "resolve-${safe_example}"
    COMMAND "$<TARGET_FILE:test_resolve>"
            "${data_dir}/${example}")
  set_tests_properties("resolve-${safe_example}"
    PROPERTIES
      DEPENDS "parse-${safe_example}")
endforeach ()
