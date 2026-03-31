local app_name = "ModelName"
local options = {
    {"textColor",   COLOR, YELLOW},
    {"autoSize",    BOOL,    0 },
    {"autoAlign",   BOOL,    0 },
    {"fontSizeIdx", CHOICE,  4, {"Extra Small (6px)","Normal (8px)","Large (12px)","Extra Large (16px)","Huge (38px)"} },
    {"space_x",     VALUE,  10, 0, 400},
    {"space_y",     VALUE,   0, 0, 200},
}

local function translate(name)
    local translations = {
        textColor = "Text Color",
        autoSize = "Auto Size",
        fontSizeIdx = "Manual Text Size",
        autoAlign = "Auto align to center",
        space_x = "Manual Space X",
        space_y = "Manual Space Y",
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
local function refresh(wgt)         return wgt._tool.refresh(wgt)         end

return {name="Model Name", options=options, translate=translate, create=create, update=update, refresh=refresh, useLvgl=true}
