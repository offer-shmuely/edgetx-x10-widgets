-- Gauge widget, to provide real-time gauge
-- Possible usages are: Temp / rpm / batt-capacity visualizing.
-- Version        : 2.0
-- Original Author: Herman Kruisman (herman@ccme.nl, Tadango online)
-- Author         : Offer Shmuely
-- Option         : Source, min / max value


-- Zone sizes WxH(wo menu / w menu):
-- 2x4 = 160x32
-- 2x2 = 225x122/98
-- 2x1 = 225x252/207
-- 2+1 = 192x152 & 180x70
-- 1x1 = 460/390x252/217/172
--Heights: 32,70,98,122,152,172,207,217,252

--- Zone size: 160x32 1/8th
--- Zone size: 180x70 1/4th  (with sliders/trim)
--- Zone size: 225x98 1/4th  (no sliders/trim)
--- Zone size: 192x152 1/2
--- Zone size: 390x172 1/1
--- Zone size: 460x252 1/1 (no sliders/trim/topbar)

local unitToString = { "V", "A", "mA", "kts", "m/s", "f/s", "km/h", "km/h", "mph", "m", "m", "f", "�C", "�C", "�F", "%", "mAh", "W", "mW", "dB", "rpms", "g", "�", "Rad" }

local _options = {
	{ "Source"      , SOURCE,   1 },
	{ "Min"         , VALUE ,   0 , -1024, 1024 },
	{ "Max"         , VALUE , 100 , -1024, 1024 },
	{ "HighAsGreen" , BOOL  ,   1 }
}


function getFieldUnits(Source)
	local fieldinfo = getFieldInfo(Source)
	if (fieldinfo == nil) then
	  print(string.format("getFieldInfo(%s)==nil", Source))
	else
	  local txt = fieldinfo['name'] .. "(id:" .. fieldinfo['id']
		.. ")"
		.. "=" .. fieldValue
		.. txtUnit
		.. " [desc: " .. fieldinfo['desc'] .. "]"
  
  
		print("getFieldInfo()="   .. txt)
		--print("getFieldInfo().name:" .. fieldinfo.name)
		--print("getFieldInfo().desc:" .. fieldinfo.desc)
  
		local txtUnit = "---"
		if (fieldinfo['unit']) then
			local idUnit = fieldinfo['unit']

			if (idUnit > 0 and idUnit < #unitToString) then
				print("idUnit: " .. idUnit)
				txtUnit = unitToString[idUnit]
				print("txtUnit: " .. txtUnit)
				return txtUnit
			end
		end
	end
	
	return 'no-units'

end


function create(zone, options)
	-- calculate image file name
	local imageFileHighAsRed   = "/WIDGETS/Gauge2/img/h_"          .. zone.h .. ".png"
	local imageFileHighAsGreen = "/WIDGETS/Gauge2/img/h_"          .. zone.h .. "_op.png"
	local circleFile           = "/WIDGETS/Gauge2/img/arm_circle_" .. zone.h .. ".png"
	local highAsGreen = options.HighAsGreen % 2 -- modulo due to bug that cause the value to be other than 0|1
	local imgBg = Bitmap.open(imageFileHighAsRed)
	if (highAsGreen == 1) then
		imgBg = Bitmap.open(imageFileHighAsGreen)
	end

	local units = getFieldUnits(options.Source)

	-- 
	local wgt = {
		zone=zone,
		options=options,
		bgImage=imgBg,
		circleImage = Bitmap.open(circleFile),
		units=units
	}

	-- cleanup
	imageFileHighAsRed = nil
	imageFileHighAsGreen = nil
	return wgt

end

function printSomeInfo(wgt)

	local filedKey = wgt.options.Source
	print("wgt.options.Source:" .. wgt.options.Source)
	print("filedKey:" .. filedKey)
	
	local fieldInfo = getFieldInfo('alt')
	if fieldInfo == nil then
		print("fieldInfo:" .. 'nil')
	else
		print("fieldInfo:" .. fieldInfo)
	end

	local fieldInfo1 = getFieldInfo(filedKey)
	if fieldInfo1 == nil then
		print("fieldInfo1:" .. 'nil')
	else
		print("fieldInfo1:" .. fieldInfo1)
	end

	--local fieldInfo1 = getFieldInfo(filedKey).id
	--print("getFieldInfo().id:" .. getFieldInfo(filedKey).id)
	--print("getFieldInfo().name:" .. getFieldInfo(filedKey).name)
	--print("getFieldInfo().desc:" .. getFieldInfo(filedKey).desc)
	--if (getFieldInfo(filedKey).unit) then
	--	print("getFieldInfo().unit:" .. getFieldInfo(filedKey).unit)
	--
	--end

	local units = getFieldUnits(wgt.options.Source)
	print("units:" .. units)

end

function getPrecentegeValue(wgt)

	printSomeInfo(wgt)

	local valStr = 'N/A' .. wgt.units
	--value = 60
	local value = getValue(wgt.options.Source)

	if(value == nil) then
		return nil,nil
	end
	
	-- local valStr = string.format("%2.1fV %s", value, getFieldInfo(filedKey).name)

	--Value from source in percentage
	local percentageValue = value * 10 - wgt.options.Min;

	percentageValue = (percentageValue / (wgt.options.Max - wgt.options.Min)) * 100

	if percentageValue > 100 then
		percentageValue = 100
	elseif percentageValue < 0 then
		percentageValue = 0
	end

	return percentageValue, valStr

end

function drawGauge(wgt)

	lcd.drawBitmap(wgt.bgImage, wgt.zone.x, wgt.zone.y)


	percentageValue, valStr = getPrecentegeValue(wgt)

	--min = 5.54
	--max = 0.8
	local degrees = 5.51 - (percentageValue / (100 / 4.74));

	local x2 = math.floor(wgt.zone.x + (wgt.zone.h/2) + (math.sin(degrees) * (wgt.zone.h/2.3)))
	local y2 = math.floor(wgt.zone.y + (wgt.zone.h/2) + (math.cos(degrees) * (wgt.zone.h/2.3)))

	lcd.setColor(CUSTOM_COLOR, lcd.RGB(0,0,255))
	lcd.setColor(CUSTOM_COLOR, lcd.RGB(255,255,255))
	for deg = 0, 3, 0.05 do
		local x1 = math.floor(wgt.zone.x + (wgt.zone.h/2) - (math.sin(deg) * (20/2.3)))
		local y1 = math.floor(wgt.zone.y + (wgt.zone.h/2) - (math.cos(deg) * (20/2.3)))
		lcd.drawLine(x1, y1, x2, y2, SOLID, CUSTOM_COLOR)
	end

	lcd.setColor(CUSTOM_COLOR, lcd.RGB(255,255,255))
	lcd.drawBitmap(wgt.circleImage, wgt.zone.x, wgt.zone.y )

	local flags1 = DBLSIZE +RIGHT + TEXT_COLOR


	if wgt.zone.w < 100 or wgt.zone.h < 60 then
		flags1 = flags1 + SMLSIZE
	end

	if     wgt.zone.w  > 380 and wgt.zone.h > 165 then
		-- 1/1
		lcd.drawSource(wgt.zone.x + wgt.zone.w, wgt.zone.y + 1, wgt.options.Source, DBLSIZE +RIGHT + TEXT_COLOR)
		lcd.drawText  (wgt.zone.x + wgt.zone.w, wgt.zone.y + 50, valStr, XXLSIZE +RIGHT + TEXT_COLOR)
	elseif wgt.zone.w  > 180 and wgt.zone.h > 145 then
		--1/2
		lcd.drawSource(wgt.zone.x + wgt.zone.w, wgt.zone.y + 1, wgt.options.Source, DBLSIZE +RIGHT + TEXT_COLOR)
		lcd.drawText  (wgt.zone.x + wgt.zone.w, wgt.zone.y + wgt.zone.h - 19, valStr, flags1)
	elseif wgt.zone.w  > 170 and wgt.zone.h >  65 then
		--1/4
		lcd.drawSource(wgt.zone.x + 120, wgt.zone.y + 1, wgt.options.Source, MIDSIZE + TEXT_COLOR)
		lcd.drawText  (wgt.zone.x + 120, wgt.zone.y + 40, valStr,            MIDSIZE + TEXT_COLOR)
	elseif wgt.zone.w  > 150 and wgt.zone.h >  28 then
		--1/8
		lcd.drawSource(wgt.zone.x + 70, wgt.zone.y + 1, wgt.options.Source, SMLSIZE + TEXT_COLOR)
		lcd.drawText  (wgt.zone.x + 110, wgt.zone.y + 1, valStr, SMLSIZE +TEXT_COLOR)
	elseif wgt.zone.w  >  65 and wgt.zone.h >  35 then
		--tobbar
	end

	--if wgt.zone.w > wgt.zone.h * 1.6 or wgt.zone.h > 100 then
	--	lcd.drawSource(wgt.zone.x + wgt.zone.w, wgt.zone.y + 1, wgt.options.Source, flags1)
	--	--lcd.drawNumber(wgt.zone.x + wgt.zone.w, wgt.zone.y + wgt.zone.h - 19, value, flags1)
	--	lcd.drawText  (wgt.zone.x + wgt.zone.w, wgt.zone.y + wgt.zone.h - 19, valStr, flags1)
	--end

end

function update(wgt, options)
	wgt.options = options
end

function refresh(wgt)
	drawGauge(wgt)
end

return { name="Gauge2", options=_options, create=create, update=update, refresh=refresh }
