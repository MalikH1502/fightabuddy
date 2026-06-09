-- src/server/AbilityService.server.luau
-- Replaces Abilities.server.luau. Loads all gloves at startup, routes requests.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataService       = require(script.Parent.DataService)

local abilityEvent = ReplicatedStorage:WaitForChild("AbilityEvent")
local gloveFolder  = ReplicatedStorage.Shared.Gloves

-- Auto-load every glove module in the folder at startup
-- To add a new glove: drop a new module in src/shared/Gloves/ and you're done
local registry: {[string]: any} = {}
for _, module in gloveFolder:GetChildren() do
    if module:IsA("ModuleScript") then
        local ok, glove = pcall(require, module)
        if ok then
            registry[module.Name] = glove
            print("[AbilityService] Loaded", module.Name)
        else
            warn("[AbilityService] Failed to load", module.Name, glove)
        end
    end
end

-- One instance of each ability per player so cooldowns are isolated
local playerAbilities: {[number]: {[string]: any}} = {}

local function getOrCreateAbility(userId: number, gloveName: string)
    playerAbilities[userId] = playerAbilities[userId] or {}
    if not playerAbilities[userId][gloveName] then
        local template = registry[gloveName]
        if not template then return nil end
        -- Create a fresh instance so each player has independent cooldown state
        playerAbilities[userId][gloveName] = setmetatable({}, { __index = template })
        playerAbilities[userId][gloveName]._lastUsed = 0
        playerAbilities[userId][gloveName]._active   = false
    end
    return playerAbilities[userId][gloveName]
end

abilityEvent.OnServerEvent:Connect(function(player: Player)
    local session   = DataService.GetSession(player)
    if not session then return end

    local gloveName = session:Get("Equipped") or "BasicGloves"
    local ability   = getOrCreateAbility(player.UserId, gloveName)
    if not ability then return end

    ability:Use(player)
end)

game:GetService("Players").PlayerRemoving:Connect(function(player)
    playerAbilities[player.UserId] = nil
end)