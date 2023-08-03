local lux = require('luxure')
local cosock = require('cosock').socket
local json = require('dkjson')

local log = require('log')


local hub_server = {}

function hub_server.start(driver)
  local server = lux.Server.new_with(cosock.tcp(), {env='debug'})

  -- Register server
  driver:register_channel_handler(server.sock, function ()
    server:tick()
  end)

  -- Endpoint
  server:post('/push-state', function (req, res)
    log.info('Got push-state')
    log.trace('req:  '..tostring(req))
    log.trace('req.on_off:  '..tostring(req.on_off))
    local body = json.decode(req:get_body())
    log.trace('body.on_off:  '..tostring(body.on_off))
    local device = driver:get_device_info(body.uuid)
    if body.on_off then
      driver:on_off(device, body.on_off)
    end
    if body.lvl then
      driver:set_level(device, tonumber(body.lvl))
    end
    res:send('HTTP/1.1 200 OK')
  end)

  server:listen()
  driver.server = server
end

return hub_server
