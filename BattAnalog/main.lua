---- #########################################################################
---- #                                                                       #
---- # Telemetry Widget script for FrSky Horus/RadioMaster TX16s             #
---- # Copyright (C) EdgeTX                                                  #
-----#                                                                       #
---- # License GPLv2: http://www.gnu.org/licenses/gpl-2.0.html               #
---- #                                                                       #
---- # This program is free software; you can redistribute it and/or modify  #
---- # it under the terms of the GNU General Public License version 2 as     #
---- # published by the Free Software Foundation.                            #
---- #                                                                       #
---- # This program is distributed in the hope that it will be useful        #
---- # but WITHOUT ANY WARRANTY; without even the implied warranty of        #
---- # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
---- # GNU General Public License for more details.                          #
---- #                                                                       #
---- #########################################################################

-- This widget display a graphical representation of a Lipo/Li-ion (not other types) battery level,
-- it will automatically detect the cell amount of the battery.
-- it will take a lipo/li-ion voltage that received as a single value (as opposed to multi cell values send while using FLVSS liPo Voltage Sensor)
-- common sources are:
--   * Transmitter Battery
--   * FrSky VFAS
--   * A1/A2 analog voltage
--   * mini quad flight controller
--   * radio-master 168
--   * OMP m2 heli


-- Widget to display the levels of Lipo battery from single analog source
-- Offer Shmuely
-- Date: 2022
-- ver: 0.4

local _options = {
  { "Sensor"            , SOURCE, 0      }, -- default to 'A1'
  { "Color"             , COLOR , YELLOW },
  { "Show_Total_Voltage", BOOL  , 0      }, -- 0=Show as average Lipo cell level, 1=show the total voltage (voltage as is)
  { "Lithium_Ion"       , BOOL  , 0      }, -- 0=LIPO battery, 1=LI-ION (18650/21500)
}

-- Data gathered from commercial lipo sensors
local _lipoPercentListSplit = {
  { 3, 0 }, { 3.093, 1 }, { 3.196, 2 }, { 3.301, 3 }, { 3.401, 4 }, { 3.477, 5 }, { 3.544, 6 }, { 3.601, 7 }, { 3.637, 8 }, { 3.664, 9 }, { 3.679, 10 }, { 3.683, 11 }, { 3.689, 12 }, { 3.692, 13 },
  { 3.705, 14 }, { 3.71, 15 }, { 3.713, 16 }, { 3.715, 17 }, { 3.72, 18 }, { 3.731, 19 }, { 3.735, 20 }, { 3.744, 21 }, { 3.753, 22 }, { 3.756, 23 }, { 3.758, 24 }, { 3.762, 25 }, { 3.767, 26 },
  { 3.774, 27 }, { 3.78, 28 }, { 3.783, 29 }, { 3.786, 30 }, { 3.789, 31 }, { 3.794, 32 }, { 3.797, 33 }, { 3.8, 34 }, { 3.802, 35 }, { 3.805, 36 }, { 3.808, 37 }, { 3.811, 38 }, { 3.815, 39 },
  { 3.818, 40 }, { 3.822, 41 }, { 3.825, 42 }, { 3.829, 43 }, { 3.833, 44 }, { 3.836, 45 }, { 3.84, 46 }, { 3.843, 47 }, { 3.847, 48 }, { 3.85, 49 }, { 3.854, 50 }, { 3.857, 51 }, { 3.86, 52 },
  { 3.863, 53 }, { 3.866, 54 }, { 3.87, 55 }, { 3.874, 56 }, { 3.879, 57 }, { 3.888, 58 }, { 3.893, 59 }, { 3.897, 60 }, { 3.902, 61 }, { 3.906, 62 }, { 3.911, 63 }, { 3.918, 64 },
  { 3.923, 65 }, { 3.928, 66 }, { 3.939, 67 }, { 3.943, 68 }, { 3.949, 69 }, { 3.955, 70 }, { 3.961, 71 }, { 3.968, 72 }, { 3.974, 73 }, { 3.981, 74 }, { 3.987, 75 }, { 3.994, 76 },
  { 4.001, 77 }, { 4.007, 78 }, { 4.014, 79 }, { 4.021, 80 }, { 4.029, 81 }, { 4.036, 82 }, { 4.044, 83 }, { 4.052, 84 }, { 4.062, 85 }, { 4.074, 86 }, { 4.085, 87 }, { 4.095, 88 },
  { 4.105, 89 }, { 4.111, 90 }, { 4.116, 91 }, { 4.12, 92 }, { 4.125, 93 }, { 4.129, 94 }, { 4.135, 95 }, { 4.145, 96 }, { 4.176, 97 }, { 4.179, 98 }, { 4.193, 99 }, { 4.2, 100 },
}

-- from: https://electric-scooter.guide/guides/electric-scooter-battery-voltage-chart/
local _liionPercentListSplit_old = {
  {3.00,   0 },{3.01,   1 },{3.02,   2 },{3.03,   3 },{3.04,   4 },
  {3.06,   5 },{3.07,   6 },{3.08,   7 },{3.09,   8 },{3.10,   9 },
  {3.12,  10 },{3.13,  11 },{3.14,  12 },{3.15,  13 },{3.16,  14 },
  {3.18,  15 },{3.19,  16 },{3.20,  17 },{3.21,  18 },{3.22,  19 },
  {3.24,  20 },{3.25,  21 },{3.26,  22 },{3.27,  23 },{3.28,  24 },
  {3.30,  25 },{3.31,  26 },{3.32,  27 },{3.33,  28 },{3.34,  29 },
  {3.36,  30 },{3.37,  31 },{3.38,  32 },{3.39,  33 },{3.40,  34 },
  {3.42,  35 },{3.43,  36 },{3.44,  37 },{3.45,  38 },{3.46,  39 },
  {3.48,  40 },{3.49,  41 },{3.50,  42 },{3.51,  43 },{3.52,  44 },
  {3.54,  45 },{3.55,  46 },{3.56,  47 },{3.57,  48 },{3.58,  49 },
  {3.60,  50 },{3.61,  51 },{3.62,  52 },{3.63,  53 },{3.64,  54 },
  {3.66,  55 },{3.67,  56 },{3.68,  57 },{3.69,  58 },{3.70,  59 },
  {3.72,  60 },{3.73,  61 },{3.74,  62 },{3.75,  63 },{3.76,  64 },
  {3.78,  65 },{3.79,  66 },{3.80,  67 },{3.81,  68 },{3.82,  69 },
  {3.84,  70 },{3.85,  71 },{3.86,  72 },{3.87,  73 },{3.88,  74 },
  {3.90,  75 },{3.91,  76 },{3.92,  77 },{3.93,  78 },{3.94,  79 },
  {3.96,  80 },{3.97,  81 },{3.98,  82 },{3.99,  83 },{4.00,  84 },
  {4.02,  85 },{4.03,  86 },{4.04,  87 },{4.05,  88 },{4.06,  89 },
  {4.08,  90 },{4.09,  91 },
  {4.10,  100 }

  --{ {4.08,  90 },{4.09,  91 },{4.10,  92 },{4.11,  93 },{4.12,  94 } },
  --{ {4.14,  95 },{4.15,  96 },{4.16,  97 },{4.17,  98 },{4.18,  99 } },
  --{ {4.20, 100 },{4.21, 101 },{4.22, 102 },{4.23, 103 },{4.24, 104 } },
}

local _liionPercentListSplit = {
  {2.80,  0 },{2.85,  1 },{2.89,  2 },{2.92,  3 },{2.94,  4 },
  {2.96,  5 },{2.97,  6 },{2.98,  7 },{2.99,  8 },{3.00,  9 },
  {3.01, 10 },{3.02, 11 },{3.03, 12 },{3.04, 13 },{3.05, 14 },
  {3.06, 15 },{3.07, 16 },{3.08, 17 },{3.09, 18 },{3.10, 19 },
  {3.11, 20 },{3.12, 21 },{3.13, 22 },{3.14, 23 },{3.15, 24 },
  {3.16, 25 },{3.17, 26 },{3.18, 27 },{3.19, 28 },{3.20, 29 },
  {3.21, 30 },{3.22, 31 },{3.23, 32 },{3.24, 33 },{3.25, 34 },
  {3.26, 35 },{3.27, 36 },{3.28, 37 },{3.29, 38 },{3.30, 39 },
  {3.31, 40 },{3.32, 41 },{3.33, 42 },{3.34, 43 },{3.35, 44 },
  {3.36, 45 },{3.37, 46 },{3.38, 47 },{3.39, 48 },{3.40, 49 },
  {3.41, 50 },{3.42, 51 },{3.43, 52 },{3.44, 53 },{3.45, 54 },
  {3.46, 55 },{3.47, 56 },{3.48, 57 },{3.49, 58 },{3.50, 59 },
  {3.51, 60 },{3.52, 61 },{3.53, 62 },{3.54, 63 },{3.55, 64 },
  {3.56, 65 },{3.57, 66 },{3.58, 67 },{3.59, 68 },{3.60, 69 },
  {3.61, 70 },{3.62, 71 },{3.63, 72 },{3.64, 73 },{3.65, 74 },
  {3.66, 75 },{3.67, 76 },{3.68, 77 },{3.69, 78 },{3.70, 79 },
  {3.71, 80 },{3.72, 81 },{3.73, 82 },{3.74, 83 },{3.75, 84 },
  {3.76, 85 },{3.77, 86 },{3.78, 87 },{3.79, 88 },{3.80, 89 },
  {3.81, 90 },{3.83, 91 },{3.83, 92 },{3.84, 93 },{3.85, 94 },
  {3.87, 95 },{3.89, 96 },{3.92, 97 },{3.96, 98 },{4.04, 99 },
  {4.10, 100}
  }


local defaultSensor = "RxBt" -- RxBt / A1 / A3/ VFAS /RxBt

--------------------------------------------------------------
local function log(s)
  print("BattAnalog: " .. s)
end
--------------------------------------------------------------

local function update(wgt, options)
  if (wgt == nil) then
    return
  end

  wgt.options = options

  -- use default if user did not set, So widget is operational on "select widget"
  if wgt.options.Sensor == 0 then
    wgt.options.Sensor = defaultSensor
  end

  wgt.options.source_name = ""
  if (type(wgt.options.Sensor) == "number") then
    local source_name = getSourceName(wgt.options.Sensor)
    if (source_name ~= nil) then
      if string.byte(string.sub(source_name,1,1)) > 127 then
        source_name = string.sub(source_name,2,-1) -- ???? why?
      end
      if string.byte(string.sub(source_name,1,1)) > 127 then
        source_name = string.sub(source_name,2,-1) -- ???? why?
      end
      log(string.format("source_name: %s", source_name))
      wgt.options.source_name = source_name
    end
  end

  wgt.options.Show_Total_Voltage = wgt.options.Show_Total_Voltage % 2 -- modulo due to bug that cause the value to be other than 0|1

  log(string.format("wgt.options.lithium_ion: %s", wgt.options.lithium_ion))
end


local function create(zone, options)
  local wgt = {
    zone = zone,
    options = options,
    counter = 0,
    text_color = 0,

    telemResetCount = 0,
    telemResetLowestMinRSSI = 101,
    no_telem_blink = 0,
    isDataAvailable = 0,
    vMax = 0,
    vMin = 0,
    vTotalLive = 0,
    vPercent = 0,

    cellCount = 0,
    vCellLive = 0,

    mainValue = 0,
    secondaryValue = 0
  }

  update(wgt, options)
  return wgt
end

-- clear old telemetry data upon reset event
local function onTelemetryResetEvent(wgt)
  wgt.telemResetCount = wgt.telemResetCount + 1

  wgt.vTotalLive = 0
  wgt.vCellLive = 0
  wgt.vMin = 99
  wgt.vMax = 0
  wgt.cellCount = 0
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
  if (currMinRSSI == nil) then
    return
  end
  if (currMinRSSI == wgt.telemResetLowestMinRSSI) then
    return
  end

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

--- This function return the percentage remaining in a single Lipo cel
local function getCellPercent(wgt, cellValue)
  if cellValue == nil then
    return 0
  end

  -- in case somehow voltage is higher, don't return nil
  if (cellValue > 4.2) then
    return 100
  end

  local _percentListSplit = _lipoPercentListSplit
  if wgt.options.lithium_ion == 1 then
    _percentListSplit = _liionPercentListSplit
  end
  
  for i, v in ipairs(_percentListSplit) do
    if v[1] >= cellValue then
      result = v[2]
      break
    end
  end
  return result
end

local function calcCellCount(wgt, singleVoltage)
  if singleVoltage < 4.3 then
    return 1
  elseif singleVoltage < 8.6 then
    return 2
  elseif singleVoltage < 12.9 then
    return 3
  elseif singleVoltage < 17.2 then
    return 4
  elseif singleVoltage < 21.5 then
    return 5
  elseif singleVoltage < 25.8 then
    return 6
  elseif singleVoltage < 30.1 then
    return 7
  elseif singleVoltage < 34.4 then
    return 8
  elseif singleVoltage < 38.7 then
    return 9
  elseif singleVoltage < 43.0 then
    return 10
  elseif singleVoltage < 47.3 then
    return 11
  elseif singleVoltage < 51.6 then
    return 12
  end

  log("no match found" .. singleVoltage)
  return 1
end

--- This function returns a table with cels values
local function calculateBatteryData(wgt)

  local v = getValue(wgt.options.Sensor)
  local fieldinfo = getFieldInfo(wgt.options.Sensor)
  log("wgt.options.Sensor: " .. wgt.options.Sensor)

  if type(v) == "table" then
    -- multi cell values using FLVSS liPo Voltage Sensor
    if (#v > 1) then
      wgt.isDataAvailable = false
      local txt = "FLVSS liPo Voltage Sensor, not supported"
      log(txt)
      return
    end
  elseif v ~= nil and v >= 1 then
    -- single cell or VFAS lipo sensor
    if fieldinfo then
      log(wgt.options.source_name .. ", value: " .. fieldinfo.name .. "=" .. v)
    else
      log("only one cell using Ax lipo sensor")
    end
  else
    -- no telemetry available
    wgt.isDataAvailable = false
    if fieldinfo then
      log("no telemetry data: " .. fieldinfo['name'] .. "=??")
    else
      log("no telemetry data")
    end
    return
  end

  local newCellCount = calcCellCount(wgt, v)
  log("newCellCount: " .. newCellCount)

  -- this is necessary for simu where cell-count can change
  if newCellCount ~= wgt.cellCount then
    wgt.vMin = 99
    wgt.vMax = 0
  end

  -- calc highest of all cells
  if v > wgt.vMax then
    wgt.vMax = v
  end

  wgt.cellCount = newCellCount
  wgt.vTotalLive = v
  wgt.vCellLive = wgt.vTotalLive / wgt.cellCount
  wgt.vPercent = getCellPercent(wgt, wgt.vCellLive)

  -- log("wgt.vCellLive: ".. wgt.vCellLive)
  -- log("wgt.vPercent: ".. wgt.vPercent)

  -- mainValue
  if wgt.options.Show_Total_Voltage == 0 then
    wgt.mainValue = wgt.vCellLive
    wgt.secondaryValue = wgt.vTotalLive
  elseif wgt.options.Show_Total_Voltage == 1 then
    wgt.mainValue = wgt.vTotalLive
    wgt.secondaryValue = wgt.vCellLive
  else
    wgt.mainValue = "-1"
    wgt.secondaryValue = "-2"
  end

  --- calc lowest main voltage
  if wgt.mainValue < wgt.vMin and wgt.mainValue > 1 then
    -- min 1v to consider a valid reading
    wgt.vMin = wgt.mainValue
  end

  wgt.isDataAvailable = true

end


-- color for battery
-- This function returns green at 100%, red bellow 30% and graduate in between
local function getPercentColor(percent)
  if percent < 30 then
    return lcd.RGB(0xff, 0, 0)
  else
    g = math.floor(0xdf * percent / 100)
    r = 0xdf - g
    return lcd.RGB(r, g, 0)
  end
end

-- color for cell
-- This function returns green at gvalue, red at rvalue and graduate in between
local function getRangeColor(value, green_value, red_value)
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
    if value > green_value then
      return lcd.RGB(0, 0xdf, 0)
    end
    if value < red_value then
      return lcd.RGB(0xdf, 0, 0)
    end
    r = math.floor(0xdf * (value - green_value) / range)
    g = 0xdf - r
    return lcd.RGB(r, g, 0)
  end
end

local function drawBattery(wgt, myBatt)
  -- fill batt
  local fill_color = getPercentColor(wgt.vPercent)
  lcd.drawFilledRectangle(wgt.zone.x + myBatt.x, wgt.zone.y + myBatt.y + myBatt.h  - math.floor(wgt.vPercent / 100 * (myBatt.h - myBatt.cath_h)), myBatt.w, math.floor(wgt.vPercent / 100 * (myBatt.h - myBatt.cath_h)), fill_color)

  -- draw battery segments
  lcd.drawRectangle(wgt.zone.x + myBatt.x, wgt.zone.y + myBatt.y + myBatt.cath_h, myBatt.w, myBatt.h - myBatt.cath_h, WHITE, 2)
  for i = 1, myBatt.h - myBatt.cath_h - myBatt.segments_h, myBatt.segments_h do
    lcd.drawRectangle(wgt.zone.x + myBatt.x, wgt.zone.y + myBatt.y + myBatt.cath_h + i, myBatt.w, myBatt.segments_h, WHITE, 1)
  end

  -- draw plus terminal
  local tw = 4
  local th = 4
  lcd.drawFilledRectangle(wgt.zone.x + myBatt.x + myBatt.w / 2 - myBatt.cath_w / 2 + tw / 2, wgt.zone.y + myBatt.y, myBatt.cath_w - tw, myBatt.cath_h, WHITE)
  lcd.drawFilledRectangle(wgt.zone.x + myBatt.x + myBatt.w / 2 - myBatt.cath_w / 2, wgt.zone.y + myBatt.y + th, myBatt.cath_w, myBatt.cath_h - th, WHITE)
  --lcd.drawText(wgt.zone.x + myBatt.x + 20, wgt.zone.y + myBatt.y + 5, string.format("%2.0f%%", wgt.vPercent), LEFT + MIDSIZE + wgt.text_color)
  --lcd.drawText(wgt.zone.x + myBatt.x + 20, wgt.zone.y + myBatt.y + 5, string.format("%2.1fV", wgt.mainValue), LEFT + MIDSIZE + wgt.text_color)
end

--- Zone size: 70x39 1/8th top bar
local function refreshZoneTiny(wgt)
  local myString = string.format("%2.1fV", wgt.mainValue)

  -- write text
  lcd.drawText(wgt.zone.x + wgt.zone.w - 25, wgt.zone.y + 5, wgt.vPercent .. "%", RIGHT + SMLSIZE + wgt.text_color + wgt.no_telem_blink)
  lcd.drawText(wgt.zone.x + wgt.zone.w - 25, wgt.zone.y + 20, myString, RIGHT + SMLSIZE + wgt.text_color + wgt.no_telem_blink)

  -- draw battery
  local batt_color = wgt.options.Color
  lcd.drawRectangle(wgt.zone.x + 50, wgt.zone.y + 9, 16, 25, batt_color, 2)
  lcd.drawFilledRectangle(wgt.zone.x + 50 + 4, wgt.zone.y + 7, 6, 3, batt_color)
  local rect_h = math.floor(25 * wgt.vPercent / 100)
  lcd.drawFilledRectangle(wgt.zone.x + 50, wgt.zone.y + 9 + 25 - rect_h, 16, rect_h, batt_color + wgt.no_telem_blink)
end

--- Zone size: 160x32 1/8th
local function refreshZoneSmall(wgt)
  local myBatt = { ["x"] = 0, ["y"] = 0, ["w"] = 155, ["h"] = 35, ["segments_w"] = 25, ["color"] = WHITE, ["cath_w"] = 6, ["cath_h"] = 20 }

  -- fill battery
  local fill_color = getPercentColor(wgt.vPercent)
  lcd.drawGauge(wgt.zone.x, wgt.zone.y, myBatt.w, myBatt.h, wgt.vPercent, 100, fill_color)

  -- draw battery
  lcd.drawRectangle(wgt.zone.x + myBatt.x, wgt.zone.y + myBatt.y, myBatt.w, myBatt.h, WHITE, 2)

  -- write text
  local topLine = string.format("%2.1fV      %2.0f%%", wgt.mainValue, wgt.vPercent)
  lcd.drawText(wgt.zone.x + 20, wgt.zone.y + 2, topLine, MIDSIZE + wgt.text_color + wgt.no_telem_blink)
end


--- Zone size: 180x70 1/4th  (with sliders/trim)
--- Zone size: 225x98 1/4th  (no sliders/trim)
local function refreshZoneMedium(wgt)
  local myBatt = { ["x"] = 0, ["y"] = 0, ["w"] = 50, ["h"] = wgt.zone.h, ["segments_w"] = 15, ["color"] = WHITE, ["cath_w"] = 26, ["cath_h"] = 10, ["segments_h"] = 16 }

  -- draw values
  lcd.drawText(wgt.zone.x + myBatt.w + 10, wgt.zone.y, string.format("%2.2fV", wgt.mainValue), DBLSIZE + wgt.text_color + wgt.no_telem_blink)
  lcd.drawText(wgt.zone.x + myBatt.w + 10, wgt.zone.y + 30, string.format("%2.0f%%", wgt.vPercent), MIDSIZE + wgt.text_color + wgt.no_telem_blink)
  lcd.drawText(wgt.zone.x + wgt.zone.w, wgt.zone.y + wgt.zone.h -53, wgt.options.source_name, RIGHT + SMLSIZE + wgt.text_color + wgt.no_telem_blink)
  if wgt.options.Show_Total_Voltage == 0 then
    lcd.drawText(wgt.zone.x + wgt.zone.w, wgt.zone.y + wgt.zone.h -35, string.format("%2.2fV %dS", wgt.secondaryValue, wgt.cellCount), RIGHT + SMLSIZE + wgt.text_color + wgt.no_telem_blink)
  else
    --lcd.drawText(wgt.zone.x, wgt.zone.y + 40, string.format("%2.1fV", wgt.mainValue), DBLSIZE + wgt.text_color + wgt.no_telem_blink)
  end
  lcd.drawText(wgt.zone.x + wgt.zone.w, wgt.zone.y + wgt.zone.h - 20, string.format("Min %2.2fV", wgt.vMin), RIGHT + SMLSIZE + wgt.text_color + wgt.no_telem_blink)

  -- more info if 1/4 is high enough (without trim & slider)
  if wgt.zone.h > 80 then
  end

  drawBattery(wgt, myBatt)

end

--- Zone size: 192x152 1/2
local function refreshZoneLarge(wgt)
  local myBatt = { ["x"] = 0, ["y"] = 0, ["w"] = 76, ["h"] = wgt.zone.h, ["segments_h"] = 30, ["color"] = WHITE, ["cath_w"] = 30, ["cath_h"] = 10 }

  lcd.drawText(wgt.zone.x + wgt.zone.w, wgt.zone.y + 0, string.format("%2.2fV", wgt.mainValue), RIGHT + DBLSIZE + wgt.text_color)
  lcd.drawText(wgt.zone.x + wgt.zone.w, wgt.zone.y + 30, wgt.vPercent .. "%", RIGHT + DBLSIZE + wgt.text_color)

  lcd.drawText(wgt.zone.x + wgt.zone.w, wgt.zone.y + wgt.zone.h - 53, wgt.options.source_name, RIGHT + SMLSIZE + wgt.text_color)
  lcd.drawText(wgt.zone.x + wgt.zone.w, wgt.zone.y + wgt.zone.h - 35, string.format("%2.2fV %dS", wgt.secondaryValue, wgt.cellCount), RIGHT + SMLSIZE + wgt.text_color)
  lcd.drawText(wgt.zone.x + wgt.zone.w, wgt.zone.y + wgt.zone.h - 20, string.format("min %2.2fV", wgt.vMin), RIGHT + SMLSIZE + wgt.text_color + wgt.no_telem_blink)

  drawBattery(wgt, myBatt)

end

--- Zone size: 390x172 1/1
--- Zone size: 460x252 1/1 (no sliders/trim/topbar)
local function refreshZoneXLarge(wgt)
  local x = wgt.zone.x
  local w = wgt.zone.w
  local y = wgt.zone.y
  local h = wgt.zone.h

  local myBatt = { ["x"] = 10, ["y"] = 0, ["w"] = 80, ["h"] = h, ["segments_h"] = 30, ["color"] = WHITE, ["cath_w"] = 30, ["cath_h"] = 10 }

  -- draw right text section
  --lcd.drawText(x + w, y + myBatt.y + 0, string.format("%2.2fV    %2.0f%%", wgt.mainValue, wgt.vPercent), RIGHT + XXLSIZE + wgt.text_color + wgt.no_telem_blink)
  --lcd.drawText(x + w, y + myBatt.y +  0, string.format("%2.2fV", wgt.mainValue), RIGHT + XXLSIZE + wgt.text_color + wgt.no_telem_blink)
  lcd.drawText(x + 150, y + myBatt.y +  0, string.format("%2.2fV", wgt.mainValue), XXLSIZE + wgt.text_color + wgt.no_telem_blink)
  lcd.drawText(x + 150, y + myBatt.y + 70, wgt.options.source_name, DBLSIZE + wgt.text_color + wgt.no_telem_blink)
  lcd.drawText(x + w, y + myBatt.y + 80, string.format("%2.0f%%", wgt.vPercent), RIGHT + DBLSIZE + wgt.text_color + wgt.no_telem_blink)
  lcd.drawText(x + w, y +h - 60       , string.format("%2.2fV    %dS", wgt.secondaryValue, wgt.cellCount), RIGHT + DBLSIZE + wgt.text_color + wgt.no_telem_blink)
  lcd.drawText(x + w, y +h - 30       , string.format("min %2.2fV", wgt.vMin), RIGHT + DBLSIZE + wgt.text_color + wgt.no_telem_blink)

  drawBattery(wgt, myBatt)

  return
end


--- Zone size: 460x252 - app mode (full screen)
local function refreshAppMode(wgt, event, touchState)
  local x = 0
  local y = 0
  local w = LCD_W
  local h = LCD_H - 20

  local myBatt = { ["x"] = 10, ["y"] = 10, ["w"] = 90, ["h"] = h, ["segments_h"] = 30, ["color"] = WHITE, ["cath_w"] = 30, ["cath_h"] = 10 }

  if (event ~= nil) then
    log("event: " .. event)
  end
    
  -- draw right text section
  --lcd.drawText(x + w - 20, y + myBatt.y + 0, string.format("%2.2fV    %2.0f%%", wgt.mainValue, wgt.vPercent), RIGHT + XXLSIZE + wgt.text_color + wgt.no_telem_blink)
  lcd.drawText(x + 180, y + 0, wgt.options.source_name, DBLSIZE + wgt.text_color + wgt.no_telem_blink)
  lcd.drawText(x + 180, y + 30, string.format("%2.2fV", wgt.mainValue), XXLSIZE + wgt.text_color + wgt.no_telem_blink)
  lcd.drawText(x + 180, y + 90, string.format("%2.0f%%", wgt.vPercent), XXLSIZE + wgt.text_color + wgt.no_telem_blink)

  lcd.drawText(x + w - 20, y + h - 90, string.format("%2.2fV", wgt.secondaryValue), RIGHT + DBLSIZE + wgt.text_color + wgt.no_telem_blink)
  lcd.drawText(x + w - 20, y + h - 60, string.format("%dS", wgt.cellCount), RIGHT + DBLSIZE + wgt.text_color + wgt.no_telem_blink)
  lcd.drawText(x + w - 20, y + h - 30, string.format("min %2.2fV", wgt.vMin), RIGHT + DBLSIZE + wgt.text_color + wgt.no_telem_blink)

  drawBattery(wgt, myBatt)

  return
end

-- This function allow recording of lowest cells when widget is in background
local function background(wgt)
  if (wgt == nil) then
    return
  end

  detectResetEvent(wgt)

  calculateBatteryData(wgt)

end

local function refresh(wgt, event, touchState)

  if (wgt == nil)         then return end
  if type(wgt) ~= "table" then return end
  if (wgt.options == nil) then return end
  if (wgt.zone == nil)    then return end
  if (wgt.options.Show_Total_Voltage == nil) then return end

  detectResetEvent(wgt)

  calculateBatteryData(wgt)

  if wgt.isDataAvailable then
    wgt.no_telem_blink = 0
    wgt.text_color = wgt.options.Color
  else
    wgt.no_telem_blink = INVERS + BLINK
    wgt.text_color = GREY
  end

  if (event ~= nil) then
    refreshAppMode(wgt, event, touchState)
  elseif wgt.zone.w > 380 and wgt.zone.h > 165 then
    refreshZoneXLarge(wgt)
  elseif wgt.zone.w > 180 and wgt.zone.h > 145 then
    refreshZoneLarge(wgt)
  elseif wgt.zone.w > 170 and wgt.zone.h > 65 then
    refreshZoneMedium(wgt)
  elseif wgt.zone.w > 150 and wgt.zone.h > 28 then
    refreshZoneSmall(wgt)
  elseif wgt.zone.w > 65 and wgt.zone.h > 35 then
    refreshZoneTiny(wgt)
  end

end

return { name = "BattAnalog", options = _options, create = create, update = update, background = background, refresh = refresh }
