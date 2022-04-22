local HighAsGreen, p2 = ...

local self = {}
self.HighAsGreen = HighAsGreen

--------------------------------------------------------------
local function log(s)
  --return;
  print("Gauge_core: " .. s)
end
--------------------------------------------------------------

function self.drawArm(armX, armY, armR, percentageValue, color)
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
function self.getRangeColor(value, red_value, green_value)
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

function self.drawGauge(centerX, centerY, centreR, percentageValue, percentageValueMin, percentageValueMax, txt1, txt2)
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
    if (self.HighAsGreen == 1) then
      lcd.setColor(CUSTOM_COLOR, self.getRangeColor(i, 0, 210 - 10))
    else
      lcd.setColor(CUSTOM_COLOR, self.getRangeColor(i, 210 - 10, 0))
      --lcd.setColor(CUSTOM_COLOR, self.getRangeColor(i, 120 , 30))
    end
    lcd.drawAnnulus(centerX, centerY, centreR - fender - 3 - tickWidth, centreR - fender - 3, 250 + i, 250 + i + 7, CUSTOM_COLOR)
    --lcd.drawAnnulus(centerX, centerY, centreR -fender -3 -tickWidth,     centreR -fender -3 , 250 +i, 250 +i +7, YELLOW)
    --lcd.drawAnnulus(centerX, centerY, centreR -fender -3 -tickWidth -15, centreR -fender -3 -tickWidth -4 , 250 +i, 250 +i +7, RED)
  end
  --lcd.drawPie(centerX,centerY,centreR - fender, 0,20)

  local armColor = lcd.RGB(255, 255, 255)
  local armColorMin, armColorMax
  if (self.HighAsGreen == 1) then
    armColorMin = lcd.RGB(100, 0, 0)
    armColorMax = lcd.RGB(0, 100, 0)
  else
    armColorMin = lcd.RGB(0, 100, 0)
    armColorMax = lcd.RGB(100, 0, 0)
  end

  if percentageValueMin ~= nil and percentageValueMax ~= nil then
    self.drawArm(centerX, centerY, armR, percentageValueMin, armColorMin)
    self.drawArm(centerX, centerY, armR, percentageValueMax, armColorMax)
  end
  self.drawArm(centerX, centerY, armR, percentageValue, armColor)

  -- hide the base of the arm
  lcd.drawFilledCircle(centerX, centerY, armCenterR, BLACK)

  -- text in center
  lcd.drawText(centerX + 0, centerY - 8, txt2, CENTER + SMLSIZE + WHITE) -- XXLSIZE/DBLSIZE/MIDSIZE/SMLSIZE
  -- text below
  lcd.drawText(centerX + 8, centerY + 30, txt1, CENTER + txtSize + WHITE)

end

return self