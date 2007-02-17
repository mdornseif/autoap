#!/bin/sh
#########################################################################################
##                                                                                     ##
##  AutoAP, by JohnnyPrimus, additional development by Mathilda and MarcJohnson        ##
##  http://sourceforge.net/projects/autoap                                             ##
##                                                                                     ##
##  autoap is a small addition for the already robust DD-WRT firmware that enables     ##
##  users to migrate through/over many different wireless hotspots with low impact     ##
##  to the users internet connectivity.  This is especially useful in broad, city      ##
##  scale areas with dense AP population.                                              ##
##                                                                                     ##
##  Terms and Conditions:                                                              ##
##                                                                                     ##
##  AutoAP is released under the GNU Public License, and is subject to all conditions  ##
##  of the latest version.  The full version of the license can be viewed within the   ##
##  filed named LICENSE, or by visiting http://www.gnu.org/licenses/gpl.txt            ##
##                                                                                     ##
#########################################################################################
authstring="AutoAP, by JohnnyPrimus - lee@partners.biz - 2007-02-17 10:54 GMT"
authstring2="Additional development by Mathilda and MarcJohnson"

# Latest changes:
#
# 2007-02-17
# - autoap_findwep now enabled by default (no penalty any more if wepkeys is empty)
# - oups, there was a glitch that slowed wep-connection down for some cases
# - dynamical reload of nvram variables and new scan every 2 hours
# - new nvram variable that permits immediate rescanning / refreshing of variables

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


aap_findopen="1"
aap_findwep="1"
aap_logger="html"
aap_wepkeys=""
aap_watch_inet="1";
aap_aplimit="15"
aap_chk_url="www.google.com";
aap_dhcpw="15"
aap_scanfreq="60"
aap_logsize="1000"
aap_prefonly="0"

aap_varupdate ()
{
aaplog 3 aap_varupdate - rereading nvram variables.
aap_refreshdelay="120"
nvram set autoap_refreshnow=0

######  Search modes - WEP and Open.  Default is Open enabled and WEP disabled.
##  nvram set autoap_findopen="1"
##  nvram set autoap_findwep="1"
##
##  Note: If WEP is enabled you need to provide SSID/key combinations to connect with.
##  AutoAP will check if there is a key for the current SSID otherwise it moves on.
##  There is no penalty having autoap_findwep enabled when autoap_wepkeys is empty

[ -n "$(nvram get autoap_findopen)" ] && aap_findopen="$(nvram get autoap_findopen)";
[ -n "$(nvram get autoap_findwep)" ] && aap_findwep="$(nvram get autoap_findwep)";


######  Logging.  Default is log to html.
######  AutoAP can log to syslog, or to a file. Valid options are
##  syslog, filename and html.  If html is selected, the log is
##  available via web browser at http://routerip/user/autoap.htm

[ -n "$(nvram get autoap_logger)" ] && aap_logger="$(nvram get autoap_logger)";

######  WEP Keys
######  Space seperated list of wep keys to try
##  nvram set autoap_wepkeys="00134A3BF2 5B8CE1B462 AAA1234567" 
## to. Spaces are replaced by stars, a wep-key is attached with a separating "*key*"#
## spaces in the SSIDs have to be replaced by *s                                    #
## nvram set autoap_wepkeys="ssid1*with*spaces*key*123234234abba ssid2*key*12345ab" # 

[ -n "$(nvram get autoap_wepkeys)" ] && aap_wepkeys="$(nvram get autoap_wepkeys)";
if [ -n "$(nvram get autoap_wep1)" ]; then
 	aap_wepkeys="${aap_wepkeys} $(nvram get autoap_wep1)";
 	[ -n "$(nvram get autoap_wep2)" ] && aap_wepkeys="${aap_wepkeys} $(nvram get autoap_wep2)";
 	[ -n "$(nvram get autoap_wep3)" ] && aap_wepkeys="${aap_wepkeys} $(nvram get autoap_wep3)";
fi

######  Max APs to track at once. Default 10
##  nvram set autoap_aplimit="15"

[ -n "$(nvram get autoap_aplimit)" ] && aap_aplimit="$(nvram get autoap_aplimit)";

######  Internet check toggle.  Set to 1 to enable, 0 to disable.  Default enabled.
##  nvram set autoap_inet="1"

[ -n "$(nvram get autoap_inet)" ] && aap_watch_inet="$(nvram get autoap_inet)";

######  Internet check URL.  The URL or IP to ping to ensure internet access.
##  nvram set autoap_ineturl="www.partners.biz"

[ -n "$(nvram get autoap_ineturl)" ] && aap_chk_url="$(nvram get autoap_ineturl)";

######  Length of time to wait for a DHCP request to succeed.  Default 15
##  nvram set autoap_dhcpw="15"

[ -n "$(nvram get autoap_dhcpw)" ] && aap_dhcpw="$(nvram get autoap_dhcpw)";

######  Scan Frequency.  Default 60 Seconds
##  The delay in seconds to wait between scanning
##  for new or improved signals.  This frequency
##  is only used when a signal has already been established.
##  When no connection is active, it is not used.
[ -n "$(nvram get autoap_scanfreq)" ] && aap_scanfreq="$(nvram get autoap_scanfreq)";

############### MAC/BSSID Ignore List ###################################
## You can permanently store this setting in nvram, as a space          #
## seperated list of MAC address you don't wish to connect with.        #
## nvram set autoap_macfilter="00:11:22:33:44:55 AA:BB:CC:DD:EE:FF etc" #
##   -see SSID ignore below.                                            #
#########################################################################


if [ -n "$(nvram get autoap_macfilter)" ]; then
   aap_ignmacs="$(nvram get autoap_macfilter)";
 	[ -n "$(nvram get autoap_mac1)" ] && aap_ignmacs="${aap_ignmacs} $(nvram get autoap_mac1)"
 	[ -n "$(nvram get autoap_mac2)" ] && aap_ignmacs="${aap_ignmacs} $(nvram get autoap_mac2)"
 	[ -n "$(nvram get autoap_mac3)" ] && aap_ignmacs="${aap_ignmacs} $(nvram get autoap_mac3)"
 # for n in $aap_ignmacs; do
 #   wl mac "$n"
 # done
 # wl macmode 1
fi

############### SSID Ignore List ##########################################
## Like the MAC filter, this is a space separated list stored in nvram,   # 
## and will prevent autoap from connecting to any SSID you designate.     #
## spaces in the SSIDs have to be replaced by *s                          #
## nvram set autoap_ssidfilter="ssid1 ssid*with*spaces2 etc"              # 
##                                                                        #
###########################################################################
[ -n "$(nvram get autoap_ssidfilter)" ] && aap_ignssid="$(nvram get autoap_ssidfilter)";
 if [ -n "$(nvram get autoap_ssid1)" ]; then
 	aap_ignssid="${aap_ignssid} $(nvram get autoap_ssid1)";
 	[ -n "$(nvram get autoap_ssid2)" ] && aap_ignssid="${aap_ignssid} $(nvram get autoap_ssid2)"
 	[ -n "$(nvram get autoap_ssid3)" ] && aap_ignssid="${aap_ignssid} $(nvram get autoap_ssid3)"
fi

############### SSID Prefer List ##########################################
## Like the MAC filter, this is a space separated list stored in nvram,   # 
## but with adverse effects. These are the preferred networks to connect  #
## to. An eventual wep-key is attached with a separating "*key*"          #
## spaces in the SSIDs have to be replaced by *s                          #
## nvram set autoap_prefssid="ssid1*with*spaces ssid2_is_wep*key*12345ab" # 
##                                                                        #
###########################################################################
[ -n "$(nvram get autoap_prefssid)" ] && aap_prefssid="$(nvram get autoap_prefssid)";
if [ -n "$(nvram get autoap_pref_1)" ]; then
 	aap_prefssid="${aap_prefssid} $(nvram get autoap_pref_1)"
 	[ -n "$(nvram get autoap_pref_2)" ] && aap_prefssid="${aap_prefssid} $(nvram get autoap_pref_2)"
fi

######  Maximum number of lines of the logfile. Default 1000
##  nvram set autoap_logsize="1000"
[ -n "$(nvram get autoap_logsize)" ] && aap_logsize="$(nvram get autoap_logsize)";

###### True if only interested in preferred networks. Default false.
[ -n "$(nvram get autoap_prefonly)" ] && aap_prefonly="$(nvram get autoap_prefonly)";

###### True if only interested in preferred networks. Default false.
[ -n "$(nvram get autoap_refreshdelay)" ] && aap_refreshdelay="$(nvram get autoap_refreshdelay)";
nvram set autoap_refreshdelay=$aap_refreshdelay
}

########## Misc. Utilities #############
## A number of utility functions needed
## by scanman, amongst others.

aaplog ()
{
	[ $# -gt 0 ] && p1="$1 " && shift;
	ts=` /bin/date "+%Y-%m-%d %H:%M:%S "`
  if [ "$aap_logger" = "html" ]; then
    echo "${ts}$* <br>" >> $errredir;
  else
    lcmd="${lc1}$p1${lc2}${ts}\"$* \"";
	  $($lcmd) 2>>$errredir
  fi
}

aap_logcurrsig ()
{
	wl rssi $(wl bssid); wl noise &&  sleep 2;
	cPRE=$(echo `wl rssi $(wl bssid);wl noise`)
	cSIG=`echo $cPRE|awk {'print \$1-\$2'}`
  aaplog 3 logsig - Current signal is ${cSIG}dB
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

# try to join a network: aajoin <network> [wepkey]
aajoin ()
{
if [ -n "$2" ]; then 
  aaplog 3 aajoin - Trying to connect to ${1}, with wep key ${2}.
  wl join "$1" key "$2"
else
  aaplog 3 aajoin - Trying to connect to ${1}
  wl join "$1"
fi
sleep 2
#kill -USR1 `cat /tmp/var/run/udhcpc.pid` > /dev/null 2>&1 # this is not strong enough for recent builds.
kill -USR2 `cat /tmp/var/run/udhcpc.pid` > /dev/null 2>&1
killall udhcpc > /dev/null 2>&1
udhcpc  -i eth1 -p /tmp/var/run/udhcpc.pid -s /tmp/udhcpc > /dev/null 2>&1 &
sleep $aap_dhcpw
cur_ssid=$(wl ssid|sed s/^.*:.\"//|sed s/\"$//)
  #aaplog 3 aajoin - GW: $(ip route | awk '/default via/ {print $3}'), SSID: ${cur_ssid}

}

################### Start AutoAP ###########################
##  Scanners, parsers, etc   
##	                        

aap_varupdate # read nvram variables for the first time

firstRun=1
current_ap=1
wl_mode=`wl ap | awk '{ print \$3 }'`
wl_if=`nvram get wl0_ifname`
tPref=""
wl wsec 0 2>/dev/null

case "$aap_logger" in
		'syslog')
			lc1="logger -p local7."
			lc2=" -t autoap "
			errredir="/dev/null"
		;;
		'html')
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
		
aaplog 6 $authstring
aaplog 6 $authstring2
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

if [ "$(nvram get wan_proto)" = "static" ]; then
	aaplog 4 init_scan - Router is not in DHCP mode.  Setting DHCP mode.
	nvram set wan_proto="dhcp"
fi

## Initialize scans
aap_init_scan ()
{
    wl wsec 0 2>/dev/null
 	  wl scan -t passive > /dev/null 2>&1 && wl scanresults > /tmp/aap.result
	  if [ $(cat /tmp/aap.result | wc -l) -gt 2 ]; then
		  current_ap=1
		  aaplog 5 init_scan - Retrieved new scan data.
		  firstRun=0
		  aap_scanman
	  else
		  aaplog 5 init_scan - Scan failed.  Retrying initial scan.
		  sleep $aap_dhcpw
	  fi
}

## Scanman performs all of the parsing and filter
## logic, if the filter lists are configured. 
aap_scanman ()
{
  if [ -n "$aap_prefssid" ]; then	# check for preferred networks	
    wlkey=""
 		for n in $aap_prefssid; do
      cSSID="$(echo "$n" | sed "s/\(.*\)\*key\*.*/\1/" | sed 's/*/ /g')"
      wlkey="$(echo "$n" | grep \*key\* | sed "s/.*\*key\*\(.*\)/\1/")"
      is_there="$(cat /tmp/aap.result | grep "$cSSID" )"
      if [ -n "$is_there" ]; then # got the network detected at all?
   			aaplog 4 scanman - Trying to join preferred network $cSSID.
        nvram set wl0_ssid="$cSSID"
        nvram set wl_ssid="$cSSID"
        nvram set wan_gateway="0.0.0.0"
        wl wsec 0 2>/dev/null
		    aajoin "$cSSID" $wlkey
 			  aap_checkjoin "$cSSID" $wlkey
      else
 			  aaplog 4 scanman - Preferred network $cSSID is not online.
      fi
 		done
  fi
  if [ "$aap_prefonly" = "0" ]; then # do not scan if only looking for preferred networks
	 while read scanLine; do
		lineID=$(expr substr "$scanLine" 1 4)
		case "$lineID" in
				'SSID')
						cSSID=$(echo "$scanLine" | tr -d '"' | sed s!SSID:.!!)
						for i in $aap_ignssid; do
              i="$(echo "$i" | sed 's/*/ /g')"
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
							  [ "$cBSSID" = "$j" ] && net_type="ignore"
              done; 
							if [ $net_type = "ignore" ]; then 
								aaplog 4 scanman - Ignoring SSID $cSSID with remote BSSID $cBSSID per user request.
                net_type="open"
                continue
							fi;
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
								echo "$cSNR $cSSID $cBSSID $cCHAN" | sed s!^\(.-\)!0\1! > $aaptmpdir/${cSNR}aawep-$cSSID
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
   aaplog 4 scanman - End of available APs.  Sleeping $aap_dhcpw
   nvram set wl0_ssid=""
   nvram set wl_ssid=""
   sleep $aap_scanfreq
	 rm -f $aaptmpdir/* 2>/dev/null
	 firstRun=1
	 current_ap=1
  else
		aaplog 2 scanman - End of preferred networks. Sleeping $aap_scanfreq
    sleep $aap_scanfreq
  fi
}

## joinpref handles associating with an AP, 
## verifying the connection is decent, and cleaning
## up the connection when a new AP is found. 
aap_joinpref ()
{
  while [ $current_ap -le $aap_aplimit ] && [ $current_ap -le $ap_dir_limit ]; do
    tPref=$(ls -1 $aaptmpdir | grep -v log | sort -r | head -n$((${current_ap})) | tail -n1 | sed 's!^..!!')
    twPref=`echo "$tPref" | sed 's/^aawep-//'`
    if [ "$tPref" != "$twPref"  ]; then
      wepnet=1
      tPref="$twPref"
    else
      wepnet=0
    fi
    aaplog 4 joinpref - Moving to network $current_ap \($tPref\). 
    current_ap=$(($current_ap + 1))
    nvram set wan_ipaddr="0.0.0.0"
    nvram set wan_netmask="0.0.0.0"
    nvram set wan_gateway="0.0.0.0"
    nvram set wan_get_dns=""
    nvram set wan_lease="0"
    rm /tmp/get_lease_time
    rm /tmp/lease_time
    wlkey=""
		if [ "$wepnet" = "1" ]; then
 		for n in $aap_wepkeys; do
      cSSID="$(echo "$n" | sed "s/\(.*\)\*key\*.*/\1/" | sed 's/*/ /g')"
      wlkey="$(echo "$n" | grep \*key\* | sed "s/.*\*key\*\(.*\)/\1/")"
      if [ "$tPref" = "$cSSID" ]; then # do we have a key for this net?
        nvram set wl0_ssid="$tPref"
        nvram set wl_ssid="$tPref"
		    aaplog 5 joinpref - We have a key for ${cSSID}, connecting ... 
		    aajoin "$tPref" $wlkey
 			  aap_checkjoin "$cSSID" $wlkey
      fi
 		done
		fi
		if [ "$wepnet" = "0" ]; then
      nvram set wl0_ssid="$tPref"
      nvram set wl_ssid="$tPref"
      wl wsec 0 2>/dev/null
			aajoin "$tPref"
      aap_checkjoin "$tPref" $wlkey
    fi
  [ "$aap_refreshdelay" -lt 0 ] && aap_varupdate && return 1 ; # reread nvram variables
  done
}

## checkjoin contains logic to verify the connection to the correct AP
## and the assignment of a valid DHCP address. checkjoin will make two 
## attempts before courting a new AP.
aap_checkjoin ()
{
    req_ssid="$1"
    [ "$(nvram get autoap_refreshnow)" -eq 0 ] || $aap_refreshdelay=0 ;
    aap_refreshdelay=$(($aap_refreshdelay - 1))
    [ "$aap_refreshdelay" -lt 0 ] && return 1 ;
		wlip=$(nvram get wan_gateway)
		if [ ! "$req_ssid" = "$cur_ssid" ] || [ $wlip = "0.0.0.0" ] ; then # see if join worked otherwise retry twice
	    aaplog 3 checkjoin - Currently connected to "$cur_ssid", attempting to join "$req_ssid".
			aajoin "$req_ssid" $2
		  wlip=$(nvram get wan_gateway)
		  if [ ! "$req_ssid" = "$cur_ssid" ] || [ $wlip = "0.0.0.0" ] ; then
	      aaplog 3 checkjoin - Attempting again to join ${req_ssid}.
			  aajoin "$req_ssid" $2
      fi
    fi
		if [ "$req_ssid" = "$cur_ssid" ] ; then 
      ap_good=$(aap_inet_chk)
    fi
    while [ "$ap_good" = "1" ]; do # looping here until connection is lost
      aaplog 3 checkjoin - Connection to ${cur_ssid} with GW ${wlip} confirmed. Sleeping ${aap_scanfreq} seconds.
      sleep $aap_scanfreq
      ap_good=$(aap_inet_chk)
      cur_ssid=$(wl ssid|sed s/^.*:.\"//|sed s/\"$//)
	    if [ -n "$errredir" ] && [ $(cat $errredir | wc -l)  -gt $aap_logsize ]; then
        cp $errredir /tmp/tmplog
        `echo head -n3 /tmp/tmplog` > $errredir 
        tail -$(($aap_logsize *3/4)) "/tmp/tmplog" >> $errredir
        rm "/tmp/tmplog"
      fi
      [ "$(nvram get autoap_refreshnow)" -eq 0 ] || $aap_refreshdelay=0 ;
      aap_refreshdelay=$(($aap_refreshdelay - 1))
      [ "$aap_refreshdelay" -lt 0 ] && return 1 ;
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
