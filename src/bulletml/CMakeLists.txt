add_subdirectory(elements)

set(bulletml_srcs
    ${elements_srcs}
    )

add_library(bulletml
    ${bulletml_srcs})
