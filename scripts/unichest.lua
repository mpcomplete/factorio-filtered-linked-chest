local Position = require('__stdlib__/stdlib/area/position')
local Area = require('__stdlib__/stdlib/area/area')
local table = require('__stdlib__/stdlib/utils/table')
local Util = require('util')

Chest = Chest or {}

function Chest.onBuiltEntity(event, entity)
  if entity.name ~= Config.CHEST_NAME then return end
  local tagFilter = event.tags and event.tags["filter"]   -- Extract filter from a blueprint tag

  global.updateFilterQueue = global.updateFilterQueue or {}
  if tagFilter then
    table.insert(global.updateFilterQueue, {entity, tagFilter})
  else
    table.insert(global.updateFilterQueue, {entity, Chest.getNameFromId(entity.link_id) or global.lastItemFilter})
  end
end

function tick_event_handler_gui(player, guiEntity, guiFilter)
  -- Reset any changes via the GUIs we can't control (e.g. Link bitmask and manual filtering).
  if not guiEntity.valid then return end
  player.gui.relative.unichestFrame.itemFilter.elem_value = guiFilter
  Chest.setItemFilter(guiEntity, guiFilter)
end

function tick_event_handler_update_filter(event)
  global.updateFilterQueue = global.updateFilterQueue or {}
  for i, val in pairs(global.updateFilterQueue) do
    Chest.setItemFilter(val[1], val[2])
  end

  global.updateFilterQueue = {}
end

function Chest.openGui(player, entity)
  local guiEntity = entity
  local guiFilter = Chest.getNameFromId(guiEntity.link_id)
  player.gui.relative.unichestFrame.itemFilter.elem_value = guiFilter
  Chest.setItemFilter(guiEntity, guiFilter)

  script.on_event(defines.events.on_tick, function(event)
    tick_event_handler_gui(player, guiEntity, guiFilter)
    tick_event_handler_update_filter(event)
  end)

  script.on_event(defines.events.on_gui_elem_changed, function(event)
    if not guiEntity.valid then return end
    local element = event.element
    if element ~= player.gui.relative.unichestFrame.itemFilter then return end
    if element.elem_value and element.elem_value ~= "" then
      -- Don't let them set an empty filter.
      guiFilter = element.elem_value
    end
  end)

  script.on_event(defines.events.on_gui_closed, function(event)
    script.on_event(defines.events.on_tick, function(event)
      tick_event_handler_update_filter(event)
    end)
    script.on_event(defines.events.on_gui_elem_changed, nil)
  end)
end

function Chest.buildGui(player)
  player.gui.relative.add {
    type = "frame",
    name = "unichestFrame",
    direction = "vertical",
    caption = { "zy-unichest.heading" },
    anchor = {
      gui = defines.relative_gui_type.linked_container_gui,
      position = defines.relative_gui_position.right
    },
    visible = true
  }
  player.gui.relative.unichestFrame.add {
    type = "choose-elem-button",
    name = "itemFilter",
    tooltip = { "zy-unichest.chooseElemTooltip" },
    style = "slot_button",
    elem_type = "item"
  }
end

function Chest.destroyGui(player)
  if player.gui.relative.unichestFrame ~= nil then player.gui.relative.unichestFrame.destroy() end
end