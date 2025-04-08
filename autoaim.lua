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
			print("🎯 Target:", currentTarget.Parent.Name)
		else
			print("❌ No target found")
		end
	end
end)

UserInputService.InputEnded:Connect(function(input, processed)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rightClickHeld = false
		currentTarget = nil
		print("🛑 Right click released")
	end
end)

--// Aim Loop: Rotate the Character
RunService.RenderStepped:Connect(function()
	if rightClickHeld and LocalPlayer.Character then
		if not currentTarget or currentTarget.Health <= 0 then
			currentTarget = GetClosestHumanoid()
		end

		if currentTarget then
			local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			local targetRoot = currentTarget.Parent:FindFirstChild("HumanoidRootPart")

			if myRoot and targetRoot then
				local lookDirection = (targetRoot.Position - myRoot.Position).Unit
				local newCFrame = CFrame.new(myRoot.Position, myRoot.Position + Vector3.new(lookDirection.X, 0, lookDirection.Z))
				myRoot.CFrame = newCFrame
			end
		end
	end
end)
