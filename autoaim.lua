--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

--// References
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--// State
local rightClickHeld = false

--// Helper: Get the closest humanoid to screen center
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

--// Input Events
UserInputService.InputBegan:Connect(function(input, processed)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rightClickHeld = true
		print("🖱️ Right click held")

		local humanoid = GetClosestHumanoid()
		if humanoid then
			print("🎯 Aimed at:", humanoid.Parent.Name)
		else
			print("❌ No humanoid found on screen")
		end
	end
end)

UserInputService.InputEnded:Connect(function(input, processed)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rightClickHeld = false
		print("🛑 Right click released")
	end
end)
