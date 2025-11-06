-- storycam/core.lua
storycam = storycam or {}

-- linear interp
function storycam.lerp(a,b,t) return a + (b-a)*t end

-- shortest angle interp (radians)
function storycam.lerp_angle(a,b,t)
    local diff = ((b - a + math.pi) % (2*math.pi)) - math.pi
    return a + diff * t
end

-- cubic ease-in-out (smooth cinematic)
function storycam.ease(t)
    if t < 0 then return 0 end
    if t > 1 then return 1 end
    if t < 0.5 then
        return 4 * t * t * t
    else
        local f = (-2 * t + 2)
        return 1 - (f * f * f) / 2
    end
end

function storycam.filepath(name)
    return storycam.worldpath .. "/story_" .. name .. ".json"
end

-- safe player look getters (some server builds differ)
function storycam.safe_get_look_horizontal(player)
    if not player then return 0 end
    if player.get_look_horizontal then
        return player:get_look_horizontal()
    elseif player.get_look_yaw then
        return player:get_look_yaw()
    end
    return 0
end

function storycam.safe_get_look_vertical(player)
    if not player then return 0 end
    if player.get_look_vertical then
        return player:get_look_vertical()
    end
    return 0
end

function storycam.safe_set_look(player, yaw_rad, pitch_rad)
    if not player then return end
    if player.set_look_horizontal then
        pcall(function() player:set_look_horizontal(yaw_rad) end)
    elseif player.set_look_yaw then
        pcall(function() player:set_look_yaw(yaw_rad) end)
    end
    if player.set_look_vertical then
        pcall(function() player:set_look_vertical(pitch_rad) end)
    end
end

function storycam.lock_player(player, lock)
    if not player or not player:is_player() then return end
    if lock then
        -- freeze movement and hide hud/tools
        pcall(function() player:set_physics_override({speed=0, jump=0}) end)
        pcall(function() player:hud_set_flags({
            wielditem=false, crosshair=false, healthbar=false, hotbar=false
        }) end)
    else
        pcall(function() player:set_physics_override({speed=1, jump=1}) end)
        pcall(function() player:hud_set_flags({
            wielditem=true, crosshair=true, healthbar=true, hotbar=true
        }) end)
    end
end
