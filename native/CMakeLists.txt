cmake_minimum_required(VERSION 3.20)
project(minerva_native_bridge C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

option(MINERVA_BUILD_SMOKE_TEST "Build native smoke test executable" ON)
option(MINERVA_FETCH_SDL3 "Fetch SDL3 source when system package is unavailable" ON)

find_package(SDL3 QUIET CONFIG)

if(NOT SDL3_FOUND)
    if(MINERVA_FETCH_SDL3)
        include(FetchContent)
        message(STATUS "SDL3 package not found; fetching SDL3 from GitHub")
        FetchContent_Declare(
            SDL3
            GIT_REPOSITORY https://github.com/libsdl-org/SDL.git
            GIT_TAG main
        )
        FetchContent_MakeAvailable(SDL3)
    else()
        message(FATAL_ERROR "SDL3 not found. Install SDL3 dev package or enable MINERVA_FETCH_SDL3.")
    endif()
endif()

add_library(minerva_native SHARED
    src/minerva_native.c
)

target_include_directories(minerva_native
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_link_libraries(minerva_native
    PRIVATE
        SDL3::SDL3
)

set_target_properties(minerva_native PROPERTIES
    OUTPUT_NAME "minerva_native"
)

if(MINERVA_BUILD_SMOKE_TEST)
    add_executable(minerva_native_smoke
        tests/smoke_native.c
    )

    target_include_directories(minerva_native_smoke
        PRIVATE
            ${CMAKE_CURRENT_SOURCE_DIR}/include
    )

    target_link_libraries(minerva_native_smoke
        PRIVATE
            minerva_native
    )
endif()
