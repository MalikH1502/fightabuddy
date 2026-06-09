local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local musicFolder = ReplicatedStorage:WaitForChild("Music")
local availableMusic = musicFolder:GetChildren()
local currentTrack = ReplicatedStorage:WaitForChild("CurrentTrack")
local fightMusicFolder = ReplicatedStorage:WaitForChild("BattleMusoc")
local deathEvent = ReplicatedStorage:WaitForChild("PlayerDiedEvent")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local currentRandomTrack = nil
local currentFightTrack = nil
local isFightMusicPlaying = false
local normalMusicPosition = 0
local fadeTime = 1
local isDead = false

-- Utility function to safely stop and nil out any track
local function stopTrack(track)
	if track then
		if track.IsPlaying then
			track:Stop()
		end
		track.Volume = 0
	end
end

local function fadeOut(track, duration)
	if track and track.IsPlaying then
		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tween = TweenService:Create(track, tweenInfo, {Volume = 0})
		tween:Play()
		tween.Completed:Connect(function()
			track:Stop()
		end)
		return tween
	end
end

local function fadeIn(track, targetVolume, duration)
	if track and not isDead then
		track.Volume = 0
		track:Play()
		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tween = TweenService:Create(track, tweenInfo, {Volume = targetVolume})
		tween:Play()
		return tween
	end
end

local function stopAllMusic()
	stopTrack(currentRandomTrack)
	stopTrack(currentFightTrack)
	currentRandomTrack = nil
	currentFightTrack = nil
	isFightMusicPlaying = false
	normalMusicPosition = 0
	currentTrack.Value = ""
end

local function startFightMusic()
	if not isFightMusicPlaying and not isDead then
		isFightMusicPlaying = true
		local fightMusicTracks = fightMusicFolder:GetChildren()

		if #fightMusicTracks > 0 then
			currentFightTrack = fightMusicTracks[math.random(1, #fightMusicTracks)]

			-- Stop and fade out normal track
			if currentRandomTrack and currentRandomTrack.IsPlaying then
				normalMusicPosition = currentRandomTrack.TimePosition
				fadeOut(currentRandomTrack, fadeTime)
				task.wait(fadeTime)
				stopTrack(currentRandomTrack)
				currentRandomTrack = nil
			else
				normalMusicPosition = 0
			end

			-- Double check not dead before starting
			if not isDead then
				currentFightTrack.TimePosition = 0
				fadeIn(currentFightTrack, 0.5, fadeTime)
				currentTrack.Value = currentFightTrack.Name
			end
		else
			warn("No fight music tracks found!")
			isFightMusicPlaying = false
		end
	end
end

local function stopFightMusic()
	if isFightMusicPlaying and currentFightTrack then
		isFightMusicPlaying = false

		fadeOut(currentFightTrack, fadeTime)
		task.wait(fadeTime)
		stopTrack(currentFightTrack)
		currentFightTrack = nil

		-- Only resume normal music if not dead
		if currentRandomTrack and not isDead then
			currentRandomTrack.TimePosition = normalMusicPosition
			fadeIn(currentRandomTrack, 0.5, fadeTime)
			currentTrack.Value = currentRandomTrack.Name
		end
	end
end

local function onHealthChanged()
	local health = humanoid.Health
	local maxHealth = humanoid.MaxHealth

	if health <= 0 then
		isDead = true
		stopAllMusic()
		deathEvent:FireServer(player)
	elseif health < 50 and health > 0 and not isDead then
		startFightMusic()
	elseif health >= 50 and not isDead then
		stopFightMusic()
	end
end

humanoid.HealthChanged:Connect(onHealthChanged)

player.CharacterAdded:Connect(function(newCharacter)
	stopAllMusic()
	isDead = false

	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	humanoid.HealthChanged:Connect(onHealthChanged)
end)

task.spawn(function()
	while true do
		if not isFightMusicPlaying and not isDead then
			-- Stop any fight music just in case
			if currentFightTrack and currentFightTrack.IsPlaying then
				stopTrack(currentFightTrack)
				currentFightTrack = nil
			end

			-- Pick a new random track that isn't the same as the old one
			local randomTrack
			repeat
				randomTrack = availableMusic[math.random(1, #availableMusic)]
			until randomTrack ~= currentRandomTrack or #availableMusic == 1
			currentRandomTrack = randomTrack

			currentTrack.Value = "..."
			task.wait(2)

			if not isDead and not isFightMusicPlaying then
				-- Ensure no overlap
				stopTrack(currentRandomTrack)
				randomTrack.Volume = 0.5
				randomTrack.TimePosition = 0
				randomTrack:Play()
				currentTrack.Value = randomTrack.Name

				-- Wait for the track to end, or for fight music/death
				while randomTrack.IsPlaying and not isFightMusicPlaying and not isDead do
					task.wait(0.1)
				end

				-- Stop if fight music or death happens
				if randomTrack.IsPlaying and (isFightMusicPlaying or isDead) then
					randomTrack:Stop()
				end
			end
		else
			task.wait(1)
		end
	end
end)