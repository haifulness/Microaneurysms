--[[
-- Author: Hai Tran
-- Date: May 22, 2016
-- File: 2-model.lua
-- Create the model (autoencoders & stacked sparse autoencoder).
--]]

print("==> Building model...")

-----------------------------------------------------
-- Autoencoder #1
--
-- Encoder
encoder1 = nn.Linear(IMG_PATCH_SIZE*IMG_PATCH_SIZE, HIDDEN_FIRST)
-- Decoder
decoder1 = nn.Linear(HIDDEN_FIRST, IMG_PATCH_SIZE*IMG_PATCH_SIZE)
-- Autoencoder
ae1 = nn.Sequential()
ae1:add(encoder1)
ae1:add(decoder1)


-----------------------------------------------------
-- Autoencoder #2
--
-- Encoder
encoder2 = nn.Linear(HIDDEN_FIRST, HIDDEN_SECOND)
-- Decoder
decoder2 = nn.Linear(HIDDEN_SECOND, HIDDEN_FIRST)
-- Autoencoder
ae2 = nn.Sequential()
ae2:add(encoder2)
ae2:add(decoder2)

-----------------------------------------------------
-- Stacked Autoencoder
-- We discard all decoders
--
model = nn.Sequential()
model:add(encoder1)
model:add(encoder2)
model:add(nn.Linear(HIDDEN_SECOND, 1))
model:add(nn.SoftMax())

-----------------------------------------------------
-- Criterion
--
criterion = nn.MSECriterion(false)
