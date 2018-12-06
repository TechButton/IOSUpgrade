#!/bin/bash
# Feed the expect script a device list & the collected passwords 
cd $(dirname $0)
cp blank-error.csv devices-with-errors.csv
cp blank-ready.csv devices-ready.csv
message1="Please schedule reboot"

message2="
1. dir (check for free space, delete any pcap or extra syslog files)

2. software clean (make sure all the old ios software is cleaned up)

3. copy ftp://ios:PASSWORD@FTPSERVER flash:cat3k_caa-universalk9.SPA.03.06.08.E.152-2.E8.bin (copy the iso to the switch)

4. software install file flash:cat3k_caa-universalk9.SPA.03.06.08.E.152-2.E8.bin on-reboot (installs the IOS software on next reboot)

5. Schedule a reboot change for the device."
log_location="/usr/iospush/devicelogs"
for device in `cat device-list.csv`; do
expect -f iospush.exp $device TACACS-USERNAME PASSWORD > $log_location/$device.log
if grep -q -e "Install Complete" "$log_location/$device.log"; then
    mail -s "$device Install Ready - Schedule Reboot Window" nocalerts@mayo.edu <<< $message1
	grep -v "$device" device-list.csv > device-list-temp.csv; mv device-list-temp.csv device-list.csv
	echo "$device" >> devices-ready.csv
else
	mail -s "$device has an error - Please follow instructions" nocalerts@mayo.edu <<< $message2
	grep -v "$device" device-list.csv > device-list-temp.csv; mv device-list-temp.csv device-list.csv
	echo "$device" >> devices-with-errors.csv
fi
done
echo "$message1" | mail -s "Device's Ready for Reboot" noc@email.com -A devices-ready.csv #modify email address
echo "$message2" | mail -s "Device's with Errors" noc@email.com -A devices-with-errors.csv #modify email address
exit