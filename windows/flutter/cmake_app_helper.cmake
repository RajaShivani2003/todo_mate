# cmake-format: off
# cmake-lint: disable=C0103
# cmake-lint: disable=C0111
# Dart file package-internal build system

cmake_minimum_required(VERSION 3.14)

set(EMBEDDER_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../flutter/include")
set(FLUTTER_LIBRARY "${CMAKE_CURRENT_SOURCE_DIR}/../flutter/engine/windows-x64/flutter_windows.dll")

# Published to other packages.
add_library(flutter SHARED IMPORTED)
set_target_properties(flutter PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${EMBEDDER_INCLUDE_DIR}"
  IMPORTED_LOCATION "${FLUTTER_LIBRARY}"
)
add_library(flutter_wrapper_app SHARED IMPORTED)
set_target_properties(flutter_wrapper_app PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${EMBEDDER_INCLUDE_DIR}"
  IMPORTED_LOCATION "${CMAKE_CURRENT_SOURCE_DIR}/../flutter/engine/windows-x64/flutter_wrapper_app.dll"
)
add_library(flutter_wrapper_plugin SHARED IMPORTED)
set_target_properties(flutter_wrapper_plugin PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${EMBEDDER_INCLUDE_DIR}"
  IMPORTED_LOCATION "${CMAKE_CURRENT_SOURCE_DIR}/../flutter/engine/windows-x64/flutter_wrapper_plugin.dll"
)
add_library(flutter_wrapper_utils SHARED IMPORTED)
set_target_properties(flutter_wrapper_utils PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${EMBEDDER_INCLUDE_DIR}"
  IMPORTED_LOCATION "${CMAKE_CURRENT_SOURCE_DIR}/../flutter/engine/windows-x64/flutter_wrapper_utils.dll"
)
add_library(flutter_wrapper_cpp SHARED IMPORTED)
set_target_properties(flutter_wrapper_cpp PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${EMBEDDER_INCLUDE_DIR}"
  IMPORTED_LOCATION "${CMAKE_CURRENT_SOURCE_DIR}/../flutter/engine/windows-x64/flutter_wrapper_cpp.dll"
)

# flutter_gen_res
add_library(flutter_gen_res SHARED IMPORTED)
set_target_properties(flutter_gen_res PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${EMBEDDER_INCLUDE_DIR}"
  IMPORTED_LOCATION "${CMAKE_CURRENT_SOURCE_DIR}/../flutter/engine/windows-x64/flutter_gen_res.dll"
)

# flutter_assemble
add_custom_command(
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/flutter_assets"
    COMMAND "${CMAKE_CURRENT_SOURCE_DIR}/../flutter/bin/flutter" build bundle
        --output-dir="${CMAKE_CURRENT_BINARY_DIR}/flutter_assets"
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/.."
    COMMENT "Running Flutter build to copy assets"
    VERBATIM
)
add_custom_target(flutter_assemble DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/flutter_assets")
