local Position = require('__stdlib__/stdlib/area/position')
local Area = require('__stdlib__/stdlib/area/area')
local table = require('__stdlib__/stdlib/utils/table')
require('util')

-- From https://github.com/mrvn/factorio-example-entity-with-tags
script.on_event(defines.events.on_player_setup_blueprint, function(event)
  local player = game.players[event.player_index]
  -- get new blueprint or fake blueprint when selecting a new area
  local bp = player.blueprint_to_setup
  if not bp or not bp.valid_for_read then
    bp = player.cursor_stack
  end
  if not bp or not bp.valid_for_read then
    return
  end
  -- get entities in blueprint
  local entities = bp.get_blueprint_entities()
  if not entities then
    return
  end
  -- get mapping of blueprint entities to source entities
  if event.mapping.valid then
    local map = event.mapping.get()
    for _, bp_entity in pairs(entities) do
      if bp_entity.name == Config.CHEST_NAME then
        -- set tag for our example tag-chest
        local id = bp_entity.entity_number
        local entity = map[id]
        if entity then
          bp.set_blueprint_entity_tag(id, "filter", Chest.getNameFromId(entity.link_id))
        else
          game.print("missing mapping for bp_entity " .. id .. ":" .. bp_entity.name)
        end
      end
    end
  else
    game.print("no entity mapping in event")
  end
end)

function onBuiltEntity(event)
  local entity = event.created_entity
  if entity and entity.valid then
    Chest.onBuiltEntity(event, entity)
  end
end

script.on_event(defines.events.on_built_entity, onBuiltEntity)
script.on_event(defines.events.on_robot_built_entity, onBuiltEntity)
script.on_event(defines.events.script_raised_built, onBuiltEntity)

script.on_event("zy-unichest-paste-alt", function(event)
  local player = game.players[event.player_index]
  Chest.setItemFilterFromSource(player.selected, player.entity_copy_source, true)
end)

script.on_event(defines.events.on_entity_settings_pasted, function(event)
  local player = game.players[event.player_index]
  Chest.setItemFilterFromSource(event.destination, event.source, false)
end)

function initGui(player)
  Chest.destroyGui(player)
  Chest.buildGui(player)
end

script.on_event(defines.events.on_gui_opened, function(event)
  local player = game.get_player(event.player_index)
  if not player or not event.entity then return end
  if event.entity.name == Config.CHEST_NAME then Chest.openGui(player, event.entity) end
end)

script.on_init(function(event)
  global.nameToId = {}
  for i, player in pairs(game.players) do
    initGui(player)
  end
end)

script.on_configuration_changed(function(event)
  for i, player in pairs(game.players) do
    initGui(player)
  end
  -- TODO
  -- for _, surface in pairs(game.surfaces) do
  --   table.each(surface.find_entities_filtered {name = Config.CHEST_NAME}, function(v)
  --     local inventory = v.get_output_inventory()
  --     local filter = inventory.get_filter(1)
  --     if filter and filter ~= "" then
  --       global.nameToId[filter] = v.link_id
  --       global.nextId = math.max((global.nextId or 0), v.link_id) + 1
  --       game.print("Found filter " .. filter .. " with id=" .. v.link_id)
  --     end
  --   end)
  -- end
end)

script.on_event(defines.events.on_player_created, function(event)
  initGui(game.get_player(event.player_index))
end)

script.on_event(defines.events.on_player_joined_game, function(event)
  initGui(game.get_player(event.player_index))
end)