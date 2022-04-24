local UNIT_ID_TO_STRING = { "V", "A", "mA", "kts", "m/s", "f/s", "km/h", "km/h", "mph", "m", "m", "f", "°C", "°C", "°F", "%", "mAh", "W", "mW", "dB", "rpms", "g", "°", "Rad" }

--------------------------------------------------------------
local function log(s)
  return;
  --print("Batt_A1: " .. s)
end
--------------------------------------------------------------

local options = {
  { "Source1", SOURCE, 251 }, -- RSSI
  { "Source2", SOURCE, 254 }, -- RxBt
  { "Source3", SOURCE, 1 }    -- Ail
}

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

local function showField(wgt, fieldName, offsetY)
  local fieldinfo = getFieldInfo(fieldName)
  local fieldValue = getValue(fieldName)

  if fieldinfo == nil then
    local txt = "field info NOT available: " .. "name: " .. fieldName .. ", value: [" .. fieldValue .. "]"
    lcd.drawText(0,0, txt, LEFT + SMLSIZE)
    return
  end

  if type(fieldValue) == "table" then
    fieldValue = "<TABLE>"
  end

  if fieldinfo then
    local txtUnit = "---"
    if (fieldinfo.unit) then
      --log("have unit")
      if (fieldinfo.unit > 0 and fieldinfo.unit < #UNIT_ID_TO_STRING) then
        log("idUnit: " .. fieldinfo.unit)
        txtUnit = UNIT_ID_TO_STRING[fieldinfo.unit]
        log("txtUnit: " .. txtUnit)
      end
    end

    local txt = fieldinfo['name'] .. "(id:" .. fieldinfo['id']
      .. ")"
      .. "=" .. fieldValue
      .. txtUnit
      .. " [desc: " .. fieldinfo['desc'] .. "]"

    lcd.drawText(wgt.zone.x + 3, wgt.zone.y + offsetY, txt, LEFT + SMLSIZE)

    for k, v in pairs(fieldinfo) do
      if (k ~= 'name' and k ~= 'id' and k ~= 'desc' and k ~= 'unit') then
        print("found field: " .. k)
      end
    end

  else
    lcd.drawText(x, y + 0, fieldName .. " - field NOT available! ", LEFT + SMLSIZE)
  end
  return
end

local function refresh(wgt)
  showField(wgt, 'cell', 0)
  showField(wgt, 'Cels', 20)
  showField(wgt, 'RSSI', 40)
  showField(wgt, 'RxBt', 60)
  showField(wgt, 'Curr', 80)
  showField(wgt, 'mAH', 100)
  showField(wgt, 'Cel1', 120)
  showField(wgt, 'Bat1', 140)
  showField(wgt, 'Tmr1', 150)
  showField(wgt, 'TMR1', 160)
  showField(wgt, 'timer1', 170)
end

return { name = "t_fieldInfo1", options = options, create = create, update = update, refresh = refresh }
