-- Widget to show a telemetry Value (while fill better the widget area)
-- Offer Shmuely
-- Date: 2022
-- ver: 0.5

local app_name = "Value2"

-- imports
local WidgetToolsClass = loadScript("/WIDGETS/" .. app_name .. "/widget_tools.lua", "tcd")
local WidgetTransitionClass = loadScript("/WIDGETS/" .. app_name .. "/widget_transition.lua", "tcd")
local UtilsSensorsClass = loadScript("/WIDGETS/" .. app_name .. "/utils_sensors.lua", "tcd")

local options = {
    --{ "Source", SOURCE, 253 }, -- RSSI
    --{ "Source", SOURCE, 243 }, -- TxBt
    { "Source", SOURCE, 256 }, -- RxBt
    { "TextColor", COLOR, YELLOW }
}

--------------------------------------------------------------
local function log(s)
    print("appValue2: " .. s)
end
--------------------------------------------------------------

local function update(wgt, options)
  if (wgt == nil) then return end
    wgt.options = options

    wgt.lastValue = -1
    wgt.unit = ""
    wgt.precession = -1

    wgt.source_min_id = nil
    wgt.source_max_id = nil
    wgt.last_value = -1
    wgt.last_value_min = -1
    wgt.last_value_max = -1
    wgt.tools = WidgetToolsClass(app_name)
    wgt.transitions = WidgetTransitionClass(app_name)
    wgt.utils_sensors = UtilsSensorsClass(app_name)
end

local function create(zone, options)
    local wgt = {
        zone = zone,
        options = options,
    }

    update(wgt, options)
    return wgt
end

local function prettyPrintNone(val, precession)
    if val == nil then
        return "N/A (nil)"
    end

    if val == -1 then
        return "N/A"
    end

    if precession == 0 then
        return string.format("%2.0f", val)
    elseif precession == 1 then
        return string.format("%2.1f", val)
    elseif precession == 2 then
        return string.format("%2.2f", val)
    elseif precession == 3 then
        return string.format("%2.3f", val)
    end

    return string.format("%2f p?", val)
end

local function getFontSize(wgt, txt, num_lines_h)
    --wide_txt = string.gsub(txt, "[1-9]", "0")
    local wide_txt = txt
    --log(string.gsub("******* 12:34:56", "[1-9]", "0"))
    --log("wide_txt: " .. wide_txt)

    local w, h = lcd.sizeText(wide_txt, XXLSIZE)
    --log(string.format("XXLSIZE w: %d, h: %d, %s", w, h, time_str))
    if w < wgt.zone.w and h * num_lines_h <= wgt.zone.h then
        return XXLSIZE
    end

    w, h = lcd.sizeText(wide_txt, DBLSIZE)
    --log(string.format("DBLSIZE w: %d, h: %d, %s", w, h, time_str))
    if w < wgt.zone.w and h * num_lines_h <= wgt.zone.h then
        return DBLSIZE
    end

    w, h = lcd.sizeText(wide_txt, MIDSIZE)
    --log(string.format("MIDSIZE w: %d, h: %d, %s", w, h, time_str))
    if w < wgt.zone.w and h * num_lines_h <= wgt.zone.h then
        return MIDSIZE
    end

    --log(string.format("SMLSIZE w: %d, h: %d, %s", w, h, time_str))
    return SMLSIZE
end

local function getWidgetValue(wgt)
    local currentValue = wgt.lastValue

    log("Source: " .. wgt.options.Source .. ",currentValue: " .. currentValue)

    local fieldinfo = getFieldInfo(wgt.options.Source)
    local sourceName = getSourceName(wgt.options.Source)
    -- workaround for bug in getFiledInfo()
    if (sourceName == nil) then
        sourceName = "M/A"
    end

    sourceName = wgt.tools.cleanInvalidCharFromGetFiledInfo(sourceName)

    if (fieldinfo == nil) then
        log(string.format("getFieldInfo(%s)==nil", wgt.options.Source))
    else
        wgt.unit = wgt.tools.unitIdToString(fieldinfo.unit)
        wgt.precession = wgt.tools.getSensorPrecession(sourceName)

        log(string.format("getFieldInfo  id: %s", fieldinfo.id))
        log(string.format("getFieldInfo    sourceName: %s", sourceName))
        --log(string.format("getFieldInfo    curr: %2.1f", currentValue))
        --log(string.format("getFieldInfo    name: %s", fieldinfo.name))
        --log(string.format("getFieldInfo    desc: %s", fieldinfo.desc))
        log(string.format("getFieldInfo    idUnit: %s", fieldinfo.unit))
        --log(string.format("getFieldInfo    prec: %d", wgt.precession))
        --log(string.format("  txtUnit: %s", txtUnit))
    end

    if (wgt.tools.isTelemetryAvailable() == false) then
        log("overriding value with last_value: " .. wgt.last_value)
        return sourceName, wgt.last_value
    end

    -- try to get min/max value (if exist)
    local minValue
    local maxValue

    -- need to update id?
    if wgt.source_min_id == nil or wgt.source_max_id == nil then
        local source_min_obj = getFieldInfo(sourceName .. "-")
        --log("sourceName: " .. sourceName)
        if source_min_obj ~= nil then
            wgt.source_min_id = source_min_obj.id
            --log("source_min_id: " .. wgt.source_min_id)
        end
        local source_max_obj = getFieldInfo(sourceName .. "+")
        if source_min_obj ~= nil then
            wgt.source_max_id = source_max_obj.id
            --log("source_max_id: " .. wgt.source_max_id)
        end
    end
    --log("source_min_id: " .. wgt.source_min_id .. ", source_max_id: " .. wgt.source_max_id)

    if wgt.source_min_id ~= nil and wgt.source_max_id ~= nil then
        minValue = getValue(wgt.source_min_id)
        maxValue = getValue(wgt.source_max_id)
    end

    wgt.last_value = currentValue
    wgt.last_value_min = minValue
    wgt.last_value_max = maxValue

    if minValue == nil or maxValue == nil then
        log("min/max: [" .. sourceName .. "]  ?? < " .. currentValue .. " < ??")
    else
        log("min/max: [" .. sourceName .. "]" .. minValue .. " < " .. currentValue .. " < " .. maxValue)
    end
    return sourceName, currentValue

end

local function calculateData(wgt)
    local currentValue = getValue(wgt.options.Source)
    if (wgt.tools.isTelemetryAvailable() == true) then
        wgt.lastValue = currentValue
    end
end

local function background(wgt)
  if (wgt == nil) then return end

    calculateData(wgt)
    return
end

------------------------------------------------------------
local function refresh_app_mode(wgt, event, touchState)
    local sourceName, currentValue = getWidgetValue(wgt)
    local val_str = string.format("%2.1f %s", currentValue, wgt.unit)

    -- app mode (full screen)
    local zone_w = LCD_W
    local zone_h = LCD_H
    local ts_w, ts_h = lcd.sizeText(val_str, XXLSIZE)
    local dx = (zone_w - ts_w) / 2
    local dy = (zone_h - ts_h) / 2

    local no_telem_blink = 0
    if (wgt.tools.isTelemetryAvailable() == false) then
        no_telem_blink = INVERS + BLINK
    end

    local textColor = wgt.options.TextColor

    -- draw header
    lcd.drawText(10, 0, sourceName, DBLSIZE + textColor)

    -- draw value
    lcd.drawText(wgt.zone.x + dx, wgt.zone.y + dy, val_str, XXLSIZE + textColor + no_telem_blink)

    -- draw min value (if exist)
    if (wgt.last_value_min ~= -1) then
        val_str = string.format("min: %2.1f %s", wgt.last_value_min, wgt.unit)
        lcd.drawText(wgt.zone.x + 10, wgt.zone.y + LCD_H - 80, val_str, DBLSIZE + textColor + no_telem_blink)
    end

    -- draw max value (if exist)
    if (wgt.last_value_max ~= -1) then
        val_str = string.format("max: %2.1f %s", wgt.last_value_max, wgt.unit)
        lcd.drawText(wgt.zone.x + 10, wgt.zone.y + LCD_H - 40, val_str, DBLSIZE + textColor + no_telem_blink)
    end

end

local function refresh_widget_with_telem(wgt)
    local no_telem_blink = 0

    local sourceName, currentValue = getWidgetValue(wgt)

    local val_str = string.format("%s %s", prettyPrintNone(currentValue, wgt.precession), wgt.unit)
    local font_size = getFontSize(wgt, val_str, 1)

    local zone_w = wgt.zone.w
    local zone_h = wgt.zone.h

    local font_size_header = SMLSIZE

    local ts_w, ts_h = lcd.sizeText(val_str, font_size)
    local dx = (zone_w - ts_w) / 2
    local dy = (zone_h - ts_h) / 2
    --if (timer_info_h + ts_h > zone_h) and (zone_h < 50) then
    --  log(string.format("--- not enough height, force minimal spaces"))
    --  dy = 10
    --end

    local textColor = wgt.options.TextColor

    -- draw header
    lcd.drawText(wgt.zone.x, wgt.zone.y, sourceName, font_size_header + textColor)

    -- draw value
    lcd.drawText(wgt.zone.x + dx, wgt.zone.y + dy, val_str, font_size + textColor + no_telem_blink)

    if (wgt.last_value_min ~= -1 and wgt.last_value_max ~= -1) and (zone_h > 40 and zone_w > 100) then
        local val_str_minmax = string.format("%s...%s %s", prettyPrintNone(wgt.last_value_min, wgt.precession), prettyPrintNone(wgt.last_value_max, wgt.precession), wgt.unit)
        local ts_w, ts_h = lcd.sizeText(val_str_minmax, SMLSIZE)
        local dx = (wgt.zone.w - ts_w) / 2
        lcd.drawFilledRectangle(wgt.zone.x + dx, wgt.zone.y + zone_h - ts_h, ts_w, ts_h, LIGHTGREY)
        lcd.drawText(wgt.zone.x + dx, wgt.zone.y + zone_h - ts_h, val_str_minmax, SMLSIZE + textColor)
    end
end

local function refresh_widget_no_telem(wgt)
    -- end of flight

    local no_telem_blink = INVERS + BLINK
    local sourceName, currentValue = getWidgetValue(wgt)
    local val_str = string.format("%s %s", prettyPrintNone(currentValue, wgt.precession), wgt.unit)
    local font_size = getFontSize(wgt, val_str, 3)

    local zone_w = wgt.zone.w
    local zone_h = wgt.zone.h
    local font_size_header = SMLSIZE
    local ts_w, ts_h = lcd.sizeText(val_str, font_size)
    local dx = (zone_w - ts_w) / 2
    local dy = (zone_h - ts_h) * 0.2

    local textColor = wgt.options.TextColor

    -- draw header
    lcd.drawText(wgt.zone.x, wgt.zone.y, sourceName, font_size_header + textColor)

    -- draw value
    lcd.drawText(wgt.zone.x + dx, wgt.zone.y + dy, val_str, font_size + textColor + no_telem_blink)

    -- draw min max
    if (wgt.last_value_min ~= -1 and wgt.last_value_max ~= -1) and (zone_h > 40 and zone_w > 100) then
        local val_str_minmax1 = string.format("%s...%s %s", prettyPrintNone(wgt.last_value_min, wgt.precession), prettyPrintNone(wgt.last_value_max, wgt.precession), wgt.unit)
        local val_str_minmax2 = string.format("%s...%s", prettyPrintNone(wgt.last_value_min, wgt.precession), prettyPrintNone(wgt.last_value_max, wgt.precession)) --, wgt.unit)

        local font_size_minmax1 = getFontSize(wgt, val_str_minmax1, 2)
        local font_size_minmax2 = getFontSize(wgt, val_str_minmax2, 2)

        local ts_w1, ts_h1 = lcd.sizeText(val_str_minmax1, font_size_minmax1)
        local ts_w2, ts_h2 = lcd.sizeText(val_str_minmax2, font_size_minmax2)
        local val_str_minmax
        local font_size_minmax
        local ts_w
        --local ts_h
        if ts_w1 < zone_w then
            val_str_minmax = val_str_minmax1
            font_size_minmax = font_size_minmax1
            ts_w = math.min(ts_w1,wgt.zone.w)
            --ts_h = ts_h1
        else
            val_str_minmax = val_str_minmax2
            font_size_minmax = font_size_minmax2
            ts_w = math.min(ts_w2,wgt.zone.w)
            --ts_h = ts_h2
        end
        local dx = (wgt.zone.w - ts_w) / 2
        lcd.drawFilledRectangle(wgt.zone.x + dx - 5, wgt.zone.y + dy + ts_h, ts_w + 10, ts_h1, LIGHTGREY)
        lcd.drawText(wgt.zone.x + dx, wgt.zone.y + dy + ts_h, val_str_minmax, font_size_minmax + textColor)
        --lcd.drawText(wgt.zone.x + 10, wgt.zone.y + dy + ts_h, val_str_minmax, font_size_minmax + textColor)
    end
end

function refresh(wgt, event, touchState)
    if (wgt == nil) then return end
    if (wgt.options == nil) then return end

    calculateData(wgt)

    if (event ~= nil) then
        -- full screen (app mode)
        refresh_app_mode(wgt, event, touchState)
    else
        -- regular screen
        log(string.format("isTelemetryAvailable: %s", wgt.tools.isTelemetryAvailable()))
        local transitionState
        if (wgt.tools.isTelemetryAvailable()) then
            transitionState = "a"
            --refresh_widget_with_telem(wgt)
        else
            transitionState = "b"
            --refresh_widget_no_telem(wgt)
        end
        wgt.transitions.areaTransition(wgt, transitionState, refresh_widget_with_telem, refresh_widget_no_telem)
    end

end

return { name = app_name, options = options, create = create, update = update, background = background, refresh = refresh }
