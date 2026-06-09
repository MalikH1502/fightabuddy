local Abilities = {}
local cooldowns = {}
local debounces = {}
local module = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("PlayerDataManager"))
local tweenServ = game:GetService("TweenService")
local Storage = game.ReplicatedStorage.Resources
local cooldownEvent = game.ReplicatedStorage.coolDownEvent


function Abilities.UseAbility(player)
	local playerInZone = false
	for _, zonePlayer in pairs(_G.PlayersInZone) do
		if zonePlayer == player then
			playerInZone = true
			break
		end
	end

	if not playerInZone then
		return
	end

	local equipped = module.GetPlayerData(player, "Equipped")

	if not equipped or equipped == "" then
		equipped = "BrickGloves"
	end

	local func = Abilities[equipped]
	if func then
		func(player)
	end
end



function Abilities.VoidGloves(player)
	local userId = player.UserId

	if not cooldowns[userId] then cooldowns[userId] = 0 end
	if not debounces[userId] then debounces[userId] = false end

	local cooldown = 12
	local pushRadius = 75 -- studs
	local pushForce = 1000 -- adjust as needed

	if time() - cooldowns[userId] >= cooldown and not debounces[userId] then
		debounces[userId] = true
		cooldowns[userId] = time()
		cooldownEvent:FireClient(player, "VoidGloves", cooldown)

		local character = player.Character
		if not character or not character:FindFirstChild("HumanoidRootPart") then
			debounces[userId] = false
			return
		end
		local origin = character.HumanoidRootPart.Position

		for _, otherPlayer in ipairs(game.Players:GetPlayers()) do
			if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") and otherPlayer.Character:FindFirstChild("Humanoid") and otherPlayer.Character.Humanoid.Health > 0 then
				local otherHRP = otherPlayer.Character.HumanoidRootPart
				local humanoid = otherPlayer.Character.Humanoid
				local distance = (otherHRP.Position - origin).Magnitude
				if distance <= pushRadius then
					-- Knockback direction: outward from the player
					local direction = (otherHRP.Position - origin).Unit

					-- Optional: scale push based on size
					local massFactor = 1
					if humanoid:FindFirstChild("BodyDepthScale") and humanoid:FindFirstChild("BodyHeightScale") and humanoid:FindFirstChild("BodyWidthScale") then
						massFactor = humanoid.BodyDepthScale.Value * humanoid.BodyHeightScale.Value * humanoid.BodyWidthScale.Value
					end
					local adjustedSpeed = pushForce / massFactor

					local knockBackForce = Instance.new("BodyVelocity")
					knockBackForce.MaxForce = Vector3.new(1,1,1) * 1e5 -- ensure enough force
					knockBackForce.Velocity = (direction + Vector3.new(0,0.2,0)).Unit * adjustedSpeed
					knockBackForce.Parent = otherHRP
					game:GetService("Debris"):AddItem(knockBackForce, 0.3)
				end
			end
		end

		task.delay(0.5, function()
			debounces[userId] = false
		end)
	end
end

function Abilities.MudGloves(player)
	local userId = player.UserId

	if not cooldowns[userId] then cooldowns[userId] = 0 end
	if not debounces[userId] then debounces[userId] = false end

	local cooldown = 10

	if time() - cooldowns[userId] >= cooldown and not debounces[userId] then
		debounces[userId] = true
		cooldowns[userId] = time()
		cooldownEvent:FireClient(player, "MudGloves", cooldown)

		if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
			debounces[userId] = false
			return
		end

		local mudSpot = Storage.MudPart:Clone()

		mudSpot.Anchored = true
		mudSpot.CanCollide = false
		mudSpot.Parent = workspace
		mudSpot.Name = player.Name .. "_MudSpot"
		mudSpot.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, -3.2, 0)
		mudSpot.Orientation = Vector3.new(0,0,90)



		game.Debris:AddItem(mudSpot, 6)
		debounces[userId] = false
	end
end

function Abilities.SpeedGloves(player)
	local userId = player.UserId

	if not cooldowns[userId] then cooldowns[userId] = 0 end
	if not debounces[userId] then debounces[userId] = false end

	local cooldown = 14

	if time() - cooldowns[userId] >= cooldown and not debounces[userId] then
		debounces[userId] = true
		cooldowns[userId] = time()
		cooldownEvent:FireClient(player, "SpeedGloves", cooldown)

		if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
			debounces[userId] = false
			return
		end

		local char = player.Character
		char:FindFirstChild("Humanoid").WalkSpeed = 32
		task.wait(7)
		char:FindFirstChild("Humanoid").WalkSpeed = 16
		debounces[userId] = false
	end
end

function Abilities.DashGloves(player)
	local userId = player.UserId

	if not cooldowns[userId] then cooldowns[userId] = 0 end
	if not debounces[userId] then debounces[userId] = false end

	local cooldown = 5

	if time() - cooldowns[userId] >= cooldown and not debounces[userId] then
		debounces[userId] = true
		cooldowns[userId] = time()
		cooldownEvent:FireClient(player, "DashGloves", cooldown)

		local character = player.Character
		if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Humanoid") then
			debounces[userId] = false
			return
		end

		local hrp = character.HumanoidRootPart

		-- DASH: Move 6 studs forward
		local dashDistance = 22
		local forward = hrp.CFrame.LookVector
		local dashPosition = hrp.Position + (forward * dashDistance)

		-- Optional: Raycast for obstacles here

		-- TRAIL: Create a white trail during the dash
		-- Create attachments for the trail ends
		local attachment0 = Instance.new("Attachment")
		local attachment1 = Instance.new("Attachment")
		attachment0.Name = "DashTrailStart"
		attachment1.Name = "DashTrailEnd"
		attachment0.Parent = hrp
		attachment1.Parent = hrp
		-- Offset them for a visible trail length
		attachment0.Position = Vector3.new(0, 1, 0)
		attachment1.Position = Vector3.new(0, -1, 0)

		local trail = Instance.new("Trail")
		trail.Attachment0 = attachment0
		trail.Attachment1 = attachment1
		trail.Color = ColorSequence.new(Color3.new(1,1,1))
		trail.Lifetime = 0.3 -- seconds trail remains visible
		trail.MinLength = 0.1
		trail.LightEmission = 1
		trail.Parent = hrp

		-- Move the character instantly
		hrp.CFrame = CFrame.new(dashPosition, dashPosition + hrp.CFrame.LookVector)

		-- Remove trail after short duration
		task.delay(0.4, function()
			if trail then trail:Destroy() end
			if attachment0 then attachment0:Destroy() end
			if attachment1 then attachment1:Destroy() end
		end)

		-- Debounce reset after a short delay
		task.delay(0.5, function()
			debounces[userId] = false
		end)
	end
end


function Abilities.JumpGloves(player)
	local userId = player.UserId

	if not cooldowns[userId] then cooldowns[userId] = 0 end
	if not debounces[userId] then debounces[userId] = false end

	local cooldown = 6

	if time() - cooldowns[userId] >= cooldown and not debounces[userId] then
		debounces[userId] = true
		cooldowns[userId] = time()
		cooldownEvent:FireClient(player, "BrickGloves", cooldown)

		if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
			debounces[userId] = false
			return
		end

		local char = player.Character
		local temp = char.Humanoid.JumpPower
		char.Humanoid.JumpPower = 300
		task.delay(5, function()
			char.Humanoid.JumpPower = temp
		end)
		
		debounces[userId] = false
	end
end

function Abilities.BrickGloves(player)
	local userId = player.UserId

	if not cooldowns[userId] then cooldowns[userId] = 0 end
	if not debounces[userId] then debounces[userId] = false end

	local cooldown = 6

	if time() - cooldowns[userId] >= cooldown and not debounces[userId] then
		debounces[userId] = true
		cooldowns[userId] = time()
		cooldownEvent:FireClient(player, "BrickGloves", cooldown)

		if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
			debounces[userId] = false
			return
		end

		local wall = Instance.new("Part")
		wall.Size = Vector3.new(11.5, 7.5, 0.5)
		wall.Material = Enum.Material.Brick
		wall.Color = Color3.fromRGB(150, 85, 85)
		wall.Anchored = true
		wall.CanCollide = true
		wall.Parent = workspace
		wall.Name = player.Name .. "_BrickWall"
		wall.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, -8, -6)
		local goal = {}
		goal.CFrame = wall.CFrame * CFrame.new(0, 8, 0)

		local TweenInf = TweenInfo.new(
			.25,
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.In,
			0,
			false,
			0

		)
		local tween = tweenServ:Create(wall,TweenInf,goal)
		local sound = Instance.new("Sound")
		sound.SoundId = 120929237265578
	
		sound:Play()
		tween:Play()
		game.Debris:addItem(sound, 3)
		game.Debris:AddItem(wall, 3)
		debounces[userId] = false
	end
end

function Abilities.BoulderGloves(player)
	local userId = player.UserId

	if not cooldowns[userId] then cooldowns[userId] = 0 end
	if not debounces[userId] then debounces[userId] = false end

	local cooldown = 8 -- adjust cooldown as needed

	if time() - cooldowns[userId] >= cooldown and not debounces[userId] then
		debounces[userId] = true
		cooldowns[userId] = time()
		cooldownEvent:FireClient(player, "Boulder", cooldown)

		local character = player.Character
		if not character or not character:FindFirstChild("HumanoidRootPart") then
			debounces[userId] = false
			return
		end

		local hrp = character.HumanoidRootPart
		local boulderTemplate = Storage:FindFirstChild("Boulder")
		if not boulderTemplate then
			warn("Boulder template not found in storage")
			debounces[userId] = false
			return
		end

		local boulder = boulderTemplate:Clone()
		boulder.Name = player.Name .. "_Boulder"
		boulder.Parent = workspace
		boulder.CanCollide = true
		boulder.Anchored = false

		-- Position boulder a little in front of HRP
		local spawnOffset = hrp.CFrame.LookVector * 5 + Vector3.new(0, 2, 0)
		boulder.CFrame = hrp.CFrame + spawnOffset
		boulder.Parent = workspace

		-- Give the boulder velocity in the facing direction
		local direction = hrp.CFrame.LookVector.Unit
		local force = 100 -- Adjust this value for speed
		if boulder:IsA("BasePart") then
			boulder.Velocity = direction * force + Vector3.new(0, 15, 0) -- Some upward arc
		elseif boulder:FindFirstChildWhichIsA("BasePart") then
			-- If boulder is a model, set primary part velocity
			local mainPart = boulder.PrimaryPart or boulder:FindFirstChildWhichIsA("BasePart")
			mainPart.Velocity = direction * force + Vector3.new(0, 15, 0)
		end

		-- Optional: clean up after a few seconds
		game:GetService("Debris"):AddItem(boulder, 4)

		task.delay(0.5, function()
			debounces[userId] = false
		end)
	end
end

Abilities.BrickGlove = Abilities.BrickGloves
Abilities.VoidGlove = Abilities.VoidGloves


game.Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId
	cooldowns[userId] = nil
	debounces[userId] = nil
end)

return Abilities