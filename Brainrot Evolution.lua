--// Key System Configuration
local HttpService = game:GetService("HttpService")
local keyFile = "userkey.txt"
local keyExpireFile = "keyexpire.txt"

local getKeyURL = "https://adxm-o.adxm-o.workers.dev/getkey.php"
local validateURL = "https://adxm-o.adxm-o.workers.dev/validate.php?key="

--// Notification function
local function notify(title, text)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 5
        })
    end)
end

--// Load existing key if not expired
local function loadSavedKey()
    if isfile(keyFile) and isfile(keyExpireFile) then
        local savedKey = readfile(keyFile)
        local expireTime = tonumber(readfile(keyExpireFile))
        if os.time() < expireTime then
            return savedKey
        else
            delfile(keyFile)
            delfile(keyExpireFile)
        end
    end
    return nil
end

--// Validate key remotely
local function validateKey(key)
    local success, result = pcall(function()
        return HttpService:GetAsync(validateURL .. key)
    end)

    if success then
        local response = HttpService:JSONDecode(result)
        return response.valid == true
    else
        notify("Key Error", "Failed to reach validation server.")
        return false
    end
end

--// Request new key from server
local function requestNewKey()
    local success, result = pcall(function()
        return HttpService:GetAsync(getKeyURL)
    end)

    if not success then
        notify("Key Error", "Failed to get key from server.")
        error("Key server unreachable.")
    end

    local data = HttpService:JSONDecode(result)
    local key = data.key
    local message = data.message or "Key acquired."

    -- Save key + 24hr expiration
    writefile(keyFile, key)
    writefile(keyExpireFile, tostring(os.time() + 86400))

    notify("Key System", message)
    return key
end

--// Main Key Flow
local activeKey = loadSavedKey()
if activeKey and validateKey(activeKey) then
    notify("Key System", "Existing key is valid.")
else
    activeKey = requestNewKey()
    if validateKey(activeKey) then
        notify("Key System", "New key activated.")
    else
        notify("Key Error", "Key invalid or blocked.")
        error("Unauthorized user.")
    end
end

print("[✔] Key system passed — loading Brainrot Evolution script...")

-- MAIN GUI FUNCTION
function initGUI()
    -- ROOT
    local Main = Instance.new("Frame", ScreenGui)
    Main.Name = "Main"
    Main.Size = UDim2.new(0,350,0,450)
    Main.Position = UDim2.new(0.5,-175,0.5,-225)
    Main.BackgroundColor3 = Color3.fromRGB(25,25,25)
    Main.Active=true; Main.Draggable=true

    -- UI LIST
    local function makeToggle(name, y, callback, init)
        local lbl = Instance.new("TextLabel", Main)
        lbl.Text = name
        lbl.TextColor3 = Color3.new(1,1,1)
        lbl.Position = UDim2.new(0,10,0, y)
        lbl.Size = UDim2.new(0,150,0,25)
        local btn = Instance.new("TextButton", Main)
        btn.Size = UDim2.new(0,40,0,25)
        btn.Position=UDim2.new(0,170,0,y)
        btn.Text = init and "ON" or "OFF"
        btn.BackgroundColor3 = init and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,0)
        local state = init
        btn.MouseButton1Click:Connect(function()
            state = not state
            btn.Text = state and "ON" or "OFF"
            btn.BackgroundColor3 = state and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,0)
            callback(state)
            config[name:gsub("%s","")] = state
            saveConfig()
        end)
        return btn
    end

    -- Speed Slider
    local speedLabel = Instance.new("TextLabel", Main)
    speedLabel.Text = "WalkSpeed"
    speedLabel.TextColor3 = Color3.new(1,1,1)
    speedLabel.Position = UDim2.new(0,10,0,10)
    speedLabel.Size = UDim2.new(0,100,0,25)
    local speedBox = Instance.new("TextBox", Main)
    speedBox.Position = UDim2.new(0,120,0,10)
    speedBox.Size = UDim2.new(0,50,0,25)
    speedBox.Text = tostring(config.Speed)
    speedBox.FocusLost:Connect(function()
        local v = tonumber(speedBox.Text)
        if v then
            config.Speed=v; saveConfig()
            if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then
                localPlayer.Character.Humanoid.WalkSpeed = v
            end
        else speedBox.Text=tostring(config.Speed) end
    end)
    -- initial speed
    if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then
        localPlayer.Character.Humanoid.WalkSpeed = config.Speed
    end

    -- Toggles
    makeToggle("AutoClick",    50, function(on) 
        _G.AutoClick = on 
    end, config.AutoClick)
    makeToggle("AutoEvolve",   90, function(on) 
        _G.AutoEvolve = on 
    end, config.AutoEvolve)
    makeToggle("AutoRebirth", 130, function(on) 
        _G.AutoRebirth = on 
    end, config.AutoRebirth)
    makeToggle("AutoChest",   170, function(on) 
        _G.AutoChest = on 
    end, config.AutoChest)
    makeToggle("Fly",         210, function(on)
        _G.Fly = on
    end, config.Fly)

    -- Teleport Dropdown
    local tpLabel = Instance.new("TextLabel", Main)
    tpLabel.Text = "Teleport to"
    tpLabel.TextColor3 = Color3.new(1,1,1)
    tpLabel.Position = UDim2.new(0,10,0,250)
    tpLabel.Size = UDim2.new(0,100,0,25)
    local tpBox = Instance.new("TextBox", Main)
    tpBox.PlaceholderText = "PlaceName"
    tpBox.Position = UDim2.new(0,120,0,250)
    tpBox.Size = UDim2.new(0,100,0,25)
    local tpBtn = Instance.new("TextButton", Main)
    tpBtn.Text="Go"
    tpBtn.Position = UDim2.new(0,230,0,250)
    tpBtn.Size=UDim2.new(0,40,0,25)
    tpBtn.MouseButton1Click:Connect(function()
        local plr = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        local cf = workspace:FindFirstChild(tpBox.Text) and workspace[tpBox.Text]:FindFirstChild("PrimaryPart") or workspace:FindFirstChild(tpBox.Text)
        if plr and cf then
            plr.CFrame = cf.CFrame
            notify("Teleported","To "..tpBox.Text)
            config.TeleportTo = tpBox.Text; saveConfig()
        else notify("Error","Place not found.") end
    end)

    -- Stat Viewer
    local statBtn = Instance.new("TextButton", Main)
    statBtn.Text = "Show Stats"
    statBtn.Position = UDim2.new(0,10,0,290)
    statBtn.Size = UDim2.new(0,100,0,25)
    statBtn.MouseButton1Click:Connect(function()
        local stats = localPlayer:FindFirstChild("leaderstats")
        if not stats then return notify("No Stats","leaderstats missing.") end
        local msg = ""
        for _,s in pairs(stats:GetChildren()) do
            msg = msg..s.Name..": "..s.Value.."\n"
        end
        notify("Your Stats",msg)
    end)

    -- Panic Button
    local panic = Instance.new("TextButton", Main)
    panic.Text = "PANIC"
    panic.Position = UDim2.new(0,10,0,330)
    panic.Size = UDim2.new(0,330,0,40)
    panic.BackgroundColor3 = Color3.new(1,0,0)
    panic.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        notify("Panic","GUI removed.")
    end)

    -- BACKGROUND LOOPS
    spawn(function()
        while RunService.RenderStepped:Wait() do
            -- Auto Click
            if _G.AutoClick then
                pcall(function()
                    fireclickdetector(workspace.ClickPart.ClickDetector)
                end)
            end
            -- Auto Evolve
            if _G.AutoEvolve then
                pcall(function()
                    -- example: game.ReplicatedStorage.Events.Evolve:FireServer()
                    game:GetService("ReplicatedStorage").Remotes.Evolve:InvokeServer()
                end)
            end
            -- Auto Rebirth
            if _G.AutoRebirth then
                pcall(function()
                    game:GetService("ReplicatedStorage").Remotes.Rebirth:InvokeServer()
                end)
            end
            -- Auto Chest
            if _G.AutoChest then
                for _,v in pairs(workspace.Chests:GetChildren()) do
                    if v:FindFirstChild("TouchPart") then
                        local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.CFrame = v.TouchPart.CFrame
                        end
                    end
                end
            end
            -- Fly
            if _G.Fly and localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local root = localPlayer.Character.HumanoidRootPart
                root.Velocity = Vector3.new(0,0,0)
                root.AssemblyLinearVelocity = Vector3.new(0,0,0)
                local cam = workspace.CurrentCamera
                local dir = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
                root.CFrame = root.CFrame + dir.Unit * (config.Speed or 50) * RunService.RenderStepped:Wait()
            end
            -- Anti AFK
            pcall(function()
                localPlayer.Idled:Connect(function()
                    game:GetService("VirtualUser"):ClickButton2(Vector2.new())
                end)
            end)
        end
    end)

    -- Final notification
    notify("Loaded","Brainrot GUI is ready.")
end
