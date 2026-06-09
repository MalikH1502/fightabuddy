local Players = game:GetService("Players")
local gloveStorage = game:GetService("ReplicatedStorage").Gloves
local PlayerDataManager = require(game:GetService("ReplicatedStorage").Shared.PlayerDataManager)

local function unEquipGloves(character)
	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		for _, accessory in pairs(humanoid:GetAccessories()) do
			if accessory.Name == "LeftGlove" or accessory.Name == "RightGlove" then
				accessory:Destroy()
			end
		end
	end
end

local function equipGloves(player, character)
	wait(.1)
	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		local equippedGlove = PlayerDataManager.GetPlayerData(player, "Equipped") or "BasicGloves"
		local gloveFolder = gloveStorage:FindFirstChild(equippedGlove)
		if gloveFolder then
			local leftGlove = gloveFolder:FindFirstChild("LeftGlove")
			local rightGlove = gloveFolder:FindFirstChild("RightGlove")

			if leftGlove then
				local leftClone = leftGlove:Clone()
				humanoid:AddAccessory(leftClone)
			end

			if rightGlove then
				local rightClone = rightGlove:Clone()
				humanoid:AddAccessory(rightClone)
			end

			print("Equipped " .. equippedGlove .. " for " .. player.Name)
		else
			warn("Glove " .. equippedGlove .. " not found in storage for " .. player.Name)
		end
	end
end



PlayerDataManager.OnItemEquipped.Event:Connect(function(player)
	if player and player.Character then
		unEquipGloves(player.Character)
		equipGloves(player, player.Character)
	end
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		equipGloves(player, character)
	end)
end)

for _, player in pairs(Players:GetPlayers()) do
	if player.Character then
		equipGloves(player, player.Character)
	end

	player.CharacterAdded:Connect(function(character)
		equipGloves(player, character)
	end)
end