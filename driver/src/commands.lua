local caps = require('st.capabilities')
local utils = require('st.utils')
local neturl = require('net.url')
local log = require('log')
local json = require('dkjson')
local cosock = require "cosock"
local http = cosock.asyncify "socket.http"
local ltn12 = require('ltn12')

local command_handler = {}


-- Ping command
function command_handler.ping(address, port, device)
  log.trace('sending PING')
  local ping_data = {ip=address, port=port, ext_uuid=device.id}
  return command_handler.send_lan_command(
    device.device_network_id, 'POST', 'ping', ping_data)
end


-- Refresh command
function command_handler.refresh(_, device)
  local success, data = command_handler.send_lan_command(
    device.device_network_id,
    'GET',
    'refresh')
  -- Check success
  if success then
    -- Define online status
    device:online()
    -- Monkey patch due to issues on ltn12 lib to fully sink
    -- JSON payload into table. Last bracket is missing.
    -- Update below when fixed:
    --local raw_data = json.decode(table.concat(data))
    ---@diagnostic disable-next-line: param-type-mismatch
    local status = json.decode(table.concat(data)..'}')
    -- Refresh Switch Level
    log.trace('Refreshing switch='..status.on_off..'  level='..status.lvl)
    device:emit_event(caps.switchLevel.level(status.lvl))
    -- Refresh Switch
    if status.on_off == 'off' then
      device:emit_event(caps.switch.switch.off())
    else
      device:emit_event(caps.switch.switch.on())
    end
  else
    log.error('failed to poll device state')
    -- Set device as offline
    device:offline()
  end
end


-- Switch command
function command_handler.on_off(_, device, command)
  local on_off = command.command
  -- send command via LAN
  local success, data = command_handler.send_lan_command(
    device.device_network_id,
    'POST',
    'control',
    {switch=on_off})
  -- Check if success
  if success then
    -- Monkey patch due to issues on ltn12 lib to fully sink
    -- JSON payload into table. Last bracket is missing.
    -- Update below when fixed:
    --local raw_data = json.decode(table.concat(data))
    --local raw_data = json.decode(table.concat(data)..'}')
    ---@diagnostic disable-next-line: param-type-mismatch
    local raw_data = json.decode(table.concat(data))
    log.trace('setting  Level after switch change to: '..raw_data.on_off)
    device:emit_event(caps.switchLevel.level(raw_data.lvl))
    if raw_data.on_off == 'off' then
      return device:emit_event(caps.switch.switch.off())
    end
    return device:emit_event(caps.switch.switch.on())
  end
  log.error('no response from device')
end


-- Switch level command
function command_handler.set_level(_, device, command)
  local lvl = command.args.level
  -- send command via LAN
  local success, data = command_handler.send_lan_command(
    device.device_network_id,
    'POST',
    'control',
    {level=lvl})
  -- Check if success
  if success then
    if lvl == 0 then
      device:emit_event(caps.switch.switch.off())
    else
      device:emit_event(caps.switch.switch.on())
    end
    device:emit_event(caps.switchLevel.level(lvl))
    return
  end
  log.error('no response from device')
end


-- Send LAN HTTP Request
function command_handler.send_lan_command(url, method, path, body)
  local dest_url = url..'/'..path
  local query = neturl.buildQuery(body or {})
  local res_body = {}
  -- HTTP Request
  local _, code = http.request({
    method=method,
    url=dest_url..'?'..query,
    sink=ltn12.sink.table(res_body),
    headers={
      ['Content-Type'] = 'application/x-www-urlencoded'
    }})
  -- Handle response
  if code == 200 then
    return true, res_body
  end
  return false, nil
end


return command_handler
