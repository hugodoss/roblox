local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/ahsrua/AsruaUI/main/sursa.lua"))():MakePrototypeLibrary("DeadLine")

local CuteTab = Lib:MakeTab("Visuals", true)

CuteTab:Info("Visuals")

local ESPBoxEnabled = false
local ESPNameEnabled = false
local ESPDistanceEnabled = false
local CrosshairEnabled = false
local crosshair = nil

CuteTab:Toggle("ESP Box", function(value)
    ESPBoxEnabled = value
end)

CuteTab:Toggle("ESP Name", function(value)
    ESPNameEnabled = value
end)

CuteTab:Toggle("ESP Distance", function(value)
    ESPDistanceEnabled = value
end)

CuteTab:Toggle("Crosshair", function(value)
    CrosshairEnabled = value
    if CrosshairEnabled then
        crosshair = {
            line1 = Drawing.new("Line"),
            line2 = Drawing.new("Line")
        }

        crosshair.line1.Thickness = 2
        crosshair.line1.Color = Color3.fromRGB(255, 255, 255)
        crosshair.line1.Visible = true

        crosshair.line2.Thickness = 2
        crosshair.line2.Color = Color3.fromRGB(255, 255, 255)
        crosshair.line2.Visible = true
    elseif crosshair then
        crosshair.line1:Remove()
        crosshair.line2:Remove()
        crosshair = nil
    end
end)

local AimTab = Lib:MakeTab("Aim Options", false)

AimTab:Info("Aim Options")

AimTab:Toggle("Aimbot", function(value)
    print(value)
end)

local ESP = {}
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local WorldToViewportPoint = camera.WorldToViewportPoint

local function Create2DESP(model)
    if not model or not model.Parent then return end
    if ESP[model] then return end
    
    local drawings = {
        box = Drawing.new("Square"),
        text = Drawing.new("Text")
    }
    
    local box = drawings.box
    box.Thickness = 1
    box.Color = Color3.fromRGB(255, 255, 255)
    box.Transparency = 1
    box.Filled = false
    box.Visible = false

    local text = drawings.text
    text.Size = 12
    text.Color = Color3.fromRGB(255, 255, 255)
    text.Center = true
    text.Outline = true
    text.Visible = false

    ESP[model] = drawings
end

local updateConnection = RunService.PreRender:Connect(function()
    for model, drawings in pairs(ESP) do
        local rootPart = model:FindFirstChild("humanoid_root_part")
        if not rootPart then 
            drawings.box.Visible = false
            drawings.text.Visible = false
            continue 
        end
        
        local rootCFrame = rootPart.CFrame
        local rootPos = rootCFrame.Position
        local upVectorY = rootCFrame.UpVector.Y
        local screenPos, onScreen = WorldToViewportPoint(camera, rootPos)
        
        if onScreen then
            local offset = Vector3.new(0, 3 * math.abs(upVectorY), 0)
            local topPos = WorldToViewportPoint(camera, rootPos + offset)
            local bottomPos = WorldToViewportPoint(camera, rootPos - offset)
            
            local height = math.abs(topPos.Y - bottomPos.Y)
            local width = height * 0.6
            
            if ESPBoxEnabled then
                drawings.box.Size = Vector2.new(width, height)
                drawings.box.Position = Vector2.new(screenPos.X - width / 2, screenPos.Y - height / 2)
                drawings.box.Visible = true
            else
                drawings.box.Visible = false
            end
            
            local distance = (rootPos - camera.CFrame.Position).Magnitude
            local roundedDistance = math.floor(distance)
            local formattedDistance = string.format("%dm", roundedDistance)
            
            if ESPNameEnabled or ESPDistanceEnabled then
                local displayText = ""
                if ESPNameEnabled then
                    displayText = "Player"
                end
                if ESPDistanceEnabled then
                    displayText = displayText .. " [" .. formattedDistance .. "]"
                end
                
                drawings.text.Text = displayText
                drawings.text.Position = Vector2.new(screenPos.X, screenPos.Y + height / 2 + 5)
                drawings.text.Visible = true
            else
                drawings.text.Visible = false
            end
        else
            drawings.box.Visible = false
            drawings.text.Visible = false
        end
    end

    if CrosshairEnabled and crosshair then
        local centerX = camera.ViewportSize.X / 2
        local centerY = camera.ViewportSize.Y / 2

        crosshair.line1.From = Vector2.new(centerX - 10, centerY)
        crosshair.line1.To = Vector2.new(centerX + 10, centerY)

        crosshair.line2.From = Vector2.new(centerX, centerY - 10)
        crosshair.line2.To = Vector2.new(centerX, centerY + 10)
    end
end)

local characters = workspace:WaitForChild("characters")
if characters then
    for _, model in ipairs(characters:GetChildren()) do
        task.spawn(function()
            Create2DESP(model)
        end)
    end
    
    characterAddedConnection = characters.ChildAdded:Connect(function(model)
        task.wait(0.5)
        task.spawn(function()
            Create2DESP(model)
        end)
    end)
    
    characterRemovedConnection = characters.ChildRemoved:Connect(function(model)
        if ESP[model] then
            ESP[model].box:Remove()
            ESP[model].text:Remove()
            ESP[model] = nil
        end
    end)
end

local function CleanupESP()
    for _, drawings in pairs(ESP) do
        drawings.box:Remove()
        drawings.text:Remove()
    end
    ESP = {}
    
    if updateConnection then
        updateConnection:Disconnect()
    end
    if characterAddedConnection then
        characterAddedConnection:Disconnect()
    end
    if characterRemovedConnection then
        characterRemovedConnection:Disconnect()
    end
end

game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightControl then
        CleanupESP()
    end
end)
