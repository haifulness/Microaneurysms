--[[
-- Author: Hai Tran
-- Date: May 22, 2016
-- File: 3-train.lua
-- Train the built model.
--]]

print("==> Training...")

-- Indices for the autoencoders
local train_indices, validate_indices, test_indices = {}, {}, {}
local indices = torch.randperm(DATASET_SIZE)

-- Indices for the final model
local fold_size = math.floor(DATASET_SIZE/params.num_folds)
local idx = torch.Tensor(params.num_folds, fold_size)

local ssa_train_set = torch.Tensor(fold_size)

-----------------------------------------------------
-- Divide dataset by randomizing the indices
--
function shuffleData()	
	-- Train
	for i = 1, math.floor(DATASET_SIZE * 0.6) do
		train_indices[i] = indices[i]
	end

	-- Validate
	for i = math.floor(DATASET_SIZE * 0.6) + 1, math.floor(DATASET_SIZE * 0.8) do
		validate_indices[i - math.floor(DATASET_SIZE * 0.6)] = indices[i]
	end
	
	-- Test
	for i = math.floor(DATASET_SIZE * 0.8) + 1, DATASET_SIZE do
		test_indices[i - math.floor(DATASET_SIZE * 0.8)] = indices[i]
	end
end


-----------------------------------------------------
-- Train autoencoders
-- 
function train_ae(aemodel, datasrc)
	i = (i or 0) + 1
	if i > #train_indices then i = 1 end

	local input = datasrc[train_indices[i]]
	local target = input

	local prediction = aemodel:forward(input)
	local loss = criterion:forward(prediction, target)
	aemodel:zeroGradParameters()
	aemodel:backward(input, criterion:backward(aemodel.output, target))
	aemodel:updateParameters(optimState.learningRate)
end



-----------------------------------------------------
-- Test the stacked sparse autoencoder
-- 
function test_ssa(fold_num)
	local correct = 0
	-- True Positive, True Negative, False Positive, False Negative
	local tp, fp, fn, tn = 0, 0, 0, 0

	for i = 1, fold_size do
		local input = data[idx[fold_num][i]]
		local target = torch.Tensor(1)
		target[1] = label[idx[fold_num][i]]

		local prediction = model:forward(input)
		local predictedLabel = math.floor(prediction[1] + 0.5)

		if predictedLabel == 1 and target[1] == 1 then tp = tp + 1 end
		if predictedLabel == 1 and target[1] == 0 then fp = fp + 1 end
		if predictedLabel == 0 and target[1] == 1 then fn = fn + 1 end
		if predictedLabel == 0 and target[1] == 1 then tn = tn + 1 end
	end

	--print(fn)

	local _precision = tp/(tp + fp)
	local _recall = tp/(tp + fn)
	local _specificity = tn/(tn + fp)
	local _fmeasure = 2*_precision*_recall/(_precision + _recall)

	return _precision, _recall, _specificity, _fmeasure
end


-----------------------------------------------------
--
-- Shuffle data for the autoencoders
shuffleData()
-- 10-fold cross-validation
-- First, we random the dataset again
indices = torch.randperm(DATASET_SIZE)
-- Second, we assign the indices to 10 sets
for i = 1, params.num_folds do
	for j = 1, fold_size do
		idx[i][j] = indices[(i-1)*fold_size + j]
	end
end

w, dl_dw = model:getParameters()

local timer = torch.Timer()

-- Train autoencoder #1
print("Training AutoEncoder #1")
for i = 1, params.max_epoch1 do
	train_ae(ae1, data)
end

-- Reformat all data
local reformattedData = torch.Tensor(DATASET_SIZE, HIDDEN_FIRST)
for i = 1, DATASET_SIZE do
	reformattedData[i] = encoder1:forward(data[i])
end

-- Train autoencoder #2
print("Training AutoEncoder #2")
for i = 1, params.max_epoch2 do
	train_ae(ae2, reformattedData)
end

-- Train the final model
print("Training SSA")
local precision, recall, specificity, fmeasure = {}, {}, {}, {}
-- Define eval closure
local feval = function(w_new)
	-- Reset data
	if w ~= w_new then w:copy(w_new) end
	dl_dw:zero()

	i = (i or 0) + 1
	if i > fold_size then i = 1 end

	local input = data[ssa_train_set[i]]
	local target = torch.Tensor(1)
	target[1] = label[ssa_train_set[i]]

	local prediction = model:forward(input)
	local loss_w = criterion:forward(prediction, target)
	local df_dw = criterion:backward(prediction, target)
	model:backward(input, df_dw)

	-- Return 
	return  loss_w, dl_dw
end

for i = 1, params.num_folds do
	-- Leave out 1 set
	local leave_out = i

	-- Train with num_folds-1 sets
	for ii = 1, params.max_epoch do
		for j = 1, params.num_folds do
			if j ~= i then
				ssa_train_set = idx[j]
				-- Stochastic Gradient Descent
				w_new, fs = optim.sgd(feval, w, optimState)
			end
		end
	end

	-- Test with the left out set
	precision[i], recall[i], specificity[i], fmeasure[i] = test_ssa(leave_out)
end

local avgprecision, avgrecall, avgspecificity, avgfmeasure = 0, 0, 0, 0
for i = 1, params.num_folds do
	avgprecision = avgprecision + precision[i]
	avgrecall = avgrecall + recall[i]
	avgspecificity = avgspecificity + specificity[i]
	avgfmeasure = avgfmeasure + fmeasure[i]
end

avgprecision = avgprecision / params.num_folds
avgrecall = avgrecall / params.num_folds
avgspecificity = avgspecificity / params.num_folds
avgfmeasure = avgfmeasure / params.num_folds

print("----- RESULT -----")
print("Image patch size: " .. IMG_PATCH_SIZE)
print("Dimension of the two hidden layers: " .. HIDDEN_FIRST .. "*" .. HIDDEN_SECOND)
print("Training iterations: " .. params.max_epoch)
print("Total time: " .. timer:time().real .. " seconds\n")

print("Avg Precision (%) = " .. avgprecision*100)
print("Avg Recall (%) = " .. avgrecall*100)
print("Avg Specificity (%) = " .. avgspecificity*100)
print("Avg F-measure (%) = " .. avgfmeasure*100)