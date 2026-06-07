local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- 1. Point to the folder
local soundsFolder = ReplicatedStorage:WaitForChild("Sounds"):WaitForChild("DeathSounds")

local function playDeathSound(char)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end -- Don't play if they fell in void/have no body

	local deathSounds = soundsFolder:GetChildren()

	if #deathSounds > 0 then
		-- Pick a random sound
		local randomSoundAsset = deathSounds[math.random(1, #deathSounds)]

		-- Create the sound on the SERVER
		local sound = Instance.new("Sound")
		sound.SoundId = randomSoundAsset.SoundId
		sound.Volume = 1 -- Adjust this if it's too loud/quiet

		-- 3D Audio Settings (Optional)
		sound.RollOffMaxDistance = 100 -- Players further than 100 studs won't hear it
		sound.RollOffMinDistance = 10

		sound.Parent = hrp -- Play from the player's body
		sound:Play()

		-- Automatically destroy the sound object after 5 seconds to prevent lag
		Debris:AddItem(sound, 5)
	end
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")

		-- Listen for death
		humanoid.Died:Connect(function()
			playDeathSound(character)
		end)
	end)
end

-- Connect existing players (if the script loads after players join)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Connect future players
Players.PlayerAdded:Connect(onPlayerAdded)