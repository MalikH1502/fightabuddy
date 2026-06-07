require(game:GetService('ReplicatedStorage').RagdollService)

local players = game:GetService('Players')

players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild('Humanoid') :: Humanoid

		humanoid:AddTag('Ragdollable')
		humanoid:AddTag('RagdollOnHumanoidFall')
		humanoid:AddTag('RagdollOnHumanoidDied')
	end)
end)

function _G.ToggleRagdoll(player)
	if player.Character then		if player.Character.Humanoid:HasTag('Ragdoll') then
			player.Character.Humanoid:RemoveTag('Ragdoll')
		else
			player.Character.Humanoid:AddTag('Ragdoll')
		end
	end
end

game:GetService('ReplicatedStorage').Remote.OnServerEvent:Connect(function(player)
	if player.Character then
		if player.Character.Humanoid:HasTag('Ragdoll') then
			player.Character.Humanoid:RemoveTag('Ragdoll')
		else
			player.Character.Humanoid:AddTag('Ragdoll')
		end
	end
end)