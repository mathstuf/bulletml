add_subdirectory(elements)

set(bulletml_srcs
    parser.d
    runner.d
    )

add_library(bulletml STATIC
    ${bulletml_srcs})
target_link_libraries(bulletml
    LINK_PUBLIC
        bulletml_elements)
