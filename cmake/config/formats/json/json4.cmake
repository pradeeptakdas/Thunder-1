
function(json4 input)
  string_encode_list("${input}")
  ans(input)
  regex_json()
  string(REGEX MATCHALL "${regex_json_token}" tokens "${input}")
  string(REGEX REPLACE "${regex_json_token}" "" input "${input}" )
  if(NOT "${input}_" STREQUAL "_")
    message(FATAL_ERROR "invalid json - the following could no be tokenized : '${input}'")
  endif()

  map_new()
  ans(result)
  map_set("${result}" value)
  set(current_key value)
  set(is_array object)
  set(current_ref "${result}")
  set(ref_stack)
  set(key_stack)
  set(is_array_stack)
  while(true)
    list(LENGTH tokens length)
    if(NOT length)
      break()
    endif()
    list(GET tokens 0 token)
    list(REMOVE_AT tokens 0)


    if("${token}" MATCHES "^\"(.*)\"$")
      json_string_to_cmake("${token}")
      string_decode_bracket("${__ans}") ## semicolons will stay encoded...
      set_property(GLOBAL APPEND_STRING PROPERTY "${current_ref}.${current_key}" "${__ans}")
    elseif("${token}" MATCHES "^${regex_json_number_token}$")
      ## todo validate number correclty
      set_property(GLOBAL APPEND_STRING PROPERTY "${current_ref}.${current_key}" "${token}")
    elseif("${token}" MATCHES "^${regex_json_bool_token}$")
      set_property(GLOBAL APPEND_STRING PROPERTY "${current_ref}.${current_key}" "${token}")
    elseif("${token}" MATCHES "^${regex_json_null_token}$")
      ## do nothing because json null is empty string in cmake
    elseif("${token}" MATCHES "^(${regex_json_array_begin_token})|(${regex_json_object_begin_token})$")
      list(INSERT ref_stack 0 "${current_ref}")
      list(INSERT key_stack 0 "${current_key}")
      list(INSERT is_array_stack 0 "${is_array}")
      if("${token}" STREQUAL "${regex_json_array_begin_token}")
        set(is_array true)
      else() ## ${token} STREQUAL "${regex-json_object_begin_token}"
        map_new()
        ans(new_ref)
        set_property(GLOBAL APPEND_STRING PROPERTY "${current_ref}.${current_key}" "${new_ref}")
        set(current_key "${free_token}")
        set(current_ref "${new_ref}")
        set(is_array false)
      endif()
    elseif("${token}" MATCHES "^(${regex_json_array_end_token})|(${regex_json_object_end_token})$")
      list(GET ref_stack 0 current_ref)
      list(REMOVE_AT ref_stack 0)
      list(GET key_stack 0 current_key)
      list(REMOVE_AT key_stack 0)
      list(GET is_array_stack 0 is_array)
      list(REMOVE_AT is_array_stack 0)
    elseif("${token}" MATCHES "^${regex_json_separator_token}$")
      if(is_array)
        set_property(GLOBAL APPEND_STRING PROPERTY "${current_ref}.${current_key}" ";")
      else()
        set(current_key "${free_token}")
      endif()
    elseif("${token}" MATCHES "^${regex_json_keyvalue_token}$")
      if("${current_key}" STREQUAL "${free_token}")
        get_property(current_key GLOBAL PROPERTY "${current_ref}.${free_token}")
        set_property(GLOBAL PROPERTY "${current_ref}.${free_token}")
        map_set("${current_ref}" "${current_key}")
      endif()
    #elseif("${token}" MATCHES "^${regex_json_whitespace_token}$") # ignored
    # else()  #error
    endif()



  endwhile()
  map_tryget("${result}" value)
  return_ans()

endfunction()