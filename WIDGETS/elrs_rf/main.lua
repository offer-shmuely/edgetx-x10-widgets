--[[
#########################################################################
#                                                                       #
# Telemetry Widget script for FrSky Horus/RadioMaster TX16s             #
# Copyright "Offer Shmuely"                                             #
#                                                                       #
# License GPLv2: http://www.gnu.org/licenses/gpl-2.0.html               #
#                                                                       #
# This program is free software; you can redistribute it and/or modify  #
# it under the terms of the GNU General Public License version 2 as     #
# published by the Free Software Foundation.                            #
#                                                                       #
# This program is distributed in the hope that it will be useful        #
# but WITHOUT ANY WARRANTY; without even the implied warranty of        #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
# GNU General Public License for more details.                          #
#                                                                       #
#########################################################################


  This widget display express-lrs RF telemetry
  nice presentation of the RF link telemetry,
  this widget focused on fixed wing planes (i.e. line of site)
  arm/disarm switch (throttle cutoff switch) change between in-flight screen / post-flight-summary screen
  it detect end of flight (by telemetry) and favor the min/max of the unused current value
  all aspect of RF
    * rate
    * link quality
    * power
    * rssi1
    * rssi2
  smart:
    * show min-max
    * detect end of flight (no telemetry) to change display focus

  no non-elrs telemetry:
    * no range
    * no gps
    * no current

]]

-- Author : Offer Shmuely
-- Date: 2023-2024
local app_name = "elrs_rf"
local app_ver = "1.1"

-- ELRS_RF
-- ELRS-RF
-- eLRS-RF
-- eLRS_RF
-- eLRS-Planes
-- eLRS-PlanesTelemetry
-- eLRS-RF-Planes-Telemetry
-- eLRS-RF-Telemetry

-- CRSF available telemetry fields
--[[
    -- RF --
    1RSS Uplink - received signal strength antenna 1 (RSSI) TBS CROSSFIRE RX
    2RSS Uplink - received signal strength antenna 2 (RSSI) TBS CROSSFIRE RX
    RQly Uplink - link quality (valid packets) TBS CROSSFIRE RX
    RSNR Uplink - signal-to-noise ratio TBS CROSSFIRE RX
    RFMD Uplink - update rate, 0 = 4Hz, 1 = 50Hz, 2 = 150Hz TBS CROSSFIRE RX
    TPWR Uplink - transmitting power TBS CROSSFIRE TX
    TRSS Downlink - signal strength antenna TBS CROSSFIRE TX
    TQly Downlink - link quality (valid packets) TBS CROSSFIRE TX
    TSNR Downlink - signal-to-noise ratio TBS CROSSFIRE TX
    ANT Sensor for debugging only TBS CROSSFIRE TX
]]

-- better font names
local FONT_38 = XXLSIZE -- 38px
local FONT_16 = DBLSIZE -- 16px
local FONT_12 = MIDSIZE -- 12px
local FONT_8 = 0 -- Default 8px
local FONT_6 = SMLSIZE -- 6px

local TH --  = 17
local TXT_SIZE -- = FONT_6
local TXT_COL = COLOR_THEME_SECONDARY1
local lcd = lcd

local RFMD_I = 1
local RFMD_MODULATION = 2
local RFMD_IS_FULL_RES = 3
local RFMD_RATE_STR = 4
local RFMD_MIN_RSSI = 5
local RFMD_DESC = 6
local RFMD_LIST = {
    { 1, "LORA",   false, "25Hz"    , -123, "25Hz (LORA)" },
    { 2, "LORA",   false, "50Hz"    , -115, "50Hz (LORA)" },
    { 3, "LORA",   false, "100Hz"   , -117, "100Hz (LORA)" },
    { 4, "LORA",   true,  "100HzFull",-112, "100Hz (LORA-full-res)" },
    { 5, "LORA",   false, "150Hz"   , -112, "150Hz (LORA)" },
    { 6, "LORA",   false, "200Hz"   , -112, "200Hz (LORA)" },
    { 7, "LORA",   false, "250Hz"   , -108, "250Hz (LORA)" },
    { 8, "LORA",   true,  "333HzFull",-105, "333Hz (LORA-full-res)" },
    { 9, "LORA",   true,  "500Hz"   , -105, "500Hz (LORA)" },
    { 10, "FLRC+", false, "D250"    , -104, "250Hz (FLRC x4-DVDA)" },
    { 11, "FLRC+", false, "D500"    , -104, "500Hz (FLRC x2-DVDA)" },
    { 12, "FLRC ", false, "F500"    , -104, "500Hz (FLRC)" },
    { 13, "FLRC ", false, "F1000"   , -104, "1000Hz (FLRC)" },
    { 14, "n/a"  , false, "n/a"     , -128, "[off-line]" },
}
local RFMD_NA = 14
local MAX_RSSI = -40
local MAX_TX_POWER = 7
local POWERS      = { 10,   25, 50, 100, 250, 500, 1000, 2000 }
local POWERS_PERC = { 100, 100, 70, 50 ,  30,  10,    1,    0 }

local progress_bar_x = 70
local progress_bar_h = 15
-- simulation data
-- current_value, min, max, step
local sim_data = {
    rfmd = { 2, 2, 13, 0.5 },
    lq = { 100, 70, 100, -7 },
    tpwr = { 2, 1, 7, 1 },
    --rssi1 = { 10, -105, 10, -2 },
    rssi1 = { -20, -105, -2, -2 },
    rssi2 = { -60, -105, -2, -2 },
    ant = { 1, 0, 1, 0.3 },
}
local dbgX = LCD_W - 10
local dbgY = 150
local dbgDx = 13


-- Variables used across all instances
local vcache -- valueId cache

-- imports
local LibLogClass = loadScript("/WIDGETS/" .. app_name .. "/lib_log.lua", "tcd")
local LibWidgetToolsClass = loadScript("/WIDGETS/" .. app_name .. "/lib_widget_tools.lua", "tcd")
local m_log = LibLogClass(app_name, "/WIDGETS/" .. app_name)

local function log(fmt, ...)
    m_log.info(fmt, ...)
end

local function is_simulator()
    local _, rv = getVersion()
    return string.sub(rv, -5) == "-simu"
end

-- for backward compatibility
local function getSwitchIds(key)
    local OS_SWITCH_ID = {
        ["2.7"]  = {SA=112, SB=113, SC=114, SD=115, SE=116, SF=117, CH3 = 204},
        ["2.8"]  = {SA=120, SB=121, SC=122, SD=123, SE=124, SF=125, CH3 = 212},
        ["2.9"]  = {SA=120, SB=121, SC=122, SD=123, SE=124, SF=125, CH3 = 212},
        ["2.10"] = {SA=126, SB=127, SC=128, SD=129, SE=130, SF=131, CH3 = 228},
    }
    local ver, radio, maj, minor, rev, osname = getVersion()
    local os1 = string.format("%d.%d", maj, minor)
    return OS_SWITCH_ID[os1][key]
end

local DEFAULT_ARM_SWITCH_ID = getSwitchIds("SF")      -- arm/safety switch=SF

local options = {
    { "arm_switch", SOURCE, DEFAULT_ARM_SWITCH_ID },
    --{ "text_color", COLOR, COLOR_THEME_PRIMARY2 },
}


local function update(wgt, options)
    wgt.options = options
    wgt.zw = wgt.zone.w
    wgt.zh = wgt.zone.h
    wgt.SIMU = is_simulator()
    --wgt.SIMU = false
    wgt.DEBUG = false
    wgt.arm_switch_on = false
    wgt.module_info = {
        is_filled = false,
        name = "n/a",
        vMaj = "n/a",
        vMin = "n/a",
        vRev = "n/a",
        vStr = "n/a",

    }
    wgt.rx_info = {
    }
    wgt.tlm = {
        rfmd = RFMD_NA,
        rqly = 0,
        rqly_min = nil,
        rqly_max = nil,
        tpwr = 0,
        tpwr_min = nil,
        tpwr_max = nil,
        rssi1 = nil,
        rssi1_min = nil,
        rssi1_max = nil,
        rssi2 = nil,
        rssi2_min = nil,
        rssi2_max = nil,
        ant = 0,
        tlm_enabled = false,
    }
    wgt.ctx = {
        isDiversity = false
    }
    wgt.tools = LibWidgetToolsClass(m_log, app_name)

    wgt.sim_periodic = wgt.tools.periodicInit()
    wgt.tools.periodicStart(wgt.sim_periodic, 5000)

    wgt.show_minmax = true
    wgt.minmax_init_periodic = wgt.tools.periodicInit()
    --wgt.tools.periodicStart(wgt.minmax_init_periodic, 10000)
end

local function create(zone, options)
    local wgt = {
        zone = zone,
        cfg = options,
    }
    vcache = {}
    update(wgt, options)
    return wgt
end

local function fieldGetString(data, off)
    local startOff = off
    while data[off] ~= 0 do
        data[off] = string.char(data[off])
        off = off + 1
    end

    return table.concat(data, nil, startOff, off - 1), off + 1
end

local function getModuleInfo(wgt)
    if wgt.module_info.is_filled == true then
        return
    end

    local command, data = crossfireTelemetryPop()
    if command ~= 0x29 then
        -- frame_type::device_info = 0x29,
        local now = getTime()
        -- Poll the module every second
        if (wgt.module_info.lastUpd or 0) + 100 < now then
            crossfireTelemetryPush(0x28, { 0x00, 0xEA }) -- frame_type::device_ping = 0x28, address::radio_transmitter = 0xEA,
            wgt.module_info.lastUpd = now
        end
        return
    end

    -- 29 = type
    -- EA EE = extended packet dest/src
    if data[2] ~= 0xEE then
        --   address::crsf_transmitter = 0xEE
        -- only interested in TX info
        return
    end
    local name, off = fieldGetString(data, 3)
    wgt.module_info.name = name
    -- off = serNo ('ELRS') off+4 = hwVer off+8 = swVer
    wgt.module_info.vMaj = data[off + 9] -- 2.x | 3.x
    wgt.module_info.vMin = data[off + 10]
    wgt.module_info.vRev = data[off + 11]
    wgt.module_info.vStr = string.format("%s (%d.%d.%d)", wgt.module_info.name, wgt.module_info.vMaj, wgt.module_info.vMin, wgt.module_info.vRev)

    log("module_info#")
    log("wgt.module_info.name: %s", wgt.module_info.name)
    log("wgt.module_info.vMaj: %s", wgt.module_info.vMaj)
    log("wgt.module_info.vMin: %s", wgt.module_info.vMin)
    log("wgt.module_info.vRev: %s", wgt.module_info.vRev)
    log("ver: %s", wgt.module_info.vStr)
    wgt.module_info.is_filled = true
end

local function getV(wgt, id)
    -- Return the getValue of ID or nil if it does not exist
    local cid = vcache[id]
    if cid == nil then
        local info = getFieldInfo(id)
        -- use 0 to prevent future lookups
        cid = info and info.id or 0
        vcache[id] = cid
    end
    return cid ~= 0 and getValue(cid) or nil
end

local function update_randomizer(value)
    local current_value = value[1]
    local min = value[2]
    local max = value[3]
    local step = value[4]
    current_value = current_value + step
    if (step > 0) then
        -- go up
        if (current_value >= max) then
            current_value = max
            value[4] = value[4] * -1
        end
    else
        -- go down
        if (current_value <= min) then
            current_value = min
            value[4] = value[4] * -1
        end
    end
    value[1] = current_value
end

local function updateMinMax(wgt, oldVal, id)
    local newVal = getV(wgt, id)
    if newVal == nil then
        return oldVal
    else
        return newVal
    end
end

local function safe_min(min, v)
    if v == nil then
        return nil
    end
    local min2
    if (min == nil) then
        min2 = v
        m_log.warn("new min due to nil (%s)", v)
    else
        min2 = math.min(min, v)
    end
    --log("min: %d, %d --> %d", min, v, min2)
    return min2
end
local function safe_max(max, v)
    if v == nil then
        return nil
    end
    local max2
    if (max == nil) then
        max2 = v
    else
        max2 = math.max(max, v)
    end
    --log("max: %d, %d --> %d", max, v, max2)
    return max2
end

local function getSwitchStatus(wgt)
    if getValue(wgt.options.arm_switch) < 0 then
        --log(string.format("switch status (%s): =ON", wgt.options.arm_switch))
        return true
    else
        --log(string.format("switch status (%s): =OFF", wgt.options.arm_switch))
        return false
    end
end

local function drawProgressBar(wgt, field_type, Y, percent, val_to_display, val_to_display_min, percent_min, percent_max, unit)
    log("drawProgressBar [%s] %s: %s<%s<%s    %s", field_type, val_to_display, percent_min, percent, percent_max, unit)
    --log("drawProgressBar [%s] [%s] %d < %d < %d", field_type, val_to_display, percent_min, percent, percent_max)
    local bkg_col = GREEN
    if  wgt.tlm.tlm_enabled == false then
        percent = percent_min or 0
        val_to_display = val_to_display_min or "0"
        --log("drawProgressBar() - STATE.POST_FLIGHT_x")
        bkg_col = LIGHTGREY
    else
        if percent == nil then
            percent = 0
        elseif percent < 30 then
            bkg_col = RED
        elseif percent < 50 then
            bkg_col = ORANGE
        end
    end

    local x = progress_bar_x
    local y = Y + 3
    local w = wgt.zw - x - 5
    local h = progress_bar_h
    local px = (w - 2) * percent / 100
    lcd.drawFilledRectangle(x + 1, y + 1, px, h - 2, bkg_col)
    lcd.drawRectangle(x, y, w, h, bkg_col)

    if wgt.show_minmax and percent_min and percent_max then
        local pmin = (w - 2) * percent_min / 100
        local pmax = (w - 2) * percent_max / 100
        local ptri_w = 4
        local ptri_h = 6
        lcd.drawFilledTriangle(x + pmin - ptri_w, y, x + pmin + ptri_w, y, x + pmin, y + ptri_h, BLACK)
        lcd.drawFilledTriangle(x + pmax - ptri_w, y, x + pmax + ptri_w, y, x + pmax, y + ptri_h, BLACK)
    end

    lcd.drawText(x + (wgt.zw - x) * 0.45, Y + 1, string.format("%s %s", val_to_display, unit), TXT_SIZE + GREY + CENTER)

end

local function drawRfMode(wgt, Y)
    --log("wgt.tlm.rfmd: %d", wgt.tlm.rfmd)
    --lcd.drawText(180, Y, string.format("rfmd: %s", wgt.tlm.rfmd), TXT_SIZE)
    if wgt.tlm.rfmd == 0 then
        return Y
    end
    local rfmd = RFMD_LIST[wgt.tlm.rfmd]
    local txt = string.format("Rate: %s", rfmd[RFMD_DESC])
    lcd.drawText(5, Y, txt, TXT_SIZE + TXT_COL)
    return Y + TH
end

local function drawLq(wgt, Y)
    --lcd.drawText(5, Y, string.format("LQ: %d %%", wgt.tlm.rqly), FONT_8 + TXT_COL)
    lcd.drawText(5, Y, "Link Qly: ", FONT_8 + TXT_COL)
    local percent_min = wgt.tlm.rqly_min
    local percent_max = wgt.tlm.rqly_max

    drawProgressBar(wgt, "LQ", Y, wgt.tlm.rqly, wgt.tlm.rqly,wgt.tlm.rqly_min, percent_min, percent_max, "%")
    return Y + TH + 8
end

local function pwrToPercent(powval)
    if (powval == nil) then
        --return -3
        return nil
    end
    if (powval == 0) then
        --return -2
        return nil
    end
    for k, v in ipairs(POWERS) do
        if powval <= v then
            --log("pwrToPercent(%d)--%d--> %d", powval, k, POWERS_PERC[k])
            return POWERS_PERC[k]
        end
    end
    --log("pwrToPercent(%d)--> %d", powval, -1)
    --return -1
    return nil
end

local function drawPower(wgt, Y)
    --lcd.drawText(5, Y, "power: " .. tostring(wgt.tlm.tpwr) .. "mW", TXT_SIZE + TXT_COL)
    --m_log.info("power: tpwr_min:%s, tpwr:%s, tpwr_max:%s ", wgt.tlm.tpwr_min, wgt.tlm.tpwr, wgt.tlm.tpwr_max)
    --local percent = 100 * pwrToIdx(wgt.tlm.tpwr) / MAX_TX_POWER
    --local inv_percent = math.floor(100 * (MAX_TX_POWER - pwrToIdx(wgt.tlm.tpwr) -1) / MAX_TX_POWER -1)

    local inv_percent = pwrToPercent(wgt.tlm.tpwr)
    local inv_percent_min = pwrToPercent(wgt.tlm.tpwr_max)
    local inv_percent_max = pwrToPercent(wgt.tlm.tpwr_min)

    lcd.drawText(5, Y, "power: ", TXT_SIZE + TXT_COL)
    drawProgressBar(wgt, "POWER", Y, inv_percent, wgt.tlm.tpwr, wgt.tlm.tpwr_min, inv_percent_min, inv_percent_max, "mW")
    --m_log.info("power: tpwr:%s=%s%%, %s=%s%%, %s=%s%%",
    --    wgt.tlm.tpwr, inv_percent,
    --    wgt.tlm.tpwr_min, inv_percent_min,
    --    wgt.tlm.tpwr_max, inv_percent_max
    --)
    --m_log.info("power: tpwr:%s, MAX_TX_POWER:%s, percent:%s, inv_percent:%s ", wgt.tlm.tpwr, MAX_TX_POWER, percent, inv_percent)
    return Y + TH
end

local function drawRssi(wgt, Y, id)
    if wgt.ctx.isDiversity == false and id == 2 then
        return Y
    end
    local rssi
    local rssi_min
    local rssi_max
    local is_ant_active
    if id == 1 then
        rssi = wgt.tlm.rssi1
        rssi_min = wgt.tlm.rssi1_min --or 0
        rssi_max = wgt.tlm.rssi1_max --or 0
        is_ant_active = (wgt.tlm.ant == 0)
    else
        rssi = wgt.tlm.rssi2
        rssi_min = wgt.tlm.rssi2_min --or 0
        rssi_max = wgt.tlm.rssi2_max --or 0
        is_ant_active = (wgt.tlm.ant == 1)
    end

    --lcd.drawText(5, Y, string.format("rssi%d: %d dBm", id, rssi), TXT_SIZE + TXT_COL)
    lcd.drawText(5, Y, string.format("rssi%d:", id), TXT_SIZE + TXT_COL)
    --log("wgt.tlm.rfmd: %s", wgt.tlm.rfmd)
    local min_allow_rssi = RFMD_LIST[wgt.tlm.rfmd][RFMD_MIN_RSSI]
    --log("min_allow_rssi: %s", min_allow_rssi)

    --local fix_rssi = (rssi ~= nil) and math.min(rssi, MAX_RSSI) or nil
    local fix_rssi = nil
    local rangePct = 0
    if rssi ~= nil then
        fix_rssi = math.min(rssi, MAX_RSSI)
        rangePct = 100 * (fix_rssi - min_allow_rssi) / (MAX_RSSI - min_allow_rssi)
    end

    --log("rssi_min: %s, rssi_max: %s", rssi_min, rssi_max)
    local fix_rssi_min, fix_rssi_max, rangePct_min, rangePct_max
    if rssi_min ~= nil and rssi_max ~= nil then
        fix_rssi_min = math.min(rssi_min, MAX_RSSI)
        fix_rssi_max = math.min(rssi_max, MAX_RSSI)
        rangePct_min = 100 * (fix_rssi_min - min_allow_rssi) / (MAX_RSSI - min_allow_rssi)
        rangePct_max = 100 * (fix_rssi_max - min_allow_rssi) / (MAX_RSSI - min_allow_rssi)
    end

    --log("drawProgressBarRssi: 100*(%d-%d) / (%d-%d) = %d", fix_rssi, min_allow_rssi, max_rssi, min_allow_rssi, rangePct)
    --log("rangePct: %s, rssi: %s, rssi_min: %s, rangePct_min: %s, rangePct_max: %s, min_allow_rssi: %s", rangePct, rssi, rssi_min, rangePct_min, rangePct_max, min_allow_rssi)

    drawProgressBar(wgt, "RSSI", Y, rangePct, rssi, rssi_min, rangePct_min, rangePct_max, "dBm")

    if wgt.tlm.tlm_enabled == true and is_ant_active then
        local now = getTime()
        local blink_mode = now%50 > 15
        if blink_mode then
            lcd.drawFilledCircle(progress_bar_x + 8, Y + 10, 4, BLUE)
        else
            --lcd.drawCircle(110 + 6, Y + 9, 4, BLUE)
        end
    end

    return Y + TH
end

local function drawModuleName(wgt, Y)
    lcd.drawText(5, Y, string.format("elrs module: %s", wgt.module_info.vStr), TXT_SIZE + TXT_COL)
    return Y + TH
end

local function calcData(wgt)
    --log("minmax/rqly : %s, %s...%s", wgt.tlm.rqly, wgt.tlm.rqly_min, wgt.tlm.rqly_max)
    --log("minmax/power: %s, %s...%s ", wgt.tlm.tpwr, wgt.tlm.tpwr_min, wgt.tlm.tpwr_max)
    --log("minmax/rssi1: %s, %s...%s ", wgt.tlm.rssi1, wgt.tlm.rssi1_min, wgt.tlm.rssi1_max)
    --log("minmax/rssi2: %s, %s...%s ", wgt.tlm.rssi2, wgt.tlm.rssi2_min, wgt.tlm.rssi2_max)

    getModuleInfo(wgt)

    wgt.arm_switch_on = getSwitchStatus(wgt)

    if wgt.SIMU then
        local is_sim_active = getValue("sa")
        wgt.DEBUG = (is_sim_active == 0)
        wgt.tlm.tlm_enabled = (is_sim_active > -100)
    else
        wgt.tlm.rfmd = getV(wgt, "RFMD")
        wgt.tlm.rqly = getV(wgt, "RQly")
        wgt.tlm.tpwr = getV(wgt, "TPWR")
        wgt.tlm.rssi1 = getV(wgt, "1RSS")
        wgt.tlm.rssi2 = getV(wgt, "2RSS")
        wgt.tlm.ant = getV(wgt, "ANT")

        if (wgt.tlm.rfmd == nil or wgt.tlm.rfmd == 0) then
            wgt.tlm.rfmd = RFMD_NA
        end
        wgt.tlm.tlm_enabled = ((wgt.tlm.rfmd ~= nil) and (wgt.tlm.rfmd > 0) and (wgt.tlm.rfmd ~= RFMD_NA)) and ((wgt.tlm.rqly ~= nil) and (wgt.tlm.rqly > 10)) and ((wgt.tlm.tpwr ~= nil) and (wgt.tlm.tpwr > 0))

        if wgt.arm_switch_on then
            wgt.tlm.rqly_min = updateMinMax(wgt.tlm.rqly_min, wgt,"RQly-")
            wgt.tlm.rqly_max = updateMinMax(wgt.tlm.rqly_max, wgt, "RQly+")
            wgt.tlm.tpwr_min = updateMinMax(wgt.tlm.tpwr_min, wgt, "TPWR-")
            wgt.tlm.tpwr_max = updateMinMax(wgt.tlm.tpwr_max, wgt, "TPWR+")
            wgt.tlm.rssi1_min = updateMinMax(wgt.tlm.rssi1_min, wgt, "1RSS-")
            wgt.tlm.rssi1_max = updateMinMax(wgt.tlm.rssi1_max, wgt, "1RSS+")
            wgt.tlm.rssi2_min = updateMinMax(wgt.tlm.rssi2_min, wgt, "2RSS-")
            wgt.tlm.rssi2_max = updateMinMax(wgt.tlm.rssi2_max, wgt, "2RSS+")
        end
    end

    if wgt.DEBUG then
        if wgt.tools.periodicHasPassed(wgt.sim_periodic) then
            update_randomizer(sim_data.rfmd)
            update_randomizer(sim_data.lq)
            update_randomizer(sim_data.tpwr)
            update_randomizer(sim_data.rssi1)
            update_randomizer(sim_data.rssi2)
            update_randomizer(sim_data.ant)
            wgt.tools.periodicReset(wgt.sim_periodic)
        end

        wgt.tlm.rfmd = math.floor(sim_data.rfmd[1])
        wgt.tlm.rqly = math.floor(sim_data.lq[1])
        wgt.tlm.tpwr = POWERS[sim_data.tpwr[1]]
        wgt.tlm.rssi1 = math.floor(sim_data.rssi1[1])
        wgt.tlm.rssi2 = math.floor(sim_data.rssi2[1])
        wgt.tlm.ant = math.floor(sim_data.ant[1])
        wgt.ctx.isDiversity = true
        local ver, radio, maj, minor, rev, osname = getVersion()
        wgt.module_info.vStr = string.format("simulator (%s)", ver)

        if wgt.arm_switch_on then
            wgt.tlm.rqly_min = safe_min(wgt.tlm.rqly_min, wgt.tlm.rqly)
            wgt.tlm.rqly_max = safe_max(wgt.tlm.rqly_max, wgt.tlm.rqly)
            wgt.tlm.tpwr_min = safe_min(wgt.tlm.tpwr_min, wgt.tlm.tpwr)
            wgt.tlm.tpwr_max = safe_max(wgt.tlm.tpwr_max, wgt.tlm.tpwr)
            wgt.tlm.rssi1_min = safe_min(wgt.tlm.rssi1_min, wgt.tlm.rssi1)
            wgt.tlm.rssi1_max = safe_max(wgt.tlm.rssi1_max, wgt.tlm.rssi1)
            wgt.tlm.rssi2_min = safe_min(wgt.tlm.rssi2_min, wgt.tlm.rssi2)
            wgt.tlm.rssi2_max = safe_max(wgt.tlm.rssi2_max, wgt.tlm.rssi2)
        end
    end

    if wgt.tlm.tlm_enabled == false then
        wgt.tlm.rfmd = RFMD_NA
        wgt.tlm.rqly = nil
        wgt.tlm.tpwr = nil
        wgt.tlm.rssi1 = nil -- bug in read, it return 0
        wgt.tlm.rssi2 = nil
        wgt.tlm.ant = 0
    end

    if wgt.tlm.ant ~= 0 then
        wgt.ctx.isDiversity = true
    end

    -- ----------------- state machine end -----------------------------------------

    -- record min/max (not recortding in POST_FLIGHT_ARM_SWITCH_OFF)
    --log("115 wgt.tlm.rqly_min: %s, rqly_max: %s", wgt.tlm.rqly_min, wgt.tlm.rqly_max)
end

local function drawDbgText(msg)
    lcd.drawText(dbgX, dbgY, msg, FONT_6 + LIGHTGREY + RIGHT)
    dbgY = dbgY +dbgDx
end

local function background(wgt)
    calcData(wgt)
end

local function refresh(wgt, event, touchState)
    if (touchState and touchState.tapCount == 2) or (event and event == EVT_VIRTUAL_EXIT) then
        lcd.exitFullScreen()
    end
    local is_app_mode = (event ~= nil)

    if (is_app_mode) then
        wgt.zw = LCD_W
        wgt.zh = LCD_H
    else
        wgt.zw = wgt.zone.w
        wgt.zh = wgt.zone.h
    end

    local Y = 5
    TH = 17
    if wgt.zh > 120 then
        TH = 25
    end
    TXT_SIZE = FONT_6
    if wgt.zh > 140 then
        TXT_SIZE = FONT_8
    end

    --background
    lcd.drawFilledRectangle(0, 0, wgt.zw, wgt.zh, COLOR_THEME_PRIMARY2)

    calcData(wgt)

    --if wgt.tlm.tlm_enabled == false then
    --    lcd.drawText(wgt.zone.x + wgt.zone.w, wgt.zone.y, string.format("load: %d%%", getUsage()), FONT_6 + GREY + RIGHT)
    --    lcd.drawFilledRectangle(0, 0, wgt.zw, wgt.zh, BLACK)
    --    if wgt.zh > 50 then
    --        lcd.drawText(wgt.zw / 2, 10, "-- ELRS-RF --", FONT_8 + WHITE + CENTER)
    --    end
    --    lcd.drawText(wgt.zw / 2, wgt.zh / 2, "No RX connected...", FONT_12 + WHITE + CENTER+ VCENTER)
    --    return
    --end

    Y = drawRfMode(wgt, Y)
    Y = drawLq(wgt, Y)
    Y = drawPower(wgt, Y, 0, 6, 6, wgt.tlm.tpwr, wgt.zw, wgt.zh) -- uses 1W as max
    Y = drawRssi(wgt, Y, 1)
    Y = drawRssi(wgt, Y, 2)
    Y = drawModuleName(wgt, Y)

    --if app_mode (or big screen)
    if wgt.zh > 200 then
        local y = 180
        local dy = 20
        lcd.drawText(10, y, string.format("RX link quality min: %s%%",wgt.tlm.rqly_min), FONT_8 + TXT_COL)
        y = y + dy
        lcd.drawText(10, y, string.format("TX power         max: %smW",wgt.tlm.tpwr_max), FONT_8 + TXT_COL)

        -- debugging
        dbgY = 120
        --drawDbgText(string.format("load: %d%%", getUsage()))
        --drawDbgText(string.format("rfmd: %s",wgt.tlm.rfmd))
        drawDbgText(string.format("arm: %s",(wgt.arm_switch_on)and "on" or "off"))
        drawDbgText(string.format("tlm: %s",(wgt.tlm.tlm_enabled)and "on" or "off"))
        drawDbgText(string.format("rssi: %s",wgt.tlm.rssi1))
        drawDbgText(string.format("rssi-: %s",wgt.tlm.rssi1_min))
        drawDbgText(string.format("rssi+: %s",wgt.tlm.rssi1_max))
        drawDbgText(string.format("tpwr-: %s",wgt.tlm.tpwr_min))
        drawDbgText(string.format("tpwr+: %s",wgt.tlm.tpwr_max))
        --drawDbgText(string.format("tlm.ant: %s",wgt.tlm.ant))
        --drawDbgText(string.format("isDiversity: %s",wgt.ctx.isDiversity))
    end
end

return {
    name = app_name,
    options = options,
    create = create,
    update = update,
    background = background,
    refresh = refresh
}

