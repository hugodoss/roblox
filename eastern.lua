-- Lib
local Lib = {}
function Lib:MakePrototypeLibrary(Title)

local fontmenu = 26

local SG = Instance.new("ScreenGui")
SG.Name = "AstralicPrototype"
SG.DisplayOrder = math.huge
SG.ResetOnSpawn = false
SG.IgnoreGuiInset = true
SG.Parent = gethui()

local Back = Instance.new("Frame")
Back.Name = "Back"
Back.BackgroundColor3 = Color3.fromHex("121318")
Back.Size = UDim2.new(0, 450, 0, 300)
Back.Draggable = true
Back.BorderSizePixel = 0
Back.Position = UDim2.new(0.5, 0, 0.7, 0)
Back.Active = true
Back.AnchorPoint = Vector2.new(0.5, 0.5)
Back.Parent = SG
Instance.new("UICorner", Back).CornerRadius = UDim.new(0, 8)

local X = Instance.new("TextButton")
X.Name = "X"
X.BackgroundTransparency = 1
X.Font = fontmenu
X.TextColor3 = Color3.fromHex("6198ff")
X.Size = UDim2.new(0, 30, 0, 30)
X.Text = "X"
X.TextScaled = true
X.Position = UDim2.new(0, 410, 0, 10)
X.Parent = Back
X.MouseButton1Click:Connect(function()
SG:Destroy()
end)

local TitleUI = Instance.new("TextLabel")
TitleUI.Name = "TitleUI"
TitleUI.Size = UDim2.new(0, 400, 0, 30)
TitleUI.Text = Title
TitleUI.TextColor3 = Color3.fromHex("6198ff")
TitleUI.Font = fontmenu
TitleUI.Position = UDim2.new(0, 10, 0, 10)
TitleUI.TextScaled = true
TitleUI.BackgroundTransparency = 1
TitleUI.TextXAlignment = 0
TitleUI.Parent = Back

local ToggleUI = Instance.new("TextButton")
ToggleUI.Name = "ToggleUI"
ToggleUI.Font = fontmenu
ToggleUI.Size = UDim2.new(0, 32, 0, 32)
ToggleUI.TextScaled = true
ToggleUI.TextColor3 = Color3.fromHex("6198ff")
ToggleUI.Position = UDim2.new(1, -224, 0, 4)
ToggleUI.Text = "P"
ToggleUI.BackgroundTransparency = 0.4
ToggleUI.BackgroundColor3 = Color3.fromHex("121318")
ToggleUI.Parent = SG
Instance.new("UICorner", ToggleUI).CornerRadius = UDim.new(0, 8)
ToggleUI.MouseButton1Click:Connect(function()
Back.Visible = not Back.Visible
end)

local TabsOpenContainer = Instance.new("ScrollingFrame")
TabsOpenContainer.ScrollingDirection = 2
TabsOpenContainer.BackgroundColor3 = Color3.fromHex("17181D")
TabsOpenContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
TabsOpenContainer.AutomaticCanvasSize = 2
TabsOpenContainer.Name = "TabsOpenContainer"
TabsOpenContainer.Position = UDim2.new(0, 10, 0, 45)
TabsOpenContainer.ElasticBehavior = 1
TabsOpenContainer.BorderSizePixel = 0
TabsOpenContainer.ScrollBarThickness = 0
TabsOpenContainer.Size = UDim2.new(0, 105, 0, 245)
TabsOpenContainer.BackgroundTransparency = 0
TabsOpenContainer.Parent = Back
local L = Instance.new("UIListLayout")
L.SortOrder = 2
L.HorizontalAlignment = 1
L.Padding = UDim.new(0, 2)
L.Parent = TabsOpenContainer

local TabsContainer = Instance.new("Frame")
TabsContainer.Size = UDim2.new(0, 315, 0, 245)
TabsContainer.BorderSizePixel = 0
TabsContainer.Name = "TabsContainer"
TabsContainer.Position = UDim2.new(0, 125, 0, 45)
TabsContainer.BackgroundColor3 = Color3.fromHex("17181D")
TabsContainer.Parent = Back

local MakeATab = {}

function MakeATab:MakeTab(Title, Visible)
local OpenTab = Instance.new("TextButton")
OpenTab.BorderSizePixel = 0
OpenTab.Name = "OpenTab"
OpenTab.TextColor3 = Color3.fromHex("7A7A84")
if Visible then OpenTab.TextColor3 = Color3.fromHex("6198ff") end
OpenTab.AutoButtonColor = false
OpenTab.Text = Title
OpenTab.Size = UDim2.new(1, 0, 0, 25)
OpenTab.TextScaled = true
OpenTab.BackgroundColor3 = Color3.fromHex("1D1D27")
OpenTab.Font = fontmenu
OpenTab.Parent = TabsOpenContainer
Instance.new("UICorner", OpenTab).CornerRadius = UDim.new(0, 8)

local Tab = Instance.new("ScrollingFrame")
Tab.Name = "Tab"
Tab.Visible = Visible or false
Tab.ScrollingDirection = 2
Tab.AutomaticCanvasSize = 2
Tab.ElasticBehavior = 1
Tab.CanvasSize = UDim2.new(0, 0, 0, 0)
Tab.ScrollBarThickness = 0
Tab.Size = UDim2.new(1, 0, 1, 0)
Tab.BackgroundTransparency = 1
Tab.Parent = TabsContainer
local L = Instance.new("UIListLayout")
L.SortOrder = 2
L.HorizontalAlignment = 1
L.Padding = UDim.new(0, 4)
L.Parent = Tab

OpenTab.MouseButton1Click:Connect(function()
for i,v in ipairs(TabsOpenContainer:GetChildren()) do
if v.Name == "OpenTab" then
v.TextColor3 = Color3.fromHex("7A7A84")
end
end
for i,v in ipairs(TabsContainer:GetChildren()) do
v.Visible = false
end
OpenTab.TextColor3 = Color3.fromHex("6198ff")
Tab.Visible = true
end)

local TabElements = {}
function TabElements:Info(Title)
local Info = Instance.new("TextLabel")
Info.TextScaled = true
Info.Font = fontmenu
Info.Size = UDim2.new(1, 0, 0, 25)
Info.BackgroundTransparency = 1
Info.Text = Title
Info.TextXAlignment = 0
Info.Name = "Info"
Info.TextColor3 = Color3.fromHex("6198ff")
Info.Parent = Tab
end

function TabElements:Button(Title, Cally)
local Button = Instance.new("TextButton")
Button.TextXAlignment = 0
Button.Name = "Button"
Button.TextColor3 = Color3.fromHex("7A7A84")
Button.Text = Title
Button.AutoButtonColor = false
Button.Font = fontmenu
Button.Size = UDim2.new(1, 0, 0, 25)
Button.TextScaled = true
Button.BackgroundColor3 = Color3.fromHex("1D1D27")
Button.BorderSizePixel = 0
Button.Parent = Tab
Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 8)
local ButtonImg = Instance.new("ImageLabel")
ButtonImg.Position = UDim2.new(1, -30, 0, 0)
ButtonImg.Size = UDim2.new(0, 30, 0, 30)
ButtonImg.BackgroundTransparency = 1
ButtonImg.Parent = Button
Instance.new("UICorner", ButtonImg).CornerRadius = UDim.new(0, 8)
Button.MouseButton1Click:Connect(function()
coroutine.wrap(function()
Button.TextColor3 = Color3.fromHex("6198ff")
task.wait(1)
Button.TextColor3 = Color3.fromHex("7A7A84")
end)()
pcall(Cally)
end)
end

function TabElements:Toggle(Title, Cally)
    local Tog = Instance.new("TextLabel")
    Tog.Size = UDim2.new(1, -40, 0, 25)
    Tog.BorderSizePixel = 0
    Tog.BackgroundColor3 = Color3.fromHex("1D1D27")
    Tog.TextXAlignment = Enum.TextXAlignment.Left
    Tog.TextColor3 = Color3.fromHex("7A7A84")
    Tog.Text = Title
    Tog.Font = fontmenu
    Tog.TextScaled = true
    Tog.Parent = Tab
    Instance.new("UICorner", Tog).CornerRadius = UDim.new(0, 8)

    local TogButton = Instance.new("ImageButton")
    TogButton.ImageTransparency = 1
    TogButton.BackgroundTransparency = 0.9
    TogButton.Size = UDim2.new(0, 25, 0, 25)
    TogButton.BackgroundColor3 = Color3.fromHex("7A7A84")
    TogButton.Position = UDim2.new(1, 10, 0, 0)
    TogButton.Parent = Tog
    Instance.new("UICorner", TogButton).CornerRadius = UDim.new(0, 8)

    local On = false
    TogButton.MouseButton1Click:Connect(function()
        On = not On
        if On then
            TogButton.BackgroundTransparency = 0
            TogButton.BackgroundColor3 = Color3.fromHex("6198ff")
            Tog.TextColor3 = Color3.fromHex("6198ff")
        else
            TogButton.BackgroundTransparency = 0.9
            TogButton.BackgroundColor3 = Color3.fromHex("7A7A84")
            Tog.TextColor3 = Color3.fromHex("7A7A84")
        end
        pcall(Cally, On)
    end)
end

return TabElements
end
return MakeATab
end

-- Interface 
local LibInstance = Lib:MakePrototypeLibrary("Eastern Warfare")

local CuteTab = LibInstance:MakeTab("Visuals", true)

CuteTab:Info("Visuals")

local TeamCheck = false

local ESPBoxEnabled = false
local ESPLineEnabled = false
local ESPNameEnabled = false
local ESPDistanceEnabled = false
local CrosshairEnabled = false
local crosshair = nil

CuteTab:Toggle("ESP Box", function(value)
    ESPBoxEnabled = value
end)

CuteTab:Toggle("ESP Line", function(value)
    ESPLineEnabled = value
end)

CuteTab:Toggle("ESP Name", function(value)
    ESPNameEnabled = value
end)

CuteTab:Toggle("ESP Distance", function(value)
    ESPDistanceEnabled = value
end)

CuteTab:Toggle("Team Check", function(value)
    TeamCheck = value
end)

CuteTab:Toggle("Crosshair", function(value)
    CrosshairEnabled = value
    if CrosshairEnabled then
        crosshair = {
            line1 = Drawing.new("Line"),
            line2 = Drawing.new("Line")
        }

        crosshair.line1.Thickness = 2
        crosshair.line1.Visible = true

        crosshair.line2.Thickness = 2
        crosshair.line2.Visible = true
    elseif crosshair then
        crosshair.line1:Remove()
        crosshair.line2:Remove()
        crosshair = nil
    end
end)

-- Funcoes
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local ESP = {}

local function GetTeamColor(player)
    local localTeam = LocalPlayer.Team and LocalPlayer.Team.Name or nil
    local playerTeam = player.Team and player.Team.Name or nil

    if TeamCheck then

        if localTeam == "Allegiance" then
            if playerTeam == "Coalition" then
                return Color3.fromRGB(255, 255, 255)
            elseif playerTeam == "Allegiance" then
                return Color3.fromRGBA(0, 0, 255, 0)
            end
        elseif localTeam == "Coalition" then
            if playerTeam == "Allegiance" then
                return Color3.fromRGB(255, 255, 255)
            elseif playerTeam == "Coalition" then
                return Color3.fromRGBA(0, 0, 255, 0)
            end
        end

    else
        return Color3.fromRGB(255, 255, 255)
    end
    
    return Color3.fromRGB(255, 255, 255) -- Branco para sem time
end

local function Create2DESP(model, player)
    if not model or not model.Parent then return end
    if ESP[model] then return end

    local color = GetTeamColor(player)

    local drawings = {
        box = Drawing.new("Square"),
        text = Drawing.new("Text"),
        line = Drawing.new("Line")
    }

    local box = drawings.box
    box.Thickness = 1
    box.Color = color
    box.Transparency = 1
    box.Filled = false
    box.Visible = false

    local text = drawings.text
    text.Size = 12
    text.Color = color
    text.Center = true
    text.Outline = true
    text.Visible = false

    local line = drawings.line
    line.Thickness = 1
    line.Color = color
    line.Visible = false

    ESP[model] = drawings
end

local function UpdateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local character = player.Character
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            local head = character:FindFirstChild("Head")

            if humanoidRootPart and head then
                local modelESP = ESP[character]
                if not modelESP then
                    Create2DESP(character, player)
                    modelESP = ESP[character]
                end

                local screenPos, onScreen = Camera:WorldToViewportPoint(humanoidRootPart.Position)

                if onScreen then
                    local headPos, _ = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                    local rootPos, _ = Camera:WorldToViewportPoint(humanoidRootPart.Position - Vector3.new(0, 3, 0))
                    local height = math.abs(headPos.Y - rootPos.Y)
                    local width = height / 2

                    local color = GetTeamColor(player)
                    modelESP.box.Color = color
                    modelESP.text.Color = color
                    modelESP.line.Color = color

                    if ESPBoxEnabled and modelESP.box then
                        modelESP.box.Size = Vector2.new(width, height)
                        modelESP.box.Position = Vector2.new(screenPos.X - width / 2, screenPos.Y - height / 2)
                        modelESP.box.Visible = true
                    else
                        modelESP.box.Visible = false
                    end

                    if ESPLineEnabled and modelESP.line then
                        modelESP.line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        modelESP.line.To = Vector2.new(screenPos.X, screenPos.Y)
                        modelESP.line.Visible = true
                    else
                        modelESP.line.Visible = false
                    end
                    
                    if CrosshairEnabled and crosshair then
                        local centerX = Camera.ViewportSize.X / 2
                        local centerY = Camera.ViewportSize.Y / 2

                        crosshair.line1.From = Vector2.new(centerX - 10, centerY)
                        crosshair.line1.To = Vector2.new(centerX + 10, centerY)

                        crosshair.line2.From = Vector2.new(centerX, centerY - 10)
                        crosshair.line2.To = Vector2.new(centerX, centerY + 10)
                    end

                    local distance = (humanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                    local roundedDistance = math.floor(distance)
                    local formattedDistance = string.format("%dm", roundedDistance)

                    local displayText = ""
                    if ESPNameEnabled then
                        displayText = player.Name
                    end
                    if ESPDistanceEnabled then
                        displayText = displayText .. " [" .. formattedDistance .. "]"
                    end

                    if modelESP.text then
                        modelESP.text.Text = displayText
                        modelESP.text.Position = Vector2.new(screenPos.X, screenPos.Y + height / 2 + 5)
                        modelESP.text.Visible = true
                    end
                else
                    if modelESP.box then modelESP.box.Visible = false end
                    if modelESP.text then modelESP.text.Visible = false end
                    if modelESP.line then modelESP.line.Visible = false end
                end
                if not humanoidRootPart or not character.Parent then
                    if ESP[character] then
                        ESP[character].box.Visible = false
                        ESP[character].line.Visible = false
                        ESP[character].text.Visible = false
                        ESP[character] = nil -- Remove do sistema de ESP
                    end
                    continue
                end
    
                -- Atualiza a posição do ESP
                local screenPos, onScreen = Camera:WorldToViewportPoint(humanoidRootPart.Position)
                if onScreen then
                    local teamColor = GetTeamColor(player)
                    ESP[character].box.Color = teamColor
                    ESP[character].line.Color = teamColor
                    ESP[character].text.Color = teamColor
                    ESP[character].box.Visible = true
                    ESP[character].line.Visible = true
                    ESP[character].text.Visible = true
                else
                    ESP[character].box.Visible = false
                    ESP[character].line.Visible = false
                    ESP[character].text.Visible = false
                end
            end
        end
    end
end

local function CleanupESP()
    for model, drawings in pairs(ESP) do
        if not model or not model.Parent then
            for _, drawing in pairs(drawings) do
                drawing:Remove()
            end
            ESP[model] = nil
        end
    end
end

RunService.RenderStepped:Connect(function()
    UpdateESP()
    CleanupESP()
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer and player.Character then
        Create2DESP(player.Character, player)
    end
end
