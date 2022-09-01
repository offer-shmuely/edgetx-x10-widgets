-- Horus Widget that show the Value while fill better the widget area
-- Offer Shmuely
-- Date: 2022
-- ver: 0.3


local app_name = "Value2"

-- imports
local ToolsClass = loadScript("/WIDGETS/" .. app_name .. "/tools.lua")

-- consts
local UNIT_ID_TO_STRING = { "V", "A", "mA", "kts", "m/s", "f/s", "km/h", "mph", "m", "f", "°C", "°F", "%", "mAh", "W", "mW", "dB", "rpm", "g", "°", "rad", "ml", "fOz", "ml/m", "Hz", "uS", "km" }


local options = {
  --{ "Source", SOURCE, 253 }, -- RSSI
  --{ "Source", SOURCE, 243 }, -- TxBt
  { "Source", SOURCE, 256 }, -- RxBt
  { "TextColor", COLOR, YELLOW }
}


--------------------------------------------------------------
local function log(s)
  --return;
  print("appValue2: " .. s)
end
--------------------------------------------------------------

local function update(wgt, options)
  if (wgt == nil) then return end
  wgt.options = options
  wgt.tools = ToolsClass()
end

local function create(zone, options)
  local wgt = {
    zone = zone,
    options = options,
    lastValue = -1,
    unit = "---",
  }
  update(wgt, options)
  return wgt
end

local function getFontSize(wgt, txt)
  --wide_txt = string.gsub(txt, "[1-9]", "0")
  local wide_txt = txt
  --log(string.gsub("******* 12:34:56", "[1-9]", "0"))
  log("wide_txt: " .. wide_txt)

  local w,h = lcd.sizeText(wide_txt, XXLSIZE)
  log(string.format("XXLSIZE w: %d, h: %d, %s", w, h, time_str))
  if w < wgt.zone.w and h <= wgt.zone.h then
    return XXLSIZE
  end

  w,h = lcd.sizeText(wide_txt, DBLSIZE)
  log(string.format("DBLSIZE w: %d, h: %d, %s", w, h, time_str))
  if w < wgt.zone.w and h <= wgt.zone.h then
    return DBLSIZE
  end

  w,h = lcd.sizeText(wide_txt, MIDSIZE)
  log(string.format("MIDSIZE w: %d, h: %d, %s", w, h, time_str))
  if w < wgt.zone.w and h <= wgt.zone.h then
    return MIDSIZE
  end

  log(string.format("SMLSIZE w: %d, h: %d, %s", w, h, time_str))
  return SMLSIZE
end

local function getWidgetValue(wgt)
  local currentValue = wgt.lastValue

  log(string.format("%2.1fV", currentValue)) -- ???
  log("Source: " .. wgt.options.Source .. ",currentValue: " .. currentValue)

  local fieldinfo = getFieldInfo(wgt.options.Source)
  local sourceName = getSourceName(wgt.options.Source)
  if (fieldinfo == nil) then
    log(string.format("getFieldInfo(%s)==nil", wgt.options.Source))
  else
    local txtUnit = "---"
    if (fieldinfo.unit) then
      if (fieldinfo.unit > 0 and fieldinfo.unit < #UNIT_ID_TO_STRING) then
        log("idUnit: " .. fieldinfo.unit)
        txtUnit = UNIT_ID_TO_STRING[fieldinfo.unit]
        log("txtUnit: " .. txtUnit)
        wgt.unit = txtUnit
      end
    end
    --log(string.format("id: %s", fieldinfo.id))
    --log(string.format("  sourceName: %s", sourceName))
    --log(string.format("  curr: %2.1f", currentValue))
    --log(string.format("  name: %s", fieldinfo.name))
    --log(string.format("  desc: %s", fieldinfo.desc))
    --log(string.format("  idUnit: %s", fieldinfo.unit))
    --log(string.format("  txtUnit: %s", txtUnit))
  end

  return sourceName, string.format("%2.1f %s", currentValue, wgt.unit)
end

local function calculateData(wgt)
  local currentValue = getValue(wgt.options.Source)
  if (wgt.tools.isTelemetryAvailable() == false) then
    return
  end

  wgt.lastValue = currentValue
end

local function background(wgt)
  if (wgt == nil) then return end

  calculateData(wgt)
  return
end

------------------------------------------------------------
local function refresh_app_mode(wgt, event, touchState, field_header)
  local field_header, val_str = getWidgetValue(wgt)

  -- app mode (full screen)
  local zone_w = 460
  local zone_h = 252
  local dx = (zone_w - ts_w) /2
  local dy = (zone_h - ts_h) /2

  local no_telem_blink = 0
  if (wgt.tools.isTelemetryAvailable() ==false) then
    no_telem_blink = INVERS + BLINK
  end

  local textColor = wgt.options.TextColor

  -- draw header
  lcd.drawText(0, 0, field_header, DBLSIZE + textColor)

  -- draw value
  lcd.drawText(wgt.zone.x + dx, wgt.zone.y + dy, val_str, XXLSIZE + textColor + no_telem_blink)


  ---- try to get min/max value (if exist)
  --local minValue = nil
  --local maxValue = nil
  --if source_min_id == nil or source_max_id == nil then
  --  source_min_id = getFieldInfo(sourceName .. "-").id
  --  source_max_id = getFieldInfo(sourceName .. "+").id
  --end
  --if source_min_id ~= nil and source_max_id ~= nil then
  --  minValue = getValue(source_min_id)
  --  maxValue = getValue(source_max_id)
  --end

end


local function refresh_widget(wgt)
  local field_header, val_str = getWidgetValue(wgt)
  local font_size = getFontSize(wgt, val_str)

  local zone_w = wgt.zone.w
  local zone_h = wgt.zone.h

  font_size_header = SMLSIZE

  local ts_w,ts_h = lcd.sizeText(val_str, font_size)
  local dx = (zone_w - ts_w) /2
  local dy = (zone_h - ts_h) /2
  --if (timer_info_h + ts_h > zone_h) and (zone_h < 50) then
  --  log(string.format("--- not enough height, force minimal spaces"))
  --  dy = 10
  --end

  local no_telem_blink = 0
  if (wgt.tools.isTelemetryAvailable() ==false) then
    no_telem_blink = INVERS + BLINK
  end

  textColor = wgt.options.TextColor

  -- draw header
  lcd.drawText(wgt.zone.x, wgt.zone.y, field_header, font_size_header + textColor)

  -- draw value
  lcd.drawText(wgt.zone.x + dx, wgt.zone.y + dy, val_str, font_size + textColor + no_telem_blink)

end

function refresh(wgt)
  if (wgt == nil) then return end
  if (wgt.options == nil) then return end

  calculateData(wgt)

  if (event ~= nil) then
    -- full screen (app mode)
    refresh_app_mode(wgt, event, touchState, field_header)
  else
    -- regular screen
    refresh_widget(wgt)
  end

end

return { name = "Value2", options = options, create = create, update = update, background = background, refresh = refresh }
