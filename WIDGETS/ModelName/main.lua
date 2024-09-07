---- #########################################################################
---- #                                                                       #
---- # Telemetry Widget script for radiomaster TX16s                         #
---- # Copyright (C) OpenTX                                                  #
-----#                                                                       #
---- # License GPLv2: http://www.gnu.org/licenses/gpl-2.0.html               #
---- #                                                                       #
---- # This program is free software; you can redistribute it and/or modify  #
---- # it under the terms of the GNU General Public License version 2 as     #
---- # published by the Free Software Foundation.                            #
---- #                                                                       #
---- # This program is distributed in the hope that it will be useful        #
---- # but WITHOUT ANY WARRANTY; without even the implied warranty of        #
---- # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
---- # GNU General Public License for more details.                          #
---- #                                                                       #
---- #########################################################################

-- Horus Widget that show the name of the model on the bar on top
-- Offer Shmuely
-- Date: 2019
local app_name = "ModelName"
local app_ver = "0.3"

local options = {
  { "TextColor", COLOR, YELLOW }
}

local function create(zone, options)
  local theModelName = model.getInfo().name
  local wgt = { zone=zone, options=options, modelName=theModelName }
  print(wgt.modelName)
  return wgt
end

local function update(wgt, options)
  if (wgt == nil) then return end
  wgt.options = options
 end

local function background(wgt)
end

local function refresh(wgt)
  if (wgt == nil) then return end

  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x, wgt.zone.y, wgt.modelName, LEFT + DBLSIZE + CUSTOM_COLOR);
end

return { name=app_name, options=options, create=create, update=update, refresh=refresh, background=background }
