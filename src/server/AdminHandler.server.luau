local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AdminSystem = {}

-- Admin Configuration
local ADMINS = {
	["PizzOffWithUnholy"] = true,
	["luvvabagz"] = true,
	["IncorpGroupHolder"] = true,
	["Player1"] = true	-- Add more admins here: ["Username"] = true,
}

local PREFIX = ":" -- Command prefix

-- Storage for commands
AdminSystem.Commands = {}

-- Function to check if player is admin
function AdminSystem:IsAdmin(player)
	return ADMINS[player.Name] == true
end

-- Function to register a new command
function AdminSystem:RegisterCommand(name, aliases, description, minArgs, func)
	local command = {
		Name = name,
		Aliases = aliases or {},
		Description = description,
		MinArgs = minArgs or 0,
		Function = func
	}

	self.Commands[name:lower()] = command

	-- Register aliases
	for _, alias in pairs(aliases or {}) do
		self.Commands[alias:lower()] = command
	end
end

-- Function to parse command arguments
function AdminSystem:ParseArguments(message)
	local args = {}
	for arg in message:gmatch("%S+") do
		table.insert(args, arg)
	end
	return args
end

-- Function to find players by partial name

-- Function to find players by partial name
function AdminSystem:FindPlayer(name, currentPlayer)
	if name:lower() == "me" then
		return currentPlayer and {currentPlayer} or {}
	elseif name:lower() == "all" then
		return Players:GetPlayers()
	elseif name:lower() == "others" then
		local players = {}
		for _, player in pairs(Players:GetPlayers()) do
			if not currentPlayer or player ~= currentPlayer then
				table.insert(players, player)
			end
		end
		return players
	else
		local found = {}
		for _, player in pairs(Players:GetPlayers()) do
			if player.Name:lower():find(name:lower(), 1, true) or player.DisplayName:lower():find(name:lower(), 1, true) then
				table.insert(found, player)
			end
		end
		return found
	end
end

-- Function to send message to admin
function AdminSystem:SendMessage(player, message, color)
	if not self:IsAdmin(player) then return end

	local gui = player.PlayerGui:FindFirstChild("AdminGUI")
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "AdminGUI"
		gui.Parent = player.PlayerGui
		gui.ResetOnSpawn = false
	end

	local frame = gui:FindFirstChild("MessageFrame")
	if not frame then
		frame = Instance.new("Frame")
		frame.Name = "MessageFrame"
		frame.Size = UDim2.new(0, 400, 0, 200)
		frame.Position = UDim2.new(0, 10, 0, 10)
		frame.BackgroundTransparency = 1
		frame.Parent = gui

		local list = Instance.new("UIListLayout")
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.VerticalAlignment = Enum.VerticalAlignment.Bottom
		list.Parent = frame
	end

	local msgLabel = Instance.new("TextLabel")
	msgLabel.Size = UDim2.new(1, 0, 0, 20)
	msgLabel.BackgroundColor3 = Color3.new(0, 0, 0)
	msgLabel.BackgroundTransparency = 0.3
	msgLabel.BorderSizePixel = 0
	msgLabel.Text = message
	msgLabel.TextColor3 = color or Color3.new(1, 1, 1)
	msgLabel.TextScaled = true
	msgLabel.Font = Enum.Font.SourceSans
	msgLabel.Parent = frame

	-- Auto remove message after 5 seconds
	game:GetService("Debris"):AddItem(msgLabel, 5)

	-- Remove old messages if too many
	local children = frame:GetChildren()
	local textLabels = {}
	for _, child in pairs(children) do
		if child:IsA("TextLabel") then
			table.insert(textLabels, child)
		end
	end

	if #textLabels > 10 then
		for i = 1, #textLabels - 10 do
			textLabels[i]:Destroy()
		end
	end
end

-- Function to execute command
function AdminSystem:ExecuteCommand(player, message)
	if not self:IsAdmin(player) then
		return
	end

	if not message:sub(1, 1) == PREFIX then
		return
	end

	local args = self:ParseArguments(message:sub(2)) -- Remove prefix
	if #args == 0 then return end

	local commandName = args[1]:lower()
	local command = self.Commands[commandName]

	if not command then
		self:SendMessage(player, "Command not found: " .. commandName, Color3.new(1, 0, 0))
		return
	end

	if #args - 1 < command.MinArgs then
		self:SendMessage(player, "Not enough arguments. Usage: " .. PREFIX .. command.Name, Color3.new(1, 0, 0))
		return
	end

	-- Remove command name from args
	table.remove(args, 1)

	local success, error = pcall(function()
		command.Function(player, args, self)
	end)

	if not success then
		self:SendMessage(player, "Error executing command: " .. tostring(error), Color3.new(1, 0, 0))
		warn("Admin command error:", error)
	end
end

-- REGISTER ALL COMMANDS
-- Add this to your AdminSystem
AdminSystem:RegisterCommand("cleaninventory", {"cleaninv"}, "Remove duplicate items from inventory", 1, function(player, args, adminSystem)
	local success, PlayerDataManager = pcall(function()
		return require(game.ReplicatedStorage.PlayerDataManager)
	end)

	if not success then
		adminSystem:SendMessage(player, "PlayerDataManager not found", Color3.new(1, 0, 0))
		return
	end

	local targets = adminSystem:FindPlayer(args[1], player)

	if #targets == 0 then
		adminSystem:SendMessage(player, "Player not found: " .. args[1], Color3.new(1, 0, 0))
		return
	end

	for _, target in pairs(targets) do
		if target then
			local inventory = PlayerDataManager.GetPlayerData(target, "inventory") or {}
			local cleanInventory = {}
			local seen = {}

			-- Remove duplicates
			for i, item in pairs(inventory) do
				if not seen[item] then
					table.insert(cleanInventory, item)
					seen[item] = true
				end
			end

			-- Update inventory
			PlayerDataManager.SetPlayerData(target, "inventory", cleanInventory)

			adminSystem:SendMessage(player, "Cleaned inventory for " .. target.Name .. ". Removed " .. (#inventory - #cleanInventory) .. " duplicates", Color3.new(0, 1, 0))
		end
	end
end)
-- Help Command
AdminSystem:RegisterCommand("help", {"commands", "cmds"}, "List all commands", 0, function(player, args, adminSystem)
	local message = "Available commands:\n"
	for name, command in pairs(adminSystem.Commands) do
		if command.Name == name then -- Only show main command names, not aliases
			message = message .. PREFIX .. command.Name .. " - " .. command.Description .. "\n"
		end
	end
	adminSystem:SendMessage(player, message, Color3.new(0, 1, 0))
end)

-- Ping Command
AdminSystem:RegisterCommand("ping", {}, "Test command", 0, function(player, args, adminSystem)
	adminSystem:SendMessage(player, "Pong! Admin system is working.", Color3.new(0, 1, 0))
end)

-- Kill Command
AdminSystem:RegisterCommand("kill", {"k"}, "Kill a player", 1, function(player, args, adminSystem)
	local targets = adminSystem:FindPlayer(args[1], player)

	if #targets == 0 then
		adminSystem:SendMessage(player, "Player not found: " .. args[1], Color3.new(1, 0, 0))
		return
	end

	for _, target in pairs(targets) do
		if target.Character and target.Character:FindFirstChild("Humanoid") then
			target.Character.Humanoid.Health = 0
			adminSystem:SendMessage(player, "Killed " .. target.Name, Color3.new(0, 1, 0))
		end
	end
end)

-- Teleport Command
AdminSystem:RegisterCommand("tp", {"teleport"}, "Teleport to a player", 1, function(player, args, adminSystem)
	local targets = adminSystem:FindPlayer(args[1], player)

	if #targets == 0 then
		adminSystem:SendMessage(player, "Player not found: " .. args[1], Color3.new(1, 0, 0))
		return
	end

	local target = targets[1]
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and 
		target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
		player.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame
		adminSystem:SendMessage(player, "Teleported to " .. target.Name, Color3.new(0, 1, 0))
	end
end)

-- Bring Command
AdminSystem:RegisterCommand("bring", {"summon"}, "Bring a player to you", 1, function(player, args, adminSystem)
	local targets = adminSystem:FindPlayer(args[1], player)

	if #targets == 0 then
		adminSystem:SendMessage(player, "Player not found: " .. args[1], Color3.new(1, 0, 0))
		return
	end

	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		adminSystem:SendMessage(player, "You need to be spawned to use this command", Color3.new(1, 0, 0))
		return
	end

	for _, target in pairs(targets) do
		if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
			target.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(3, 0, 0)
			adminSystem:SendMessage(player, "Brought " .. target.Name .. " to you", Color3.new(0, 1, 0))
		end
	end
end)

-- Give Money Command
AdminSystem:RegisterCommand("givemoney", {"money"}, "Give money to a player", 2, function(player, args, adminSystem)
	local PlayerDataManager = require(game.ReplicatedStorage.PlayerDataManager)
	local targets = adminSystem:FindPlayer(args[1], player)
	local amount = tonumber(args[2])

	if not amount then
		adminSystem:SendMessage(player, "Invalid amount: " .. args[2], Color3.new(1, 0, 0))
		return
	end

	if #targets == 0 then
		adminSystem:SendMessage(player, "Player not found: " .. args[1], Color3.new(1, 0, 0))
		return
	end

	for _, target in pairs(targets) do
		PlayerDataManager.AddMoney(target, amount)
		adminSystem:SendMessage(player, "Gave " .. amount .. " money to " .. target.Name, Color3.new(0, 1, 0))
	end
end)

-- Give Item Command
AdminSystem:RegisterCommand("giveitem", {"item"}, "Give specific item to a player", 2, function(player, args, adminSystem)
	local PlayerDataManager = require(game.ReplicatedStorage.PlayerDataManager)
	local targets = adminSystem:FindPlayer(args[1], player)
	local itemName = args[2]

	if #targets == 0 then
		adminSystem:SendMessage(player, "Player not found: " .. args[1], Color3.new(1, 0, 0))
		return
	end

	for _, target in pairs(targets) do
		PlayerDataManager.AddItemToInventory(target, itemName)
		adminSystem:SendMessage(player, "Gave " .. itemName .. " to " .. target.Name, Color3.new(0, 1, 0))
	end
end)

-- Give All Items Command
AdminSystem:RegisterCommand("giveallitems", {"allitems"}, "Give all items to a player", 1, function(player, args, adminSystem)
	local PlayerDataManager = require(game.ReplicatedStorage.PlayerDataManager)
	local targets = adminSystem:FindPlayer(args[1], player)

	if #targets == 0 then
		adminSystem:SendMessage(player, "Player not found: " .. args[1], Color3.new(1, 0, 0))
		return
	end

	-- Define all available items (adjust based on your game)
	local allItems = {"BasicGloves", "BrickGloves", "PowerGloves", "SpeedGloves", "GoldGloves"}

	for _, target in pairs(targets) do
		for _, item in pairs(allItems) do
			PlayerDataManager.AddItemToInventory(target, item)
		end
		adminSystem:SendMessage(player, "Gave all items to " .. target.Name, Color3.new(0, 1, 0))
	end
end)

-- Clown Kidnap Command
AdminSystem:RegisterCommand("clown", {"kidnap"}, "Kidnap a player with a clown", 1, function(player, args, adminSystem)
	local targets = adminSystem:FindPlayer(args[1], player)

	if #targets == 0 then
		adminSystem:SendMessage(player, "Player not found: " .. args[1], Color3.new(1, 0, 0))
		return
	end

	for _, target in pairs(targets) do
		if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
			local clown = Instance.new("Part")
			clown.Name = "Clown"
			clown.Size = Vector3.new(4, 6, 2)
			clown.Anchored = true
			clown.CanCollide = false
			clown.BrickColor = BrickColor.new("Bright red")
			clown.Position = target.Character.HumanoidRootPart.Position + Vector3.new(0, 10, 0)
			clown.Parent = workspace

			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.FileMesh
			mesh.MeshId = "rbxasset://fonts/torso.mesh"
			mesh.TextureId = "rbxasset://textures/face.png"
			mesh.Parent = clown

			local sound = Instance.new("Sound")
			sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
			sound.Volume = 1
			sound.Parent = clown
			sound:Play()

			local weld = Instance.new("WeldConstraint")
			weld.Part0 = clown
			weld.Part1 = target.Character.HumanoidRootPart
			weld.Parent = clown

			clown.Anchored = false

			target.Character.HumanoidRootPart.Anchored = true

			spawn(function()
				for i = 1, 50 do
					clown.CFrame = clown.CFrame * CFrame.new(0, 0.5, 0) * CFrame.Angles(0, math.rad(10), 0)
					wait(0.1)
				end
				target.Character.HumanoidRootPart.Anchored = false
				clown:Destroy()
			end)

			adminSystem:SendMessage(player, "Kidnapped " .. target.Name .. " with a clown!", Color3.new(1, 0.5, 0))
		end
	end
end)

-- Dog Command
AdminSystem:RegisterCommand("dog", {"doggy"}, "Turn a player into a dog", 1, function(player, args, adminSystem)
	local targets = adminSystem:FindPlayer(args[1], player)

	if #targets == 0 then
		adminSystem:SendMessage(player, "Player not found: " .. args[1], Color3.new(1, 0, 0))
		return
	end

	for _, target in pairs(targets) do
		if target.Character then
			local humanoid = target.Character:FindFirstChild("Humanoid")
			if humanoid then
				-- Change walkspeed and jump
				humanoid.WalkSpeed = 25
				humanoid.JumpPower = 75

				-- Add dog sounds
				local barkSound = Instance.new("Sound")
				barkSound.SoundId = "rbxasset://sounds/impact_water.mp3"
				barkSound.Volume = 0.5
				barkSound.Parent = target.Character.Head

				-- Make them crawl
				local bodyPosition = Instance.new("BodyPosition")
				bodyPosition.MaxForce = Vector3.new(0, math.huge, 0)
				bodyPosition.Position = target.Character.HumanoidRootPart.Position
				bodyPosition.Parent = target.Character.HumanoidRootPart

				-- Add dog face
				local head = target.Character:FindFirstChild("Head")
				if head then
					local face = head:FindFirstChild("face")
					if face then
						face.Texture = "rbxasset://textures/face.png"
					end

					-- Add ears
					local leftEar = Instance.new("Part")
					leftEar.Name = "LeftEar"
					leftEar.Size = Vector3.new(1, 1, 0.1)
					leftEar.BrickColor = BrickColor.new("Brown")
					leftEar.CanCollide = false
					leftEar.Parent = target.Character

					local leftWeld = Instance.new("WeldConstraint")
					leftWeld.Part0 = head
					leftWeld.Part1 = leftEar
					leftWeld.Parent = leftEar
					leftEar.CFrame = head.CFrame * CFrame.new(-0.7, 0.5, 0)

					local rightEar = leftEar:Clone()
					rightEar.Name = "RightEar"
					rightEar.Parent = target.Character
					local rightWeld = rightEar:FindFirstChild("WeldConstraint")
					rightWeld.Part0 = head
					rightEar.CFrame = head.CFrame * CFrame.new(0.7, 0.5, 0)
				end

				-- Play bark sound periodically
				spawn(function()
					for i = 1, 10 do
						wait(math.random(2, 5))
						if barkSound and barkSound.Parent then
							barkSound:Play()
						end
					end
				end)

				-- Remove dog effects after 30 seconds
				game:GetService("Debris"):AddItem(bodyPosition, 30)
				spawn(function()
					wait(30)
					if humanoid then
						humanoid.WalkSpeed = 16
						humanoid.JumpPower = 50
					end
					if target.Character then
						local leftEar = target.Character:FindFirstChild("LeftEar")
						local rightEar = target.Character:FindFirstChild("RightEar")
						if leftEar then leftEar:Destroy() end
						if rightEar then rightEar:Destroy() end
					end
				end)

				adminSystem:SendMessage(player, "Turned " .. target.Name .. " into a dog!", Color3.new(0.8, 0.5, 0.2))
			end
		end
	end
end)

-- Poop Command
AdminSystem:RegisterCommand("poop", {"💩"}, "Make a player poop", 1, function(player, args, adminSystem)
	local targets = adminSystem:FindPlayer(args[1], player)

	if #targets == 0 then
		adminSystem:SendMessage(player, "Player not found: " .. args[1], Color3.new(1, 0, 0))
		return
	end

	for _, target in pairs(targets) do
		if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
			for i = 1, 5 do
				local poop = Instance.new("Part")
				poop.Name = "Poop"
				poop.Size = Vector3.new(0.5, 0.5, 0.5)
				poop.Shape = Enum.PartType.Ball
				poop.Material = Enum.Material.Plastic
				poop.BrickColor = BrickColor.new("Brown")
				poop.TopSurface = Enum.SurfaceType.Smooth
				poop.BottomSurface = Enum.SurfaceType.Smooth
				poop.CanCollide = true
				poop.Position = target.Character.HumanoidRootPart.Position + Vector3.new(
					math.random(-2, 2), -2, math.random(-2, 2)
				)
				poop.Parent = workspace

				-- Add stink effect
				local stink = Instance.new("Smoke")
				stink.Size = 2
				stink.Color = Color3.new(0.5, 0.3, 0.1)
				stink.Opacity = 0.8
				stink.RiseVelocity = 5
				stink.Parent = poop

				-- Add gross sound
				local sound = Instance.new("Sound")
				sound.SoundId = "rbxasset://sounds/impact_water.mp3"
				sound.Volume = 0.3
				sound.Pitch = 0.5
				sound.Parent = poop
				sound:Play()

				-- Clean up after 15 seconds
				game:GetService("Debris"):AddItem(poop, 15)

				wait(0.2)
			end

			adminSystem:SendMessage(player, target.Name .. " has pooped! 💩", Color3.new(0.5, 0.3, 0.1))
		end
	end
end)

-- Connect to player chatted
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		AdminSystem:ExecuteCommand(player, message)
	end)
end)

-- Handle players already in game
for _, player in pairs(Players:GetPlayers()) do
	player.Chatted:Connect(function(message)
		AdminSystem:ExecuteCommand(player, message)
	end)
end

return AdminSystem