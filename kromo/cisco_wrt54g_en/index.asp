<% do_pagehead(); %>
		<title><% nvram_get("router_name"); %> - Setup</title>
		<script type="text/javascript">
		//<![CDATA[

document.title = "<% nvram_get("router_name"); %>" + idx.titl;

var wan_proto = "<% nvram_get("wan_proto"); %>";
var dhcp_win = null;

function pptpUseDHCP(F, val) {
	setElementsActive("wan_ipaddr_0", "wan_netmask_3", val==0)
}

function valid_mtu(I) {
	var start = null;
	var end = null;
	if(wan_proto == "pppoe") {
		start = 576;
		end = 1492;
	} else if (wan_proto == "pptp" || wan_proto == "l2tp") {
		start = 1200;
        end = 1400;
	} else {
		start = 576;
		end = 1500;
	}

	valid_range(I,start,end,"MTU");
}

function SelMTU(num,F) {
	mtu_enable_disable(F,num);
}

function mtu_enable_disable(F,I) {
	if ( I == "0" )
		choose_disable(F.wan_mtu);
	else
		choose_enable(F.wan_mtu);
}

function valid_value(F) {
	if (!('<% nvram_get("wl0_mode"); %>' == 'wet') && !('<% nvram_get("wl0_mode"); %>' == 'apstawet')) {
		if (F.now_proto.value == "pptp" || F.now_proto.value == "static") {
			pptp_dhcp = "";
	
			// Sveasoft: allow 0.0.0.0 for pptp. We'll let DHCP take care of it.
			if (F.now_proto.value == "pptp" &&
					F.wan_ipaddr_0.value == "0" &&
					F.wan_ipaddr_1.value == "0" &&
					F.wan_ipaddr_2.value == "0" &&
					F.wan_ipaddr_3.value == "0")
						pptp_dhcp = "skip";
			
			if (!F.pptp_use_dhcp || F.pptp_use_dhcp.value == "0") {
				if(pptp_dhcp != "skip" && !valid_ip(F,"F.wan_ipaddr","IP",ZERO_NO|MASK_NO))
					return false;
	
				if(pptp_dhcp != "skip" && !valid_mask(F,"F.wan_netmask",ZERO_NO|BCST_NO))
					return false;
			}
	
			if(F.now_proto.value == "static") {
				if(!valid_ip(F,"F.wan_gateway","Gateway",ZERO_NO|MASK_NO))
					return false;
			}
	
			if(pptp_dhcp != "skip" && F.now_proto.value == "pptp") {
				if (F.pptp_use_dhcp.value == "0") {
					if(!valid_ip(F,"F.pptp_server_ip","Gateway",ZERO_NO|MASK_NO))
						return false;
					
					if(!valid_ip_gw(F,"F.wan_ipaddr","F.wan_netmask","F.pptp_server_ip"))
						return false;
				}
			}
		}
	}
	
	if(F.now_proto.value == "pppoe" || F.now_proto.value == "pptp" || F.now_proto.value == "l2tp") {
		if(F.ppp_username.value == "") {
			alert(errmsg.err0);
			F.ppp_username.focus();
			return false;
		}
	}
	
	if(!<% nvram_else_selmatch("dhcpfwd_enable", "1", "1", "0"); %>) {
		if(!valid_dhcp_server(F))
			return false;
	}

	if(F.router_name)
		if(F.router_name.value == "") {
			alert(errmsg.err1);
			F.router_name.focus();
			return false;
		}
	if(document.setup)
		if(document.setup.now_proto)
			if(document.setup.now_proto.value == "pptp")
				pptpUseDHCP(document.setup, '<% nvram_get("pptp_use_dhcp"); %>');

	return true;
}

function valid_dhcp_server(F) {
	if(F.lan_proto == null)
		return true;
	if (F.lan_proto.selectedIndex == 0)
		return true;

	a1 = parseInt(F.dhcp_start.value,10);
	a2 = parseInt(F.dhcp_num.value,10);
	if (a1 + a2 > 255) {
		alert(errmsg.err2);
		return false;
	}

	if (F.wan_dns0 != null)
		if (!valid_ip(F,"F.wan_dns0","DNS",MASK_NO))
			return false;
	
	if (F.wan_dns1 != null)
		if (!valid_ip(F,"F.wan_dns1","DNS",MASK_NO))
			return false;
	
	if (F.wan_dns2 != null)
		if (!valid_ip(F,"F.wan_dns2","DNS",MASK_NO))
			return false;
	
	if (F.wan_wins != null)
		if (!valid_ip(F,"F.wan_wins","WINS",MASK_NO))
			return false;

	return true;
}

function SelDHCP(T,F) {
	dhcp_enable_disable(F,T);
}

function dhcp_enable_disable(F,T) {
	var start = '';
	var end = '';
 	var total = F.elements.length;
	for(i=0 ; i < total ; i++) {
		if(F.elements[i].name == "dhcp_start")
			start = i;
		if(F.elements[i].name == "wan_wins_3")
			end = i;
	}
	if(start == '' || end == '')
		return true;

	if( T == "static" ) {
		for(i = start; i<=end ;i++) {
			choose_disable(F.elements[i]);
		}
	} else {
		for(i = start; i<=end ;i++) {
			choose_enable(F.elements[i]);
		}
	}
}

function ppp_enable_disable(F,I) {
	if( I == "0") {
		choose_disable(F.ppp_idletime);
		choose_enable(F.ppp_redialperiod);
	} else {
		choose_enable(F.ppp_idletime);
		choose_disable(F.ppp_redialperiod);
	}
}


function setDNSMasq(F) {
	if (document.setup._dhcp_dnsmasq) {
		if(F._dhcp_dnsmasq.checked == true) {
			setElementActive("_auth_dnsmasq", true);
		} else {
			F._auth_dnsmasq.checked=false;		
			setElementActive("_auth_dnsmasq", false);
		}
	}
}

function SelWAN(num,F) {
	F.submit_type.value = "wan_proto";
	F.wan_proto.value=F.wan_proto.options[num].value;
	F.submit();
}

function SelDHCPFWD(num,F) {
	F.submit_type.value = "dhcpfwd";
	F.dhcpfwd_enable.value = F.dhcpfwd_enable.options[num].value;
	F.submit();
}

function to_submit(F) {
	if(valid_value(F)) {
		if(F._daylight_time.checked == false)
			F.daylight_time.value = 0;
		else
			F.daylight_time.value = 1;

		if(F._dhcp_dnsmasq) {
			if(F._dhcp_dnsmasq.checked == false)
				F.dhcp_dnsmasq.value = 0;
			else
				F.dhcp_dnsmasq.value = 1;
		}

		if(F._dns_dnsmasq) {
			if(F._dns_dnsmasq.checked == false)
				F.dns_dnsmasq.value = 0;
			else
				F.dns_dnsmasq.value = 1;
		}

		if(F._auth_dnsmasq) {
			if(F._auth_dnsmasq.checked == false)
				F.auth_dnsmasq.value = 0;
			else
				F.auth_dnsmasq.value = 1;
		}
		
		if(F._fullswitch) {
			if(F._fullswitch.checked == false)
				F.fullswitch.value = 0;
			else
				F.fullswitch.value = 1;
		}
		
		F.submit_type.value = "";
		F.change_action.value = "";
		F.save_button.value = sbutton.saving;
		apply(F);
	}
}

function init() {
	mtu_enable_disable(document.setup,'<% nvram_get("mtu_enable"); %>');

	if (document.setup.now_proto.value == "pppoe" ||
		document.setup.now_proto.value == "pptp" ||
		document.setup.now_proto.value == "l2tp" ||
		document.setup.now_proto.value == "heartbeat")
			ppp_enable_disable(document.setup,'<% nvram_get("ppp_demand"); %>');

	dhcp_enable_disable(document.setup,'<% nvram_get("lan_proto"); %>');
	setDNSMasq(document.setup);
}

		//]]>
		</script>
	</head>

	<body class="gui" onload="init();">
	<% showad(); %>
		<div id="wrapper">
			<div id="content">
				<div id="header">
					<div id="logo"><h1><% show_control(); %></h1></div>
					<% do_menu("index.asp","index.asp"); %>
				</div>
				<div id="main">
					<div id="contents">
						<form name="setup" action="apply.cgi" method="<% get_http_method(); %>">
							<input type="hidden" name="submit_button" value="index" />
							<input type="hidden" name="action" value="Apply" />
							<input type="hidden" name="change_action" value="gozila_cgi" />
							<input type="hidden" name="submit_type" />
							
							<input type="hidden" name="now_proto" value="<% nvram_gozila_get("wan_proto"); %>" />
							<input type="hidden" name="dhcp_dnsmasq" value="0" />
							<input type="hidden" name="dns_dnsmasq" value="0" />
							<input type="hidden" name="auth_dnsmasq" value="0" />
							<input type="hidden" name="fullswitch" value="0" />
							<input type="hidden" name="daylight_time" value="0" />
							<input type="hidden" name="lan_ipaddr" value="4" />
							<h2><% nvram_else_match("wl_mode", "ap", "<script type="text/javascript">Capture(idx.h2);</script>", "<script type="text/javascript">Capture(idx.h22);</script>"); %></h2>

							<fieldset>
								<legend><% tran("idx.legend"); %></legend>

				<% nvram_match("wl0_mode", "ap", "<!--"); %>
				<% nvram_match("wl0_mode", "sta", "<!--"); %>
				<% nvram_match("wl0_mode", "infra", "<!--"); %>
				<% nvram_match("wl0_mode", "apsta", "<!--"); %>
				<% nvram_match("wl0_mode", "wdssta", "<!--"); %>
				<% nvram_match("wl0_mode", "wdsap", "<!--"); %>
								<div class="setting">
							    	<div class="label"><% tran("idx.conn_type"); %></div>
							    	<% tran("share.disabled"); %>
								</div>
				<% nvram_match("wl0_mode", "ap", "-->"); %>
				<% nvram_match("wl0_mode", "sta", "-->"); %>
				<% nvram_match("wl0_mode", "infra", "-->"); %>
				<% nvram_match("wl0_mode", "apsta", "-->"); %>
				<% nvram_match("wl0_mode", "wdssta", "-->"); %>	
				<% nvram_match("wl0_mode", "wdsap", "-->"); %>

				
				<% nvram_match("wl0_mode", "apstawet", "<!--"); %>
				<% nvram_match("wl0_mode", "wet", "<!--"); %>
								<div class="setting">
							    	<div class="label"><% tran("idx.conn_type"); %></div>
							    	<select name="wan_proto" onchange="SelWAN(this.form.wan_proto.selectedIndex,this.form)">
									<% show_connectiontype(); %>
									</select>
								</div>
								<% show_index_setting(); %>
				<% nvram_match("wl0_mode", "wet", "-->"); %>
				<% nvram_match("wl0_mode", "apstawet", "-->"); %>
				
								<div class="setting">
									<div class="label"><% tran("idx.stp"); %></div>
									<input class="spaceradio" type="radio" value="1" name="lan_stp" <% nvram_selmatch("lan_stp", "1", "checked"); %> /><% tran("share.enable"); %>&nbsp;
									<input class="spaceradio" type="radio" value="0" name="lan_stp" <% nvram_selmatch("lan_stp", "0", "checked"); %> /><% tran("share.disable"); %>
									<span class="default"><% tran("idx.stp_mess"); %></span>
								</div>
							</fieldset><br />
				
				<% nvram_match("wl0_mode", "wet", "<!--"); %>
				<% nvram_match("wl0_mode", "apstawet", "<!--"); %>
							<% portsetup(); %>
				<% nvram_match("wl0_mode", "wet", "-->"); %>
				<% nvram_match("wl0_mode", "apstawet", "-->"); %>
							
							<fieldset>
								<legend><% tran("idx.optional"); %></legend>
								<div class="setting">
									<div class="label"><% tran("share.routername"); %></div>
									<input maxlength="39" name="router_name" size="20" onblur="valid_name(this,&#34;Router%20Name&#34;)" value="<% nvram_get("router_name"); %>"/>
								</div>
			
				<% nvram_match("wl0_mode", "wet", "<!--"); %>
				<% nvram_match("wl0_mode", "apstawet", "<!--"); %>
								<div class="setting">
									<div class="label"><% tran("share.hostname"); %></div>
									<input maxlength="39" name="wan_hostname" size="20" onblur="valid_name(this,&#34;Host%20Name&#34;)" value="<% nvram_get("wan_hostname"); %>"/>
								</div>
								<div class="setting">
									<div class="label"><% tran("share.domainname"); %></div>
									<input maxlength="79" name="wan_domain" size="20" onblur="valid_name(this,&#34;Domain%20name&#34;,SPACE_NO)" value="<% nvram_get("wan_domain"); %>" />
								</div>
								<div class="setting">
									<div class="label"><% tran("idx.mtu"); %></div>
									<select name="mtu_enable" onchange="SelMTU(this.form.mtu_enable.selectedIndex,this.form)">
										<option value="0" <% nvram_selmatch("mtu_enable", "0", "selected"); %>>Auto</option>
										<script type="text/javascript">
										//<![CDATA[
										document.write("<option value=\"1\" <% nvram_selmatch("mtu_enable", "1", "selected"); %> >" + share.manual + "</option>");
										//]]>
										</script>
									</select>&nbsp;
									<input class="num" maxlength="4" onblur="valid_mtu(this)" size="5" name="wan_mtu" value="<% nvram_get("wan_mtu"); %>" />
								</div>
				<% nvram_match("wl0_mode", "wet", "-->"); %>
				<% nvram_match("wl0_mode", "apstawet", "-->"); %>
							</fieldset><br />
							
							<h2><% tran("idx.h23"); %></h2>
							<fieldset>
								<legend><% tran("idx.routerip"); %></legend>
								<div class="setting">
									<div class="label"><% tran("idx.lanip"); %></div>
									<input class="num" maxlength="3" size="3" onblur="valid_range(this,1,223,'IP')" name="lan_ipaddr_0" value="<% get_single_ip("lan_ipaddr","0"); %>"/>.<input class="num" maxlength="3" size="3" onblur="valid_range(this,0,255,'IP')" name="lan_ipaddr_1" value="<% get_single_ip("lan_ipaddr","1"); %>"/>.<input class="num" maxlength="3" size="3" onblur="valid_range(this,0,255,'IP')" name="lan_ipaddr_2" value="<% get_single_ip("lan_ipaddr","2"); %>"/>.<input class="num" maxlength="3" size="3" onblur="valid_range(this,1,254,'IP')" name="lan_ipaddr_3" value="<% get_single_ip("lan_ipaddr","3"); %>"/>
								</div>
								<div class="setting">
									<div class="label"><% tran("share.subnet"); %></div>
									<input type="hidden" name="lan_netmask" value="4" />
									<input class="num" maxlength="3" size="3" name="lan_netmask_0" onblur="valid_range(this,0,255,'Netmask')" value="<% get_single_ip("lan_netmask","0"); %>"/>.<input class="num" maxlength="3" size="3" name="lan_netmask_1" onblur="valid_range(this,0,255,'Netmask')" value="<% get_single_ip("lan_netmask","1"); %>"/>.<input class="num" maxlength="3" size="3" name="lan_netmask_2" onblur="valid_range(this,0,255,'Netmask')" value="<% get_single_ip("lan_netmask","2"); %>"/>.<input class="num" maxlength="3" size="3" name="lan_netmask_3" onblur="valid_range(this,0,255,'Netmask')" value="<% get_single_ip("lan_netmask","3"); %>"/>
								</div>
								<div class="setting">
									<div class="label"><% tran("share.gateway"); %></div>
									<input type="hidden" name="lan_gateway" value="4" />
									<input class="num" maxlength="3" size="3" name="lan_gateway_0" onblur="valid_range(this,0,255,share.gateway)" value="<% get_single_ip("lan_gateway","0"); %>"/>.<input class="num" maxlength="3" size="3" name="lan_gateway_1" onblur="valid_range(this,0,255,share.gateway)" value="<% get_single_ip("lan_gateway","1"); %>"/>.<input class="num" maxlength="3" size="3" name="lan_gateway_2" onblur="valid_range(this,0,255,share.gateway)" value="<% get_single_ip("lan_gateway","2"); %>"/>.<input class="num" maxlength="3" size="3" name="lan_gateway_3" onblur="valid_range(this,0,255,share.gateway)" value="<% get_single_ip("lan_gateway","3"); %>"/>
								</div>
								<div class="setting">
									<div class="label"><% tran("share.localdns"); %></div>
									<input type="hidden" name="sv_localdns" value="4" />
									<input class="num" maxlength="3" size="3" name="sv_localdns_0" onblur="valid_range(this,0,255,share.localdns)" value="<% get_single_ip("sv_localdns","0"); %>"/>.<input class="num" maxlength="3" size="3" name="sv_localdns_1" onblur="valid_range(this,0,255,share.localdns)" value="<% get_single_ip("sv_localdns","1"); %>"/>.<input class="num" maxlength="3" size="3" name="sv_localdns_2" onblur="valid_range(this,0,255,share.localdns)" value="<% get_single_ip("sv_localdns","2"); %>"/>.<input class="num" maxlength="3" size="3" name="sv_localdns_3" onblur="valid_range(this,0,254,share.localdns)" value="<% get_single_ip("sv_localdns","3"); %>"/>
								</div>
							</fieldset><br />
							
							<% show_wan_to_switch(); %>
							<% show_dhcpd_settings(); %>
							
							<fieldset>
								<legend><% tran("idx.legend3"); %></legend>
								<div class="setting">
									<div class="label"><% tran("idx.timeset"); %></div>
									<select name="time_zone">
										<% show_timeoptions(); %>
									</select>
								</div>
								<div class="setting">
									<div class="label"><% tran("idx.localtime"); %></div>
									<input class="spaceradio" type="checkbox" value="1" name="_daylight_time" <% nvram_checked("daylight_time", "1"); %> />
								</div>
							</fieldset><br />
							
							<div class="submitFooter">
								<script type="text/javascript">
	            	//<![CDATA[
	            	submitFooterButton(1,1);
	            	//]]>
	            	</script>
							</div>
						</form>
					</div>
				</div>
				<div id="helpContainer">
					<div id="help">
						<div><h2><% tran("share.help"); %></h2></div>
						<dl>
							<dt class="term"><% tran("idx.dhcp"); %>:</dt>
							<dd class="definition"><% tran("hidx.right2"); %></dd>
							<dt class="term"><% tran("share.hostname"); %>:</dt>
							<dd class="definition"><% tran("hidx.right4"); %></dd>
							<dt class="term"><% tran("share.domainname"); %>:</dt>
							<dd class="definition"><% tran("hidx.right6"); %></dd>
							<dt class="term"><% tran("idx.lanip"); %>:</dt>
							<dd class="definition"><% tran("hidx.right8"); %></dd>
							<dt class="term"><% tran("share.subnet"); %>:</dt>
							<dd class="definition"><% tran("hidx.right10"); %></dd>
							<dt class="term"><% tran("idx.dhcp_srv"); %>:</dt>
							<dd class="definition"><% tran("hidx.right12"); %></dd>
							<dt class="term"><% tran("idx.dhcp_start"); %>:</dt>
							<dd class="definition"><% tran("hidx.right14"); %></dd>
							<dt class="term"><% tran("idx.dhcp_maxusers"); %>:</dt>
							<dd class="definition"><% tran("hidx.right16"); %></dd>
							<dt class="term"><% tran("idx.legend3"); %>:</dt>
							<dd class="definition"><% tran("hidx.right18"); %></dd>
						</dl>
						<br/>
						<a href="javascript:openHelpWindow<% nvram_selmatch("dist_type","micro","Ext"); %>('HSetup.asp');"><% tran("share.more"); %></a>
					</div>
				</div>
				<div id="floatKiller"></div>
				<% do_statusinfo(); %>
			</div>
		</div>
	</body>
</html>