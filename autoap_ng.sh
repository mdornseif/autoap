#!/bin/sh
##############################################################################################
##                                                                                          ##
##  AutoAP Next Gen by kuthulu/Iron, supported by wo-fo, infusion, drats, cid12, mathilda   ##
##  This script is inspired by the autoap script that stoped working after the command      ##
##  set of the "wl" was reduced in the DD-WRT V2.4 Beta firmware on the 18th of June 2007   ##
##                                                                                          ##
##  http://sourceforge.net/projects/autoap                                                  ##
##                                                                                          ##
##  AutoAP NG is a script that enables users to automatically log into different AP's       ##
##  that provide internet access. The AP's can be automatically searched or set in a list   ##
##                                                                                          ##
##  Terms and Conditions:                                                                   ##
##  AutoAP can be used, modified and distributed freely for private or commerical purposes  ##
##                                                                                          ##
##############################################################################################
version="2009-07-11"
# Todo:
# - Test script in all modes (AP, client, repeater etc.)
# - Test connection to WEP/WPA protected AP
# - Check network setup for G/mixed/B etc.
# - Connect to AP with specific MAC address
# - Deny other AP's macs with the same SSID. Fixed and dynamic list.
# - Give mac with preferred SSID(ssid*key*mac combination?)
# - Configure via web GUI
# - Use non volatile storage for history
# - Make script to create different versions: Micro, copy to rc_startup, cat
# - GPIO/logreverse on the fly change not allowed
# - Test!
#
# Idea's
# - Smarter html refresh, server push?
# - Use LED's to signal status (Ilja: hard for different router models!)
# - What to do with the idle time?
# - Using ping times to select a AP
# - Mesh networking
#
# Latest changes:
#
# 2009-7-11 (kingsmill)
# - fixed scripting errors result from apply changed settings from the cgi web script.
#   changed the for loop to a while loop
#
# 2009-6-28 (Ilja)
# - $aap_possid and $aap_prefssid finally work again... The missing IFS=" " was
#   spoiling the correct parsing of these entries
#
# 2009-06-21 (Ilja)
# - Changed such that it runs with the newer versions of dd-wrt...
#
# 2009-06-20 (andreev2001)
# - Changed "eth1" to "$(nvram get wl0_ifname)"
#
# 2009-05-06 (RNR aka Drats)
# - Fix for aap_maxfailed = 0 problem
#   which ignores number of failed connection attempts
#
# 2007-10-10 (RNR aka Drats)
# - Added code to include a list of possible WEP sites to include in the sort order
#
# 2007-07-28 (kuthulu/Iron)
# - Completely rewritten
#
# 2007-07-18 (kuthulu/Iron)
# - modified to use site_survey in stead of wl
#
##########################################################################
##  Script control variables, set your preferred values here.           ##
##  These variables have corresponding NVRAM variables.                 ##
##  The NVRAM variables will be read when the script is started, after  ##
##  a definable timout period, and when autoap_rescannow is set to "1"  ##
##########################################################################

# Defines after how many connection attempt a rescan is done.
# (1) NVRAM: autoap_aplimit=20
aap_aplimit=20

# Internet connection check frequency in minutes.
# (2) NVRAM: autoap_checkfreq=2
aap_checkfreq=2

# Length of time in seconds to wait for a DHCP request to succeed.
# Lower values are faster, but might not connect if the response is slow.
# (3) NVRAM: autoap_dhcptimeout=15
aap_dhcptimeout=15

# Defines the GPIO for showing that a connection was established.
# The GPIO number to use is different for each router.
# Check the GPIO layout of your router in the Wiki or in the forum.
# Make sure the GPIO you select is not used by a SD/MMC modification.
# (4) NVRAM: autoap_gpio=-1
aap_gpio=-1

# Defines the auto refresh time in seconds of the web log in the web brouwser.
# (5) NVRAM: autoap_htmlrefresh=30
aap_htmlrefresh=30

# Internet URL or IP address used to ping to ensure internet access is working.
# (6) NVRAM: autoap_ineturl=www.google.com
aap_ineturl=www.google.com

# Defines how to log the status.
# Valid option are "0": No logging, "1": html logging, "2": console, "3": html and console.
# If html is selected, then the log is available via web browser at http://router_ip/user/autoap.htm
# (7) NVRAM: autoap_logger=3
aap_logger=3

# Defines the display order of the log. "0"=newest log lines at bottom, "1"=newest log records on top.
# (8) NVRAM: autoap_logreverse=1
aap_logreverse=1

# Defines the maximum number of lines in the logfile.
# (9) NVRAM: autoap_logsize=100
aap_logsize=100

# Defines the HTML log width in pixels.
# (10) NVRAM: autoap_logwidth=940
aap_logwidth=940

# MAC/BSSID Ignore List
# Space seperated list of MAC address you don't want to connect to.
# (11) NVRAM: autoap_macfilter="00:11:22:33:44:55 AA:BB:CC:DD:EE:FF"
# Currently not supported!
aap_macfilter=""

# Defines after how many failed connection attempts an AP should be ignored.
# Set it to "0" to ignore it.
# (12) NVRAM: autoap_maxfailed=5
aap_maxfailed=5

# Sets the AP scanning mode to passive or active.
# In active mode the router sends a requests and check who responds.
# In passive mode the router listens to beacons.
# (13) NVRAM: aap_passive=0
aap_passive=0

# Defines the search mode. Try to find all AP's that provide internet access. "0"=NO, "1"=YES
# (14) NVRAM: autoap_prefonly=0
aap_prefonly=0

# Defines the order in which to try available preferred SSID's. "0"=Use SNR order, "1"=Use listed order
# (15) NVRAM: autoap_preforder=0
aap_preforder=0

# == Options for the next two entries ==
# Space separated list of preferred SSID. They will be tried first if available.
# An encryption-key can be attached with a separating "*key*"
# In the SSID replace a star:         "*" by backslash star:         "\*"
# In the SSID replace a space:        " " by star:                   "*"
# In the key  replace a backslash:    "\" by 4 backslashes:          "\\\\"
# In the key  replace a backtick:     "`" by backslash backtick:     "\`"
# In the key  replace a dollar sign:  "$" by backslash dollar sign:  "\$"
# In the key  replace a double quote: """ by backslash double qoute: "\""
# In the key  replace a asterix:      "*" by backslash asterix:      "\*"
#
# SSID preferred list
# (16) NVRAM: autoap_prefssid="ssid*with*spaces ssid_is_wep*key*123456abcd"
aap_prefssid=""

# A space seperated list that will include these WEP encrypted SSID's with the
# open SSID's which may be selected for connection to based on SNR order.
# (16a) NVRAM: autoap_possid="ssid*with*spaces ssid_is_wep*key*123456abcd"
aap_possid=""

# Defines the AP refresh scan delay in minutes.
# A rescan can be usefull to find a stronger signal.
# If your router is always located at the same place then you might want to increase the value.
# Set it to "0" if you want to disable this function.
# This option is useful for for mobile routers.
# (17) NVRAM: autoap_rescandelay=120
aap_rescandelay=120

# Defines the search mode. Only try to find open networks, when found just continue. "0"=NO, "1"=YES
# (18) NVRAM: autoap_scanonly=0
aap_scanonly=0

# SSID Ignore List
# This is a space separated list of SSID's to ignore.
# Spaces in the SSIDs have to be replaced by "*". Example "Bad*AP"
# (19) NVRAM: autoap_ssidfilter="ssid ssid*with*spaces"
aap_ssidfilter=""

# Try's the SSID's in the prefssid list even if they are not found by a scan
# (20) NVRAM: autoap_tryhidden=0
aap_tryhidden=0

# Internet check toggle. "0"=don't verify connection, "1"=check it.
# (21) NVRAM: autoap_watchinet=1
aap_watchinet=1

## FUNCTIONS AND PROCEDURES ####################################

## Update the local AutoAP variables with the values in NVRAM ##
## Takes no parameters, no return value
## Command line support is provided by this fuction.
aap_varupdate ()
{
  nvram set autoap_rescannow=0
  index=1
  hd=""
  gpio enable $aap_gpio

  [ -n "$(nvram get autoap_logreverse)" ] && lr=$(nvram get autoap_logreverse)
  [ -n "$8" ] && lr=$8
  if [ $lr != $aap_logreverse ]; then
    # Reset log, sortorder changed
    index=1
    lines=1
    rm -f "$htmllog"
    aap_head CCCCFF Searching... x
  fi
  [ -n "$1" ] && x=" and command line parameters" || x=""
  aap_log CCCCFF "Reading NVRAM variables$x..."
  nvram show 2>/dev/null | grep autoap_ >/tmp/aap.result
  set | grep aap_ | sed "s/aap_//;s/=.*//" > /tmp/aap.set.result
  while read x; do
    eval "y=\$aap_$x"
    [ $(grep -c "autoap_$x" /tmp/aap.result) -gt 0 ] && eval "z=\"$(nvram get autoap_$x)\"" || z=$y
    [ -n "$1" ] && z="$1" && shift
    [ "$y" != "$z" ] && aap_log CCCCFF "Received new value for <b>$x</b>: \"$z\"" && hd=1
    eval "aap_$x=\$z"
  done < /tmp/aap.set.result
  nPREF=$(echo $aap_prefssid|wc -w)
  nMACF=$(echo $aap_macfilter|wc -w)
  nSSIDF=$(echo $aap_ssidfilter|wc -w)
  nPOSS=$(echo $aap_possid|wc -w)
  
  if [ -z "$aap_prefssid" -a $aap_prefonly -gt 0 ]; then
    aap_log CCCCFF "The preferred SSID list is empty, disabling preferred only mode."
    aap_prefonly=0
  fi

  aap_head CCCCFF Searching... $hd
}

## Generic logging function for HTML or console ##
## Syntax: aap_log <html_color> <full line cell text>
## Syntax: aap_log <html_color> <cell 1 text> <cell 2 text> [cell 3 text] [cell 4 text] [cell 5 text] [cell 6 text]
aap_log ()
{
  if [ "$(($aap_logger & 1))" = 1 ]; then
    cl=CCCCFF
    t="</td><td>"
    [ -z "$2" ] && ts="" && cl=$1 || ts=$(uptime | sed "s/up.*$//")
    [ -z "$3" ] && v="<tr bgcolor=#$1><td width=1% bgcolor=#$cl>$ts</td><td colspan=6>$2</td></tr>" \
                || v="<tr bgcolor=#$1 align=center><td width=1% bgcolor=#$cl>$ts$t$2$t$3$t$4$t$5$t$6$t$7</td></tr>" >> "$htmllog"
    if [ $aap_logreverse -gt 0 ]; then
      # Insert line into log
      sed "${index}a$v" "$htmllog" > /tmp/aap.t1
      index=$(($index+1))
      cp /tmp/aap.t1 "$htmllog"
    else
      # Add line to end of log
      echo $v >> "$htmllog"
    fi

    lines=$(($lines+1))
    if [ $lines -gt $aap_logsize ]; then
      if [ $aap_logreverse -gt 0 ]; then
        # Remove part of the end of the file, but not current record
        [ $index -lt $((3*$aap_logsize/4)) ] && k=$((3*$aap_logsize/4-1)) || k=$index
        sed "$k q" /tmp/aap.t1 > "$htmllog"
        lines=$k
      else
        cp "$htmllog" /tmp/aap.t1
      fi
      if [ $aap_logreverse -le 0 -o $index -gt $aap_logsize ]; then
        # Remove part of the old log in the beginning of the file, leave header in tact
        sed "2,$((2+$aap_logsize/4))d" /tmp/aap.t1 > "$htmllog"
        lines=$(($lines-1-$aap_logsize/4))
        index=$(($index-1-$aap_logsize/4))
      fi
    fi
    rm -f /tmp/aap.t1
  fi
  [ "$(($aap_logger & 2))" = 2 ] && shift && echo "$*" | sed "s#<[^>]*>##g"
}

## Ping function to verify internet connection
## Syntax: status = aap_ping <x>
## Pings twice (if needed) if a parameters is supplied
## Returns "" on fail. Returns the ping stats if successful: "xx% packet Loss. Ping round-trip min/avg/max = xx.x/xx.x/xxx.x ms"
aap_ping ()
{
  ap_good=""
  if [ "$(nvram get wan_ipaddr)" != "0.0.0.0" -a "$(nvram get autoap_rescannow)" -le 0 ]; then
    # Try pinging only if a ipaddress was assigned
    [ $aap_watchinet -gt 0 ] && x=$aap_ineturl || x=$(nvram get wan_gateway)
    ap_good="$(ping -c5 "$x" | grep [/,] | sed 'N;s/.*,//; s/\n/. Ping /')"
    [ -z "$ap_good" -a -n "$1" ] && [ "$(nvram get autoap_rescannow)" -le 0 ] && ap_good=$(ping -c5 "$x" | grep [/,] | sed 'N;s/.*,//; s/\n/. Ping /')
  fi
  [ -n "$ap_good" ] && gpio disable $aap_gpio || gpio enable $aap_gpio
  echo "$ap_good"
}

## (Re)writes the head of the html log.
## Syntax: aap_head <htmlcolor> <title message> <force rewrite>
## No return value
aap_head ()
{
  if [ "$headstatus" != "$2$aap_htmlrefresh" -o -n "$3" ]; then
    sp="<tr bgcolor=#444444><td colspan=7></td></tr>"
    t="</td><td>"
    ts="<tr bgcolor=#CCCCFF align=center><td>$(uptime | sed "s/up.*$//")$t"
    echo "<html><head><meta http-equiv=\"REFRESH\" CONTENT=\"$aap_htmlrefresh\"><meta http-equiv=\"Cache-Control\" content=\"no-cache, must-revalidate\"><meta http-equiv=\"Pragma\" content=\"nocache\"><title>AutoAP Next Gen ($version) - $2</title></head><body bgcolor=#DDDDFF><table align=center width=$aap_logwidth>$sp<tr bgcolor=#$1 align=center><td colspan=7><FONT SIZE=5>AutoAP Next Gen ($version) - $2</FONT></td></tr>$sp \
          $ts Preferred Only=$aap_prefonly,$nPREF$t Preferred SSID Order=$aap_preforder Possible_Pref=$nPOSS $t Passive Scan=$aap_passive$t Scan Only=$aap_scanonly$t Max failed=$aap_maxfailed$t GPIO=$aap_gpio</td></tr> \
          $ts Check Internet=$aap_watchinet$t Ping=$aap_ineturl$t Check Freq=$aap_checkfreq$t Rescan Delay=$aap_rescandelay$t DHCP Timeout=$aap_dhcptimeout$t AP Limit=$aap_aplimit</td></tr> \
          $ts Logger=$aap_logger$t Log Reverse=$aap_logreverse$t Log Size=$aap_logsize,$aap_logwidth$t Try Hidden=$aap_tryhidden$t HTML Refresh=$aap_htmlrefresh$t Filter SSID=$nSSIDF,MAC=$nMACF </td></tr>$sp" > /tmp/aap.t3
    sed "1d" "$htmllog" >> /tmp/aap.t3
    cp /tmp/aap.t3 "$htmllog"
    rm -f /tmp/aap.t3
    headstatus="$2$aap_htmlrefresh"
  fi
}

## Contains logic to verify the connection to the correct AP
## and the assignment of a valid DHCP address.
## Syntax: aap_checkjoin <ssid> <type> <mac address> [key] [nofail]
aap_checkjoin ()
{
  if [ -n "$4" ]; then
    aap_log CCFFCC "Trying to connect to $2: \"$1\" with MAC Address: $3, with key: \"$4\""
  else
    aap_log CCFFCC "Trying to connect to $2: \"$1\" with MAC Address: $3"
  fi

  cur_ssid=$(wl ssid | sed "s/^.*:.\"//; s/\"$//")
  cur_bssid=$(wl bssid 2>/dev/null | sed "s/^.*:.\"//; s/\"$//")
  ap_good=""
  
  # Don't break active connection
  [ "$1" = "$cur_ssid" -a "$3" = "$cur_bssid" ] && ap_good=$(aap_ping)
  [ "$(nvram get autoap_rescannow)" -gt 0 ] && return

  if [ -z "$ap_good" ]; then
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
    udhcpc -i $(nvram get wl0_ifname) -p /tmp/var/run/udhcpc.pid -s /tmp/udhcpc > /dev/null 2>&1 &

    # wait for assigment of WAN IP address
    c=$aap_dhcptimeout
    while [ $c -gt 0 -a "$(nvram get autoap_rescannow)" -le 0 ] && [ "$(nvram get wan_ipaddr)" = "0.0.0.0" -o "$(nvram get wan_gateway)" = "0.0.0.0" ]; do
      sleep 3
      c=$(($c-3))
    done
    ap_good=$(aap_ping)
    [ "$(nvram get autoap_rescannow)" -gt 0 ] && return
  fi

  if [ -n "$ap_good" ]; then
    aap_log 66FF66 "Connected to: \"$1\" with MAC Address: $(wl bssid) Gateway: $(nvram get wan_gateway) WLAN IP: $(nvram get wan_ipaddr)"
    aap_head 66FF66 "Connected to: \"$1\""
    # Got a connection, remove AP from failed list if present
    cp /tmp/aap.failed /tmp/aap.t4
    grep -v "$1-$3" /tmp/aap.t4 > /tmp/aap.failed
    rm -f /tmp/aap.t4
    countdown=$aap_rescandelay

    while [ -n "$ap_good" ]; do
      [ $aap_rescandelay -le 0 ] && y="not rescanning." || y="rescanning in $countdown minute(s)."
      [ $aap_rescandelay -gt 0 ] && countdown=$(($countdown - $aap_checkfreq))
      [ $countdown -lt 0 ] && nvram set autoap_rescannow=1
      [ $aap_scanonly -gt 0 ] && aap_log 66FF66 "\"$1\" $ap_good" && return
      [ "$(nvram get autoap_rescannow)" -gt 0 ] && return

      aap_log 66FF66 "Monitoring connection every $aap_checkfreq minute(s), $y$ap_good"
      # Loop here until connection is lost or a rescan is needed/requested
      sleep $(($aap_checkfreq*60 -6))
      ap_good=$(aap_ping 2)

      if [ "$(($aap_logger & 1))" = 1 ]; then
        # Remove line from the log
        lines=$(($lines-1))
        cp "$htmllog" /tmp/aap.t5
        [ $aap_logreverse -gt 0 ] && sed "$index d" /tmp/aap.t5 > "$htmllog" && index=$(($index-1)) || sed '$d' /tmp/aap.t5 > "$htmllog"
        rm -f /tmp/aap.t5
      fi
      [ "$(nvram get autoap_rescannow)" -gt 0 ] && return
    done
    aap_log FF8888 "Lost connection to: \"$1\". No response to ping request."
  else
    aap_log FF8888 "Failed to ping: \"$1\" Gateway: $(nvram get wan_gateway) Received IP Address: $(nvram get wan_ipaddr)"
    [ $aap_maxfailed -gt 0 -a "$5" != 1 ] && echo "$1-$3" >> /tmp/aap.failed
    aap_head CCCCFF Searching...
  fi
}

## Performs all of the parsing and filter logic
## Takes no parameters, no return value
aap_scan ()
{
  rm -f /tmp/aap.scan
  touch /tmp/aap.scan
  aap_log 44FFFF Status Type Name "MAC Address" Channel SNR[dB]
  if [ $aap_tryhidden -gt 0 ]; then
    for n in $aap_prefssid; do
      # Dump all preferred networks in aap.result if they are not there already                   
      tSSID=$(echo "$n" | sed "s/\(.*\)\*key\*.*/\1/; s/*/ /g")
      # Look for "[ ssid]", ignoring spaces at start
      is_detected=$(egrep -c "\[[ ]*$tSSID\]" /tmp/aap.result)
      if [ $is_detected -eq 0 ]; then
        # Didn't find the SSID already
        echo "[] [$tSSID] [unknown] chan=[-] [0] [0] [] [421] [0] [-] [HIDDEN]" >> /tmp/aap.result
      fi         
    done
  fi
  
  while IFS="[]"; read a b cSSID e cBSSID g cCHAN i cRSSI k cNOISE m n o cCAP q r s t u cMODES; do
    # Skip the first line, look if cCHAN is defined:
    [ "$cCHAN" = "" ] && continue
    # Workaround for bug in site_survey, long SSID's show wrong
    cSSID=$(echo "$cSSID" | sed "s/^ *//" | awk '{ print substr($0,1,32) }')
    net_type="open"
    status=Ignoring # define a default value, will be overwritten if anything else
    order=000
    cKEY=""
    [ "$cMODES" = "HIDDEN" ] && net_type="hidden" 
    [ -n "$(echo "$cMODES" | grep -i "WEP")" ] && net_type="WEP"
    [ -n "$(echo "$cMODES" | grep -i "WPA")" ] && net_type="WPA"

    [ "$net_type" = "open" -a $aap_prefonly -le 0 ] && status="Found"

#
#             RNR 2009-05-06
#
#     A fix for aap_maxfailed = 0 problem
#             if "0" it should ignore connection failures, if not "0" then mark the site
#             to ignore future connection attempts.
#
    [ $aap_maxfailed -gt 0 ] && [ $(grep -c "$cSSID-$cBSSID" /tmp/aap.failed) = $aap_maxfailed ] && status=Ignoring


    for i in $aap_ssidfilter; do
      [ "$cSSID" = $(echo "$i" | sed "s/*/ /g") ] && status=Ignoring && break
    done

    for i in $aap_macfilter; do
      [ "$cBSSID" = "$i" ] && status=Ignoring && break
    done

    i=999
    IFS=" ";
    for n in $aap_prefssid; do
      tSSID=$(echo "$n" | sed "s/\(.*\)\*key\*.*/\1/; s/*/ /g")
      i=$(($i-1))
      if [ "$tSSID" = "$cSSID" ]; then
        status="Found"
        [ $aap_preforder -gt 0 ] && order=$i || order=999
        net_type="preferred $net_type"
        cKEY=$(echo "$n" | awk -F'\*key\*' '{ print $2 }')
        break
      fi
    done

#
#	RNR	2007-10-10
#
#	This looks like a good place to add a check  for possibly
#		valid SSID's with *key* and mark it as Found so that
#		it is checked in SNR order.
#

     IFS=" ";
     for n in $aap_possid; do
      tSSID=$(echo $n | sed "s/\(.*\)\*key\*.*/\1/; s/*/ /g")
      if [ "$tSSID" = "$cSSID" ]; then
        status="Found"
        net_type="included $net_type"
        cKEY=$(echo $n | awk -F'\*key\*' '{ print $2 }' | sed s/://g )
        break
      fi
    done
#
#	RNR	2007-10-10
#

   cSNR=$(($cRSSI - $cNOISE))
    # Make 0 for negative SNR and add leading zero
    [ $cSNR -lt 0 ] && cSNR=0
    [ $cSNR -lt 10 ] && cSNR=0$cSNR
    [ "$(($cCAP % 10))" = 2 ] && cINFRA=AdHoc || cINFRA=AP
    echo "$order$cSNR *EEEE44*$status*$net_type $cINFRA*$cSSID*$cBSSID*$cCHAN*$cSNR*$cKEY" >> /tmp/aap.scan
  done < /tmp/aap.result
  sort -r /tmp/aap.scan > /tmp/aap.result

  c=0
  while IFS="*" read a b d e f g h i j; do
    aap_log "$b" "$d" "$e" "$f" "$g" "$h" "$i"
    [ "$d" = "Found" ] && c=$(($c+1))
  done < /tmp/aap.result

  if [ $c -gt 0 ]; then
    # Try candidates
    ct=0
    while IFS="*" read a b cSTATUS cTYPE cSSID cBSSID h i cKEY; do
      [ "$cSTATUS" != "Found" -o -n "$(echo "$cTYPE" | egrep -i "WEP|WPA")" -a -z "$cKEY" ] && continue
      [ -n "$(echo "$cTYPE" | grep "preferred")" ] && NOFAIL=1 || NOFAIL=0
      aap_checkjoin "$cSSID" "$cTYPE" "$cBSSID" "$cKEY" "$NOFAIL"
      [ "$(nvram get autoap_rescannow)" -gt 0 -o $ct -ge $aap_aplimit ] && return
      ct=$(($ct+1))
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
index=1
lines=1
nPREF=0
nMACF=0
nSSIDF=0
rm -f "$htmllog"
rm -f /tmp/aap.failed
touch /tmp/aap.failed
if [ $(ps | grep -c "$0") -gt 3 ]; then
  echo "ERROR: Another instance of \"$0\" is running. Exiting..."
  exit
fi
aap_head CCCCFF Initialzing...
aap_varupdate $*
# Check this with repeater client mode etc. ???
if [ $(nvram get wl_mode) = ap ]; then
  aap_log FF8888 "FATAL ERROR - Router is in AP mode, switch to repeater mode and try again. Exiting..."
  exit
fi

if [ $(nvram get wan_proto) != dhcp ]; then
  aap_log FF8888 "WARNING - Router mode changed to DHCP"
  nvram set wan_proto=dhcp
fi

[ "$(($aap_logger & 1))" = 0 ] && echo "<tr><td colspan=7 bgcolor=#FF8888>Warning: HTML logging is disabled ($aap_logger), set autoap_logger to 1 or 3 to enable it. Continuing...</td></tr>" >> "$htmllog"
## MAIN LOOP ##########
while :; do
  countdown=0
  wl wsec 0 2>/dev/null
  rm -f /tmp/aap.result
  rm -f /tmp/aap.set.result
  [ $aap_passive -gt 0 ] && wl passive 1 || wl passive 0
  aap_head CCCCFF Searching...
  site_survey 2> /tmp/aap.result
  if [ $(grep -c c /tmp/aap.result) -ge 2 -o $(($aap_tryhidden * $nPREF)) -gt 0 ]; then
    [ $no_ap = 1 ] && index=1 && aap_log 444444 && index=1
    aap_log 44FFFF "Successfully collected access point scan data, analysing..."
    no_ap=0
    aap_scan
  else
    [ $no_ap = 0 ] && no_ap=1 && aap_log FF8888 "No AP's found in range, scanning continuously..."
    gpio enable $aap_gpio
    sleep 15
  fi

  [ $countdown -lt 0 ] && aap_log CCCCFF "Rescan period exceeded. Rescanning..."
  [ $countdown -ge 0 -a "$(nvram get autoap_rescannow)" -gt 0 ] && aap_log CCCCFF "Rescan requested by user. Rescanning..." && no_ap=0
  [ $no_ap = 0 ] && index=1 && aap_log 444444
  index=1
  [ "$(nvram get autoap_rescannow)" -gt 0 ] && aap_varupdate && no_ap=0
done

