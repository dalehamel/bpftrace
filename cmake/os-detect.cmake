# Detect the distribution bpftrace is being built on
function(detect_os)
  file(STRINGS "/etc/os-release" HOST_OS_INFO)

  foreach(os_info IN LISTS HOST_OS_INFO)
    if(os_info MATCHES "^ID=")
      string(REPLACE "ID=" "" HOST_OS_ID ${os_info})
      set(HOST_OS_ID ${HOST_OS_ID} PARENT_SCOPE)
    elseif(os_info MATCHES "^ID_LIKE=")
      string(REPLACE "ID_LIKE=" "" HOST_OS_ID_LIKE ${os_info})
      set(HOST_OS_ID_LIKE ${HOST_OS_ID_LIKE} PARENT_SCOPE)
    endif()
  endforeach(os_info)
endfunction(detect_os)
