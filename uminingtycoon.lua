-- Create a unique ID for this script instance
local scriptInstanceId = tostring(tick()) .. "_" .. math.random(1000, 9999)

-- Check if there's already an active instance and remove it before starting a new one
if _G.MiningHelperActive then
    -- Disconnect all existing events
    if _G.MiningHelperConnections then
        for _, connection in pairs(_G.MiningHelperConnections) do
            if connection and typeof(connection) == "RBXScriptConnection" and connection.Connected then
                connection:Disconnect()
            end
        end
    end
    
    -- Clear all active UserInputService connections
    if _G.MiningHelperInputConnections then
        for _, inputConnection in pairs(_G.MiningHelperInputConnections) do
            if inputConnection and typeof(inputConnection) == "RBXScriptConnection" and inputConnection.Connected then
                inputConnection:Disconnect()
            end
        end
    end
    
    -- Clear all active mouse connections
    if _G.MiningHelperMouseConnections then
        for _, mouseConnection in pairs(_G.MiningHelperMouseConnections) do
            if mouseConnection and typeof(mouseConnection) == "RBXScriptConnection" and mouseConnection.Connected then
                mouseConnection:Disconnect()
            end
        end
    end
    
    -- Clear all Heartbeat and RenderStepped connections
    if _G.MiningHelperLoopConnections then
        for _, loopConnection in pairs(_G.MiningHelperLoopConnections) do
            if loopConnection and typeof(loopConnection) == "RBXScriptConnection" and loopConnection.Connected then
                loopConnection:Disconnect()
            end
        end
    end
    
    -- Disable all flight and movement functions that might be active
    _G.MiningHelperFlyEnabled = false
    _G.MiningHelperCtrlTP = false
    _G.MiningHelperCtrlDelete = false
    
    -- Remove previous UI if it exists
    if _G.MiningHelperWindow and _G.MiningHelperWindow.Remove then
        _G.MiningHelperWindow:Remove()
    end
    
    print("Previous version of Mining Helper terminated")
end

-- Create tables to store connections separated by type
_G.MiningHelperConnections = {}
_G.MiningHelperInputConnections = {}
_G.MiningHelperMouseConnections = {}
_G.MiningHelperLoopConnections = {}
_G.MiningHelperActive = true
_G.MiningHelperInstanceId = scriptInstanceId

-- Use global variables with unique prefix for this script
_G.MiningHelperFlyEnabled = false
_G.MiningHelperCtrlTP = false
_G.MiningHelperCtrlDelete = false

--// Services 
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local IsStudio = RunService:IsStudio()

--// Variables for the player
local player = Players.LocalPlayer
local playerID = player.UserId
local mouse = player:GetMouse()

--// Variable to store the camera position and ORIENTATION
local savedCFrame = nil
local savedCameraDirection = nil

--// Variables for ESP
local espEnabled = false
local maxDistance = 500
local espCache = {}
local oreFilters = {}
local customBlockSize = 4.43
local espConnection = nil

--// At the beginning of the file, add key to hide and variables for automatic selling
local uiVisible = true
local autoSellEnabled = false
local backpackCheckCooldown = 0

--// Variables for Ctrl Click TP and Ctrl Delete
local ctrltp = false
local ctrldelete = false

-- Variables for the flight system
local flyEnabled = false
local flySpeed = 16
local moveDirection = {
    forward = Vector3.new(0, 0, 0),
    backward = Vector3.new(0, 0, 0),
    left = Vector3.new(0, 0, 0),
    right = Vector3.new(0, 0, 0),
    up = Vector3.new(0, 0, 0),
    down = Vector3.new(0, 0, 0)
}

--// Variables for UI
local backpackInfo = nil
local plotInfo = nil
local cargoInfo = nil
local humanoidRoot = nil
local coordinate = nil
local coordinateSpring = Vector3.new(0, 0, 0)

-- Register global variables with prefix
_G["playerSpeed_" .. scriptInstanceId] = _G["playerSpeed_" .. scriptInstanceId] or 16  -- Default speed
_G["jumpHeight_" .. scriptInstanceId] = _G["jumpHeight_" .. scriptInstanceId] or 50    -- Default jump height

--// Fetch ImGui library
local ImGui
if IsStudio then
    ImGui = require(ReplicatedStorage.ImGui)
else
    local SourceURL = 'https://github.com/depthso/Roblox-ImGUI/raw/main/ImGui.lua'
    ImGui = loadstring(game:HttpGet(SourceURL))()
end

--// Function to save the current position and reset character (AntiCoolDown)
local function savePositionAndReset()
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        -- Save the complete CFrame of the character (position AND orientation)
        savedCFrame = character.HumanoidRootPart.CFrame
        
        -- Save camera direction
        local camera = workspace.CurrentCamera
        if camera then
            savedCameraDirection = camera.CFrame.LookVector
        end
        
        -- Reset character
        character:BreakJoints()
        
        -- Create a unique connection for when the character is added
        local connection
        connection = player.CharacterAdded:Connect(function(newCharacter)
            connection:Disconnect() -- Disconnect after first use
            
            -- Wait until HumanoidRootPart is available
            repeat wait() until newCharacter:FindFirstChild("HumanoidRootPart")
            
            -- Small additional delay to ensure everything is loaded
            wait(0.5)
            
            if savedCFrame then
                -- Teleport with the exact saved CFrame
                newCharacter.HumanoidRootPart.CFrame = savedCFrame
                
                -- Restore camera direction if saved
                if savedCameraDirection then
                    local camera = workspace.CurrentCamera
                    if camera then
                        -- Calculate new camera CFrame maintaining current position but with saved direction
                        local newCameraCFrame = CFrame.new(camera.CFrame.Position, 
                                                        camera.CFrame.Position + savedCameraDirection)
                        camera.CFrame = newCameraCFrame
                    end
                end
            
            end
        end)
    else
        print("Could not find character or its position!")
    end
end

--// Function to collect all available ore types
local function collectOreTypes()
    local oreTypes = {}
    
    for _, block in pairs(game.Workspace.SpawnedBlocks:GetChildren()) do
        if block:GetAttribute("MineId") then
            local mineId = block:GetAttribute("MineId")
            if not oreTypes[mineId] then
                oreTypes[mineId] = true
                -- By default, all filters are active
                if oreFilters[mineId] == nil then
                    oreFilters[mineId] = false
                end
            end
        end
    end
    
    return oreTypes
end

--// Function to check if an ore should be displayed based on filters
local function shouldShowOre(mineId)
    return oreFilters[mineId] == true
end

--// Function to create or update an ESP for an ore
local function createOrUpdateOreESP(block)
    -- Check if block has MineId attribute
    local mineId = block:GetAttribute("MineId")
    if not mineId then return end
    
    -- Check if ore should be displayed based on filters
    if not shouldShowOre(mineId) then
        -- Remove existing ESP if it shouldn't be displayed
        if block:FindFirstChild("ESPTag") then
            block.ESPTag:Destroy()
        end
        -- Restore default size
        block.Size = Vector3.new(4.43, 4.43, 4.43)
        espCache[block] = nil
        return
    else
        -- Apply custom size
        block.Size = Vector3.new(customBlockSize, customBlockSize, customBlockSize)
    end
    
    -- Check player distance
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local distance = (character.HumanoidRootPart.Position - block.Position).Magnitude
    if distance > maxDistance then
        -- Remove ESP if too far away
        if block:FindFirstChild("ESPTag") then
            block.ESPTag:Destroy()
        end
        -- Restore default size if out of range
        block.Size = Vector3.new(4.43, 4.43, 4.43)
        espCache[block] = nil
        return
    end
    
    -- Check if already in cache and update information
    if espCache[block] then
        local existingTag = block:FindFirstChild("ESPTag")
        if existingTag and existingTag:FindFirstChild("TextLabel") and existingTag:FindFirstChild("DistanceLabel") then
            existingTag.TextLabel.Text = mineId
            existingTag.DistanceLabel.Text = math.floor(distance) .. "m"
        else
            -- If tag exists in cache but not on block, recreate
            espCache[block] = nil
        end
    end
    
    -- If not in cache, create new ESP
    if not espCache[block] then
        -- Remove existing ESP if any
        if block:FindFirstChild("ESPTag") then
            block.ESPTag:Destroy()
        end
        
        -- Create BillboardGui for text
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESPTag"
        billboard.Adornee = block
        billboard.Size = UDim2.new(0, 100, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 1, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = block
        
        -- ESP text for ore name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "TextLabel"
        nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
        nameLabel.Position = UDim2.new(0, 0, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.new(1, 1, 1) -- White
        nameLabel.Text = mineId
        nameLabel.Font = Enum.Font.SourceSansBold
        nameLabel.TextSize = 14
        nameLabel.TextStrokeTransparency = 0.5
        nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        nameLabel.TextXAlignment = Enum.TextXAlignment.Center
        nameLabel.TextYAlignment = Enum.TextYAlignment.Center
        nameLabel.Parent = billboard
        
        -- ESP text for distance
        local distanceLabel = Instance.new("TextLabel")
        distanceLabel.Name = "DistanceLabel"
        distanceLabel.Size = UDim2.new(1, 0, 0.5, 0)
        distanceLabel.Position = UDim2.new(0, 0, 0.5, 0)
        distanceLabel.BackgroundTransparency = 1
        distanceLabel.TextColor3 = Color3.new(1, 1, 1) 
        distanceLabel.Text = math.floor(distance) .. "m"
        distanceLabel.Font = Enum.Font.SourceSans
        distanceLabel.TextSize = 12
        distanceLabel.TextStrokeTransparency = 0.5
        distanceLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        distanceLabel.TextXAlignment = Enum.TextXAlignment.Center
        distanceLabel.TextYAlignment = Enum.TextYAlignment.Center
        distanceLabel.Parent = billboard
        
        -- Add to cache
        espCache[block] = true
    end
end

--// Optimized update system
local updateCooldown = 0
local function updateAllOreESPs()
    if not espEnabled then return end
    
    -- Update every 0.5 seconds to save resources
    updateCooldown = updateCooldown + 1
    if updateCooldown < 30 then return end
    updateCooldown = 0
    
    for _, block in pairs(game.Workspace.SpawnedBlocks:GetChildren()) do
        createOrUpdateOreESP(block)
    end
end

--// Check if ESP is already configured in a previous instance
local espEnabledGlobal = _G["espEnabled_" .. scriptInstanceId]

--// Function to enable/disable ESP
local function toggleESP(value)
    -- Update local and global variable
    espEnabled = value
    _G["espEnabled_" .. scriptInstanceId] = value
    
    if espEnabled then
        -- When enabling, collect ore types
        collectOreTypes()
        
        -- Apply ESP to all visible blocks
        for _, block in pairs(game.Workspace.SpawnedBlocks:GetChildren()) do
            local mineId = block:GetAttribute("MineId")
            if mineId and shouldShowOre(mineId) then
                -- Apply custom size
                block.Size = Vector3.new(customBlockSize, customBlockSize, customBlockSize)
            else
                -- Default size for unselected blocks
                block.Size = Vector3.new(4.43, 4.43, 4.43)
            end
            createOrUpdateOreESP(block)
        end
        
        -- Start continuous update
        if not espConnection then
            espConnection = RunService.RenderStepped:Connect(updateAllOreESPs)
        end
    else
        -- Disable ESP
        if espConnection then
            espConnection:Disconnect()
            espConnection = nil
        end
        
        -- Clear all existing ESPs and restore default sizes
        for _, block in pairs(game.Workspace.SpawnedBlocks:GetChildren()) do
            if block:FindFirstChild("ESPTag") then
                block.ESPTag:Destroy()
            end
            -- Restore default size
            block.Size = Vector3.new(4.43, 4.43, 4.43)
        end
        
        -- Clear cache
        table.clear(espCache)
    end
end

--// Monitor new blocks
game.Workspace.SpawnedBlocks.ChildAdded:Connect(function(block)
    if espEnabled then
        wait(0.1) -- Small delay to ensure all attributes are loaded
        local mineId = block:GetAttribute("MineId")
        
        if mineId then
            -- Add new ore type if it doesn't exist yet
            if oreFilters[mineId] == nil then
                oreFilters[mineId] = true  -- By default, new ores are visible
            end
            
            -- Check if type is selected and apply appropriate size
            if shouldShowOre(mineId) then
                block.Size = Vector3.new(customBlockSize, customBlockSize, customBlockSize)
            else
                block.Size = Vector3.new(4.43, 4.43, 4.43) -- Default size
            end
            
            -- Always try to create ESP for new block
            createOrUpdateOreESP(block)
        end
    end
end)

--// Clear cache when blocks are removed
game.Workspace.SpawnedBlocks.ChildRemoved:Connect(function(child)
    if espCache[child] then
        espCache[child] = nil
    end
    
    if child:FindFirstChild("ESPTag") then
        child.ESPTag:Destroy()
    end
end)

--// Function to find player base
local function findPlayerBase()
    local playerPlot = nil
    
    -- Check if Plots folder exists
    if not workspace:FindFirstChild("Plots") then
        print("Plots folder not found!")
        return nil
    end
    
    -- Search for all plots
    for _, plot in pairs(workspace.Plots:GetChildren()) do
        -- Check if plot has OwnerId attribute
        local ownerId = plot:GetAttribute("OwnerId")
        if ownerId and ownerId == playerID then
            playerPlot = plot
            break
        end
    end
    
    return playerPlot
end

--// Function to teleport to player base
local function teleportToBase()
    local plot = findPlayerBase()
    
    if not plot then
        print("Player base not found!")
        return
    end
    
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        print("Character not found!")
        return
    end
    
    -- Teleport to the front of the plot
    local plotPosition = plot:GetPivot().Position
    local teleportPosition = CFrame.new(plotPosition + Vector3.new(0, 5, 0))
    character.HumanoidRootPart.CFrame = teleportPosition
    
    print("Teleported to base!")
end

--// Function to find player's CargoPrompt
local function findCargoPrompt()
    local plot = findPlayerBase()
    if not plot then
        print("Player base not found!")
        return nil
    end
    
    -- Search for placeables with the same plot number
    local plotName = plot.Name
    local placeables = workspace:FindFirstChild("Placeables")
    if not placeables then
        print("Placeables folder not found!")
        return nil
    end
    
    -- Search for folder with plot name
    local plotFolder = placeables:FindFirstChild(plotName)
    if not plotFolder then
        print("Plot folder " .. plotName .. " not found in Placeables!")
        return nil
    end
    
    -- Search for UnloaderSystem
    local unloaderSystem = plotFolder:FindFirstChild("UnloaderSystem")
    if not unloaderSystem then
        print("UnloaderSystem not found!")
        return nil
    end
    
    -- Search for Unloader
    local unloader = unloaderSystem:FindFirstChild("Unloader")
    if not unloader then
        print("Unloader not found!")
        return nil
    end
    
    -- Search for CargoVolume
    local cargoVolume = unloader:FindFirstChild("CargoVolume")
    if not cargoVolume then
        print("CargoVolume not found!")
        return nil
    end
    
    -- Search for CargoPrompt
    local cargoPrompt = cargoVolume:FindFirstChild("CargoPrompt")
    if not cargoPrompt then
        print("CargoPrompt not found!")
        return nil
    end
    
    return cargoPrompt
end

--// Add function to check player backpack
local function checkBackpackCapacity()
    local character = player.Character
    if not character then return 0, 0 end
    
    -- Search for backpack by player name
    local playerName = player.Name
    local playerBackpack = workspace:FindFirstChild(playerName)
    
    if not playerBackpack then return 0, 0 end
    
    local orePackCargo = playerBackpack:FindFirstChild("OrePackCargo")
    if not orePackCargo then return 0, 0 end
    
    local capacity = orePackCargo:GetAttribute("Capacity") or 0
    local numContents = orePackCargo:GetAttribute("NumContents") or 0
    
    return numContents, capacity
end

-- Optimized definitive function for selling via ProximityPrompt
local function sellViaProximityPromptFinal()
    local cargoPrompt = findCargoPrompt()
    if not cargoPrompt then
        print("CargoPrompt not found!")
        return false
    end
    
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        print("Character not found!")
        return false
    end
    
    -- Save current position and orientation
    local currentPosition = character.HumanoidRootPart.CFrame
    local camera = workspace.CurrentCamera
    local savedCameraLookVector = camera.CFrame.LookVector
    local savedCameraPosition = camera.CFrame.Position
    
    -- Reference to CargoVolume
    local cargoVolume = cargoPrompt.Parent
    local cargoPosition = cargoVolume.Position
    
    -- Position player next to cargo, already looking at center
    local playerPosition = cargoPosition + Vector3.new(0, 1, 2)
    character.HumanoidRootPart.CFrame = CFrame.new(playerPosition, cargoPosition)
    
    -- Wait a moment for the game to process movement
    task.wait(0.05)
    
    -- Adjust camera to look directly at cargo
    local cameraDirection = (cargoPosition - camera.CFrame.Position).Unit
    camera.CFrame = CFrame.new(camera.CFrame.Position, camera.CFrame.Position + cameraDirection)
    
    -- Small delay to ensure everything is registered
    task.wait(0.1)
    
    -- Activate prompt
    if cargoPrompt:IsA("ProximityPrompt") then
        -- Try to activate once to ensure
        for i = 1, 1 do
            fireproximityprompt(cargoPrompt)
            task.wait(0.1)
        end
        print("Sale activated with optimized positioning!")
    else
        print("Object is not a ProximityPrompt!")
    end
    
    -- Wait a bit more before restoring position
    task.wait(0.1)
    
    -- Restore position and orientation
    character.HumanoidRootPart.CFrame = currentPosition
    camera.CFrame = CFrame.new(savedCameraPosition, savedCameraPosition + savedCameraLookVector)
    
    return true
end

-- Function to check and make automatic sale with optimized method
local function checkAndAutoSell()
    if not autoSellEnabled then return end
    
    -- Check cooldown
    backpackCheckCooldown = backpackCheckCooldown + 1
    if backpackCheckCooldown < 30 then return end
    backpackCheckCooldown = 0
    
    -- Check backpack capacity
    local numContents, capacity = checkBackpackCapacity()
    if capacity <= 0 then return end
    
    -- If backpack is full or almost full (90%), trigger automatic sale
    if numContents >= capacity * 0.9 then
        sellViaProximityPromptFinal()
    end
end

-- Update main window configuration (wider)
local Window = ImGui:CreateWindow({
    Title = "Mining Helper",
    Size = UDim2.new(0, 400, 0, 500), 
    Position = UDim2.new(0.8, 0, 0.5, 0),
    NoCollapse = false,
    TabsBar = false,
})

--// Creating main tab (single)
local MainTab = Window:CreateTab({
    Name = "Main",
    Visible = true
})

--// Player Section with requested features
local PlayerSection = MainTab:CollapsingHeader({
    Title = "Movement and Controls",
    Open = false
})

-- Helper functions for flight system
local function resetCoordinate()
    if not humanoidRoot then return end
    local camCFrame = workspace.CurrentCamera.CFrame
    coordinate = CFrame.new(humanoidRoot.Position, camCFrame.LookVector + humanoidRoot.Position)
end

local function resetSpring()
    if coordinate then
        coordinateSpring = Vector3.new(coordinate.X, coordinate.Y, coordinate.Z)
    end
end

local function getUnitDirection()
    local sum = Vector3.new(0, 0, 0)
    for _, v in pairs(moveDirection) do
        sum = sum + v
    end
    return sum.Magnitude > 0 and sum.Unit or sum
end

local function updateCoordinate(deltaTime)
    if not coordinate then return end
    local camCFrame = workspace.CurrentCamera.CFrame
    local direction = getUnitDirection()
    if direction.Magnitude > 0 then
        coordinate = CFrame.fromMatrix(
            coordinate.Position, 
            camCFrame.XVector, 
            camCFrame.YVector, 
            camCFrame.ZVector
        ) * CFrame.new(direction * flySpeed * deltaTime)
    else
        coordinate = CFrame.fromMatrix(coordinate.Position, camCFrame.XVector, camCFrame.YVector, camCFrame.ZVector)
    end
end

local function updateDirection(keyCode, begin)
    local direction = begin and 1 or 0
    if keyCode == Enum.KeyCode.W then
        moveDirection.forward = Vector3.new(0, 0, -direction)
    elseif keyCode == Enum.KeyCode.S then
        moveDirection.backward = Vector3.new(0, 0, direction)
    elseif keyCode == Enum.KeyCode.A then
        moveDirection.left = Vector3.new(-direction, 0, 0)
    elseif keyCode == Enum.KeyCode.D then
        moveDirection.right = Vector3.new(direction, 0, 0)
    end
end

-- Function to apply movement settings
local function applyMovementSettings()
    local character = player.Character
    if character and character:FindFirstChild("Humanoid") then
        character.Humanoid.WalkSpeed = _G["playerSpeed_" .. scriptInstanceId]
        character.Humanoid.JumpPower = _G["jumpHeight_" .. scriptInstanceId]
        
        -- Ensure settings were applied correctly
        print("Settings applied: Speed=" .. character.Humanoid.WalkSpeed .. ", Jump=" .. character.Humanoid.JumpPower)
    else
        print("Humanoid not found to apply movement settings")
    end
end

-- Configure input connections
local UserInputService = game:GetService("UserInputService")
local mouse = player:GetMouse()

-- Settings for flight system
local flyInputBeganConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- Check if this script should be processing this event
    if _G.MiningHelperInstanceId ~= scriptInstanceId then return end
    
    if not gameProcessed then
        updateDirection(input.KeyCode, true)
    end
end)
table.insert(_G.MiningHelperInputConnections, flyInputBeganConnection)

local flyInputEndedConnection = UserInputService.InputEnded:Connect(function(input)
    -- Check if this script should be processing this event
    if _G.MiningHelperInstanceId ~= scriptInstanceId then return end
    
    updateDirection(input.KeyCode, false)
end)
table.insert(_G.MiningHelperInputConnections, flyInputEndedConnection)

-- Teleport function when clicking with Ctrl pressed
local ctrlClickTpConnection = mouse.Button1Down:Connect(function()
    -- Check if this script should be processing this event
    if _G.MiningHelperInstanceId ~= scriptInstanceId then return end
    
    if ctrltp and mouse.Target and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        local targetPosition = mouse.Hit.Position + Vector3.new(0, 3, 0)

        -- Adjust direction based on camera LookVector
        local lookVector = workspace.CurrentCamera.CFrame.LookVector
        local targetCFrame = CFrame.new(targetPosition, targetPosition + lookVector)

        -- Get character and HumanoidRootPart
        local character = player.Character
        if character then
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                -- Teleport character
                humanoidRootPart.CFrame = targetCFrame
                print("Teleported to clicked location")
            else
                warn("HumanoidRootPart not found.")
            end
        else
            warn("Character not found.")
        end
    end
end)
table.insert(_G.MiningHelperMouseConnections, ctrlClickTpConnection)

-- Fix Ctrl+Delete function (using correct mouse.Button1Down)
local ctrlDeleteConnection = mouse.Button1Down:Connect(function()
    -- Check if this script should be processing this event
    if _G.MiningHelperInstanceId ~= scriptInstanceId then return end
    
    if ctrldelete and mouse.Target and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        mouse.Target:Destroy()
        print("Object deleted!")
    end
end)
table.insert(_G.MiningHelperMouseConnections, ctrlDeleteConnection)

-- Loop connections for flight system and ESP update
local heartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime)
    -- Check if this script should be processing this event
    if _G.MiningHelperInstanceId ~= scriptInstanceId then return end
    
    if flyEnabled and humanoidRoot and coordinate then
        updateCoordinate(deltaTime)
        humanoidRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        humanoidRoot.CFrame = workspace.CurrentCamera.CFrame.Rotation + coordinate.Position
    end
end)
table.insert(_G.MiningHelperLoopConnections, heartbeatConnection)

local renderSteppedConnection = RunService.RenderStepped:Connect(function()
    -- Check if this script should be processing this event
    if _G.MiningHelperInstanceId ~= scriptInstanceId then return end
    
    if flyEnabled and humanoidRoot then
        humanoidRoot.CFrame = workspace.CurrentCamera.CFrame.Rotation + humanoidRoot.Position
    end
end)
table.insert(_G.MiningHelperLoopConnections, renderSteppedConnection)

-- Set up CharacterAdded with more robust movement application
local characterAddedConnection = player.CharacterAdded:Connect(function(character)
    -- Check if this script should be processing this event
    if _G.MiningHelperInstanceId ~= scriptInstanceId then return end
    
    humanoidRoot = character:WaitForChild("HumanoidRootPart")
    resetCoordinate()
    resetSpring()
    
    local humanoid = character:WaitForChild("Humanoid")
    if humanoid then
        -- Set directly on humanoid to ensure
        humanoid.WalkSpeed = _G["playerSpeed_" .. scriptInstanceId]
        humanoid.JumpPower = _G["jumpHeight_" .. scriptInstanceId]
        print("Character added - Settings applied: Speed=" .. humanoid.WalkSpeed .. ", Jump=" .. humanoid.JumpPower)
    else
        print("Failed to find Humanoid in new character")
    end
end)
table.insert(_G.MiningHelperConnections, characterAddedConnection)

-- Initialize with current character more robustly
if player.Character then
    humanoidRoot = player.Character:FindFirstChild("HumanoidRootPart")
    resetCoordinate()
    
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if humanoid then
        -- Set directly on humanoid to ensure
        humanoid.WalkSpeed = _G["playerSpeed_" .. scriptInstanceId]
        humanoid.JumpPower = _G["jumpHeight_" .. scriptInstanceId]
        print("Initial settings applied: Speed=" .. humanoid.WalkSpeed .. ", Jump=" .. humanoid.JumpPower)
    else
        print("Failed to find Humanoid in current character")
    end
end

-- Add controls in UI
PlayerSection:Checkbox({
    Label = "Ctrl Click TP",
    Value = ctrltp,
    Callback = function(self, Value)
        ctrltp = Value
    end
})

PlayerSection:Checkbox({
    Label = "Ctrl Delete",
    Value = ctrldelete,
    Callback = function(self, Value)
        ctrldelete = Value
    end
})

PlayerSection:Keybind({
    Label = "Toggle Fly",
    Value = Enum.KeyCode.X, 
    Callback = function()
        flyEnabled = not flyEnabled
        if flyEnabled then
            resetCoordinate()
            resetSpring()
        end
    end
})

PlayerSection:ProgressSlider({
    Label = "Fly Speed",
    Format = "%.d",
    Value = flySpeed,
    MinValue = 1,
    MaxValue = 500,
    Callback = function(_, Value)
        flySpeed = Value
        -- Apply the value immediately
        print("Fly speed changed to: " .. Value)
    end
})

PlayerSection:ProgressSlider({
    Label = "Walk Speed",
    Format = "%.d",
    Value = _G["playerSpeed_" .. scriptInstanceId],
    MinValue = 16,
    MaxValue = 500,
    Callback = function(_, Value)
        _G["playerSpeed_" .. scriptInstanceId] = Value
        
        -- Apply immediately without depending on external function
        local character = player.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.WalkSpeed = Value
            print("Speed changed to: " .. Value)
        end
    end
})

PlayerSection:ProgressSlider({
    Label = "Jump Height",
    Format = "%.d",
    Value = _G["jumpHeight_" .. scriptInstanceId],
    MinValue = 50,
    MaxValue = 300,
    Callback = function(_, Value)
        _G["jumpHeight_" .. scriptInstanceId] = Value
        
        -- Apply immediately without depending on external function
        local character = player.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.JumpPower = Value
            print("Jump height changed to: " .. Value)
        end
    end
}) 

--// Separator
MainTab:Separator()

--// ESP Section
local ESPSection = MainTab:CollapsingHeader({
    Title = "ESP",
    Open = false
})

--// Checkbox to enable/disable ESP
ESPSection:Checkbox({
    Label = "Ore ESP",
    Value = espEnabledGlobal ~= nil and espEnabledGlobal or false, 
    Callback = function(self, Value)
        toggleESP(Value)
    end
})

--// ESP Initialization - check if script is being reloaded
-- Should be placed at the beginning of the script after variable declarations
if espEnabledGlobal ~= nil then
    -- If script has been loaded before, disable previous ESP
    toggleESP(false)
    print("Script reloaded - Previous ESP has been disabled")
    
    -- Here you can decide whether to initialize with ESP already enabled again
    -- To automatically reactivate after disabling the previous one, uncomment:
    -- task.wait(0.5) -- small delay to ensure the previous one was removed
    -- toggleESP(true)
else
    -- First time loading, initialize global variable as false
    _G["espEnabled_" .. scriptInstanceId] = false
    print("First script initialization - ESP configured as disabled")
end

--// Slider to control maximum distance
ESPSection:Slider({
    Label = "Maximum Distance",
    Format = "%.d m",
    Value = maxDistance,
    MinValue = 10,
    MaxValue = 1000,
    Callback = function(self, Value)
        maxDistance = Value
    end
})

--// Slider to control block size
ESPSection:Slider({
    Label = "Block Size",
    Format = "%.2f",
    Value = customBlockSize,
    MinValue = 4.43,
    MaxValue = 30.0,
    Callback = function(self, Value)
        customBlockSize = Value
    end
})

--// Ore filters using CollapsingHeader
local oreFiltersHeader = MainTab:CollapsingHeader({
    Title = "Ore Filters",
    Open = false
})

-- Variable to store filters
local oreFilterControls = {}

--// Button to update ore list
oreFiltersHeader:Button({
    Text = "Update Ore List",
    Callback = function()
        -- Collect ore types
        local oreTypes = collectOreTypes()
        
        -- Clear existing filter elements
        for _, control in pairs(oreFilterControls) do
            if control and control.Remove then
                control:Remove()
            end
        end
        oreFilterControls = {}
        
        -- Create new checkboxes for each ore type
        for mineId, _ in pairs(oreTypes) do
            oreFilterControls[mineId] = oreFiltersHeader:Checkbox({
                Name = "OreFilter_" .. mineId,
                Label = mineId,
                Value = oreFilters[mineId] or false,
                Callback = function(self, Value)
                    oreFilters[mineId] = Value
                end
            })
        end
    end
})

--// Separator
MainTab:Separator()

--// Teleport and selling section
local teleportHeader = MainTab:CollapsingHeader({
    Title = "Teleport and Selling",
    Open = false
})

--// Button to teleport to base
teleportHeader:Button({
    Text = "Teleport to Base",
    Callback = function()
        teleportToBase()
    end
})

--// Keybind for automatic selling with final method
teleportHeader:Keybind({
    Label = "Auto Sell Key",
    Value = Enum.KeyCode.F,
    Callback = function(self, KeyCode)
        sellViaProximityPromptFinal()
    end
})

--// Checkbox for automatic selling
local autoSellCheckbox = teleportHeader:Checkbox({
    Label = "Auto Sell (Full Backpack)",
    Value = autoSellEnabled,
    Callback = function(self, Value)
        autoSellEnabled = Value
    end
})

--// Separator
MainTab:Separator()

--// AntiCoolDown Section
local cooldownHeader = MainTab:CollapsingHeader({
    Title = "Anti-CoolDown",
    Open = false
})

--// Keybind for AntiCoolDown
local anticooldownKeybind = cooldownHeader:Keybind({
    Label = "Anti-CoolDown Key",
    Value = Enum.KeyCode.E,
    Callback = function(self, KeyCode)
        savePositionAndReset()
    end
})

--// Add periodic backpack information update
local backpackUpdateConnection = coroutine.wrap(function()
    while _G.MiningHelperActive do
        wait(1)
        local numContents, capacity = checkBackpackCapacity()
        if capacity > 0 and backpackInfo then
            backpackInfo.Text = string.format("Backpack: %d/%d", numContents, capacity)
        elseif backpackInfo then
            backpackInfo.Text = "Backpack: Not found"
        end
    end
end)
backpackUpdateConnection()

--// Update player information
local playerInfoUpdateConnection = coroutine.wrap(function()
    wait(1) -- Small delay to ensure workspace is loaded
    
    -- Update plot information
    local plot = findPlayerBase()
    if plot and plotInfo then
        plotInfo.Text = "Plot: " .. plot.Name
    elseif plotInfo then
        plotInfo.Text = "Plot not found!"
    end
    
    -- Check CargoPrompt
    local cargoPrompt = findCargoPrompt()
    if cargoPrompt and cargoInfo then
        cargoInfo.Text = "CargoPrompt found!"
    elseif cargoInfo then
        cargoInfo.Text = "CargoPrompt not found!"
    end
end)
playerInfoUpdateConnection()

--// Add keybind for UI toggle in ImGui style at the correct place
local toggleKeybind = MainTab:Keybind({
    Label = "Toggle UI",
    Value = Enum.KeyCode.RightControl,
    Callback = function(self, KeyCode)
        uiVisible = not uiVisible
        Window:SetVisible(uiVisible)
    end
})

-- In the update loop, add backpack check
local gameUpdateConnection
local function startGameUpdates()
    if gameUpdateConnection then
        gameUpdateConnection:Disconnect()
    end
    
    gameUpdateConnection = RunService.RenderStepped:Connect(function()
        -- ESP update system
        if espEnabled then
            updateCooldown = updateCooldown + 1
            if updateCooldown >= 30 then
                updateCooldown = 0
                updateAllOreESPs()
            end
        end
        
        -- Check backpack and sell if necessary
        checkAndAutoSell()
    end)
end

-- Automatic ore types update
local function setupAutoUpdateOreTypes()
    local updateOresCooldown = 0
    
    game.Workspace.SpawnedBlocks.ChildAdded:Connect(function(block)
        -- When adding a new block, mark for update
        updateOresCooldown = 29 -- Next frame will update
    end)
    
    RunService.RenderStepped:Connect(function()
        updateOresCooldown = updateOresCooldown + 1
        if updateOresCooldown < 30 then return end
        updateOresCooldown = 0
        
        -- Update ores automatically every 30 frames
        local oreTypes = collectOreTypes()
        
        -- Remove non-existent types
        for mineId, control in pairs(oreFilterControls) do
            if not oreTypes[mineId] and control and control.Remove then
                control:Remove()
                oreFilterControls[mineId] = nil
            end
        end
        
        -- Add new types
        for mineId, _ in pairs(oreTypes) do
            if not oreFilterControls[mineId] then
                oreFilterControls[mineId] = oreFiltersHeader:Checkbox({
                    Name = "OreFilter_" .. mineId,
                    Label = mineId,
                    Value = oreFilters[mineId] or false,
                    Callback = function(self, Value)
                        oreFilters[mineId] = Value
                    end
                })
            end
        end
    end)
end

--// At the end of the script, start additional functions
setupAutoUpdateOreTypes()
startGameUpdates()

-- Store all important connections
table.insert(_G.MiningHelperConnections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        updateDirection(input.KeyCode, true)
    end
end))

table.insert(_G.MiningHelperConnections, UserInputService.InputEnded:Connect(function(input)
    updateDirection(input.KeyCode, false)
end))

table.insert(_G.MiningHelperConnections, RunService.Heartbeat:Connect(function(deltaTime)
    if flyEnabled and humanoidRoot and coordinate then
        updateCoordinate(deltaTime)
        humanoidRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        humanoidRoot.CFrame = workspace.CurrentCamera.CFrame.Rotation + coordinate.Position
    end
end))

table.insert(_G.MiningHelperConnections, RunService.RenderStepped:Connect(function()
    if flyEnabled and humanoidRoot then
        humanoidRoot.CFrame = workspace.CurrentCamera.CFrame.Rotation + humanoidRoot.Position
    end
end))

--// Adjust window position to be at the corner of the screen
Window:Center()
Window.Position = UDim2.new(1, -Window.AbsoluteSize.X - 10, 0.5, -Window.AbsoluteSize.Y/2)

--// Store window reference globally to be able to remove it later
_G.MiningHelperWindow = Window

--// Adding handler for when the game is closed
game:BindToClose(function()
    if _G.MiningHelperActive then
        -- Disconnect all events
        for _, connection in pairs(_G.MiningHelperConnections) do
            if connection and typeof(connection) == "RBXScriptConnection" and connection.Connected then
                connection:Disconnect()
            end
        end
        
        -- Remove UI
        if _G.MiningHelperWindow and _G.MiningHelperWindow.Remove then
            _G.MiningHelperWindow:Remove()
        end
        
        _G.MiningHelperActive = false
    end
end)

print("Mining Helper v2.0 loaded successfully!")

--// Return window for possible external use
return Window
