#!/bin/sh
################################################################################
#
# XIAOMI YI MODE SWITCH BY SHUTTER BUTTON
# (2016-02-29)
# reaper7
# https://github.com/reaper7/XIAOMI_YI_MODE_SWITCH
#
################################################################################
# ------------------------------------------------------------------------------
# DEFINITIONS & VARIABLES
# ------------------------------------------------------------------------------
BTN_WIFI_EN=11
LED_WIFI=114
LED_SHUTTER=12
LED_FRONT_BLUE=6
LED_FRONT_RED=54

ULSSPATH="/usr/local/share/script"
CARDPATH="/tmp/fuse_d"
TOOLPATH="$(cd "$(dirname "$0")" && pwd -P)"
CONFFILE="$TOOLPATH/mode_set.cfg"
UASHPATH="$TOOLPATH/ash_scripts"

MAXWAIT=5																		# wait in loop when previous reqest is complete (send_custom_settings func)

LSTMODE=0
MINMODE=1
MAXMODE=5                                                                       # change this one if You add more Your modes
# ------------------------------------------------------------------------------
# CUSTOM MODES
# ------------------------------------------------------------------------------
# 1. AP MODE (DEFAULT WHEN NO PARAMETER)
mode_1() {
  wifi_conf_file_prepare 0                                                      # prepare wifi.conf file for AP mode
  send_custom_settings "mydefset"                                               # send mydefset.ash from ash_scripts folder to autoexec.ash
  return 1;
}
# ------------------------------------------------------------------------------
# 2. STA MODE, WIFI AUTOSTART, TELNET SERVER, FTP SERVER, MY FAVORITE SETTINGS
mode_2() {
  wifi_conf_file_prepare 1                                                      # prepare wifi.conf file for STA mode
  sta_mode_fix                                                                  # STA mode fix by halvaborsch
#  $ULSSPATH/t_gpio.sh $BTN_WIFI_EN 1 &                                         # activate wifi - NOT NEEDED
#  $ULSSPATH/t_gpio.sh $LED_WIFI 0 &                                            # turn ON wifi LED - NOT NEEDED
  $ULSSPATH/wifi_start.sh &                                                     # start 'wifi on' script
  telnet_start                                                                  # start telnet server
  ftp_start                                                                     # start ftp server
  send_custom_settings "mydefset"                                               # send mydefset.ash from ash_scripts folder to autoexec.ash
  return 1;
}
# ------------------------------------------------------------------------------
# 3. TEST, SEND USER SETTINGS (AUTORECORD) TO AUTOEXEC
mode_3() {
  send_custom_settings "autorec"
  return 1;
}
# ------------------------------------------------------------------------------
# 4. EMPTY
mode_4() {
  return 1;
}
# ------------------------------------------------------------------------------
# 5. EMPTY
mode_5() {
  return 1;
}
# ------------------------------------------------------------------------------
# 6. EMPTY
#mode_6() {
#  return 1;
#}
# ------------------------------------------------------------------------------
# VARIOUS FUNCTIONS
# ------------------------------------------------------------------------------
# Func. -> send selected settings file from ash_scripts folder to autoexec.ash loop
send_custom_settings() {
  if [ ! -z $1 ]; then
    ASHFILE=$UASHPATH/$1.ash
    if [ -s $ASHFILE ]; then
	  WAITFORFREE=0
	  while ( [ $WAITFORFREE -le $MAXWAIT ] && [ -s $CARDPATH/commands_from_app.ash ] )
	  do
		sleep 1
		WAITFORFREE=$((WAITFORFREE +1))
	  done
	  cat $ASHFILE > $CARDPATH/commands_from_app.ash
    fi
  fi
}
# ------------------------------------------------------------------------------
# Func. -> run telnet server
telnet_start() {
  telnetd -l/bin/sh &
}
# ------------------------------------------------------------------------------
# Func. -> run ftp server
ftp_start() {
  nohup tcpsvd -u root -vE 0.0.0.0 21 ftpd -w / >> /dev/null 2>&1 &
}
# ------------------------------------------------------------------------------
# Func. -> STA mode fix by halvaborsch
sta_mode_fix() {
  # by Halvaborsch <dsequence@gmail.com>
  # https://github.com/halvaborsch/
  # The problem is: 
  # lnx system has two diffrent version of wpa_supplicant file
  mkdir -p /tmp/bcmdhd/;
  cp /usr/local/bcmdhd/* /tmp/bcmdhd/;
  rm /tmp/bcmdhd/wpa_supplicant;
  ln -s /usr/bin/wpa_supplicant /usr/local/bcmdhd/wpa_supplicant;
  mount --bind /tmp/bcmdhd/ /usr/local/bcmdhd/;
}
# ------------------------------------------------------------------------------
# Func. -> configure wifi.conf file (param 0=AP, 1=STA)
wifi_conf_file_prepare() {
  if [ -f $CARDPATH/MISC/wifi.conf ]; then rm -f $CARDPATH/MISC/wifi.conf; fi
  cp -f $CARDPATH/MISC/TMP.WIFI.CONF $CARDPATH/MISC/wifi.conf
  if [ -z "$1" ] || [ $1 -eq 0 ]; then
    sed -i 's/WIFI_MODE=sta/WIFI_MODE=ap/g' $CARDPATH/MISC/wifi.conf
  else
    sed -i 's/WIFI_MODE=ap/WIFI_MODE=sta/g' $CARDPATH/MISC/wifi.conf  
  fi
}
# ------------------------------------------------------------------------------
# Func. -> blink shutter red led (param=n blinks)
shutter_led_blink() {
  for i in $( seq 1 ${1} );
  do
    $ULSSPATH/t_gpio.sh $LED_WIFI 0 &
    sleep 0.15
    $ULSSPATH/t_gpio.sh $LED_WIFI 1 &
    sleep 0.15
  done
}
# ------------------------------------------------------------------------------
check_gpio() {
  # Func. -> check shutter button, return 1 if pressed
  GPIO=`cat /proc/ambarella/gpio`
  return ${GPIO:13:1}
}
# ------------------------------------------------------------------------------
# MAIN PROGRAM
# ------------------------------------------------------------------------------
# if script (starts with parameter) and ((parameter between MINMODE and MAXMODE) or (USE_LAST_MODE and CONFFILE exists))
if ( [ $# -ne 0 ] ) && (( [ $1 -ge $MINMODE ] && [ $1 -le $MAXMODE ] ) || ( [ $1 -eq $LSTMODE ] && [ -s $CONFFILE ] )); then
  if [ $1 -eq 0 ]; then
    TMPMODE=`cat $CONFFILE`
    if [ $TMPMODE -ge $MINMODE ] && [ $TMPMODE -le $MAXMODE ]; then
      MODESET=$TMPMODE
    else
      MODESET=$MINMODE
    fi	
  else
    MODESET=$1
  fi
else
  MODESET=$MINMODE
fi
# ------------------------------------------------------------------------------
shutter_led_blink $MODESET
sleep 1
# ------------------------------------------------------------------------------
# while shutter btn pressed then increment MODE and blinks led
while check_gpio
do
  if [ $MODESET -lt $MAXMODE ]; then
    MODESET=$((MODESET +1))
  else
    MODESET=$MINMODE
  fi
  shutter_led_blink $MODESET
  sleep 1
done
# ------------------------------------------------------------------------------
# save selected MODE to config file
echo -n $MODESET > $CONFFILE
# ------------------------------------------------------------------------------
# run selected mode
case $MODESET in
  1) mode_1 ;;
  2) mode_2 ;;
  3) mode_3 ;;
  4) mode_4 ;;
  5) mode_5 ;;
  # additional modes...
  # 6) mode_6 ;;
  # etc
  *) exit ;;
esac
# ------------------------------------------------------------------------------
sleep 0.5
