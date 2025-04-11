

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

local effects = {
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

local function randomhex(min, max, fac)
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
    effects.colors[name] = {col1, col2}
    table.insert(effects.names, name)
end

function ecliptic_cycle.get_day(c)
    if c then
        return (ecliptic_cycle.phase_offset+core.get_day_count()) % 30
    end
    return ecliptic_cycle.phase_offset+core.get_day_count()
end

function ecliptic_cycle.set_effect(...)
    local args = {...}
    if #args == 1 then
        local param = args[1]
        if tonumber(param) then
            ecliptic_cycle.effect = {randomhex(70, 120, tonumber(param)), randomhex(150, 255, tonumber(param))}
            return true
        elseif type(param) == "string" then
            if param == "shuffle" then
                local effect = effects.names[math.random(1, #effects.names)]
                ecliptic_cycle.effect = effects.colors[effect]
                return true, effect
            end
            if effects[param] then
                ecliptic_cycle.effect = effects[param]
                return true
            end
            local colors = get_hexes(param)
            if colors and #colors >= 2 then
                ecliptic_cycle.effect = {colors[1], colors[2]}
                return true
            end
            return false, "Invalid Color: \""..tostring(param).."\""
        end
        -- error("Effect: "..tostring(param).." is invalid. Expected \"string\" or \"number\" got \""..type(param).."\"")
        return
    elseif #args >= 2 then
        local colors = {get_hexes(args[1]), get_hexes(args[2])}
        if colors[1] and colors[2] then
            ecliptic_cycle = colors
            return true
        end
        -- error("Colors invalid")
        return false, "Invalid Color: \""..tostring(args[1]).."\", \""..tostring(args[2]).."\""
    end
    return false, "No Parameters."
end

function ecliptic_cycle.is_event(day)
    local event = (math.cos(math.rad(
            day * 367.088)) +
        math.sin(math.rad(
            day/(day*5 % 60 + 60) * 7000
        ))
    ) * 2 / 2
    local event2 = math.cos(math.rad(day*math.max(math.min(math.tan(math.rad(day)), math.pi), -math.pi)))*2
    return event > ecliptic_cycle.threshold, event2 < -ecliptic_cycle.variance_threshold
end

function ecliptic_cycle.update_player_moon(player)
    if not player or not player:is_player() then return end
    local pos = "-"..(ecliptic_cycle.current_lunar_phase*32)..",0="
    local texture = "[combine:32x32:"..pos.."ecliptic_cycle_the_pale.png"
    if #ecliptic_cycle.effect == 2 and ecliptic_cycle.effect[1] and ecliptic_cycle.effect[2] then
        local texture1 = "ecliptic_cycle_the_pale_shadows.png\\^[multiply\\:"..ecliptic_cycle.effect[1]
        local texture2 = "ecliptic_cycle_the_pale_highlights.png\\^[multiply\\:"..ecliptic_cycle.effect[2]
        texture = "[combine:32x32:"..pos.."ecliptic_cycle_umbra.png:"..pos..texture1..":"..pos..texture2
    end
    player:set_moon({
        texture = texture,
        scale = 4
    })
end

function ecliptic_cycle.set_phase(day)
    if not day then day = ecliptic_cycle.get_day() end
    ecliptic_cycle.current_lunar_phase = day % 30
    local event, random_event = ecliptic_cycle.is_event(day)
    if event then
        ecliptic_cycle.set_effect("shuffle")
    elseif random_event then
        ecliptic_cycle.set_effect(ecliptic_cycle.variance)
    elseif not event and #ecliptic_cycle.effect > 0 then
        ecliptic_cycle.effect = {}
    end
end