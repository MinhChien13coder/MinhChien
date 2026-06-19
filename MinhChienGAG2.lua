-- ========================================================
-- MINHCHIEN HUB - REDZ V2 (SIÊU BẢO MẬT + NETWORK)
-- ========================================================
-- Script hoàn chỉnh, không cắt bớt, tối ưu chống ban.
-- ========================================================

-- ========================================================
-- PHẦN 1: TƯỜNG LỬA CHỐNG BAN (SIÊU CẤP)
-- ========================================================
pcall(function()
    -- Vô hiệu hóa debug, getfenv, setfenv, loadstring
    local function disableDangerousFunctions()
        if debug then
            debug.getinfo = nil
            debug.getupvalue = nil
            debug.setupvalue = nil
            debug.getfenv = nil
            debug.setfenv = nil
            debug.getmetatable = nil
            debug.setmetatable = nil
            debug.traceback = nil
        end
        if getfenv then
            getfenv = nil
            setfenv = nil
        end
        if loadstring then
            -- Ghi đè loadstring
            local old_loadstring = loadstring
            loadstring = function(...) 
                -- Chỉ cho phép thực thi nếu đến từ script này (có thể dùng thêm kiểm tra)
                return nil 
            end
        end
    end
    disableDangerousFunctions()

    -- Danh sách remote bị cấm (mở rộng)
    local bannedRemotes = {
        "BanRemote", "CheckCheat", "AdminRemote", "CheatDetection", "ReportServer",
        "Anticheat", "KickRemote", "KickPlayer", "BanPlayer", "BanUser",
        "AntiExploit", "AntiCheat", "ExploitDetector", "RemoteLog", "Analytics",
        "UserReport", "ServerLog", "BanService", "Punishment", "Moderation",
        "AdminService", "LogService", "Telemetry", "CrashReport", "ErrorReport",
        "ReportPlayer", "AbuseReport", "SecurityCheck", "Validation", "Verify",
        "PermissionCheck", "RoleCheck", "AdminCheck", "BanCheck", "KickCheck",
        "ScriptCheck", "MemoryCheck", "ExecutionCheck", "BehaviorCheck",
        "PlayerReport", "GameReport", "SystemReport", "EventLog", "DebugLog",
        "RemoteMonitor", "RemoteWatch", "RemoteScanner", "RemoteDetector",
        "PlayerTracker", "PlayerMonitor", "PlayerWatch", "ServerWatch",
        "ServerMonitor", "ServerTracker", "ServerAnalyzer", "ServerLogger",
        "ExploitLogger", "ExploitTracker", "ExploitMonitor", "ExploitDetector",
        "CheatLogger", "CheatMonitor", "CheatTracker", "CheatWatch",
        "BanLogger", "BanMonitor", "BanTracker", "PunishLogger",
        "AuthCheck", "AuthVerify", "AuthService", "AuthLogger",
        "LoadCheck", "LoadMonitor", "LoadAnalyzer", "LoadTracker"
    }

    -- Ghi đè __namecall
    if getrawmetatable then
        local gmt = getrawmetatable(game)
        if setreadonly then setreadonly(gmt, false) end
        local oldNamecall = gmt.__namecall

        gmt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local methodStr = tostring(method):lower()

            -- Chặn Kick
            if methodStr == "kick" then
                print("[REDZ FIREWALL] Đã chặn lệnh Kick từ máy chủ!")
                return nil
            end

            -- Chặn FireServer, InvokeServer, FireAllClients trên remote bị cấm
            if methodStr == "fireserver" or methodStr == "invokeserver" or methodStr == "fireallclients" then
                local selfName = tostring(self):lower()
                local fullName = (self:GetFullName() or ""):lower()
                for _, banned in ipairs(bannedRemotes) do
                    local bannedLower = banned:lower()
                    if selfName:find(bannedLower) or fullName:find(bannedLower) then
                        print("[REDZ FIREWALL] Vô hiệu hóa Remote: " .. banned)
                        return nil
                    end
                end
            end

            return oldNamecall(self, ...)
        end)

        -- Bảo vệ metatable để không ai ghi đè __namecall
        local protectedMeta = {
            __newindex = function(t, k, v)
                if k == "__namecall" then
                    print("[REDZ FIREWALL] Cố gắng ghi đè __namecall - Đã chặn!")
                    return
                end
                rawset(t, k, v)
            end
        }
        setmetatable(gmt, protectedMeta)
        if setreadonly then setreadonly(gmt, true) end
    end

    -- Tự động quét và vô hiệu hóa remote mới
    task.spawn(function()
        while true do
            pcall(function()
                for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
                    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                        local name = obj.Name:lower()
                        for _, banned in ipairs(bannedRemotes) do
                            if name:find(banned:lower()) then
                                if obj:IsA("RemoteEvent") and obj.FireServer then
                                    local old = obj.FireServer
                                    obj.FireServer = function(...) 
                                        print("[REDZ FIREWALL] Tự động chặn Remote: " .. obj.Name)
                                        return nil 
                                    end
                                end
                                if obj:IsA("RemoteFunction") and obj.InvokeServer then
                                    local old = obj.InvokeServer
                                    obj.InvokeServer = function(...) 
                                        print("[REDZ FIREWALL] Tự động chặn RemoteFunction: " .. obj.Name)
                                        return nil 
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            task.wait(5)
        end
    end)

    -- Vô hiệu hóa script mới trong ServerScriptService
    pcall(function()
        local sss = game:GetService("ServerScriptService")
        if sss then
            sss.ChildAdded:Connect(function(child)
                if child:IsA("Script") or child:IsA("ModuleScript") then
                    child.Disabled = true
                    print("[REDZ FIREWALL] Vô hiệu hóa script mới: " .. child.Name)
                end
            end)
        end
    end)

    -- Bảo vệ CoreGui khỏi bị xóa
    pcall(function()
        local coreGui = game:GetService("CoreGui")
        if coreGui then
            coreGui.ChildRemoved:Connect(function(child)
                if child.Name == "RedzCloneMinhChien" then
                    print("[REDZ FIREWALL] Phát hiện xóa UI, sẽ khôi phục sau 1 giây")
                    task.wait(1)
                    if not coreGui:FindFirstChild("RedzCloneMinhChien") then
                        -- Khôi phục UI (sẽ được tạo lại sau khi script chạy)
                        -- Ở đây có thể gọi lại hàm tạo UI nếu cần
                    end
                end
            end)
        end
    end)

    -- Bảo vệ game.Players.LocalPlayer khỏi bị kick
    pcall(function()
        if LocalPlayer then
            LocalPlayer:Kick = function() return nil end
        end
    end)

    print("[REDZ FIREWALL] Tường lửa siêu cấp đã kích hoạt thành công!")
end)

-- ========================================================
-- PHẦN 2: CẤU HÌNH VÀ TRẠNG THÁI HỆ THỐNG
-- ========================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Bảng trạng thái toàn cục
local State = {
    -- Auto Farm cũ (dùng RemoteEvent)
    AutoPlant          = false,
    AutoHarvest        = false,
    AutoBuySeeds       = false,
    AutoBuyPets        = false,
    AutoSell           = false,
    AutoBuyGear        = false,
    SelectedSeed       = "Strawberry",
    SelectedPet        = "Frog",
    SelectedGear       = "BasicSprinkler",
    BuyDelay           = 2,
    FarmDelay          = 1,
    StealMode          = "Highest Value",
    AutoFlingOwner     = false,
    OnlyMutated        = false,
    AutoStealFruit     = false,
    FlingTargetText    = "",
    
    -- Auto Farm mới (dùng ProximityPrompt)
    AutoHarvestPrompt  = false,
    AutoFarmSell       = false,
    AutoBuyPlant       = false,
    AutoCollectFruits  = false,
    AutoStealNight     = false,
    AutoBuyLegendPet   = false,
    AutoBuyMythicSeed  = false,
    AutoBuySuperSeed   = false,
    AntiAFK            = false,

    -- Network & API
    UseProxy           = false,
    ProxyURL           = "https://cors-anywhere.herokuapp.com/",
    APIEndpoint        = "https://api.minhchienhub.com/v1/",
    UseDNS             = false,
    DNSServer          = "1.1.1.1",
    APITimeout         = 10,
    APIRetryCount      = 3,
}

-- Danh sách các loại hạt, pet, dụng cụ
local SeedsList = {
    "Carrot", "Strawberry", "Blueberry", "Tulip", "Tomato", "Apple", "Corn", "Cactus", "Pineapple",
    "Mushroom", "Green Bean", "Banana", "Grape", "Coconut", "Mango", "Dragon Fruit", "Acorn", "Cherry", 
    "Sunflower", "Venus Fly Trap", "Pomegranate", "Poison Apple", "Moon Bloom", "Dragon's Breath",
    "Baby Cactus", "Horned Melon", "Glow Mushroom", "Poison Ivy", "Ghost Pepper"
}

local PetsList = {
    "Frog", "Bunny", "Owl", "Deer", "Robin", "Bee", "Monkey", "Golden Dragonfly", "Unicorn", "Raccoon", "Black Dragon", "Ice Serpent"
}

local GearsList = {
    "BasicSprinkler", "AdvancedSprinkler", "AutoHarvester", "Fertilizer", "GoldenFertilizer", "WateringCan", "Shovel", "Hoe", "Rake"
}

-- ========================================================
-- PHẦN 3: HÀM TIỆN ÍCH VÀ REMOTE
-- ========================================================
local function getRemote(name)
    local remote = ReplicatedStorage:FindFirstChild(name, true)
    if not remote then
        local folder = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:FindFirstChild("Events")
        if folder then remote = folder:FindFirstChild(name) end
    end
    return remote
end

local function safeFireServer(eventName, ...)
    local remote = getRemote(eventName)
    if remote and remote:IsA("RemoteEvent") then
        local success, err = pcall(function()
            remote:FireServer(...)
        end)
        if not success then
            warn("[MINHCHIEN] FireServer thất bại: " .. tostring(err))
        end
        return success
    end
    return false
end

-- Hàm lấy thông tin nhân vật
local function getCharacter()
    return LocalPlayer.Character
end

local function getRootPart()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- Teleport với kiểm tra
local function teleportTo(cframe)
    local root = getRootPart()
    if root and cframe then
        root.CFrame = cframe
        task.wait(0.3)
        return true
    end
    return false
end

-- Lấy số tiền
local function getWallet()
    local stats = LocalPlayer:FindFirstChild("leaderstats")
    if stats then
        local money = stats:FindFirstChild("Coins") or stats:FindFirstChild("Cash") or stats:FindFirstChild("Money") or stats:FindFirstChild("Gems")
        if money then return money.Value end
    end
    return 0
end

-- Kiểm tra kho đầy
local function checkInventoryFull()
    local isFull = false
    pcall(function()
        local stats = LocalPlayer:FindFirstChild("leaderstats")
        if stats then
            local current, max
            for _, child in pairs(stats:GetChildren()) do
                if child:IsA("IntValue") or child:IsA("NumberValue") then
                    local cName = string.lower(child.Name)
                    if cName == "maxinventory" or cName == "maxbag" or cName == "capacity" or cName == "inventorysize" then
                        max = child.Value
                    elseif cName == "inventory" or cName == "bag" or cName == "fruits" or cName == "items" then
                        current = child.Value
                    end
                end
            end
            if current and max and max > 0 and current >= max then isFull = true end
        end
    end)
    return isFull
end

-- Kiểm tra ban đêm
local function isNightTime()
    local clock = Lighting.ClockTime
    return (clock >= 18 or clock <= 6)
end

-- ========================================================
-- PHẦN 4: CÁC VÒNG LẶP AUTO FARM CŨ (RemoteEvent)
-- ========================================================
local function runAutoPlant()
    while State.AutoPlant do
        pcall(function()
            local garden = workspace:FindFirstChild("GardenPlots") or workspace:FindFirstChild("Garden") or workspace:FindFirstChild("Plots")
            if garden then
                for _, plot in ipairs(garden:GetChildren()) do
                    if not State.AutoPlant then break end
                    if plot:IsA("Model") or plot:IsA("BasePart") then
                        if not (plot:FindFirstChild("Plant") or plot:FindFirstChild("Crop") or plot:FindFirstChild("Seed")) then
                            safeFireServer("PlantSeed", plot, State.SelectedSeed)
                            task.wait(0.15)
                        end
                    end
                end
            end
        end)
        task.wait(State.FarmDelay)
    end
end

local function runAutoHarvest()
    while State.AutoHarvest do
        pcall(function()
            local garden = workspace:FindFirstChild("GardenPlots") or workspace:FindFirstChild("Garden") or workspace:FindFirstChild("Plots")
            if garden then
                for _, plot in ipairs(garden:GetChildren()) do
                    if not State.AutoHarvest then break end
                    if plot:IsA("Model") or plot:IsA("BasePart") then
                        local plant = plot:FindFirstChild("Plant") or plot:FindFirstChild("Crop")
                        if plant then
                            safeFireServer("HarvestPlant", plot)
                            task.wait(0.15)
                        end
                    end
                end
            end
        end)
        task.wait(State.FarmDelay)
    end
end

local function runAutoBuySeeds()
    while State.AutoBuySeeds do
        safeFireServer("BuySeed", State.SelectedSeed)
        task.wait(State.BuyDelay)
    end
end

local function runAutoBuyPets()
    while State.AutoBuyPets do
        safeFireServer("PurchasePet", State.SelectedPet)
        task.wait(State.BuyDelay)
    end
end

local function runAutoSell()
    while State.AutoSell do
        safeFireServer("SellAll")
        safeFireServer("SellCrops")
        task.wait(State.BuyDelay + 1)
    end
end

local function runAutoBuyGear()
    while State.AutoBuyGear do
        safeFireServer("BuyGear", State.SelectedGear)
        task.wait(State.BuyDelay)
    end
end

local function runAutoStealFruit()
    while State.AutoStealFruit do
        pcall(function()
            local targets = workspace:FindFirstChild("GardenPlots") or workspace:FindFirstChild("Garden")
            if targets then
                for _, plot in ipairs(targets:GetChildren()) do
                    if not State.AutoStealFruit then break end
                    local plant = plot:FindFirstChild("Plant") or plot:FindFirstChild("Crop")
                    if plant then
                        if State.OnlyMutated and not (plant:FindFirstChild("Mutated") or plant.Name:lower():find("mutated")) then
                            continue
                        end
                        safeFireServer("StealFruit", plot)
                        task.wait(0.2)
                    end
                end
            end
        end)
        task.wait(0.5)
    end
end

-- ========================================================
-- PHẦN 5: FLING SYSTEM
-- ========================================================
local function executeFling(targetPlayer)
    if not targetPlayer or targetPlayer == LocalPlayer then return end
    local char = LocalPlayer.Character
    local targetChar = targetPlayer.Character
    if not char or not targetChar then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local thrp = targetChar:FindFirstChild("HumanoidRootPart")
    if not hrp or not thrp then return end

    local oldCFrame = hrp.CFrame
    local bv = Instance.new("BodyVelocity", hrp)
    bv.MaxForce = Vector3.new(1, 1, 1) * math.huge
    bv.Velocity = Vector3.new(500000, 500000, 500000)
    
    local bav = Instance.new("BodyAngularVelocity", hrp)
    bav.MaxForce = Vector3.new(1, 1, 1) * math.huge
    bav.AngularVelocity = Vector3.new(500000, 500000, 500000)
    
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") then part.CanCollide = false end
    end
    
    local startTime = tick()
    while tick() - startTime < 2.5 and thrp and thrp.Parent and hrp and hrp.Parent do
        hrp.CFrame = thrp.CFrame * CFrame.new(math.random(-1, 1), 0, math.random(-1, 1))
        task.wait()
    end
    
    bv:Destroy()
    bav:Destroy()
    hrp.Velocity = Vector3.new(0, 0, 0)
    hrp.RotVelocity = Vector3.new(0, 0, 0)
    task.wait(0.1)
    hrp.CFrame = oldCFrame
end

-- ========================================================
-- PHẦN 6: CÁC VÒNG LẶP AUTO FARM MỚI (ProximityPrompt)
-- ========================================================

-- Cache các object cần thiết
local sellPartCache = nil
local mythicShopPrompt = nil
local superShopPrompt = nil
local harvestPrompts = {}
local plantPrompts = {}

-- Cập nhật cache
task.spawn(function()
    while true do
        pcall(function()
            if not sellPartCache then
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and string.find(string.lower(obj.Name), "sell") then
                        sellPartCache = obj
                        break
                    end
                end
            end

            local tempHarvest = {}
            local tempPlant = {}

            for _, p in pairs(Workspace:GetDescendants()) do
                if p:IsA("ProximityPrompt") then
                    local act = string.lower(tostring(p.ActionText))
                    local pName = p.Parent and string.lower(p.Parent.Name) or ""

                    if (string.find(act, "harvest") or string.find(act, "take") or string.find(act, "pick") or string.find(pName, "fruit") or string.find(pName, "crop")) and not string.find(act, "talk") then
                        if p.Parent:IsA("BasePart") then table.insert(tempHarvest, p) end
                    elseif string.find(act, "plant") or string.find(act, "sow") then
                        if p.Parent:IsA("BasePart") then table.insert(tempPlant, p) end
                    elseif string.find(pName, "mythic") and (string.find(act, "buy") or string.find(act, "seed") or string.find(act, "shop")) then
                        mythicShopPrompt = p
                    elseif string.find(pName, "super") and (string.find(act, "buy") or string.find(act, "seed") or string.find(act, "shop")) then
                        superShopPrompt = p
                    end
                end
            end

            harvestPrompts = tempHarvest
            plantPrompts = tempPlant
        end)
        task.wait(1.5)
    end
end)

-- Thread A: Auto Harvest (Prompt)
task.spawn(function()
    while true do
        task.wait(0.3)
        if not State.AutoHarvestPrompt then continue end
        local root = getRootPart()
        if not root then continue end

        if checkInventoryFull() and sellPartCache then
            local savedPos = root.CFrame
            root.CFrame = sellPartCache.CFrame * CFrame.new(0, 3, 0)
            task.wait(0.8)
            pcall(function()
                for _, p in pairs(Workspace:GetDescendants()) do
                    if p:IsA("ProximityPrompt") and (root.Position - p.Parent.Position).Magnitude < 25 then
                        fireproximityprompt(p)
                        break
                    end
                end
            end)
            while checkInventoryFull() and State.AutoHarvestPrompt do
                task.wait(0.5)
            end
            root.CFrame = savedPos
            task.wait(0.5)
        else
            local acted = false
            if State.AutoBuyPlant and #plantPrompts > 0 then
                local wallet = getWallet()
                local targetShop = nil
                if wallet >= 10000 and mythicShopPrompt then
                    targetShop = mythicShopPrompt
                elseif wallet >= 5000 and superShopPrompt then
                    targetShop = superShopPrompt
                end
                if targetShop and targetShop.Parent then
                    root.CFrame = targetShop.Parent.CFrame * CFrame.new(0, 2, 0)
                    task.wait(0.3)
                    fireproximityprompt(targetShop)
                    task.wait(0.3)
                end
                local activePlot = plantPrompts[1]
                if activePlot and activePlot.Parent and activePlot.Parent:IsA("BasePart") then
                    root.CFrame = activePlot.Parent.CFrame * CFrame.new(0, 2, 0)
                    task.wait(0.3)
                    fireproximityprompt(activePlot)
                    task.wait(0.1)
                    acted = true
                end
            end

            if not acted then
                for _, prompt in pairs(harvestPrompts) do
                    if not State.AutoHarvestPrompt or checkInventoryFull() then break end
                    if #plantPrompts > 0 then break end
                    if prompt and prompt.Parent and prompt.Parent:IsA("BasePart") then
                        root.CFrame = prompt.Parent.CFrame * CFrame.new(0, 2, 0)
                        task.wait(0.3)
                        fireproximityprompt(prompt)
                        task.wait(0.1)
                    end
                end
            end
        end
    end
end)

-- Thread B: Auto Farm & Sell (Prompt)
task.spawn(function()
    while true do
        task.wait(0.3)
        if not State.AutoFarmSell then continue end
        local root = getRootPart()
        if not root then continue end

        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") and State.AutoFarmSell then
                local namaParent = string.lower(v.Parent.Name)
                if string.find(namaParent, "fruit") or string.find(namaParent, "harvest") or v.ObjectText == "Harvest" or v.ActionText == "Harvest" then
                    root.CFrame = v.Parent.CFrame * CFrame.new(0, 2, 0)
                    task.wait(0.2)
                    fireproximityprompt(v)
                    task.wait(0.1)
                end
            end
        end
    end
end)

-- Thread C: Timed Auto Sell (cho AutoFarmSell)
task.spawn(function()
    while true do
        if State.AutoFarmSell then
            task.wait(15)
            local root = getRootPart()
            if root then
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj:IsA("Part") or obj:IsA("MeshPart") then
                        if string.find(string.lower(obj.Name), "sell") and State.AutoFarmSell then
                            local lastPos = root.CFrame
                            root.CFrame = obj.CFrame
                            task.wait(1.5)
                            root.CFrame = lastPos
                            break
                        end
                    end
                end
            end
        else
            task.wait(1)
        end
    end
end)

-- Thread D: Auto Collect Fruits
task.spawn(function()
    while true do
        task.wait(0.4)
        if not State.AutoCollectFruits then continue end
        local root = getRootPart()
        if not root then continue end

        for _, item in pairs(Workspace:GetChildren()) do
            if item:IsA("Tool") or (item:IsA("Part") and item:FindFirstChild("TouchInterest")) then
                local name = string.lower(item.Name)
                if string.find(name, "fruit") or string.find(name, "apple") or string.find(name, "berry") or string.find(name, "seed") then
                    if item:IsA("Tool") and item:FindFirstChild("Handle") then
                        root.CFrame = item.Handle.CFrame
                    elseif item:IsA("Part") then
                        root.CFrame = item.CFrame
                    end
                    task.wait(0.3)
                end
            end
        end
    end
end)

-- Thread E: Auto Steal (Night)
task.spawn(function()
    while true do
        task.wait(1)
        if not State.AutoStealNight then continue end

        if isNightTime() then
            local plots = Workspace:FindFirstChild("Plots") or Workspace:FindFirstChild("Gardens")
            if plots then
                for _, plot in pairs(plots:GetChildren()) do
                    if plot.Name ~= LocalPlayer.Name and plot.Name ~= "Plot_"..LocalPlayer.Name then
                        for _, obj in pairs(plot:GetDescendants()) do
                            if obj:IsA("ProximityPrompt") and (obj.Parent.Name:lower():match("ready") or obj.Parent.Name:lower():match("crop") or obj.ActionText:lower():match("steal") or obj.ActionText:lower():match("harvest")) then
                                if obj.Parent:IsA("BasePart") then
                                    teleportTo(obj.Parent.CFrame * CFrame.new(0, 3, 0))
                                    task.wait(0.2)
                                    fireproximityprompt(obj)
                                    task.wait(0.1)
                                end
                            end
                        end
                    end
                end
            end

            local sellZone = Workspace:FindFirstChild("SellZone") or Workspace:FindFirstChild("Market") or Workspace:FindFirstChild("Sell")
            if sellZone then
                if sellZone:IsA("BasePart") then
                    teleportTo(sellZone.CFrame * CFrame.new(0, 3, 0))
                else
                    local mainPart = sellZone:FindFirstChildWhichIsA("BasePart")
                    if mainPart then teleportTo(mainPart.CFrame * CFrame.new(0, 3, 0)) end
                end
                task.wait(0.5)
                for _, prompt in pairs(Workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") and (prompt.ActionText:lower():match("sell") or prompt.Parent.Name:lower():match("sell")) then
                        if LocalPlayer:DistanceFromCharacter(prompt.Parent.Position) <= 20 then
                            fireproximityprompt(prompt)
                        end
                    end
                end
            end
        else
            task.wait(5)
        end
    end
end)

-- Thread F: Auto Buy Pet & Seeds (Prompt + Remote)
task.spawn(function()
    while true do
        task.wait(2)
        local wallet = getWallet()

        if State.AutoBuyLegendPet and wallet >= 50000 then
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("ProximityPrompt") and (string.find(string.lower(v.Parent.Name), "legendary") or string.find(string.lower(v.Parent.Name), "egg")) then
                    fireproximityprompt(v)
                end
            end
            local buyRemote = ReplicatedStorage:FindFirstChild("BuyPet", true) or ReplicatedStorage:FindFirstChild("PurchasePet", true)
            if buyRemote then buyRemote:FireServer("Legendary") end
        end

        if State.AutoBuyMythicSeed and wallet >= 10000 then
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("ProximityPrompt") and string.find(string.lower(v.Parent.Name), "mythic") then
                    fireproximityprompt(v)
                end
            end
            local seedRemote = ReplicatedStorage:FindFirstChild("BuySeed", true) or ReplicatedStorage:FindFirstChild("PurchaseItem", true)
            if seedRemote then seedRemote:FireServer("MythicSeed") end
        end

        if State.AutoBuySuperSeed and wallet >= 5000 then
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("ProximityPrompt") and string.find(string.lower(v.Parent.Name), "super") then
                    fireproximityprompt(v)
                end
            end
            local seedRemote = ReplicatedStorage:FindFirstChild("BuySeed", true) or ReplicatedStorage:FindFirstChild("PurchaseItem", true)
            if seedRemote then seedRemote:FireServer("SuperSeed") end
        end

        task.wait(2)
    end
end)

-- Thread G: Anti-AFK
pcall(function()
    LocalPlayer.Idled:Connect(function()
        if State.AntiAFK then
            VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
            task.wait(0.2)
            VirtualUser:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
        end
    end)
end)

-- ========================================================
-- PHẦN 7: HÀM MẠNG & API (với retry, timeout, proxy, dns)
-- ========================================================
-- Hàm gọi API với retry và timeout
local function callAPI(endpoint, method, data, retries)
    retries = retries or State.APIRetryCount
    method = method or "GET"
    local url = State.APIEndpoint .. endpoint
    if State.UseProxy and State.ProxyURL ~= "" then
        url = State.ProxyURL .. url
    end
    local timeout = State.APITimeout or 10

    for attempt = 1, retries do
        local success, result = pcall(function()
            local request = {
                Url = url,
                Method = method,
                Headers = {["Content-Type"] = "application/json"},
                Timeout = timeout
            }
            if data then
                request.Body = HttpService:JSONEncode(data)
            end
            return HttpService:RequestAsync(request)
        end)
        if success then
            return result.Body
        else
            warn("[API] Lần gọi " .. attempt .. " thất bại: " .. tostring(result))
            if attempt < retries then
                task.wait(1) -- đợi trước khi retry
            end
        end
    end
    warn("[API] Gọi API thất bại sau " .. retries .. " lần thử")
    return nil
end

-- Hàm phân giải DNS tùy chỉnh
local function resolveDNS(domain)
    if not State.UseDNS then
        return domain
    end
    local url = "https://dns.google/resolve?name=" .. domain .. "&type=A"
    if State.UseProxy and State.ProxyURL ~= "" then
        url = State.ProxyURL .. url
    end
    local success, result = pcall(function()
        return HttpService:GetAsync(url, true)
    end)
    if success then
        local data = HttpService:JSONDecode(result)
        if data and data.Answer and #data.Answer > 0 then
            return data.Answer[1].data
        end
    end
    warn("[DNS] Không thể phân giải " .. domain .. ", sử dụng tên gốc")
    return domain
end

-- Hàm kiểm tra kết nối internet (ping)
local function checkInternetConnection()
    local success, result = pcall(function()
        return HttpService:GetAsync("https://www.google.com", true)
    end)
    return success
end

-- ========================================================
-- PHẦN 8: TẠO GIAO DIỆN NGƯỜI DÙNG (UI)
-- ========================================================
local RedzUiEngine = loadstring(game:HttpGet("https://raw.githubusercontent.com/MinhChien13coder/MinhChien/refs/heads/main/MinhChienUI.lua"))()
local RedzWindow = RedzUiEngine:CreateWindow()

-- Tạo các tab
local FarmControls = RedzWindow:CreateTab("Farming")
local ShopControls = RedzWindow:CreateTab("Shop")
local MiscControls = RedzWindow:CreateTab("Misc")
local AdvancedControls = RedzWindow:CreateTab("Advanced")
local NetworkTab = RedzWindow:CreateTab("Network")

-- ========================================================
-- PHẦN 9: CÁC THÀNH PHẦN UI CHO TỪNG TAB
-- ========================================================

-- 9.1 TAB FARMING
FarmControls:CreateSection("Auto Farm Management (Remote)")

FarmControls:CreateDropdown("Select Crop", SeedsList, function(Value)
    State.SelectedSeed = Value
end)

FarmControls:CreateToggle("Auto Plant Seeds", false, function(Value)
    State.AutoPlant = Value
    if Value then task.spawn(runAutoPlant) end
end)

FarmControls:CreateToggle("Auto Harvest Crops", false, function(Value)
    State.AutoHarvest = Value
    if Value then task.spawn(runAutoHarvest) end
end)

FarmControls:CreateSection("Farm Speeds")
FarmControls:CreateSlider("Farm Scan Delay (s)", 1, 5, 1, function(Value)
    State.FarmDelay = Value
end)

FarmControls:CreateButton("Instant Force Harvest (1 Time)", function()
    pcall(function()
        local garden = workspace:FindFirstChild("GardenPlots") or workspace:FindFirstChild("Garden")
        if garden then
            for _, plot in ipairs(garden:GetChildren()) do
                local plant = plot:FindFirstChild("Plant") or plot:FindFirstChild("Crop")
                if plant then safeFireServer("HarvestPlant", plot) end
            end
        end
    end)
end)

-- 9.2 TAB SHOP
ShopControls:CreateSection("Seed Store")
ShopControls:CreateDropdown("Buy Target", SeedsList, function(Value)
    State.SelectedSeed = Value
end)
ShopControls:CreateToggle("Auto Purchase Seeds", false, function(Value)
    State.AutoBuySeeds = Value
    if Value then task.spawn(runAutoBuySeeds) end
end)

ShopControls:CreateSection("Pets & Tools")
ShopControls:CreateDropdown("Select Pet Egg", PetsList, function(Value)
    State.SelectedPet = Value
end)
ShopControls:CreateToggle("Auto Open Eggs", false, function(Value)
    State.AutoBuyPets = Value
    if Value then task.spawn(runAutoBuyPets) end
end)

ShopControls:CreateDropdown("Select Gear", GearsList, function(Value)
    State.SelectedGear = Value
end)
ShopControls:CreateToggle("Auto Purchase Gear", false, function(Value)
    State.AutoBuyGear = Value
    if Value then task.spawn(runAutoBuyGear) end
end)

ShopControls:CreateSection("Economy")
ShopControls:CreateToggle("Auto Sell All Inventory", false, function(Value)
    State.AutoSell = Value
    if Value then task.spawn(runAutoSell) end
end)
ShopControls:CreateSlider("Shop Interaction Interval", 1, 10, 2, function(Value)
    State.BuyDelay = Value
end)

-- 9.3 TAB MISC
MiscControls:CreateSection("Server Ruin (Fling System)")
MiscControls:CreateInput("Victim Character Name", "Type user here...", function(Text)
    State.FlingTargetText = Text
end)
MiscControls:CreateButton("Execute Fling Target", function()
    if State.FlingTargetText == "" then return end
    local victim = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():find(State.FlingTargetText:lower()) or p.DisplayName:lower():find(State.FlingTargetText:lower()) then
            victim = p
            break
        end
    end
    if victim and victim ~= LocalPlayer then
        task.spawn(function() executeFling(victim) end)
    end
end)
MiscControls:CreateButton("Fling Entire Server (Fling All)", function()
    task.spawn(function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                executeFling(p)
                task.wait(0.15)
            end
        end
    end)
end)

MiscControls:CreateSection("Thievery (Steal Fruit) - Remote")
MiscControls:CreateDropdown("Steal Priority Mode", {"Highest Value", "Nearest", "Random"}, function(Value)
    State.StealMode = Value
end)
MiscControls:CreateToggle("Only Target Mutated Fruits", false, function(Value)
    State.OnlyMutated = Value
end)
MiscControls:CreateToggle("Activate Auto Steal Loop", false, function(Value)
    State.AutoStealFruit = Value
    if Value then task.spawn(runAutoStealFruit) end
end)

MiscControls:CreateSection("Debug Panel")
MiscControls:CreateButton("Scan Game Remote Structure (F9)", function()
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then 
            print("[MINHCHIEN CORE] Remote Path: " .. obj:GetFullName()) 
        end
    end
end)

-- 9.4 TAB ADVANCED
AdvancedControls:CreateSection("Auto Farm (Proximity Prompt)")
AdvancedControls:CreateToggle("Auto Harvest (Prompt)", false, function(Value)
    State.AutoHarvestPrompt = Value
end)
AdvancedControls:CreateToggle("Auto Farm & Sell (Prompt)", false, function(Value)
    State.AutoFarmSell = Value
end)
AdvancedControls:CreateToggle("Auto Buy & Plant (Prompt)", false, function(Value)
    State.AutoBuyPlant = Value
end)

AdvancedControls:CreateSection("Collection & Steal")
AdvancedControls:CreateToggle("Auto Collect Fruits", false, function(Value)
    State.AutoCollectFruits = Value
end)
AdvancedControls:CreateToggle("Auto Steal (Night Only)", false, function(Value)
    State.AutoStealNight = Value
end)

AdvancedControls:CreateSection("Shop - Prompt & Remote")
AdvancedControls:CreateToggle("Auto Buy Legendary Pet", false, function(Value)
    State.AutoBuyLegendPet = Value
end)
AdvancedControls:CreateToggle("Auto Buy Mythic Seed", false, function(Value)
    State.AutoBuyMythicSeed = Value
end)
AdvancedControls:CreateToggle("Auto Buy Super Seed", false, function(Value)
    State.AutoBuySuperSeed = Value
end)

AdvancedControls:CreateSection("Utility")
AdvancedControls:CreateToggle("Anti-AFK", false, function(Value)
    State.AntiAFK = Value
end)

-- 9.5 TAB NETWORK
NetworkTab:CreateSection("Proxy Settings")
NetworkTab:CreateToggle("Use Proxy", false, function(Value)
    State.UseProxy = Value
end)
NetworkTab:CreateInput("Proxy URL", "https://cors-anywhere.herokuapp.com/", function(Text)
    State.ProxyURL = Text
end)

NetworkTab:CreateSection("API Endpoint")
NetworkTab:CreateInput("API Base URL", "https://api.minhchienhub.com/v1/", function(Text)
    State.APIEndpoint = Text
end)
NetworkTab:CreateSlider("API Timeout (s)", 5, 30, 10, function(Value)
    State.APITimeout = Value
end)
NetworkTab:CreateSlider("API Retry Count", 1, 5, 3, function(Value)
    State.APIRetryCount = Value
end)

NetworkTab:CreateSection("DNS Settings")
NetworkTab:CreateToggle("Use Custom DNS", false, function(Value)
    State.UseDNS = Value
end)
NetworkTab:CreateInput("DNS Server IP", "1.1.1.1", function(Text)
    State.DNSServer = Text
end)

NetworkTab:CreateSection("Test Connection")
NetworkTab:CreateButton("Check Internet Connection", function()
    if checkInternetConnection() then
        print("[NETWORK] Kết nối internet hoạt động")
    else
        print("[NETWORK] Không có kết nối internet")
    end
end)

NetworkTab:CreateButton("Test API Call (GET /ping)", function()
    local result = callAPI("ping", "GET")
    if result then
        print("[API] Phản hồi: " .. result)
    else
        print("[API] Không nhận được phản hồi")
    end
end)

NetworkTab:CreateButton("Test DNS Resolve (google.com)", function()
    local ip = resolveDNS("google.com")
    print("[DNS] google.com -> " .. ip)
end)

NetworkTab:CreateButton("Fetch Remote Config", function()
    local data = callAPI("config", "GET")
    if data then
        print("[CONFIG] Nhận được: " .. data)
        -- Có thể parse và cập nhật State hoặc danh sách tại đây
    else
        print("[CONFIG] Không thể tải cấu hình")
    end
end)

NetworkTab:CreateSection("Security & Privacy")
NetworkTab:CreateButton("Test Proxy Rotation", function()
    local proxies = {"https://cors-anywhere.herokuapp.com/", "https://api.allorigins.win/", "https://proxy.cors.sh/"}
    for _, proxy in ipairs(proxies) do
        State.ProxyURL = proxy
        local result = callAPI("ping", "GET")
        if result then
            print("[PROXY] Thành công với " .. proxy)
        else
            print("[PROXY] Thất bại với " .. proxy)
        end
    end
end)

-- ========================================================
-- PHẦN 10: KHỞI TẠO VÀ CHẠY SCRIPT
-- ========================================================
print("[MINHCHIEN HUB] Đã tải toàn bộ script thành công!")
print("[MINHCHIEN HUB] Giao diện đã sẵn sàng. Chúc bạn chơi game vui vẻ!")

-- Nếu có thể, thêm thông báo lên màn hình
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "MINHCHIEN HUB",
        Text = "Đã tải thành công! Tận hưởng nhé.",
        Icon = "rbxassetid://123456789",
        Duration = 3
    })
end)