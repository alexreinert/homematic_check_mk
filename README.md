# Homematic check_mk addon

This project contains an addon for the Homematic CCU2 or a Raspberrymatic device which acts as an check_mk_agent.

As the orginal check_mk_agent does not support Busybox, not all of the sections of the original agent are available, but I tried to support as much as possible.

Additionally all datapoints of Homematic channels added to the Gewerk Monitored and all service messages are sent to the server in one section.

At the moment there are some Plugins for the check_mk server implemented:

- Check for Devices with Low Batteries (All devices)
- Check for Unreachable devices (All devices)
- Check for all other service messages (All devices)
- Check for Dutycycle (CCU and all connected LAN GW)
- Check for Humidity with configurable limits (Only channels in Gewerk Monitored)

Don't hesitate to ask for additional check plugins.

# Installation
- CCU Addon: Use the normal addon installation process of the CCU/Raspberrymatic
- check_mk Plugin: Refer to the check_mk documentation, how to install MKP packages

# License
Apache 2
