local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MessagingService = game:GetService("MessagingService")

local AntiCheatConfig = require(ReplicatedStorage.AntiCheatConfig)

local AntiCheatManager = {}

-- Player tracking data
local playerData = {}
local suspiciousPlayers = {}

-- Initialize player data
local function initializePlayerData(player)
	playerData[player.UserId] = {
		lastPunchTime = 0,
		punchCount = 0,
		violations = 0,
		warnings = 0,
		totalViolations = 0,
		recentPunches = {},
		lastPosition = nil,
		isAnimating = false,
		animationStartTime = 0
	}
end

-- Clean up player data
local function cleanupPlayerData(player)
	playerData[player.UserId] = nil
	suspiciousPlayers[player.UserId] = nil
end

-- Log violation
local function logViolation(player, violationType, details)
	if not AntiCheatConfig.LOG_VIOLATIONS then return end

	local timestamp = os.date("%Y-%m-%d %H:%M:%S")
	local logMessage = string.format(
		"[ANTICHEAT] %s | Player: %s (ID: %d) | Violation: %s | Details: %s",
		timestamp, player.Name, player.UserId, violationType, details
	)

	print(logMessage)

	-- You can extend this to write to a datastore or external logging service
end

-- Add violation to player record
function AntiCheatManager.AddViolation(player, violationType, details)
	local data = playerData[player.UserId]
	if not data then return end

	data.violations = data.violations + 1
	data.totalViolations = data.totalViolations + 1

	logViolation(player, violationType, details)

	-- Check for punishment thresholds
	if data.violations >= AntiCheatConfig.KICK_THRESHOLD then
		AntiCheatManager.KickPlayer(player, "Anti-cheat violation: " .. violationType)
	elseif data.violations >= AntiCheatConfig.WARNING_THRESHOLD then
		data.warnings = data.warnings + 1
		AntiCheatManager.WarnPlayer(player, violationType)
	end

	-- Reset violation counter periodically
	task.delay(60, function()
		if data then
			data.violations = math.max(0, data.violations - 1)
		end
	end)
end

-- Warn player
function AntiCheatManager.WarnPlayer(player, reason)
	-- You can implement a GUI warning system here
	print("WARNING issued to " .. player.Name .. " for: " .. reason)
end

-- Kick player
function AntiCheatManager.KickPlayer(player, reason)
	logViolation(player, "KICKED", reason)
	player:Kick(reason)
end

-- Validate punch timing
function AntiCheatManager.ValidatePunchTiming(player)
	local data = playerData[player.UserId]
	if not data then return false end

	local currentTime = tick()
	local timeSinceLastPunch = currentTime - data.lastPunchTime

	-- Check cooldown
	if timeSinceLastPunch < AntiCheatConfig.PUNCH_COOLDOWN then
		AntiCheatManager.AddViolation(player, "PUNCH_COOLDOWN", 
			string.format("Punch too soon: %.2fs (min: %.2fs)", timeSinceLastPunch, AntiCheatConfig.PUNCH_COOLDOWN))
		return false
	end

	-- Check for rapid fire
	table.insert(data.recentPunches, currentTime)

	-- Remove old punches outside the window
	for i = #data.recentPunches, 1, -1 do
		if currentTime - data.recentPunches[i] > AntiCheatConfig.BURST_WINDOW then
			table.remove(data.recentPunches, i)
		end
	end

	-- Check punch rate
	if #data.recentPunches > AntiCheatConfig.MAX_PUNCHES_PER_SECOND * AntiCheatConfig.BURST_WINDOW then
		AntiCheatManager.AddViolation(player, "RAPID_FIRE", 
			string.format("Too many punches: %d in %ds", #data.recentPunches, AntiCheatConfig.BURST_WINDOW))
		return false
	end

	data.lastPunchTime = currentTime
	return true
end

-- Validate punch distance
function AntiCheatManager.ValidateDistance(attacker, target, maxDistance)
	if not attacker.Character or not target.Character then return false end

	local attackerRoot = attacker.Character:FindFirstChild("HumanoidRootPart")
	local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")

	if not attackerRoot or not targetRoot then return false end

	local distance = (attackerRoot.Position - targetRoot.Position).Magnitude

	if distance > maxDistance then
		AntiCheatManager.AddViolation(attacker, "DISTANCE_CHEAT", 
			string.format("Distance too far: %.2f (max: %.2f)", distance, maxDistance))
		return false
	end

	return true, distance
end

-- Validate damage values
function AntiCheatManager.ValidateDamage(player, damage, expectedDamage)
	if damage ~= expectedDamage then
		AntiCheatManager.AddViolation(player, "DAMAGE_MANIPULATION", 
			string.format("Invalid damage: %d (expected: %d)", damage, expectedDamage))
		return false
	end

	if damage < AntiCheatConfig.MIN_DAMAGE or damage > AntiCheatConfig.MAX_DAMAGE then
		AntiCheatManager.AddViolation(player, "DAMAGE_OUT_OF_RANGE", 
			string.format("Damage out of range: %d", damage))
		return false
	end

	return true
end

-- Validate player state
function AntiCheatManager.ValidatePlayerState(player)
	if not player.Character then return false end

	local humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid then return false end

	-- Check if player is alive
	if humanoid.Health <= 0 then
		AntiCheatManager.AddViolation(player, "DEAD_PLAYER_ATTACK", "Attacking while dead")
		return false
	end

	-- Check if player is seated (optional)
	if humanoid.Sit then
		AntiCheatManager.AddViolation(player, "SEATED_ATTACK", "Attacking while seated")
		return false
	end

	return true
end

-- Raycast validation for line of sight
function AntiCheatManager.ValidateLineOfSight(attacker, target)
	if not attacker.Character or not target.Character then return false end

	local attackerRoot = attacker.Character:FindFirstChild("HumanoidRootPart")
	local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")

	if not attackerRoot or not targetRoot then return false end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = {attacker.Character, target.Character}

	local raycastResult = workspace:Raycast(attackerRoot.Position, 
		(targetRoot.Position - attackerRoot.Position).Unit * AntiCheatConfig.MAX_PUNCH_DISTANCE, raycastParams)

	if raycastResult then
		AntiCheatManager.AddViolation(attacker, "NO_LINE_OF_SIGHT", "Obstacle between attacker and target")
		return false
	end

	return true
end

-- Main validation function
function AntiCheatManager.ValidateDamageRequest(attacker, target, damage, hitPosition, requestedMoney, requestedKnockback)
	-- Basic existence checks
	if not attacker or not target then return false end
	if attacker == target then return false end -- Prevent self-damage

	-- Initialize data if needed
	if not playerData[attacker.UserId] then
		initializePlayerData(attacker)
	end

	-- Validate player state
	if not AntiCheatManager.ValidatePlayerState(attacker) then return false end

	-- Validate timing
	if not AntiCheatManager.ValidatePunchTiming(attacker) then return false end

	-- Validate distance
	local isValidDistance, distance = AntiCheatManager.ValidateDistance(attacker, target, AntiCheatConfig.MAX_PUNCH_DISTANCE)
	if not isValidDistance then return false end

	-- Validate line of sight (optional, may cause issues with legitimate gameplay)
	-- if not AntiCheatManager.ValidateLineOfSight(attacker, target) then return false end

	return true
end

-- Event connections
Players.PlayerAdded:Connect(initializePlayerData)
Players.PlayerRemoving:Connect(cleanupPlayerData)

return AntiCheatManager