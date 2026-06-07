local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local dailyRewardStore = DataStoreService:GetDataStore("DailyRewardDataStore")
local module = require(ReplicatedStorage:WaitForChild("PlayerDataManager"))

local REWARD_INTERVAL = 24 * 60 * 60 -- 24 hours in seconds
local DAILY_REWARD_AMOUNT = 100 -- Amount given as daily reward

local chest = workspace:WaitForChild("DailyRewards")
local claimPart = chest:WaitForChild("Claim")
local remote = claimPart:FindFirstChild("DailyRewardClaim") or Instance.new("RemoteEvent")
remote.Name = "DailyRewardClaim"
remote.Parent = claimPart

local moneyNotificationEvent = ReplicatedStorage:FindFirstChild("MoneyNotificationEvent")

-- Utility function to check if player can claim
local function canClaim(lastClaim)
	if not lastClaim then return true end
	local now = os.time()
	return (now - lastClaim) >= REWARD_INTERVAL
end

-- Send state to client
local function sendState(player)
	local key = "LastClaim_" .. player.UserId
	local lastClaim = dailyRewardStore:GetAsync(key)
	local now = os.time()
	local ready = canClaim(lastClaim)
	local nextClaimAt = (lastClaim or 0) + REWARD_INTERVAL
	if not lastClaim then nextClaimAt = now end
	remote:FireClient(player, ready, nextClaimAt)
end

-- Handle claim requests and manual state requests from client
remote.OnServerEvent:Connect(function(player, action)
	local key = "LastClaim_" .. player.UserId
	local lastClaim = dailyRewardStore:GetAsync(key)
	local now = os.time()
	if action == "requestState" then
		sendState(player)
	else
		-- Default: treat as claim request
		if canClaim(lastClaim) then
			dailyRewardStore:SetAsync(key, now)
			module.AddMoney(player, DAILY_REWARD_AMOUNT)
			if _G.UpdatePlayerLeaderstats then
				_G.UpdatePlayerLeaderstats(player)
			end
			if moneyNotificationEvent then
				moneyNotificationEvent:FireClient(player, DAILY_REWARD_AMOUNT)
			end
		end
		sendState(player)
	end
end)

-- Optional: send state when player joins (for automatic UI update)
Players.PlayerAdded:Connect(function(player)
	sendState(player)
end)