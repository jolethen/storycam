-- storycam/project.lua
-- Saving, loading, and managing projects

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

function storycam.capture_waypoint(player, dur)
    local pos = player:get_pos()
    local yaw = player:get_look_horizontal()
    local pitch = player:get_look_vertical()
    return {
        pos = {x = pos.x, y = pos.y + player:get_eye_height(), z = pos.z},
        yaw = yaw,
        pitch = pitch,
        dur = tonumber(dur) or 2
    }
end
