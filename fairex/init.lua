-- debug
local component = require('component')
local computer = require('computer')
local event = require('event')
--
local config = require('config')
local labels = require('labels')
local insert, tonumber, min, max = table.insert, tonumber, math.min, math.max

local ob = component.openperipheral_bridge
local containers = {[0] = {}, {}, {}, {}}
local users = {['Dummy'] = 123456}
local states = {}
local links = {
  "minecraft:stone:0",
  "minecraft:coal_block:0",
  "minecraft:iron_block:0",
  "minecraft:gold_block:0",
  "minecraft:redstone_block:0",
  "minecraft:lapis_block:0",
  "minecraft:diamond_block:0",
  "minecraft:emerald_block:0",
  "minecraft:sand:0",
  "minecraft:sand:1",
  "minecraft:gravel:0",
  "minecraft:gold_ore:0",
  "minecraft:iron_ore:0",
  "minecraft:coal_ore:0",
  "minecraft:log:0",
  "minecraft:log:1",
  "minecraft:log:2",
  "minecraft:log:3",
}

local items = {
  ["minecraft:stone:0"] = {1, 0, 0},
  ["minecraft:coal_block:0"] = {9, 0, 0},
  ["minecraft:iron_block:0"] = {18, 0, 0},
  ["minecraft:gold_block:0"] = {180, 0, 0},
  ["minecraft:redstone_block:0"] = {15, 0, 0},
  ["minecraft:lapis_block:0"] = {61, 0, 0},
  ["minecraft:diamond_block:0"] = {504, 0, 0},
  ["minecraft:emerald_block:0"] = {4068, 0, 0},
  ["minecraft:sand:0"] ={4068, 0, 0},
  ["minecraft:sand:1"] ={4068, 0, 0},
  ["minecraft:gravel:0"] ={4068, 0, 0},
  ["minecraft:gold_ore:0"] ={4068, 0, 0},
  ["minecraft:iron_ore:0"] ={4068, 0, 0},
  ["minecraft:coal_ore:0"] ={4068, 0, 0},
  ["minecraft:log:0"] ={4068, 0, 0},
  ["minecraft:log:1"] ={4068, 0, 0},
  ["minecraft:log:2"] ={4068, 0, 0},
  ["minecraft:log:3"] ={4068, 0, 0},
}

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

local function split(mod_item_meta)
  for i = #mod_item_meta, 1, -1 do
    if mod_item_meta:sub(i, i) == ':' then
      return mod_item_meta:sub(1, i - 1), tonumber(mod_item_meta:sub(i + 1, -1))
    end
  end
end

local function update_list(surface, name)
  local p = 0
  for i = 1, config.list_l do
    local a = surface.getById(containers[2][i+1+p])
    local pos = i + states[name].pos
    local item = links[pos]
    if not item then
      break
    end
    local n, m = split(item)
    a.setItemId(n)
    a.setMeta(m)
    if labels[item] then
      item = labels[item]
    end
    surface.getById(containers[2][i+2+p]).setText(item)
    surface.getById(containers[2][i+3+p]).setText(items[links[pos]][2])
    surface.getById(containers[2][i+4+p]).setText(items[links[pos]][3])
    p = p + 4
  end
end

local actions = {
  head = function(surface, state)
    if state == 0 then
      toggle(surface, 1, true)
      toggle(surface, 2, true)
      return 11
    elseif state == 1 or state == 11 then
      toggle(surface, 1, false)
      toggle(surface, 2, false)
      return 0
    end
    return state
  end,
  sell = function(surface, state, name)
    if state == 1 then
      update_list(surface, name)
      ob.sync()
    end
    return state
  end,
  buy = function(surface, state, name)
    if state == 11 then
      update_list(surface, name)
      ob.sync()
    end
    return state
  end,
  list = function(surface, state)
    if state == 1 or state == 11 then
      toggle(surface, 3, true)
      return 2
    end
    return state
  end,
  cancel = function(surface, state)
    if state == 2 then
      toggle(surface, 3, false)
      return 1
    end
    return state
  end
}

local function main()
  ob.clear()
  ob.sync()
  local surface, element, state
  while true do
    local e = {event.pull()}
    local name = e[3]
    if type(name) == 'string' and not states[name] then
      if not users[name] then
        users[name] = 0
      end
      states[name] = {pos = 0, state = 0}
      surface = ob.getSurfaceByName(name), name
      init(surface, name)
      update_list(surface, name)
    end
    if e[1] == 'glasses_component_mouse_up' then
      surface = ob.getSurfaceByName(name)
      element = surface.getById(e[5])
      local data = element.getUserdata()
      if element and data then
        
        state = states[name].state
        local pos = states[name].pos
        if actions[data.name] then
          state = actions[data.name](surface, state, name)
        end
        if states[name].state ~= state then
          states[name].state = state
          ob.sync()
        end
      end
    elseif e[1] == 'glasses_component_mouse_wheel' and
           (states[name].state == 1 or states[name].state == 11) then
      if e[9] > 0 then
        states[name].pos = max(states[name].pos - 1, 0)
      else
        states[name].pos = min(states[name].pos + 1, config.list_l - 2)
      end
      update_list(surface, name)
      ob.sync()
    end
  end
end

main()