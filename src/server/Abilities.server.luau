local ReplicatedStorage = game:GetService("ReplicatedStorage")
local abilityEvt = ReplicatedStorage:WaitForChild("AbilityEvent")
local Abilities = require(ReplicatedStorage.Abilities)

abilityEvt.OnServerEvent:Connect(function(player)
	Abilities.UseAbility(player)
end)