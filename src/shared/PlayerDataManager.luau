local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local DataStore = DataStoreService:GetDataStore("PlayerData")


local defData = {
	inventory = {"BasicGloves"},
	money = 0,
	KO = 0,
	Equipped = "BasicGloves"
}

local PlayerData = {}

local PlayerDataManager = {}

local function CreateLeaderstats(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Value = PlayerData[player.UserId].money
	money.Parent = leaderstats

	local KO = Instance.new("IntValue")
	KO.Name = "KO"
	KO.Value = PlayerData[player.UserId].KO
	KO.Parent = leaderstats
end

local function LoadPlayerData(player)
	local playerID = player.UserId
	local success, data

	local attempts = 0
	repeat
		attempts+=1
		success,data = pcall(function()
			return DataStore:GetAsync(playerID)
		end)
	until attempts >= 3
	if not success then
		warn("Failed to Load data for "..player.Name)
	end
	if success then
		if data then
			PlayerData[playerID] = data
		else
			PlayerData[playerID] = {}
			for i,v in pairs(defData) do
				PlayerData[playerID][i] = v
			end
		end
	else
		PlayerData[playerID] = {}
		for i,v in pairs(defData) do
			PlayerData[playerID][i] = v
		end
	end
	CreateLeaderstats(player)
end

local function SavePlayerData(player)
	local playerID = player.UserId
	local playerData = PlayerData[playerID]
	local success

	local attempts = 0
	repeat
		attempts+=1
		success = pcall(function()
			return DataStore:SetAsync(playerID, playerData)
		end)
	until attempts >= 3
	if not success then
		warn("Failed to Save data for "..player.Name)
	end
end

function PlayerDataManager.GetPlayerData(player, key)
	local playerID = player.UserId
	if PlayerData[playerID] then
		return PlayerData[playerID][key]
	end
	return nil
end

function PlayerDataManager.SetPlayerData(player,key,value)
	local playerID = player.UserId
	if PlayerData[playerID] then
		PlayerData[playerID][key] = value

		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local stat = leaderstats:FindFirstChild(key)
			if stat then
				stat.Value = value
			end
		end
		return true
	end
	return false
end

function PlayerDataManager.AddMoney(player, amount)
	if amount == 0 then return end
	local currentMoney = PlayerDataManager.GetPlayerData(player, "money")
	PlayerDataManager.SetPlayerData(player, "money", currentMoney + amount)
end

-- In PlayerDataManager
function PlayerDataManager.AddItemToInventory(player, itemName)
	local playerData = PlayerDataManager.GetPlayerData(player)
	if not playerData then return end

	-- Check if item already exists to prevent duplicates
	for i, existingItem in pairs(playerData.Inventory) do
		if existingItem == itemName then
			print("Item already in inventory, not adding duplicate:", itemName)
			return -- Don't add duplicate
		end
	end

	-- Add item if not already present
	table.insert(playerData.Inventory, itemName)
	print("Added to inventory:", itemName)

	-- Save data immediately
	PlayerDataManager.SetPlayerData(player)
end

function PlayerDataManager.EquipItem(player, itemName)
	local inventory = PlayerDataManager.GetPlayerData(player, "inventory")
	PlayerDataManager.SetPlayerData(player, "Equipped", itemName)
	PlayerDataManager:ItemEquipped(player)
end

function PlayerDataManager:ItemEquipped(player)
	if self.OnItemEquipped then
		self.OnItemEquipped:Fire(player)
	end
end


PlayerDataManager.OnItemEquipped = Instance.new("BindableEvent")
PlayerDataManager.OnItemEquipped.Name = "ItemEquippedEvent"

Players.PlayerAdded:Connect(function(player)
	LoadPlayerData(player)
end)

Players.PlayerRemoving:Connect(function(player)
	SavePlayerData(player)
	PlayerData[player.UserId] = nil
end)

spawn(function()
	while true do
		wait(300)
		for _, player in pairs(Players:GetPlayers()) do
			SavePlayerData(player)
		end
		print("Auto-saved all player data")
	end
end)

game:BindToClose(function()
	print("Server shutting down, saving all data...")
	for _, player in pairs(Players:GetPlayers()) do
		SavePlayerData(player)
	end
	wait(2)
end)



return PlayerDataManager