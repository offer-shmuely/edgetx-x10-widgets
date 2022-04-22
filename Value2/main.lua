-- Horus Widget that show the Value while fill better the widget area
-- Offer Shmuely
-- Date: 2022
-- ver: 0.2


local options = {
  --{ "Source", SOURCE, 251 }, -- RSSI
  { "Source", SOURCE, 254 }, -- RxBt
  { "TextColor", COLOR, YELLOW }
}

local UNIT_ID_TO_STRING = { "V", "A", "mA", "kts", "m/s", "f/s", "km/h", "mph", "m", "f", "°C", "°F", "%", "mAh", "W", "mW", "dB", "rpm", "g", "°", "rad", "ml", "fOz", "ml/m", "Hz", "uS", "km" }

--------------------------------------------------------------
local function log(s)
  return;
  --print("Batt_A1: " .. s)
end
--------------------------------------------------------------

local function create(zone, options)
  local wgt = {
    zone = zone,
    options = options,
    isDataAvailable = 0,
    no_telem_blink = 0,
    lastValue = -1,
    unit = "---",
  }
  return wgt
end

local function update(wgt, options)
  if (wgt == nil) then return end
  wgt.options = options
end

local function getFontSize(wgt, txt)
  --wide_txt = string.gsub(txt, "[1-9]", "0")
  wide_txt = txt
  --log(string.gsub("******* 12:34:56", "[1-9]", "0"))
  log("wide_txt: " .. wide_txt)

  local w,h = lcd.sizeText(wide_txt, XXLSIZE)
  log(string.format("XXLSIZE w: %d, h: %d, %s", w,h, time_str))
  if w < wgt.zone.w and h <= wgt.zone.h then
    return XXLSIZE
  end

  w,h = lcd.sizeText(wide_txt, DBLSIZE)
  log(string.format("DBLSIZE w: %d, h: %d, %s", w,h, time_str))
  if w < wgt.zone.w and h <= wgt.zone.h then
    return DBLSIZE
  end

  w,h = lcd.sizeText(wide_txt, MIDSIZE)
  log(string.format("MIDSIZE w: %d, h: %d, %s", w,h, time_str))
  if w < wgt.zone.w and h <= wgt.zone.h then
    return MIDSIZE
  end

  log(string.format("SMLSIZE w: %d, h: %d, %s", w,h, time_str))
  return SMLSIZE
end

local function getWidgetValue(wgt)
  local currentValue = getValue(wgt.options.Source)

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


    log("getFieldInfo()="   .. txt)
    log("getFieldInfo().name:" .. fieldinfo.name)
    log("getFieldInfo().desc:" .. fieldinfo.desc)

    local txtUnit = "---"
    if (fieldinfo.unit) then

      if (fieldinfo.unit > 0 and fieldinfo.unit < #UNIT_ID_TO_STRING) then
        log("idUnit: " .. fieldinfo.unit)
        txtUnit = UNIT_ID_TO_STRING[fieldinfo.unit]
        log("txtUnit: " .. txtUnit)
        wgt.unit = txtUnit
      end
    end
    log(string.format("id: %s", fieldinfo.id))
    log(string.format("  sourceName: %s", sourceName))
    log(string.format("  curr: %2.1f", currentValue))
    log(string.format("  name: %s", fieldinfo.name))
    log(string.format("  desc: %s", fieldinfo.desc))
    log(string.format("  idUnit: %s", fieldinfo.unit))
    log(string.format("  txtUnit: %s", txtUnit))


  end

  if (currentValue == nil)
  then
    return fieldinfo.name, string.format("%2.1f %s", wgt.lastValue , wgt.unit)
  end
  return fieldinfo.name, string.format("%2.1f %s", currentValue, wgt.unit)
end

local function calculateData(wgt)

  --Todo: check if table and return
  local currentValue = getValue(wgt.options.Source) / 10.24
  --log(wgt.options.Source .. "] currentValue:" .. currentValue .. "-" .. getValue(wgt.options.Source))
  if (currentValue == nil or currentValue == 0)
  then
    wgt.isDataAvailable = false
    wgt.no_telem_blink = INVERS + BLINK
    wgt.lastValue = -1 --???
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

function refresh(wgt)
  if (wgt == nil) then return end
  if (wgt.options == nil) then return end

  calculateData(wgt)

  local field_header, val_str = getWidgetValue(wgt)
  local font_size = getFontSize(wgt, val_str)

  local zone_w = wgt.zone.w
  local zone_h = wgt.zone.h

  font_size_header = SMLSIZE
  if (event ~= nil) then
    -- app mode (full screen)
    font_size = XXLSIZE
    font_size_header = DBLSIZE
    zone_w = 460
    zone_h = 252
  end

  local ts_w,ts_h = lcd.sizeText(val_str, font_size)
  local dx = (zone_w - ts_w) /2
  local dy = (zone_h - ts_h) /2
  --if (timer_info_h + ts_h > zone_h) and (zone_h < 50) then
  --  log(string.format("--- not enough height, force minimal spaces"))
  --  dy = 10
  --end

  textColor = wgt.options.TextColor

  -- draw header
  lcd.drawText(wgt.zone.x, wgt.zone.y, field_header, font_size_header + textColor)

  -- draw value
  lcd.drawText(wgt.zone.x + dx, wgt.zone.y + dy, val_str, font_size + textColor)

  --unit_str = ???
  --font_size_units = ???
  -- draw units
  --lcd.drawText(wgt.zone.x + dx, wgt.zone.y + dy, unit_str, font_size_units + textColor)
end

return { name = "Value2", options = options, create = create, update = update, background = background, refresh = refresh }
