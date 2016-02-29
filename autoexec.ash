###########################################
# AUTOXEC FOR XIAOMI YI MODE SWITCH BY SHUTTER BUTTON
# (2016-02-29)
# reaper7
# https://github.com/reaper7/XIAOMI_YI_MODE_SWITCH
sleep 3
lu_util exec '/tmp/fuse_d/SCRIPTS/mode_set/mode_set.sh'
# or for start with last used mode: 
# lu_util exec '/tmp/fuse_d/SCRIPTS/mode_set/mode_set.sh 0'
# or for start any other mode (where X are value from MINMODE to MAXMODE -> check inside mode_set.sh):
# lu_util exec '/tmp/fuse_d/SCRIPTS/mode_set/mode_set.sh X'
###########################################

# put your favorite setting here
# or
# use mode_set.sh funcionality to upload 
# Your ash files from SCRIPTS/mode_set/ash_scripts dir to autoexec.ash loop

###########################################
# commands_from_app.ash loop
# (based on information from AirKite member:
# https://dashcamtalk.com/forum/threads/xiaomi-yi-share-your-scripts-and-settings.12707/page-11#post-214957 )
###########################################
## prepare files and scripts for external commands
lu_util exec 'if [ ! -f /tmp/fuse_d/commands_from_app.ash ]; then touch /tmp/fuse_d/commands_from_app.ash; fi'
t pwm 1 enable
sleep 1
t pwm 1 disable

## loop for external commands
while true
do
d:\commands_from_app.ash
lu_util exec 'if [ -s /tmp/fuse_d/commands_from_app.ash ]; then > /tmp/fuse_d/commands_from_app.ash; fi'
sleep 2
done
