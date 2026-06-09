local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- CONFIGURABLE SETTINGS
local COIN_LIMIT = 6
local COIN_SPAWN_INTERVAL = 10 -- seconds between spawns
local COIN_MONEY_AMOUNT = 20

-- SERVICES & FOLDERS
local coinsFolder = ReplicatedStorage:WaitForChild("Coins")
local workspaceCoins = workspace:FindFirstChild("Coins") or Instance.new("Folder", workspace)
workspaceCoins.Name = "Coins"

local PlayerDataManager = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PlayerDataManager"))
local MoneyNotificationEvent = ReplicatedStorage:WaitForChild("MoneyNotificationEvent")

-- Helper: Animation for coin collect
local function spinAndFade(coin)
	local spinGoal = {Orientation = coin.Orientation + Vector3.new(0, 720, 0)}
	local fadeGoal = {Transparency = 1}
	local spinTween = TweenService:Create(coin, TweenInfo.new(0.75, Enum.EasingStyle.Linear), spinGoal)
	local fadeTween = TweenService:Create(coin, TweenInfo.new(0.75, Enum.EasingStyle.Quad), fadeGoal)
	spinTween:Play()
	fadeTween:Play()
	fadeTween.Completed:Wait()
	coin:Destroy()
end

-- Debounce table to prevent duplicate credit per coin per player
local collectedDebounce = {}

-- Touch logic for coins
local function onCoinTouched(coin, hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then return end

	collectedDebounce[coin] = collectedDebounce[coin] or {}
	local userId = player.UserId
	if collectedDebounce[coin][userId] then return end -- Prevent double collect
	collectedDebounce[coin][userId] = true

	coin.CanTouch = false -- Prevent further touches during animation

	-- Give money, notify, update stats
	PlayerDataManager.AddMoney(player, COIN_MONEY_AMOUNT)
	MoneyNotificationEvent:FireClient(player, COIN_MONEY_AMOUNT)
	if _G.UpdatePlayerLeaderstats then
		_G.UpdatePlayerLeaderstats(player)
	end

	spinAndFade(coin)
	collectedDebounce[coin] = nil -- Clean up debounce for destroyed coin
end

-- Setup a coin to be collectible
local function setupCoin(coin)
	if coin:IsA("BasePart") then
		coin.Touched:Connect(function(hit)
			onCoinTouched(coin, hit)
		end)
		coin.Transparency = 0
		coin.CanTouch = true
		coin:SetAttribute("Collected", false)
	end
end

-- Initial spawn: random coins, no duplicates, up to COIN_LIMIT
local templateCoins = coinsFolder:GetChildren()
local availableIndexes = {}
for i = 1, #templateCoins do
	table.insert(availableIndexes, i)
end
for i = 1, math.min(COIN_LIMIT, #templateCoins) do
	local rand = math.random(1, #availableIndexes)
	local index = table.remove(availableIndexes, rand)
	local templateCoin = templateCoins[index]
	local coinClone = templateCoin:Clone()
	coinClone.Parent = workspaceCoins
	coinClone.CFrame = templateCoin.CFrame
	setupCoin(coinClone)
end

-- Listen for coins manually added elsewhere (optional)
workspaceCoins.ChildAdded:Connect(setupCoin)

-- Coin respawn loop
while true do
	wait(COIN_SPAWN_INTERVAL)
	local currentCoins = workspaceCoins:GetChildren()
	if #currentCoins < COIN_LIMIT then
		-- Avoid duplicates if possible
		local presentNames = {}
		for _, coin in ipairs(currentCoins) do
			presentNames[coin.Name] = true
		end

		local coinsToSpawn = {}
		for _, templateCoin in ipairs(coinsFolder:GetChildren()) do
			if not presentNames[templateCoin.Name] then
				table.insert(coinsToSpawn, templateCoin)
			end
		end

		local coinToClone
		if #coinsToSpawn > 0 then
			coinToClone = coinsToSpawn[math.random(1, #coinsToSpawn)]
		else
			coinToClone = templateCoins[math.random(1, #templateCoins)]
		end

		local clone = coinToClone:Clone()
		clone.Parent = workspaceCoins
		clone.CFrame = coinToClone.CFrame
		setupCoin(clone)
	end
end