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
local app_ver = "0.9"

-- better font names
local FS={FONT_38=XXLSIZE,FONT_16=DBLSIZE,FONT_12=MIDSIZE,FONT_8=0,FONT_6=SMLSIZE}
local FONT_LIST = {FS.FONT_38,FS.FONT_16,FS.FONT_12,FS.FONT_8,FS.FONT_6}
local FONT_NAME_LIST = {"FONT_38","FONT_16","FONT_12","FONT_8","FONT_6"}

--------------------------------------------------------------
local function log(fmt, ...)
    print(string.format("[%s] "..fmt, app_name, ...))
end
--------------------------------------------------------------

local function getModelName()
    local name = model.getInfo().name

    -- remove leading ">" if exists from rotorflight
    local first_char = string.sub(name, 1,1)
    if first_char == ">" then
        name = string.sub(name, 2) -- remove ">"
    end

    -- log("getModelName() name: %s, %s, %s", name, string.sub(name, 1,1), name)
    return name
end

local function getFontSize(wgt, txt, max_w, max_h)
    log("getFontSize() [%s] zone: %sx%s, text area: %sx%s", txt, wgt.zone.w, wgt.zone.h, max_w, max_h)

    local i = 0
    for _, font_size in ipairs(FONT_LIST) do
        local fw, fh = lcd.sizeText(txt, font_size)
        local font_name = FONT_NAME_LIST[i]
        log("getFontSize() [%s] %s (%s, %s)", txt, font_name, fw, fh)

        if fw <= max_w and fh <= max_h then
            log("getFontSize() found the font size [%s] %s %dx%d", txt, font_name, fw, fh)
            return font_size, fw, fh
        end
        i = i+1
    end

    log("getFontSize() failed to find font!!!! using default for (%s)", txt)
    local fw, fh = lcd.sizeText(txt, FS.FONT_6)
    return FS.FONT_6, fw, fh
end


local function build_ui(wgt)
    local font_size, space_x, space_y, fw,fh

    local txt = getModelName()

    if wgt.options.autoSize==1 then
        log('FONT-SIZE: %s %s %s=%s', FONT_NAME_LIST[#FONT_NAME_LIST - wgt.options.fontSizeIdx +1], #FONT_NAME_LIST, wgt.options.fontSizeIdx, #FONT_NAME_LIST - wgt.options.fontSizeIdx +1);

        -- auto size the widget to fit the text
        font_size,fw,fh = getFontSize(wgt, txt, wgt.zone.w-6, wgt.zone.h-6)
        log('ModelName: autoSize: text="%s", fw=%s, fh=%s, space_x=%s, space_y=%s', txt, fw, fh, space_x, space_y);
    else
        -- manual size
        font_size = FONT_LIST[#FONT_LIST - wgt.options.fontSizeIdx +1]
        fw, fh = lcd.sizeText(txt, font_size)
    end

    if wgt.options.autoAlign==1 then
        space_x = (wgt.zone.w - fw) // 2
        space_y = (wgt.zone.h - fh) // 2
    else
        space_x = wgt.options.space_x
        space_y = wgt.options.space_y
    end

    lvgl.clear()
    lvgl.build({
        -- {type="rectangle", x=0, y=0, w=wgt.zone.w, h=wgt.zone.h, color=BLUE, filled=true},
        -- {type="rectangle", x=0, y=0, w=wgt.zone.w, h=wgt.zone.h, color=wgt.options.textColor}
        {type="label", x=space_x, y=space_y, font=font_size, color=wgt.options.textColor,
            text = function() return getModelName() end
        }
    })

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
    build_ui(wgt)
end

local function refresh(wgt)

end

return {create=create, update=update, refresh=refresh}
