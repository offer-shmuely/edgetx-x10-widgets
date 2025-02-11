local app_name = "Mixers"
local app_ver = "0.6"
local y
local M = {}
--------------------------------------------------------------
local function log(...)
    print(string.format("[%s] %s", app_name, ...))
    return
end
--------------------------------------------------------------

-- better font size names
FONT_38 = XXLSIZE -- 38px
FONT_16 = DBLSIZE -- 16px
FONT_12 = MIDSIZE -- 12px
FONT_8  = 0       -- Default 8px
FONT_6  = SMLSIZE -- 6px


local options = {
    { "text_color", COLOR, COLOR_THEME_SECONDARY1 },
    { "bar_color", COLOR, COLOR_THEME_FOCUS },
    { "bar_bkg_enabled", BOOL, 1 },
    { "bar_bkg_color", COLOR, GREY },
    { "background_enabled", BOOL, 0 },
    -- { "background_color", COLOR, LIGHTGREY },
}
local function translate(nam)
    local translations = {
        text_color = "Text Color",
        bar_color = "Bar: Color",
        bar_bkg_enabled = "Bar: Background Enabled",
        bar_bkg_color = "Bar: Background Color",
        background_enabled="Background Enabled",
        -- background_color = "Background: Color",
    }
    return translations[nam]
end

local function update(wgt, options)
    if (wgt == nil) then return end
    wgt.options = options
    wgt.text_color = options.text_color
    wgt.bar_color = options.bar_color
    wgt.bar_bkg_enabled = (options.bar_bkg_enabled==1)
    wgt.bar_bkg_color = options.bar_bkg_color
    wgt.background_enabled = (options.background_enabled==1)
    wgt.background_color = options.background_color or LIGHTGREY
    -- wgt.background_color = LIGHTGREY
    return wgt
end

local function create(zone, options)
    local wgt = {
        zone = zone,
        options = options,
        values = {},
        names = {},
    }
    return update(wgt, options)
end

local function background(wgt)
    for i = 1, 16 do
        wgt.values[i] = getValue("ch" .. i)
        wgt.names[i] = model.getOutput(i-1).name
        -- log(string.format("%s. aaa: %s", i, model.getOutput(i-1).name))
    end
end

local function draw_all_bars(wgt, from_ch, to_ch, zx, zy, zw, zh)
    local line_height = 18
    local bar_height = line_height - 2
    local bar_area_x = zx + 40
    local bar_area_y = zy + 20
    local bar_area_w = zw - 40
    local bar_area_h = zh - 40

    for i = from_ch, to_ch do
        local value = wgt.values[i] or 0
        local percent = math.floor(100 * (value+5) / 1024) -- +3 to remove fluctuations
        local bar_width = percent * bar_area_w /2/100
        -- local text = string.format("CH%d  %d%%", i, percent)
        local yy = zy + (i - from_ch) * line_height
        local text_y = yy - 1 -- (bar_height - ) / 2
        local x_mid = bar_area_x + bar_area_w / 2

        -- if (yy+line_height > zy + zh) then
        --     break
        -- end

        -- border
        if (wgt.bar_bkg_enabled) then
            lcd.drawFilledRectangle(bar_area_x, yy, bar_area_w, bar_height, SOLID + wgt.bar_bkg_color)
        end

        -- bar
        lcd.drawFilledRectangle(x_mid, yy, bar_width, bar_height, SOLID + wgt.bar_color)--wgt.bar_color)

        -- border
        -- lcd.drawLine(bar_area_x,  yy, bar_area_x + bar_area_w,  yy, SOLID , BLACK)

        -- middle mark
        lcd.drawFilledRectangle(x_mid-1, yy, 1, bar_height, SOLID + WHITE)

        -- text channel
        lcd.drawText(zx + 6, text_y, string.format("CH%d", i), FONT_6 + wgt.text_color)

        -- text output name
        lcd.drawText(bar_area_x + 6, text_y, wgt.names[i], FONT_6 + WHITE)

        -- text percent
        local dx = (percent > 0) and -35 or 15
        -- log(string.format("percent: %d", percent))
        lcd.drawText(x_mid + dx, text_y, string.format("%d%%", percent), FONT_6 + WHITE)
    end

end

local function refresh(wgt)
    if (wgt == nil) then return end

    background(wgt)

    local dy = 17

    if (wgt.background_enabled == true) then
        lcd.drawFilledRectangle(wgt.zone.x, wgt.zone.y, wgt.zone.w, wgt.zone.h, wgt.background_color)
    end

    if (wgt.zone.w < 320) then
        -- single column
        lcd.drawText(40,0,"Mixers", wgt.text_color + FONT_6)
        draw_all_bars(wgt, 1, 16, wgt.zone.x, wgt.zone.y+dy, wgt.zone.w -5, wgt.zone.h-dy)
    else
        -- two columns
        lcd.drawText(40 ,0,"Mixers 1-8", wgt.text_color + FONT_6)
        lcd.drawText(wgt.zone.w /2+40,0,"Mixers 9-16", wgt.text_color + FONT_6)
        draw_all_bars(wgt, 1, 8,  wgt.zone.x,                wgt.zone.y +dy, wgt.zone.w /2 -5, wgt.zone.h -dy)
        draw_all_bars(wgt, 9, 16, wgt.zone.x + wgt.zone.w/2, wgt.zone.y +dy, wgt.zone.w /2 -5, wgt.zone.h -dy)
    end
end

return { name = app_name, options = options, create = create, update = update, refresh = refresh,  background = background, translate=translate }
