-- Gauge widget, to provide real-time gauge
-- Possible usages are: Temp / rpm / batt-capacity visualizing.
-- Version        : 0.1
-- Author         : Offer Shmuely
-- Option         : Source, min / max value / HighAsGreen

local value1 = { 0, 0, 100, -1 }
local value2 = { 95, 0, 100, -1 }
local cx = { 200, 197, 203, 1 }
local cy = { 100, 99, 101, 0 }
local cr = { 60, 55, 90, 1 }

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
    options = options
  }

  return wgt
end

local function update(wgt, options)
  wgt.options = options
end

local function drawArm(armX, armY, armR, percentageValue, color)
  --min = 5.54
  --max = 0.8
  local degrees = 5.51 - (percentageValue / (100 / 4.74));
  local xh = math.floor(armX + (math.sin(degrees) * armR))
  local yh = math.floor(armY + (math.cos(degrees) * armR))

  --lcd.setColor(CUSTOM_COLOR, lcd.RGB(0, 0, 255))
  --lcd.setColor(CUSTOM_COLOR, lcd.RGB(255, 255, 255))
  lcd.setColor(CUSTOM_COLOR, color)

  local x1 = math.floor(armX - (math.sin(0) * (20 / 2.3)))
  local y1 = math.floor(armY - (math.cos(0) * (20 / 2.3)))
  local x2 = math.floor(armX - (math.sin(3) * (20 / 2.3)))
  local y2 = math.floor(armY - (math.cos(3) * (20 / 2.3)))
  lcd.drawFilledTriangle(x1, y1, x2, y2, xh, yh, CUSTOM_COLOR)
end

-- This function returns green at gvalue, red at rvalue and graduate in between
local function getRangeColor(value, red_value, green_value)
  local range = math.abs(green_value - red_value)
  if range == 0 then
    return lcd.RGB(0, 0xdf, 0)
  end
  if value == nil then
    return lcd.RGB(0, 0xdf, 0)
  end

  if green_value > red_value then
    if value > green_value then
      return lcd.RGB(0, 0xdf, 0)
    end
    if value < red_value then
      return lcd.RGB(0xdf, 0, 0)
    end
    g = math.floor(0xdf * (value - red_value) / range)
    r = 0xdf - g
    return lcd.RGB(r, g, 0)
  else
    if value < green_value then
      return lcd.RGB(0, 0xdf, 0)
    end
    if value > red_value then
      return lcd.RGB(0xdf, 0, 0)
    end
    r = math.floor(0xdf * (value - green_value) / range)
    g = 0xdf - r
    return lcd.RGB(r, g, 0)
  end
end

local function drawGauge(wgt, centerX, centerY, centreR, percentageValue, percentageValueMin, percentageValueMax, txt1, txt2)
  local fender = 4
  local tickWidth = 9
  local armCenterR = centreR / 2.5
  local armR = centreR - 8
  local txtSize = DBLSIZE
  if centreR < 65 then
    txtSize = MIDSIZE
  end
  if centreR < 30 then
    txtSize = SMLSIZE
  end

  -- main gauge background
  lcd.drawFilledCircle(centerX, centerY, centreR, lcd.RGB(0x1A1A1A))

  -- fender
  lcd.drawAnnulus(centerX, centerY, centreR - fender, centreR, 0, 360, BLACK)

  -- ticks
  --lcd.drawAnnulus(centerX, centerY, centreR - fender-3 - tickWidth, centreR - fender -3 ,  270 ,270 + 8, YELLOW)
  --lcd.drawAnnulus(centerX, centerY, centreR - fender-3 - tickWidth, centreR - fender -3 ,  278 + 2 ,278 + 2 + 8, YELLOW)
  --lcd.drawAnnulus(centerX, centerY, centreR - fender-3 - tickWidth, centreR - fender -3 ,  288 + 2 ,288 + 2 + 8, YELLOW)

  for i = 0, 210, 10 do
    --log("wgt.options.HighAsGreen: " .. wgt.options.HighAsGreen)
    if (wgt.options.HighAsGreen == 1) then
      lcd.setColor(CUSTOM_COLOR, getRangeColor(i, 0, 210 - 10))
    else
      lcd.setColor(CUSTOM_COLOR, getRangeColor(i, 210 - 10, 0))
      --lcd.setColor(CUSTOM_COLOR, getRangeColor(i, 120 , 30))
    end
    lcd.drawAnnulus(centerX, centerY, centreR - fender - 3 - tickWidth, centreR - fender - 3, 250 + i, 250 + i + 7, CUSTOM_COLOR)
    --lcd.drawAnnulus(centerX, centerY, centreR -fender -3 -tickWidth,     centreR -fender -3 , 250 +i, 250 +i +7, YELLOW)
    --lcd.drawAnnulus(centerX, centerY, centreR -fender -3 -tickWidth -15, centreR -fender -3 -tickWidth -4 , 250 +i, 250 +i +7, RED)
  end
  --lcd.drawPie(centerX,centerY,centreR - fender, 0,20)

  local armColor = lcd.RGB(255, 255, 255)
  local armColorMin, armColorMax
  if (wgt.options.HighAsGreen == 1) then
    armColorMin = lcd.RGB(100, 0, 0)
    armColorMax = lcd.RGB(0, 100, 0)
  else
    armColorMin = lcd.RGB(0, 100, 0)
    armColorMax = lcd.RGB(100, 0, 0)
  end

  if percentageValueMin ~= nil and percentageValueMax ~= nil then
    drawArm(centerX, centerY, armR, percentageValueMin, armColorMin)
    drawArm(centerX, centerY, armR, percentageValueMax, armColorMax)
  end
  drawArm(centerX, centerY, armR, percentageValue, armColor)

  -- hide the base of the arm
  lcd.drawFilledCircle(centerX, centerY, armCenterR, BLACK)

  lcd.drawText(centerX + 7, centerY - 10, txt2, CENTER + SMLSIZE + WHITE) -- XXLSIZE/DBLSIZE/MIDSIZE/SMLSIZE
  lcd.drawText(centerX + 10, centerY + 30, txt1, CENTER + txtSize + WHITE)

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

  log("getPercentageValue(" .. value .. ", " .. options_min .. ", " .. options_max .. ")-->" .. percentageValue)
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
  else
    local txt = fieldinfo['name'] .. "(id:" .. fieldinfo['id']
      .. ")"
    --.. "=" .. fieldValue
    --.. txtUnit
    --.. " [desc: " .. fieldinfo.desc .. "]"


    log("getFieldInfo()=" .. txt)
    log("getFieldInfo().name:" .. fieldinfo.name)
    log("getFieldInfo().desc:" .. fieldinfo.desc)

    local txtUnit = "---"
    if (fieldinfo['unit']) then
      local idUnit = fieldinfo['unit']

      --if (idUnit > 0 and idUnit < #unitToString) then
      --  log("idUnit: " .. idUnit)
      --  txtUnit = unitToString[idUnit]
      --  log("txtUnit: " .. txtUnit)
      --  wgt.unit = txtUnit
      --end
    else
      local idUnit = -1
    end
  end

  local minValue = getValue(sourceName .. "-")
  local maxValue = getValue(sourceName .. "+")
  log("min/max: " .. minValue .. " < " .. currentValue .. " < " .. maxValue)

  if (currentValue == nil)
  then
    --return fieldinfo.name, string.format("%2.1f %s", wgt.lastValue, wgt.unit)
    return fieldinfo.name, wgt.lastValue, minValue, maxValue, idUnit
  end
  --return fieldinfo.name, string.format("%2.1f %s", currentValue, wgt.unit)
  --return fieldinfo.name, currentValue, minValue, maxValue, idUnit
  return sourceName, currentValue, minValue, maxValue, idUnit
end

local function refresh(wgt, event, touchState)
  if (wgt == nil) then
    return
  end
  if (wgt.options == nil) then
    return
  end
  if (wgt.zone == nil) then
    return
  end

  local ver, radio, maj, minor, rev, osname = getVersion()
  log("version: " .. ver)
  if maj == 2 and minor < 6 then
    log("this widget is NOT SUPPORTED at this version")
  end

  if osname ~= "EdgeTX" then
    log("this widget is supported only on EdgeTX:" .. osname)
  end

  local w_name, value, minValue, maxValue, w_unit = getWidgetValue(wgt)
  if (value == nil) then
    return
  end

  local zone_x
  local zone_y
  local zone_w
  local zone_h

  if (event ~= nil) then
    -- full screen
    --font_size = XXLSIZE
    --font_size_header = DBLSIZE
    zone_x = 0
    zone_y = 0
    zone_w = 460
    zone_h = 252
  else
    zone_x = wgt.zone.x
    zone_y = wgt.zone.y
    zone_w = wgt.zone.w
    zone_h = wgt.zone.h
  end
  local centerX = zone_x + (zone_w / 2)
  local centerY = zone_y + (zone_h / 2)
  local centerR = math.min(zone_h, zone_w) / 2

  local percentageValue = getPercentageValue(value, wgt.options.Min, wgt.options.Max)
  local percentageValueMin = getPercentageValue(minValue, wgt.options.Min, wgt.options.Max)
  local percentageValueMax = getPercentageValue(maxValue, wgt.options.Min, wgt.options.Max)
  --drawGauge(wgt, centerX, centerY, centerR, percentageValue, percentageValue .. "%", "Fuel\n  %")

  drawGauge(wgt, centerX, centerY, centerR, percentageValue, percentageValueMin, percentageValueMax, percentageValue .. "%", w_name)

  -- widget load (debugging)
  lcd.drawText(zone_x + 10, zone_y, string.format("load: %d%%", getUsage()), SMLSIZE, LIGHTGREY) -- ???
  lcd.drawText(zone_x + 10, zone_y + 10, string.format("R: %d", cr[1]), SMLSIZE, LIGHTGREY) -- ???
end

return { name = "Gauge2", options = _options, create = create, update = update, refresh = refresh }
