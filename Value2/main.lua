-- Horus Widget that show the Value while fill better the widget area
-- Offer Shmuely
-- Date: 2019
-- ver: 0.1

local unitToString = { "V", "A", "mA", "kts", "m/s", "f/s", "km/h", "km/h", "mph", "m", "m", "f", "°C", "°C", "°F", "%", "mAh", "W", "mW", "dB", "rpms", "g", "°", "Rad" }

local options = {
  { "Source", SOURCE, 1 },
  { "TextColor", COLOR, YELLOW }
}

local function create(zone, options)
  local wgt = {
    zone = zone,
    options = options,
    isDataAvailable = 0,
    no_telem_blink = 0,
    lastValue = 0,
    unit = "---",
  }
  return wgt
end

local function update(wgt, options)
  if (wgt == nil) then return end
  wgt.options = options
end

local function getWidgetValue(wgt)
  local currentValue = getValue(wgt.options.Source) / 10.24
  print(string.format("%2.1fV", currentValue)) -- ???
  print("Source: " .. wgt.options.Source .. ",currentValue: " .. currentValue)

  local fieldinfo = getFieldInfo(wgt.options.Source)
  if (fieldinfo == nil) then
    print(string.format("getFieldInfo(%s)==nil", wgt.options.Source))
  else
    local txt = fieldinfo['name'] .. "(id:" .. fieldinfo['id']
      .. ")"
      .. "=" .. fieldValue
      .. txtUnit
      .. " [desc: " .. fieldinfo['desc'] .. "]"


    print("getFieldInfo()="   .. txt)
    --print("getFieldInfo().name:" .. fieldinfo.name)
    --print("getFieldInfo().desc:" .. fieldinfo.desc)

    local txtUnit = "---"
    if (fieldinfo['unit']) then
      local idUnit = fieldinfo['unit']

      if (idUnit > 0 and idUnit < #unitToString) then
        print("idUnit: " .. idUnit)
        txtUnit = unitToString[idUnit]
        print("txtUnit: " .. txtUnit)
        wgt.unit = txtUnit
      end
    end


  end

  if (currentValue == nil)
  then
    return string.format("%2.1f %s", wgt.lastValue , wgt.unit)
  end
  return string.format("%2.1f %s", currentValue, wgt.unit)
end

local function calculateData(wgt)

  --Todo: check if table and return
  local currentValue = getValue(wgt.options.Source) / 10.24
  --print(wgt.options.Source .. "] currentValue:" .. currentValue .. "-" .. getValue(wgt.options.Source))
  if (currentValue == nil or currentValue == 0)
  then
    wgt.isDataAvailable = false
    wgt.no_telem_blink = INVERS + BLINK
    wgt.lastValue = 5 --???
    return
  end

  wgt.isDataAvailable = true
  wgt.no_telem_blink = 0
  wgt.lastValue = currentValue

end

local function background(wgt)
  if (wgt == nil) then return end

  calculateData(wgt)
  return
end

------------------------------------------------------------

-- This size is for top bar widgets
local function refreshZoneTiny(wgt)
  lcd.drawSource(wgt.zone.x, wgt.zone.y, wgt.options.Source, SMLSIZE + CUSTOM_COLOR)
  --lcd.drawNumber(wgt.zone.x, wgt.zone.y + 20, getWidgetValue(wgt), SMLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x, wgt.zone.y + 20, getWidgetValue(wgt), SMLSIZE + CUSTOM_COLOR)
end

--- Size is 160x32 1/8th
local function refreshZoneSmall(wgt)
  lcd.drawSource(wgt.zone.x, wgt.zone.y, wgt.options.Source, CUSTOM_COLOR)
  --lcd.drawNumber(wgt.zone.x + wgt.zone.w, wgt.zone.y, getWidgetValue(wgt), DBLSIZE + CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x + wgt.zone.w, wgt.zone.y, getWidgetValue(wgt), DBLSIZE + CUSTOM_COLOR + RIGHT)
  return
end

--- Size is 180x70 1/4th  (with sliders/trim)
--- Size is 225x98 1/4th  (no sliders/trim)
local function refreshZoneMedium(wgt)
  lcd.drawSource(wgt.zone.x, wgt.zone.y, wgt.options.Source, CUSTOM_COLOR)
  --lcd.drawNumber(wgt.zone.x, wgt.zone.y + 10, getWidgetValue(wgt), XXLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x, wgt.zone.y + 10, getWidgetValue(wgt), XXLSIZE + CUSTOM_COLOR)
end

--- Size is 192x152 1/2
local function refreshZoneLarge(wgt)
  lcd.drawSource(wgt.zone.x, wgt.zone.y, wgt.options.Source, CUSTOM_COLOR)
  --lcd.drawNumber(wgt.zone.x, wgt.zone.y + 15, getWidgetValue(wgt), XXLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x, wgt.zone.y + 15, getWidgetValue(wgt), XXLSIZE + CUSTOM_COLOR)
end

--- Size is 390x172 1/1
--- Size is 460x252 1/1 (no sliders/trim/topbar)
local function refreshZoneXLarge(wgt)
  lcd.drawSource(wgt.zone.x, wgt.zone.y + 15, wgt.options.Source, CUSTOM_COLOR)
  --lcd.drawNumber(wgt.zone.x, wgt.zone.y + 75, getWidgetValue(wgt), XXLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x, wgt.zone.y + 75, getWidgetValue(wgt), XXLSIZE + CUSTOM_COLOR)
end

function refresh(wgt)

  if (wgt == nil) then return end
  if (wgt.options == nil) then return end

  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)

  calculateData(wgt)

  if     wgt.zone.w > 380 and wgt.zone.h > 165 then refreshZoneXLarge(wgt)
  elseif wgt.zone.w > 180 and wgt.zone.h > 145 then refreshZoneLarge(wgt)
  elseif wgt.zone.w > 170 and wgt.zone.h > 65  then refreshZoneMedium(wgt)
  elseif wgt.zone.w > 150 and wgt.zone.h > 28  then refreshZoneSmall(wgt)
  elseif wgt.zone.w > 65  and wgt.zone.h > 35  then refreshZoneTiny(wgt)
  end
end

return { name = "Value2", options = options, create = create, update = update, background = background, refresh = refresh }
