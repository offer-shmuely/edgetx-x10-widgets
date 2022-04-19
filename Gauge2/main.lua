-- Gauge widget, to provide real-time fancy gauge display with needle
-- Possible  visualizing usages: RSSI, Temp, rpm, fuel, vibration, batt-capacity
-- Version        : 0.1
-- Author         : Offer Shmuely


local _options = {
  { "Source", SOURCE, 1 },
  { "Min", VALUE, 0, -1024, 1024 },
  { "Max", VALUE, 100, -1024, 1024 },
  { "HighAsGreen", BOOL, 1 }
}

--------------------------------------------------------------
local function log(s)
  --return;
  print("Gauge2: " .. s)
end
--------------------------------------------------------------

local function create(zone, options)

  local wgt = {
    zone = zone,
    options = options,
    --gauge1 = GaugeClass(1, 2)

  }
  local GaugeClass = loadScript("/WIDGETS/Gauge2/gauge_core.lua")
  wgt.gauge1 = GaugeClass(wgt.options.HighAsGreen, 2)


  return wgt
end

local function update(wgt, options)
  wgt.options = options
  wgt.gauge1.HighAsGreen = wgt.options.HighAsGreen
end

-- -----------------------------------------------------------------------------------------------------

local function getPercentageValue(value, options_min, options_max)
  if value == nil then
    return nil
  end

  local percentageValue = value - options_min;
  percentageValue = (percentageValue / (options_max - options_min)) * 100
  percentageValue = tonumber(percentageValue)
  percentageValue = math.floor( percentageValue )

  if percentageValue > 100 then
    percentageValue = 100
  elseif percentageValue < 0 then
    percentageValue = 0
  end

  --log("getPercentageValue(" .. value .. ", " .. options_min .. ", " .. options_max .. ")-->" .. percentageValue)
  return percentageValue
end

local function getWidgetValue(wgt)
  local currentValue = getValue(wgt.options.Source)
  local sourceName = getSourceName(wgt.options.Source)
  sourceName = string.sub(sourceName,2,-1) -- ???? why?
  log("Source: " .. wgt.options.Source .. ",name: " .. sourceName)

  --local currentValue = getValue(wgt.options.Source) / 10.24
  log(string.format("%2.1fV", currentValue)) -- ???
  log("Source: " .. wgt.options.Source .. ",currentValue: " .. currentValue)

  local fieldinfo = getFieldInfo(wgt.options.Source)
  if (fieldinfo == nil) then
    log(string.format("getFieldInfo(%s)==nil", wgt.options.Source))
    return sourceName, -1, nil, nil, ""
  end

  local txtUnit = "-"
  if (fieldinfo.unit) then
    log("have unit")
    log("idUnit: " .. fieldinfo.unit)
    txtUnit = "??" -- ???
    --if (idUnit > 0 and idUnit < #unitToString) then
    --  txtUnit = unitToString[idUnit]
    --  log("txtUnit: " .. txtUnit)
    --end
  end

  log(string.format("  id: %s", fieldinfo.id))
  log(string.format("  name: %s (sourceName: %s)", fieldinfo.name, sourceName))
  log(string.format("  desc: %s", fieldinfo.desc))
  log(string.format("  idUnit: %s", fieldinfo.unit))
  log(string.format("  txtUnit: %s", txtUnit))

  -- try to get min/max value (if exist)
  local minValue = getValue(sourceName .. "-")
  local maxValue = getValue(sourceName .. "+")
  --log("min/max: " .. minValue .. " < " .. currentValue .. " < " .. maxValue)

  return sourceName, currentValue, minValue, maxValue, txtUnit
end

local function refresh_full_screen(wgt, event, touchState, w_name, value, minValue, maxValue, w_unit, percentageValue, percentageValueMin, percentageValueMax)
  local zone_w = 460
  local zone_h = 252

  local centerX = zone_w / 2
  wgt.gauge1.drawGauge(centerX, 120, 110, percentageValue, percentageValueMin, percentageValueMax, percentageValue .. w_unit, w_name)
  lcd.drawText(10, 10, string.format("%d%s", percentageValue, w_unit), XXLSIZE + YELLOW)

  -- min / max
  wgt.gauge1.drawGauge(100, 180, 50, percentageValueMin, nil, nil, "", w_name)
  wgt.gauge1.drawGauge(zone_w - 100, 180, 50, percentageValueMax, nil, nil, "", w_name)
  lcd.drawText(50, 230, string.format("Min: %d%s", percentageValueMin, w_unit), MIDSIZE)
  lcd.drawText(350, 230, string.format("Max: %d%s", percentageValueMax, w_unit), MIDSIZE)

end

local function refresh(wgt, event, touchState)
  if (wgt == nil) then return end
  if (wgt.options == nil) then return end
  if (wgt.zone == nil) then return end

  local ver, radio, maj, minor, rev, osname = getVersion()
  --log("version: " .. ver)
  if osname ~= "EdgeTX" then
    local err = string.format("supported only on EdgeTX: ", osname)
    log(err)
    lcd.drawText(0, 0, err, SMLSIZE)
    return
  end
  if maj == 2 and minor < 7 then
    local err = string.format("NOT supported ver: %s", ver)
    log(err)
    lcd.drawText(0, 0, err, SMLSIZE)
    return
  end

  local w_name, value, minValue, maxValue, w_unit = getWidgetValue(wgt)
  if (value == nil) then
    return
  end

  local percentageValue = getPercentageValue(value, wgt.options.Min, wgt.options.Max)
  local percentageValueMin = getPercentageValue(minValue, wgt.options.Min, wgt.options.Max)
  local percentageValueMax = getPercentageValue(maxValue, wgt.options.Min, wgt.options.Max)

  if (event ~= nil) then
    -- full screen (app mode)
    refresh_full_screen(wgt, event, touchState, w_name, value, minValue, maxValue, w_unit, percentageValue, percentageValueMin, percentageValueMax)
  else
    -- regular screen
    local centerX = wgt.zone.x + (wgt.zone.w / 2)
    local centerY = wgt.zone.y + (wgt.zone.h / 2)
    local centerR = math.min(wgt.zone.h, wgt.zone.w) / 2
    wgt.gauge1.drawGauge(centerX, centerY, centerR, percentageValue, percentageValueMin, percentageValueMax, percentageValue .. w_unit, w_name)
  end

  -- widget load (debugging)
  lcd.drawText(wgt.zone.x + 10, wgt.zone.y, string.format("load: %d%%", getUsage()), SMLSIZE + GREY) -- ???
end

return { name = "Gauge2", options = _options, create = create, update = update, refresh = refresh }
