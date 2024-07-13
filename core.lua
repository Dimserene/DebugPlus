local global = {}

local enhancements = nil
local seals = nil
local saveStateKeys = {"1", "2", "3"}
local consoleOpen = false
local showNewLogs = true
local firstConsoleRender
local old_print = print
local logs = nil

local function handleLog(colour, ...) 
    old_print(...)
    local _str = ""
    for i, v in ipairs({...}) do
        _str = _str .. tostring(v) .. " "
    end
    local meta = {
        str = _str,
        time = love.timer.getTime(),
        colour = colour
    }
    table.insert(logs, meta)
    if #logs > 100 then
        table.remove(logs, 1)
    end

end

local function log(...) 
    handleLog({.65, .36, 1}, "[DebugPlus]", ...) 
end

local function getSeals()
    if seals then
        return seals
    end
    seals = {"None"}
    for i, v in pairs(G.P_SEALS) do
        seals[v.order + 1] = i
    end

    return seals
end

local function getEnhancements()
    if enhancements then
        return enhancements
    end
    enhancements = {"c_base"}
    for k, v in pairs(G.P_CENTER_POOLS["Enhanced"]) do
        enhancements[v.order] = v.key
    end
    return enhancements
end


function global.handleKeys(controller, key, dt)
    if controller.hovering.target and controller.hovering.target:is(Card) then
        local _card = controller.hovering.target
        if key == 'w' then
            if _card.playing_card then
                for i, v in ipairs(getEnhancements()) do
                    if _card.config.center == G.P_CENTERS[v] then
                        local _next = i + 1
                        if _next > #enhancements then
                            _card:set_ability(G.P_CENTERS[enhancements[1]], nil, true)
                            _card:set_sprites(nil, "cards_" .. (G.SETTINGS.colourblind_option and 2 or 1))
                        else
                            _card:set_ability(G.P_CENTERS[enhancements[_next]], nil, true)
                        end
                        break
                    end
                end
            end
        end
        if key == "e" then
            if _card.playing_card then
                for i, v in ipairs(getSeals()) do
                    if (_card:get_seal(true) or "None") == v then
                        local _next = i + 1
                        if _next > #seals then
                            _next = 1
                        end
                        if _next == 1 then
                            _card:set_seal(nil, true)
                        else
                            _card:set_seal(seals[_next], true)
                        end
                        break
                    end
                end
            end
        end
        if key == "a" then
            if _card.ability.set == 'Joker' then
                _card.ability.eternal = not _card.ability.eternal
            end
        end
        if key == "s" then
            if _card.ability.set == 'Joker' then
                _card.ability.perishable = not _card.ability.perishable
                _card.ability.perish_tally = G.GAME.perishable_rounds
            end
        end
        if key == "d" then
            if _card.ability.set == 'Joker' then
                _card.ability.rental = not _card.ability.rental
                _card:set_cost()
            end
        end
        if key == "f" then
            if _card.ability.set == 'Joker' or _card.playing_card or _card.area then
                _card.ability.couponed = not _card.ability.couponed
                _card:set_cost()
            end
        end
        if key == "c" then
            local _area
            if _card.ability.set == 'Joker' then
                _area = G.jokers
            elseif _card.playing_card then
                _area = G.hand
            elseif _card.ability.consumeable then
                _area = G.consumeables
            end
            if _area == nil then
                return log("Error: Trying to dup card without an area")
            end
            local new_card = copy_card(_card, nil, nil, _card.playing_card)
            new_card:add_to_deck()
            if _card.playing_card then
                table.insert(G.playing_cards, new_card)
            end
            _area:emplace(new_card)

        end
        if key == "r" then
            if _card.ability.name == "Glass Card" then
                _card.shattered = true
            end
            _card:remove()
            if _card.playing_card then
                for j = 1, #G.jokers.cards do
                    eval_card(G.jokers.cards[j], {
                        cardarea = G.jokers,
                        remove_playing_cards = true,
                        removed = {_card}
                    })
                end
            end
        end
		-- this might break things
        -- or it might WORK ON MY FIRST F#CKING TRY LETS GOOOOOOOOOOOO
		-- randomaster13 here, this is taken from the strength tarot card
        if key == 'up' then
            if _card.playing_card then
                local suit_prefix = string.sub(_card.base.suit, 1, 1)..'_'
                local rank_suffix = _card.base.id == 14 and 2 or math.min(_card.base.id+1, 14) -- the rank of the card is increased here.
                if rank_suffix < 10 then rank_suffix = tostring(rank_suffix)
                elseif rank_suffix == 10 then rank_suffix = 'T'
                elseif rank_suffix == 11 then rank_suffix = 'J'
                elseif rank_suffix == 12 then rank_suffix = 'Q'
                elseif rank_suffix == 13 then rank_suffix = 'K'
                elseif rank_suffix == 14 then rank_suffix = 'A'
                end
                _card:set_base(G.P_CARDS[suit_prefix..rank_suffix])
            end
        end
        if key == 'down' then
            if _card.playing_card then
                local suit_prefix = string.sub(_card.base.suit, 1, 1)..'_'
                if _card.base.id == 2 then _card.base.id = 15
                end
                local rank_suffix = _card.base.id == 2 and 14 or math.min(_card.base.id-1, 14) -- the rank of the card is decreased here.
                if rank_suffix < 10 then rank_suffix = tostring(rank_suffix)
                elseif rank_suffix == 10 then rank_suffix = 'T'
                elseif rank_suffix == 11 then rank_suffix = 'J'
                elseif rank_suffix == 12 then rank_suffix = 'Q'
                elseif rank_suffix == 13 then rank_suffix = 'K'
                elseif rank_suffix == 14 then rank_suffix = 'A'
                end
                _card:set_base(G.P_CARDS[suit_prefix..rank_suffix]) -- like in the strength tarot card this just applies the changes.
            end
        end
        if key == 'right' then
            if _card.playing_card then
                local suit_prefix = string.sub(_card.base.suit, 1, 1)..'_'
                local rank_suffix = _card.base.id
                if rank_suffix < 10 then rank_suffix = tostring(rank_suffix) -- I think this is nessecary because the _card:set_base
                elseif rank_suffix == 10 then rank_suffix = 'T'				 -- function needs the rank suffix for the card.
                elseif rank_suffix == 11 then rank_suffix = 'J'
                elseif rank_suffix == 12 then rank_suffix = 'Q'
                elseif rank_suffix == 13 then rank_suffix = 'K'
                elseif rank_suffix == 14 then rank_suffix = 'A'
                end
                if suit_prefix == 'D_' then suit_prefix = 'C_' -- this part is probably inefficient and messy becasue I wrote it-
                elseif suit_prefix == 'C_' then suit_prefix = 'H_' -- and didn't wanna make a table for good reasons. (I'm lazy)
                elseif suit_prefix == 'H_' then suit_prefix = 'S_' -- the if / elseif statements take the suits and
                elseif suit_prefix == 'S_' then suit_prefix = 'D_' --  just change it to the next one in the arbitrary sequence I came up with
                end
                _card:set_base(G.P_CARDS[suit_prefix..rank_suffix]) -- like in the strength tarot card this just applies the changes.
            end
        end
        if key == 'left' then
            if _card.playing_card then
                local suit_prefix = string.sub(_card.base.suit, 1, 1)..'_'
                local rank_suffix = _card.base.id
                if rank_suffix < 10 then rank_suffix = tostring(rank_suffix)
                elseif rank_suffix == 10 then rank_suffix = 'T'
                elseif rank_suffix == 11 then rank_suffix = 'J'
                elseif rank_suffix == 12 then rank_suffix = 'Q'
                elseif rank_suffix == 13 then rank_suffix = 'K'
                elseif rank_suffix == 14 then rank_suffix = 'A'
                end
                if suit_prefix == 'D_' then suit_prefix = 'S_'
                elseif suit_prefix == 'S_' then suit_prefix = 'H_'
                elseif suit_prefix == 'H_' then suit_prefix = 'C_'
                elseif suit_prefix == 'C_' then suit_prefix = 'D_'
                end
                _card:set_base(G.P_CARDS[suit_prefix..rank_suffix])
            end
        end
    end

    if key == '/' then
        if love.keyboard.isDown('lshift') then
            showNewLogs = not showNewLogs
        else
            consoleOpen = not consoleOpen
        end
    end
    local _element = controller.hovering.target
    if _element and _element.config and _element.config.tag then
        local _tag = _element.config.tag
        if key == "2" then
            G.P_TAGS[_tag.key].unlocked = true
            G.P_TAGS[_tag.key].discovered = true
            G.P_TAGS[_tag.key].alerted = true
            _tag.hide_ability = false
            set_discover_tallies()
            G:save_progress()
            _element:set_sprite_pos(_tag.pos)
        end
        if key == "3" then
            if G.STAGE == G.STAGES.RUN then
                add_tag(Tag(_tag.key, false, 'Big'))
            end
        end
    end

    for i, v in ipairs(saveStateKeys) do
        if key == v and love.keyboard.isDown("z") then
            if G.STAGE == G.STAGES.RUN then
                if not (
                    G.STATE == G.STATES.TAROT_PACK
                    or G.STATE == G.STATES.PLANET_PACK
                    or G.STATE == G.STATES.SPECTRAL_PACK
                    or G.STATE == G.STATES.STANDARD_PACK
                    or G.STATE == G.STATES.BUFFOON_PACK
                    or G.STATE == G.STATES.SMODS_BOOSTER_OPENED
                ) then
                    save_run()
                end
                compress_and_save(G.SETTINGS.profile .. '/' .. 'debugsave' .. v .. '.jkr', G.ARGS.save_run)
                log("Saved to slot", v)
            end
        end
        if key == v and love.keyboard.isDown("x") then
            G:delete_run()
            G.SAVED_GAME = get_compressed(G.SETTINGS.profile .. '/' .. 'debugsave' .. v .. '.jkr')
            if G.SAVED_GAME ~= nil then
                G.SAVED_GAME = STR_UNPACK(G.SAVED_GAME)
            end
            G:start_run({
                savetext = G.SAVED_GAME
            })
            log("Loaded slot", v)
        end
    end
end

function global.registerButtons()
    G.FUNCS.DT_win_blind = function()
        if G.STATE ~= G.STATES.SELECTING_HAND then
            return
        end
        G.GAME.chips = G.GAME.blind.chips
        G.STATE = G.STATES.HAND_PLAYED
        G.STATE_COMPLETE = true
        end_round()
    end
    G.FUNCS.DT_double_tag = function()
        if G.STAGE == G.STAGES.RUN then
            add_tag(Tag('tag_double', false, 'Big'))
        end
    end
end

function global.handleSpawn(controller, _card)
    if _card.ability.set == 'Voucher' and G.shop_vouchers then
        local center = _card.config.center
        G.shop_vouchers.config.card_limit = G.shop_vouchers.config.card_limit + 1
        local card = Card(G.shop_vouchers.T.x + G.shop_vouchers.T.w / 2, G.shop_vouchers.T.y, G.CARD_W, G.CARD_H,
            G.P_CARDS.empty, center, {
                bypass_discovery_center = true,
                bypass_discovery_ui = true
            })
        create_shop_card_ui(card, 'Voucher', G.shop_vouchers)
        G.shop_vouchers:emplace(card)

    end
    if _card.ability.set == 'Booster' and G.shop_booster then
        local center = _card.config.center
        G.shop_booster.config.card_limit = G.shop_booster.config.card_limit + 1
        local card = Card(G.shop_booster.T.x + G.shop_booster.T.w / 2, G.shop_booster.T.y, G.CARD_W * 1.27,
            G.CARD_H * 1.27, G.P_CARDS.empty, center, {
                bypass_discovery_center = true,
                bypass_discovery_ui = true
            })

        create_shop_card_ui(card, 'Booster', G.shop_booster)
        card.ability.booster_pos = G.shop_booster.config.card_limit
        G.shop_booster:emplace(card)

    end

end

local showTime = 5
local fadeTime = 1

local function calcHeight(text, width)
    local font = love.graphics.getFont()
    local rw, lines = font:getWrap(text, width)
    local lineHeight = font:getHeight()
    
    return #lines * lineHeight, rw
end

global.registerLogHandler = function()
    if logs then
        return
    end
    logs = {}
    print = function(...)
        handleLog({0, 1, 1}, ...)
    end
end

global.doConsoleRender = function()
    if not consoleOpen and not showNewLogs then
        return
    end
    local width, height = love.graphics.getDimensions()
    local padding = 10
    local lineWidth = width - padding * 2
    local bottom = height - padding * 2
    local now = love.timer.getTime()
    if firstConsoleRender == nil then
        firstConsoleRender = now
        log("Press [/] to toggle console and press [shift] + [/] to toggle new log previews")
    end
    love.graphics.setColor(0, 0, 0, .5)
    if consoleOpen then
        love.graphics.rectangle("fill", padding, padding, lineWidth, height - padding * 2)
    end
    for i = #logs, 1, -1 do
        local v = logs[i]
        if not consoleOpen and v.time < firstConsoleRender then
            break
        end
        local age = now - v.time
        if not consoleOpen and age > showTime + fadeTime then
            break
        end
        local lineHeight, realWidth = calcHeight(v.str, lineWidth)
        bottom = bottom - lineHeight
        if bottom < padding then
            break
        end

        local opacityPercent = 1
        if not consoleOpen and age > showTime then 
            opacityPercent = (fadeTime - (age - showTime)) / fadeTime
        end
        
        if not consoleOpen then
            love.graphics.setColor(0, 0, 0, .5 * opacityPercent)
            love.graphics.rectangle("fill", padding, bottom, lineWidth, lineHeight)
        end
        love.graphics.setColor(v.colour[1], v.colour[2], v.colour[3], opacityPercent)

        love.graphics.printf(v.str, padding * 2, bottom, lineWidth - padding * 2)
    end
end

return global
