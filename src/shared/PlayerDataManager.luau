local defData = {
	inventory = {"BasicGloves"},
	money = 0,
	KO = 0,
	Equipped = "BasicGloves"
}

local PlayerData = {}

local PlayerDataManager = {}

local function CloneValue(value)
	if type(value) ~= "table" then
		return value
	end

	local copy = {}
	for index, item in ipairs(value) do
		copy[index] = CloneValue(item)
	end
	return copy
end

local function CreateDefaultData()
	local data = {}
	for key, value in pairs(defData) do
		data[key] = CloneValue(value)
	end
	return data
end

local function EnsurePlayerData(player)
	local playerID = player.UserId
	if not PlayerData[playerID] then
		PlayerData[playerID] = CreateDefaultData()
	end
	return PlayerData[playerID]
end

function PlayerDataManager.InitializePlayerData(player, data)
	local playerID = player.UserId
	local playerData = CreateDefaultData()

	if type(data) == "table" then
		for key, value in pairs(data) do
			playerData[key] = CloneValue(value)
		end
	end

	PlayerData[playerID] = playerData
	return playerData
end

function PlayerDataManager.ClearPlayerData(player)
	PlayerData[player.UserId] = nil
end

function PlayerDataManager.GetPlayerData(player, key)
	local playerID = player.UserId
	local data = PlayerData[playerID]
	if data then
		if key == nil then
			return data
		end
		return data[key]
	end
	return nil
end

function PlayerDataManager.SetPlayerData(player,key,value)
	local playerID = player.UserId
	if key == nil then
		return false
	end

	local data = EnsurePlayerData(player)
	data[key] = CloneValue(value)

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local statName = key == "money" and "Money" or key
		local stat = leaderstats:FindFirstChild(statName)
		if stat then
			stat.Value = value
		end
	end

	if PlayerDataManager.OnPlayerDataChanged then
		PlayerDataManager.OnPlayerDataChanged:Fire(player, key, data[key])
	end
	return true
end

function PlayerDataManager.AddMoney(player, amount)
	if amount == 0 then return end
	local currentMoney = PlayerDataManager.GetPlayerData(player, "money") or 0
	PlayerDataManager.SetPlayerData(player, "money", currentMoney + amount)
end

-- In PlayerDataManager
function PlayerDataManager.AddItemToInventory(player, itemName)
	local inventory = PlayerDataManager.GetPlayerData(player, "inventory")
	if type(inventory) ~= "table" then
		inventory = {}
	end

	-- Check if item already exists to prevent duplicates
	for _, existingItem in ipairs(inventory) do
		if existingItem == itemName then
			return false
		end
	end

	-- Add item if not already present
	table.insert(inventory, itemName)
	PlayerDataManager.SetPlayerData(player, "inventory", inventory)
	if PlayerDataManager.OnPlayerDataChanged then
		PlayerDataManager.OnPlayerDataChanged:Fire(player, "inventory", inventory)
	end
	return true
end

function PlayerDataManager.EquipItem(player, itemName)
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

PlayerDataManager.OnPlayerDataChanged = Instance.new("BindableEvent")
PlayerDataManager.OnPlayerDataChanged.Name = "PlayerDataChangedEvent"



return PlayerDataManager