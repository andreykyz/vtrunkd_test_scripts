#!/bin/bash

CLI_MACHINE="user@cli-32"
SRV_MACHINE="user@srv"
echo "killall vtrunkd ... "
ssh $SRV_MACHINE "sudo killall -9 vtrunkd ; sudo ipcrm -M 567888 ; sudo ipcrm -M 567889"
ssh $CLI_MACHINE "sudo killall -9 vtrunkd ; sudo ipcrm -M 567888 ; sudo ipcrm -M 567889"

