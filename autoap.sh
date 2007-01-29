#!/bin/sh
#########################################################################################
##                                                                                     ##
##  AutoAP, by JohnnyPrimus - lee@partners.biz - 01.29.2007                            ##
##  http://sourceforge.net/projects/autoap
##                                                                                     ##
##  autoap is a small addition for the already robust DD-WRT firmware that enables     ##
##  users to migrate through/over many different wireless hotspots with low impact     ##
##  to the users internet connectivity.  This is especially useful in broad, city      ##
##  scale areas with dense AP population.                                              ##
##                                                                                     ##
#########################################################################################

#   History:
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
#  2007-01-16
# - major overhaul aap_scanman and aap_joinpref
# - connection to wep-networks working now
# - you can have both wep and open search enabled separately or together
# - no need for the subdir autoap/wep anymore
# - dhcp is safer now
#
#  2007-01-28
# - add aap_logcurrsig.  invoking this function
#   with no arugments will log the current signal
#   strength of the active AP.
#
#  2007-01-29
# - some small tweaks for stability
#
#  2007-01-29
# - In an effort to both maintain compatibility with
# - the upcoming web interface (autoap.cgi and Wireless_AutoAP.asp)
# - I have reverted the functions to a previous revision.  This rev 
# - should be considered a stable branch of old code, as the functionality
# - here has never been publically released.
# - The secondary motive is to fix the problems with WEP, curr_ssid, and
# - joinpref that have become prevelant in the past few releases.
# - The detailed changelog is too long to fully list here, a code diff is available
# - via the SVN interface at sourceforge.


aaptmpdir="/tmp/autoap"
aapwmpdir="/tmp/autoap/wep"
rm -f $aaptmpdir/*
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
[ "$aap_findwep" = "1" ] && mkdir -p $aaptmpdir/wep;


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
if [ -n "$(nvram get autoap_wep1)" ]; then
	aap_wepkeys="$(nvram get autoap_wep1)";
	[ -n "$(nvram get autoap_wep2)" ] && aap_wepkeys="${aap_wepkeys} $(nvram get autoap_wep2)";
	[ -n "$(nvram get autoap_wep3)" ] && aap_wepkeys="${aap_wepkeys} $(nvram get autoap_wep3)";
fi

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
if [ -n "$(nvram get autoap_mac1)" ]; then
	aap_ignmacs="$(nvram get autoap_mac1)";
	[ "$(nvram get autoap_mac2)" ] && aap_ignmacs="${aap_ignmacs} $(nvram get autoap_mac2)"
	[ "$(nvram get autoap_mac3)" ] && aap_ignmacs="${aap_ignmacs} $(nvram get autoap_mac3)"
fi

############### SSID Ignore List ##########################################
## Like the MAC filter, this is a space seperated list stored in nvram,   # 
## and will prevent autoap from connecting to any SSID you designate.     #
## nvram set autoap_ssidfilter="AA:BB:CC:DD:EE:FF 00:11:22:33:44:55 etc"  # 
##                                                                        #
###########################################################################
if [ -n "$(nvram get autoap_ssid1)" ]; then
	aap_ignssid="$(nvram get autoap_ssid1)";
	[ "$(nvram get autoap_ssid2)" ] && aap_ignssid="${aap_ignssid} $(nvram get autoap_ssid2)"
	[ "$(nvram get autoap_ssid3)" ] && aap_ignssid="${aap_ignssid} $(nvram get autoap_ssid3)"
fi

############### SSID Prefer List ##########################################
## Like the MAC filter, this is a space seperated list stored in nvram,   # 
## and will prevent autoap from connecting to any SSID you designate.     #
## nvram set autoap_ssidfilter="AA:BB:CC:DD:EE:FF 00:11:22:33:44:55 etc"  # 
##                                                                        #
###########################################################################
if [ -n "$(nvram get autoap_pref_1)" ]; then
	aap_prefssid=""
else
	aap_prefssid="$(nvram get autoap_pref_1)"
	if [ "$(nvram get autoap_pref_2)" ]; then
	  aap_prefssid=$(aap_prefssid)"$(nvram get autoap_pref_2)"
	fi
fi

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
			log_parse="0"
			ln -s $errredir /tmp/www/autoap.htm
			echo "<html><head><title>AutoAP Log Data</title></head><body><h2>AutoAP Log Begin:</h2>" > $errredir 2>/dev/null
		;;
		*)
			lc1="logger -s -p local7."
			lc2=" -t autoap "
			errredir="$aap_logger"
			log_parse="0"
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

aap_logcurrsig ()
{
	wl rssi $(wl bssid); wl noise &&  sleep 2;
	cPRE=$(echo `wl rssi $(wl bssid);wl noise`)
	cSIG=`echo $cPRE|awk {'print \$1-\$2'}`
	aaplog 3 logsig - Current signal is ${cSIG}dB
}

wlVarDie ()
{
	aaplog 7 wlVarDie - Unsetting variables.
	unset cSSID cRSSI cNOISE cCHAN cSNR cBSSID cMODES 
	newwep=0
	wl wep 0 2>/dev/null
}

wlReset ()
{
	aaplog 7 wlReset - Completely resetting scanner. 
	wlVarDie
	firstRun=1
	inet_two=0
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


################### Start AutoAP ###########################
##  Scanners, parsers, etc   
##	                        

firstRun=1
inet_two=0
current_ap=1
wl_mode=`wl ap | awk '{ print \$3 }'`
wl_if=`nvram get wl0_ifname`
keynum=1
tPref=""

if [ "$aap_findwep" = "1" ]; then
	if [ "$aap_wepkeys" = "" ]; then
		aaplog 4 WEP keys not provided.  Switching to open only mode.
		aap_findwep=0
		aap_findopen=1
	else
		wl addwep 1 0000000000
		wl primary_key 1
	fi
fi

aaplog 6 AutoAP by JohnnyPrimus started. lee@partners.biz

if [ "$wl_mode" = "1" ]; then
	aaplog 3 FATAL - Router is in AP mode.  Exiting.
	exit 0
fi

## Initialize scans
aap_init_scan ()
{
	wl scan > /dev/null 2>&1 && wl scanresults > /tmp/aap.result
	[ "$inet_two" = "1" ] && aap_inet_chk;
	if [ "$ap_good" = "1" ]; then
		ap_good=0
		log_parse=$(( $log_parse + 1 ))
		aaplog 6 init_scan - Sleeping for ${aap_scanfreq}.
		if [ "$log_parse" = "2" ] && [ ! "$errredir" = "" ]; then
			echo `tail -1000 $errredir` > $errredir
			log_parse=0
		fi
		sleep $aap_scanfreq
		if [ "$aap_watch_inet" = "1" ]; then
			aaplog 6 init_scan - Woke up.  Verifying internet connection.
			aap_inet_chk
		else
			aaplog 6 init_scan - Woke up.  Verifying router connection.
			aap_chk_join $tPref
		fi
	else
		if [ "$firstRun" = "1" ] || [ ! -n $(nvram get wan_gateway) ]; then
			if [ $(cat /tmp/aap.result | wc -l) -gt 2 ]; then
				sleep 1
				current_ap=1
				aaplog 5 init_scan - Retrieved new scan data.
				firstRun=0
				aap_scanman
			else
				aaplog 5 init_scan - Scan failed.  Retrying initial scan.
				sleep 3
			fi
		else
			cur_wip=$(ifconfig `nvram get wl0_ifname`|awk 'NR==2{print \$2}'|sed s!addr:!!)
			sleep 1
			if [ "$cur_wip" = "0.0.0.0" ]; then
				aaplog 4 init_scan - WAN IP address invalid.
				if [ "$(nvram get wan_proto)" = "static" ]; then
					aaplog 4 init_scan - Router is not in DHCP mode.  Setting DHCP mode.
					nvram set wan_proto="dhcp"
					nvram commit
					kill -SIGTERM `cat /tmp/var/run/udhcpc.pid`
					rm -f /tmp/*.expires
					ln -sf /sbin/rc /tmp/udhcpc
					sleep 1
					udhcpc -i eth1 -p /var/run/udhcpc.pid -s /tmp/udhcpc -H $(nvram get wan_hostname) > /dev/null 2>&1
					sleep 1
					[ -s /tmp/var/run/udhcpc.pid ] || aaplog 2 init_scan - Could not start dhcp client.  Reinitializing. && aap_init_scan;
					aaplog 4 init_scan - DHCP client successfully started for WAN device.
				fi
				killall -SIGUSR1 udhcpc > /dev/null 2>&1
				aaplog 6 init_scan - Waiting $aap_dhcpw for DHCP response.
				sleep $aap_dhcpw
				[ "$cur_wip" = "0.0.0.0" ] && aaplog 4 init_scan - DHCP lease failed.  Seeking new AP. && wlVarDie && aap_scanman;
				aaplog 5 init_scan - DHCP lease renewed successfully.
			fi
			if [ "$aap_watch_inet" = "1" ]; then
				aaplog 5 init_scan - Currently connected to $(nvram get wan_gateway).  Checking for internet access.
				aap_inet_chk
			else
				aaplog 5 init_scan - Connected to $(nvram get wan_gateway).  No internet check requested, sleeping $aap_scanfreq seconds.
				sleep $aap_scanfreq
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
						if [ -n "$aap_ignssid" ]; then		
							for i in $aap_ignssid; do
								if [ "$cSSID" = "$i" ]; then
									aaplog 4 ssid_filter - Ignoring remote SSID  $cSSID  per user request. 
									wlVarDie
									fi; done; fi
				;;
				'Mode')
						cRSSI=`echo $scanLine | awk '{ print \$4 }'`
						cNOISE=`echo $scanLine | awk '{ print \$7 }'`
						cCHAN=`echo $scanLine | awk '{ print \$10 }'`
						cSNR=$(( $cRSSI - $cNOISE ))
				;;
				'BSSI')
						cBSSID=`echo $scanLine | awk '{ print \$2 }'`
							if [ -n "$aap_ignmacs" ]; then
								for j in $aap_ignmacs; do 
									if [ "$cBSSID" = "$j" ]; then 
										aaplog 4 bssid_filter - Ignoring remote BSSID $cBSSID per user request.
										wlVarDie
										fi; done; fi
						cMODES=$(echo "$scanLine" | sed s!BSSID.*bility..!!)
						for k in $cMODES; do
							if [ "$k" = "WEP" ] || [ "$k" = "WPA" ]; then 
								if [ "$k" = "WEP" ] && [ "$findwep" = "1" ]; then 
									newwep=1
									[ "$findopen" = "0" ] && aaplog 5 scanman - Currently in WEP only mode.  Skipping open network $cSSID.
								else
									aaplog 5 scanman - Skipping \($cMODES\) protected network $cSSID.  
									wlVarDie
									fi; fi; done
				;;
				*)
						if [ -n "$scanLine" ] && [ $cSNR -gt 3 ]; then
							[ $cSNR -lt 10 ] && cSNR="0${cSNR}";
							if [ "$aap_findwep" = "1" ] && [ "$newwep" = "1" ]; then
								echo "$cSNR $cSSID $cBSSID $cCHAN" | sed s!^\(.-\)!0\1! > $aaptmpdir/wep/$cSNR-$cSSID
								aaplog 2 scanman - Found WEP network ${cSSID}. \(BSSID\: ${cBSSID},  Signal\: ${cSNR}dB\) 
								aaplog Trying WEP keys.
							elif [ "$aap_findopen" = "1" ]; then
								echo "$cSNR $cSSID $cBSSID $cCHAN" | sed s!^\(.-\)!0\1! > $aaptmpdir/$cSNR-$cSSID
								aaplog 2 scanman - Found open network $cSSID. \(BSSID\: ${cBSSID},  Signal\: ${cSNR}dB\)
							else
								wlVarDie
								aaplog 7 scanman - No interesting networks found this pass. 
								fi;
						fi
				;;
		esac
	done < /tmp/aap.result
	ap_dir_limit="$(ls -1 $aaptmpdir | grep -v autoap.log | wc -l)"
	aap_joinpref
}

## joinpref handles associating with an AP, 
## verifying the connection is decent, and cleaning
## up the connection when a new AP is found. 
aap_joinpref ()
{
  if [ $current_ap -le $aap_aplimit ]; then
    aaplog 4 joinpref - Moving to network $current_ap. 
    tPref=$(ls -1 $aaptmpdir | grep -v log | sort -r | head -n${current_ap} | tail -n1 | sed s!^..-!!)
		if [ "$aap_prefssid" ]; then		
			for n in $aap_prefssid; do
				if [ "$n" = "$cSSID" ]; then
					aaplog 4 ssid_filter - Joining $cSSID per used request.
					tPref="$n"
		fi; done; fi
                current_ap=$(($current_ap + 1))
                aaplog 4 joinpref - Trying to join SSID ${tPref}.
                nvram set wl0_ssid=""
                nvram set wl_ssid=""
                nvram set wan_ipaddr="0.0.0.0"
                nvram set wan_netmask="0.0.0.0"
                nvram set wan_gateway="0.0.0.0"
                nvram set wan_get_dns=""
                nvram set wan_lease="0"
                rm /tmp/get_lease_time
                rm /tmp/lease_time
		if [ "$newwep" = "1" ]; then
			wlkey=`echo $aap_wepkeys | awk '{ print \$$keynum }'`
			if [ ! "$wlkey" = "" ]; then 
				wl rmwep 1
				wl addwep 1 $wlkey
				keynum=$(($keynum + 1))
				wl wep 1 2>/dev/null
				aaplog 4 joinpref - Trying to join ${tPref}.  Using WEP key $wlkey 
				sleep 1
			else
				keynum=0
				newwep=0
				aaplog 4 joinpref - No WEP keys left to try.  
			fi
		else	
			wl wep 0 2>/dev/null
		fi
		if [ "$keynum" = "0" ]; then
			keynum=1
			aaplog 4 joinpref - Unable authenticate to ${tPref}.  Moving on.
		else
			wl join $tPref > /dev/null 2>&1
			sleep 2
			aaplog 5 joinpref - Associated to ${tPref}, renewing DHCP lease. 
        	        killall -SIGUSR1 udhcpc > /dev/null 2>&1
			sleep $aap_dhcpw
                	aap_checkjoin $tPref
		fi
        else
                aaplog 4 joinpref - No available/responding APs.  Sleeping.
                sleep $aap_scanfreq
                aaplog 4 joinpref - Restarting scan. 
		wlReset
		current_ap=1
  fi
}

## checkjoin contains logic to verify an AP is connected, but also
## providing a usable connection.  checkjoin will make two attempts
## to find a stable connection before courting a new AP.
aap_checkjoin ()
{
		req_ssid=$1
		cur_ssid=$(wl assoc|head -n1|sed s/^.*:.\"//|sed s/\"$//)
		wlip=$(nvram get wan_gateway)
		if [ ! "$req_ssid" = "$cur_ssid" ] || [ "$wlip" = "0.0.0.0" ] ; then
				if [ "$2" = "1" ]; then
					aaplog 4 checkjoin - $req_ssid is not responding, trying a different AP.
					wlVarDie
					aap_joinpref
				elif [ "$wlip" = "0.0.0.0" ]; then
					aaplog 3 checkjoin - $req_ssid has a WAN address of 0.0.0.0, last attempt at dhcp renewal.
					killall -SIGUSR1 udhcpc > /dev/null 2>&1
					sleep 7
					wlip=$(nvram get wan_gateway)
					if [ "$wlip" = "0.0.0.0" ]; then
						aaplog 4 checkjoin - $req_ssid invalid. Proceeding.
						wlVarDie
						aap_joinpref
					else
						aaplog 4 checkjoin - DHCP renewal appears to have worked.  Passing control to inet_check.
						aap_inet_check
					fi
				else
					aaplog 3 checkjoin - Currently connected to ${cur_ssid}, attempting to join ${req_ssid}.
					aaplog 7 checkjoin - Retrying join.
					wl join $req_ssid > /dev/null 2>&1
					sleep 2
					aap_checkjoin $req_ssid 1
				fi
		else
				aaplog 5 checkjoin - Successfully associated with $req_ssid.  Attempting to ping gateway.
				if [ ! "wlip" = "0.0.0.0" ]; then
					gtping=$(aaping `nvram get wan_gateway`)
					if [ "$gtping" = "0" ]; then
							aaplog 3 checkjoin - Attempts to ping ${req_ssid} unsuccessful.  Retrying in 1 second. 
							gtping=$(aaping `nvram get wan_gateway`)
							[ "$gtping" = "1" ] && aaplog 3 checkjoin - Ping successful. && aap_inet_chk;
							aaplog 3 checkjoin - Failed to contact gateway.  Moving to another AP.
							wlVarDie
							aap_joinpref
					else
							aaplog 4 checkjoin - Successfully configured for gateway.
							aap_logcurrsig
							aap_inet_chk
					fi
				else
					aaplog 3 checkjoin - WAN IP is still invalid.
					if [ "$2" = "1" ]; then
						aaplog 4 checkjoin - $req_ssid invalid. Proceeding.
						wlVarDie
						aap_joinpref
					fi
				fi
		fi
}

## aap_inet_chk checks for internet connectivity
## and returns true or restarts scanning
aap_inet_chk ()
{
	if [ "$aap_watch_inet" = "1" ]; then
		icret=$(aaping $aap_chk_url)
		if [ "$icret" = "0" ]; then
			aaplog 5 inet_check - Failed first internet check, retry in 3 seconds.  \($aap_chk_url\)
			sleep 3
			icret=$(aaping $aap_chk_url)
			if [ "$icret" = "0" ]; then
				aaplog 2 inet_check Failed second internet check.  Seeking new AP.
				wlVarDie
				if [ $current_ap -ge $aap_aplimit ]; then
					aaplog 4 inet_check - Exceeded max AP limit.  Refreshing AP selections.
					wlReset
				fi
				aap_joinpref
			fi
		else
			aaplog 4 inet_check - Contacted ${aap_chk_url}, connection valid.
			aap_logcurrsig
			ap_good=1
		fi
	else
		aaplog 4 inet_check - Skipping internet check per user request.
		ap_good=1
	fi
}

until [ 2 = 1 ]; do
	aap_init_scan
done
