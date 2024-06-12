# 
# Generate RTT typekits and plugins for using ROS .msg messages and .srv
# services
#

cmake_minimum_required(VERSION 2.8.3)

@[if DEVELSPACE]@
  set(rtt_roscomm_TEMPLATES_DIR @(PROJECT_SOURCE_DIR)/src/templates)
  set(rtt_roscomm_SCRIPTS_DIR @(PROJECT_SOURCE_DIR)/scripts)
@[else]@
  set(rtt_roscomm_TEMPLATES_DIR ${rtt_roscomm_DIR}/../src/templates)
  set(rtt_roscomm_SCRIPTS_DIR @(CMAKE_INSTALL_PREFIX)/@(CATKIN_PACKAGE_BIN_DESTINATION))
@[end if]@

macro(rtt_roscomm_destinations)
  if(ORO_USE_ROSBUILD)
    #message(STATUS "[ros_generate_rtt_typekit] Generating ROS typekit for ${PROJECT_NAME} with ROSBuild destinations.")
    set(rtt_roscomm_GENERATED_HEADERS_OUTPUT_DIRECTORY    "${PROJECT_SOURCE_DIR}/include")
    set(rtt_roscomm_GENERATED_HEADERS_INSTALL_DESTINATION)
  elseif(ORO_USE_CATKIN)
    #message(STATUS "[ros_generate_rtt_typekit] Generating ROS typekit for ${PROJECT_NAME} with Catkin destinations.")
    catkin_destinations()
    set(rtt_roscomm_GENERATED_HEADERS_OUTPUT_DIRECTORY    "${CATKIN_DEVEL_PREFIX}/include")
    set(rtt_roscomm_GENERATED_HEADERS_INSTALL_DESTINATION "${CATKIN_GLOBAL_INCLUDE_DESTINATION}")
  else()
    #message(STATUS "[ros_generate_rtt_typekit] Generating ROS typekit for ${PROJECT_NAME} with normal CMake destinations.")
    set(rtt_roscomm_GENERATED_HEADERS_OUTPUT_DIRECTORY    "${PROJECT_BINARY_DIR}/include")
    set(rtt_roscomm_GENERATED_HEADERS_INSTALL_DESTINATION "${CMAKE_INSTALL_PREFIX}/include")
  endif()

  if(DEFINED ENV{VERBOSE_CONFIG})
    message(STATUS "[ros_generate_rtt_typekit]   Generating headers in: ${rtt_roscomm_GENERATED_HEADERS_OUTPUT_DIRECTORY}")
    message(STATUS "[ros_generate_rtt_typekit]   Installing headers to: ${rtt_roscomm_GENERATED_HEADERS_INSTALL_DESTINATION}")
  endif()
endmacro()

macro(rtt_roscomm_debug)
  if(DEFINED ENV{VERBOSE_CONFIG})
    message(STATUS "[ros_generate_rtt_typekit]     catkin_INCLUDE_DIRS: ${catkin_INCLUDE_DIRS}")
  endif()
endmacro()

macro(ros_generate_rtt_typekit package)
  cmake_parse_arguments(ros_generate_rtt_typekit "" "" "EXTRA_INCLUDES" ${ARGN})

  find_package(rtt_${package} QUIET)

  if(NOT rtt_${package}_FOUND AND NOT TARGET rtt-${package}-typekit)
    set(_include_dirs)
    set(_pkg_libs)
    set(_msg_exported_targets)
    set(_typekit_targets)
    set(_transport_targets)
    set(_mqueue_targets)
    set(_corba_targets)

    include(${${package}_PREFIX}/${CATKIN_GLOBAL_SHARE_DESTINATION}/${package}/cmake/${package}-msg-paths.cmake)

    foreach(dep ${${package}_MSG_DEPENDENCIES})
      find_package(${dep} QUIET)

      if(${dep}_FOUND)
        list(APPEND _include_dirs ${${dep}_INCLUDE_DIRS})
        list(APPEND _pkg_libs ${${dep}_LIBRARIES})
        list(APPEND _msg_exported_targets ${${dep}_EXPORTED_TARGETS})

        find_package(rtt_${dep} QUIET)

        if(NOT rtt_${dep}_FOUND AND NOT TARGET rtt-${dep}-typekit)
          ros_generate_rtt_typekit(${dep})
        endif()
        
        if(rtt_${dep}_FOUND)
          list(APPEND _pkg_libs ${rtt_${dep}_LIBRARIES})
        endif()

        if(TARGET rtt-${dep}-typekit)
          list(APPEND _typekit_targets rtt-${dep}-typekit)
        endif()

        if(TARGET rtt-${dep}-ros-transport)
          list(APPEND _transport_targets rtt-${dep}-ros-transport)
        endif()

        if(TARGET rtt-${dep}-ros-transport-mqueue)
          list(APPEND _mqueue_targets rtt-${dep}-ros-transport-mqueue)
        endif()

        if(TARGET rtt-${dep}-ros-transport-corba)
          list(APPEND _corba_targets rtt-${dep}-ros-transport-corba)
        endif()
      endif()
    endforeach()

    set(_package ${package})
    add_subdirectory(${rtt_roscomm_TEMPLATES_DIR}/typekit ${package}_typekit)
  endif()
endmacro(ros_generate_rtt_typekit)

macro(ros_generate_rtt_service_proxies package)
  cmake_parse_arguments(ros_generate_rtt_service_proxies "" "" "EXTRA_INCLUDES" ${ARGN})

  find_package(rtt_${package} QUIET)

  if(NOT rtt_${package}_FOUND AND NOT TARGET rtt_${package}_rosservice_proxies)
    set(_package ${package})
    add_subdirectory(${rtt_roscomm_TEMPLATES_DIR}/service ${package}_service_proxies)
  endif()
endmacro(ros_generate_rtt_service_proxies)
