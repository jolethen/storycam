-- storycam/init.lua
storycam = storycam or {}
storycam.active_plays = {}
storycam.projects = storycam.projects or {}
storycam.worldpath = minetest.get_worldpath()

local modpath = minetest.get_modpath("storycam")
dofile(modpath .. "/core.lua")
dofile(modpath .. "/project.lua")
dofile(modpath .. "/camera.lua")
dofile(modpath .. "/editor.lua")

minetest.log("action", "[storycam] loaded")
