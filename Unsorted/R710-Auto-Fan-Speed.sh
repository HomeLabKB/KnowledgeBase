#!/bin/bash

####################################################################################
# Script for checking the temperature reported by the ambient temperature sensor,
# and if deemed too high send the raw IPMI command to enable dynamic fan control.
# Send notifications to Discord when temperature exceeds threshold(s).
#
# Requires:
# ipmitool – apt install ipmitool
# mosquitto – apt install mosquitto mosquitto-clients
#
# If you are new to using MQTT / Mosquitto, I recommend reading this article and 
# setting it up with a password.
# --> https://www.digitalocean.com/community/tutorials/how-to-install-and-secure-the-mosquitto-mqtt-messaging-broker-on-ubuntu-18-04
#
# I run this script all of it's log files in /custom-scripts/ but you can change 
# that to a directory that you prefer.
#
####################################################################################

####################################################################################
# CRONTAB
# This is setup for reporting temperatures every
# 15 seconds.
# 
# Run:
#     crontab -l
#
# */1 * * * * /bin/bash /custom-scripts/R710-Auto-Fan-Speed.sh > /dev/null 2>&1
# */1 * * * * sleep 15; /bin/bash /custom-scripts/R710-Auto-Fan-Speed.sh > /dev/null 2>&1
# */1 * * * * sleep 30; /bin/bash /custom-scripts/R710-Auto-Fan-Speed.sh > /dev/null 2>&1
# */1 * * * * sleep 45; /bin/bash /custom-scripts/R710-Auto-Fan-Speed.sh > /dev/null 2>&1
####################################################################################

#################################################
# BEGIN IPMI SETTINGS
# Modify to suit your needs.
#################################################

# IP Address of your Dell R710
IPMIHOST=xxx.xxx.xxx.xxx

# Username for your iDRAC
IPMIUSER=username

# Password for your iDRAC
IPMIPW=password

# Not sure what this is for tbh... was in a previous script. Only change if you know!
IPMIEK=0000000000000000000000000000000000000000

#################################################
# END IPMI SETTINGS
#################################################


#################################################
# BEGIN MQTT SETTINGS
# Modify to suit your needs.
#################################################

# IP Address of your Mosquitto broker
MQTTHOST=192.168.100.201

# Topic - You can organize it as you wish
MQTTTOPIC=r710/cpu/temp/highest

# Broker Username
MQTTUSER=username

# Broker Password
MQTTPW=password

#################################################
# END MQTT SETTINGS
#################################################


#################################################
# BEGIN FUNCTIONS
#################################################

function checkStage ()
{
    local arg1=$1
    local retval=0

    if [[ $arg1 < $STAGE1_TEMP ]];
    then
        retval=1
    elif [[ $arg1 < $STAGE2_TEMP ]];
    then
        retval=2
    elif [[ $arg1 < $STAGE3_TEMP ]];
    then
        retval=3
    elif [[ $arg1 < $STAGE4_TEMP ]];
    then
        retval=4
    else
        retval=5
    fi

    echo $retval
}

#################################################
# END FUNCTIONS
#################################################


#################################################
# BEGIN RPM VALUES
#################################################

RPM_1200=0x30\ 0x30\ 0x02\ 0xff\ 0x02
RPM_1440=0x30\ 0x30\ 0x02\ 0xff\ 0x03
RPM_1560=0x30\ 0x30\ 0x02\ 0xff\ 0x04
RPM_1680=0x30\ 0x30\ 0x02\ 0xff\ 0x05
RPM_1800=0x30\ 0x30\ 0x02\ 0xff\ 0x06
RPM_1920=0x30\ 0x30\ 0x02\ 0xff\ 0x07
RPM_2040=0x30\ 0x30\ 0x02\ 0xff\ 0x08
RPM_2160=0x30\ 0x30\ 0x02\ 0xff\ 0x0a
RPM_2280=0x30\ 0x30\ 0x02\ 0xff\ 0x0b
RPM_2400=0x30\ 0x30\ 0x02\ 0xff\ 0x0c
RPM_2520=0x30\ 0x30\ 0x02\ 0xff\ 0x0d
RPM_2640=0x30\ 0x30\ 0x02\ 0xff\ 0x0e
RPM_2760=0x30\ 0x30\ 0x02\ 0xff\ 0x0f
RPM_2880=0x30\ 0x30\ 0x02\ 0xff\ 0x10
RPM_3000=0x30\ 0x30\ 0x02\ 0xff\ 0x11
RPM_3120=0x30\ 0x30\ 0x02\ 0xff\ 0x12
RPM_3240=0x30\ 0x30\ 0x02\ 0xff\ 0x13
RPM_3360=0x30\ 0x30\ 0x02\ 0xff\ 0x14
RPM_3480=0x30\ 0x30\ 0x02\ 0xff\ 0x15
RPM_3600=0x30\ 0x30\ 0x02\ 0xff\ 0x16
RPM_3720=0x30\ 0x30\ 0x02\ 0xff\ 0x17
RPM_3840=0x30\ 0x30\ 0x02\ 0xff\ 0x18
RPM_3960=0x30\ 0x30\ 0x02\ 0xff\ 0x1a
RPM_4080=0x30\ 0x30\ 0x02\ 0xff\ 0x1b
RPM_4200=0x30\ 0x30\ 0x02\ 0xff\ 0x1c
RPM_4320=0x30\ 0x30\ 0x02\ 0xff\ 0x1d
RPM_4440=0x30\ 0x30\ 0x02\ 0xff\ 0x1e
RPM_4560=0x30\ 0x30\ 0x02\ 0xff\ 0x1f
RPM_4680=0x30\ 0x30\ 0x02\ 0xff\ 0x20
RPM_4800=0x30\ 0x30\ 0x02\ 0xff\ 0x21
RPM_4920=0x30\ 0x30\ 0x02\ 0xff\ 0x22
RPM_5040=0x30\ 0x30\ 0x02\ 0xff\ 0x23
RPM_5160=0x30\ 0x30\ 0x02\ 0xff\ 0x24
RPM_5280=0x30\ 0x30\ 0x02\ 0xff\ 0x25
RPM_5400=0x30\ 0x30\ 0x02\ 0xff\ 0x26
RPM_5520=0x30\ 0x30\ 0x02\ 0xff\ 0x27
RPM_5640=0x30\ 0x30\ 0x02\ 0xff\ 0x28
RPM_5760=0x30\ 0x30\ 0x02\ 0xff\ 0x2a
RPM_6000=0x30\ 0x30\ 0x02\ 0xff\ 0x2b
RPM_6240=0x30\ 0x30\ 0x02\ 0xff\ 0x2d
RPM_6360=0x30\ 0x30\ 0x02\ 0xff\ 0x2f
RPM_6480=0x30\ 0x30\ 0x02\ 0xff\ 0x30
RPM_6600=0x30\ 0x30\ 0x02\ 0xff\ 0x31
RPM_6720=0x30\ 0x30\ 0x02\ 0xff\ 0x32
RPM_6840=0x30\ 0x30\ 0x02\ 0xff\ 0x33
RPM_6960=0x30\ 0x30\ 0x02\ 0xff\ 0x34
RPM_7080=0x30\ 0x30\ 0x02\ 0xff\ 0x35
RPM_7200=0x30\ 0x30\ 0x02\ 0xff\ 0x36
RPM_7320=0x30\ 0x30\ 0x02\ 0xff\ 0x37
RPM_7560=0x30\ 0x30\ 0x02\ 0xff\ 0x39
RPM_7680=0x30\ 0x30\ 0x02\ 0xff\ 0x3a
RPM_7920=0x30\ 0x30\ 0x02\ 0xff\ 0x3c
RPM_8040=0x30\ 0x30\ 0x02\ 0xff\ 0x3e
RPM_8160=0x30\ 0x30\ 0x02\ 0xff\ 0x3f
RPM_8280=0x30\ 0x30\ 0x02\ 0xff\ 0x40
RPM_8520=0x30\ 0x30\ 0x02\ 0xff\ 0x41
RPM_8640=0x30\ 0x30\ 0x02\ 0xff\ 0x43
RPM_8760=0x30\ 0x30\ 0x02\ 0xff\ 0x44
RPM_8880=0x30\ 0x30\ 0x02\ 0xff\ 0x45
RPM_9000=0x30\ 0x30\ 0x02\ 0xff\ 0x46
RPM_9120=0x30\ 0x30\ 0x02\ 0xff\ 0x47
RPM_9240=0x30\ 0x30\ 0x02\ 0xff\ 0x48

# Suspect that hex values should be able to go to 0x64 (12000RPM). 
# For the use case of this script, I doubt that anyone using this 
# script would want to go above 9240RPM as it's quite loud already.

#################################################
# END FUNCTIONS
#################################################


#################################################
# BEGIN VARIABLES
#################################################
STAGE1_TEMP=50                           # Target temperature for Stage 1 Max
STAGE1_FAN=$RPM_1200                     # Fan speed for Stage 1 - 1200 RPM
STAGE1_FAN_SPEED=1200\ RPM               # Text version of fan speed

STAGE2_TEMP=56                           # Target temperature for Stage 2 Max
STAGE2_FAN=$RPM_1800                     # Fan speed for Stage 2 - 1800 RPM
STAGE2_FAN_SPEED=1800\ RPM               # Text version of fan speed

STAGE3_TEMP=60                           # Target temperature for Stage 3 Max
STAGE3_FAN=$RPM_2160                     # Fan speed for Stage 3 - 2160 RPM
STAGE3_FAN_SPEED=2160\ RPM               # Text version of fan speed

STAGE4_TEMP=64                           # Target temperature for Stage 4 Max
STAGE4_FAN=$RPM_3000                     # Fan speed for Stage 4 - 3000 RPM
STAGE4_FAN_SPEED=3000\ RPM               # Text version of fan speed

# Get current CPU temp from MQTT. 
CURRENT_TEMP=$(mosquitto_sub -h $MQTTHOST -t $MQTTTOPIC -u $MQTTUSER -P $MQTTPW -C 1)

# Get previous recorded temperature.
PREVIOUS_TEMP=$(cat /custom-scripts/R710-Current-Temp-Log)

# Sends an IPMI command to get the current fan speed for FAN 1, and outputs it as four digits.
CURRENT_FAN_SPEED=$(ipmitool -I lanplus -H $IPMIHOST -U $IPMIUSER -P $IPMIPW -y $IPMIEK sdr type fan |grep "FAN 1" |grep RPM |grep -Po '\d{4}' | tail -l)

# If desired, we can send a message to Discord with a mention for a group. Left blanked as a default. Adjusted further down in the script on a need-be basis.
DISCORD_ROLE=""

# Determine what threshold stage we started at.
STAGE_START=$(cat /custom-scripts/R710-Fan-Speed-Log)

# Determine what threshold stage we should be at.
STAGE_END=$(checkStage $CURRENT_TEMP)

# Write the new stage to a log file so that it can become the STAGE_START value next time it is run.
echo $STAGE_END > /custom-scripts/R710-Fan-Speed-Log

# Write the current temperature to a log file.
echo $CURRENT_TEMP > /custom-scripts/R710-Current-Temp-Log

# Ongoing log of temperatures
echo "[" $(zdump CST) "] " $CURRENT_TEMP"C" >> /custom-scripts/R710.log

#################################################
# END VARIABLES
#################################################


#################################################
# BEGIN THRESHOLD CHECKS
#################################################

if [[ $CURRENT_TEMP < $STAGE1_TEMP ]];
  then
    ## Enter Manual Control Mode -- Do Not Modify/Remove
    ipmitool -I lanplus -H $IPMIHOST -U $IPMIUSER -P $IPMIPW -y $IPMIEK  raw 0x30 0x30 0x01 0x00

    ## Set fan speed to STAGE1_FAN
    ipmitool -I lanplus -H $IPMIHOST -U $IPMIUSER -P $IPMIPW -y $IPMIEK raw $STAGE1_FAN

    ## Optional: Set an emoji for the Discord notification, this is a sub-component of curl's content.
    DISCORD_EMOJI=\:snowflake\:

    ## Write the new fan speed as a variable
    NEW_FAN_SPEED=$STAGE1_FAN_SPEED

elif [[ $CURRENT_TEMP < $STAGE2_TEMP ]];
  then
    ## Enter Manual Control Mode -- Do Not Modify/Remove
    ipmitool -I lanplus -H $IPMIHOST -U $IPMIUSER -P $IPMIPW -y $IPMIEK  raw 0x30 0x30 0x01 0x00

    ## Set fan speed to STAGE2_FAN
    ipmitool -I lanplus -H $IPMIHOST -U $IPMIUSER -P $IPMIPW -y $IPMIEK raw $STAGE2_FAN

    ## Optional: Set an emoji for the Discord notification, this is a sub-component of curl's content.
    DISCORD_EMOJI=\:wind_blowing_face\:

    ## Write the new fan speed as a variable
    NEW_FAN_SPEED=$STAGE2_FAN_SPEED

elif [[ $CURRENT_TEMP < $STAGE3_TEMP ]];
  then
    ## Enter Manual Control Mode -- Do Not Modify/Remove
    ipmitool -I lanplus -H $IPMIHOST -U $IPMIUSER -P $IPMIPW -y $IPMIEK  raw 0x30 0x30 0x01 0x00

    ## Set fan speed to STAGE3_FAN
    ipmitool -I lanplus -H $IPMIHOST -U $IPMIUSER -P $IPMIPW -y $IPMIEK raw $STAGE3_FAN

    ## Optional: Set an emoji for the Discord notification, this is a sub-component of curl's content.
    DISCORD_EMOJI=\:dash\:

    ## Write the new fan speed as a variable
    NEW_FAN_SPEED=$STAGE3_FAN_SPEED

elif [[ $CURRENT_TEMP < $STAGE4_TEMP ]];
  then
    ## Enter Manual Control Mode -- Do Not Modify/Remove
    ipmitool -I lanplus -H $IPMIHOST -U $IPMIUSER -P $IPMIPW -y $IPMIEK  raw 0x30 0x30 0x01 0x00

    ## Set fan speed to STAGE4_FAN
    ipmitool -I lanplus -H $IPMIHOST -U $IPMIUSER -P $IPMIPW -y $IPMIEK raw $STAGE4_FAN

    ## Optional: Set an emoji for the Discord notification, this is a sub-component of curl's content.
    DISCORD_EMOJI=\:dash\:

    ## Write the new fan speed as a variable
    NEW_FAN_SPEED=$STAGE4_FAN_SPEED

elif [[ $CURRENT_TEMP > $STAGE4_TEMP ]];
  then
    ## If the temperature is getting too high, then allow the server to regulate it's own temperature until it drops below STAGE3_TEMP again.

    ## Reset back to Automatic Fan Control -- Do Not Modify/Remove
    ipmitool -I lanplus -H $IPMIHOST -U $IPMIUSER -P $IPMIPW -y $IPMIEK raw 0x30 0x30 0x01 0x01

    ## Optional: Set an emoji for the Discord notification, this is a sub-component of curl's content.
    DISCORD_EMOJI=\:cloud_tornado\:

    # Add a mention for the @sysadmin role to notify me about higher temperatures, this is a sub-component of curl's content.
    DISCORD_ROLE=\-\-\ \<@\&606200692373949153\>

    ## Write the new fan speed as a variable
    NEW_FAN_SPEED="Automatic"

fi

#################################################
# END THRESHOLD CHECKS
#################################################


#################################################
# BEGIN DISCORD NOTIFICATION
# Send a curl with two components:
#    - username
#    - content (which has 3 sub-components)
#         - emoji (DISCORD_EMOJI)
#         - message (DISCORD_MESSAGE)
#         - role (DISCORD_ROLE
#################################################

# Main message sub-component of content
DISCORD_MESSAGE_1=CPU\ Temperature\:\ $CURRENT_TEMP\°C.
DISCORD_MESSAGE_2=The\ current\ fan\ speed\ is\:\ $CURRENT_FAN_SPEED\ RPM.
DISCORD_MESSAGE_3=Adjusting\ the\ fan\ to\:\ $NEW_FAN_SPEED.

if [[ $STAGE_START != $STAGE_END ]];
then
    DISCORD_MESSAGE=$DISCORD_MESSAGE_1\ $DISCORD_MESSAGE_2\ $DISCORD_MESSAGE_3
else
    DISCORD_MESSAGE=$DISCORD_MESSAGE_1\ $DISCORD_MESSAGE_2
fi

# The username of the Bot that posts in Discord.
DISCORD_BOT_NAME=\"[Dell\ R710\ \-\ $IPMIHOST]\"

# The message to be posted in Discord. Combine all three sub-components
DISCORD_BOT_MESSAGE=\"[\ $DISCORD_EMOJI\ ]\ $DISCORD_MESSAGE\ $DISCORD_ROLE\"

# The Discord Webhook
DISCORD_WEBHOOK='https://discordapp.com/api/webhooks/webhook_url_goes_here'

# Send the message to Discord if the stage has changed.
if [[ $CURRENT_TEMP != $PREVIOUS_TEMP ]];
then
    curl -H "Content-Type: application/json" -X POST -d "{\"username\": $DISCORD_BOT_NAME, \"content\": $DISCORD_BOT_MESSAGE}" $DISCORD_WEBHOOK
fi
#################################################
# END DISCORD NOTIFICATION
#################################################
