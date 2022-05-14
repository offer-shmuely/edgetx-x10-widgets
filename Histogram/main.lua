local app_name = "Histogram"

-- imports
local HistClass = loadScript("/WIDGETS/" .. app_name .. "/hist_core.lua")

-- consts
--local UNIT_ID_TO_STRING = { "V", "A", "mA", "kts", "m/s", "f/s", "km/h", "mph", "m", "f", "°C", "°F", "%", "mAh", "W", "mW", "dB", "rpm", "g", "°", "rad", "ml", "fOz", "ml/m", "Hz", "uS", "km" }

local _options = {
  { "Source", SOURCE, 253 }, -- RSSI
  --{ "Source", SOURCE, 243 }, -- TxBt
  --{ "Source", SOURCE, 256 }, -- RxBt
  { "Min", VALUE, -1, -1024, 1024 },
  { "Max", VALUE, -1, -1024, 1024 },
  --{ "HighAsGreen", BOOL, 1 },
  { "Precision", VALUE, 1 , 0 , 2}
}
--------------------------------------------------------------
local function log(s)
  --return;
  print("appHist: " .. s)
end
--------------------------------------------------------------

local function update(wgt, options)
  log("+++ function update()")
  wgt.options = options
  wgt.hist1 = HistClass(options.Source, 1000)

  local sourceName = getSourceName(wgt.options.Source)
  log("aaaaaa2:  "..  sourceName)
  log("aaaaaa2:  ".. sourceName .. ": " .. string.byte(string.sub(sourceName, 1, 1)))
  -- workaround for bug in getFiledInfo()
  if string.byte(string.sub(sourceName,1,1)) > 127 then
    sourceName = string.sub(sourceName,2,-1) -- ???? why?
  end

  wgt.source_name = sourceName
  log("wgt.source_name: " .. wgt.source_name)

end

local function create(zone, options)
  log("+++ function create()")
  --local HistClass = loadScript("/WIDGETS/" .. app_name .. "/hist_core.lua")

  local wgt = {
    zone = zone,
    options = options,
    source_name = "---",
    hist1 = nil
    --hist1 = HistClass(options.Source, 1000),
  }

  update(wgt, options)
  return wgt
end

local function getWidgetValueEx(wgt)
  local currentValue = getValue(wgt.options.Source)
  local sourceName = getSourceName(wgt.options.Source)
  log("aaaaaa:  "..  sourceName)
  log("aaaaaa:  ".. sourceName .. ": " .. string.byte(string.sub(sourceName, 1, 1)))

  -- workaround for bug in getFiledInfo()
  if string.byte(string.sub(sourceName,1,1)) > 127 then
    sourceName = string.sub(sourceName,2,-1) -- ???? why?
  end
  --log("Source: " .. wgt.options.Source .. ",name: " .. sourceName)


  local fieldinfo = getFieldInfo(wgt.options.Source)
  if (fieldinfo == nil) then
    log(string.format("getFieldInfo(%s)==nil", wgt.options.Source))
    return sourceName, -1, nil, nil, ""
  end

  local txtUnit = "-"
  if (fieldinfo.unit) then
    --log("have unit")
    if (fieldinfo.unit > 0 and fieldinfo.unit < #UNIT_ID_TO_STRING) then
      txtUnit = UNIT_ID_TO_STRING[fieldinfo.unit]
    end
  end

  log("")
  log(string.format("id: %s", fieldinfo.id))
  log(string.format("  sourceName: %s", sourceName))
  log(string.format("  curr: %2.1f", currentValue))
  log(string.format("  name: %s", fieldinfo.name))
  log(string.format("  desc: %s", fieldinfo.desc))
  log(string.format("  idUnit: %s", fieldinfo.unit))
  log(string.format("  txtUnit: %s", txtUnit))

  -- try to get min/max value (if exist)
  local minValue = getValue(sourceName .. "-")
  local maxValue = getValue(sourceName .. "+")
  --log("min/max: " .. minValue .. " < " .. currentValue .. " < " .. maxValue)

  return sourceName, currentValue, minValue, maxValue, txtUnit
end

local function background(wgt)
  wgt.hist1.updateBucketsIfNeeded()
end

local function refresh_app_mode(wgt, event, touchState, w_name, value, minValue, maxValue, w_unit, percentageValue, percentageValueMin, percentageValueMax)
  wgt.hist1.drawHist(wgt)
end

local function refresh_widget(wgt)
  wgt.hist1.drawHist(wgt)
end

local function refresh(wgt, event, touchState)
  if (wgt == nil) then return end
  if (wgt.options == nil) then return end
  if (wgt.zone == nil) then return end

  --background(wgt)
  wgt.hist1.updateBucketsIfNeeded()

  if (event ~= nil) then
    -- full screen (app mode)
    refresh_app_mode(wgt, event, touchState)
  else
    -- regular screen
    refresh_widget(wgt)
  end

  -- Title
  lcd.drawText(3, 3, string.format("%s Histogram", wgt.source_name), 0 + YELLOW)

  -- widget load (debugging)
  lcd.drawText(wgt.zone.x + 200, wgt.zone.y, string.format("load: %d%%", getUsage()), SMLSIZE + GREY) -- ???

  return 0
end

return { name = app_name, options = _options, create = create, update = update, refresh = refresh, background = background }
