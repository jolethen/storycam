-- storycam/camera.lua
storycam = storycam or {}

-- playback internals
storycam.active_plays = storycam.active_plays or {}

-- build playback path from project (ordered frames)
local function build_path_from_project(proj)
    if not proj or not proj.points then return {} end
    local ordered = storycam.get_ordered_points(proj.points)
    local path = {}
    for i, item in ipairs(ordered) do
        table.insert(path, item.point)
    end
    return path
end

-- start playback for a single player
function storycam.play_sequence_for_player(player, proj)
    if not player or not player:is_player() then return false, "player missing" end
    if not proj then return false, "project missing" end
    local path = build_path_from_project(proj)
    if #path == 0 then return false, "no frames in project" end
    -- create an entry
    local id = tostring(player:get_player_name()) .. "_" .. tostring(math.random(10000,99999))
    storycam.active_plays[id] = {
        player = player,
        path = path,
        idx = 1,   -- current point index (source point)
        timer = 0
    }
    storycam.lock_player(player, true)
    return true, id
end

-- entrypoint used by editor: player + proj table
function storycam.play_sequence(player, proj)
    return storycam.play_sequence_for_player(player, proj)
end

-- globalstep to advance active plays
minetest.register_globalstep(function(dtime)
    for id, play in pairs(storycam.active_plays) do
        local player = play.player
        local path = play.path
        if not player or not player:is_player() or not path then
            -- cleanup
            storycam.lock_player(player, false)
            storycam.active_plays[id] = nil
        else
            local cur_idx = play.idx
            local cur = path[cur_idx]
            if not cur then
                -- finished
                storycam.lock_player(player, false)
                storycam.active_plays[id] = nil
            else
                local next_idx = cur_idx + 1
                local nxt = path[next_idx]
                local dur = tonumber(cur.dur) or 3
                play.timer = play.timer + dtime
                local t = math.min(play.timer / dur, 1)
                local eased = storycam.ease(t)

                local pos, yaw, pitch
                if nxt then
                    pos = {
                        x = storycam.lerp(cur.pos.x, nxt.pos.x, eased),
                        y = storycam.lerp(cur.pos.y, nxt.pos.y, eased),
                        z = storycam.lerp(cur.pos.z, nxt.pos.z, eased)
                    }
                    yaw = storycam.lerp_angle(cur.yaw, nxt.yaw, eased)
                    pitch = storycam.lerp(cur.pitch, nxt.pitch, eased)
                else
                    pos = cur.pos
                    yaw = cur.yaw or 0
                    pitch = cur.pitch or 0
                end

                -- move player safely
                if player and player:is_player() then
                    pcall(function() player:set_pos(pos) end)
                    pcall(function() storycam.safe_set_look(player, yaw, pitch) end)
                end

                if t >= 1 then
                    -- advance to next frame
                    play.idx = next_idx
                    play.timer = 0
                    -- if no next, will be cleaned next loop
                end
            end
        end
    end
end)
