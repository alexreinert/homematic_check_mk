set ADDON_NAME "check_mk_agent"

proc log { message } {
  global ADDON_NAME
  exec logger "$ADDON_NAME - $message"
}

proc save_to_file { fileName content } {
  set fd -1

  set fd [open $fileName w]
  if { $fd != -1 } then {
    puts -nonewline $fd $content
    close $fd
  } else {
    error "could not write file $fileName"
  }
}

proc load_from_file { fileName } {
  set fd -1
  
  set fd [open $fileName r]
  if { $fd != -1 } then {
    set result [read $fd]
    close $fd
  } else {
    error "could not read file $fileName"
  }
  
  return $result
}
 
set PID_FILE "/var/lock/$ADDON_NAME.pid"

proc is_running { } {
  global PID_FILE
  return [file exists $PID_FILE]
}

proc write_pid_file { } {
  global PID_FILE
  save_to_file $PID_FILE [pid]
}

proc read_pid_file { } {
  global PID_FILE
  return [load_from_file $PID_FILE]
}

proc remove_pid_file { } {
  global PID_FILE
  file delete $PID_FILE
}

