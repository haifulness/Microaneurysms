--[[
-- Author: Hai Tran
-- Date: June 11, 2016
-- File: 1-data.lua
-- Load raw data from the images and XML files.
--]]

print("==> Loading data...")


-------------------------------------------------------------------------------
-- A global table to store all regions by their centroid & radius.
-- Torch's Tensor is not used here because it is limited by 5 dimensions.
-- Format of an element of this table:
--     {image number, xml number, x coordinator, y coordinator, radius, agreement counter}
-- Example:
--     {12, 2, 175, 206, 19, 2} means an image region which belongs to
--     diaretdb1_image012.png, XML file #2, position (175, 206) in the image, 
--     radius of 19 pixels, and this region is selected by exactly 
--     2 physicians.
local regions_all = {}

-- Another table to store only the regions that are approved by at least
-- 3 physicians. 
local regions_filtered = {}

-- Number of patches in each image. 
-- This collection is helpful to calculate the size of the train and test
-- datasets, which change every iteration.
local regions_count = {}


-------------------------------------------------------------------------------
-- Load the list of vertices from XML files
--
function loadXML()
	local xmlpath = ""
	local counter_all = 0  -- size of regions_all

	for index = 1, NUM_IMG do
		for j = 1, 4 do
			-- XML path.
			xmlpath = "groundtruth/diaretdb1_image0"
			if index < 10 then
				xmlpath = xmlpath .. "0"
			end
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
								-- Get the radius
								local radius = node:find("radius")
								if radius ~= nil then
									counter_all = counter_all + 1
									regions_all[counter_all] = {}
									regions_all[counter_all][1] = index
									regions_all[counter_all][2] = j
									regions_all[counter_all][3] = coordX
									regions_all[counter_all][4] = coordY
									regions_all[counter_all][5] = radius[1]
									regions_all[counter_all][6] = 1
								end
							end
						end
					end
				end
			end
		end
	end
end


-------------------------------------------------------------------------------
-- Check if two regions overlap
-- Given 2 regions (each contains a x-coord, y-coord, and radius), 
--
function is_overlap(x1, y1, r1, x2, y2, r2)
	local distance = math.sqrt((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2))

	-- If distance is too big, we consider the two regions do not overlap
	if (distance >= r1+r2) then return false end

	return true
end


-------------------------------------------------------------------------------
-- Mark all duplications
--
function agreementCounter()
	for i1 = 1, #regions_all-1 do
		for i2 = i1+1, #regions_all do
			if regions_all[i1][6] == 1
				and regions_all[i2][6] == 1
				and regions_all[i1][1] == regions_all[i2][1]
				and regions_all[i1][2] ~= regions_all[i2][2]
				and is_overlap(
					regions_all[i1][3], regions_all[i1][4], regions_all[i1][5],
					regions_all[i2][3], regions_all[i2][4], regions_all[i2][5]
				) 
				then
					-- Only count for the first one, so later we can remove the
					-- second
					regions_all[i2][6] = 0
			end
		end
	end
end


-------------------------------------------------------------------------------
-- Filter out regions that are selected by less than 3 physicians.
--
function filterRegions()
	local counter_filtered = 0  --size of regions_filtered

	for i = 1, #regions_all do
		if regions_all[i][6] == 1 then
			counter_filtered = counter_filtered + 1
			regions_filtered[counter_filtered] = {}
			regions_filtered[counter_filtered][1] = regions_all[i][1]
			regions_filtered[counter_filtered][2] = regions_all[i][2]
			regions_filtered[counter_filtered][3] = regions_all[i][3]
			regions_filtered[counter_filtered][4] = regions_all[i][4]
			regions_filtered[counter_filtered][5] = regions_all[i][5]
		end
	end
end

-------------------------------------------------------------------------------
-- Save the filtered table to a file
--
function saveFiltered(file)
	for i = 1, #regions_filtered do
		io.write(regions_filtered[i][1] .. "," .. 
			regions_filtered[i][2] .. "," .. 
			regions_filtered[i][3] .. "," .. 
			regions_filtered[i][4] .. "," ..
			regions_filtered[i][5] .. "\n")
	end
end

-------------------------------------------------------------------------------
-- Load the filtered table from a file
--
function loadFiltered(file)
	local counter_filtered = 0  --size of regions_filtered

	while true do
		local line = file:read()
		if line == nil then break end

		counter_filtered = counter_filtered + 1
		regions_filtered[counter_filtered] = {}

		regions_filtered[counter_filtered][1],
		regions_filtered[counter_filtered][2],
		regions_filtered[counter_filtered][3],
		regions_filtered[counter_filtered][4],
		regions_filtered[counter_filtered][5]
			= line:match("([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")

		regions_filtered[counter_filtered][1] = tonumber(regions_filtered[counter_filtered][1])
		regions_filtered[counter_filtered][2] = tonumber(regions_filtered[counter_filtered][2])
		regions_filtered[counter_filtered][3] = tonumber(regions_filtered[counter_filtered][3])
		regions_filtered[counter_filtered][4] = tonumber(regions_filtered[counter_filtered][4])
		regions_filtered[counter_filtered][5] = tonumber(regions_filtered[counter_filtered][5])
	end
end


-------------------------------------------------------------------------------
-- Generate negative samples
--
function generate_negative_samples()
	-- Plant a seed to random values
	math.randomseed(os.time())
	local regions_count = #regions_filtered

	-- Generate negative samples equally among images
	for i = 1, NUM_IMG do
		-- Count if number of randomized negative samples are enough
		local neg_samples_counter = 0

		-- Generate negative samples
		while neg_samples_counter < NUM_LESIONS_NEG/NUM_IMG do
			-- Random a point
			local neg_coordX = math.random(ORIGIN_IMG_W-IMG_PATCH_SIZE-1) 
				+ IMG_PATCH_HALF_POS
			local neg_coordY = math.random(ORIGIN_IMG_H-IMG_PATCH_SIZE-1) 
				+ IMG_PATCH_HALF_POS
			-- Maybe this point does not overlap with the selected points?
			local isOverlap = false

			-- Let's check.
			for j = 1, #regions_filtered do
				if regions_filtered[j][1] == i and is_overlap(
					regions_filtered[j][3], 
					regions_filtered[j][4], 
					regions_filtered[j][5],
					neg_coordX,
					neg_coordY,
					IMG_PATCH_SIZE
				) then
					isOverlap = true
					break
				end
			end

			-- If this point pass the test
			if isOverlap == false then
				regions_count = regions_count + 1
				
				regions_filtered[regions_count] = {}
				regions_filtered[regions_count][1] = i
				regions_filtered[regions_count][2] = 0
				regions_filtered[regions_count][3] = neg_coordX
				regions_filtered[regions_count][4] = neg_coordX
				regions_filtered[regions_count][5] = IMG_PATCH_SIZE

				neg_samples_counter = neg_samples_counter + 1
			end
		end
	end
end


-------------------------------------------------------------------------------
-- Load image.
-- Assumptions/Requirements:
-- + All images are stored in folder "images" which is placed in the same 
--   directory with this file.
--
function loadImage(index)
	local imgpath = "images/diaretdb1_image0"
	if index < 10 then
		imgpath = imgpath .. "0" .. index .. ".png"
	else 
		imgpath = imgpath .. index .. ".png"
	end

	return image.load(imgpath)
end

-------------------------------------------------------------------------------

function loadData(indices)
	local size = 0

	-- value is the index of the image
	for key, value in pairs(indices) do
		size = size + regions_count[value]
	end

	local img_crop = torch.Tensor(size, 3, IMG_PATCH_SIZE, IMG_PATCH_SIZE)
	local label = torch.Tensor(size)

	local counter = 0

	-- value is the index of the image
	for key, value in pairs(indices) do
		counter = counter + 1

		for i = 1, #regions_filtered do
			if (regions_filtered[i][2] == value) then
				image.crop(
					img_crop[counter], 
					loadImage(value), 
					regions_filtered[i][3] + IMG_PATCH_HALF_NEG,
					regions_filtered[i][4] + IMG_PATCH_HALF_NEG,
					regions_filtered[i][3] + IMG_PATCH_HALF_POS,
					regions_filtered[i][4] + IMG_PATCH_HALF_POS
				)
			end
		end
	end

	local img = torch.Tensor(size, IMG_PATCH_SIZE*IMG_PATCH_SIZE)

	for idx = 1, size do
		for i = 1, IMG_PATCH_SIZE do
			for j = 1, IMG_PATCH_SIZE do
				img[size][(i-1) * IMG_PATCH_SIZE + j] = img_crop[size][2][i][j]
			end
		end
	end

	return img, label
end


-------------------------------------------------------------------------------
-- Execute all functions
-- 
function util_init()
	local file = io.open("filted_regions.txt", "r")
	if file == nil 
		--or filesize(file) < 1 
		then
		-- Create the file
		file = io.open("filted_regions.txt", "w")

		-- Fill up the table
		loadXML()
		agreementCounter()
		filterRegions()
		generate_negative_samples()
		
		-- Write to file
		io.output(file)
		saveFiltered(file)
		io.close(file)
		--io.flush()
	else
		io.input(file)
		loadFiltered(file)
		io.close(file)
		io.flush()
	end

	for i = 1, 89 do regions_count[i] = 0 end

	for j = 1, #regions_filtered do
		regions_count[regions_filtered[j][1]] = 
			regions_count[regions_filtered[j][1]] + 1
	end

	--print(#regions_filtered)
end


-------------------------------------------------------------------------------
-- Main
-- 
util_init()