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

local function addIcon(surface, container, type, x, y, name, meta, size)
  x = x or 0
  y = y or 0
  name = name or 'minecraft:stone'
  meta = meta or 0
  size = size or 1
  local a = surface.addIcon(x, y - size * 8, name, meta)
  a.setScale(size)
  a.setAlignment('MIDDLE', 'TOP')
  insert(containers[container], a.getId())
  if type then
    a.setUserdata(type)
  end
end

local function addText(surface, container, type, x, y, text, text_color, center)
  x = x or 0
  y = y or 0
  text = text or ''
  text_color = text_color or 0
  local a
  if center then
    a = surface.addText(x + center / 2 + 0.5, y - 4, text, text_color)
    a.setAlignment('MIDDLE', 'TOP')
  else
    a = surface.addText(x, y - 4, text, text_color)
    a.setScreenAnchor('MIDDLE', 'TOP')
  end
  if type then
    a.setUserdata(type)
  end
  insert(containers[container], a.getId())
end

local function toggle(surface, id, state)
  for i = 1, #containers[id] do
    local element = surface.getById(containers[id][i])
    element.setVisible(state)
    if element.getUserdata() then
      element.setClickable(state)
    end
  end
end
