-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- Configs and Remotes
local GloveConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GloveConfig"))
local GetEquippedGlove = ReplicatedStorage:WaitForChild("GetEquippedGlove")
local ZoneEvent = ReplicatedStorage:WaitForChild("ZoneEvent")
local damageEvent = ReplicatedStorage:WaitForChild("DamageEvent")
local abilityEvent = ReplicatedStorage:WaitForChild("AbilityEvent")
local punchsounds = ReplicatedStorage.Sounds.Punches
local HIT_EFFECT_TEMPLATE = ReplicatedStorage.Resources["Meshes/newWave"]
local AntiCheatConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AntiCheatConfig"))

-- Player Setup
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- State Variables
local isInZone = false
local isAttacking = false
local lastPunchTime = 0
local loadedAnimations = {} 

-- Hitbox Config
local HITBOX_SIZE = Vector3.new(5, 6, 5)
local HITBOX_OFFSET = CFrame.new(0, 0, -3)

-- Animation IDs
local ANIMATION_IDS = {
	"rbxassetid://122247074143444",
	"rbxassetid://104324657890074",
	"rbxassetid://90096644211800",
	"rbxassetid://74659629152773"
}

--================--
-- HELPER FUNCTIONS --
--================--

local function preloadAnimations()
	if not animator then return end
	for _, animId in ipairs(ANIMATION_IDS) do
		local anim = Instance.new("Animation")
		anim.AnimationId = animId
		loadedAnimations[animId] = animator:LoadAnimation(anim)
	end
end

local function setupTrailForHand(hand)
	if not hand or hand:FindFirstChild("GloveTrail") then return end
	local attachment0 = Instance.new("Attachment", hand)
	attachment0.Position = Vector3.new(0, -0.75, 0)
	local attachment1 = Instance.new("Attachment", hand)
	attachment1.Position = Vector3.new(0, 0.75, 0)

	local trail = Instance.new("Trail", hand)
	trail.Name = "GloveTrail"
	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1
	trail.Lifetime = 0.12
	trail.Enabled = false
end

local function setupCharacter(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	animator = humanoid:WaitForChild("Animator")
	rootPart = char:WaitForChild("HumanoidRootPart")
	loadedAnimations = {}
	task.spawn(preloadAnimations)

	setupTrailForHand(char:WaitForChild("RightHand", 5) or char:WaitForChild("Right Arm", 5))
	setupTrailForHand(char:WaitForChild("LeftHand", 5) or char:WaitForChild("Left Arm", 5))
end

local function toggleTrails(enabled)
	local gloveName = GetEquippedGlove:InvokeServer() or "BasicGloves"
	local config = GloveConfig[gloveName] or GloveConfig.BasicGloves

	for _, name in ipairs({"RightHand", "LeftHand", "Right Arm", "Left Arm"}) do
		local hand = character:FindFirstChild(name)
		local trail = hand and hand:FindFirstChild("GloveTrail")
		if trail then
			trail.Enabled = enabled
			if enabled then
				trail.Color = config.TrailColor or ColorSequence.new(Color3.new(1,1,1))
			end
		end
	end
end

--================--
-- COMBAT LOGIC --
--================--

local function performHitboxCheck()
	local hitboxCFrame = rootPart.CFrame * HITBOX_OFFSET
	local overlapParams = OverlapParams.new()
	overlapParams.FilterDescendantsInstances = {character}
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude

	local parts = workspace:GetPartBoundsInBox(hitboxCFrame, HITBOX_SIZE, overlapParams)
	local targetFound = nil

	for _, part in ipairs(parts) do
		local model = part:FindFirstAncestorOfClass("Model")
		local targetHum = model and model:FindFirstChild("Humanoid")
		local targetRoot = model and model:FindFirstChild("HumanoidRootPart")

		if targetHum and targetRoot and targetHum.Health > 0 then
			targetFound = model

			-- Fire Server
			damageEvent:FireServer(Players:GetPlayerFromCharacter(model), nil, targetRoot.Position)

			-- 2. HIT EFFECT PARALLEL TO ENEMY LOOKVECTOR
			local impact = HIT_EFFECT_TEMPLATE:Clone()
			-- We use the target's Rotation but keep the position at their root
			impact.CFrame = targetRoot.CFrame 
			impact.Parent = workspace
			Debris:AddItem(impact, 0.3)

			break 
		end
	end

	if targetFound then
		local sounds = punchsounds:GetChildren()
		local s = sounds[math.random(#sounds)]:Clone()
		s.Parent = rootPart
		s:Play()
		Debris:AddItem(s, 1)
	end
end

local function playPunchAnimation()
	-- 1. FIX: Stuck Bug Prevention
	-- Added verification that character and animator actually exist
	if not character or not humanoid or not animator then return end
	if isAttacking or (tick() - lastPunchTime) < AntiCheatConfig.PUNCH_COOLDOWN or not isInZone then return end

	isAttacking = true
	lastPunchTime = tick()
	local hasHit = false 

	toggleTrails(true)

	local animId = ANIMATION_IDS[math.random(#ANIMATION_IDS)]
	local track = loadedAnimations[animId]

	if not track then
		-- Fallback if preloading failed for some reason
		local anim = Instance.new("Animation")
		anim.AnimationId = animId
		track = animator:LoadAnimation(anim)
	end

	track:Play()

	-- Primary Hit (Animation Marker)
	local hitConn
	hitConn = track:GetMarkerReachedSignal("Hit"):Connect(function()
		if not hasHit then
			hasHit = true
			performHitboxCheck()
		end
	end)

	-- Secondary Hit (Timer Fallback)
	task.delay(0.18, function()
		if not hasHit and isAttacking then
			hasHit = true
			performHitboxCheck()
		end
	end)

	-- FIX: EMERGENCY RESET
	-- If the animation hangs or fails to call "Stopped", this forces the player back to idle state
	task.delay(0.8, function()
		if isAttacking then
			isAttacking = false
			toggleTrails(false)
			if hitConn then hitConn:Disconnect() end
		end
	end)

	track.Stopped:Connect(function()
		isAttacking = false
		toggleTrails(false)
		if hitConn then hitConn:Disconnect() end
	end)
end

--================--
-- INPUTS & EVENTS --
--================--

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		playPunchAnimation()
	elseif input.KeyCode == Enum.KeyCode.Q and isInZone then
		abilityEvent:FireServer()
	end
end)

ZoneEvent.OnClientEvent:Connect(function(inZone) isInZone = inZone end)
player.CharacterAdded:Connect(setupCharacter)
if player.Character then setupCharacter(player.Character) end