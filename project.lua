-- storycam/project.lua
-- Saving, loading, and managing projects (safe waypoint capture)

if not storycam then storycam = {} end
storycam.projects = storycam.projects or {}

local function safe_get_look_horizontal(player)
    if player.get_look_horizontal then
        return player:get_look_horizontal()
    elseif player.get_look_yaw then
        return player:get_look_yaw()
    end
    return 0
end

local function safe_get_look_vertical(player)
    if player.get_look_vertical then
        return player:get_look_vertical()
    end
    return 0
end

function storycam.save(name)
    local proj = storycam.projects[name]
    if not proj then return false, "no such project" end
    local file, err = io.open(storycam.filepath(name), "w")
    if not file then return false, err end
    file:write(minetest.write_json(proj))
    file:close()
    return true
end

function storycam.load(name)
    local file = io.open(storycam.filepath(name), "r")
    if not file then return false, "file not found" end
    local data = file:read("*a")
    file:close()
    local ok, json = pcall(minetest.parse_json, data)
    if not ok then return false, "invalid json" end
    storycam.projects[name] = json
    return true
end

-- Capture a waypoint from a player. Returns waypoint table or nil + err
function storycam.capture_waypoint(player, dur)
    if not player or not player:is_player() then
        return nil, "player not found"
    end

    local pos = player:get_pos()
    if not pos then
        return nil, "couldn't get player position"
    end

    local eye_h = 1.5
    if player.get_eye_height then
        local ok, eh = pcall(player.get_eye_height, player)
        if ok and type(eh) == "number" then eye_h = eh end
    end

    local yaw = safe_get_look_horizontal(player) or 0
    local pitch = safe_get_look_vertical(player) or 0

    return {
        pos = { x = pos.x, y = pos.y + eye_h, z = pos.z },
        yaw = tonumber(yaw) or 0,
        pitch = tonumber(pitch) or 0,
        dur = tonumber(dur) or 3
    }
end
