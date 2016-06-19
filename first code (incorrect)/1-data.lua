--[[
-- Author: Hai Tran
-- Date: May 22, 2016
-- File: 1-data.lua
-- Load raw data from the images and XML files.
--]]

print("==> Loading data...")


-------------------------------------------------------------------------------
-- Load raw data.
-- Assumptions/Requirements:
-- + Two folders "images" and "groundtruth" are placed
--   add the same directory with this file.
-- + Images are stored in "images".
-- + XML files are stored in "groundtruth".
--
function loadRawData()
	-- This storage will store all the image patches.
	img = torch.Tensor(DATASET_SIZE, 3, IMG_PATCH_SIZE, IMG_PATCH_SIZE)
	-- Label (positive or negative sample)
	label = torch.Tensor(DATASET_SIZE)

	-- This tensor will store all the original images
	local img_orig = torch.Tensor(NUM_IMG, 3, ORIGIN_IMG_H, ORIGIN_IMG_W)
	
	-- The following tables will store the coordinators of the centroid of
	-- positive and negative samples
	local positive_coords = {}
	local negative_coords = {}

	-- A counter to see how many slots have been filled in the img storage.
	local counter = 1

	-- Since there is a small diffenrece in file name
	-- (image003 vs. image015), we need to self-generate
	-- the path to each file.
	for index = 1, NUM_IMG do
		--print("Loading Image #" .. index)

		if index < 10 then
			-- Image path.
			local imgpath = "images/diaretdb1_image00" .. index .. ".png"
			-- Load image.
			img_orig[index] = image.load(imgpath)

			-- Load xml files corresponded to this image.
			-- Each image goes with 4 XML files.
			for j = 1, 4 do
				-- XML path.
				local xmlpath = "groundtruth/diaretdb1_image00" .. index .. "_0" .. j .. ".xml"
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
								for i = 1, #centroid do
									-- Fourth, find <coords2d> tag. This is the value
									-- that we want to grab.
									local coords2d = centroid[i]:find("coords2d")
									-- Split into horizontal and vertical coordinators.
									local coordX, coordY = coords2d[1]:match("([^,]+),([^,]+)")
									-- Crop img to get an image patch.
									if coordX+IMG_PATCH_HALF_NEG > 0 and coordY+IMG_PATCH_HALF_NEG > 0 and coordX+IMG_PATCH_HALF_POS < ORIGIN_IMG_W and coordY+IMG_PATCH_HALF_POS < ORIGIN_IMG_H then
										image.crop(img[counter], img_orig[index], coordX+IMG_PATCH_HALF_NEG, coordY+IMG_PATCH_HALF_NEG, coordX+IMG_PATCH_HALF_POS, coordY+IMG_PATCH_HALF_POS)
										-- Label: positive
										label[counter] = 1
										-- Add to positive_coords
										table.insert(positive_coords, {index, coordX, coordY})
										-- Increase counter
										counter = counter + 1
									end
								end
							end
						end
					end
				end
			end
		else
			-- Image path.
			local imgpath = "images/diaretdb1_image0" .. index .. ".png"
			-- Load image.
			img_orig[index] = image.load(imgpath)
			-- Load xml files corresponded to this image.
			-- Each image goes with 4 XML files.
			for j = 1, 4 do
				--print("XML file #" .. j)
				-- XML path.
				local xmlpath = "groundtruth/diaretdb1_image0" .. index .. "_0" .. j .. ".xml"
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
								for i = 1, #centroid do
									-- Fourth, find <coords2d> tag. This is the value
									-- that we want to grab.
									local coords2d = centroid[i]:find("coords2d")
									-- Split into horizontal and vertical coordinators.
									local coordX, coordY = coords2d[1]:match("([^,]+),([^,]+)")
									-- Crop img to get an image patch.
									if coordX+IMG_PATCH_HALF_NEG > 0 and coordY+IMG_PATCH_HALF_NEG > 0 and coordX+IMG_PATCH_HALF_POS < ORIGIN_IMG_W and coordY+IMG_PATCH_HALF_POS < ORIGIN_IMG_H then
										image.crop(img[counter], img_orig[index], coordX+IMG_PATCH_HALF_NEG, coordY+IMG_PATCH_HALF_NEG, coordX+IMG_PATCH_HALF_POS, coordY+IMG_PATCH_HALF_POS)
										-- Label: positive
										label[counter] = 1
										-- Add to positive_coords
										table.insert(positive_coords, {index, coordX, coordY})
										-- Increase counter
										counter = counter + 1
									end
								end
							end
						end
					end
				end
			end
		end
	end

	-- Plant a seed to random values
	math.randomseed(os.time())
	-- Count if number of randomized negative samples are enough
	local neg_samples_counter = 0
	-- Generate negative samples
	while neg_samples_counter < NUM_LESIONS_NEG do
		-- Random an image
		local neg_img = math.random(NUM_IMG)
		-- Random a point
		local neg_coordX = math.random(ORIGIN_IMG_W-IMG_PATCH_SIZE-1) + IMG_PATCH_HALF_POS
		local neg_coordY = math.random(ORIGIN_IMG_H-IMG_PATCH_SIZE-1) + IMG_PATCH_HALF_POS
		-- Maybe this point does not overlap with the selected points?
		local isOverlap = false

		-- Let us check.
		for threshold = 0, IMG_PATCH_HALF_POS do
			if positive_coords[{neg_img, neg_coordX-threshold, neg_coordY-threshold}] ~= nil 
				or positive_coords[{neg_img, neg_coordX+threshold, neg_coordY+threshold}] ~= nil
				or negative_coords[{neg_img, neg_coordX, neg_coordY}] ~= nil 
			then
				isOverlap = true
			end
		end

		-- If this point pass the test
		if isOverlap == false then
			-- Get the crop
			image.crop(img[counter], img_orig[neg_img], neg_coordX+IMG_PATCH_HALF_NEG, neg_coordY+IMG_PATCH_HALF_NEG, neg_coordX+IMG_PATCH_HALF_POS, neg_coordY+IMG_PATCH_HALF_POS)
			-- Label is now false
			label[counter] = 0
			-- Increase counter
			counter = counter + 1
			-- Record it
			table.insert(negative_coords, {neg_img, neg_coordX, neg_coordY})
		end

		-- Increase counter.
		neg_samples_counter = neg_samples_counter + 1
	end

	-- "Flatten" img tensor to a 2D tensor
	-- We'll use the green channel only (as the paper suggests)
	local data = torch.Tensor(DATASET_SIZE, IMG_PATCH_SIZE * IMG_PATCH_SIZE)
	for i = 1, DATASET_SIZE do
		for j = 1, IMG_PATCH_SIZE do
			for k = 1, IMG_PATCH_SIZE do
				data[i][(j-1)*IMG_PATCH_SIZE + k] = img[i][2][j][k]
			end
		end
	end

	-- Convert the storage to a tensor.
	return data, label
end


-------------------------------------------------------------------------------
--[[
-- I planned to dump all the loaded data into a text file,
-- so I do not have to generate them again everytime I run this.
-- However, it is not easy to write a 4D tensor and load it without
-- losing any information of the structure. Therefore, I will risk
-- my time by not doing any file saving here.
--]]


-------------------------------------------------------------------------------
-- Test
-- local gmi, lebal = loadRawData()
