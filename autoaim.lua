local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local rightClickHeld = false
local currentTarget = nil

-- Get Closest Humanoid
local function GetClosestHumanoid()
	local closestHumanoid = nil
	local closestDistance = math.huge
	local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local hrp = player.Character:FindFirstChild("HumanoidRootPart")
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			if hrp and humanoid and humanoid.Health > 0 then
				local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
				if onScreen then
					local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
					if dist < closestDistance then
						closestDistance = dist
						closestHumanoid = humanoid
					end
				end
			end
		end
	end

	return closestHumanoid
end

-- Input
UserInputService.InputBegan:Connect(function(input, processed)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rightClickHeld = true
		currentTarget = GetClosestHumanoid()
	end
end)

UserInputService.InputEnded:Connect(function(input, processed)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rightClickHeld = false
		currentTarget = nil
	end
end)

-- Main Loop
RunService.RenderStepped:Connect(function()
	if rightClickHeld and currentTarget then
		local targetHRP = currentTarget.Parent:FindFirstChild("HumanoidRootPart")
		if targetHRP then
			local camPos = Camera.CFrame.Position
			local lookVector = (targetHRP.Position - camPos).Unit
			Camera.CFrame = CFrame.new(camPos, camPos + lookVector)
		end
	end
end)
