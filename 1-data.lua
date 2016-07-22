--[[
-- Author: Hai Tran
-- Date: June 11, 2016
-- File: 1-data.lua
-- Load raw data from the images and XML files.
--]]

print("==> Loading data...")

DATASET_SIZE = 10585

--------------------------------------------------------------------------------
-- Load data from txt file
--
function load_data(path)
	local file = assert(io.open(path, "r"))
	local data, label = {}, {}
	local line

	for i = 1, DATASET_SIZE do
		line = file:read()
		data[i] = {}

		data[i][1],
		data[i][2],
		data[i][3],
		data[i][4],
		data[i][5],
		data[i][6],
		data[i][7],
		label[i]
		= line:match("([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*)")
	end

	return data, label
end


--------------------------------------------------------------------------------
-- Test
--
--data, label = load_data("result.txt")
--print(data)