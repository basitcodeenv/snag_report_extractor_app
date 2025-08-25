cmake_minimum_required(VERSION 3.16)
project(mupdf_wrapper LANGUAGES C CXX)

# Build shared library
add_library(mupdf_wrapper SHARED
    mupdf_wrapper.c
)

# Where MuPDF headers live (adjust path)
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/mupdf/include
)

# Where MuPDF static libraries live (adjust path)
set(MUPDF_LIB_DIR ${CMAKE_CURRENT_SOURCE_DIR}/mupdf/build/release)

# Link platform-specific stuff
if (APPLE)
    # macOS build
    target_link_libraries(mupdf_wrapper
        ${MUPDF_LIB_DIR}/libmupdf.a
        ${MUPDF_LIB_DIR}/libmupdf-third.a
    )
elseif (WIN32)

    # target_include_directories(mupdf_wrapper PRIVATE
    #     ${CMAKE_CURRENT_SOURCE_DIR}/mupdf/include
    # )
    # Windows build
    target_link_libraries(mupdf_wrapper PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/mupdf/platform/win32/x64/Debug/libmupdf.lib
    )
else()
    # Linux build
    target_link_libraries(mupdf_wrapper
        ${MUPDF_LIB_DIR}/libmupdf.a
        ${MUPDF_LIB_DIR}/libmupdf-third.a
    )
endif()

# Example test program
add_executable(tester mupdf_wrapper_test.c)
target_link_libraries(tester PRIVATE mupdf_wrapper)
if (WIN32)
    target_link_libraries(tester PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/mupdf/platform/win32/x64/Debug/libmupdf.lib
    )
endif()

enable_testing()
add_test(NAME run_tester COMMAND tester)
