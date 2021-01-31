-- debug
local component = require('component')
local computer = require('computer')
local event = require('event')
--
local config = require('config')
local insert, tonumber, min, max = table.insert, tonumber, math.min, math.max

local ob = component.openperipheral_bridge
local containers = {[0] = {}, {}, {}, {}}

local function addBox(surface, container, clickable, x, y, w, h, box_color, text, text_color)
  x = x or 0
  y = y or 0
  w = w or 0
  h = h or 0
  local a = surface.addBox(x, y, w, h, box_color)
  a.setScreenAnchor('MIDDLE', 'TOP')
  if clickable then
    a.setClickable(true)
    a.setUserdata(clickable)
  else
    a.setClickable(false)
  end
  insert(containers[container], a.getId())
  if text then
    text_color = text_color or 0xffffff
    local b = surface.addText(x + w / 2 + 0.5, y + h / 2 - 4, text, text_color)
    b.setAlignment('MIDDLE', 'TOP')
    b.setClickable(false)
    insert(containers[container], b.getId())
  end
end

local function addIcon()
end

local function addText()
end
