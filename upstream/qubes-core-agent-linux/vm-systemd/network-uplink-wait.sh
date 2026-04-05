#!/bin/sh

# Source Qubes library.
# shellcheck source=init/functions
. /usr/lib/qubes/init/functions

# Setup IP address at specific time of system boot, instead of asynchronously
# by udev
QUBES_MANAGED_IFACE="$(get_qubes_managed_iface)"
if [ "x$QUBES_MANAGED_IFACE" != "x" ]; then
    # runit does not support conditional After= dependencies, nor a tool to
    # just wait for the unit to be activated
    # if the network interface is expected, use `sv start` to wait for
    # it to be started - it would be started by udev (RUNIT_WANTS) anyway
    sv start "qubes-network-uplink@$QUBES_MANAGED_IFACE.service"
fi
