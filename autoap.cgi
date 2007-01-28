#!/bin/sh
echo "<html><head><title>Saving AutoAP configuration...</title>"
echo "<script>setTimeout('location.href=\"http://`nvram get lan_ipaddr`/Wireless_AutoAP.asp\"',7000)</script></head><body>"
read QUERY_STRING
tqs=`echo $QUERY_STRING | tr '&' ' '`
for x in $tqs; do
        vname=`echo "$x" | tr '=' ' ' | awk '{ print \$1 }'`
        vdata=`echo "$x" | tr '=' ' ' | awk '{ print \$2 }'`
        case "$vname" in
                        'wl_aap_freq')
                                if [ "$vdata" -gt "0" ] && [ "$vdata" -lt "1000" ]; then
                                        vname="autoap_scanfreq";
					echo "<div>Saving Scan Frequency</div><br/>";
	                        else
                                        echo "<div sytle='color:red'>Scan frequency must be between 1 and 1000. Skipping.</div><br/>";
                                fi
                        ;;
                        'wl_aap_enab')
                                if [ "$vdata" = "1" ]; then
					aastat=`ps | grep autoap | grep -v grep | wc -l`;
					startstp=`nvram get rc_startup | grep -v autoap`;
					echo "$startstp" > /tmp/aapstart;
					echo "/bin/autoap" >> /tmp/aapstart;
					vname="rc_startup";
                                        vdata=`cat /tmp/aapstart`; 
					echo "<div>Enabling AutoAP</div><br/>";
					[ "$aastat" -lt "1" ] && /bin/sh autoap;
					echo "<div>Started AutoAP</div><br/>";
	                        else
					nvram set "rc_startup"=`nvram get rc_startup | grep -v autoap`;
                                        echo "<div>Disabled AutoAP</div><br/>";
					killall -9 autoap;
					echo "<div>Stopped AutoAP Processes</div><br/>";
                                fi
                        ;;
                        'wl_aap_ap')
                                if [ "$vdata" -gt "0" ] && [ "$vdata" -lt "20" ]; then
                                        vname="autoap_aplimit";
					echo "<div>Saving AP Limit</div><br/>";
                                else
                                        echo "<div sytle='color:red'>AP Limit must be between 1 and 20. Skipping.</div><br/>";
                                fi
                        ;;
                        'wl_aap_dwait')
                                if [ "$vdata" -gt "0" ] && [ "$vdata" -lt "60" ]; then
                                        vname="autoap_dhcpw";
                			echo "<div>Saving DHCP Wait</div><br/>";
		                else
                                        echo "<div sytle='color:red'>DHCP wait time must be between 1 and 60. Skipping.</div><br/>";
                                fi
                        ;;
                        'wl_aap_ineturl')
                                vname="autoap_ineturl";
				echo "<div>Saving URL</div><br/>";
                        ;;
                        'wl_aap_mac1')
                                vname="autoap_mac1";
				echo "<div>Saving MAC Filters</div><br/>";
                        ;;
                        'wl_aap_mac2')
                                vname="autoap_mac2";
                        ;;
                        'wl_aap_mac3')
                                vname="autoap_mac3";
                        ;;
                        'wl_aap_ssid1')
                                vname="autoap_ssid1";
				echo "<div>Saving SSID Filters</div><br/>";
                        ;;
                        'wl_aap_ssid2')
                                vname="autoap_ssid2";
                        ;;
                        'wl_aap_ssid3')
                                vname="autoap_ssid3";
                        ;;
                        'wl_aap_wep1')
                                vname="autoap_wep1";
				echo "<div>Saving WEP Keys</div><br/>";
                        ;;
                        'wl_aap_wep2')
                                vname="autoap_wep2";
                        ;;
                        'wl_aap_wep3')
                                vname="autoap_wep3";
                        ;;
                        'wl_aap_findo')
                                vname="autoap_findopen";
				echo "<div>Saving Open Pref</div><br/>";
                        ;;
                        'wl_aap_findw')
                                vname="autoap_findwep";
				echo "<div>Saving WEP Pref</div><br/>";
                        ;;
                        'wl_aap_inetck')
                                vname="autoap_inet";
				echo "<div>Saving Inet Pref</div><br/>";
                        ;;
                        'wl_aap_logger')
				vname="autoap_logger";
				echo "<div>Saving Logger</div><br/>";
                        ;;
        esac
	nvram set "${vname}"="${vdata}";
done
nvcomm=`nvram commit`
echo "</body></html>"

