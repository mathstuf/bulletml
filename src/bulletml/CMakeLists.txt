add_subdirectory(data)
add_subdirectory(elements)

set(bulletml_srcs
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
install(
    FILES       ${bulletml_srcs}
    DESTINATION "include/d/bulletml"
    COMPONENT   development)
install(
    TARGETS     bulletml
    EXPORT      bulletml
    DESTINATION lib
    COMPONENT   runtime)
