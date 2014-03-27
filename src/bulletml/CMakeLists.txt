add_subdirectory(elements)

set(bulletml_srcs
    ${elements_srcs}

    parser.d
    runner.d
    )

add_library(bulletml STATIC
    ${bulletml_srcs})
