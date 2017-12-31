cmake_minimum_required(VERSION 3.0)
enable_testing()

project(SqueezeDet)
set(SqueezeDet_VERSION_MAJOR 1)
set(SqueezeDet_VERSION_MINOR 0)

set(CMAKE_CXX_COMPILER "clang++")
set(CMAKE_CXX_FLAGS "-std=c++14 -O3 -Wall -Wno-deprecated-declarations")
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR})

find_package(FFMPEG REQUIRED)
include_directories(${FFMPEG_INCLUDE_DIRS})

find_package(OpenCV REQUIRED)
include_directories(${OpenCV_INCLUDE_DIRS})

file(GLOB src_files "../files/[!(main)]*.cpp")
include_directories(../files)
add_library(squeezedet STATIC ${src_files})

file(GLOB test_files "test_*.cpp")
foreach(test ${test_files})
  get_filename_component(test_name ${test} NAME_WE)

  add_executable(${test_name} ${test})
  target_link_libraries(${test_name} squeezedet)
  target_link_libraries(${test_name} ${OpenCV_LIBS})
  target_link_libraries(${test_name} ${FFMPEG_LIBRARIES})

  add_test(${test_name} "${CMAKE_CURRENT_BINARY_DIR}/${test_name}")
endforeach()
