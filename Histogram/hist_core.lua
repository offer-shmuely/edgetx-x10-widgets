local wgt_options_source, sampleIntervalMili = ...

local self = {}
self.wgt_options_source = wgt_options_source
--self.buckets = {}
--self.buckets_sorted_keys = {}
self.buckets = {
-- { 0, 0 }, { 10, 0 }, { 20, 0 }, { 30, 0 }, { 40, 0 }, { 50, 0 }, { 60, 0 }, { 70, 0 }, { 80, 0 }, { 90, 0 }, { 100, 0 },
  --{ -100, 0 }, { -95, 0 }, { -90, 0 }, { -85, 0 }, { -80, 0 }, { -75, 0 }, { -70, 0 }, { -65, 0 }, { -60, 0 }, { -55, 0 }, { -50, 0 }, { -45, 0 }, { -40, 0 }, { -35, 0 }, { -30, 0 }, { -25, 0 }, { -20, 0 }, { -15, 0 }, { -10, 0 }, { -5, 0 }, { 0, 0 },
--{ 0, 0 }, { 100, 0 }, { 200, 0 }, { 300, 0 }, { 400, 0 }, { 500, 0 }, { 600, 0 }, { 700, 0 }, { 800, 0 }, { 900, 0 }, { 1000, 0 },
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
function self.tableSort(t)
  self.tablePrint(t, "before sort")

  local a = {}

  for i,n in ipairs(t) do
    --print(i .. ": " .. n[1] .. " -?- " .. n[2])
    table.insert(a, n[1])
  end

  table.sort(a, f)

  local sorted_buckets = {}
  for i,n in ipairs(a) do
    key = n
    val = t[i][2]
    log("key: " .. n .. ", val: " .. val)
    table.insert(sorted_buckets, {key, val})
  end

  self.tablePrint(sorted_buckets, "after sort")
  return sorted_buckets
end

function self.tablePrint(t, prefix)
  for i,n in ipairs(t) do
    log("[" .. prefix .. "] " .. i .. ". " .. n[1] .. "-" .. n[2])
  end
end

function self.tableGet(t, key)
  for i,n in ipairs(t) do
    log("[tableGet] " .. i .. ". " .. n[1] .. "-" .. n[2])
    if n[1] == key then
      log("tableGet(" .. key .. ") --> " .. n[2])
      return n[2]
    end
    --log("[" .. prefix .. "] " .. i .. ". " .. n[1] .. "-" .. n[2])
  end
  log("!!!! (tableGet) not found[" .. key .. "] ")
  return nil
end

function self.tableSet(t, key, value)
  for i,n in ipairs(t) do
    if n[1] ~= key then
      log("[tableSet] " .. i .. ". " .. n[1] .. "-" .. n[2])
    else
      t[i][2] = value
      return
    end
    log("!!!! tableSet not found[" .. key .. "] ")
  end

  log("[tableSet] " .. i .. ". " .. n[1] .. "-" .. n[2])
end

function self.tableIncrement(t, key)
  for i,n in ipairs(t) do
    log("[tableIncrement] " .. i .. ". " .. n[1] .. "-" .. n[2])

    if n[1] ~= key then
      log("[tableIncrement]" .. i .. ". " .. n[1] .. "-" .. n[2])
    else
      t[i][2] = t[i][2] + 1
      return
    end
  end

  log("!!!! (tableIncrement) not found[" .. key .. "] ")
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

  --self.tablePrint(self.buckets, "before sort")
  --local sorted_buckets = self.tableSort(self.buckets)
  --self.buckets = sorted_buckets
  --self.tablePrint(self.buckets, "after sort")


  --self.updateBuckets(self.wgt_options_source)
  self.updateBucketsAuto(self.wgt_options_source)
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

  --if self.buckets[value] == nil then
  if self.tableGet(self.buckets, value) == nil then

    table.insert(self.buckets, {value, 0})
    --table.insert(self.buckets, 5)
    --table.insert(self.buckets, 9)
    --self.buckets[5] = 55
    --self.buckets[7] = 77
    --self.buckets[9] = 99
    --log(string.format("@ self.buckets[9] = %d", self.buckets[9]))
    --log(string.format("@ self.buckets[7] = %d", self.buckets[7]))
    --log(string.format("@ self.buckets[5] = %d", self.buckets[5]))

    local sorted_buckets = self.tableSort(self.buckets)
    self.buckets = sorted_buckets


  end

  -- +1 to the sample-count of the correct bucket
  self.tableIncrement(self.buckets, value)

  --self.buckets[value] = self.buckets[value] + 1
  --log(string.format("self.buckets[%d]: %d", value, self.buckets[value]))

  --for i, v in ipairs(self.buckets) do
  --  local bucket_val = v[1]
  --  local sample_count = v[2]
  --  if value <= bucket_val then
  --    v[2] = sample_count + 1
  --    log(string.format("found value: %d - %d", v[1], v[2]))
  --    break
  --  end
  --end
  --

  log("------------------------")
  self.tablePrint(self.buckets, "last")
  log("------------------------")


  -- calc min/max
  if self.minVal == nil or value < self.minVal
  then
    self.minVal =value
  end

  if self.maxVal == nil or value > self.maxVal
  then
    self.maxVal =value
  end

  --log(string.format("minVal: %d, maxVal: %d", self.minVal, self.maxVal))
end

function self.drawHist(wgt)

  --lcd.clear()
  local valueCurr = getValue(wgt_options_source)
  local presetMin = 0
  local presetMax = 100

  -- draw current value
  if self.minVal ~= nil and self.maxVal ~= nil
  then
    lcd.drawText(5, 60, string.format("%d (min: %d, max: %d)", valueCurr, self.minVal, self.maxVal), 0 + MIDSIZE + CUSTOM_COLOR)
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
  --log(string.format("y: %d, h: %d", wgt.zone.y, wgt.zone.h))

  -- calculate max_count
  --local total_sample_count = 0
  local sample_count = 0
  local max_count = 0
  local sample_count_log = 0
  for i, v in ipairs(self.buckets) do
    sample_count = v[2]
    if sample_count == 0 then
      sample_count_log = 0
    else
      sample_count_log = math.log(sample_count)
    end
    if sample_count_log > max_count then
      max_count = sample_count_log
    end
    --if sample_count > max_count then
    --  max_count = sample_count
    --end
    --total_sample_count = total_sample_count + sample_count
  end

  -- print histogram
  local xx = xMin
  local sample_count = 0
  local sample_count_log = 0
  for i, v in ipairs(self.buckets) do
    sample_count = v[2]
    if sample_count == 0 then
      sample_count_log = 0
    else
      sample_count_log = math.log(sample_count)
    end
    local bar_height = (sample_count_log / max_count) * hist_height
    --local signalPercent = 100 * ((val - presetMin) / (presetMax - presetMin))

    lcd.drawFilledRectangle(xx, yMin - bar_height, bar_width,bar_height, CUSTOM_COLOR)
    --lcd.drawFilledRectangle(xx, yMin - h, bar_width, h, CUSTOM_COLOR)
    lcd.drawText(xx, yMin-50, v[2], 0 + SMLSIZE)
    lcd.drawText(xx, yMin-30, string.format("%.1f", sample_count_log), 0 + SMLSIZE)
    lcd.drawText(xx, yMin, v[1], 0 + CUSTOM_COLOR)
    xx = xx + bar_dist
  end

end

return self