---- #########################################################################
---- #                                                                       #
---- # Telemetry Widget script for radiomaster TX16s                         #
---- # Copyright (C) OpenTX                                                  #
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
-- Widget that show the name of the model on the bar on top
-- Offer Shmuely
-- Date: 2019
local app_name = "ModelName"
local app_ver = "0.5"

-- better font names
local FONT_6 = SMLSIZE -- 6px
local FONT_8 = 0 -- Default 8px
local FONT_12 = MIDSIZE -- 12px
local FONT_16 = DBLSIZE -- 16px
local FONT_38 = XXLSIZE -- 38px
local FONT_LIST = {FONT_6,FONT_8,FONT_12,FONT_16,FONT_38,}

local options = {
    {"TextColor", COLOR, YELLOW},
    {"fontSizeIndex", CHOICE, 3 , {"6px","8px","12px","16px","38px"} },
}

local function translate(name)
    local translations = {
        TextColor = "Text Color",
        fontSizeIndex = "Font Size",
    }
    return translations[name]
end

local function create(zone, options)
    local wgt = {
        zone = zone,
        options = options,
    }
    return wgt
end

local function update(wgt, options)
    if (wgt == nil) then return end
    wgt.options = options
end

local function refresh(wgt)
    if (wgt == nil) then return end

    local modelName = model.getInfo().name
    lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)

    local font = FONT_LIST[wgt.options.fontSizeIndex]
    if (font == nil) then
        font = FONT_16
    end

    lcd.drawText(wgt.zone.x, wgt.zone.y, modelName, LEFT + font + wgt.options.TextColor);
end

return {name = app_name, options = options, create = create, update = update, refresh = refresh, translate = translate}
