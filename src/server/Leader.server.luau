local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Your PlayerDataManager already handles leaderstats creation and updates!
-- This script provides additional functionality for manual updates and synchronization

local module = require(ReplicatedStorage.PlayerDataManager)

-- Function to manually update leaderstats (backup sync)
local function updateLeaderstats(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	-- Update Money
	local money = leaderstats:FindFirstChild("Money")
	if money then
		local currentMoney = module.GetPlayerData(player, "money")
		if currentMoney then
			money.Value = currentMoney
		end
	end

	-- Update KO
	local ko = leaderstats:FindFirstChild("KO")
	if ko then
		local currentKO = module.GetPlayerData(player, "KO")
		if currentKO then
			ko.Value = currentKO
		end
	end
end

-- Periodic sync to ensure leaderstats stay updated (backup system)
task.spawn(function()
	while true do
		task.wait(10) -- Check every 10 seconds
		for _, player in pairs(Players:GetPlayers()) do
			if player:FindFirstChild("leaderstats") then
				updateLeaderstats(player)
			end
		end
	end
end)

-- Optional: Create a remote event for manual updates
local updateLeaderstatsEvent = ReplicatedStorage:FindFirstChild("UpdateLeaderstatsEvent")
if not updateLeaderstatsEvent then
	updateLeaderstatsEvent = Instance.new("RemoteEvent")
	updateLeaderstatsEvent.Name = "UpdateLeaderstatsEvent"
	updateLeaderstatsEvent.Parent = ReplicatedStorage
end

-- Handle manual update requests
updateLeaderstatsEvent.OnServerEvent:Connect(function(player)
	updateLeaderstats(player)
end)

-- Global functions for other scripts to use
_G.UpdatePlayerLeaderstats = updateLeaderstats

-- Function to add KO (since your module doesn't have a dedicated KO function)
_G.AddKO = function(player, amount)
	amount = amount or 1
	local currentKO = module.GetPlayerData(player, "KO") or 0
	module.SetPlayerData(player, "KO", currentKO + amount)
end

print("Leaderstats updater loaded - works with existing PlayerDataManager!")