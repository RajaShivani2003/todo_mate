cmake_minimum_required(VERSION 3.14)
project(todo_app LANGUAGES CXX)

set(BINARY_NAME "todo_app")

cmake_policy(SET CMP0079 NEW)

set(CMAKE_ASM_COMPILER "${FLUTTER_DIR}/bin/cache/artifacts/engine/windows-x64/dart-sdk/bin/dart" CACHE STRING "" FORCE)

list(APPEND CMAKE_PROJECT_INCLUDE_BEFORE "${CMAKE_CURRENT_SOURCE_DIR}/flutter/cmake_app_helper.cmake")
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/flutter")

add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/flutter" "${CMAKE_CURRENT_BINARY_DIR}/flutter")

set(WINDOWS_BUNDLE_LIBS "${BINARY_NAME}")

add_executable(${BINARY_NAME} WIN32
  "runner/flutter_window.cpp"
  "runner/main.cpp"
  "runner/utils.cpp"
  "runner/win32_application.cpp"
  "runner/win32_window.cpp"
  "runner/utils.cpp"
  "runner/flutter_window.cpp"
  "runner/main.cpp"
  "runner/resource.h"
  "${CMAKE_CURRENT_SOURCE_DIR}/runner/resources/app_icon.rc"
)
set_target_properties(${BINARY_NAME} PROPERTIES
  WINDOWS_PACKAGE_LOCATION "${CMAKE_CURRENT_BINARY_DIR}"
  VS_DEBUGGER_COMMAND_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/runner"
)
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/runner")
add_dependencies(${BINARY_NAME} flutter_assemble)

install(DESTINATION "bin" COMPONENT Runtime)
install(DESTINATION "data/flutter_assets" COMPONENT Runtime)

if(WIN32)
  set_target_properties(${BINARY_NAME} PROPERTIES
    VS_DEBUGGER_COMMAND "${CMAKE_CURRENT_SOURCE_DIR}/runner/$<TARGET_FILE_DIR:${BINARY_NAME}>/${BINARY_NAME}.exe"
    VS_DEBUGGER_COMMAND_ARGUMENTS "."
    VS_DEBUGGER_ENVIRONMENT "FLUTTER_SKIP_PRECONDITION_CHECK=1"
  )
endif()
