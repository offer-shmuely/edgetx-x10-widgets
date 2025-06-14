
local options = {
    {"textColor", COLOR, YELLOW},
    {"fontSizeIdx", CHOICE, 3 , {"Extra Small","Normal","Large","Extra Large","Huge"} },
    {"space_x", VALUE, 5, 0, 100},
    {"space_y", VALUE, 5, 0, 100},
    -- {"align", ALIGNMENT, 0},
}

local function translate(name)
    local translations = {
        TextColor = "Text Color",
        fontSizeIdx = "Text Size",
        space_x = "Horizontal Space (X)",
        space_y = "Vertical Space (Y)",
        -- align = "Text Alignment"
    }
    return translations[name]
end

local tool = nil

local function create(zone, options)
    tool = assert(loadScript("/WIDGETS/ModelName/app.lua", "btd"))()
    return tool.create(zone, options)
end
local function update(wgt, options) return tool.update(wgt, options) end
local function background(wgt)      return tool.background(wgt) end
local function refresh(wgt)         return tool.refresh(wgt)    end

return {name="Model Name", options=options, translate=translate, create=create, update=update, refresh=refresh, useLvgl=true}
