-- Horus Widget that count number of flights
-- Offer Shmuely
-- Date: 2022
-- ver: 0.1
-- flight considered successful: ofter 20sec the engine above 25%, and telemetry is active (to indicated that the model connected), and safe switch ON
-- flight considered ended: ofter 20sec of battery disconnection (detected by no telemetry)
-- warning: do NOT use this widget if model is using GV9!!!

-- widget assume as follow:
--   the model have motor
--   the motor is activated on chanel 3 (can be change in settings)
--   there is telemetry with one of the above [RSSI|RxBt|A1|A2|1RSS|2RSS|RQly]
--   there is a safe switch (arm switch)
--   global variable GV9 is free (i.e. not used)

-- states:
--   ground --> flight-starting --> flight-on --> flight-ending --> ground
--   all-flags on for 20s => flight-on
--   no telemetry for 30s => flight-completed


local app_name = "FlightCount"

-- status
local switch_on
local switch_name
local tele_src
local tele_src_name
local tele_is_available
local motor_active
local motor_channel_name
local flight_state = "GROUND"
local periodic1 = {startTime = getTime(), durationMili = 20000}

-- imports

-- consts

local options = {
  { "switch", SOURCE, 117 },         -- 117== SF (arm/safety switch)
  { "motor_channel", SOURCE, 204 },   -- 204==CH3
  { "setup_time", VALUE, 30, 0, 120},
  --{ "text_color", COLOR, YELLOW },
  { "wait_for_telemetry", BOOL, 1 },   -- only increase flight count if telemetry available
  { "debug", BOOL, 1 }   -- show status on screen

}

local function log(s)
  --return;
  print("flightCount: " .. s)
end

local function update(wgt, options)
  if (wgt == nil) then return end
  wgt.options = options
  --log("TimerNumB:" .. options.Timer)
  if (wgt.options.switch == nil) then
    wgt.options.switch = "sf"
  end

  fi_sw = getFieldInfo(wgt.options.switch)
  switch_name = fi_sw.name

  fi_mot = getFieldInfo(wgt.options.motor_channel)
  motor_channel_name = fi_mot.name

  model.setGlobalVariable(8, 7, 77)
  model.setGlobalVariable(8, 6, 66)

end

local function create(zone, options)
  local wgt = { zone = zone, options = options }
  --wgt.options.use_days = wgt.options.use_days % 2 -- modulo due to bug that cause the value to be other than 0|1
  update(wgt, options)
  return wgt
end


local function getFontSize(wgt, txt)
  wide_txt = string.gsub(txt, "[1-9]", "0")
  --log(string.gsub("******* 12:34:56", "[1-9]", "0"))
  --log("wide_txt: " .. wide_txt)

  local w,h = lcd.sizeText(wide_txt, XXLSIZE)
  --log(string.format("XXLSIZE w: %d, h: %d, %s", w, h, time_str))
  if w < wgt.zone.w and h <= wgt.zone.h then
    return XXLSIZE
  end

  w,h = lcd.sizeText(wide_txt, DBLSIZE)
  --log(string.format("DBLSIZE w: %d, h: %d, %s", w, h, time_str))
  if w < wgt.zone.w and h <= wgt.zone.h then
    return DBLSIZE
  end

  w,h = lcd.sizeText(wide_txt, MIDSIZE)
  --log(string.format("MIDSIZE w: %d, h: %d, %s", w, h, time_str))
  if w < wgt.zone.w and h <= wgt.zone.h then
    return MIDSIZE
  end

  --log(string.format("SMLSIZE w: %d, h: %d, %s", w, h, time_str))
  return SMLSIZE
end

------------------------------------------------------------

local function periodicStart(t, durationMili)
  t.startTime = getTime();
  t.durationMili = durationMili;
end

local function periodicHasPassed(t)
  local elapsed = getTime() - t.startTime;
  local elapsedMili = elapsed * 10;
  if (elapsedMili < t.durationMili) then
    return false;
  end
  return true;
end

local function periodicGetElapsedTime(t)
  local elapsed = getTime() - t.startTime;
  --log(string.format("elapsed: %d",elapsed));
  local elapsedMili = elapsed * 10;
  --log(string.format("elapsedMili: %d",elapsedMili));
  return elapsedMili;
end

--------------------------------------------------------------------------------------------------------

function updateTelemetryStatus(wgt)
  -- select telemetry source
  if not tele_src then
    log("select telemetry source")
    tele_src = getFieldInfo("RSSI")
    if not tele_src then tele_src = getFieldInfo("RxBt") end
    if not tele_src then tele_src = getFieldInfo("A1") end
    if not tele_src then tele_src = getFieldInfo("A2") end
    if not tele_src then tele_src = getFieldInfo("1RSS") end
    if not tele_src then tele_src = getFieldInfo("2RSS") end
    if not tele_src then tele_src = getFieldInfo("RQly") end

    if tele_src ~= nil then
      tele_src_name = tele_src.name
      log("found telemetry source: " .. tele_src_name)
    end
  end

  if tele_src == nil then
    log("no telemetry sensor found")
    tele_src_name = "---"
    tele_is_available = false
    return
  end

  local tele_src_val = getValue(tele_src.id)
  log("tele_src.id: " .. tele_src.id)
  log("tele_src_name: " .. tele_src_name)
  log("tele_src_val: " .. tele_src_val)
  local tele_val = getValue(tele_src.id)
  if tele_val <= 0 then
    log("tele: tele_val<=0")
    tele_is_available = false
    return
  end

  log("tele: tele_val>0")
  tele_is_available = true
  return

end

function updateMotorStatus(wgt)
  local motor_value = getValue(wgt.options.motor_channel)
  log(string.format("motor_value (%s): %s", wgt.options.motor_channel, motor_value))

  if (motor_value > -800 ) then
    motor_active = true
  else
    motor_active = false
  end
end

function updateSwitchStatus(wgt)
  if getValue(wgt.options.switch) > 0 then
    log(string.format("switch status (%s): =ON", wgt.options.switch))
    switch_on = true
    --return 2
  else
    log(string.format("switch status (%s): =OFF", switch_name))
    switch_on = false
    --return 1
  end
end

--------------------------------------------------------------------------------------------------------
------------------------------------------------------------
------------------------------------------------------------
------------------------------------------------------------
local function getFlightCount()
  -- get flight count
  -- get GV9 (index = 8) from Flight mode 8 (FM8)
  local num_flights = model.getGlobalVariable(8, 8)
  return num_flights
end

local function incrementFlightCount()
  local num_flights = getFlightCount()
  local new_flight_count = num_flights + 1
  model.setGlobalVariable(8, 8, new_flight_count)
  log("num_flights updated: " .. new_flight_count)
end

---------------------------------------------------------------
local function stateChange(newState)
  log(string.format("flight_state: %s --> %s", flight_state, newState))
  flight_state = newState
  periodicStart(periodic1, 10000)
end

local function background(wgt)

  updateMotorStatus(wgt)

  updateSwitchStatus(wgt)

  updateTelemetryStatus(wgt)

  log(string.format("tele_is_available: %s", tele_is_available))

  if flight_state == "GROUND" then
    if (motor_active == true) and (switch_on == true) and (tele_is_available == true) then
      stateChange("FLIGHT_STARTING")
    end

  elseif flight_state == "FLIGHT_STARTING" then
    if (motor_active == true) and (switch_on == true) and (tele_is_available == true) then
      pt = periodicGetElapsedTime(periodic1)
      log("flight_state: FLIGHT_STARTING ..." .. pt)
      if (periodicHasPassed(periodic1)) then
        stateChange("FLIGHT_ON")
        incrementFlightCount()
      end
    else
      stateChange("GROUND")
    end

  elseif flight_state == "FLIGHT_ON" then
    if (tele_is_available == false) then
      stateChange("FLIGHT_ENDING")
    end

  elseif flight_state == "FLIGHT_ENDING" then
    pt = periodicGetElapsedTime(periodic1)
    log("flight_state: FLIGHT_ENDING ..." .. pt)

    if (periodicHasPassed(periodic1)) then
      stateChange("GROUND")
    end

    if (tele_is_available == true) then
      stateChange("FLIGHT_ON")
    end

  end
  log("flight_state: " .. flight_state)

end

function ternary(cond , T , F)
  if cond then
    return "ON"
  else
    return "OFF"
  end
end


local function refresh(wgt, event, touchState)
  if (wgt == nil)               then log("refresh(nil)")                   return end
  if (wgt.options == nil)       then log("refresh(wgt.options=nil)")       return end

  background(wgt)

  -- get flight count
  local num_flights = getFlightCount()

  -- header
  local header = "Flights count:"
  local header_w, header_h = lcd.sizeText(header, SMLSIZE)

  local font_size = getFontSize(wgt, num_flights)
  local zone_w = wgt.zone.w
  local zone_h = wgt.zone.h

  local font_size_header = SMLSIZE
  if (event ~= nil) then
    -- app mode (full screen)
    font_size = XXLSIZE
    font_size_header = DBLSIZE
    zone_w = 460
    zone_h = 252
  end

  local ts_w,ts_h = lcd.sizeText(num_flights, font_size)
  local dx = (zone_w - ts_w) /2
  local dy = header_h -1
  if (header_h + ts_h > zone_h) and (zone_h < 50) then
    log(string.format("--- not enough height, force minimal spaces"))
    dy = 10
  end

  -- draw header
  lcd.drawText(wgt.zone.x, wgt.zone.y, header, font_size_header)

  -- draw count
  if wgt.options.debug == 1 then
    lcd.drawText(wgt.zone.x+wgt.zone.w, wgt.zone.y + dy, num_flights, font_size +  RIGHT)
  else
    lcd.drawText(wgt.zone.x + dx, wgt.zone.y + dy, num_flights, font_size)
  end

  -- dbg
  if wgt.options.debug == 1 then
    lcd.drawText(wgt.zone.x, wgt.zone.y + 35, string.format("state: %s", flight_state), SMLSIZE)
    lcd.drawText(wgt.zone.x, wgt.zone.y + 50, string.format("switch(%s): %s", switch_name, ternary(switch_on)), SMLSIZE)
    lcd.drawText(wgt.zone.x, wgt.zone.y + 65, string.format("telemetry(%s): %s", tele_src_name, ternary(tele_is_available)), SMLSIZE)
    lcd.drawText(wgt.zone.x, wgt.zone.y + 80, string.format("motor(%s): %s", motor_channel_name, ternary(motor_active)), SMLSIZE)
  end

end

return { name = "FlightCount", options = options, create = create, update = update, background = background, refresh = refresh }
