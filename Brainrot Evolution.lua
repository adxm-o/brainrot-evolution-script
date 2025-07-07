--[[======================================================================
   Brainrot Evolution GUI + 24‑H Key System | v2.1
   • Auto‑detects remotes and clickdetector
   • Works with or without writefile/readfile
======================================================================]]--

-------------------------  SERVICES  -------------------------------------
local HttpService       = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local UIS               = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local StarterGui        = game:GetService("StarterGui")
local LP                = Players.LocalPlayer
-------------------------------------------------------------------------

-------------------------  FILE / FS  ------------------------------------
local hasFS, writefile, readfile, isfile, delfile
hasFS, writefile, readfile, isfile, delfile = pcall(function()
    return writefile, readfile, isfile, delfile
end)
-------------------------------------------------------------------------

---------------------  KEY ENDPOINTS (HTTPS)  ----------------------------
local BASE = "https://adxm-o.adxm-o.workers.dev"
local GET  = BASE .. "/getkey.php"
local VAL  = BASE .. "/validate.php?key="
-------------------------------------------------------------------------

-------------------------  NOTIFY  ---------------------------------------
local function notify(t, m)
    pcall(function()
        StarterGui:SetCore("SendNotification",{Title=t,Text=m,Duration=5})
    end)
end
-------------------------------------------------------------------------

----------------------  KEY FUNCTIONS  -----------------------------------
local KEY_FILE, EXP_FILE = "BREvoKey.txt", "BREvoExp.txt"

local function cachedKey()
    if not hasFS then return nil end
    if isfile(KEY_FILE) and isfile(EXP_FILE) then
        local exp = tonumber(readfile(EXP_FILE))
        if os.time() < exp then
            return readfile(KEY_FILE)
        end
    end
    return nil
end

local function saveKey(k)
    if not hasFS then return end
    writefile(KEY_FILE, k)
    writefile(EXP_FILE, tostring(os.time()+86400))
end

local function remoteValidate(k)
    local ok, res = pcall(function() return HttpService:GetAsync(VAL..k,true) end)
    return ok and res=="valid_24h"
end

local function fetchKey()
    local ok, res = pcall(function() return HttpService:GetAsync(GET,true) end)
    if not ok then error("Key server offline") end
    local data = HttpService:JSONDecode(res)
    saveKey(data.key)
    notify("Key System", data.message or "Key obtained.")
    return data.key
end

local key = cachedKey()
if not (key and remoteValidate(key)) then
    key = fetchKey()
    if not remoteValidate(key) then error("Key invalid") end
end
notify("Key OK","Access granted for 24 h.")

----------------------  REMOTE AUTODETECT  -------------------------------
local function findRemote(namePart, class)
    for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA(class) and v.Name:lower():find(namePart:lower()) then
            return v
        end
    end
    return nil
end
local evolveRemote  = findRemote("evolve","RemoteFunction")  or findRemote("evolve","RemoteEvent")
local rebirthRemote = findRemote("rebirth","RemoteFunction") or findRemote("rebirth","RemoteEvent")
local clickDet      = workspace:FindFirstChildWhichIsA("ClickDetector",true)

----------------------  CONFIG / DEFAULTS  ------------------------------
local cfg = {Speed=16,AutoClick=false,AutoEvolve=false,AutoRebirth=false,AutoChest=false,Fly=false}
local CFG_FILE="BREvoCfg.json"
if hasFS and isfile(CFG_FILE) then
    local ok,t=pcall(readfile,CFG_FILE)
    if ok then pcall(function() cfg=HttpService:JSONDecode(t) end) end
end
local function saveCfg() if hasFS then writefile(CFG_FILE,HttpService:JSONEncode(cfg)) end end

----------------------  GUI  --------------------------------------------
local SG=Instance.new("ScreenGui",LP.PlayerGui) SG.ResetOnSpawn=false
local main=Instance.new("Frame",SG) main.Size=UDim2.new(0,330,0,440) main.Position=UDim2.new(.5,-165,.5,-220)
main.BackgroundColor3=Color3.fromRGB(30,30,30) main.Active=true main.Draggable=true

local function label(txt,y)
    local l=Instance.new("TextLabel",main)
    l.Text=txt l.Position=UDim2.new(0,10,0,y) l.Size=UDim2.new(0,150,0,25)
    l.BackgroundTransparency=1 l.TextColor3=Color3.new(1,1,1) l.Font=Enum.Font.SourceSansBold l.TextSize=16
end
local function button(txt,x,y,w,cb)
    local b=Instance.new("TextButton",main)
    b.Text=txt b.Position=UDim2.new(0,x,0,y) b.Size=UDim2.new(0,w,0,25)
    b.BackgroundColor3=Color3.fromRGB(50,50,50) b.TextColor3=Color3.new(1,1,1) b.Font=Enum.Font.SourceSans b.TextSize=16
    b.MouseButton1Click:Connect(cb) return b
end
local function toggle(name,y,flag)
    label(name,y)
    local b=button(flag and"ON"or"OFF",170,y,50,function()
        flag=not flag cfg[name]=flag saveCfg()
        b.Text=flag and"ON"or"OFF" b.BackgroundColor3=flag and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,0)
    end)
    b.BackgroundColor3=flag and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,0)
    return function()return flag end
end

-- Walkspeed
label("WalkSpeed",10)
local wsBox=Instance.new("TextBox",main)
wsBox.Position=UDim2.new(0,120,0,10) wsBox.Size=UDim2.new(0,50,0,25)
wsBox.Text=tostring(cfg.Speed) wsBox.BackgroundColor3=Color3.fromRGB(50,50,50) wsBox.TextColor3=Color3.new(1,1,1)
wsBox.FocusLost:Connect(function()
    local v=tonumber(wsBox.Text) if v then cfg.Speed=v saveCfg()
        if LP.Character and LP.Character:FindFirstChild("Humanoid") then LP.Character.Humanoid.WalkSpeed=v end
    else wsBox.Text=tostring(cfg.Speed) end
end)
if LP.Character and LP.Character:FindFirstChild("Humanoid") then LP.Character.Humanoid.WalkSpeed=cfg.Speed end

-- Toggles
local getAC = toggle("AutoClick",  50,cfg.AutoClick)
local getAE = toggle("AutoEvolve", 90,cfg.AutoEvolve)
local getAR = toggle("AutoRebirth",130,cfg.AutoRebirth)
local getCH = toggle("AutoChest",  170,cfg.AutoChest)
local getFL = toggle("Fly",        210,cfg.Fly)

-- Teleport
label("Teleport to",250)
local tpBox=Instance.new("TextBox",main) tpBox.Position=UDim2.new(0,120,0,250) tpBox.Size=UDim2.new(0,100,0,25)
tpBox.BackgroundColor3=Color3.fromRGB(50,50,50) tpBox.TextColor3=Color3.new(1,1,1) tpBox.PlaceholderText="ObjectName"
button("Go",230,250,40,function()
    local dest=workspace:FindFirstChild(tpBox.Text,true)
    local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if dest and hrp then hrp.CFrame=dest:IsA("Model")and dest:GetModelCFrame() or dest.CFrame else notify("TP","Not found") end
end)

-- Stats
button("Show Stats",10,290,100,function()
    local s=LP:FindFirstChild("leaderstats") if not s then return notify("Stats","None") end
    local msg="" for _,v in pairs(s:GetChildren())do msg=msg..v.Name..": "..v.Value.."\n" end notify("Your Stats",msg)
end)

-- Panic
local p=button("PANIC",10,330,310,function() SG:Destroy() end) p.BackgroundColor3=Color3.new(1,0,0)

---------------------  TASK LOOP  ---------------------------------------
spawn(function()
    while RunService.Heartbeat:Wait() do
        -- Auto Click
        if getAC() and clickDet then pcall(fireclickdetector,clickDet) end
        -- Auto Evolve
        if getAE() and evolveRemote then
            pcall(function()
                if evolveRemote:IsA("RemoteFunction") then evolveRemote:InvokeServer()
                else evolveRemote:FireServer() end
            end)
        end
        -- Auto Rebirth
        if getAR() and rebirthRemote then
            pcall(function()
                if rebirthRemote:IsA("RemoteFunction") then rebirthRemote:InvokeServer()
                else rebirthRemote:FireServer() end
            end)
        end
        -- Auto Chest
        if getCH() then
            for _,v in pairs(workspace:GetDescendants())do
                if v.Name:lower():find("chest") and v:IsA("BasePart")then
                    local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then hrp.CFrame=v.CFrame wait(.1) end
                end
            end
        end
        -- Fly
        if getFL() and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            local root=LP.Character.HumanoidRootPart
            root.Velocity=Vector3.zero
            local dir=Vector3.zero
            local cam=workspace.CurrentCamera
            if UIS:IsKeyDown(Enum.KeyCode.W)then dir+=cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S)then dir-=cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A)then dir-=cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D)then dir+=cam.CFrame.RightVector end
            if dir.Magnitude>0 then root.CFrame+=dir.Unit*cfg.Speed*RunService.Heartbeat:Wait() end
        end
        -- Anti‑AFK
        pcall(function()
            LP.Idled:Connect(function()
                game:GetService("VirtualUser"):ClickButton2(Vector2.new())
            end)
        end)
    end
end)

notify("Loaded","Brainrot GUI ready.")
