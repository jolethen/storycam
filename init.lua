-- StoryCam Mod (init.lua)
-- Main entry point

storycam = {
    active_plays = {},
    projects = {},
    worldpath = minetest.get_worldpath(),
}

-- Load modules
dofile(minetest.get_modpath("storycam").."/core.lua")
dofile(minetest.get_modpath("storycam").."/project.lua")
dofile(minetest.get_modpath("storycam").."/camera.lua")
dofile(minetest.get_modpath("storycam").."/editor.lua")

minetest.log("action", "[StoryCam] Loaded successfully.")
