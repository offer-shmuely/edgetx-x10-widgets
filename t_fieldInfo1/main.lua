-- test_getFieldInfo

local unitToString = { "V", "A", "mA", "kts", "m/s", "f/s", "km/h", "km/h", "mph", "m", "m", "f", "°C", "°C", "°F", "%", "mAh", "W", "mW", "dB", "rpms", "g", "°", "Rad" }

local options = {
  { "Sensor", SOURCE, 0 },
  { "Color", COLOR, WHITE },
  { "Shadow", BOOL, 0 },
  { "LowestCell", BOOL, 1 }
}

-- workaround for companion simulator issues
local function isWidgetInvalid(wgt)

  if (wgt == nil) then return false end
  if type(wgt) ~= "table" then return false end
  if (wgt.options == nil) then return false end
  if type(wgt.options) ~= "table" then return false end
  if (wgt.zone == nil) then return false end
  if type(wgt.zone) ~= "table" then return false end
  --print("aaaaa create::wgt=" .. type(wgt))
  --print("aaaaa create::options=" .. type(options))
end


-- This function is runned once at the creation of the widget
local function create(zone, options)
  local wgt = {
    zone = nil,
    options = nil,
    counter = 0
  }

  -- workaround for companion simulator issues
  print("aaaaa create::wgt=" .. type(wgt))
  print("aaaaa create::options=" .. type(options))

  if type(wgt) ~= "table" then
    return wgt
  end
  --if type(options) ~= "table" then
  --  return wgt
  --end

  wgt.zone = zone
  wgt.options = options

  -- use default if user did not set, So widget is operational on "select widget"
  if wgt.options.Sensor == 0 then
    wgt.options.Sensor = "Cels"
  end

  wgt.options.LowestCell = wgt.options.LowestCell % 2 -- modulo due to bug that cause the value to be other than 0|1

  return wgt
end

-- This function allow updates when you change widgets settings
local function update(wgt, options)
  if (isWidgetInvalid(wgt)) then return end

  wgt.options = options
end

local function showField(wgt, fieldName, offsetY)
  local x = wgt.zone.x
  local y = wgt.zone.y + offsetY

  local fieldinfo = getFieldInfo(fieldName)
  local fieldValue = getValue(fieldName)

  if type(fieldValue) == "table" then
    fieldValue = "<TABLE>"
  end

  local txt

  if fieldinfo then
    local idUnit = -1
    if (fieldinfo['unit']) then
      idUnit = fieldinfo['unit']
    end
    --print ("aaaa unit1: " .. txtUnit)
    local txtUnit = "---"
    if (idUnit > 0 and idUnit < #unitToString) then
      print("idUnit: " .. idUnit)
      txtUnit = unitToString[idUnit]
      print("txtUnit: " .. txtUnit)
    end

    local txt = fieldinfo['name'] .. "(id:" .. fieldinfo['id']
      .. ")"
      .. "=" .. fieldValue
      .. txtUnit
      .. " [desc: " .. fieldinfo['desc'] .. "]"

    lcd.drawText(x, y, txt, LEFT + SMLSIZE)


    for k, v in pairs(fieldinfo) do
      if (k ~='name' and k~='id'and k~='desc'and k~='unit') then
        print("found field: " .. k)
      end
    end

  else
    lcd.drawText(x, y + 0, fieldName .. " - field NOT available! ", LEFT + SMLSIZE)
  end
  return
end

local function testPrint(wgt)
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
  return
end


-- This size is for top bar widgets
local function refreshZoneTiny(wgt)
end

--- Size is 160x32 1/8th
local function refreshZoneSmall(wgt)
  testPrint(wgt)
  return
end

--- Size is 225x98 1/4th  (no sliders/trim)
local function refreshZoneMedium(wgt)
  testPrint(wgt)
  return
end

--- Size is 192x152 1/2
local function refreshZoneLarge(wgt)
  testPrint(wgt)
  return
end

--- Size is 460x252 1/1 (no sliders/trim/topbar)
local function refreshZoneXLarge(wgt)
  testPrint(wgt)

  return
end

-- This function allow recording of lowest cells when widget is not active
local function background(wgt)
  if (isWidgetInvalid(wgt)) then return end
  return
end

local function refresh(wgt)

  if (isWidgetInvalid(wgt)) then return end

  if wgt.zone.w > 380 and wgt.zone.h > 165 then
    refreshZoneXLarge(wgt)
  elseif wgt.zone.w > 180 and wgt.zone.h > 145 then
    refreshZoneLarge(wgt)
  elseif wgt.zone.w > 170 and wgt.zone.h > 65 then
    refreshZoneMedium(wgt)
  elseif wgt.zone.w > 150 and wgt.zone.h > 28 then
    refreshZoneSmall(wgt)
  elseif wgt.zone.w > 65 and wgt.zone.h > 35 then
    refreshZoneTiny(wgt)
  end
end

return { name = "t_fieldInfo1", options = options, create = create, update = update, background = background, refresh = refresh }
