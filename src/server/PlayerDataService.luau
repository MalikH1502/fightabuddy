local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataManager = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PlayerDataManager"))

local PlayerDataService = {}

local DataStore = DataStoreService:GetDataStore("PlayerData")

local defaultData = {
	inventory = {"BasicGloves"},
	money = 0,
	KO = 0,
	Equipped = "BasicGloves",
}

local initialized = false

local function cloneValue(value)
	if type(value) ~= "table" then
		return value
	end

	local copy = {}
	for index, item in ipairs(value) do
		copy[index] = cloneValue(item)
	end
	return copy
end

local function createDefaultData()
	local data = {}
	for key, value in pairs(defaultData) do
		data[key] = cloneValue(value)
	end
	return data
end

local function getOrCreateLeaderstats(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local money = leaderstats:FindFirstChild("Money")
	if not money then
		money = Instance.new("IntValue")
		money.Name = "Money"
		money.Parent = leaderstats
	end

	local ko = leaderstats:FindFirstChild("KO")
	if not ko then
		ko = Instance.new("IntValue")
		ko.Name = "KO"
		ko.Parent = leaderstats
	end

	return leaderstats, money, ko
end

local function updateLeaderstats(player)
	local data = PlayerDataManager.GetPlayerData(player)
	if not data then
		return
	end

	local _, money, ko = getOrCreateLeaderstats(player)
	money.Value = data.money or 0
	ko.Value = data.KO or 0
end

local function syncLeaderstat(player, key, value)
	if key ~= "money" and key ~= "KO" then
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end

	local stat = leaderstats:FindFirstChild(key == "money" and "Money" or "KO")
	if stat then
		stat.Value = value
	end
end

local function loadPlayerData(player)
	local playerId = player.UserId
	local success, data

	local attempts = 0
	while attempts < 3 do
		attempts = attempts + 1
		success, data = pcall(function()
			return DataStore:GetAsync(playerId)
		end)

		if success then
			break
		end
	end

	if not success then
		warn("Failed to load data for " .. player.Name)
	end

	local playerData = createDefaultData()
	if success and type(data) == "table" then
		for key, value in pairs(data) do
			playerData[key] = cloneValue(value)
		end
	end

	PlayerDataManager.InitializePlayerData(player, playerData)
	getOrCreateLeaderstats(player)
	updateLeaderstats(player)
end

local function savePlayerData(player)
	local playerData = PlayerDataManager.GetPlayerData(player)
	if not playerData then
		return
	end

	local success
	local attempts = 0
	while attempts < 3 do
		attempts = attempts + 1
		success = pcall(function()
			return DataStore:SetAsync(player.UserId, playerData)
		end)

		if success then
			break
		end
	end

	if not success then
		warn("Failed to save data for " .. player.Name)
	end
end

local function registerGlobals()
	_G.UpdatePlayerLeaderstats = updateLeaderstats
	_G.AddKO = function(player, amount)
		amount = amount or 1
		local currentKO = PlayerDataManager.GetPlayerData(player, "KO") or 0
		PlayerDataManager.SetPlayerData(player, "KO", currentKO + amount)
	end
end

function PlayerDataService.Start()
	if initialized then
		return
	end
	initialized = true

	registerGlobals()
	PlayerDataManager.OnPlayerDataChanged.Event:Connect(syncLeaderstat)

	Players.PlayerAdded:Connect(loadPlayerData)
	Players.PlayerRemoving:Connect(function(player)
		savePlayerData(player)
		PlayerDataManager.ClearPlayerData(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		loadPlayerData(player)
	end

	task.spawn(function()
		while true do
			task.wait(300)
			for _, player in ipairs(Players:GetPlayers()) do
				savePlayerData(player)
			end
		end
	end)

	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			savePlayerData(player)
		end
		task.wait(2)
	end)
end

PlayerDataService.Start()

return PlayerDataService