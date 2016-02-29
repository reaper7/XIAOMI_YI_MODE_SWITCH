# set my default params

#set JPEG quality to 100%
writeb 0xC0BC205B 0x64

#set file size to 4GB
writew 0xC03A8520 0x2004

t pwm 1 enable
sleep 1
t pwm 1 disable
