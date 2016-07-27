--[[
-- Author: Hai Tran
-- Date: Jul 15, 2016
-- File: 3-train.lua
--]]


--------------------------------------------------------------------------------
-- Train a model
--
function train(train_input, train_output)
	model: training()
	local params, grads = model:getParameters()
	local total_err = 0

	for idx = 1, train_input:size(1) do

		-- Define eval closure
		local feval = function(x)
			-- Get new parameters
			if params ~= x then params:copy(x) end
			-- Reset gradients
			grads:zero()

			local input = train_input[idx]
			local output = torch.Tensor(1)
			output[1] = train_output[idx]

			local prediction = model:forward(input)
			local err = criterion:forward(prediction, output)
			local df_dw = criterion:backward(prediction, output)
			model:backward(input, df_dw)

			total_err = total_err + err
			print(err)

			-- Return 
			return  err, grads
		end

		-- Train
		optim.sgd(feval, params, config)
	end

	return total_err/train_input:size(1)
end


--------------------------------------------------------------------------------
-- Test a model
--
function test(test_input, test_output)
	model:evaluate()

	local tp, tn, fp, fn = 0, 0, 0, 0

	for idx = 1, test_input:size(1) do
		local input = test_input[idx]
		local output = torch.Tensor(1)
		print(test_output[idx]:size())
		output[1] = test_output[idx]

		local prediction = model:forward(input)
		prediction[1] = math.floor(prediction[1] + 0.5)

		if output[1] == 1 and prediction[1] == 1 then tp = tp + 1 end
		if output[1] == 1 and prediction[1] == 0 then tn = tn + 1 end
		if output[1] == 0 and prediction[1] == 1 then fp = fp + 1 end
		if output[1] == 0 and prediction[1] == 0 then fn = fn + 1 end
	end

	model:training()

	return tp, tn, fp, fn
end
