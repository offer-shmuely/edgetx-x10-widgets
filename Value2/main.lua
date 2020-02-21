
local options = {
  { "Source", SOURCE, 1 },
  { "TextColor", COLOR, YELLOW }
}

local function create(zone, options)
  local wgt = {
    zone = zone,
    options = options,
    telemResetCount = 0,
    telemResetLowestMinRSSI = 101,
  }

  return wgt
end

local function update(wgt, options)
  if (wgt == nil) then return end
  wgt.options = options
end

-- clear old telemetry data upon reset event
local function onTelemetryResetEvent(wgt)
  wgt.telemResetCount = wgt.telemResetCount + 1

  -- ToDo: clean here the telemetry values
end


-- workaround to detect telemetry-reset event, until a proper implementation on the lua interface will be created
-- this workaround assume that:
--   RSSI- is always going down
--   RSSI- is reset on the C++ side when a telemetry-reset is pressed by user
--   widget is calling this func on each refresh/background
-- on event detection, the function onTelemetryResetEvent() will be trigger
--
local function detectResetEvent(wgt)

  local currMinRSSI = getValue('RSSI-')
  if (currMinRSSI == nil) then return
  end
  if (currMinRSSI == wgt.telemResetLowestMinRSSI) then return end

  if (currMinRSSI < wgt.telemResetLowestMinRSSI) then
    -- rssi just got lower, record it
    wgt.telemResetLowestMinRSSI = currMinRSSI
    return
  end


  -- reset telemetry detected
  wgt.telemResetLowestMinRSSI = 101

  -- notify event
  onTelemetryResetEvent(wgt)

end


local function background(wgt)
  if (wgt == nil) then return end

  detectResetEvent(wgt)

end


local function showField(wgt, fieldName, offsetY)
  local x = wgt.zone.x
  local y = wgt.zone.y + offsetY
  local fieldValue = getValue(fieldName)
  local txt = fieldName .. ": " .. fieldValue
  lcd.drawText(x, y, txt, LEFT + SMLSIZE)
end

------------------------------------------------------------

function refresh(wgt)
  if (wgt == nil) then return end
  if wgt.zone.w  <= 170 or wgt.zone.h <=  65 then return  end

  detectResetEvent(wgt)


  local currMinRSSI = getValue('RSSI-')
  if (currMinRSSI == nil) then
    lcd.drawText(wgt.zone.x, wgt.zone.y + 0, "currMinRSSI: ".. 'N/A', SMLSIZE + CUSTOM_COLOR)
    return
  end


  lcd.drawText(wgt.zone.x, wgt.zone.y + 0, "currMinRSSI: ".. currMinRSSI, SMLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x, wgt.zone.y + 15, "lowestMinRSSI: ".. wgt.telemResetLowestMinRSSI, SMLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x, wgt.zone.y + 30, string.format("resetCount: %d", wgt.telemResetCount), SMLSIZE + CUSTOM_COLOR)

  showField(wgt, 'RSSI', 50)
  showField(wgt, 'RSSI-', 65)
  showField(wgt, 'RSSI+', 80)
  showField(wgt, 'Cels-', 90)


end

return { name = "Value2", options = options, create = create, update = update, background = background, refresh = refresh }
