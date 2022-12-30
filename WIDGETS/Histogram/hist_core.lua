local wgt_options_source, sampleIntervalMili = ...

local self = {}
self.wgt_options_source = wgt_options_source
self.buckets = {}
self.buckets_sorted_keys = {}
--self.buckets = {
-- { 0, 0 }, { 10, 0 }, { 20, 0 }, { 30, 0 }, { 40, 0 }, { 50, 0 }, { 60, 0 }, { 70, 0 }, { 80, 0 }, { 90, 0 }, { 100, 0 },
  --{ -100, 0 }, { -95, 0 }, { -90, 0 }, { -85, 0 }, { -80, 0 }, { -75, 0 }, { -70, 0 }, { -65, 0 }, { -60, 0 }, { -55, 0 }, { -50, 0 }, { -45, 0 }, { -40, 0 }, { -35, 0 }, { -30, 0 }, { -25, 0 }, { -20, 0 }, { -15, 0 }, { -10, 0 }, { -5, 0 }, { 0, 0 },
--{ 0, 0 }, { 100, 0 }, { 200, 0 }, { 300, 0 }, { 400, 0 }, { 500, 0 }, { 600, 0 }, { 700, 0 }, { 800, 0 }, { 900, 0 }, { 1000, 0 },
--}
self.minVal = nil
self.maxVal = nil
self.max_sample_count_log = 0
self.unit = "na"
--self.unit = wgt.tools.unitIdToString(fieldinfo.unit)

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
--function self.bucketsSort(t)
--  self.bucketsPrint(t, "before sort")
--
--  local a = {}
--
--  for i,n in ipairs(t) do
--    --print(i .. ": " .. n[1] .. " -?- " .. n[2])
--    table.insert(a, n[1])
--  end
--
--  table.sort(a, f)
--
--  local sorted_buckets = {}
--  for i,n in ipairs(a) do
--    key = n
--    val = t[i][2]
--    log("key: " .. n .. ", val: " .. val)
--    table.insert(sorted_buckets, {key, val})
--  end
--
--  self.bucketsPrint(sorted_buckets, "after sort")
--  return sorted_buckets
--end

function self.bucketsPrint(prefix)
  for i,n in ipairs(self.buckets_sorted_keys) do
    log("[" .. prefix .. "] " .. i .. ". " .. n .. "-" .. self.buckets[n])
  end
end

function self.bucketsAddNewItem(key, value)
  if self.buckets[key] ~= nil then
    return
  end
  table.insert(self.buckets_sorted_keys, key)
  self.buckets[key] = value
end

function self.bucketsIncrement(key)
  self.buckets[key] = self.buckets[key] + 1
end
-----------------------------------------------------------------


function self.updateBucketsIfNeeded()
  if (periodicHasPassed(self.periodic1) == false) then
    --log(".")
    return
  end

  --table.insert(self.buckets, {2,2} )
  --table.insert(self.buckets, {3,3} )
  --table.insert(self.buckets, {4,4} )
  --self.buckets[5] = { 55 , 1}
  --self.buckets[7] = {77 , 7}
  --self.buckets[9] = {99 , 9}

  --self.bucketsPrint("before sort")
  --local sorted_buckets = self.bucketsSort(self.buckets)
  --self.buckets = sorted_buckets
  --self.bucketsPrint("after sort")


  --self.updateBuckets(self.wgt_options_source)
  self.updateBucketsAuto(self.wgt_options_source)

  log("------------------------")
  self.bucketsPrint("last")
  log("------------------------")

  periodicReset(self.periodic1)
end

function self.updateBuckets(wgt_options_source)
  local value = getValue(wgt_options_source)
  if (value == nil) then return end

  -- +1 to the sample-count of the correct bucket
  for i, v in ipairs(self.buckets) do
    local bucket_val = v[1]
    local sample_count = v[2]
    if value <= bucket_val then
      v[2] = sample_count + 1
      log(string.format("found value: %d - %d", v[1], v[2]))
      break
    end
  end

  -- calc min/max
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

function self.updateBucketsAuto(wgt_options_source)
  local value = getValue(wgt_options_source)
  if (value == nil) then return end

  log("self.buckets[" .. value .. "]: ")

  -- calc min/max
  if self.minVal == nil or value < self.minVal
  then
    self.minVal =value
  end

  if self.maxVal == nil or value > self.maxVal
  then
    self.maxVal =value
  end

  if self.buckets[value] == nil then
    log("!!!! (tableIncrement) not found[" .. value .. "] ")
    self.bucketsAddNewItem(value, 0)
    self.bucketsPrint("after adding new value")

    log("????????????????????filling table gaps")
    if self.minVal ~= nil and self.maxVal ~= nil then
      log("filling table gaps")
      for i = self.minVal, self.maxVal, 1 do
        if self.buckets[i] == nil then
          log("+++ fill table: ".. i)
          self.bucketsAddNewItem(i,0)
        end
      end
    end

    table.sort(self.buckets_sorted_keys)
  end

  -- +1 to the sample-count of the correct bucket
  self.bucketsIncrement(value)

  log(string.format("minVal: %d, maxVal: %d", self.minVal, self.maxVal))
end

function self.drawHist(wgt)
  --self.bucketsPrint("drawHist")

  local valueCurr = getValue(wgt_options_source)
  local presetMin = 0
  local presetMax = 100

  -- draw current value
  if self.minVal ~= nil and self.maxVal ~= nil
  then
    lcd.drawText(5, 25, string.format("%d %s (%d - %d %s)", valueCurr,self.unit, self.minVal, self.maxVal, self.unit), 0 + MIDSIZE + YELLOW)
  end

  -- properties
  local margin_top = 90
  local margin_buttom = 20
  local margin_left = 10
  local margin_right = 10

  local bar_dist = (wgt.zone.w - margin_left - margin_right) / #self.buckets_sorted_keys
  local space = 4
  local bar_width = bar_dist - space

  -- draw main bar
  local xMin = wgt.zone.x + margin_left
  local xMax = wgt.zone.x + wgt.zone.w
  local yMin = wgt.zone.y + wgt.zone.h - margin_buttom
  local yMax = wgt.zone.y - margin_top
  local hist_height = wgt.zone.h - margin_buttom - margin_top
  --log(string.format("y: %d, h: %d", wgt.zone.y, wgt.zone.h))

  -- print histogram
  local xx = xMin
  for i,n in ipairs(self.buckets_sorted_keys) do
    local key = n
    local sample_count = self.buckets[n]
    local sample_count_log = 0
    if sample_count > 0 then
      sample_count_log = math.log(sample_count)
    end

    if sample_count_log > self.max_sample_count_log then
      self.max_sample_count_log = sample_count_log
    end

    local bar_height = (sample_count_log / self.max_sample_count_log) * hist_height
    --local signalPercent = 100 * ((val - presetMin) / (presetMax - presetMin))

    local bar_color = YELLOW
    if n == valueCurr then
      bar_color = GREEN
    end

    lcd.drawFilledRectangle(xx, yMin - bar_height, bar_width,bar_height, bar_color)
    if #self.buckets_sorted_keys <= 17 then
      lcd.drawText(xx, yMin-50, sample_count, 0 + SMLSIZE)
      lcd.drawText(xx, yMin-30, string.format("%.1f", sample_count_log), 0 + SMLSIZE)
    end
    if #self.buckets_sorted_keys <= 25 then
      lcd.drawText(xx, yMin, key, 0 + CUSTOM_COLOR)
    end

    xx = xx + bar_dist
  end

end

return self