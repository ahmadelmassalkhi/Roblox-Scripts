--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

--// References
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--// Settings
local maxDistance = 1000
local aimSmoothness = 0.3
local rightClickActive = false
local visibilityCheck = false -- set to true if you want real raycast visibility

--// Target Tracking
local currentTarget = nil
local currentHighlight = nil

print("✅ Auto-aim script loaded")

--// Utilities
local function IsOnScreen(worldPos)
	local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)
	return onScreen, screenPos
end

local function IsVisible(origin, target)
	if not visibilityCheck then return true end
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist
	rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
	local result = Workspace:Raycast(origin, (target - origin), rayParams)
	return not result or result.Instance:IsDescendantOf(Players)
end

local function GetClosestTarget()
	local closest = nil
	local closestDist = math.huge
	local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local character = player.Character
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local part = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChildWhichIsA("BasePart")

			if humanoid and humanoid.Health > 0 and part then
				local onScreen, screenPos = IsOnScreen(part.Position)
				if onScreen then
					local distance = (screenCenter - Vector2.new(screenPos.X, screenPos.Y)).Magnitude

					if distance < closestDist and IsVisible(Camera.CFrame.Position, part.Position) then
						closest = part
						closestDist = distance
					end
				end
			end
		end
	end

	if closest then
		print("🎯 Closest Target:", closest.Parent.Name)
	end

	return closest
end

local function AimAt(part)
	if not part then
		if currentHighlight then
			currentHighlight:Destroy()
			currentHighlight = nil
			currentTarget = nil
		end
		return
	end

	if part.Parent ~= currentTarget then
		if currentHighlight then currentHighlight:Destroy() end

		local highlight = Instance.new("Highlight")
		highlight.Name = "AutoAim_Highlight"
		highlight.Adornee = part.Parent
		highlight.FillColor = Color3.fromRGB(255, 255, 0)
		highlight.OutlineColor = Color3.fromRGB(255, 170, 0)
		highlight.FillTransparency = 0.5
		highlight.OutlineTransparency = 0
		highlight.Parent = part.Parent

		currentHighlight = highlight
		currentTarget = part.Parent
	end

	local camPos = Camera.CFrame.Position
	local direction = (part.Position - camPos).Unit
	local newCFrame = CFrame.lookAt(camPos, camPos + direction)
	Camera.CFrame = Camera.CFrame:Lerp(newCFrame, aimSmoothness)
end

--// Input
UserInputService.InputBegan:Connect(function(input, processed)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rightClickActive = true
		print("🖱️ Right click held")
	end
end)

UserInputService.InputEnded:Connect(function(input, processed)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rightClickActive = false
		print("🛑 Right click released")

		if currentHighlight then
			currentHighlight:Destroy()
			currentHighlight = nil
			currentTarget = nil
		end
	end
end)

--// Main Loop
RunService.RenderStepped:Connect(function()
	if not rightClickActive then return end
	if not LocalPlayer.Character then return end

	print("🔍 Scanning for target...")
	local targetPart = GetClosestTarget()
	AimAt(targetPart)
end)
