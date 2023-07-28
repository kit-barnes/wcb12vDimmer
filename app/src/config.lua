----------------
-- Socket Config
-- UDP UPnP
MC_PORT=1900
LOCAL_ADDR='0.0.0.0'
MC_ADDR='239.255.255.250'
-- TCP Server
SRV_PORT=80

--------------------
-- Wifi Access Point
-- config
WIFI_AP_CONFIG = {
  ssid='wcbDimmer',
  pwd='dummy123',
  save=true,
  hidden=false,
  max=1
}

--------------
-- Device info
DEV = {
  CHIP_ID=string.format('%x', node.chipid()),
  SN=string.format('WCB%d', node.chipid()),
  MN='wcbHomeBuilt',
  NAME='wcb12vDimmer',
  TYPE='LAN',
  ext_uuid=nil,
  state = { on_off='off', lvl=0, clr={r=50,g=50,b=50,},},
  HUB = { addr=nil, port=nil },
}

