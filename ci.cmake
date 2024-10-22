cmake_minimum_required(VERSION 3.19)

###########################################
#### Usage: cmake -P ci.cmake -- cmake args
###########################################

if(NOT CMAKE_SCRIPT_MODE_FILE)
	message(FATAL_ERROR "Script mode is required")
endif()

get_filename_component(CMAKE_SOURCE_DIR "${CMAKE_SCRIPT_MODE_FILE}" DIRECTORY)
message(STATUS "CMAKE_VERSION: ${CMAKE_VERSION}")
message(STATUS "CMAKE_SOURCE_DIR: ${CMAKE_SOURCE_DIR}")
message(STATUS "CMAKE_BINARY_DIR: ${CMAKE_BINARY_DIR}")

set(CMAKE_DIR "${CMAKE_SOURCE_DIR}/cmake")
set(CMAKE_MODULE_PATH "${CMAKE_DIR}/ci")

if(CMAKE_COMMAND MATCHES " ")
	set(CMAKE_COMMAND cmake)
endif()
if(CMAKE_CTEST_COMMAND MATCHES " ")
	set(CMAKE_CTEST_COMMAND ctest)
endif()

set(IMPORT_PY ${CMAKE_SOURCE_DIR}/resources/jenkins/import.py)


function(GET_PARAMS _params _definitions)
	foreach(_arg RANGE ${CMAKE_ARGC})
		if("${CMAKE_ARGV${_arg}}" STREQUAL "--")
			math(EXPR delimiter "${_arg}+1")
			break()
		elseif("${CMAKE_ARGV${_arg}}" MATCHES "^-D")
			list(APPEND definition ${CMAKE_ARGV${_arg}})
		endif()
	endforeach()

	if(DEFINED delimiter)
		foreach(_arg RANGE ${delimiter} ${CMAKE_ARGC})
			list(APPEND param ${CMAKE_ARGV${_arg}})
		endforeach()
		set(${_params} "${param}" PARENT_SCOPE)
	endif()

	if(DEFINED definition)
		set(${_definitions} "${definition}" PARENT_SCOPE)
	endif()
endfunction()


function(CALC_CHECKSUM _out_checksum _out_repatch)
	set(CHECKSUM_FILES ${CMAKE_SCRIPT_MODE_FILE} ${IMPORT_PY})
	foreach(file ${CHECKSUM_FILES})
		file(MD5 "${file}" _hash)
		string(MD5 hashes "${_hash}${hashes}")
	endforeach()

	if((NOT DEFINED SPLITTED OR SPLITTED) AND PATCHED AND NOT ${_out_checksum} STREQUAL hashes)
		set(${_out_repatch} ON PARENT_SCOPE)
	endif()

	set(${_out_checksum} ${hashes} PARENT_SCOPE)
endfunction()


function(IMPORT_PATCH _out)
	message(STATUS "Import patch(es)...")
	find_package(Python REQUIRED)
	step(${Python_EXECUTABLE} ${IMPORT_PY} ${ARGN} NO_ECHO OUTPUT output CHDIR ${CMAKE_SOURCE_DIR})
	if(output MATCHES "Pending patch: (.+)")
		string(STRIP "${CMAKE_MATCH_1}" PENDING_PATCH)
		set(${_out} "${PENDING_PATCH}" PARENT_SCOPE)
	endif()
endfunction()


function(STEP)
	set(options NO_ECHO)
	set(oneValueArgs CHDIR OUTPUT RESULT PATH)
	set(multiValueArgs ENV)
	cmake_parse_arguments(_PARAM "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

	if(_PARAM_ENV)
		set(ENV_CMD ${CMAKE_COMMAND} -E env)
		foreach(env ${_PARAM_ENV})
			if(env MATCHES "^PATH=")
				message(FATAL_ERROR "Use explicit PATH parameter")
			endif()
			list(APPEND ENV_CMD "${env}")
		endforeach()
		list(APPEND ENV_CMD --)
	endif()

	if(NOT _PARAM_CHDIR)
		set(_PARAM_CHDIR ${CMAKE_BINARY_DIR})
	endif()

	if(_PARAM_OUTPUT)
		set(OUTPUT_OPTION OUTPUT_VARIABLE)
		set(OUTPUT _output)
	endif()

	if(_PARAM_NO_ECHO OR NOT ECHO)
		set(COMMAND_ECHO STDOUT)
	else()
		set(ECHO_CMD ${CMAKE_COMMAND} -E echo)
		set(COMMAND_ECHO NONE)
	endif()

	if(_PARAM_PATH)
		set(TMP_PATH "$ENV{PATH}")
		if(CMAKE_HOST_SYSTEM_NAME MATCHES "Windows")
			set(SEP ";")
		else()
			set(SEP ":")
		endif()
		set(ENV{PATH} "${_PARAM_PATH}${SEP}$ENV{PATH}")
	endif()
	execute_process(COMMAND ${ECHO_CMD} ${ENV_CMD} ${_PARAM_UNPARSED_ARGUMENTS}
		RESULT_VARIABLE _result
		${OUTPUT_OPTION} ${OUTPUT}
		ECHO_OUTPUT_VARIABLE
		WORKING_DIRECTORY ${_PARAM_CHDIR}
		COMMAND_ECHO ${COMMAND_ECHO})
	if(TMP_PATH)
		set(ENV{PATH} "${TMP_PATH}")
		unset(TMP_PATH)
	endif()

	if(NOT ${_result} EQUAL 0)
		if(_PARAM_RESULT)
			set(${_PARAM_RESULT} ${_result} PARENT_SCOPE)
		else()
			message(FATAL_ERROR "Process failed: ${_result}")
		endif()
	endif()

	if(_PARAM_OUTPUT)
		set(${_PARAM_OUTPUT} ${${OUTPUT}} PARENT_SCOPE)
	endif()
endfunction()


function(CALL_SCRIPT)
	if(NOT SCRIPT)
		message(FATAL_ERROR "SCRIPT is undefined")
	endif()

	SET_TEMPLATES()
	if(EXISTS ${T_BUILD_DIR})
		step(${CMAKE_COMMAND} -E rm -r ${T_BUILD_DIR})
	endif()

	message(STATUS "Use SCRIPT: ${SCRIPT}")
	include(${SCRIPT})
endfunction()


macro(PARSE_FROM_NAME)
	if(DEFINED ENV{JOB_NAME} AND NOT NAME)
		set(NAME $ENV{JOB_NAME})
	endif()

	if(NAME)
		message(STATUS "Use NAME: ${NAME}")

		if(NAME MATCHES "^Release_" AND NOT DEFINED RELEASE)
			set(RELEASE ON)
		elseif(NAME MATCHES "_Review_" AND NOT DEFINED REVIEW)
			set(REVIEW ON)
		endif()

		if(NOT SCRIPT)
			file(GLOB scripts "${CMAKE_MODULE_PATH}/*.cmake")
			foreach(entry ${scripts})
				get_filename_component(entry "${entry}" NAME_WLE)
				if(NAME MATCHES "_${entry}")
					set(SCRIPT ${entry})
					break()
				endif()
			endforeach()
		endif()
	endif()

	if(NOT REVIEW AND NOT RELEASE)
		set(DAILY ON)
	endif()
endmacro()


macro(SET_TEMPLATES) # Provide some base templates for SCRIPTs
	if(DEFINED ENV{WORKSPACE})
		set(WORKSPACE $ENV{WORKSPACE})
	else()
		set(WORKSPACE ${CMAKE_BINARY_DIR})
	endif()

	set(T_BUILD_DIR build)
	set(T_DIST_DIR ${T_BUILD_DIR}/dist)
	set(T_BUILD ${CMAKE_COMMAND} --build ${T_BUILD_DIR})
	set(T_TARGET ${T_BUILD} --target)
	set(T_CTEST ${CMAKE_CTEST_COMMAND} --test-dir ${T_BUILD_DIR} --output-on-failure)
	set(T_CFG ${CMAKE_COMMAND} -S ${CMAKE_SOURCE_DIR} -B ${T_BUILD_DIR} ${PARAMS})
endmacro()


function(RESPAWN_PATCHED)
	if(NOT DEFINED SPLITTED OR SPLITTED)
		set(SPLITTED_PARAM --splitted)
	endif()
	if(NOT PATCHED)
		set(CLEAN_PARAM --clean)
	endif()
	if(DEFINED PENDING AND NOT PENDING AND SPLITTED_PARAM)
		set(PENDING_PARAM --no-pending)
	endif()
	if(REPATCH)
		set(REPATCH_PARAM --repatch)
	endif()

	if(NOT PATCHED OR SPLITTED_PARAM)
		unset(PENDING_PATCH CACHE)
		IMPORT_PATCH(PENDING_PATCH ${SPLITTED_PARAM} ${CLEAN_PARAM} ${PENDING_PARAM} ${REPATCH_PARAM})

		if(PENDING_PATCH OR NOT PATCHED)
			set(PATCHED_OPTION "-DPATCHED=ON")
			if(NOT PATCHED_OPTION IN_LIST DEFINITIONS)
				list(APPEND DEFINITIONS ${PATCHED_OPTION})
			endif()

			set(PENDING_PATCH_OPTION "-DPENDING_PATCH")
			list(FILTER DEFINITIONS EXCLUDE REGEX "${PENDING_PATCH_OPTION}")
			if(PENDING_PATCH)
				list(APPEND DEFINITIONS "${PENDING_PATCH_OPTION}=${PENDING_PATCH}")
			endif()

			set(CHECKSUM_OPTION "-DCHECKSUM")
			list(FILTER DEFINITIONS EXCLUDE REGEX "${CHECKSUM_OPTION}")
			list(APPEND DEFINITIONS "${CHECKSUM_OPTION}=${CHECKSUM}")

			if(NOT PATCHED AND SPLITTED_PARAM)
				set(INITIAL_RUNNER INITIAL_RUNNER_FAILED)
			endif()

			message(STATUS "script runner: respawn")
			step(${CMAKE_COMMAND} ${DEFINITIONS} -P ${CMAKE_SCRIPT_MODE_FILE} -- ${PARAMS} NO_ECHO RESULT ${INITIAL_RUNNER})
			if(INITIAL_RUNNER)
				IMPORT_PATCH(_unused --clean-only)
				if(INITIAL_RUNNER_FAILED)
					message(FATAL_ERROR "script runner: failed")
				else()
					message(STATUS "script runner: done")
				endif()
			endif()
		endif()
	endif()
endfunction()


function(RUN)
	PARSE_FROM_NAME()
	GET_PARAMS(PARAMS DEFINITIONS)
	CALC_CHECKSUM(CHECKSUM REPATCH)

	if(NOT REPATCH AND (NOT REVIEW OR PATCHED))
		CALL_SCRIPT()
	endif()

	if(REVIEW)
		RESPAWN_PATCHED()
	endif()
endfunction()


if(PATCH_ONLY)
	IMPORT_PATCH(_unused --clean)
else()
	RUN()
endif()
