if(WIN32)
 set(BOOST_DEBUG ON)
  if(DEFINED ENV{BOOST_ROOT})
    set(BOOST_ROOT $ENV{BOOST_ROOT})
    if(MSVC_TOOLSET_VERSION VERSION_LESS 140)
      set(BOOST_LIBRARYDIR ${BOOST_ROOT}/lib${PLATFORM}-msvc-12.0)
    elseif(MSVC_TOOLSET_VERSION VERSION_LESS 141)
      set(BOOST_LIBRARYDIR ${BOOST_ROOT}/lib${PLATFORM}-msvc-14.0)
    else()
      if (MSVC_TOOLSET_VERSION VERSION_LESS 142)
        list(APPEND BOOST_LIBRARYDIR
          ${BOOST_ROOT}/lib${PLATFORM}-msvc-14.1
          ${BOOST_ROOT}/lib${PLATFORM}-msvc-14.0 )
      else()
        list(APPEND BOOST_LIBRARYDIR
          ${BOOST_ROOT}/lib${PLATFORM}-msvc-14.2
          ${BOOST_ROOT}/lib${PLATFORM}-msvc-14.1 )
      endif()
    endif()
  else()
    message(FATAL_ERROR "No BOOST_ROOT environment variable could be found! Please make sure it is set and the points to your Boost installation.")
  endif()

  set(Boost_USE_STATIC_LIBS        ON)
  set(Boost_USE_MULTITHREADED      ON)
  set(Boost_USE_STATIC_RUNTIME     OFF)
endif()

find_package(Boost 1.60 REQUIRED system filesystem thread program_options iostreams regex)
add_definitions(-DBOOST_DATE_TIME_NO_LIB)
add_definitions(-DBOOST_REGEX_NO_LIB)
add_definitions(-DBOOST_CHRONO_NO_LIB)
add_definitions(-DBOOST_OPTIONAL_USE_OLD_DEFINITION_OF_NONE)
add_definitions(-DBOOST_SERIALIZATION_NO_LIB)
add_definitions(-DBOOST_CONFIG_SUPPRESS_OUTDATED_MESSAGE)
add_definitions(-DBOOST_ASIO_NO_DEPRECATED)

# Find if Boost was compiled in C++03 mode because it requires -DBOOST_NO_CXX11_SCOPED_ENUMS

include (CheckCXXSourceCompiles)

set(CMAKE_REQUIRED_INCLUDES ${Boost_INCLUDE_DIR})
set(CMAKE_REQUIRED_LIBRARIES ${Boost_SYSTEM_LIBRARY} ${Boost_FILESYSTEM_LIBRARY} ${Boost_IOSTREAMS_LIBRARY})
set(CMAKE_REQUIRED_FLAGS "-std=c++11")
unset(boost_filesystem_copy_links_without_NO_SCOPED_ENUM CACHE)
check_cxx_source_compiles("
  #include <boost/filesystem/path.hpp>
  #include <boost/filesystem/operations.hpp>
  int main() { boost::filesystem::copy_file(boost::filesystem::path(), boost::filesystem::path()); }"
boost_filesystem_copy_links_without_NO_SCOPED_ENUM)
unset(CMAKE_REQUIRED_INCLUDES CACHE)
unset(CMAKE_REQUIRED_LIBRARIES CACHE)
unset(CMAKE_REQUIRED_FLAGS CACHE)

if (NOT boost_filesystem_copy_links_without_NO_SCOPED_ENUM)
  add_definitions(-DBOOST_NO_CXX11_SCOPED_ENUMS)
endif()

if (Boost_FOUND)
  include_directories(${Boost_INCLUDE_DIRS})
  
  if ("${CMAKE_SYSTEM_NAME}" MATCHES "Darwin") # MacOS es especial y por algun motivo no esta enlazando los pch bien, asi de momento para arreglar la build linkeamos al proyecto
    link_libraries(${Boost_LIBRARIES})
  endif()
endif()
