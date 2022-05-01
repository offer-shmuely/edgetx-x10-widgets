local app_name = "GaugeDash3"
local value2 = { 95, 0, 100 , -1}
local cx = { 200, 197, 400, 1}
local cy = { 100, 90, 121, 0 }
local cr = { 60, 40, 90, 1 }

local _options = {
  { "Source", SOURCE, 1 },
  { "Min", VALUE, 0, -1024, 1024 },
  { "Max", VALUE, 100, -1024, 1024 },
  { "HighAsGreen", BOOL,  1 }
}

--------------------------------------------------------------
local function log(s)
  --	return;
  print("Gauge3: " .. s)
end
--------------------------------------------------------------

local function create(zone, options)
  local GaugeClass = loadScript("/WIDGETS/".. app_name .. "/gauge_core.lua")
  local wgt = {
    zone = zone,
    options = options,
    bgImage = imgBg,
    gauge1 = GaugeClass(options.HighAsGreen, 2)
  }

  return wgt
end

local function update(wgt, options)
  wgt.options = options
end

local function getPercentageValue(value, options_min, options_max)
  local percentageValue = value - options_min;
  percentageValue = (percentageValue / (options_max - options_min)) * 100

  if percentageValue > 100 then
    percentageValue = 100
  elseif percentageValue < 0 then
    percentageValue = 0
  end

  log("getPercentageValue(" .. value .. ", " .. options_min .. ", " .. options_max .. "-->" .. percentageValue)
  return percentageValue
end


local function update_randomizer(value)
  local current_vlue = value[1]
  local min = value[2]
  local max = value[3]
  local step = value[4]
  current_vlue = current_vlue + step
  if (step>0) then
    if (current_vlue >= max) then
      --current_vlue = min
      value[4] = value[4] * -1
    end
  else
    if (current_vlue <= min) then
      --current_vlue = max
      value[4] = value[4] * -1
    end
  end
  value[1] = current_vlue
end

local function refresh(wgt)
  if (wgt == nil) then return end
  if (wgt.options == nil) then return end
  if (wgt.zone == nil) then return end

  local ver, radio, maj, minor, rev, osname = getVersion()
  print("version: "..ver)
  if maj == 2 and minor <5 then
      print ("this widget is NOT SUPPORTED at this version")
  end

  if osname ~= "EdgeTX" then
    print ("this widget is supported only on EdgeTX:" ..osname)
  end

  update_randomizer(value2)
  update_randomizer(cx)
  update_randomizer(cy)
  update_randomizer(cr)

  percentageValue2 = getPercentageValue(value2[1], value2[2], value2[3])
  wgt.gauge1.drawGauge(100, 84, 78, true, percentageValue2, 0,0,percentageValue2 .. "%", "Fuel\n  %")
  wgt.gauge1.drawGauge(cx[1], cy[1], cr[1], true, percentageValue2, 0,0,percentageValue2 .. "%", "Fuel\n  %")
  wgt.gauge1.drawGauge(300, 150, 60, true, percentageValue2, 0,0,percentageValue2, "V")


  -- widget load (debugging)
  lcd.drawText(wgt.zone.x + 10,  wgt.zone.y, string.format("load: %d%%", getUsage()), SMLSIZE +WHITE) -- ???
  lcd.drawText(wgt.zone.x + 300, wgt.zone.y, string.format("R: %d", cr[1]), MIDSIZE +WHITE) -- ???

end

return { name = app_name, options = _options, create = create, update = update, refresh = refresh }
