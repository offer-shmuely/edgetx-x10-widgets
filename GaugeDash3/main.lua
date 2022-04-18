-- Gauge widget, to provide real-time gauge
-- Possible usages are: Temp / rpm / batt-capacity visualizing.
-- Version        : 0.1
-- Author         : Offer Shmuely
-- Option         : Source, min / max value / HighAsGreen

local value2 = { 95, 0, 100 , -1}
local cx = { 200, 197, 203, 1}
local cy = { 100, 99, 101, 0 }
local cr = { 60, 55, 90, 1 }

local _options = {
  { "Source", SOURCE, 1 },
  { "Min", VALUE, 0, -1024, 1024 },
  { "Max", VALUE, 100, -1024, 1024 },
  { "HighAsGreen", BOOL,  1 }
}

--------------------------------------------------------------
local function log(s)
  --	return;
  print("Gauge3: " .. s)
end
--------------------------------------------------------------

local function create(zone, options)
  local imageFileHighAsGreen = "/WIDGETS/Gauge3/img/background4.png"
  imgBg = Bitmap.open(imageFileHighAsGreen)

  local wgt = {
    zone = zone,
    options = options,
    bgImage = imgBg
  }

  return wgt
end

local function update(wgt, options)
  wgt.options = options
end

local function drawArm(armX, armY, armR, centreR, percentageValue)
  --min = 5.54
  --max = 0.8
  local degrees = 5.51 - (percentageValue / (100 / 4.74));
  local xh = math.floor(armX + (math.sin(degrees) * armR))
  local yh = math.floor(armY + (math.cos(degrees) * armR))

  lcd.setColor(CUSTOM_COLOR, lcd.RGB(0, 0, 255))
  lcd.setColor(CUSTOM_COLOR, lcd.RGB(255, 255, 255))

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

local function drawGauge(wgt, centerX, centerY, centreR, percentageValue, txt1, txt2)
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
  lcd.drawFilledCircle(centerX,centerY, centreR, lcd.RGB(0x1A1A1A))

  -- fender
  lcd.drawAnnulus(centerX, centerY, centreR - fender, centreR ,  0 ,360, BLACK)

  -- ticks
  --lcd.drawAnnulus(centerX, centerY, centreR - fender-3 - tickWidth, centreR - fender -3 ,  270 ,270 + 8, YELLOW)
  --lcd.drawAnnulus(centerX, centerY, centreR - fender-3 - tickWidth, centreR - fender -3 ,  278 + 2 ,278 + 2 + 8, YELLOW)
  --lcd.drawAnnulus(centerX, centerY, centreR - fender-3 - tickWidth, centreR - fender -3 ,  288 + 2 ,288 + 2 + 8, YELLOW)

  for i = 0, 210, 10  do
    print("wgt.options.HighAsGreen: " .. wgt.options.HighAsGreen)
    if (wgt.options.HighAsGreen == 1) then
      lcd.setColor(CUSTOM_COLOR, getRangeColor(i, 0, 210 - 10))
    else
      lcd.setColor(CUSTOM_COLOR, getRangeColor(i, 210 - 10 , 0))
      --lcd.setColor(CUSTOM_COLOR, getRangeColor(i, 120 , 30))
    end
    lcd.drawAnnulus(centerX, centerY, centreR -fender -3 -tickWidth,     centreR -fender -3 , 250 +i, 250 +i +7, CUSTOM_COLOR)
    --lcd.drawAnnulus(centerX, centerY, centreR -fender -3 -tickWidth,     centreR -fender -3 , 250 +i, 250 +i +7, YELLOW)
    --lcd.drawAnnulus(centerX, centerY, centreR -fender -3 -tickWidth -15, centreR -fender -3 -tickWidth -4 , 250 +i, 250 +i +7, RED)
  end
  --lcd.drawPie(centerX,centerY,centreR - fender, 0,20)

  drawArm(centerX, centerY, armR, armCenterR, percentageValue)

  -- hide the base of the arm
  lcd.drawFilledCircle(centerX, centerY, armCenterR, BLACK)

  lcd.drawText(centerX + 7, centerY -10, txt2, CENTER + SMLSIZE + WHITE) -- XXLSIZE/DBLSIZE/MIDSIZE/SMLSIZE
  lcd.drawText(centerX + 10, centerY + 30, txt1, CENTER + txtSize + WHITE)

end

local function getPercentageValue(value, options_min, options_max)
  local percentageValue = value - options_min;
  percentageValue = (percentageValue / (options_max - options_min)) * 100

  if percentageValue > 100 then
    percentageValue = 100
  elseif percentageValue < 0 then
    percentageValue = 0
  end

  log("getPercentageValue(" .. value .. ", " .. options_min .. ", " .. options_max .. "-->" .. percentageValue)
  return percentageValue
end


local function update_randomizer(value)
  local current_vlue = value[1]
  local min = value[2]
  local max = value[3]
  local step = value[4]
  current_vlue = current_vlue + step
  if (step>0) then
    if (current_vlue >= max) then
      --current_vlue = min
      value[4] = value[4] * -1
    end
  else
    if (current_vlue <= min) then
      --current_vlue = max
      value[4] = value[4] * -1
    end
  end
  value[1] = current_vlue
end

local function refresh(wgt)
  if (wgt == nil) then return end
  if (wgt.options == nil) then return end
  if (wgt.zone == nil) then return end

  local ver, radio, maj, minor, rev, osname = getVersion()
  print("version: "..ver)
  if maj == 2 and minor <5 then
      print ("this widget is NOT SUPPORTED at this version")
  end

  if osname ~= "EdgeTX" then
    print ("this widget is supported only on EdgeTX:" ..osname)
  end

  update_randomizer(value2)
  update_randomizer(cx)
  update_randomizer(cy)
  update_randomizer(cr)

  percentageValue2 = getPercentageValue(value2[1], value2[2], value2[3])
  drawGauge(wgt, 100, 84, 78, percentageValue2, percentageValue2 .. "%", "Fuel\n  %")
  drawGauge(wgt, cx[1], cy[1], cr[1], percentageValue2, percentageValue2 .. "%", "Fuel\n  %")
  drawGauge(wgt, 300, 150, 60, percentageValue2, percentageValue2, "V")


  -- widget load (debugging)
  lcd.drawText(wgt.zone.x +10, wgt.zone.y, string.format("load: %d%%", getUsage()), SMLSIZE +WHITE) -- ???
  lcd.drawText(wgt.zone.x +200, wgt.zone.y, string.format("R: %d", cr[1]), SMLSIZE +WHITE) -- ???
end

return { name = "GaugeDash3", options = _options, create = create, update = update, refresh = refresh }
