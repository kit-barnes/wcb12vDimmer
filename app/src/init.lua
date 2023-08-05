------------------------
-- Load config & modules
dofile('config.lua')
dofile('device_control.lua')
dofile('server.lua')
dofile('upnp.lua')

---------------------------
-- Init Device Access Point
print([[
> wcb12vDimmer initializing
]])

wifi.setmode(wifi.STATIONAP)
wifi.ap.config(WIFI_AP_CONFIG)
-----------------------------

---------------------
-- Wifi event monitor
-- callbacks:
--
-- STATION Connected
wifi.eventmon.register(
  wifi.eventmon.STA_CONNECTED,
  function(evt)
    print(
      'service: station\r\n'..
      'status:  connected\r\n'..
      'ssid:    '..evt.SSID..'\r\n'..
      'bssid:   '..evt.BSSID..'\r\n')
  end)

-- STATION Disconnected
wifi.eventmon.register(
  wifi.eventmon.STA_DISCONNECTED,
  function (evt)
    print(
      'service:  station\r\n'..
      'status:   disconnected\r\n'..
      'reason:   '..evt.reason..'\r\n'..
      'ssid:     '..evt.SSID..'\r\n'..
      'bssid:    '..evt.BSSID..'\r\n')
  end)

-- STATION IP ready
wifi.eventmon.register(
  wifi.eventmon.STA_GOT_IP,
  function (evt)
    print(
      'service:  station\r\n'..
      'status:   IP Address ready\r\n'..
      'action:   start UPnP Socket\r\n'..
      'netmask:  '..evt.netmask..'\r\n'..
      'gateway:  '..evt.netmask..'\r\n'..
      '>>> DEVICE AVAILABLE OVER LAN AT: '..evt.IP..'\r\n')
      -- initialize ssdp session
      upnp_start()
  end)

-- ACCESS POINT new client
wifi.eventmon.register(
  wifi.eventmon.AP_STACONNECTED,
  function (evt)
    print(
      'service:  access point\r\n'..
      'action:   start LAN AP socket\r\n'..
      'status:   client connected\r\n'..
      'MAC:      '..evt.MAC..'\r\n'..
      'AID:      '..evt.AID..'\r\n')
  end)


--------------
-- init server
print("Starting server")
server_start()
