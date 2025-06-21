-- A Timer version that fill better the widget area
-- Offer Shmuely
-- Date: 2021-2024
local app_name = "Timer2"
local app_ver = "0.9"

--local progress = 100
local options = {
  { "TextColor", COLOR, YELLOW },
  { "Timer", VALUE, 1, 1, 3},
  { "use_days", BOOL, 0 }   -- if greater than 24 hours: 0=still show as hours, 1=use days

}

local function log(s)
  return;
  --print("timer2: " .. s)
end

local function create(zone, options)
  local wgt = { zone = zone, options = options }
  wgt.options.use_days = wgt.options.use_days % 2 -- modulo due to bug that cause the value to be other than 0|1
  return wgt
end

local function update(wgt, options)
  if (wgt == nil) then return end
  wgt.options = options
  --log("TimerNumB:" .. options.Timer)
end

local function background(wgt)
  return
end

------------------------------------------------------------

local function formatTime(wgt, t1)
  local dd_raw = t1.value
  local isNegative = false
  if dd_raw < 0 then
    isNegative = true
    dd_raw = math.abs(dd_raw)
  end
  log("dd_raw: " .. dd_raw)

  local dd = math.floor(dd_raw / 86400)
  dd_raw = dd_raw - dd * 86400
  local hh = math.floor(dd_raw / 3600)
  dd_raw = dd_raw - hh * 3600
  local mm = math.floor(dd_raw / 60)
  dd_raw = dd_raw - mm * 60
  local ss = math.floor(dd_raw)

  local time_str
  if dd == 0 and hh == 0 then
    -- less then 1 hour, 59:59
    time_str = string.format("%02d:%02d", mm, ss)

  elseif dd == 0 then
    -- lass then 24 hours, 23:59:59
    time_str = string.format("%02d:%02d:%02d", hh, mm, ss)

  else
    -- more than 24 hours
    if wgt.options.use_days == 0 then
      -- 25:59:59
      time_str = string.format("%02d:%02d:%02d", dd * 24 + hh, mm, ss)
    else
      -- 5d 23:59:59
      time_str = string.format("%dd %02d:%02d:%02d", dd, hh, mm, ss)
    end

  end
  if isNegative then
    time_str = '-' .. time_str
  end
  return time_str, isNegative
end

local function getTimerHeader(wgt, t1)
  local timerInfo = ""
  if (string.len(t1.name) == 0) then
    timerInfo = string.format("T%s: ", wgt.options.Timer)
  else
    timerInfo = string.format("T%s: (%s)", wgt.options.Timer, t1.name)
  end
  return timerInfo
end

local function getFontSize(wgt, txt)
  local wide_txt = string.gsub(txt, "[1-9]", "0")
  --log(string.gsub("******* 12:34:56", "[1-9]", "0"))
  log("wide_txt: " .. wide_txt)

  local w,h = lcd.sizeText(wide_txt, XXLSIZE)
  log(string.format("XXLSIZE w: %d, h: %d, %s", w, h, time_str))
  if w < wgt.zone.w and h <= wgt.zone.h then
    return XXLSIZE
  end

  w,h = lcd.sizeText(wide_txt, DBLSIZE)
  log(string.format("DBLSIZE w: %d, h: %d, %s", w, h, time_str))
  if w < wgt.zone.w and h <= wgt.zone.h then
    return DBLSIZE
  end

  w,h = lcd.sizeText(wide_txt, MIDSIZE)
  log(string.format("MIDSIZE w: %d, h: %d, %s", w, h, time_str))
  if w < wgt.zone.w and h <= wgt.zone.h then
    return MIDSIZE
  end

  log(string.format("SMLSIZE w: %d, h: %d, %s", w, h, time_str))
  return SMLSIZE
end

local function drawTicks(wgt)
  if (wgt.zone.h < 50) then return end
  if (wgt.zone.w < 50) then return end

  local isFull = false
  --local centerR = 50
  local centerR = wgt.zone.h / 2
  local centerX = (wgt.zone.x + wgt.zone.w) /2
  local centerY = (wgt.zone.y + wgt.zone.h) / 2
  local fender = 1
  local tickWidth = 9

  -- ticks
  local to_tick = progress * 2.1
  local tick_offset = 250
  local tick_step = 10

  progress = progress - 0.6
  if progress <= 0 then
    progress = 100
  end

  if (centerR < 100) then
    tick_step = 10 + 0.15 * (100 - centerR)
  end

  if progress > 25 then
    color_pie = GREY
    color_annulus = BLACK
    color_pie = lcd.RGB(0, progress, 0)
  elseif progress > 15 then
    color_pie = ORANGE
    color_annulus = ORANGE
  else
    color_pie = RED
    color_annulus = RED
  end
  --lcd.drawPie(centerX,centerY,centerR - fender, 0, 3.60 * progress, color_pie)
  --
  --for i = 0, to_tick, tick_step do
  --  --local newColor = self.getRangeColor(i, 0, to_tick - 10)
  --  --lcd.setColor(CUSTOM_COLOR, newColor)
  --  lcd.setColor(CUSTOM_COLOR, color_annulus)
  --
  --  lcd.drawAnnulus(centerX, centerY,
  --                  centerR - fender - 3 - tickWidth,
  --                  centerR - fender - 3 + 30,
  --                  tick_offset + i,
  --                  tick_offset + i + 7,
  --                  CUSTOM_COLOR)
  --
  --end

  local line_thick = 14
  local r2 = 30
  local r1 = r2 - line_thick
  local x1= wgt.zone.x + r2
  local x2 = wgt.zone.x + wgt.zone.w - r2
  local y1 = wgt.zone.y + r2
  local y2 = wgt.zone.y + wgt.zone.h - r2

  local ofs1 = 0.1
  local ofs2 = 0.1
  local ofs3 = 0.1
  local ofs4 = 0.5
  local ofs5 = 0.5
  local ofs6 = 0.5
  local ofs7 = 0.5
  local ofs8 = 0.5
  local ofs9 = 0.5

  -- top line
  lcd.drawFilledRectangle(wgt.zone.x + wgt.zone.w / 2 + (wgt.zone.x + wgt.zone.w / 2 - r2) * ofs1, wgt.zone.y, (wgt.zone.w /2 -r2) * (1 - ofs1), line_thick, YELLOW)
  lcd.drawAnnulus(x2, y1, r1, r2, 0 + ofs2*90, 90, MIDSIZE + BLUE)

  -- right line
  lcd.drawFilledRectangle(wgt.zone.x + wgt.zone.w - line_thick, r2 + ofs3 * (wgt.zone.y + wgt.zone.h - r2 - r2), line_thick, (wgt.zone.y + wgt.zone.h - r2 - r2) * ofs3, YELLOW)
  lcd.drawAnnulus(x2, y2, r1, r2, 90 + ofs4*90, 180, MIDSIZE + ORANGE)

  -- bottom line
  lcd.drawFilledRectangle(wgt.zone.x + r2, wgt.zone.y + wgt.zone.h - line_thick, wgt.zone.w - r2 -r2 - ofs5, line_thick, YELLOW)
  lcd.drawAnnulus(x1, y2, r1, r2, 180 + ofs6*90, 270, MIDSIZE + BLUE)

  -- left line
  lcd.drawFilledRectangle(wgt.zone.x, r2, line_thick, wgt.zone.y + wgt.zone.h - r2 - r2 - ofs7, YELLOW)
  lcd.drawAnnulus(x1, y1, r1, r2, 270 + ofs8*90, 360, MIDSIZE + ORANGE)

  -- top line
  local len = (wgt.zone.w /2 -r2) - ofs9 * (wgt.zone.w /2 -r2)
  --lcd.drawFilledRectangle(wgt.zone.x + r2 + ofs9 * (wgt.zone.w /2 -r2), wgt.zone.y, len, line_thick, YELLOW)

  lcd.drawFilledCircle(wgt.zone.x + wgt.zone.w - line_thick, wgt.zone.y + wgt.zone.h - r2 - r2, line_thick * 1.3, BLA)
end

local function refresh(wgt, event, touchState)
  if (wgt == nil)               then log("refresh(nil)")                   return end
  if (wgt.options == nil)       then log("refresh(wgt.options=nil)")       return end
  if (wgt.options.Timer == nil) then log("refresh(wgt.options.Timer=nil)") return end

  local t1 = model.getTimer(wgt.options.Timer - 1)

  -- calculate timer info
  local timerInfo = getTimerHeader(wgt, t1)
  local timer_info_w, timer_info_h = lcd.sizeText(timerInfo, SMLSIZE)

  -- calculate timer time
  local time_str, isNegative = formatTime(wgt, t1)
  local font_size = getFontSize(wgt, time_str)
  local zone_w = wgt.zone.w
  local zone_h = wgt.zone.h

  local textColor
  if isNegative == true then
    textColor = RED
  else
    textColor = wgt.options.TextColor
  end

  local font_size_header = SMLSIZE
  if (event ~= nil) then -- app mode (full screen)
    font_size = XXLSIZE
    font_size_header = DBLSIZE
    zone_w = 460
    zone_h = 252
  end

  --drawTicks(wgt)

  local wide_time_str = string.gsub(time_str, "[1-9]", "0")
  local ts_w,ts_h = lcd.sizeText(wide_time_str, font_size)
  local dx = (zone_w - ts_w) /2
  local dy = timer_info_h -1
  if (timer_info_h + ts_h > zone_h) and (zone_h < 50) then
    log(string.format("--- not enough height, force minimal spaces"))
    dy = 10
  end

  --log(string.format("timer_info: timer_info_x:%d, timer_info_h: %d", timer_info_w, timer_info_h))
  --log(string.format("x=%d, y=%d, w=%d, h=%d", wgt.zone.x, wgt.zone.y, zone_w, zone_h))
  --log(string.format("dx: %d, dy: %d, zone_w: %d, zone_h: %d, ts_w: %d, ts_h: %d)", dx, dy, zone_w ,zone_h , ts_w, ts_h))

  -- draw timer info
  lcd.drawText(wgt.zone.x, wgt.zone.y, timerInfo, font_size_header + textColor)

  -- draw timer time
  lcd.drawText(wgt.zone.x + dx, wgt.zone.y + dy, time_str, font_size + textColor)

  --lcd.drawText(wgt.zone.x+100, wgt.zone.y, string.format("%d%%", getUsage()), SMLSIZE + CUSTOM_COLOR)
end

return { name=app_name, options=options, create=create, update=update, background=background, refresh=refresh }
