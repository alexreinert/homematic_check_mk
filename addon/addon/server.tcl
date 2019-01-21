#!/bin/tclsh
load tclrega.so
load tclrpc.so

source [file join [file dirname [info script]] common.tcl]

proc handle_connection { channelId clientAddress clientPort } {
  if { [catch {
    log "connection accepted from $clientAddress:$clientPort"

    puts $channelId "<<<check_mk>>>"
    puts $channelId "Version: [get_version]"
    puts $channelId "AgentOS: HomeMatic"
    puts $channelId "Hostname: [info hostname]"

    puts $channelId "<<<mem>>>"
    puts $channelId [string trim [load_from_file /proc/meminfo]]

    puts $channelId "<<<cpu>>>"
    puts $channelId "[string trim [load_from_file /proc/loadavg]] [exec grep -E ^(P|p)rocessor < /proc/cpuinfo | wc -l]"

    puts $channelId "<<<uptime>>>"
    puts $channelId [string trim [load_from_file /proc/uptime]]

    puts $channelId "<<<kernel>>>"
    puts $channelId [clock seconds]
    puts $channelId [string trim [load_from_file /proc/vmstat]]
    puts $channelId [string trim [load_from_file /proc/stat]]

    if { [file exists /sys/class/thermal/thermal_zone0] == 1} {
        puts $channelId "<<<lnx_thermal>>>"
        puts $channelId [exec sh -c {for F in /sys/class/thermal/thermal_zone*; do if [ ! -e "$F/mode" ] || [ "$(cat ${F}/mode)" == "disabled" ]; then continue; fi; echo -n "${F##*/} "; for m in mode type temp; do cat "$F"/${m} 2>/dev/null | tr \\n " "; done; for i in $(seq 1 $(ls $F/trip_point_*_type 2>/dev/null| wc -l)); do cat "$F"/trip_point_${i}_temp "$F"/trip_point_${i}_type 2>/dev/null | tr \\n " "; done; echo; done}]
    }

    if { [file exists /proc/net/tcp6] == 1 } {
        puts $channelId "<<<tcp_conn_stats>>>"
        puts $channelId "[exec /usr/local/addons/check_mk_agent/timeout -s 1 10 cat /proc/net/tcp /proc/net/tcp6 2>/dev/null | awk { /:/ { c[$4]++; } END { for (x in c) { print x, c[x]; } } }]"
    } else {
        puts $channelId "<<<tcp_conn_stats>>>"
        puts $channelId "[exec /usr/local/addons/check_mk_agent/timeout -s 1 10 cat /proc/net/tcp 2>/dev/null | awk { /:/ { c[$4]++; } END { for (x in c) { print x, c[x]; } } }]"
    }

    puts $channelId "<<<lnx_if>>>"
    puts $channelId "\[start_iplink\]"
    puts $channelId "[exec ip link]"
    puts $channelId "\[end_iplink\]"

    puts $channelId "<<<lnx_if:sep(58)>>>"
    puts $channelId "[exec sed 1,2d /proc/net/dev]"
    if { [file exists /usr/sbin/ethtool] } {
      puts $channelId [exec sh -c {sed -e 1,2d /proc/net/dev | cut -d':' -f1 | sort | while read eth; do echo "[$eth]"; ethtool "$eth" | grep -E '(Speed|Duplex|Link detected|Auto-negotiation):'; echo -e "\tAddress: $(cat "/sys/class/net/$eth/address")\n"; done}]
    }

    puts $channelId "<<<df>>>"
    if { [exec busybox | sed -n 1p | awk { { print $2 } }] == "v1.20.2" } {
        puts $channelId "[exec df -Pk | sed 1d]"
    } else {
        puts $channelId "[exec df -PTk | sed 1d]"
        puts $channelId "<<<df>>>"
        puts $channelId "\[df_inodes_start\]"
        puts $channelId "[exec df -PTi | sed 1d]"
        puts $channelId "\[df_inodes_end\]"
    }

    puts $channelId "<<<mounts>>>"
    puts $channelId "[exec egrep ^(/dev|ubi) < /proc/mounts]"

    if { [file exists /bin/stat] == 1 } {
      puts $channelId "<<<nfsmounts>>>"
      puts $channelId [exec sh -c {sed -n '/ nfs4\? /s/[^ ]* \([^ ]*\) .*/\1/p' </proc/mounts | sed 's/\\040/ /g' | while read MP; do /usr/local/addons/check_mk_agent/timeout -s 9 5 stat -f -c "$MP ok %b %f %a %s" "$MP" || echo "$MP hanging 0 0 0 0"; done}]

      puts $channelId "<<<cifsmounts>>>"
      puts $channelId [exec sh -c {sed -n '/ cifs\? /s/[^ ]* \([^ ]*\) .*/\1/p' </proc/mounts | sed 's/\\040/ /g' | while read MP; do if [ ! -r "$MP" ]; then echo "$MP Permission denied"; else /usr/local/addons/check_mk_agent/timeout -s 9 2 stat -f -c "$MP ok %b %f %a %s" "$MP" || echo "$MP hanging 0 0 0 0"; fi; done}]
    }

    puts $channelId "<<<ps>>>"
    puts $channelId "[exec sh -c {ps ax -o user,vsz,rss,pid,args | sed -e 1d -e 's/ *\([^ ]*\) *\([^ ]*\) *\([^ ]*\) *\([^ ]*\) */(\1,0,0,00:00:00\/00:00:00,\4) /'}]"

    puts $channelId "<<<diskstat>>>"
    puts $channelId "[clock seconds]"
    puts $channelId "[exec egrep { (x?[shv]d[a-z]*|cciss/c[0-9]+d[0-9]+|emcpower[a-z]+|dm-[0-9]+|VxVM.*|mmcblk.*|dasd[a-z]*|bcache[0-9]+|nvme[0-9]+n[0-9]+|mtdblock.+) } < /proc/diskstats]"

    if { [file exists /usr/bin/ntpq] == 1 } {
        puts $channelId "<<<ntp>>>"
        puts $channelId "[exec /usr/local/addons/check_mk_agent/timeout 5 /usr/bin/ntpq -np | sed -e 1,2d -e {s/^\(.\)/\1 /} -e {s/^ /%/}]"
    }

    if { [file exists /usr/bin/chronyc] == 1 } {
        puts $channelId "<<<chrony>>>"
        puts $channelId "[exec /usr/local/addons/check_mk_agent/timeout 5 /usr/bin/chronyc -n tracking]"
    }

    puts $channelId "<<<homematic:sep(59)>>>"
    puts $channelId [string trim [get_homematic_check_result]]
    foreach dev [xmlrpc http://127.0.0.1:2001/ listBidcosInterfaces] {
      foreach {key value} [split $dev] {
        set values($key) $value
      }
      set address $values(ADDRESS)
      foreach key [array names values] {
        if { $key != "ADDRESS" } {
          puts $channelId "$address;$key;$values($key)"
        }
      }
    }

    foreach plugin [glob -nocomplain "[file dirname [info script]]/plugins/*"] {
      puts $channelId [exec $plugin]
    }

    flush $channelId

    close $channelId
  } err] } {
    log $err    
    [catch { close $channelId }]
  }
}

proc get_homematic_check_result { } {
  array set result [rega_script {
    string _svcId;
    object _svc;
    string _devId;
    object _dev;
    string _chId;
    object _ch;
    string _dpId;
    object _dp;
    string _name;

    foreach (_svcId, dom.GetObject(ID_SERVICES).EnumUsedIDs()) {
      _svc = dom.GetObject(_svcId);
      if (_svc && _svc.AlState() == asOncoming) {
        _dp = dom.GetObject(_svc.AlTriggerDP());
        _ch = dom.GetObject(_dp.Channel());
        _dev = dom.GetObject(_ch.Device());
        
        WriteLine("SVC_MSG;" # _dev.Name() # ";" # _svc.Name().StrValueByIndex (".", 1).StrValueByIndex ("-", 0) # ";" # _dp.Timestamp());
      }
    }

    _svc = dom.GetObject("Monitored");
    if (_svc) {
      foreach (_chId, _svc.EnumUsedIDs()) {
        _ch = dom.GetObject(_chId);

        _dev = dom.GetObject(_ch.Device());
        WriteLine(_ch.Name() # ";HSSTYPE;" # _dev.HssType());

        foreach (_dpId, _ch.DPs()) {
          _dp = dom.GetObject(_dpId);

          if (_dp.Value()) {
            _name = _dp.Name().StrValueByIndex(".", 2);
            WriteLine(_ch.Name() # ";" # _name # ";" # _dp.Value() # ";" # _dp.Timestamp());
          }
        }
      }
    }
  }]
  return $result(STDOUT)
}

proc get_homematic_bidcos_devices { } {
  foreach dev [xmlrpc http://127.0.0.1:2001/ listBidcosInterfaces] {
    foreach {key value} [split $dev] {
      puts "$key=$value"
    }
  }
}

proc read_var { filename varname } {
  set fd [open $filename r]
  set var ""
  if { $fd >=0 } {
    while { [gets $fd buf] >=0 } {
      if [regexp "^ *$varname *= *(.*)$" $buf dummy var] break
    }
    close $fd
  }
  return $var
}

proc get_version { } {
  if { [file exists /VERSION] == 1 } {
    return [read_var /VERSION VERSION]
  } else {
    return [read_var /boot/VERSION VERSION]
  }
}

proc main { } {
  startup

  socket -server handle_connection 6556
  log "check_mk agent started and waiting for connections..."

  vwait forever
}

proc startup { } {
  if {[is_running]} then {
    error "already running"
  }

  write_pid_file
}

if { [catch { main } err] } then {
  log $err
  exit 1
}
