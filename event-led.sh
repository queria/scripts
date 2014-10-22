#!/bin/bash

su -c 'echo 0 off > /proc/acpi/ibm/led'
sleep 0.14
su -c 'echo 0 on > /proc/acpi/ibm/led'
sleep 0.01
su -c 'echo 0 off > /proc/acpi/ibm/led'
sleep 0.15
su -c 'echo 0 on > /proc/acpi/ibm/led'
