add_subdirectory(data)
add_subdirectory(elements)

set(bulletml_srcs
    bulletml.d
    parser.d
    runner.d)
set(bulletml_private_srcs
    flatten.d)

add_library(bulletml STATIC
    ${bulletml_srcs}
    ${bulletml_private_srcs})
target_link_libraries(bulletml
    LINK_PUBLIC
        bulletml_data
    LINK_PRIVATE
        bulletml_elements)
set_target_properties(bulletml
    PROPERTIES
        ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
install(
    FILES       ${bulletml_srcs}
    DESTINATION "include/d/bulletml"
    COMPONENT   development)
install(
    TARGETS     bulletml
    EXPORT      bulletml
    DESTINATION lib
    COMPONENT   runtime)

# Export to the build tree.
export(
    TARGETS   bulletml_data
              bulletml
    NAMESPACE BulletML::
    FILE      "${CMAKE_BINARY_DIR}/bulletml-config-targets.cmake")
