
local options = {
  { "Source", SOURCE, 1 },
  { "TextColor", COLOR, YELLOW }
}

local function log(s)
  print("app: " .. s)
end
--------------------------------------------------------------
--periodic1 = {startTime = -1, durationInMili = -1},
--local function periodicInit(t, durationInMili)
--  t.startTime = getTime();
--  t.durationInMili = durationInMili;
--end
local function periodicReset(t)
  t.startTime = getTime();
end
local function periodicHasPassed(t)
  local elapsed = getTime() - t.startTime;
  local elapsedMili = elapsed * 10;
  if (elapsedMili < t.durationInMili) then
    return false;
  end
  return true;
end
local function periodicGetElapsedTime(t)
  local elapsed = getTime() - t.startTime;
  --log(string.format("elapsed: %d",elapsed));
  local elapsedMili = elapsed * 10;
  --log(string.format("elapsedMili: %d",elapsedMili));
  return elapsedMili;
end
-----------------------------------------------------------------

local function create(zone, options)
  local wgt = {
    zone = zone,
    options = options,
    loopCounter = 0,
    periodicLoopCounter1 = 0,
    periodicLoopCounter2 = 0,
    periodic1 = {startTime = getTime(), durationInMili = 2000},
    periodic2 = {startTime = getTime(), durationInMili = 500},
  }
  return wgt
end

local function update(wgt, options)
  if (wgt == nil) then return end
  wgt.options = options
end

local function background(wgt)
  if (wgt == nil) then return end

end

local function showLocatTimer(name, wgt, t, offsetY)
  local x = wgt.zone.x
  local y = wgt.zone.y + offsetY
  local txt = string.format("%s: start: %d, dur: %d,  elapsed: %d", name, t.startTime, t.durationInMili, periodicGetElapsedTime(t))
  lcd.drawText(x, y, txt, LEFT + SMLSIZE)
end


function refresh(wgt)
  if (wgt == nil) then return end
  if wgt.zone.w  <= 170 or wgt.zone.h <=  65 then return  end

  wgt.loopCounter =  wgt.loopCounter +1;
  if (periodicHasPassed(wgt.periodic1)) then
    wgt.periodicLoopCounter1 = wgt.periodicLoopCounter1 +1;
    periodicReset(wgt.periodic1)
  end
  if (periodicHasPassed(wgt.periodic2)) then
    wgt.periodicLoopCounter2 = wgt.periodicLoopCounter2 +1;
    periodicReset(wgt.periodic2)
  end

  lcd.drawText(wgt.zone.x, wgt.zone.y + 0, string.format("loopCounter: %d", wgt.loopCounter), SMLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x, wgt.zone.y + 15, string.format("periodicLoopCounter1: %d", wgt.periodicLoopCounter1), SMLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x, wgt.zone.y + 30, string.format("periodicLoopCounter2: %d", wgt.periodicLoopCounter2), SMLSIZE + CUSTOM_COLOR)

  showLocatTimer("periodic1", wgt, wgt.periodic1, 50)
  showLocatTimer("periodic2", wgt, wgt.periodic2, 65)
  --showLocatTimer("periodic1", wgt, wgt.periodic1, 80)
  --showLocatTimer(wgt, wgt.periodic1, 90)

end

return { name = "t_periodic", options = options, create = create, update = update, background = background, refresh = refresh }
