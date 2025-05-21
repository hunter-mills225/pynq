cmake_minimum_required(VERSION 3.1)

project(
  UNITTESTS
  VERSION 1.0
  LANGUAGES CXX)

set (CMAKE_CXX_STANDARD 11)

find_package(Catch2 REQUIRED)


add_executable(modem_test modem_unittest.cpp)

target_link_libraries(modem_test
    Catch2::Catch2WithMain
    )

enable_testing()
add_test(test_all modem_test)
