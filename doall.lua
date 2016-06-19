--[[
-- Author: Hai Tran
-- Date: May 22, 2016
-- File: doall.lua
--]]

require "unsup"
require "image"
require "optim"
require "nn"
require "gnuplot"
require "LuaXML"
--require ("util.lua")

-------------------------------------------------------------------------------
-- Constants.
--
-- Number of images and their original sizes.
NUM_IMG = 89
ORIGIN_IMG_W = 1500
ORIGIN_IMG_H = 1152

-- Number of positive lesions. 
-- WARNING: the paper says this value is 2182.
NUM_LESIONS_POS = 2057

-- Number of negative lesions. The value is get from the paper. 
-- We can modify it later.
NUM_LESIONS_NEG = 6230

-- Total
DATASET_SIZE = NUM_LESIONS_POS + NUM_LESIONS_NEG

-- We can modify this value.
IMG_PATCH_SIZE = 25

-- To get a square around with a given point as its center,
-- we need to locate the top left and the bottom right
-- vertices of the square. The below two values are for 
-- that purpose.
IMG_PATCH_HALF_NEG = -math.floor(IMG_PATCH_SIZE / 2)
IMG_PATCH_HALF_POS = math.ceil(IMG_PATCH_SIZE / 2)

-- Number of nodes in hidden layers of the autoencoder.
HIDDEN_FIRST = 225
HIDDEN_SECOND = 100


-------------------------------------------------------------------------------
-- Configuration
params = {
	seed = 1,  -- initial random seed
	threads = 2,  -- number of threads
	beta = 1e1,  -- prediction error coefficient
	batch_size = 1,  -- batch size
	max_epoch = 5e1,  -- max number of updates
	max_epoch1 = 1e4,  -- for the first autoencoder
	max_epoch2 = 1e4,  -- for the second autoencoder
	num_folds = 10  -- 10-fold cross-validation
}

optimState = {
	learningRate = 1e-3,
	momentum = 1e-2,
	weightDecay = 3e-3,
	learningRateDecay = 1e-7
}

torch.manualSeed(os.clock())
torch.setnumthreads(params.threads)


-------------------------------------------------------------------------------
-- Run
--
-- Load data
-- Assumptions/Requirements:
-- + Two folders "images" and "groundtruth" are placed
--   add the same directory with this file.
-- + Images are stored in "images".
-- + XML files are stored in "groundtruth".
dofile "1-data.lua"
--data, label = loadRawData()

-- Create model
--dofile "2-model.lua"

-- Train model
--dofile "3-train.lua"
