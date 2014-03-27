cmake_minimum_required(VERSION 2.8.12)
project(bulletml D)

option(BULLETML_ENABLE_TESTING "Enable testing" OFF)

add_subdirectory(src)

if (BULLETML_ENABLE_TESTING)
    include(CTest)

    add_subdirectory(test)
endif ()
