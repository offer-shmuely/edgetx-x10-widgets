local app_name = "elrs_rf"

local options = {
    { "arm_switch_id", SWITCH, getSwitchIndex("SF"..CHAR_UP)  },
    --{ "text_color", COLOR, COLOR_THEME_PRIMARY2 },
}

local function translate(name)
    local translations = {
        arm_switch_id = "Arm Switch",
    }
    return translations[name]
end

local function create(zone, options)
    local tool = assert(loadScript("/WIDGETS/" .. app_name .. "/app.lua", "btd"))()
    local wgt = tool.create(zone, options)
    wgt._tool = tool
    return wgt
end
local function update(wgt, options) return wgt._tool.update(wgt, options) end
local function background(wgt)      return wgt._tool.background(wgt)      end
local function refresh(wgt)         return wgt._tool.refresh(wgt)      end

return {name="ELRS RF Info", options=options, translate=translate, create=create, update=update, refresh=refresh, background=background, useLvgl=false}
