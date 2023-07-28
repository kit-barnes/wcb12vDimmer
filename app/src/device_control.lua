
-- GPIO config
-- PIN_RED = 3
-- PIN_BLUE = 4
PIN_BUTTON = 5
local PIN_PWM = 7		-- Dimmer output

local PWM_FREQ = 800
local PWM_STEPS = 100

local BUTTON_TIME = 250		-- 1/4 sec

local state = DEV.state


-- Init PWM pin
pwm2.setup_pin_hz(PIN_PWM, PWM_FREQ, PWM_STEPS, state.lvl) -- off
pwm2.start()


-- LED Level Control
function led_lvl_ctl(lvl) -- assert 0 <= lvl <= PWM_STEPS
  state.lvl = lvl
  state.on_off = lvl~=0 and 'on' or 'off'
  return pwm2.set_duty(PIN_PWM, lvl)
end


-- LED Switch Control
function led_switch_ctl(on_off)
  if on_off == 'off' then			-- leave state.lvl unchanged
    state.on_off = 'off'			--   but turn off light
	  return pwm2.set_duty(PIN_PWM, 0)
  elseif state.lvl == 0 then
    return led_lvl_ctl(PWM_STEPS) -- full on
  end
  return led_lvl_ctl(state.lvl)
end


-- Button Control
gpio.mode(PIN_BUTTON, gpio.INT, gpio.PULLUP)
local steptimer = tmr.create()
local longpress = false
local brighten = false

local function onButtonTime()
	if gpio.read(PIN_BUTTON) == gpio.LOW then	-- button pressed
		longpress = true
		-- adjust level - via exponential curve
		local level = state.lvl
		local delta = math.floor(level/4 +1)	-- ~16 full scale steps
		if  not brighten then delta = -delta end
		level = level + delta
		if level >= PWM_STEPS then level = PWM_STEPS; brighten=false
		elseif level < 1 then level=1; brighten=true 
		end
		led_lvl_ctl(level)	-- sets state
	else										-- button released
		if not longpress then  -- short press - toggle on-off
			led_switch_ctl( state.on_off == 'on' and 'off' or 'on' )
		end
		longpress = false
		steptimer:stop()
		-- report to hub (only when done)
		push_state(state)
	end
end
steptimer:register(BUTTON_TIME, tmr.ALARM_AUTO, onButtonTime)

local function onButtonPressed(input, presstime, count)
  print( 'Button pressed')
  brighten = not brighten -- alternate step direction
  steptimer:start()
end
gpio.trig(PIN_BUTTON, "down", onButtonPressed)
