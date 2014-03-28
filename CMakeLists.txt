cmake_minimum_required(VERSION 2.8.12)
project(bulletml D)

option(BULLETML_ENABLE_TESTING "Enable testing" OFF)
if (BULLETML_ENABLE_TESTING)
    include(CTest)
endif ()

add_subdirectory(src)
