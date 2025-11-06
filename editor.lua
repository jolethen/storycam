-- storycam/editor.lua
-- Command system for editing and controlling StoryCam (robust / non-crashy)

if not storycam then storycam = {} end
storycam.projects = storycam.projects or {}

minetest.register_chatcommand("story_create", {
    params = "<name>",
    description = "Create a new story project",
    func = function(name, param)
        if param == "" then return false, "Usage: /story_create <name>" end
        storycam.projects[param] = { points = {} }
        return true, "Created project " .. param
    end
})

minetest.register_chatcommand("story_addpoint", {
    params = "<name> <dur>",
    description = "Add your current camera as a waypoint",
    func = function(caller_name, param)
        local projname, dur = param:match("^(%S+)%s*(%S*)$")
        if not projname or projname == "" then
            return false, "Usage: /story_addpoint <project> <dur>"
        end

        local player = minetest.get_player_by_name(caller_name)
        if not player then
            return false, "Player not found (only a connected player can use this command)"
        end

        local proj = storycam.projects[projname]
        if not proj then return false, "Project not found: " .. projname end

        local wp, err = storycam.capture_waypoint(player, dur)
        if not wp then
            return false, "Failed to capture waypoint: " .. (err or "unknown")
        end

        table.insert(proj.points, wp)
        return true, "Added waypoint to " .. projname .. " (dur=" .. tostring(wp.dur) .. "s)"
    end
})

minetest.register_chatcommand("story_angle", {
    params = "<yaw> <pitch>",
    description = "Manually adjust your camera angle (editing only)",
    func = function(caller_name, param)
        local yaw_s, pitch_s = param:match("^(%S+)%s+(%S+)$")
        if not yaw_s or not pitch_s then
            return false, "Usage: /story_angle <yaw> <pitch>  (angles in degrees)"
        end
        local player = minetest.get_player_by_name(caller_name)
        if not player then return false, "Player not found" end

        local yaw = tonumber(yaw_s)
        local pitch = tonumber(pitch_s)
        if not yaw or not pitch then return false, "Invalid numbers" end

        -- set_look_* expect radians in many engines; we allow degrees input and convert
        if player.set_look_horizontal then
            player:set_look_horizontal(math.rad(yaw))
        elseif player.set_look_yaw then
            player:set_look_yaw(math.rad(yaw))
        end
        if player.set_look_vertical then
            player:set_look_vertical(math.rad(pitch))
        end

        return true, "Angle set to yaw=" .. yaw_s .. ", pitch=" .. pitch_s
    end
})

minetest.register_chatcommand("story_save", {
    params = "<name>",
    description = "Save current story project",
    func = function(_, param)
        if not param or param == "" then return false, "Usage: /story_save <name>" end
        local ok, err = storycam.save(param)
        return ok, ok and "Saved!" or (err or "error")
    end
})

minetest.register_chatcommand("story_load", {
    params = "<name>",
    description = "Load a story project",
    func = function(_, param)
        if not param or param == "" then return false, "Usage: /story_load <name>" end
        local ok, err = storycam.load(param)
        return ok, ok and "Loaded!" or (err or "error")
    end
})

minetest.register_chatcommand("story_list", {
    description = "List loaded projects",
    func = function()
        local list = {}
        for k in pairs(storycam.projects) do table.insert(list, k) end
        if #list == 0 then return true, "No projects loaded" end
        return true, "Projects: " .. table.concat(list, ", ")
    end
})

minetest.register_chatcommand("story_play", {
    params = "<name> [player]",
    description = "Play cinematic sequence",
    privs = { server = true },
    func = function(caller, param)
        local pname, target = param:match("^(%S+)%s*(%S*)$")
        if not pname or pname == "" then
            return false, "Usage: /story_play <project> [player]"
        end
        local proj = storycam.projects[pname]
        if not proj then return false, "Project not found: " .. pname end

        local player
        if target and target ~= "" then
            player = minetest.get_player_by_name(target)
            if not player then return false, "Target player not found: " .. target end
        else
            player = minetest.get_player_by_name(caller)
            if not player then return false, "Caller player not found" end
        end

        -- call the playback entry point. Use whichever API your camera module provides.
        if storycam.play_sequence then
            storycam.play_sequence(player, proj)
            return true, "Playing project " .. pname .. " for " .. player:get_player_name()
        elseif storycam.play then
            -- older function name fallback (some versions use storycam.play)
            local ok, err = storycam.play(pname, { player })
            if not ok then return false, err end
            return true, "Playing project " .. pname
        else
            return false, "Playback function not found (storycam.play_sequence or storycam.play)"
        end
    end
})
