local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")

-- Modules
-- Ensure these exist in the correct spots or the script will wait infinitely
local AntiCheatManager = require(script.Parent:FindFirstChild("AntiCheatManager") or ReplicatedStorage:FindFirstChild("AntiCheatManager")) 
local PlayerDataManager = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PlayerDataManager"))

-- Setup Stats Tables
local knockBackTable = {}
local damageTable = {}
local moneyTable = {}

local gloveList = ReplicatedStorage:WaitForChild("Gloves")

-- Pre-load glove data so we don't have to look it up every punch
for _, glove in pairs(gloveList:GetChildren()) do
	if glove:FindFirstChild("Knockback") then
		knockBackTable[glove.Name] = glove.Knockback.Value
	end
	if glove:FindFirstChild("Damage") then
		damageTable[glove.Name] = glove.Damage.Value
	end
	if glove:FindFirstChild("Moneys") then
		moneyTable[glove.Name] = glove.Moneys.Value
	end
end

-- Events
local damageEvent = ReplicatedStorage:WaitForChild("DamageEvent")
local moneyNotificationEvent = ReplicatedStorage:FindFirstChild("MoneyNotificationEvent")

-- [[ CONSTANTS ]]
local MAX_HIT_DISTANCE = 16 -- Studs (Hitbox size + Lag buffer)
local DEFAULT_DAMAGE = 10
local DEFAULT_KNOCKBACK = 25
local DEFAULT_MONEY = 10

-- =================================================================
-- MAIN COMBAT HANDLER
-- =================================================================
-- =================================================================
-- MAIN COMBAT HANDLER (Updated for LinearVelocity)
-- =================================================================
damageEvent.OnServerEvent:Connect(function(attacker, targetPlayer, _, hitPosition)
	-- 1. VALIDATION
	if not attacker or not targetPlayer then return end
	if attacker == targetPlayer then return end 

	local targetCharacter = targetPlayer.Character
	local attackerCharacter = attacker.Character

	if not targetCharacter or not attackerCharacter then return end

	local targetHumanoid = targetCharacter:FindFirstChild("Humanoid")
	local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
	local attackerRoot = attackerCharacter:FindFirstChild("HumanoidRootPart")

	if not targetHumanoid or targetHumanoid.Health <= 0 or not targetRoot or not attackerRoot then return end

	-- 2. DISTANCE SANITY CHECK
	local distance = (attackerRoot.Position - targetRoot.Position).Magnitude
	if distance > MAX_HIT_DISTANCE then
		warn(attacker.Name .. " hit too far: " .. math.floor(distance))
		return 
	end

	-- 3. GET STATS
	local equippedGlove = PlayerDataManager.GetPlayerData(attacker, "Equipped") or "BasicGloves"
	local damage = damageTable[equippedGlove] or DEFAULT_DAMAGE
	local knockbackPower = knockBackTable[equippedGlove] or DEFAULT_KNOCKBACK
	local moneyReward = moneyTable[equippedGlove] or DEFAULT_MONEY

	-- 4. TAGGING
	if CollectionService:HasTag(attacker, "Last") then
		CollectionService:RemoveTag(attacker, "Last")
	end
	CollectionService:AddTag(attacker, "Last")
	task.delay(5, function()
		if CollectionService:HasTag(attacker, "Last") then CollectionService:RemoveTag(attacker, "Last") end
	end)

	-- 5. REWARDS
	PlayerDataManager.AddMoney(attacker, moneyReward)
	if _G.UpdatePlayerLeaderstats then _G.UpdatePlayerLeaderstats(attacker) end
	if moneyNotificationEvent then moneyNotificationEvent:FireClient(attacker, moneyReward) end

	-- 6. KNOCKBACK PHYSICS (UPDATED to LinearVelocity)
	-- We use LinearVelocity so we don't have to calculate mass.
	local lookVector = CFrame.lookAt(attackerRoot.Position, targetRoot.Position).LookVector

	-- Create a temporary attachment (LinearVelocity needs this to work)
	local attachment = Instance.new("Attachment")
	attachment.Name = "KnockbackAttachment"
	attachment.Parent = targetRoot

	local linearVel = Instance.new("LinearVelocity")
	linearVel.Name = "KnockbackForce"
	linearVel.Attachment0 = attachment
	linearVel.MaxForce = math.huge -- INFINITE FORCE: This makes mass irrelevant
	linearVel.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVel.VectorVelocity = (lookVector * knockbackPower) + Vector3.new(0, 10, 0) -- Add small uplift
	linearVel.Parent = targetRoot

	-- Clean up the physics objects after 0.3 seconds
	Debris:AddItem(attachment, 0.3)
	Debris:AddItem(linearVel, 0.3)

	-- 7. DEAL DAMAGE
	local oldHealth = targetHumanoid.Health
	targetHumanoid:TakeDamage(damage)

	if targetHumanoid.Health <= 0 and oldHealth > 0 then
		if _G.AddKO then _G.AddKO(attacker, 1) end
	end
end)

-- Clean up tags on leave
Players.PlayerRemoving:Connect(function(player)
	if CollectionService:HasTag(player, "Last") then
		CollectionService:RemoveTag(player, "Last")
	end
end)