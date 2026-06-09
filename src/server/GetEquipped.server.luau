-- Place this in ServerScriptService. Make sure "GetEquippedGlove" RemoteFunction exists in ReplicatedStorage!

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerDataManager = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PlayerDataManager"))

local remote = ReplicatedStorage:FindFirstChild("GetEquippedGlove")
if not remote then
	remote = Instance.new("RemoteFunction")
	remote.Name = "GetEquippedGlove"
	remote.Parent = ReplicatedStorage
end

remote.OnServerInvoke = function(player)
	local equipped = PlayerDataManager.GetPlayerData(player, "Equipped")
	return equipped or "BasicGloves" -- fallback to BasicGloves if not set
end