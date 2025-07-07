--[[======================================================================
  Brainrot Evolution Universal GUI + Secure 24‑H Key System  |  v2.0
  • 5‑char rotating keys served over HTTPS via Cloudflare Worker proxy
  • Key auto‑cached for 24 h, re‑validates on launch
  • Draggable GUI, Speed, Auto Click, Auto Evolve/Rebirth, Auto Chest,
    Fly, Teleport, Stat Viewer, Anti‑AFK, Save Config, Panic, Notifications
  • One single file—copy‑paste straight into your executor
  • Adjust remote paths (⚠️) to match your game’s ReplicatedStorage events
======================================================================]]--

--------------------------[  SERVICES  ]----------------------------------
local HttpService       = game:GetService("HttpService")
local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local StarterGui        = game:GetService("StarterGui")
local localPlayer       = Players.LocalPlayer
-------------------------------------------------------------------------

--------------------------[  FILE PATHS  ]--------------------------------
local CONFIG_FILE      = "BREvoConfig.json"   -- toggles, speed, etc.
local KEY_FILE         = "BREvoUserKey.txt"
local KEY_EXPIRE_FILE  = "BREvoKeyExpire.txt"
-------------------------------------------------------------------------

-------------------------[  KEY ENDPOINTS  ]------------------------------
local BASE_URL   = "https://adxm-o.adxm-o.workers.dev"
local GET_KEY    = BASE_URL .. "/getkey.php"
local VALIDATE   = BASE_URL .. "/validate.php?key="
-------------------------------------------------------------------------

-------------------------[  UTIL / NOTIFY  ]------------------------------
local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text  = text,
            Duration = 5
        })
    end)
end
-------------------------------------------------------------------------

--------------------------[  CONFIG LOAD  ]-------------------------------
local hasFS, writefile, readfile, isfile, delfile = pcall(function()
    return writefile, readfile, isfile, delfile
end)

local config = {
    Speed        = 16,
    AutoClick    = false,
    AutoEvolve   = false,
    AutoRebirth  = false,
    AutoChest    = false,
    Fly          = false,
    TeleportTo   = nil
}
if hasFS and isfile(CONFIG_FILE) then
    local ok, data = pcall(readfile, CONFIG_FILE)
    if ok then
        local suc, tbl = pcall(HttpService.JSONDecode, HttpService, data)
        if suc and type(tbl)=="table" then
            for k,v in pairs(tbl) do config[k]=v end
        end
    end
end
local function saveConfig()
    if hasFS then writefile(CONFIG_FILE, HttpService:JSONEncode(config)) end
end
-------------------------------------------------------------------------

--------------------------[  KEY SYSTEM  ]--------------------------------
local function loadSavedKey()
    if hasFS and isfile(KEY_FILE) and isfile(KEY_EXPIRE_FILE) then
        local key = readfile(KEY_FILE)
        local exp = tonumber(readfile(KEY_EXPIRE_FILE))
        if os.time() < (exp or 0) then
            return key
        else
            delfile(KEY_FILE)
            delfile(KEY_EXPIRE_FILE)
        end
    end
    return nil
end

local function validateKey(key)
    local ok, res = pcall(function()
        return HttpService:GetAsync(VALIDATE .. key, true)
    end)
    if ok and res == "valid_24h" then
        return true
    elseif ok and res == "expired" then
        notify("Key Expired", "Grab a fresh key from the link.")
    elseif ok then
        notify("Key Invalid", "Wrong key. Get a valid one.")
    else
        notify("Key Error", "Validation server unreachable.")
    end
    return false
end

local function requestNewKey()
    local ok, res = pcall(function()
        return HttpService:GetAsync(GET_KEY, true)
    end)
    if not ok then
        error("Key server unreachable. Aborting.")
    end
    local data = HttpService:JSONDecode(res)
    local key  = data.key
    local msg  = data.message or "Key received."
    if hasFS then
        writefile(KEY_FILE, key)
        writefile(KEY_EXPIRE_FILE, tostring(os.time() + 86400))
    end
    notify("Key System", msg)
    return key
end
-------------------------------------------------------------------------

-------------------------[  GUI + FEATURES  ]-----------------------------
local ScreenGui

local function initGUI()
    --------------- GUI ROOT ---------------
    ScreenGui = Instance.new("ScreenGui", localPlayer:WaitForChild("PlayerGui"))
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Name = "BREvolutionGUI"

    local Main = Instance.new("Frame", ScreenGui)
    Main.Size = UDim2.new(0,350,0,460)
    Main.Position = UDim2.new(0.5,-175,0.5,-230)
    Main.BackgroundColor3 = Color3.fromRGB(25,25,25)
    Main.Active = true
    Main.Draggable = true

    -- helpers
    local function makeLabel(txt,y)
        local l = Instance.new("TextLabel", Main)
        l.Text = txt
        l.Position = UDim2.new(0,10,0,y)
        l.Size = UDim2.new(0,150,0,25)
        l.BackgroundTransparency = 1
        l.Font = Enum.Font.SourceSansBold
        l.TextSize = 16
        l.TextColor3 = Color3.new(1,1,1)
        return l
    end
    local function makeButton(txt,x,y,w,cb)
        local b = Instance.new("TextButton", Main)
        b.Text = txt
        b.Position = UDim2.new(0,x,0,y)
        b.Size = UDim2.new(0,w,0,25)
        b.BackgroundColor3 = Color3.fromRGB(50,50,50)
        b.Font = Enum.Font.SourceSans
        b.TextColor3 = Color3.new(1,1,1)
        b.TextSize = 16
        b.MouseButton1Click:Connect(cb)
        return b
    end
    local function makeToggle(name,y,init,cb)
        makeLabel(name,y)
        local b = makeButton(init and "ON" or "OFF",170,y,50,function()
            init = not init
            b.Text = init and "ON" or "OFF"
            b.BackgroundColor3 = init and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,0)
            cb(init)
            config[name] = init; saveConfig()
        end)
        b.BackgroundColor3 = init and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,0)
    end

    -- Speed control
    makeLabel("WalkSpeed",10)
    local speedBox = Instance.new("TextBox", Main)
    speedBox.Position = UDim2.new(0,120,0,10)
    speedBox.Size = UDim2.new(0,50,0,25)
    speedBox.Text = tostring(config.Speed)
    speedBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
    speedBox.TextColor3 = Color3.new(1,1,1)
    speedBox.Font = Enum.Font.SourceSans
    speedBox.TextSize = 16
    speedBox.FocusLost:Connect(function()
        local v = tonumber(speedBox.Text)
        if v then
            config.Speed = v; saveConfig()
            local char = localPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.WalkSpeed = v
            end
        else
            speedBox.Text = tostring(config.Speed)
        end
    end)
    -- Apply stored speed immediately
    if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then
        localPlayer.Character.Humanoid.WalkSpeed = config.Speed
    end

    -- Toggles
    makeToggle("AutoClick",  50,  config.AutoClick,  function(v) _G.AutoClick=v end)
    makeToggle("AutoEvolve", 90,  config.AutoEvolve, function(v) _G.AutoEvolve=v end)
    makeToggle("AutoRebirth",130, config.AutoRebirth,function(v) _G.AutoRebirth=v end)
    makeToggle("AutoChest",  170, config.AutoChest,  function(v) _G.AutoChest=v end)
    makeToggle("Fly",        210, config.Fly,        function(v) _G.Fly=v end)

    -- Teleport
    makeLabel("Teleport to",250)
    local tpBox = Instance.new("TextBox", Main)
    tpBox.Position = UDim2.new(0,120,0,250)
    tpBox.Size = UDim2.new(0,100,0,25)
    tpBox.PlaceholderText = "PlaceName"
    tpBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
    tpBox.TextColor3 = Color3.new(1,1,1)
    tpBox.Font = Enum.Font.SourceSans
    tpBox.TextSize = 16
    makeButton("Go",230,250,40,function()
        local dest = tpBox.Text
        local target = workspace:FindFirstChild(dest)
        local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        if target and hrp then
            hrp.CFrame = target:IsA("Model") and target:GetModelCFrame() or target.CFrame
            config.TeleportTo = dest; saveConfig()
            notify("Teleported","→ "..dest)
        else
            notify("Error","Destination not found.")
        end
    end)

    -- Stat viewer
    makeButton("Show Stats",10,290,100,function()
        local stats = localPlayer:FindFirstChild("leaderstats")
        if not stats then return notify("No Stats","leaderstats missing.") end
        local msg=""
        for _,s in pairs(stats:GetChildren()) do msg = msg .. s.Name .. ": " .. s.Value .. "\n" end
        notify("Your Stats", msg)
    end)

    -- Panic
    local panic = makeButton("PANIC",10,330,330,function()
        ScreenGui:Destroy()
        notify("Panic","GUI removed.")
    end)
    panic.BackgroundColor3 = Color3.new(1,0,0)

    -------------- BACKGROUND LOOPS --------------
    spawn(function()
        while RunService.RenderStepped:Wait() do
            -- Auto Click (edit ClickDetector path if needed)
            if _G.AutoClick then
                pcall(function()
                    fireclickdetector(workspace.ClickPart.ClickDetector)
                end)
            end
            -- Auto Evolve (⚠️ adjust remote path)
            if _G.AutoEvolve then
                pcall(function()
                    game.ReplicatedStorage.Remotes.Evolve:InvokeServer()
                end)
            end
            -- Auto Rebirth (⚠️ adjust remote path)
            if _G.AutoRebirth then
                pcall(function()
                    game.ReplicatedStorage.Remotes.Rebirth:InvokeServer()
                end)
            end
            -- Auto Chest
            if _G.AutoChest then
                for _,v in pairs(workspace:GetChildren()) do
                    if v:IsA("Model") and v.Name:lower():find("chest") and v:FindFirstChild("TouchPart") then
                        local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then hrp.CFrame = v.TouchPart.CFrame end
                    end
                end
            end
            -- Fly
            if _G.Fly and localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local root = localPlayer.Character.HumanoidRootPart
                root.Velocity = Vector3.zero
                local cam = workspace.CurrentCamera
                local dir = Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
                if dir.Magnitude > 0 then
                    root.CFrame += dir.Unit * (config.Speed or 50) * RunService.RenderStepped:Wait()
                end
            end
            -- Anti‑AFK
            pcall(function()
                localPlayer.Idled:Connect(function()
                    game:GetService("VirtualUser"):ClickButton2(Vector2.new())
                end)
            end)
        end
    end)
    notify("Loaded","Brainrot GUI ready.")
end
-------------------------------------------------------------------------

-------------------------[  KEY CHECK THEN LAUNCH  ]----------------------
local key = loadSavedKey()
if not (key and validateKey(key)) then
    key = requestNewKey()
    if not validateKey(key) then
        error("Key validation failed. Aborting script.")
    end
end
notify("Key System", "Access granted. ("..os.date("!%H:%M:%S", tonumber(readfile(KEY_EXPIRE_FILE))).." UTC expiry)")
initGUI()
--------------------------------------------------------------------------

-- End of one‑file script
