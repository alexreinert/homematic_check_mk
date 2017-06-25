def perfometer_check_mk_homematic_dutycycle(row, check_command, perf_data):
  dutycycle = float(perf_data[0][1])
  state = row["service_state"]
  color = { 0: "#39f", 1: "#ff2", 2: "#f22", 3: "#fa2" }[state]

  return "%.0f%%" % dutycycle, perfometer_linear(dutycycle, color)

perfometers["check_mk-homematic.dutycycle"] = perfometer_check_mk_homematic_dutycycle

