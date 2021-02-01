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

local function addHead(surface, user)
  addBox(
    surface, 0, {name='head'},
    -config.headHalfWidth, 0,
    config.headWidth, config.headHeight,
    config.colors.head,
    user .. ': ' .. users[user],
    config.colors.price
  )
end

local function addMain(surface, user)
  addBox(
    surface, 1, _,
    -config.background.hw - config.separator, config.headHeight,
    config.background.w + config.separator * 2, config.background.h,
    config.colors.background_2
  )
  addBox(
    surface, 1, _,
    config.item.x, config.item.y,
    config.item.w, config.infoHeight,
    config.colors.background_1,
    config.text.name,
    config.colors.inactive
  )
  addBox(
    surface, 1, _,
    config.amount.x, config.item.y,
    config.amount.w, config.infoHeight,
    config.colors.background_1,
    config.text.amount,
    config.colors.inactive
  )
  addBox(
    surface, 1, _,
    config.price.x, config.item.y,
    config.amount.w, config.infoHeight,
    config.colors.background_1,
    config.text.price,
    config.colors.inactive
  )
  addBox(
    surface, 1, {name = 'sell'},
    config.b_sell.x - config.separator, config.b_sell.y,
    config.b_sell.w + config.separator, config.headHeight,
    config.colors.background_1,
    config.text.sell,
    config.colors.inactive
  )
  addBox(
    surface, 1, {name = 'buy'},
    config.b_buy.x, config.b_sell.y,
    config.b_sell.w + config.separator, config.headHeight,
    config.colors.background_2,
    config.text.buy,
    config.colors.active
  )
  for i = 0, config.list_l - 1 do
    addBox(
      surface, 2, {name = 'list', i + 1},
      -config.background.hw, config.item.y + (i * config.iconSize) + config.infoHeight,
      config.background.w, config.iconSize - 1,
      config.colors.head      
    )
    addIcon(surface, 2, _, config.list_i.x, config.list_i.y + (i * config.iconSize))
    addText(
      surface, 2, _,
      config.item.x, config.list_y + (i * config.iconSize),
      _, config.colors.name, config.item.w
    )
    addText(
      surface, 2, _,
      config.amount.x, config.list_y + (i * config.iconSize),
      _, config.colors.amount, config.amount.w
    )
    addText(
      surface, 2, _,
      config.price.x, config.list_y + (i * config.iconSize),
      _, config.colors.price, config.amount.w
    )
  end
  toggle(surface, 1, false)
  toggle(surface, 2, false)
end

local function addDeal(surface, user)
  addBox(
    surface, 3, _,
    config.deal.x - config.separator, config.deal.y - config.separator,
    config.deal.w + config.separator * 2, config.deal.h + config.separator * 2,
    config.colors.background_2    
  )
  addBox(
    surface, 3, _,
    config.deal.x, config.deal.y,
    config.deal.w, config.deal.h,
    config.colors.background_1
  )
  addBox(
    surface, 3, {name = 'deal'},
    config.deal.x, config.deal.y,
    config.deal.w, 10,
    config.colors.head,
    config.text.name,
    config.colors.name
  )
  addIcon(
    surface, 3, {name = 'icon'},
    config.deal.icon.x, config.deal.icon.y,
    _, 0, 3
  )
  addText(
    surface, 3, {name = 'price'},
    config.deal.x + 12, config.deal.price,
    _, config.colors.price
  )
  addText(
    surface, 3, {name = 'amonut'},
    config.deal.x + 12, config.deal.amount,
    _, config.colors.amount
  )
  addText(
    surface, 3, {name = 'active'},
    config.deal.x + 12, config.deal.active,
    _, config.colors.active
  )
  addBox(
    surface, 3, {name = 'cancel'},
    config.b_deal.x, config.b_deal.y,
    config.b_deal.w, config.b_deal.h,
    config.colors.head,
    config.text.cancel,
    config.colors.cancel
  )
  addBox(
    surface, 3, {name = 'confirm'},
    config.deal.w / 6, config.b_deal.y,
    config.b_deal.w, config.b_deal.h,
    config.colors.head,
    config.text.buy,
    config.colors.active
  )
  toggle(surface, 3, false)
end

local function init(surface, user)
  surface.clear()
  addHead(surface, user)
  addMain(surface, user)
  addDeal(surface, user)
  ob.sync()
end
