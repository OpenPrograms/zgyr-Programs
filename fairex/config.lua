local config = {
  text = {
    name = 'Item name',
    amount = 'Amount',
    price = 'Price',
    sell = 'sell',
    buy = 'buy',
    cancel = 'cancel',
  },
  colors = {
    price = 0x00ffff,
    amount = 0xffff00,
    name = 0x8080ff,
    inactive = 0x008080,
    active = 0x00ff00,
    cancel = 0xff0000,
    head = 0x202020,
    background_1 = 0x101010,
    background_2 = 0
  },
  headWidth = 380,
  headHeight = 16,
  list_l = 10,
  background = {w = 356},
  separator = 5,
  infoHeight = 10,
  iconSize = 16,
  deal = {w = 170, h = 80}
}
config.headHalfWidth = config.headWidth / 2
config.background.hw = config.background.w / 2
config.background.h = config.infoHeight + config.iconSize * config.list_l + config.separator * 2
config.item = {
  x = -config.headHalfWidth + config.iconSize,
  y = config.headHeight + config.infoHeight,
  w = config.background.hw - config.separator
}
config.amount = {
  x = config.item.x + config.item.w + config.separator,
  w = config.item.w / 2 - config.separator * 2
}
config.price = {
  x = config.amount.x + config.amount.w + config.separator
}
config.b_sell = {
  x = -config.background.hw,
  y = config.headHeight + config.background.h,
  w = config.background.hw
}
config.b_buy = {
  x = config.b_sell.x + config.b_sell.w
}
config.list_y = config.item.y + config.headHeight + 1
config.list_i = {
  x = -config.background.hw + config.iconSize / 2,
  y = config.item.y + config.infoHeight + config.iconSize / 2 - 0.5
}
config.deal.x = -config.deal.w / 2
config.deal.y = (config.background.h - config.deal.h / 2) / 2
config.b_deal = {
  x = config.deal.x,
  y = config.deal.y + config.deal.h - 10,
  w = config.deal.w / 3,
  h = 10
}
config.deal.icon = {
  x = config.deal.x + config.deal.w - 32,
  y = config.deal.y + config.deal.h / 2
}
config.deal.price = config.deal.y + config.deal.h / 3 - 4
config.deal.amount = config.deal.icon.y
config.deal.active = config.deal.y + config.deal.h / 1.5 + 4

return config