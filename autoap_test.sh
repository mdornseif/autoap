#!/bin/sh
###########################################################################################
##                                                                                       ##
##  AutoAP Next Gen by kuthulu/Iron, with support of wo-fo, infusion, drats, cid12       ##
##  The script was completely rewritten and updated to work with the changes in DD-WRT   ##
##  http://sourceforge.net/projects/autoap                                               ##
##                                                                                       ##
##  AutoAP NG is a script that enables users to automatically log into different AP's    ##
##  that provide internet access. The AP can be automatically searched or set in a list  ##
##                                                                                       ##
##  Terms and Conditions:                                                                ##
##  AutoAP is released under the GNU Public License, and is subject to all conditions    ##
##  of the latest version. The full version of the license can be viewed within the      ##
##  filed named LICENSE, or by visiting http://www.gnu.org/licenses/gpl.txt              ##
##                                                                                       ##
###########################################################################################
aap_version="2007-08-07"
#
# Todo:
# - Connect to AP with specific MAC address
# - Deny other AP's macs with the same SSID. Fixed and dynamic list.
# - Give mac with preferred SSID(ssid*key*mac combination?)
# - Check network setup for G/mixed/B etc.
# - Configure via web GUI
# - Use non volatile storage for history
# - Make script to create different versions: Micro, copy to rc_startup, cat
# - Test connection WEP/WPA protected AP
# - Test script in all modes (AP, client, repeater etc.)
# - Test!
#
# Latest changes:
# 2007-07-28 (kuthulu/Iron)
# Completely rewritten
#
# 2007-07-18 (kuthulu/Iron)
# - modified to use site_survey in stead of wl
#
##########################################################################
##  Script control variables, set your preferred values here.           ##
##  These variables have corresponding NVRAM variables.                 ##
##  The NVRAM variables will be read when the script is started, after  ##
## a definable timout period, and when autoap_rescannow is set to "1"   ##
##########################################################################

# Defines the search mode. Try to find open AP's. "0"=NO, "1"=YES
# NVRAM: autoap_findopen="1"
aap_findopen="1"

# Defines the search mode. Try to find encrypted AP's. "0"=NO, "1"=YES
# NVRAM: autoap_findwep="0"
aap_findwep="0"

# Defines the search mode. Only try to find open networks, when found just continue. "0"=NO, "1"=YES
# NVRAM: autoap_scanonly="0"
aap_prefonly="0"

# Defines the search mode. Try to find all AP's that provide internet access. "0"=NO, "1"=YES
# NVRAM: autoap_prefonly="0"
aap_scanonly="0"

# Defines after how many failed connection attempts an AP should be ignored.
# set it to "0" to ignore it
# NVRAM: autoap_maxfailed="5"
aap_maxfailed="5"

# SSID preferred list
# Space separated list of preferred SSID. They will be tried first if available.
# An WEP-key can be attached with a separating "*key*"
# Spaces in the SSIDs have to be replaced by "*". Example "My*Router"
# NVRAM: autoap_prefssid="ssid*with*spaces ssid_is_wep*key*123456abcd"
aap_prefssid=""

# SSID Ignore List
# This is a space separated list of SSID's to ignore.
# Spaces in the SSIDs have to be replaced by "*". Example "Bad*AP"
# NVRAM: autoap_ssidfilter="ssid ssid*with*spaces"
aap_ssidfilter=""

# MAC/BSSID Ignore List
# Space seperated list of MAC address you don't want to connect to.
# NVRAM: autoap_macfilter="00:11:22:33:44:55 AA:BB:CC:DD:EE:FF"
aap_macfilter=""

# Logger mode. Defines how to log the status.
# Valid option are "0": No logging, "1": html logging, "2": console, "3": html and console.
# If html is selected, then the log is available via web browser at
# http://routerip/user/autoap.htm
# NVRAM: autoap_logger="3"
aap_logger="3"

# Maximum number of lines in the logfile.
# NVRAM: autoap_logsize="23"
aap_logsize="1000"

# Internet check toggle. "0"=don't verify connection, "1"=check it.
# NVRAM: autoap_watchinet="1"
aap_watchinet="1"

# Internet URL or IP address used to ping to ensure internet access is working.
# NVRAM: autoap_ineturl="www.google.com"
aap_ineturl="www.google.com"

# Internet connection check frequency in minutes.
# NVRAM: autoap_checkfreq="2"
aap_checkfreq="2"

# Defines the AP refresh scan delay in minutes
# A rescan can be usefull to find a stronger signal.
# If your router is always located at the same place then you might want to increase the value.
# Set it to "0" if you want to disable this function.
# This option is mostly used for mobile router.
# NVRAM: autoap_rescandelay="120"
aap_rescandelay="120"

# Length of time in seconds to wait for a DHCP request to succeed.
# Lower values are faster, but might not connect if the response is slow.
# NVRAM: autoap_dhcptimeout="15"
aap_dhcptimeout="15"

# Defines the auto refresh time in seconds of the web log in the web brouwser.
# NVRAM: autoap_htmlrefresh="30"
aap_htmlrefresh="30"

# Defines after how many connection attempt a rescan is done. 
# NVRAM: autoap_aplimit="20"
aap_aplimit="20"

# Defines the GPIO to use to show that a connection was established.
# The GPIO number to provide is different for each router.
# Check the GPIO layout of your router in the Wiki or in the forum.
# Make sure the GPIO you select is not used for a SD/MMC modification.
# NVRAM: autoap_gpio="-1"
aap_gpio="-1"

# Sets the AP scanning mode to passive or active.
# In active mode the router sends a requests and check who responds. 
# In passive mode the router listens to beacons. 
# NVRAM: aap_passive="0"
aap_passive="0"

## FUNCTIONS AND PROCEDURES ####################################

## Update the local AutoAP variables with the values in NVRAM ##\
## Takes no parameters, no return value
## Command line support is provided by this fuction!!! Check the order of the variables in the for loop.## Command line support is provided by this fuction!!! Check the order of the variables in the for loop.
aap_varupdate ()
{
  nvram set autoap_rescannow=0
  x=$aap_logger
  [ -n "$(nvram get autoap_logger)" ] && aap_logger="$(nvram get autoap_logger)"
  [ -n "$1" ] && aap_logger="$1"
  [ $(($aap_logger & 1)) = 1 ] && errredir="$htmllog" || errredir="/dev/null"
  aap_log CCCCFF "Reading NVRAM variables"
  aap_logger=$x
  
  for x in logger findopen findwep prefonly scanonly prefssid ssidfilter aplimit maxfailed rescandelay checkfreq watchinet ineturl dhcptimeout logger logsize htmlrefresh macfilter gpio passive; do  
    eval "t=\"\$aap_$x\""
    [ -n "$(nvram get autoap_$x)" ] && eval "aap_$x=\"$(nvram get autoap_$x)\""
    [ -n "$1" ] && eval "aap_$x=\"$1\"" && shift
    eval "[ \"$t\" != \"\$aap_$x\" ] && aap_log CCCCFF \"Received new value for <b>$x</b>: \\\"\$aap_$x\\\"\""
    c=$((c + 1))
  done
  
  countdown=$aap_rescandelay

  if [ -z "$aap_prefssid" -a $aap_prefonly != 0 ]; then
    aap_log CCCCFF "The preferred SSID list is empty, disabling preferred AP's only mode."
    aap_prefonly=0
  fi
  aap_log CCCCFF "Find Open=$aap_findopen" "Find WEP=$aap_findwep" "Preferred Only=$aap_prefonly" "Scan Only=$aap_scanonly" "Internet=$aap_watchinet" "Log=$aap_logger,$aap_logsize"
  aap_log CCCCFF "Ping=$aap_ineturl" "DHCP Timeout=$aap_dhcptimeout" "AP Limit=$aap_aplimit" "Max failed=$aap_maxfailed" "Refresh=$aap_htmlrefresh" "GPIO=$aap_gpio"
}

## Generic logging function for HTML or console ##
## Syntax: aap_log <html_color> <full line cell text>
## Syntax: aap_log <html_color> <cell 1 text> <cell 2 text> <cell 3 text> <cell 4 text> <cell 5 text> <cell 6 text>
aap_log ()
{
  if [ -n "$errredir" -a $(grep -c "" "$errredir" ) -gt $aap_logsize ]; then
    cp "$errredir" /tmp/tmplog
    sed "2,$(($aap_logsize / 4))d" /tmp/tmplog > $errredir
    rm -f "/tmp/tmplog"
  fi
  if [ $(($aap_logger & 1)) = "1" ]; then
    ts=$(uptime | sed 's/up.*$//')
  [ -z "$3" ] && echo "<tr bgcolor=#$1><td bgcolor=#CCCCFF>$ts</td><td colspan=6>$2</td></tr>" >> "$errredir" \
              || echo "<tr bgcolor=#$1 align=center><td bgcolor=#CCCCFF>$ts</td><td>$2</td><td>$3</td><td>$4</td><td>$5</td><td>$6</td><td>$7</td></tr>" >> "$errredir"
  fi
  [ $(($aap_logger & 2)) = "2" ] && shift && echo "$*" | sed 's#<[^>]*>##g'
}

## Ping function to verify internet connection
## Syntax: status = aap_pin [ x ] 
## returns 0 on fail, or the number of succesfull pings on success (1..5)
aap_ping ()
{
  ap_good=0
  sleep 1
  if [ $(nvram get wan_ipaddr) != "0.0.0.0" ]; then
    # Try pinging only if a ipaddress  was assigned
    [ $aap_watchinet -gt 0 ] && x="$aap_ineturl" || x="$(nvram get wan_gateway)"
    ap_good=$(ping -c 5 "$x" | grep -c from)
    [ $ap_good = 0 -a -n $1 ] && sleep 1 && ap_good=$(ping -c 5 "$x" | grep -c from)
  fi

  [ $ap_good -gt 0 ] && gpio disable $aap_gpio || gpio enable $aap_gpio
  echo $ap_good
}

## Contains logic to verify the connection to the correct AP
## and the assignment of a valid DHCP address.
## Syntax: aap_checkjoin <ssid> <type> <mac address> [key] [nofail]
aap_checkjoin ()
{
  if [ -n "$4" ]; then
    aap_log CCFFCC "Trying to connect to $2: \"$1\" ($3), with key: \"$4\""
  else
    aap_log CCFFCC "Trying to connect to $2: \"$1\" ($3)"
  fi

  ap_good=0;
  cur_ssid=$(wl ssid | sed 's/^.*:.\"//; s/\"$//')
  cur_bssid=$(wl bssid 2>/dev/null | sed 's/^.*:.\"//; s/\"$//')
  # Update, bssid check added 

  # Don't break active connection
  [ "$1" = "$cur_ssid" -a "$3" = "$cur_bssid" ] && ap_good=$(aap_ping)

  if [ $ap_good = 0 ]; then
    # Try to connect
    nvram set wan_ipaddr="0.0.0.0"
    nvram set wan_netmask="0.0.0.0"
    nvram set wan_gateway="0.0.0.0"
    nvram set wan_get_dns=""
    nvram set wan_lease="0"
    nvram set wl_ssid="$1"
    nvram set wl0_ssid="$1"
    wl wsec 0 2>/dev/null

    [ -n "$4" ] && wl join "$1" key "$4" || wl join "$1"
    sleep 2
    kill -USR2 $(cat /tmp/var/run/udhcpc.pid) > /dev/null 2>&1
    killall udhcpc > /dev/null 2>&1
    udhcpc -i eth1 -p /tmp/var/run/udhcpc.pid -s /tmp/udhcpc > /dev/null 2>&1 &

    # wait for assigment of WAN IP address
    c=$aap_dhcptimeout
    while [ $c -gt 0 -a $(nvram get wan_ipaddr) = "0.0.0.0" ]; do
      sleep 3
      c=$(($c - 3))
    done
    cur_ssid=$(wl ssid | sed 's/^.*:.\"//; s/\"$//')
    [ "$1" = "$cur_ssid" ] && ap_good=$(aap_ping)
  fi

  if [ $ap_good -gt 0 ]; then
    aap_log 66FF66 "Connected to AP: \"$cur_ssid\" ($(wl bssid)) Gateway: $(nvram get wan_gateway) WLAN IP: $(nvram get wan_ipaddr)"
    # Got a connection, remove AP from failed list if present
    cp /tmp/aap.failed /tmp/tmplog
    grep -v "$1-$3" /tmp/tmplog > /tmp/aap.failed
    rm -f /tmp/tmplog
    countdown=$aap_rescandelay
    
    while [ $ap_good -gt 0 ]; do
      [ $aap_rescandelay = 0 ] && x="not rescanning." || x="rescanning in $countdown minute(s)..."
      aap_log 66FF66 "Monitoring connection every $aap_checkfreq minute(s), $x"

      # Loop here until connection is lost or a rescan is needed/requested
      [ $aap_rescandelay -gt 0 ] && countdown=$(($countdown - $aap_checkfreq))
      [ $countdown -lt 0 ] && nvram set autoap_rescannow=1
      [ "$(nvram get autoap_rescannow)" -gt 0 -o $aap_scanonly -gt 0 ] && return
      sleep $(($aap_checkfreq * 60 -6))
      ap_good=$(aap_ping 2)
      cp "$errredir" /tmp/tmplog
      sed '$d' /tmp/tmplog > $errredir
      rm -f "/tmp/tmplog"
    done
    aap_log FF8888 "Lost connection to AP: \"$cur_ssid\". No response to ping request."
  else
    aap_log FF8888 "Failed to ping AP: \"$cur_ssid\" Gateway: $(nvram get wan_gateway) Received IP Address: $(nvram get wan_ipaddr)"
    [ $aap_maxfailed -gt 0 -a "$5" != 1 ] && echo "$1-$3" >> /tmp/aap.failed
  fi
}

## Performs all of the parsing and filter logic
## Takes no parameters, no return value
aap_scan ()
{
  rm -f /tmp/aap.scan
  touch /tmp/aap.scan
  aap_log 44FFFF Status Type "AP Name" "MAC Address" Channel SNR[dB]

  while IFS="[]" read a b c cSSID e cBSSID g cCHAN i cRSSI k cNOISE m n o cCAP q r s t u cMODES; do
    # Skip the first line
    [ "$cMODES" = "" ] && continue
    cSSID=$(echo $cSSID | sed 's/^ *//')
    net_type="open"
    status=Ignoring
    order=00
    ckey=""

    [ "$cMODES" = "WEP" ] && net_type="WEP"
    [ -n "$(echo "$cMODES" | grep -i "WPA")" ] && net_type="WPA"

    [ "$net_type" = "WEP" -a $aap_findwep -gt 0 ] && status=Found
    [ "$net_type" = "open" -a $aap_findopen -gt 0 ] && status=Found 

    [ $(grep -c "$cSSID-$cBSSID" /tmp/aap.failed) = $aap_maxfailed ] && status=Ignoring 
      
    for i in $aap_ssidfilter; do
      i="$(echo "$i" | sed 's/*/ /g')"
      [ "$cSSID" = "$i" ] && status=Ignoring && break
    done

    for j in $aap_macfilter; do
      [ "$cBSSID" = "$j" ] && status=Ignoring && break
    done

    [ $aap_prefonly -gt 0 ] && status=Ignoring

    for n in $aap_prefssid; do
      tSSID="$(echo "$n" | sed "s/\(.*\)\*key\*.*/\1/; s/*/ /g")"
      [ "$tSSID" = "$cSSID" ] && status="Found" && order=99 && net_type="preferred $net_type" && ckey="$(echo "$n" | awk -F'\*key\*' '{ print $2 }' )" && break
    done
    
    cSNR=$(($cRSSI - $cNOISE))
    # Make 0 for negative SNR and add leading zero
    [ $cSNR -lt 0 ] && cSNR=0
    [ $cSNR -lt 10 ] && cSNR="0$cSNR"
    [ $(echo $cCAP | sed 's/^..//') = 2 ] && cINFRA=ADHOC || cINFRA=AP     
    echo "$order$cSNR *EEEE44*$status*$net_type $cINFRA*$cSSID*$cBSSID*$cCHAN*$cSNR*$ckey" >> /tmp/aap.scan
  done < /tmp/aap.result
  sort -r /tmp/aap.scan > /tmp/aap.result

  c=0
  while IFS="*" read a b d e f g h i j; do
    aap_log "$b" "$d" "$e" "$f" "$g" "$h" "$i"
    [ "$d" = "Found" ] && c=$(($c + 1))
  done < /tmp/aap.result

  if [ $c -gt 0 ]; then
    # Try candidates
   c=0 
   while IFS="*" read a b cSTATUS cTYPE cSSID cBSSID d e cKEY; do
      [ "$cSTATUS" != "Found" -o -n "$(echo "$cTYPE" | egrep -i "WEP|WPA")" -a ! -n "$cKEY" ] && continue      
      [ -n "$(echo "$cTYPE" | grep "preferred")" ] && NOFAIL=1 || NOFAIL=0       
      aap_checkjoin "$cSSID" "$cTYPE" "$cBSSID" "$cKEY" "$NOFAIL"
      [ "$(nvram get autoap_rescannow)" -gt 0 -o $c -ge $aap_aplimit ] && return
      c=$(($c + 1))
    done < /tmp/aap.result
  else
    aap_log FF8888 "No suitable AP's found in range, rescanning..."
    gpio enable $aap_gpio
    sleep 10
  fi
}

## Start AutoAP ##############################################################
htmllog="/tmp/www/autoap.htm"
no_ap=0
sleep 1
if [ $(ps | grep -c "$0") -gt 3 ]; then
  echo "ERROR: Another instance of \"$0\" is running. Exiting..."
  exit
fi

echo "<html><head><META HTTP-EQUIV=REFRESH CONTENT=$aap_htmlrefresh><title>AutoAP Next Gen ($aap_version)</title></head><body bgcolor=#DDDDFF><table align=center><tr bgcolor=#CCCCFF align=center><td colspan=7><FONT SIZE=5>AutoAP Next Gen ($aap_version)</FONT></td></tr>" > "$htmllog"
aap_varupdate $*
[ $(($aap_logger & 1)) = 0 ] && echo "<tr colspan=7><td bgcolor=#CCCCFF align=left>HTML logging is disabled ($aap_logger), set autoap_logger to 1 or 3 to enable it</td></tr>" >> "$htmllog"

# Check this with repeater client mode etc. ???
if [ "$(nvram get wl_mode)" = "ap" ]; then
  aap_log FF8888 "FATAL ERROR - Router is not in repeater mode. Exiting..."
  exit
fi

if [ "$(nvram get wan_proto)" != "dhcp" ]; then
  aap_log FF8888 "WARNING - Router mode changed to DHCP"
  nvram set wan_proto="dhcp"
fi

gpio enable $aap_gpio
rm -f /tmp/aap.failed
touch /tmp/aap.failed

## MAIN LOOP ##########
while :; do
  wl wsec 0 2>/dev/null
  rm -f /tmp/aap.result
  [ $aap_passive -gt 0 ] && wl passive 1 || wl passive 0
  sleep 1
  site_survey 2> /tmp/aap.result
  if [ $(grep -c c /tmp/aap.result) -ge 2 ]; then
    no_ap=0
    aap_scan
  else
    [ $no_ap = 0 ] && no_ap=1 && aap_log FF8888 "No AP's found in range, scanning continuously..."
    gpio enable $aap_gpio
    sleep 15
  fi
  [ "$(nvram get autoap_rescannow)" -gt 0 ] && aap_varupdate
done
