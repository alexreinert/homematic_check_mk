#!/bin/tclsh

source [file join [file dirname [info script]] common.tcl]

proc main { } {
  if { [is_running] } then {
    set pid [read_pid_file]

    catch { exec kill -KILL $pid }
    remove_pid_file
  }

  log "stopped"
}

if { [catch { main } errorMessage] } then {
  log $errorMessage
  exit 1
}

