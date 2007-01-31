<% do_pagehead(); %>
		<title><% nvram_get("router_name"); %> - Routing</title>
		<script type="text/javascript">
		//<![CDATA[

document.title = "<% nvram_get("router_name"); %>" + route.titl;

function valid_value(F) {
	if(F.wk_mode.value != "ospf") {
		if(!valid_ip(F,"F.route_ipaddr","IP",0))
			return false;
		if(!valid_mask(F,"F.route_netmask",ZERO_OK))
			return false;
		if(!valid_ip(F,"F.route_gateway","Gateway",MASK_NO))
			return false;
	}
	return true;
}

function DeleteEntry(F) {
	if(!confirm(errmsg.err57)) return;
	F.submit_type.value = "del";
	apply(F);
}

function SelRoute(num,F) {
	F.route_page.value = F.route_page.options[num].value;
	F.submit();
}

function SelMode(num,F) {
	F.wk_mode.value = F.wk_mode.options[num].value;
	F.submit();
}

function to_submit(F) {
	if (F.routing_bgp_neighbor_ip != null) {
		F.routing_bgp_neighbor_ip.value = F.routing_bgp_neighbor_ip_0.value+'.'+F.routing_bgp_neighbor_ip_1.value+'.'+F.routing_bgp_neighbor_ip_2.value+'.'+F.routing_bgp_neighbor_ip_3.value;
	}
	
	if(!valid_value(F)) return;
	
	F.change_action.value = "";
	F.submit_type.value = "";
	F.save_button.value = sbutton.saving;
	apply(F);
}
		
		//]]>
		</script>
	</head>

	<body class="gui">
		<% showad(); %>
		<div id="wrapper">
			<div id="content">
				<div id="header">
					<div id="logo"><h1><% show_control(); %></h1></div>
					<% do_menu("index.asp","Routing.asp"); %>
				</div>
				<div id="main">
					<div id="contents">
						<form name="static" action="apply.cgi" method="<% get_http_method(); %>" >
							<input type="hidden" name="submit_button" value="Routing" />
							<input type="hidden" name="action" value="Apply" />
							<input type="hidden" name="change_action" value="gozila_cgi" />
							<input type="hidden" name="submit_type" />
							
							<input type="hidden" name="static_route" />
							<h2><% tran("route.h2"); %></h2>
							<fieldset>
								<legend><% tran("route.mod"); %></legend>
								<div class="setting">
									<div class="label"><% tran("route.mod"); %></div>
									<select name="wk_mode" onchange="SelMode(this.form.wk_mode.selectedIndex,this.form)">
										<% show_routing(); %>
									</select>
								</div>
							</fieldset><br />
							<% nvram_else_selmatch("wk_mode","bgp","","<!--"); %>
							
							<fieldset>
								<legend><% tran("route.bgp_legend"); %></legend>
								<div class="setting">
									<div class="label">BGP</div>
									<input size="10" name="routing_bgp_as" value="<% nvram_get("routing_bgp_as"); %>" />
								</div>
								<div class="setting">
									<div class="label"><% tran("route.bgp_ip"); %></div>
									<input type="hidden" name="routing_bgp_neighbor_ip" value="0.0.0.0" /><input size="3" maxlength="3" name="routing_bgp_neighbor_ip_0" onblur="valid_range(this,0,255,route.bgp_ip)" class="num" value="<% static_route_setting("routing_bgp_neighbor_ip","0"); %>" />.<input size="3" maxlength="3" name="routing_bgp_neighbor_ip_1" onblur="valid_range(this,0,255,route.bgp_ip)" class="num" value="<% static_route_setting("routing_bgp_neighbor_ip","1"); %>" />.<input size="3" maxlength="3" name="routing_bgp_neighbor_ip_2" onblur="valid_range(this,0,255,route.bgp_ip)" class="num" value="<% static_route_setting("routing_bgp_neighbor_ip","2"); %>" />.<input size="3" maxlength="3" name="routing_bgp_neighbor_ip_3" onblur="valid_range(this,0,254,route.bgp_ip)" class="num" value="<% static_route_setting("routing_bgp_neighbor_ip","3"); %>" />
								</div>
								<div class="setting">
									<div class="label"><% tran("route.bgp_as"); %></div>
									<input size="10" name="routing_bgp_neighbor_as" value="<% nvram_get("routing_bgp_neighbor_as"); %>" />
								</div>
							</fieldset><br/>							
							<% nvram_else_selmatch("wk_mode","bgp","","-->"); %>
							
							<% nvram_selmatch("wk_mode", "gateway", "<!--"); %>
							<fieldset>
								<legend><% tran("route.gateway_legend"); %></legend>
								<div class="setting">
									<div class="label"><% tran("share.intrface"); %></div>
									<select size="1" name="dr_setting">
										<script type="text/javascript">
										//<![CDATA[
										document.write("<option value=\"0\" <% nvram_selected("dr_setting", "0", "js"); %> >" + share.disable + "</option>");
										//]]>
										</script>
										<option value="1" <% nvram_selected("dr_setting", "1"); %> >WAN</option>
										<option value="2" <% nvram_selected("dr_setting", "2"); %> >LAN &amp; WLAN</option>
										<script type="text/javascript">
										//<![CDATA[
										document.write("<option value=\"3\" <% nvram_selected("dr_setting", "3", "js"); %> >" + share.both + "</option>");
										//]]>
										</script>
									</select>
								</div>
							 </fieldset><br/>
							 <% nvram_selmatch("wk_mode","gateway", "-->"); %>
							 
							 <fieldset>
								<legend><% tran("route.static_legend"); %></legend>
								<div class="setting">
									<div class="label"><% tran("route.static_setno"); %></div>
									<select size="1" name="route_page" onchange="SelRoute(this.form.route_page.selectedIndex,this.form)">
										<% static_route_table("select"); %>
									</select>&nbsp;&nbsp;
									<script type="text/javascript">
									//<![CDATA[
									document.write("<input class=\"button\" type=\"button\" name=\"del_button\" value=\"" + sbutton.del + "\" onclick=\"DeleteEntry(this.form);\" />");
									//]]>
									</script>
								</div>
								<div class="setting">
									<div class="label"><% tran("route.static_name"); %></div>
									<input name="route_name" size="25" maxlength="25" onblur="valid_name(this,route.static_name)" value="<% static_route_setting("name",""); %>" />
								</div>
								<div class="setting">
									<div class="label"><% tran("routetbl.th1"); %></div>
									<input type="hidden" name="route_ipaddr" value="4" />
									<input name="route_ipaddr_0" size="3" maxlength="3" onblur="valid_range(this,0,255,routetbl.th1)" class="num" value="<% static_route_setting("ipaddr","0"); %>" />.<input name="route_ipaddr_1" size="3" maxlength="3" onblur="valid_range(this,0,255,routetbl.th1)" class="num" value="<% static_route_setting("ipaddr","1"); %>" />.<input name="route_ipaddr_2" size="3" maxlength="3" onblur="valid_range(this,0,255,routetbl.th1)" class="num" value="<% static_route_setting("ipaddr","2"); %>" />.<input name="route_ipaddr_3" size="3" maxlength="3" onblur="valid_range(this,0,254,routetbl.th1)" class="num" value="<% static_route_setting("ipaddr","3"); %>" />
								</div>
								<div class="setting">
									<div class="label"><% tran("share.subnet"); %></div>
									<input type="hidden" name="route_netmask" value="4" />
									<input name="route_netmask_0" size="3" maxlength="3" onblur="valid_range(this,0,255,share.subnet)" class="num" value="<% static_route_setting("netmask","0"); %>" />.<input name="route_netmask_1" size="3" maxlength="3" onblur="valid_range(this,0,255,share.subnet)" class="num" value="<% static_route_setting("netmask","1"); %>" />.<input name="route_netmask_2" size="3" maxlength="3" onblur="valid_range(this,0,255,share.subnet)" class="num" value="<% static_route_setting("netmask","2"); %>" />.<input name="route_netmask_3" size="3" maxlength="3" onblur="valid_range(this,0,255,share.subnet)" class="num" value="<% static_route_setting("netmask","3"); %>" />
								</div>
								<div class="setting">
									<div class="label"><% tran("share.gateway"); %></div>
									<input type="hidden" name="route_gateway" value="4" />
									<input size="3" maxlength="3" name="route_gateway_0" onblur="valid_range(this,0,255,share.gateway)" class="num" value="<% static_route_setting("gateway","0"); %>" />.<input size="3" maxlength="3" name="route_gateway_1" onblur="valid_range(this,0,255,share.gateway)" class="num" value="<% static_route_setting("gateway","1"); %>" />.<input size="3" maxlength="3" name="route_gateway_2" onblur="valid_range(this,0,255,share.gateway)" class="num" value="<% static_route_setting("gateway","2"); %>" />.<input size="3" maxlength="3" name="route_gateway_3" onblur="valid_range(this,0,254,share.gateway)" class="num" value="<% static_route_setting("gateway","3"); %>" />
								</div>
								<div class="setting">
									<div class="label"><% tran("share.intrface"); %></div>
									<select name="route_ifname">
										<option value="lan" <% static_route_setting("lan","0"); %> >LAN &amp; WLAN</option>
										<option value="wan" <% static_route_setting("wan","0"); %> >WAN</option>
									</select>
								</div>
								<div class="center">
									<script type="text/javascript">
									//<![CDATA[
									document.write("<input class=\"button\" type=\"button\" name=\"button2\" value=\"" + sbutton.routingtab + "\" onclick=\"openWindow('RouteTable.asp', 720, 600);\" />");
									//]]>
									</script>
									<input type="hidden" value="0" name="Route_reload" />
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
							<dt class="term"><% tran("route.mod"); %>:</dt>
							<dd class="definition"><% tran("hroute.right2"); %></dd>
							<dt class="term"><% tran("route.static_setno"); %>:</dt>
							<dd class="definition"><% tran("hroute.right4"); %></dd>
							<dt class="term"><% tran("route.static_name"); %>:</dt>
							<dd class="definition"><% tran("hroute.right6"); %></dd>
							<dt class="term"><% tran("route.static_ip"); %>:</dt>
							<dd class="definition"><% tran("hroute.right8"); %></dd>
							<dt class="term"><% tran("share.subnet"); %>:</dt>
							<dd class="definition"><% tran("hroute.right10"); %></dd>
						</dl><br />
						<a href="javascript:openHelpWindow<% nvram_selmatch("dist_type","micro","Ext"); %>('HRouting.asp');"><% tran("share.more"); %></a>
					</div>
				</div>
				<div id="floatKiller"></div>
				<% do_statusinfo(); %>
			</div>
		</div>
	</body>
</html>
