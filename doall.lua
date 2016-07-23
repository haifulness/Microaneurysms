--[[
-- Author: Hai Tran
-- Date: May 22, 2016
-- File: doall.lua
--]]

require "optim"
require "nn"
require "gnuplot"


-------------------------------------------------------------------------------
-- Constants.
--
INPUT_SIZE = 7
DATASET_SIZE = 10585

-- k-fold cross-validation
NUM_FOLDS = 10

-- Size of each subset
SUB_SIZE = math.floor(DATASET_SIZE / NUM_FOLDS)


-------------------------------------------------------------------------------
-- Configuration
params = {
	seed = 1,  -- initial random seed
	threads = 1,  -- number of threads
	beta = 1e1,  -- prediction error coefficient
	batch_size = 1,  -- batch size
	max_epoch = 1e5,  -- max number of updates
}

config = {
	learningRate = 1e-3
	, momentum = 1e-3
	--, weightDecay = 1e-3
	, learningRateDecay = 1e-6
}

torch.manualSeed(os.clock())
--torch.setnumthreads(params.threads)


-------------------------------------------------------------------------------
-- Run
--
-- Load files
dofile "1-data.lua"
dofile "2-model.lua"
dofile "3-train.lua"

print("==> Run")

-- Load data
local data, target = load_data("result.txt")

-- Build models and train
for num_hidden_layers = 5, 20 do
	for num_hidden_nodes = 10, 100, 10 do
		for turn = 1, 5 do
			local log, logErr = io.open("log.txt", "a+")
			if logErr then 
				print("File open error")
				break
			end
			log:write("\n-------------------------------------------")
			log:write("\nNum of hidden layers: ", num_hidden_layers)
			log:write("\nNum of hidden nodes: ", num_hidden_nodes)
			log:write("\nTurn: ", turn)

			local timer = torch.Timer()

			-- Prepare data
			local indices = torch.randperm(DATASET_SIZE)
			local idx = {}

			-- Assign indices into subsets
			for i = 1, NUM_FOLDS do
				idx[i] = {}
				for j = 1, SUB_SIZE do
					idx[i][j] = indices[(i-1) * SUB_SIZE + j]
				end
			end

			-- The last subset receives the remains
			for j = 1, DATASET_SIZE % NUM_FOLDS do
				idx[NUM_FOLDS][SUB_SIZE + j] = indices[DATASET_SIZE - j + 1]
			end

			local train_err = {}
			local tp, tn, fp, fn = {}, {}, {}, {}

			for fold = 1, 1 do
				-- Build model
				local model, criterion = 
					buildModel(INPUT_SIZE, num_hidden_nodes, 1, num_hidden_layers, "sigmoid")
				-- Create train & test datasets
				local train_input = torch.Tensor(DATASET_SIZE - #idx[fold], INPUT_SIZE)
				local train_output = torch.Tensor(DATASET_SIZE - #idx[fold])
				local test_input = torch.Tensor(#idx[fold], INPUT_SIZE)
				local test_output = torch.Tensor(#idx[fold])

				-- Pull data into the train and test sets
				for i = 1, 10 do
					local train_counter = 1

					if i == fold then
						for j = 1, #idx[i] do
							test_input[j] = torch.Tensor(data[idx[i][j]])
							test_output[j] = target[idx[i][j]]
						end
					else
						for j = 1, #idx[i] do
							for k = 1, INPUT_SIZE do
								train_input[train_counter][k] = data[idx[i][j]][k]
							end
							train_output[train_counter] = target[idx[i][j]]
							train_counter = train_counter + 1
						end
					end
				end

				for epoch = 1, params.max_epoch do
					train_err[fold] = train(model, criterion, train_input, train_output)
				end

				tp[fold], tn[fold], fp[fold], fn[fold] = test(model, test_input, test_output)	
				
				print(fold, train_err[fold], tp[fold], tn[fold], fp[fold], fn[fold])
				log:write("\n", tp[fold], "\n", tn[fold], "\n", fp[fold], "\n", fn[fold], "\n", train_err[fold])
				
				local precision = (double)(tp[fold]) / ((double)(tp[fold]) + (double)(fp[fold]))
				local recall = (double)(tp[fold]) / ((double)(tp[fold]) + (double)(fn[fold]))
				log:write("Precision: ", precision)
				log:write("Recall: ", recall)
				log:write("Specificity: ", (double)(tn[fold]) / ((double)(tn[fold]) + (double)(fp[fold])))
				log:write("F-measure: ", 2*precision*recall/(precision + recall))
				log:write("Accuracy: ", ((double)(tp[fold]) + (double)(fn[fold])) / ((double)(tp[fold]) + (double)(tn[fold]) + (double)(fp[fold]) + (double)(fn[fold])))
			end

			log:write("\nTotal time: ", timer:time().real, " seconds")
			log:close()
			print("Total time: " .. timer:time().real .. " seconds\n")
		end
	end
end
