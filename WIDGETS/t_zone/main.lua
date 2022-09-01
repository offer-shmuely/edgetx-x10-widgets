
local options = {
  { "Color", COLOR, WHITE }
}

local function create(zone, options)
  local wgt  = { zone=zone, options=options}
  return wgt
end

local function update(wgt, options)
  if (wgt==nil) then
    print("update(nil)")
    return
  end
  wgt.options = options
end

local function background(wgt)
  return
end

local function refresh(wgt)
  if (wgt==nil) then
    print("refresh(nil)")
    return
  end

  if (wgt.options==nil) then
    print("refresh(wgt.options=nil)")
    return
  end

  lcd.setColor(CUSTOM_COLOR, lcd.RGB(0, 150, 0))
  --lcd.setColor(CUSTOM_COLOR, GREY)
  lcd.drawFilledRectangle(wgt.zone.x, wgt.zone.y, wgt.zone.w, wgt.zone.h, CUSTOM_COLOR)
  lcd.drawRectangle(wgt.zone.x, wgt.zone.y, wgt.zone.w, wgt.zone.h, BLACK)
  --
  local myString = string.format("%sx%s (%s,%s)", wgt.zone.w, wgt.zone.h, wgt.zone.x, wgt.zone.y)
  lcd.drawText(wgt.zone.x, wgt.zone.y, myString, LEFT + INVERS +CUSTOM_COLOR);

end

return { name="t_zone", options=options, create=create, update=update, background=background, refresh=refresh }
