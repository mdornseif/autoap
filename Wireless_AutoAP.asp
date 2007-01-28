<% do_pagehead(); %>
<title><% nvram_get("router_name"); %> - AutoAP</title>
</head>
<body class="gui">
  <% showad(); %>
  <div id="wrapper">
    <div id="content">
      <div id="header">
        <div id="logo">
          <h1><% show_control(); %></h1>
        </div>
        <% do_menu("Wireless_Basic.asp","Wireless_AutoAP.asp"); %>
      </div>
      <div id="main">
        <div id="contents">
            <form name="wireless_autoap" action="/cgi-bin/autoap.cgi" method="post">
            <h2><% tran("aap.h2"); %></h2>                    
            <fieldset>
            <legend><% tran("aap.legend"); %></legend>
            <div class="setting">
              <div class="label"><% tran("aap.label"); %></div>
              <LABEL><input type=Radio name="wl_aap_enab" id="wl_aap_enab" Value="1" CHECKED>Enable</LABEL>&nbsp;<LABEL><input type=Radio name="wl_aap_enab" id="wl_aap_enab" Value="0" >Disable</LABEL> 
            </div>
            <div class="setting">
              <div class="label"><% tran("aap.aap_logger"); %></div>
              <select name="wl_aap_logger" id="wl_aap_logger" >
                <option selected value="syslog">Syslogd</option>
                <option value="html">HTML Output</option>
                <option value="/tmp/autoap.log">/tmp/autoap.log</option>
                <option value="/tmp/smbshare/autoap.log">/tmp/smbshare/autoap.log</option>
              </select>
            </div>
            <div class="setting">
              <div class="label"><% tran("aap.aap_freq"); %></div>
              <input class="num" size="3" maxlength="3" name="wl_aap_freq" id="wl_aap_freq" value="<% nvram_get("autoap_scanfreq"); %>" />
            </div>
            <div class="setting">
              <div class="label"><% tran("aap.aap_ap"); %></div>
              <input class="num" size="3" maxlength="3" name="wl_aap_ap" id="wl_aap_ap" value="<% nvram_get("autoap_aplimit"); %>" />
            </div>
            <div class="setting">
              <div class="label"><% tran("aap.aap_dwait"); %></div>
              <input class="num" size="2" maxlength="2" name="wl_aap_dwait" id="wl_aap_dwait" value="<% nvram_get("autoap_dhcpw"); %>" />
            </div>
            <div class="setting">
              <div class="label"><% tran("aap.aap_findo"); %></div>
              <LABEL><input type=Radio name="wl_aap_findo" id="wl_aap_findo" Value="1" CHECKED>Enable</LABEL>&nbsp;<LABEL><input type=Radio name="wl_aap_findo" id="wl_aap_findo" Value="0" >Disable</LABEL> 
            </div>
            <div class="setting">
              <div class="label"><% tran("aap.aap_inet"); %></div>
              <LABEL><input type=Radio name="wl_aap_inetck" id="wl_aap_inetck" Value="1" CHECKED>Enable</LABEL>&nbsp;<LABEL><input type=Radio name="wl_aap_inetck" id="wl_aap_inetck" Value="0" >Disable</LABEL> 
            </div>
            <div class="setting">
              <div class="label"><% tran("aap.aap_ineturl"); %></div>
              <input class="text" name="wl_aap_ineturl" width="30" id="wl_aap_ineturl" value="<% nvram_get("autoap_ineturl"); %>" />
            </div>
            <div class="setting">
              <div class="label"><% tran("aap.aap_findw"); %></div>
              <LABEL><input type=Radio name="wl_aap_findw" id="wl_aap_findw" Value="1" >Enable</LABEL>&nbsp;<LABEL><input type=Radio name="wl_aap_findw" id="wl_aap_findw" Value="0" CHECKED>Disable</LABEL> 
            </div>
            <br/>
            <div class="setting">
              <div class="label"><% tran("aap.aap_wkeys"); %></div>
              <input class="text" name="wl_aap_wep1" width="30" id="wl_aap_wep1" value="<% nvram_get("autoap_wep1"); %>" />
            </div>
            <div class="setting">
              <div class="label">&nbsp;</div>
              <input class="text" name="wl_aap_wep2" width="30" id="wl_aap_wep2" value="<% nvram_get("autoap_wep2"); %>" />
            </div>
            <div class="setting">
              <div class="label">&nbsp;</div>
              <input class="text" name="wl_aap_wep3" width="30" id="wl_aap_wep3" value="<% nvram_get("autoap_wep3"); %>" />
            </div>
            <br/>
            <div class="setting">
              <div class="label"><% tran("aap.aap_mac"); %></div>
              <input class="text" name="wl_aap_mac1" width="30" id="wl_aap_mac1" value="<% nvram_get("autoap_mac1"); %>" />
            </div>
            <div class="setting">
              <div class="label">&nbsp;</div>
              <input class="text" name="wl_aap_mac2" width="30" id="wl_aap_mac2" value="<% nvram_get("autoap_mac2"); %>" />
            </div>
            <div class="setting">
              <div class="label">&nbsp;</div>
              <input class="text" name="wl_aap_mac3" width="30" id="wl_aap_mac3" value="<% nvram_get("autoap_mac3"); %>" />
            </div>
            <br/>
            <div class="setting">
              <div class="label"><% tran("aap.aap_ssid"); %></div>
              <input class="text" name="wl_aap_ssid1" width="30" id="wl_aap_ssid1" value="<% nvram_get("autoap_ssid1"); %>" />
            </div>
            <div class="setting">
              <div class="label">&nbsp;</div>
              <input class="text" name="wl_aap_ssid2" width="30" id="wl_aap_ssid2" value="<% nvram_get("autoap_ssid2"); %>" />
            </div>
            <div class="setting">
              <div class="label">&nbsp;</div>
              <input class="text" name="wl_aap_ssid3" width="30" id="wl_aap_ssid3" value="<% nvram_get("autoap_ssid3"); %>" />
            </div>
            </fieldset>
            <br/>
            <div align="center"><input type="submit" value="Save"></div>
            </form>
        </div>
      </div>
      <div id="helpContainer">
        <div id="help">
          <div><h2><% tran("share.help"); %></h2></div><br/>
        </div>
      </div>
      <div id="floatKiller"></div>
      <% do_statusinfo(); %>
    </div>
  </div>
</body>
</html>
