--[[
-- Author: Hai Tran
-- Date: June 12, 2016
-- File: util.lua
-- Any necessary utilities that are used in this project.
--]]

-- For testing
--[
require "LuaXML"

NUM_IMG = 89
--]]

-----------------------------------------------------
-- Check file size
--
--[[
function size(file)
	-- Get current position.
	local current = file:seek()
	-- Get file size
	local size = file:seek("end")
	-- Restore position
	file:seek("set", current)

	return size  
end
--]]

-----------------------------------------------------
-- Load the list of vertices from XML files
--
function loadXML()
	for i = 1, 89 do
		local xmlpath = "groundtruth/diaretdb1_image0"

		if i < 10 then
			xmlpath = xmlpath .. "0"
		end

		--[[
		for j = 1, 4 do
			-- XML path.
			xmlpath = xmlpath .. index .. "_0" .. j .. ".xml"
			-- Load the XML file.
			local xmlfile = xml.load(xmlpath)
			-- First, find <markinglist> tag.
			for _, node in pairs(xmlfile:find("markinglist")) do
				if node.TAG ~= nil then
					-- Second, find <marking> tag.
					if node[node.TAG] == "marking" then
						-- Third, find <centroid> tag.
						local centroid = node:find("centroid")
						if centroid ~= nil then
							for idx = 1, #centroid do
								-- Fourth, find <coords2d> tag. This is the value
								-- that we want to grab.
								local coords2d = centroid[idx]:find("coords2d")
								-- Split into horizontal and vertical coordinators.
								local coordX, coordY = coords2d[1]:match("([^,]+),([^,]+)")
								
							end
						end
						local radii = node:find("radius direction=\"x\"")
						if radii ~= nil then
							print(radii[1])
						end
					end
				end
			end
		end
		--]]
	end
end


loadXML()