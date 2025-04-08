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
local currentTarget = nil
local originalCameraType = Camera.CameraType

--// Get Closest Humanoid to Screen Center
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

--// Input
UserInputService.InputBegan:Connect(function(input, processed)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rightClickHeld = true
		print("🖱️ Right click held")

		currentTarget = GetClosestHumanoid()
		if currentTarget then
			print("🎯 Locking onto:", currentTarget.Parent.Name)
			originalCameraType = Camera.CameraType
			Camera.CameraType = Enum.CameraType.Scriptable
		else
			print("❌ No target found")
		end
	end
end)

UserInputService.InputEnded:Connect(function(input, processed)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rightClickHeld = false
		currentTarget = nil
		Camera.CameraType = originalCameraType
		print("🛑 Right click released")
	end
end)

--// Aim Loop
RunService.RenderStepped:Connect(function()
	if rightClickHeld then
		if not currentTarget or currentTarget.Health <= 0 then
			currentTarget = GetClosestHumanoid()
		end

		if currentTarget then
			local hrp = currentTarget.Parent:FindFirstChild("HumanoidRootPart")
			if hrp then
				local camPos = Camera.CFrame.Position
				local lookAt = hrp.Position
				Camera.CFrame = CFrame.new(camPos, lookAt)
			end
		end
	end
end)
