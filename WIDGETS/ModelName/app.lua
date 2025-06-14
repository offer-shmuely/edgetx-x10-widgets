---- #########################################################################
---- #                                                                       #
---- # Telemetry Widget script for RadioMaster TX16S                         #
---- # Copyright (C) Offer SHmuely                                                  #
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
-- Date: 2019-2015
local app_name = "ModelName"
local app_ver = "0.7"

-- better font names
local FS={FONT_38=XXLSIZE,FONT_16=DBLSIZE,FONT_12=MIDSIZE,FONT_8=0,FONT_6=SMLSIZE}
local FONT_LIST = {FS.FONT_6,FS.FONT_8,FS.FONT_12,FS.FONT_16,FS.FONT_38,}

--------------------------------------------------------------
local function log(fmt, ...)
    print(string.format("[%s] "..fmt, app_name, ...))
end
--------------------------------------------------------------

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
    log("widget options: %s, w=%s, h=%s", options, wgt.zone.w, wgt.zone.h)
    log("widget options: %s, %s, %s, options:%s", LEFT, CENTER, RIGHT, wgt.options.align)
    local font_size = FONT_LIST[wgt.options.fontSizeIdx]
    local align_t = wgt.options.align
    -- local align_t = CENTER + VCENTER
    local align_t = LEFT

    lvgl.clear()
    lvgl.build({
        {type="label", x=wgt.options.space_x, y=wgt.options.space_y,
            -- w=wgt.zone.w, h=wgt.zone.h,
            font= font_size, align=align_t, color=wgt.options.textColor,
            text = function() return model.getInfo().name end
        },
        -- {type="rectangle", x=0, y=0, w=wgt.zone.w, h=wgt.zone.h, color=wgt.options.textColor}
    })
end

local function refresh(wgt)
    if (wgt == nil) then return end

    local font = FONT_LIST[wgt.options.fontSizeIdx]
    if (font == nil) then
        font = FONT_16
    end
    local ali = 0
    if (wgt.options.align == 0) then
        ali = LEFT;
    elseif (wgt.options.align == 1) then
        ali = CENTER
    elseif (wgt.options.align == 2) then
        ali = RIGHT
    end



    -- lcd.drawText(wgt.zone.x, wgt.zone.y, modelName, ali + font + wgt.options.textColor);
end

return {create=create, update=update, refresh=refresh}
