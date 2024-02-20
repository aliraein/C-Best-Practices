include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


macro(C_Best_Practices_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)
    set(SUPPORTS_UBSAN ON)
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    set(SUPPORTS_ASAN ON)
  endif()
endmacro()

macro(C_Best_Practices_setup_options)
  option(C_Best_Practices_ENABLE_HARDENING "Enable hardening" ON)
  option(C_Best_Practices_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    C_Best_Practices_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    C_Best_Practices_ENABLE_HARDENING
    OFF)

  C_Best_Practices_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR C_Best_Practices_PACKAGING_MAINTAINER_MODE)
    option(C_Best_Practices_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(C_Best_Practices_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(C_Best_Practices_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(C_Best_Practices_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(C_Best_Practices_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(C_Best_Practices_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(C_Best_Practices_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(C_Best_Practices_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(C_Best_Practices_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(C_Best_Practices_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(C_Best_Practices_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(C_Best_Practices_ENABLE_PCH "Enable precompiled headers" OFF)
    option(C_Best_Practices_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(C_Best_Practices_ENABLE_IPO "Enable IPO/LTO" ON)
    option(C_Best_Practices_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(C_Best_Practices_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(C_Best_Practices_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(C_Best_Practices_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(C_Best_Practices_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(C_Best_Practices_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(C_Best_Practices_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(C_Best_Practices_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(C_Best_Practices_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(C_Best_Practices_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(C_Best_Practices_ENABLE_PCH "Enable precompiled headers" OFF)
    option(C_Best_Practices_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      C_Best_Practices_ENABLE_IPO
      C_Best_Practices_WARNINGS_AS_ERRORS
      C_Best_Practices_ENABLE_USER_LINKER
      C_Best_Practices_ENABLE_SANITIZER_ADDRESS
      C_Best_Practices_ENABLE_SANITIZER_LEAK
      C_Best_Practices_ENABLE_SANITIZER_UNDEFINED
      C_Best_Practices_ENABLE_SANITIZER_THREAD
      C_Best_Practices_ENABLE_SANITIZER_MEMORY
      C_Best_Practices_ENABLE_UNITY_BUILD
      C_Best_Practices_ENABLE_CLANG_TIDY
      C_Best_Practices_ENABLE_CPPCHECK
      C_Best_Practices_ENABLE_COVERAGE
      C_Best_Practices_ENABLE_PCH
      C_Best_Practices_ENABLE_CACHE)
  endif()

  C_Best_Practices_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (C_Best_Practices_ENABLE_SANITIZER_ADDRESS OR C_Best_Practices_ENABLE_SANITIZER_THREAD OR C_Best_Practices_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(C_Best_Practices_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(C_Best_Practices_global_options)
  if(C_Best_Practices_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    C_Best_Practices_enable_ipo()
  endif()

  C_Best_Practices_supports_sanitizers()

  if(C_Best_Practices_ENABLE_HARDENING AND C_Best_Practices_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR C_Best_Practices_ENABLE_SANITIZER_UNDEFINED
       OR C_Best_Practices_ENABLE_SANITIZER_ADDRESS
       OR C_Best_Practices_ENABLE_SANITIZER_THREAD
       OR C_Best_Practices_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${C_Best_Practices_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${C_Best_Practices_ENABLE_SANITIZER_UNDEFINED}")
    C_Best_Practices_enable_hardening(C_Best_Practices_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(C_Best_Practices_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(C_Best_Practices_warnings INTERFACE)
  add_library(C_Best_Practices_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  C_Best_Practices_set_project_warnings(
    C_Best_Practices_warnings
    ${C_Best_Practices_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(C_Best_Practices_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    configure_linker(C_Best_Practices_options)
  endif()

  include(cmake/Sanitizers.cmake)
  C_Best_Practices_enable_sanitizers(
    C_Best_Practices_options
    ${C_Best_Practices_ENABLE_SANITIZER_ADDRESS}
    ${C_Best_Practices_ENABLE_SANITIZER_LEAK}
    ${C_Best_Practices_ENABLE_SANITIZER_UNDEFINED}
    ${C_Best_Practices_ENABLE_SANITIZER_THREAD}
    ${C_Best_Practices_ENABLE_SANITIZER_MEMORY})

  set_target_properties(C_Best_Practices_options PROPERTIES UNITY_BUILD ${C_Best_Practices_ENABLE_UNITY_BUILD})

  if(C_Best_Practices_ENABLE_PCH)
    target_precompile_headers(
      C_Best_Practices_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(C_Best_Practices_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    C_Best_Practices_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(C_Best_Practices_ENABLE_CLANG_TIDY)
    C_Best_Practices_enable_clang_tidy(C_Best_Practices_options ${C_Best_Practices_WARNINGS_AS_ERRORS})
  endif()

  if(C_Best_Practices_ENABLE_CPPCHECK)
    C_Best_Practices_enable_cppcheck(${C_Best_Practices_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(C_Best_Practices_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    C_Best_Practices_enable_coverage(C_Best_Practices_options)
  endif()

  if(C_Best_Practices_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(C_Best_Practices_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(C_Best_Practices_ENABLE_HARDENING AND NOT C_Best_Practices_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR C_Best_Practices_ENABLE_SANITIZER_UNDEFINED
       OR C_Best_Practices_ENABLE_SANITIZER_ADDRESS
       OR C_Best_Practices_ENABLE_SANITIZER_THREAD
       OR C_Best_Practices_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    C_Best_Practices_enable_hardening(C_Best_Practices_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
