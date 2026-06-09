-- src/shared/Gloves/VoidGloves.luau
-- Clean example — only contains what's unique to VoidGloves.

local Debris    = game:GetService("Debris")
local Ability   = require(script.Parent.Parent.Ability)

local VoidGloves = Ability:extend({
    name     = "VoidGloves",
    cooldown = 12,
})

local PUSH_RADIUS = 75
local PUSH_FORCE  = 1000

function VoidGloves:OnActivate(player: Player)
    local hrp    = player.Character.HumanoidRootPart
    local origin = hrp.Position

    for _, other in game.Players:GetPlayers() do
        if other == player then continue end
        if not other.Character then continue end

        local otherHRP  = other.Character:FindFirstChild("HumanoidRootPart")
        local humanoid  = other.Character:FindFirstChild("Humanoid")
        if not otherHRP or not humanoid or humanoid.Health <= 0 then continue end

        local dist = (otherHRP.Position - origin).Magnitude
        if dist > PUSH_RADIUS then continue end

        local dir = (otherHRP.Position - origin).Unit

        local lv             = Instance.new("LinearVelocity")
        local att            = Instance.new("Attachment")
        att.Parent           = otherHRP
        lv.Attachment0       = att
        lv.MaxForce          = math.huge
        lv.RelativeTo        = Enum.ActuatorRelativeTo.World
        lv.VectorVelocity    = (dir + Vector3.new(0, 0.2, 0)).Unit * PUSH_FORCE
        lv.Parent            = otherHRP

        Debris:AddItem(att, 0.3)
        Debris:AddItem(lv, 0.3)
    end
end

return VoidGloves