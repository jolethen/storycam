-- storycam/project.lua
storycam = storycam or {}
storycam.projects = storycam.projects or {}

local function safe_parse_json(str)
    local ok, parsed = pcall(minetest.parse_json, str)
    if ok then return parsed end
    return nil, "invalid json"
end

function storycam.save(name)
    if not name or name == "" then return false, "no name" end
    local proj = storycam.projects[name]
    if not proj then return false, "no such project" end
    local fp = storycam.filepath(name)
    local fh, err = io.open(fp, "w")
    if not fh then return false, err end
    fh:write(minetest.write_json(proj))
    fh:close()
    return true
end

function storycam.load(name)
    if not name or name == "" then return false, "no name" end
    local fp = storycam.filepath(name)
    local fh = io.open(fp, "r")
    if not fh then return false, "file not found" end
    local data = fh:read("*a")
    fh:close()
    local proj, perr = safe_parse_json(data)
    if not proj then return false, perr end
    -- ensure structure: points is table (map frame->point)
    proj.points = proj.points or {}
    storycam.projects[name] = proj
    return true
end

-- helper: returns sorted numeric frame keys ascending
local function sorted_frame_keys(points)
    local keys = {}
    for k,_ in pairs(points) do
        if type(k) == "number" or tonumber(k) then
            table.insert(keys, tonumber(k))
        end
    end
    table.sort(keys)
    return keys
end

-- returns array of points in ascending frame order
function storycam.get_ordered_points(points_map)
    local keys = sorted_frame_keys(points_map or {})
    local out = {}
    for _, k in ipairs(keys) do
        local v = points_map[k]
        if v then table.insert(out, {frame=k, point=v}) end
    end
    return out
end

-- capture waypoint from player; returns point table or nil+err
function storycam.capture_waypoint(player, dur)
    if not player or not player:is_player() then return nil, "player not found" end
    local pos = player:get_pos()
    if not pos then return nil, "can't get position" end
    local eye_h = 1.5
    if player.get_eye_height then
        local ok, eh = pcall(player.get_eye_height, player)
        if ok and type(eh) == "number" then eye_h = eh end
    end
    local yaw = storycam.safe_get_look_horizontal(player) or 0
    local pitch = storycam.safe_get_look_vertical(player) or 0
    return {
        pos = { x = pos.x, y = pos.y + eye_h, z = pos.z },
        yaw = tonumber(yaw) or 0,
        pitch = tonumber(pitch) or 0,
        dur = tonumber(dur) or 3
    }
end

-- add a waypoint into project; frame optional
-- returns true or false+err
function storycam.add_point(project_name, player, dur, frame)
    if not project_name then return false, "no project name" end
    local proj = storycam.projects[project_name]
    if not proj then return false, "project not found" end
    local wp, err = storycam.capture_waypoint(player, dur)
    if not wp then return false, err end

    proj.points = proj.points or {}
    if frame and tonumber(frame) then
        proj.points[tonumber(frame)] = wp
    else
        -- find next free numeric key (max+1)
        local maxk = 0
        for k,_ in pairs(proj.points) do
            local kn = tonumber(k) or 0
            if kn > maxk then maxk = kn end
        end
        proj.points[maxk + 1] = wp
    end
    return true
end
