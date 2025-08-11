local app_name = "elrs_rf"

local options = {
    { "arm_switch", SWITCH, getSwitchIndex("SF"..CHAR_UP)  },
    --{ "text_color", COLOR, COLOR_THEME_PRIMARY2 },
}

local function translate(name)
    local translations = {
        arm_switch = "Arm Switch",
    }
    return translations[name]
end

local tool = nil
local function create(zone, options)
    tool = assert(loadScript("/WIDGETS/" .. app_name .. "/app.lua", "btd"))()
    return tool.create(zone, options)
end
local function update(wgt, options) return tool.update(wgt, options) end
local function background(wgt)      return tool.background(wgt) end
local function refresh(wgt)         return tool.refresh(wgt)    end

return {name="ELRS RF Info", options=options, translate=translate, create=create, update=update, refresh=refresh, background=background, useLvgl=false}
