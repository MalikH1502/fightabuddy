local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local chest = workspace:WaitForChild("DailyRewards")
local claimPart = chest:WaitForChild("Claim")
local surfaceGui = claimPart:WaitForChild("SurfaceGui")
local claimButton = surfaceGui:WaitForChild("TextButton")
local remote = claimPart:WaitForChild("DailyRewardClaim")
local billboard = chest:WaitForChild("BillboardGui")
local readyLabel = billboard:WaitForChild("Ready")


local READY_COLOR = Color3.fromRGB(67, 191, 82)
local NOT_READY_COLOR = Color3.fromRGB(120, 120, 120)

local canClaim = false
local nextClaimAt = 0
local receivedInit = false

local function formatTime(seconds)
	seconds = math.max(0, seconds)
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = math.floor(seconds % 60)
	return string.format("%02d:%02d:%02d", h, m, s)
end

local function updateUI()
	local now = os.time()
	local timeLeft = nextClaimAt - now
	if not receivedInit then
		readyLabel.Text = "Loading..."
		claimButton.BackgroundColor3 = NOT_READY_COLOR
		canClaim = false
		return
	end
	if timeLeft <= 0 then
		readyLabel.Text = "Ready!"
		claimButton.BackgroundColor3 = READY_COLOR
		canClaim = true
	else
		readyLabel.Text = "Ready in " .. formatTime(timeLeft)
		claimButton.BackgroundColor3 = NOT_READY_COLOR
		canClaim = false
	end
end

remote.OnClientEvent:Connect(function(ready, serverNextClaimAt)
	nextClaimAt = serverNextClaimAt or 0
	receivedInit = true
	updateUI()
end)

claimButton.Text = "Claim"

claimButton.MouseButton1Click:Connect(function()
	if canClaim then
		remote:FireServer() -- treat as claim request
	end
end)

RunService.RenderStepped:Connect(function()
	updateUI()
end)

-- Request state from server after UI is ready
remote:FireServer("requestState")

-- Initialize as loading
updateUI()

-- Money notification handler
