local boxes = game.Workspace:WaitForChild("DisplayBoxes")
local tweenServ = game:GetService("TweenService")
for _, box in boxes:GetChildren() do

	local handle = box:WaitForChild("Handle")
	local initialCFrame = handle.CFrame

	local upDownGoal = {}
	upDownGoal.Position = handle.Position + Vector3.new(0,1,0)
	local upDownTIFO = TweenInfo.new(
		2,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.InOut,
		-1,
		true,
		2
	)
	local upDownTween = tweenServ:Create(handle, upDownTIFO, upDownGoal)

	spawn(function()
		while handle.Parent do
			local currentCFrame = handle.CFrame
			local newCFrame = currentCFrame * CFrame.Angles(0, math.rad(1), 0)
			handle.CFrame = newCFrame
			wait(0.03)
		end
	end)

	upDownTween:Play()

end