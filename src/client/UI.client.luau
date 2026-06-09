local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local plr = Players.LocalPlayer
local UI = plr.PlayerGui:WaitForChild("ScreenGui")

-- Remotes
local moneyNotificationEvent = ReplicatedStorage:WaitForChild("MoneyNotificationEvent")
-- Make sure this event exists in ReplicatedStorage!
local playerDiedEvent = ReplicatedStorage:WaitForChild("PlayerDiedEvent") 

-- Font Settings
local FONT_ID = Font.new("rbxasset://fonts/families/Arimo.json", Enum.FontWeight.Bold)

-- =================================================================
-- MONEY POPUP FUNCTION
-- =================================================================
local function createMoneyPopup(amount)
	-- Generate random positions
	local randomX = math.random(10, 90) / 100
	local randomY = math.random(50, 85) / 100
	local endY = randomY - math.random(10, 20) / 100
	if endY < 0.5 then endY = 0.5 end

	local moneyLabel = Instance.new("TextLabel")
	moneyLabel.Name = "MoneyPopup_" .. tick()
	moneyLabel.Size = UDim2.new(0, 150, 0, 40)
	moneyLabel.Position = UDim2.new(randomX, -75, randomY, -20)
	moneyLabel.BackgroundTransparency = 1
	moneyLabel.Text = "+$" .. tostring(amount)
	moneyLabel.TextColor3 = Color3.fromRGB(255, 221, 89)
	moneyLabel.TextScaled = true
	moneyLabel.TextStrokeTransparency = 0
	moneyLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	moneyLabel.TextTransparency = 1
	moneyLabel.Parent = UI
	moneyLabel.FontFace = FONT_ID

	-- Add Gradient
	local gradient = Instance.new("UIGradient")
	gradient.Parent = moneyLabel
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 221, 89)),
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(202, 173, 55)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(202, 173, 55))
	})

	-- Animations
	local popInTween = TweenService:Create(moneyLabel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 200, 0, 50),
		TextTransparency = 0,
		TextStrokeTransparency = 0
	})

	local fadeOutTween = TweenService:Create(moneyLabel, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(.5,0,.8,0),
		TextTransparency = 1,
		TextStrokeTransparency = 1
	})

	popInTween:Play()

	popInTween.Completed:Connect(function()
		task.wait(0.5)
		fadeOutTween:Play()
		-- Play sound (kept your original timing)
		task.delay(1.2, function()
			local sound = ReplicatedStorage.Sounds:FindFirstChild("Cash Sound")
			if sound then sound:Play() end
		end)
	end)

	fadeOutTween.Completed:Connect(function() moneyLabel:Destroy() end)
	Debris:AddItem(moneyLabel, 3)
end

-- =================================================================
-- KILL FEED FUNCTION (NEW)
-- =================================================================
local function createKillPopup(victimName)
	local killLabel = Instance.new("TextLabel")
	killLabel.Name = "KillPopup_" .. victimName
	-- Positioned at bottom center (0.85 is 85% down the screen)
	killLabel.Position = UDim2.new(0.5, 0, 0.85, 0) 
	killLabel.Size = UDim2.new(0, 0, 0, 50) -- Start small
	killLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	killLabel.BackgroundTransparency = 1

	-- RICH TEXT MAGIC: We use HTML-style tags to color just the name red
	killLabel.RichText = true
	killLabel.Text = "Eliminated <font color='#FF3333'>" .. victimName .. "</font>"

	killLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- Main text is white
	killLabel.TextScaled = true
	killLabel.TextStrokeTransparency = 0
	killLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	killLabel.TextTransparency = 1
	killLabel.Parent = UI
	killLabel.FontFace = FONT_ID

	-- 1. Expand Animation (Pop Out)
	local appearTween = TweenService:Create(killLabel, TweenInfo.new(0.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
		Size = UDim2.new(0.6, 0, 0.08, 0), -- Expand to full size
		TextTransparency = 0,
		TextStrokeTransparency = 0
	})

	-- 2. Shrink and Fade Animation
	local disappearTween = TweenService:Create(killLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 0, 0, 0),
		TextTransparency = 1,
		TextStrokeTransparency = 1
	})

	appearTween:Play()

	-- Play a kill sound if you have one?
	-- local sound = ReplicatedStorage.Sounds:FindFirstChild("KillSound")
	-- if sound then sound:Play() end

	task.delay(1.5, function()
		disappearTween:Play()
		disappearTween.Completed:Connect(function()
			killLabel:Destroy()
		end)
	end)
end

-- =================================================================
-- LISTENERS
-- =================================================================

moneyNotificationEvent.OnClientEvent:Connect(createMoneyPopup)

playerDiedEvent.OnClientEvent:Connect(function(victimPlayer, killerPlayer)
	-- Only show the "Eliminated" message if WE are the killer
	if killerPlayer == plr then
		createKillPopup(victimPlayer.Name)
	end
end)