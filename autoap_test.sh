#!/bin/sh
#########################################################################################
##                                                                                     ##
authstring="AutoAP, by JohnnyPrimus - lee@partners.biz - 2007-01-15 23:01 GMT"         ##
##                                                                                     ##
##  autoap is a small addition for the already robust DD-WRT firmware that enables     ##
##  users to migrate through/over many different wireless hotspots with low impact     ##
##  to the users internet connectivity.  This is especially useful in broad, city      ##
##  scale areas with dense AP population.                                              ##
##                                                                                     ##
#########################################################################################

#History:
#
#   2007-01-09
# - removed variable inet_two (was unused)
# - update cur_wip in aap_init_scan()
# - put ssid to join in quotes, to handle spaces in SSIDs
# - wait aap_dhcpw after dhcp renewal in aap_checkjoin()
# - reorganized aap_checkjoin() and aap_inet_chk. Should be cleaner and more reliable.
#
#   2007-01-10
# - make it insist more on ping to avoid changing connection for no reason
# - for some reason DD-WRT is not reliably assigning a GW address 
#   (nvram get wan_gateway). Making it tolerant for this behavior.
# - cleanup aap_inet_chk more. 24 lines down from 39
#
#   2007-01-11
# - getting rid of $logparse 
# - restructure aap_init_scan() some (no recursive calls, leave the checking to
#   aap_checkjoin() )
#
#   2007-01-12
# - truncate logfile works now.
# - preserve HTML header when truncating logfile
# - new nvram variable autoap_logsize (default 1000 lines)
#
#  2007-01-15
# - major overhaul aap_scanman and aap_joinpref
# - connection to wep-networks working now, however still sketchy
# - you can have both wep and open search enabled separately or together
#

ME=`basename $0`
RUNNING=`ps | grep $ME | wc -l`
if [ "$RUNNING" -gt 3 ]; then
   echo "Another instance of \"$ME\" is running"
   exit
fi

aaptmpdir="/tmp/autoap"
rm -rf $aaptmpdir/*
mkdir -p $aaptmpdir
rm -f /tmp/aap.result

######  Search modes - WEP and Open.  Default is Open enabled and WEP disabled.
##  nvram set autoap_findopen="1"
##  nvram set autoap_findwep="1"
##
##  Note: If WEP is enabled you need to provide keys to connect with.
##  AutoAP will try each key until one works.  If none work, it skips
##  that network.
##
aap_findopen="1"
aap_findwep="0"
[ -n "$(nvram get autoap_findopen)" ] && aap_findopen="$(nvram get autoap_findopen)";
[ -n "$(nvram get autoap_findwep)" ] && aap_findwep="$(nvram get autoap_findwep)";


######  Logging.  Default is log to syslog.
######  AutoAP can log to syslog, or to a file. Valid options are
##  syslog, filename and html.  If html is selected, the log is
##  available via web browser at http://routerip/autoap/log.html
##
aap_logger="syslog"
[ -n "$(nvram get autoap_logger)" ] && aap_logger="$(nvram get autoap_logger)";

######  WEP Keys
######  Space seperated list of wep keys to try
##  Currenly only supports 10 digit hex keys.  Others may work, untested.
##  nvram set autoap_wepkeys="00134A3BF2 5B8CE1B462 AAA1234567" 
##
aap_wepkeys=""
[ -n "$(nvram get autoap_wepkeys)" ] && aap_wepkeys="$(nvram get autoap_wepkeys)";

######  Max APs to track at once. Default 5
##  nvram set autoap_aplimit="5"
##
aap_aplimit="10"
[ -n "$(nvram get autoap_aplimit)" ] && aap_aplimit="$(nvram get autoap_aplimit)";

######  Internet check toggle.  Set to 1 to enable, 0 to disable.  Default enabled.
##  nvram set autoap_inet="1"
##
aap_watch_inet="1";
[ -n "$(nvram get autoap_inet)" ] && aap_watch_inet="$(nvram get autoap_inet)";

######  Internet check URL.  The URL or IP to ping to ensure internet access.
##  nvram set autoap_ineturl="www.partners.biz"
##
aap_chk_url="www.google.com";
[ -n "$(nvram get autoap_ineturl)" ] && aap_chk_url="$(nvram get autoap_ineturl)";

######  Length of time to wait for a DHCP request to succeed.  Default 15
##  nvram set autoap_dhcpw="15"
##
aap_dhcpw="15"
[ -n "$(nvram get autoap_dhcpw)" ] && aap_dhcpw="$(nvram get autoap_dhcpw)";

######  Scan Frequency.  Default 60 Seconds
##  The delay in seconds to wait between scanning
##  for new or improved signals.  This frequency
##  is only used when a signal has already been established.
##  When no connection is active, it is not used.
aap_scanfreq="60"
[ -n "$(nvram get autoap_scanfreq)" ] && aap_scanfreq="$(nvram get autoap_scanfreq)";

############### MAC/BSSID Ignore List ###################################
## You can permanently store this setting in nvram, as a space          #
## seperated list of MAC address you don't wish to connect with.        #
## nvram set autoap_macfilter="00:11:22:33:44:55 AA:BB:CC:DD:EE:FF etc" #
##   -see SSID ignore below.                                            #
#########################################################################
[ -n "$(nvram get autoap_macfilter)" ] && aap_ignmacs="$(nvram get autoap_macfilter)";

############### SSID Ignore List ##########################################
## Like the MAC filter, this is a space separated list stored in nvram,   # 
## and will prevent autoap from connecting to any SSID you designate.     #
## nvram set autoap_ssidfilter="ssid1 ssid2 etc"                          # 
##                                                                        #
###########################################################################
[ -n "$(nvram get autoap_ssidfilter)" ] && aap_ignssid="$(nvram get autoap_ssidfilter)";

######  Maximum number of lines of the logfile. Default 1000
##  nvram set autoap_logsize="1000"
##
aap_logsize="1000"
[ -n "$(nvram get autoap_logsize)" ] && aap_logsize="$(nvram get autoap_logsize)";

########## Misc. Utilities #############
## A number of utility functions needed
## by scanman, amongst others.

## Clear all query and scanner vars simultaneously and reset scan status.

case "$aap_logger" in
		'syslog')
			lc1="logger -p local7."
			lc2=" -t autoap "
			errredir="/dev/null"
		;;
		'html')
			lc1="logger -s -p"
			lc2=" -t autoap "
			errredir="/tmp/autoap.log"
			touch $errredir
			ln -s $errredir /tmp/www/autoap.htm
			echo "<html><head><title>AutoAP Log Data</title></head><body><h2>AutoAP Log Begin:</h2>" > $errredir 2>/dev/null
		;;
		*)
			lc1="logger -s -p local7."
			lc2=" -t autoap "
			errredir="$aap_logger"
			touch $errredir
			echo "<pre>" > $aap_logger 2>/dev/null
		;;
esac
		
aaplog ()
{
	[ $# -gt 0 ] && p1="$1 " && shift;
	ts=` /bin/date "+%Y-%m-%d %H:%M:%S "`
	lcmd="${lc1}$p1${lc2}${ts}$* ";
	[ "$aap_logger" = "html" ] && lcmd="${lc1}$p1${lc2}${ts}$* <br />";
	runc=$($lcmd) 2>>$errredir
}

wlReset ()
{
	aaplog 7 wlReset - Completely resetting scanner. 
	firstRun=1
	rm -f /tmp/aap.result 2>/dev/null
	rm -f $aaptmpdir/* 2>/dev/null
}

aaping ()
{
	pcmd=`ping -c 5 $1 | grep from | wc -l | awk '{ print \$1 }'`
	if [ ! $pcmd -gt 1 ]; then
		aaplog 3 aaping - Failed to ping $1.
	  echo "0"
	else
		aaplog 3 aaping - Recieved ping reply from $1.
		echo "1"
	fi
}

aajoin ()
{
if [ -n "$2" ]; then 
  wl join "$1" key "$2"
else
  wl join "$1"
fi
sleep 1
kill -USR2 `cat /tmp/var/run/udhcpc.pid`  2> /dev/null
killall udhcpc 2> /dev/null
udhcpc  -i eth1 -p /tmp/var/run/udhcpc.pid -s /tmp/udhcpc 2> /dev/null 
cur_ssid=$(wl assoc|head -n1|sed s/^.*:.\"//|sed s/\"$//)
}

################### Start AutoAP ###########################
##  Scanners, parsers, etc   
##	                        

firstRun=1
current_ap=1
wl_mode=`wl ap | awk '{ print \$3 }'`
wl_if=`nvram get wl0_ifname`
tPref=""
wl wsec 0 2>/dev/null

aaplog 6 $authstring
if [ "$aap_findwep" = "1" ]; then
	if [ "$aap_wepkeys" = "" ]; then
		aaplog 4 WEP keys not provided.  Switching to open only mode.
		aap_findwep=0
		aap_findopen=1
	fi
fi
if [ "$wl_mode" = "1" ]; then
	aaplog 3 FATAL - Router is in AP mode.  Exiting.
	exit 0
fi

## Initialize scans
aap_init_scan ()
{
	wl scan > /dev/null 2>&1 && wl scanresults > /tmp/aap.result
	if [ "$ap_good" = "1" ]; then
		ap_good=0
	  aaplog 6 init_scan - Sleeping for ${aap_scanfreq} seconds.
	  sleep $aap_scanfreq
	  aap_checkjoin "$tPref"
	else
		if [ "$firstRun" = "1" ] || [ -z $(nvram get wan_gateway) ]; then
			if [ $(cat /tmp/aap.result | wc -l) -gt 2 ]; then
				current_ap=1
				aaplog 5 init_scan - Retrieved new scan data.
				firstRun=0
				aap_scanman
			else
				aaplog 5 init_scan - Scan failed.  Retrying initial scan.
				sleep 3
			fi
		else
			cur_wip=$(ifconfig `nvram get wl0_ifname`|awk 'NR==2{print $2}'|sed s!addr:!!)
			sleep 1
			if [ "$cur_wip" = "0.0.0.0" ]; then
				aaplog 4 init_scan - WAN IP address invalid.
				if [ "$(nvram get wan_proto)" = "static" ]; then #todo: this may go into header
					aaplog 4 init_scan - Router is not in DHCP mode.  Setting DHCP mode.
					nvram set wan_proto="dhcp"
					nvram commit
					kill -SIGTERM `cat /tmp/var/run/udhcpc.pid`
					rm -f /tmp/*.expires
					ln -sf /sbin/rc /tmp/udhcpc
					sleep 1
					udhcpc -i eth1 -p /var/run/udhcpc.pid -s /tmp/udhcpc -H $(nvram get wan_hostname) > /dev/null 2>&1
					sleep 1
				fi
				if [ -s /tmp/var/run/udhcpc.pid ]; then
				  aaplog 4 init_scan - DHCP client successfully started for WAN device.
			    aap_checkjoin "$tPref"
			    aaplog 7 init_scan - Awake.  Checking connection via init_scan.
        else
          aaplog 2 init_scan - Could not start dhcp client.  Reinitializing.
        fi
      else
			  aap_checkjoin "$tPref"
			  aaplog 7 init_scan - Awake.  Checking connection via init_scan.
	    fi
    fi
	fi	
}

## Scanman performs all of the parsing and filter
## logic, if the filter lists are configured. 
aap_scanman ()
{
	while read scanLine; do
		lineID=$(expr substr "$scanLine" 1 4)
		case "$lineID" in
				'SSID')
						cSSID=$(echo "$scanLine" | tr -d '"' | sed s!SSID:.!!)
						for i in $aap_ignssid; do
							[ "$cSSID" = "$i" ] && net_type="ignore"
						done 
				;;
				'Mode')
						cRSSI=`echo $scanLine | awk '{ print \$4 }'`
						cNOISE=`echo $scanLine | awk '{ print \$7 }'`
						cCHAN=`echo $scanLine | awk '{ print \$10 }'`
						cSNR=$(( $cRSSI - $cNOISE ))
				;;
				'BSSI')
						cBSSID=`echo $scanLine | awk '{ print \$2 }'`
							for j in $aap_ignmacs; do 
								if [ "$cBSSID" = "$j" ] || [ $net_type = "ignore" ]; then 
									aaplog 4 scanman - Ignoring SSID $cSSID with remote BSSID $cBSSID per user request.
                  net_type="open"
                  continue 2 
								fi; done; 
						cMODES=$(echo "$scanLine" | sed s!BSSID.*bility..!!)
            net_type="open"
						for k in $cMODES; do
						  if [ "$k" = "WPA" ]; then
								net_type="wpa"
								aaplog 5 scanman - Skipping WPA protected network $cSSID.  
              fi 
							[ "$k" = "WEP" ] && net_type="wep";
            done
						if [ $cSNR -gt 2 ]; then
							[ $cSNR -lt 10 ] && cSNR="0${cSNR}";
							if [ "$aap_findwep" = "1" ] && [ "$net_type" = "wep" ]; then
								echo "$cSNR $cSSID $cBSSID $cCHAN" | sed s!^\(.-\)!0\1! > $aaptmpdir/${cSNR}wep-$cSSID
								aaplog 2 scanman - Found WEP network ${cSSID}. \(BSSID\: ${cBSSID},  Signal\: ${cSNR}dB\) 
							elif [ "$aap_findopen" = "1" ] && [ "$net_type" = "open" ]; then
								echo "$cSNR $cSSID $cBSSID $cCHAN" | sed s!^\(.-\)!0\1! > $aaptmpdir/${cSNR}${cSSID}
								aaplog 2 scanman - Found open network $cSSID. \(BSSID\: ${cBSSID},  Signal\: ${cSNR}dB\)
							else
								aaplog 2 scanman - Skipping $net_type network $cSSID. \(BSSID\: ${cBSSID},  Signal\: ${cSNR}dB\)
							fi
            fi
				;;
		esac
	done < /tmp/aap.result
	ap_dir_limit="$(ls -1 $aaptmpdir | wc -l)"
	aap_joinpref
}

## joinpref handles associating with an AP, 
## verifying the connection is decent, and cleaning
## up the connection when a new AP is found. 
aap_joinpref ()
{
  while [ $current_ap -le $aap_aplimit ] && [ $current_ap -le $ap_dir_limit ]; do
    wl disassoc > /dev/null 2>&1
    tPref=$(ls -1 $aaptmpdir | grep -v log | sort -r | head -n$((${current_ap})) | tail -n1 | sed 's!^..!!')
    twPref=`echo "$tPref" | sed 's/^wep-//'`
    if [ "$tPref" != "$twPref"  ]; then
      wepnet=1
      tPref="$twPref"
    else
      wepnet=0
    fi
    aaplog 4 joinpref - Moving to network $current_ap \($tPref\). 
    current_ap=$(($current_ap + 1))
    nvram set wl0_ssid=""
    nvram set wl_ssid=""
    nvram set wan_ipaddr="0.0.0.0"
    nvram set wan_netmask="0.0.0.0"
    nvram set wan_gateway="0.0.0.0"
    nvram set wan_get_dns=""
    nvram set wan_lease="0"
    rm /tmp/get_lease_time
    rm /tmp/lease_time
		if [ "$wepnet" = "1" ]; then
				wl wsec 1 2>/dev/null
      for wlkey in $aap_wepkeys; do
				aaplog 4 joinpref - Trying to join ${tPref}.  Using WEP key $wlkey 
			  aajoin "$tPref"  $wlkey 
        if [ "$tPref" = "$cur_ssid" ]; then
			    aajoin "$tPref"  $wlkey 
          [ "$tPref" = "$cur_ssid" ] && break # found good key
        fi
      done
      if [ "$tPref" != "$cur_ssid" ]; then
		    aaplog 5 joinpref - no matching key, moving to next network 
        continue 
      else
		    aaplog 5 joinpref - found matching key, connecting ... 
      fi
		fi
		if [ "$wepnet" = "0" ]; then
			wl wsec 0 2>/dev/null
			aajoin "$tPref"
    fi
    aap_checkjoin "$tPref"
  done
  aaplog 4 joinpref - End of available APs.  Sleeping 15
  sleep 15
	rm -f $aaptmpdir/* 2>/dev/null
	firstRun=1
	current_ap=1
}

## checkjoin contains logic to verify the connection to the correct AP
## and the assignment of a valid DHCP address. checkjoin will make two 
## attempts before courting a new AP.
aap_checkjoin ()
{
    req_ssid="$1"
		wlip=`ip route | awk '/default via/ {print $3}'`
		if [ ! "$req_ssid" = "$cur_ssid" ] || [ $wlip = "0.0.0.0" ] ; then # see if join worked otherwise retry twice
	    aaplog 3 checkjoin - Currently connected to "$cur_ssid", attempting to join "$req_ssid".
			aajoin "$req_ssid"
		  wlip=`ip route | awk '/default via/ {print $3}'`
		  if [ ! "$req_ssid" = "$cur_ssid" ] || [ $wlip = "0.0.0.0" ] ; then
	      aaplog 3 checkjoin - Attempting again to join ${req_ssid}.
			  aajoin "$req_ssid"
      fi
    fi
		if [ "$req_ssid" = "$cur_ssid" ] ; then 
      ap_good=$(aap_inet_chk)
    fi
    while [ "$ap_good" = "1" ]; do # looping here until connection is lost
      aaplog 3 checkjoin - Connection to ${cur_ssid} with GW ${wlip} confirmed. Sleeping ${aap_scanfreq} seconds.
      sleep $aap_scanfreq
      ap_good=$(aap_inet_chk)
	    if [ -n "$errredir" ] && [ $(cat $errredir | wc -l)  -gt $aap_logsize ]; then
        cp $errredir /tmp/tmplog
        `echo head -n2 /tmp/tmplog` > $errredir 
        tail -$(($aap_logsize *3/4)) "/tmp/tmplog" >> $errredir
        rm "/tmp/tmplog"
      fi
    done
	  aaplog 3 checkjoin - Connection to ${cur_ssid} failed. Trying next AP.
}

## aap_inet_chk checks for internet connectivity if aap_watch_inet is enabled,
## otherwise ping the gateway. Returns "true" on success and "false" otherwise.
aap_inet_chk ()
{
	if [ "$aap_watch_inet" = "1" ]; then
		aaplog 5 inet_check - Checking internet connection  \($aap_chk_url\)
		icret=$(aaping $aap_chk_url) ;
		sleep 1
		[ "$icret" = "0" ] && icret=$(aaping $aap_chk_url) ;
		sleep 1
		[ "$icret" = "0" ] && icret=$(aaping $aap_chk_url) ;
	else
    aaplog 4 inet_check - Skipping internet check per user request, pinging gateway instead.
		icret=$(aaping `nvram get wan_gateway`) ;
		sleep 1
		[ "$icret" = "0" ] && icret=$(aaping `nvram get wan_gateway`) ;
		sleep 1
		[ "$icret" = "0" ] && icret=$(aaping `nvram get wan_gateway`) ;
  fi
  if [ "$icret" = "1" ]; then
	   echo "1" # connection valid
  else
	  echo "0" # no connection
	fi
}

until [ 2 = 1 ]; do
	aap_init_scan
done

