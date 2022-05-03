local wgt_options_source, sampleIntervalMili = ...

local self = {}
self.wgt_options_source = wgt_options_source
self.buckets = {
  --{ 0, 10 }, { 10, 0 }, { 20, 1 }, { 30, 150 }, { 40, 50 }, { 50, 80 }, { 60, 10 }, { 70, 5 }, { 80, 50 }, { 90, 50 }, { 100, 10 },
  { 0, 0 }, { 10, 0 }, { 20, 0 }, { 30, 0 }, { 40, 0 }, { 50, 0 }, { 60, 0 }, { 70, 0 }, { 80, 0 }, { 90, 0 }, { 100, 0 },
  --{ 50, 80 }, { 60, 10 }, { 70, 5 }, { 80, 50 }, { 90, 50 }, { 50, 80 }, { 60, 10 }, { 70, 5 }, { 80, 50 }, { 90, 50 },
}
self.minVal = nil
self.maxVal = nil
self.periodic1 = {startTime = getTime(), sampleIntervalMili = sampleIntervalMili}

--------------------------------------------------------------
local function log(s)
  --return;
  print("appHist: " .. s)
end
--------------------------------------------------------------

-----------------------------------------------------------------
local function periodicReset(t)
  t.startTime = getTime();
end
local function periodicHasPassed(t)
  local elapsed = getTime() - t.startTime;
  local elapsedMili = elapsed * 10;
  if (elapsedMili < t.sampleIntervalMili) then
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


function self.updateBucketsIfNeeded()
  if (periodicHasPassed(self.periodic1)) then
    self.updateBuckets(self.wgt_options_source)
    periodicReset(self.periodic1)
  end

end

function self.updateBuckets(wgt_options_source)

  local value = getValue(wgt_options_source)
  if (value == nil) then
    return
  end


  for i, v in ipairs(self.buckets) do
    local bucket_val = v[1]
    local sample_count = v[2]
    if value <= bucket_val then
      v[2] = sample_count + 1
      log(string.format("found value: %d - %d", v[1], v[2]))
      break
    end
  end

  if self.minVal == nil or value < self.minVal
  then
    self.minVal =value
  end

  if self.maxVal == nil or value > self.maxVal
  then
    self.maxVal =value
  end
  log(string.format("minVal: %d, maxVal: %d", self.minVal, self.maxVal))

end

function self.drawHist(wgt, percentageValue, percentageValueMin, percentageValueMax, txt1, txt2)


  --lcd.clear()
  local valueCurr = 50
  local presetMin = 0
  local presetMax = 100

  -- draw current value
  if self.minVal ~= nil and self.maxVal ~= nil
  then
    lcd.drawText(5, 60, string.format("%d db (min: %d, max: %d)", valueCurr, self.minVal, self.maxVal), 0 + MIDSIZE + CUSTOM_COLOR)
  end

  -- properties
  local margin_top = 90
  local margin_buttom = 20
  local margin_left = 10
  local margin_right = 10

  local bar_dist = (wgt.zone.w - margin_left - margin_right) / #self.buckets
  local space = 4
  local bar_width = bar_dist - space

  -- draw main bar
  local xMin = wgt.zone.x + margin_left
  local xMax = wgt.zone.x + wgt.zone.w
  local yMin = wgt.zone.y + wgt.zone.h - margin_buttom
  local yMax = wgt.zone.y - margin_top
  local hist_height = wgt.zone.h - margin_buttom - margin_top
  log(string.format("y: %d, h: %d", wgt.zone.y, wgt.zone.h))

  --local total_sample_count = 0
  local sample_count = 0
  local max_count = 0
  for i, v in ipairs(self.buckets) do
    sample_count = v[2]
    if sample_count > max_count then
      max_count = sample_count
    end
    --total_sample_count = total_sample_count + sample_count
  end


  local xx = xMin
  local sample_count = 0
  for i, v in ipairs(self.buckets) do
    sample_count = v[2]
    local bar_height = (sample_count / max_count) * hist_height
    --local signalPercent = 100 * ((val - presetMin) / (presetMax - presetMin))

    lcd.drawFilledRectangle(xx, yMin - bar_height, bar_width,bar_height, CUSTOM_COLOR)
    --lcd.drawFilledRectangle(xx, yMin - h, bar_width, h, CUSTOM_COLOR)
    lcd.drawText(xx, yMin, v[1], 0 + CUSTOM_COLOR)
    xx = xx + bar_dist
  end

end

return self