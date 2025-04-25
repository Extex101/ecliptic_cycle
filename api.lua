ecliptic_cycle.phase_names = {
    "Northern Full Moon",
    "Northern Waning Gibbous",
    "Northern Waning Gibbous",
    "Northern Waning Gibbous",
    "Northern Waning Quarter",
    "Northern Waning Quarter",
    "Northern Waning Crescent",
    "Northern Waning Crescent",
    "Sourthern New Moon",
    "Southern Waxing Crescent",
    "Southern Waxing Crescent",
    "Southern Waxing Quarter",
    "Southern Waxing Quarter",
    "Southern Waxing Gibbous",
    "Southern Waxing Gibbous",
    "Southern Waxing Gibbous",
    "Southern Full Moon",
    "Southern Waning Gibbous", 
    "Southern Waning Gibbous",
    "Southern Waning Quarter",
    "Southern Waning Quarter",
    "Southern Waning Crescent",
    "Southern Waning Crescent",
    "Northern New Moon",
    "Northern Waxing Crescent",
    "Northern Waxing Quarter",
    "Northern Waxing Quarter",
    "Northern Waxing Gibbous",
    "Northern Waxing Gibbous",
    "Northern Waxing Gibbous",
}

ecliptic_cycle.effects = {
    colors = {},
    names = {}
}

local function get_hexes(string)
    local hexes = {}
    for hex in string:gmatch("%x%x%x%x%x%x") do
        table.insert(hexes, "#"..hex)
    end
    if #hexes == 0 then
        return false
    end
    return hexes
end

---@param min number 0-255
---@param max number 0-255
---@param fac number|string 0-1
---@return string Hex
function ecliptic_cycle.random_color(min, max, fac)
    if type(fac) == "string" then
        fac = tonumber(fac) or 0
    end
    local r = math.random(min, max)
    local g = math.random(min, max)
    local b = math.random(min, max)

    local avg = (r + g + b) / 3

    r = math.floor((r - avg) * fac + avg)
    g = math.floor((g - avg) * fac + avg)
    b = math.floor((b - avg) * fac + avg)
    
    local hex = "#"..string.format("%02x%02x%02x", r, g, b)
    return hex
end

function ecliptic_cycle.register_effect(name, col1, col2)
    ecliptic_cycle.effects.colors[name] = {col1, col2}
    table.insert(ecliptic_cycle.effects.names, name)
end

function ecliptic_cycle.update_players()
    for _, player in pairs(core.get_connected_players()) do
        ecliptic_cycle.update_player_moon(player)
    end
end

---@return number day Day + phase offset
function ecliptic_cycle.get_day()
    return ecliptic_cycle.phase_offset+core.get_day_count()
end

---@param ... string|number
---@return boolean
---@return string
function ecliptic_cycle.set_effect(...)
    local args = {...}
    if #args == 1 then
        local param = args[1]
        if type(param) == "number" or tonumber(param) then
            ecliptic_cycle.effect = {ecliptic_cycle.random_color(70, 120, param), ecliptic_cycle.random_color(150, 255, param), "random"}
            return true, "Random Color set"
        elseif type(param) == "string" then
            if param == "shuffle" then
                local effect = ecliptic_cycle.effects.names[math.random(1, #ecliptic_cycle.effects.names)]
                ecliptic_cycle.effect = ecliptic_cycle.effects.colors[effect]
                ecliptic_cycle.effect[3] = effect
                return true, "Shuffled to: "..effect
            end
            if ecliptic_cycle.effects.colors[param] then
                ecliptic_cycle.effect = ecliptic_cycle.effects.colors[param]
                ecliptic_cycle.effect[3] = param
                return true, "Set to: "..param
            end
            local colors = get_hexes(param)
            if colors and #colors >= 2 then
                ecliptic_cycle.effect = {colors[1], colors[2]}
                return true, "Set to: \""..tostring(colors[1]).."\", \""..tostring(colors[2]).."\""
            end
            return false, "Invalid Color: \""..tostring(param).."\""
        end
        return false, "Invalid Color: \""..tostring(param).."\""
    elseif #args >= 2 then
        local colors = {get_hexes(args[1]), get_hexes(args[2]), "custom"}
        if colors[1] and colors[2] then
            ecliptic_cycle.effect = colors
            return true, "Set to: \""..tostring(args[1]).."\", \""..tostring(args[2]).."\""
        end
        return false, "Invalid Color: \""..tostring(args[1]).."\", \""..tostring(args[2]).."\" 2 Args"
    end
    return false, "No Parameters."
end

---@param day number
---@return boolean Event1 This day will shuffle a custom event from the effects created with register_effect
---@return boolean Event2 This day will have a subtle random effect
function ecliptic_cycle.is_event(day)
    local event = (math.cos(math.rad(
            day * 367.088)) +
        math.sin(math.rad(
            day/(day*5 % 60 + 60) * 7000
        ))
    )
    local event2 = math.cos(math.rad(day*math.max(math.min(math.tan(math.rad(day)), math.pi), -math.pi)))*2
    return event > ecliptic_cycle.threshold, event2 < -ecliptic_cycle.variance_threshold
end

function ecliptic_cycle.update_player_moon(player)
    if not player or not player:is_player() then return end
    local pos = "-"..(ecliptic_cycle.current_lunar_phase*32)..",0="
    local texture = "[combine:32x32:"..pos.."ecliptic_cycle_the_pale.png"
    if #ecliptic_cycle.effect >= 2 and ecliptic_cycle.effect[1] and ecliptic_cycle.effect[2] then
        local texture1 = "ecliptic_cycle_the_pale_shadows.png\\^[multiply\\:"..ecliptic_cycle.effect[1]
        local texture2 = "ecliptic_cycle_the_pale_highlights.png\\^[multiply\\:"..ecliptic_cycle.effect[2]
        texture = "[combine:32x32:"..pos.."ecliptic_cycle_umbra.png:"..pos..texture1..":"..pos..texture2
    end
    player:set_moon({
        texture = texture,
        scale = 4
    })
end

---@param skip boolean|nil If true then it will not update the effect for the day
function ecliptic_cycle.update_phase(skip)
    local day = ecliptic_cycle.get_day()
    ecliptic_cycle.current_lunar_phase = day % 30
    if skip then return end
    local event, random_event = ecliptic_cycle.is_event(day)
    if event then
        ecliptic_cycle.set_effect("shuffle")
    elseif random_event then
        ecliptic_cycle.set_effect(ecliptic_cycle.variance)
    elseif not event and #ecliptic_cycle.effect > 0 then
        ecliptic_cycle.effect = {}
    end
end

---@param day number|nil
function ecliptic_cycle.get_phase(day)
    if not day then
        return ecliptic_cycle.get_day() % 30
    else
        return (day + ecliptic_cycle.phase_offset) % 30
    end
end

---@return table Effect {color1, color2}
---@return string Name The Name of the effect, "random", "none", or "custom"
function ecliptic_cycle.get_effect()
    return ecliptic_cycle.effect, ecliptic_cycle.effect[3] or "none"
end