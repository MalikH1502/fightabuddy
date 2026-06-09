local players = game:GetService("Players")
local LocalPlayer = players.LocalPlayer

local ui = LocalPlayer.PlayerGui:WaitForChild("Cooldowns")
local Abilbar = ui.AbilityBar
local HealthBar = ui.Health -- Your green bar frame
local tweenServ = game:GetService("TweenService")
local cooldownEvent = game.ReplicatedStorage.coolDownEvent

-- Cooldown bar (already exists)
local function fireCooldown(cooldown)
	Abilbar.Size = UDim2.new(0,0,0.033,0)
	local targetSize = UDim2.new(0.461, 0, 0.033, 0)
	local tweenInfo = TweenInfo.new(
		cooldown,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.In,
		0,
		false
	)
	local tween = tweenServ:Create(Abilbar, tweenInfo, {Size = targetSize})
	tween:Play()
end

cooldownEvent.OnClientEvent:Connect(function(abilityName, cooldown)
	fireCooldown(cooldown)
end)

-- HEALTH BAR LOGIC BELOW (scale-based sizing)
local BAR_WIDTH_SCALE = 0.497
local BAR_HEIGHT_SCALE = 0.024
local TWEEN_TIME = 0.25 -- seconds

-- Helper function: interpolate color from green to red
local function healthColor(percent)
	local r = math.clamp((1 - percent) * 2, 0, 1)
	local g = math.clamp(percent * 2, 0, 1)
	return Color3.new(r, g, 0)
end

-- Keep track of the last tween to avoid overlap
local lastSizeTween, lastColorTween

-- Updates the health bar's size and color with tween
local function updateHealthBarTween()
	local char = LocalPlayer.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	local percent = hum.Health / hum.MaxHealth
	percent = math.clamp(percent, 0, 1)

	-- Target size for tween (scale-based)
	local targetSize = UDim2.new(BAR_WIDTH_SCALE * percent, 0, BAR_HEIGHT_SCALE, 0)
	local targetColor = healthColor(percent)

	-- Cancel the last tweens if they're still running
	if lastSizeTween then lastSizeTween:Cancel() end
	if lastColorTween then lastColorTween:Cancel() end

	-- Tween size
	lastSizeTween = tweenServ:Create(
		HealthBar,
		TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
		{Size = targetSize}
	)
	lastSizeTween:Play()

	-- Tween color
	lastColorTween = tweenServ:Create(
		HealthBar,
		TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
		{BackgroundColor3 = targetColor}
	)
	lastColorTween:Play()
end

-- Connect to health changes
local function hookCharacter(char)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.HealthChanged:Connect(updateHealthBarTween)
		-- update once immediately
		updateHealthBarTween()
	end
end

-- Ensure reconnection after respawn
LocalPlayer.CharacterAdded:Connect(hookCharacter)
if LocalPlayer.Character then
	hookCharacter(LocalPlayer.Character)
end