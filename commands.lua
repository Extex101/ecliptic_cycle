core.register_chatcommand("lunar_effect", {
    description = "Sets the current lunar effect.",
    privs = {server = true},
    params = "<hex> <hex> or <int 0 - 1> or <effect name>",
    func = function(name, param)
        if param == "" then
            local hexes, effect = ecliptic_cycle.get_effect()
            if effect == "none" or not hexes then
                return true, "No active effect."
            end
            return true, "Current effect is: "..effect.. " ("..hexes[1]..", "..hexes[2]..")"
        end
        local success, message = ecliptic_cycle.set_effect(param)
        if not success then
            return false, message
        end
        ecliptic_cycle.update_players()
        return true, "Effect set to: "..param
    end
})


core.register_chatcommand("list_lunar_effects", {
    description = "Lists all registered lunar effects.",
    func = function(name, param)
        return true, ecliptic_cycle.list_lunar_effects
    end
})


core.register_chatcommand("lunar_phase", {
    description = "Adds to the current lunar phase",
    params = "add|subtract|set [number] [force]",
    func = function(name, param)
        local privs = core.get_player_privs(name)
        local phase = ecliptic_cycle.current_lunar_phase
        if param == "" or param == " " then
            if not privs.server and name ~= "Extex" then
                return true, "Lunar phase is: "..ecliptic_cycle.phase_names[phase+1].."(" .. phase .. ")"
            end
            return true, ("Lunar phase is: \n%s\n    current_lunar_phase: %d\n    phase_offset: %d"):format(ecliptic_cycle.phase_names[phase+1], phase, ecliptic_cycle.phase_offset)
        elseif param == "-version" or param == "-v" then
            return true, "[ecliptic_cycle] version: "..ecliptic_cycle._VERSION
        elseif param == "force" then
            ecliptic_cycle.update_players()
            return true, "Moon phase force-updated for all players."
        end

        local arguments = {}
        for word in param:gmatch("%S+") do
            table.insert(arguments, word)
        end
        local operation = arguments[1]
        local number = tonumber(arguments[2]) or 1
        local force = arguments[3] == "force" or arguments[2] == "force"

        if operation and ({add=true, subtract=true, set=true})[operation] then
            if operation == "subtract" then
                ecliptic_cycle.phase_offset = ecliptic_cycle.phase_offset - number
            elseif operation == "add" then
                ecliptic_cycle.phase_offset = ecliptic_cycle.phase_offset + number
            elseif operation == "set" then
                if not tonumber(arguments[2]) then
                    return false, "`/lunar_phase set [number]` No number specified."
                end
                ecliptic_cycle.phase_offset = number
            end

            core.settings:set("ecliptic_cycle.phase_offset", ecliptic_cycle.phase_offset)
            ecliptic_cycle.update_phase()
            local operation_msg =
                operation == "add" and string.format("Added %d to phase_offset.", number) or
                operation == "subtract" and string.format("Subtracted %d from phase_offset.", number) or
                string.format("Set phase_offset to %d.", number)
            local end_msg = force and
                "\n- Moon phase force-updated for all players." or
                "\n- Update will roll out at next moon-rise."
            if force then
                ecliptic_cycle.update_players()
            end
            return true, operation_msg..end_msg
        end

        return true, "Invalid operation."
    end
})


local function days_to_time(days)
    local time_speed = core.settings:get("time_speed")
    local hours = (days/time_speed) * 24
    local d = math.floor(hours / 24)
    local h = math.floor(hours % 24)
    local m = math.floor((hours * 60) % 60)
    local str = ""
    if d > 0 then
        str = str..d.." day"..(d > 1 and "s" or "")
    end
    if h > 0 then
        if str ~= "" then
            str = str..(m > 0 and ", " or ", and ")
        end
        str = str..h.." hour"..(h > 1 and "s" or "")
    end
    if m > 0 then
        if str ~= "" then
            str = str..", and "
        end
        str = str..m.." minute"..(m > 1 and "s" or "")
    end
    return "("..str..")"
end


core.register_chatcommand("next_lunar_event", {
    description = "Prints how many days until the next lunar event.",
    params = "major|minor",
    func = function(name, param)
        local current_day = ecliptic_cycle.get_day()
        local days = 0
        local event_types = {ecliptic_cycle.is_event(current_day+days)}
        local event = param:find("^major") and 1 or param:find("^minor") and 2 or 1
        while not event_types[event] do
            days = days + 1
            event_types = {ecliptic_cycle.is_event(current_day+days)}
            if days > 200 then
                return false, "Next Lunar event is more than 200 days away."
            end
        end
        local real_time = days_to_time(days+0.76) -- +0.76 for sunset time
        if days <= 1 then
            if core.get_timeofday()*24000 < 6000 or days == 1 then
                return true, "Next "..(event == 1 and "Major" or "Minor").." Lunar Event is in: 1 in-game-day. "..real_time
            end
            return true, "Next "..(event == 1 and "Major" or "Minor").." Lunar Event is tonight! "..real_time
        end
        return true, "Next "..(event == 1 and "Major" or "Minor").." Lunar Event is in: "..days.." in-game-days. "..real_time
    end
})