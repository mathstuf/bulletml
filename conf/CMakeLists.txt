configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/bulletml-config-build.cmake.in"
    "${CMAKE_BINARY_DIR}/bulletml-config-variables.cmake"
    @ONLY)
configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/bulletml-config-install.cmake.in"
    "${CMAKE_BINARY_DIR}/bulletml-config-install.cmake"
    @ONLY)
configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/bulletml-config-common.cmake.in"
    "${CMAKE_BINARY_DIR}/bulletml-config.cmake"
    @ONLY)

if (WIN32)
    set(cmakedir cmake)
else ()
    set(cmakedir lib${LIB_SUFFIX}/cmake/sprokit)
endif ()

install(
    FILES       "${CMAKE_BINARY_DIR}/bulletml-config.cmake"
    DESTINATION "${cmakedir}"
    COMPONENT   development
    RENAME      bulletml-config.cmake)
install(
    FILES       "${CMAKE_BINARY_DIR}/bulletml-config-install.cmake"
    DESTINATION "${cmakedir}"
    COMPONENT   development
    RENAME      bulletml-config-variables.cmake)
