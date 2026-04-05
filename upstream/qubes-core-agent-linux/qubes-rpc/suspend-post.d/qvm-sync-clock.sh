#!/bin/sh

if [ ! -f /var/run/qubes-service/clocksync ]; then
    # https://github.com/QubesOS/qubes-issues/issues/7265
    sv --no-pager restart qubes-sync-time.service
fi
