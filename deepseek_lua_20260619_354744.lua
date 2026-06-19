repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════════
-- AUTO BOUNTY SCRIPT - FULL FEATURES
-- ═══════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Wrapper an toàn cho remote chính
local function CommF(...)
    local remote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommF_")
    if not remote then return end
    local ok, res = pcall(function(...) return remote:InvokeServer(...) end, ...)
    return ok and res or nil
end

-- ═══════════════════════════════════════════════════════════════════
-- SETTINGS
-- ═══════════════════════════════════════════════════════════════════
getgenv().Setting = getgenv().Setting or {
    ["Team"] = "Pirate",
    ["FlySpeed"] = 360,
    ["AttackDistance"] = 32,
    ["DelaySwitchWeapon"] = 0.4,
    ["Auto Haki"] = true,
    ["Auto Ken"] = true,
    ["Auto PvP"] = true,
    ["Active"] = false,

    ["Max Combat Time"] = 110,

    ["Race V3"] = {["Enable"] = true},
    ["Race V4"] = {["Enable"] = true},

    ["Hunt Method"] = {
        ["Use Move Predict"] = true,
        ["Aimbot"] = true,
        ["ESP Player"] = true,
        ["Orbit Radius"] = 14,
        ["Orbit Speed"] = 2,
        ["Orbit Height"] = 6,
    },

    ["SafeZone"] = {
        ["Enable"] = true,
        ["LowHealth"] = 3500,
        ["MaxHealth"] = 7000,
        ["Teleport Y"] = 7000,
        ["AllowResetInSafeZone"] = true,
        ["IgnoreEnemyInSafeZone"] = true,
        ["SafeZoneRadius"] = 150,
        ["SafeZonePositions"] = {
            Vector3.new(-2566.43, 6.856, 2045.256),  -- Marine
            Vector3.new(-1181.309, 4.751, 3803.546), -- Pirate Village
            Vector3.new(-690.331, 15.094, 1582.238), -- Middle Town
            Vector3.new(-1612.796, 36.852, 149.128), -- Jungle
        },
    },

    ["Auto Server Hop"] = {
        ["Enable"] = true,
        ["NoTargetTimeout"] = 5,
    },

    ["Aim Prediction"] = 0.65,
    ["Ignore Devil Fruit"] = {"Human-Human", "Portal-Portal"},
    ["Spam Dash"] = false,

    ["Weapons"] = {
        ["Melee"] = {
            ["Enable"] = true,
            ["Skills"] = {
                ["Z"] = {["Enable"] = true, ["HoldTime"] = 0.3, ["Number"] = 2},
                ["X"] = {["Enable"] = true, ["HoldTime"] = 0.3, ["Number"] = 3},
                ["C"] = {["Enable"] = true, ["HoldTime"] = 0.3, ["Number"] = 5},
            }
        },
        ["Blox Fruit"] = { ["Enable"] = false },
        ["Sword"] = { ["Enable"] = false },
        ["Gun"] = { ["Enable"] = false },
    },

    ["Kill Aura"] = {
        ["Enable"] = false,
        ["Range"] = 25,
        ["Interval"] = 0.3,
        ["Target"] = "All",
    },

    ["Auto Dodge"] = {
        ["Enable"] = true,
        ["Range"] = 20,
        ["SpeedThreshold"] = 40,
        ["Cooldown"] = 1.5,
        ["TeleportDistance"] = 15,
    },

    ["Reset Teleport"] = {
        ["Enable"] = true,
        ["AutoResetOnFar"] = true,
        ["FarDistance"] = 3000,
        ["MaxRetries"] = 3,
        ["RetryDelay"] = 2,
        ["TeleportOffset"] = 50,
    },

    ["PvP Settings"] = {
        ["Enable"] = true,
        ["CheckInterval"] = 1,
        ["CooldownAfterPvP"] = 5,
    },

    ["Island Teleport"] = {
        ["Enable"] = true,
        ["SelectedIsland"] = "Pirate Village",
    },
}

local cfg = getgenv().Setting

-- ═══════════════════════════════════════════════════════════════════
-- STATE VARIABLES
-- ═══════════════════════════════════════════════════════════════════
local TargetPlayer = nil
local IsInSafeZone = false
local NoTargetTimer = 0
local IsHopping = false
local orbitClock = 0
local lastDodgeTime = 0
local moveTween = nil
local isTeleporting = false
local teleportRetries = 0
local pvpActive = false
local pvpCooldown = 0
local lastPvPCheck = 0

local IgnoredPlayers = {}
local LastTarget = nil
local TargetHpTracker = 0
local DamageTimer = 0
local CombatTimeTracker = 0
local MaxNoDamageTime = 5

-- ═══════════════════════════════════════════════════════════════════
-- ISLAND DATA (for Island Teleport)
-- ═══════════════════════════════════════════════════════════════════
local IslandData = {
    ["Pirate Village"] = CFrame.new(-1181.309, 4.751, 3803.546),
    ["Marine"] = CFrame.new(-2566.43, 6.856, 2045.256),
    ["Middle Town"] = CFrame.new(-690.331, 15.094, 1582.238),
    ["Jungle"] = CFrame.new(-1612.796, 36.852, 149.128),
    ["Desert"] = CFrame.new(944.158, 20.92, 4373.3),
    ["Snow Island"] = CFrame.new(1347.807, 104.668, -1319.737),
    ["MarineFord"] = CFrame.new(-4914.821, 50.964, 4281.028),
    ["Colosseum"] = CFrame.new(-1427.62, 7.288, -2792.772),
    ["Sky Island 1"] = CFrame.new(-4869.103, 733.461, -2667.018),
    ["Prison"] = CFrame.new(4875.33, 5.652, 734.85),
    ["Magma Village"] = CFrame.new(-5247.716, 12.884, 8504.969),
    ["Fountain City"] = CFrame.new(5127.128, 59.501, 4105.446),
    ["Shank Room"] = CFrame.new(-1442.166, 29.879, -28.355),
    ["Mob Island"] = CFrame.new(-2850.201, 7.392, 5354.993),
    ["The Cafe"] = CFrame.new(-380.479, 77.22, 255.826),
    ["Frist Spot"] = CFrame.new(-11.311, 29.277, 2771.522),
    ["Dark Area"] = CFrame.new(3780.03, 22.652, -3498.586),
    ["Flamingo Mansion"] = CFrame.new(-483.734, 332.038, 595.327),
    ["Flamingo Room"] = CFrame.new(2284.414, 15.152, 875.725),
    ["Green Zone"] = CFrame.new(-2448.53, 73.016, -3210.631),
    ["Factory"] = CFrame.new(424.127, 211.162, -427.54),
    ["Colossuim"] = CFrame.new(-1503.622, 219.796, 1369.31),
    ["Zombie Island"] = CFrame.new(-5622.033, 492.196, -781.786),
    ["Two Snow Mountain"] = CFrame.new(753.143, 408.236, -5274.615),
    ["Punk Hazard"] = CFrame.new(-6127.654, 15.952, -5040.286),
    ["Cursed Ship"] = CFrame.new(923.402, 125.057, 32885.875),
    ["Ice Castle"] = CFrame.new(6148.412, 294.387, -6741.117),
    ["Forgotten Island"] = CFrame.new(-3032.764, 317.897, -10075.373),
    ["Ussop Island"] = CFrame.new(4816.862, 8.46, 2863.82),
    ["Mini Sky Island"] = CFrame.new(-288.741, 49326.316, -35248.594),
    ["MiniSky"] = CFrame.new(-288.741, 49326.316, -35248.594),
    ["Great Tree"] = CFrame.new(2681.274, 1682.809, -7190.985),
    ["Port Town"] = CFrame.new(-226.751, 20.603, 5538.34),
    ["Hydra Island"] = CFrame.new(5291.249, 1005.443, 393.762),
    ["Floating Turtle"] = CFrame.new(-13274.528, 531.821, -7579.223),
    ["Haunted Castle"] = CFrame.new(-9515.372, 164.006, 5786.061),
    ["Ice Cream Island"] = CFrame.new(-902.568, 79.932, -10988.848),
    ["Peanut Island"] = CFrame.new(-2062.748, 50.474, -10232.568),
    ["Cake Island"] = CFrame.new(-1884.775, 19.328, -11666.897),
    ["Cocoa Island"] = CFrame.new(87.943, 73.555, -12319.465),
    ["Candy Island"] = CFrame.new(-1014.424, 149.111, -14555.963),
    ["Tiki Outpost"] = CFrame.new(-16218.683, 9.086, 445.618),
    ["Dragon Dojo"] = CFrame.new(5743.319, 1206.91, 936.011),
    -- Remote islands
    ["Sky Island 2"] = function() CommF("requestEntrance", Vector3.new(-4607.823, 872.543, -1667.557)) end,
    ["Sky Island 3"] = function() CommF("requestEntrance", Vector3.new(-7894.618, 5547.142, -380.291)) end,
    ["Under Water Island"] = function() CommF("requestEntrance", Vector3.new(61163.852, 11.68, 1819.784)) end,
    ["Castle On The Sea"] = function() CommF("requestEntrance", Vector3.new(-5083.26, 314.606, -3175.673)) end,
    ["Mansion"] = function() CommF("requestEntrance", Vector3.new(-12471.17, 374.94, -7551.678)) end,
}

-- ═══════════════════════════════════════════════════════════════════
-- GUI
-- ═══════════════════════════════════════════════════════════════════
if CoreGui:FindFirstChild("AutoBounty") then
    CoreGui["AutoBounty"]:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoBounty"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local C = {
    accent = Color3.fromRGB(255, 165, 0),
    bg = Color3.fromRGB(15, 15, 25),
    bg2 = Color3.fromRGB(22, 22, 36),
    white = Color3.fromRGB(240, 240, 240),
    green = Color3.fromRGB(80, 220, 120),
    red = Color3.fromRGB(255, 80, 80),
    yellow = Color3.fromRGB(255, 220, 80),
    blue = Color3.fromRGB(100, 160, 255),
    gray = Color3.fromRGB(130, 130, 140),
    pink = Color3.fromRGB(255, 100, 200),
}

local function MakeDraggable(frame)
    local drag = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            drag = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    drag = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and drag then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local Main = Instance.new("Frame", ScreenGui)
Main.Name = "Main"
Main.Size = UDim2.new(0, 260, 0, 295)
Main.Position = UDim2.new(0.5, -130, 0.5, -148)
Main.BackgroundColor3 = C.bg
Main.Active = true
MakeDraggable(Main)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)
local Stroke = Instance.new("UIStroke", Main)
Stroke.Thickness = 2.5
Stroke.Color = C.accent

local TBar = Instance.new("Frame", Main)
TBar.Size = UDim2.new(1, 0, 0, 40)
TBar.BackgroundColor3 = C.bg2
TBar.BorderSizePixel = 0
Instance.new("UICorner", TBar).CornerRadius = UDim.new(0, 14)

local TTitle = Instance.new("TextLabel", TBar)
TTitle.Size = UDim2.new(1, 0, 1, 0)
TTitle.Text = "Auto Bounty"
TTitle.Font = Enum.Font.GothamBlack
TTitle.TextSize = 12
TTitle.TextColor3 = C.accent
TTitle.BackgroundTransparency = 1

local function MkLabel(y, txt, col)
    local l = Instance.new("TextLabel", Main)
    l.Size = UDim2.new(0.94, 0, 0, 22)
    l.Position = UDim2.new(0.03, 0, 0, y)
    l.BackgroundTransparency = 1
    l.Text = txt
    l.Font = Enum.Font.GothamSemibold
    l.TextSize = 11
    l.TextColor3 = col or C.gray
    l.TextXAlignment = Enum.TextXAlignment.Left
    return l
end

local LblTarget = MkLabel(46, "🎯 Target : Searching...", C.gray)
local LblHP = MkLabel(66, "❤️ HP      : --", C.green)
local LblDist = MkLabel(86, "📍 Dist    : --", C.blue)
local LblHop = MkLabel(106, "🌐 Hop     : --", C.yellow)
local LblStatus = MkLabel(126, "📡 Status  : Idle", C.yellow)
local LblKA = MkLabel(146, "⚔️ KillAura: OFF", C.gray)
local LblDodge = MkLabel(166, "🛡️ Dodge   : OFF", C.gray)
local LblReset = MkLabel(186, "🔄 ResetTP : OFF", C.gray)

-- Island input
local IslandLabel = Instance.new("TextLabel", Main)
IslandLabel.Size = UDim2.new(0.4, 0, 0, 22)
IslandLabel.Position = UDim2.new(0.03, 0, 0, 208)
IslandLabel.BackgroundTransparency = 1
IslandLabel.Text = "🏝️ Island:"
IslandLabel.Font = Enum.Font.GothamSemibold
IslandLabel.TextSize = 11
IslandLabel.TextColor3 = C.white
IslandLabel.TextXAlignment = Enum.TextXAlignment.Left

local IslandInput = Instance.new("TextBox", Main)
IslandInput.Size = UDim2.new(0.42, 0, 0, 22)
IslandInput.Position = UDim2.new(0.35, 0, 0, 208)
IslandInput.BackgroundColor3 = C.bg2
IslandInput.Text = cfg["Island Teleport"]["SelectedIsland"]
IslandInput.Font = Enum.Font.GothamSemibold
IslandInput.TextSize = 11
IslandInput.TextColor3 = C.white
IslandInput.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", IslandInput).CornerRadius = UDim.new(0, 4)

local IslandTPBtn = Instance.new("TextButton", Main)
IslandTPBtn.Size = UDim2.new(0.2, 0, 0, 22)
IslandTPBtn.Position = UDim2.new(0.78, 0, 0, 208)
IslandTPBtn.BackgroundColor3 = C.blue
IslandTPBtn.Text = "🚀 TP"
IslandTPBtn.Font = Enum.Font.GothamBold
IslandTPBtn.TextSize = 10
IslandTPBtn.TextColor3 = C.bg
Instance.new("UICorner", IslandTPBtn).CornerRadius = UDim.new(0, 6)

IslandTPBtn.MouseButton1Click:Connect(function()
    local islandName = IslandInput.Text
    if islandName and islandName ~= "" then
        cfg["Island Teleport"]["SelectedIsland"] = islandName
        TeleportToIsland(islandName)
    end
end)

-- Reset TP button
local ResetBtn = Instance.new("TextButton", Main)
ResetBtn.Size = UDim2.new(0.42, 0, 0, 22)
ResetBtn.Position = UDim2.new(0.03, 0, 0, 235)
ResetBtn.BackgroundColor3 = C.pink
ResetBtn.Text = "🔄 Reset TP"
ResetBtn.Font = Enum.Font.GothamBold
ResetBtn.TextSize = 10
ResetBtn.TextColor3 = C.bg
Instance.new("UICorner", ResetBtn).CornerRadius = UDim.new(0, 6)

ResetBtn.MouseButton1Click:Connect(function()
    if not cfg.Active then return end
    local targetPos
    if TargetPlayer and IsAlive(TargetPlayer) then
        targetPos = TargetPlayer.Character.HumanoidRootPart.Position
    else
        targetPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(0, 0, 30) or Vector3.new(0, 100, 0)
    end
    ResetTeleport(targetPos)
end)

-- Active toggle
local ToggleBtn = Instance.new("TextButton", Main)
ToggleBtn.Size = UDim2.new(0.42, 0, 0, 22)
ToggleBtn.Position = UDim2.new(0.55, 0, 0, 235)
ToggleBtn.BackgroundColor3 = C.green
ToggleBtn.Text = "✅ ACTIVE"
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 10
ToggleBtn.TextColor3 = C.bg
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)

ToggleBtn.MouseButton1Click:Connect(function()
    cfg["Active"] = not cfg["Active"]
    if cfg["Active"] then
        ToggleBtn.BackgroundColor3 = C.green
        ToggleBtn.Text = "✅ ACTIVE"
    else
        ToggleBtn.BackgroundColor3 = C.red
        ToggleBtn.Text = "❌ PAUSED"
        TargetPlayer = nil
        LblTarget.Text = "🎯 Target : Paused"
        LblStatus.Text = "📡 Status  : Paused"
        LblStatus.TextColor3 = C.gray
        if moveTween then moveTween:Cancel(); moveTween = nil end
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════
local function IsAlive(p)
    return p and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 and p.Character:FindFirstChild("HumanoidRootPart")
end

local function SendKey(key, hold)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
        task.wait(hold or 0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    end)
end

local function GetPredicted(hrp)
    if cfg["Hunt Method"]["Use Move Predict"] then
        return hrp.Position + hrp.AssemblyLinearVelocity * cfg["Aim Prediction"]
    end
    return hrp.Position
end

local function CleanIgnored()
    local now = tick()
    for name, expiry in pairs(IgnoredPlayers) do
        if now >= expiry then
            IgnoredPlayers[name] = nil
        end
    end
end

-- ====== KILL AURA REMOTE ======
local function FireAttackRemote(target)
    pcall(function()
        local char = target
        if target:IsA("Player") then
            char = target.Character
        end
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local hrp = char.HumanoidRootPart
        local argsHit = {
            hrp,
            {},
            [4] = "560b7197"
        }
        local net = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Net")
        if not net then return end
        local regHit = net:FindFirstChild("RE/RegisterHit")
        local regAttack = net:FindFirstChild("RE/RegisterAttack")
        if regHit and regAttack then
            regHit:FireServer(unpack(argsHit))
            regAttack:FireServer(0.4000000059604645)
        end
    end)
end

-- ====== ENEMY IN SAFE ZONE CHECK ======
local function IsEnemyInSafeZone(pos)
    if not cfg["SafeZone"]["IgnoreEnemyInSafeZone"] then return false end
    local radius = cfg["SafeZone"]["SafeZoneRadius"] or 150
    for _, safePos in pairs(cfg["SafeZone"]["SafeZonePositions"]) do
        if (pos - safePos).Magnitude <= radius then
            return true
        end
    end
    return false
end

-- ====== TARGET SELECTION ======
local function GetTarget()
    CleanIgnored()
    local best, bestScore = nil, -math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p == LocalPlayer or not IsAlive(p) or not IsAlive(LocalPlayer) then continue end
        if IgnoredPlayers[p.Name] then continue end
        
        -- Bỏ qua nếu địch ở vùng an toàn
        local enemyPos = p.Character.HumanoidRootPart.Position
        if IsEnemyInSafeZone(enemyPos) then
            continue
        end
        
        local ignoredDF = false
        for _, name in pairs(cfg["Ignore Devil Fruit"]) do
            if p.Character:FindFirstChild(name) then
                ignoredDF = true
                break
            end
        end
        if ignoredDF then continue end
        
        local hrp = p.Character.HumanoidRootPart
        local hum = p.Character.Humanoid
        local dist = (hrp.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
        local bounty = p:FindFirstChild("leaderstats") and p.leaderstats:FindFirstChild("Bounty")
        local bountyVal = bounty and bounty.Value or 0
        local score = bountyVal + (hum.MaxHealth - hum.Health) * 10 - dist * 0.5
        if score > bestScore then
            bestScore = score
            best = p
        end
    end
    return best
end

-- ====== EQUIP MELEE ======
local function EquipMelee()
    if not IsAlive(LocalPlayer) then return nil end
    local char = LocalPlayer.Character
    local bp = LocalPlayer.Backpack
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return nil end

    local function isMelee(tool)
        return tool:IsA("Tool") and tool.ToolTip == "Melee"
    end

    for _, v in pairs(char:GetChildren()) do
        if isMelee(v) then
            return v
        end
    end

    for _, v in pairs(bp:GetChildren()) do
        if isMelee(v) then
            hum:UnequipTools()
            task.wait(0.08)
            hum:EquipTool(v)
            return v
        end
    end
    return nil
end

-- ====== PVP CHECK ======
local function CheckPvPStatus()
    local char = LocalPlayer.Character
    if char then
        local pvpPart = char:FindFirstChild("PvP")
        if pvpPart and pvpPart:IsA("BoolValue") then
            return pvpPart.Value
        end
    end
    local attr = LocalPlayer:GetAttribute("PvP")
    if attr ~= nil then return attr end
    return false
end

-- ====== RESET TELEPORT (with retries) ======
local function ResetTeleport(targetPos, isRetry)
    if isTeleporting then return false end
    
    -- Kiểm tra PvP trước khi reset (trừ khi đang ở SafeZone và được phép)
    local allowResetInSafeZone = cfg["SafeZone"]["AllowResetInSafeZone"] or false
    if not (IsInSafeZone and allowResetInSafeZone) then
        if cfg["PvP Settings"]["Enable"] then
            local pvpStatus = CheckPvPStatus()
            if pvpStatus then
                LblStatus.Text = "📡 Status : ⏳ PvP active, can't reset"
                LblStatus.TextColor3 = C.yellow
                return false
            end
            local now = tick()
            if pvpCooldown > now then
                LblStatus.Text = string.format("📡 Status : ⏳ PvP cooldown %.0fs", pvpCooldown - now)
                LblStatus.TextColor3 = C.yellow
                return false
            end
        end
    end

    isTeleporting = true
    local retries = 0
    local maxRetries = cfg["Reset Teleport"]["MaxRetries"] or 5
    local offset = cfg["Reset Teleport"]["TeleportOffset"] or 50
    local farDistance = cfg["Reset Teleport"]["FarDistance"] or 1

    while retries < maxRetries do
        retries = retries + 1
        LblReset.Text = string.format("🔄 ResetTP : Attempt %d/%d", retries, maxRetries)
        LblReset.TextColor3 = C.pink

        -- Tự sát
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.Health = 0
        end

        -- Chờ respawn
        local newChar = nil
        local eventConnection
        eventConnection = LocalPlayer.CharacterAdded:Connect(function(ch)
            newChar = ch
            eventConnection:Disconnect()
        end)
        repeat task.wait() until newChar ~= nil

        local hrp = newChar:FindFirstChild("HumanoidRootPart")
        if hrp then
            -- Tính vị trí đích (có offset)
            local dest = targetPos + Vector3.new(
                math.random(-offset, offset),
                0,
                math.random(-offset, offset)
            )
            -- Dịch chuyển tức thời
            hrp.CFrame = CFrame.new(dest)
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero

            -- Bật noclip cho nhân vật mới
            task.spawn(function()
                for _, part in pairs(newChar:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end)

            -- Giữ vị trí trong 0.2 giây để chống anti-cheat
            local startTime = tick()
            local keepAlive = true
            task.spawn(function()
                while keepAlive and tick() - startTime < 0.2 do
                    if hrp and hrp.Parent then
                        hrp.CFrame = CFrame.new(dest)
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                    end
                    task.wait(0.01)
                end
            end)
            task.wait(0.22)

            -- Kiểm tra khoảng cách đến mục tiêu
            if TargetPlayer and IsAlive(TargetPlayer) then
                local enemyPos = TargetPlayer.Character.HumanoidRootPart.Position
                local dist = (hrp.Position - enemyPos).Magnitude
                if dist <= farDistance then
                    LblReset.Text = "🔄 ResetTP : ✅ Success!"
                    LblReset.TextColor3 = C.green
                    isTeleporting = false
                    return true
                else
                    LblReset.Text = string.format("🔄 ResetTP : ⚠️ Still far (%.0f), retrying...", dist)
                    LblReset.TextColor3 = C.yellow
                    if retries < maxRetries then
                        task.wait(cfg["Reset Teleport"]["RetryDelay"] or 2)
                    end
                end
            else
                LblReset.Text = "🔄 ResetTP : ✅ Success (no target)"
                LblReset.TextColor3 = C.green
                isTeleporting = false
                return true
            end
        else
            if retries < maxRetries then
                task.wait(cfg["Reset Teleport"]["RetryDelay"] or 2)
            end
        end
    end

    LblReset.Text = "🔄 ResetTP : ❌ Failed after " .. maxRetries .. " attempts"
    LblReset.TextColor3 = C.red
    isTeleporting = false
    return false
end

-- ====== TELEPORT TO ISLAND ======
function TeleportToIsland(islandName)
    if not islandName or islandName == "" then return end
    local data = IslandData[islandName]
    if not data then
        print("❌ Không tìm thấy đảo: " .. islandName)
        return
    end
    if type(data) == "function" then
        data()
    elseif type(data) == "CFrame" then
        ResetTeleport(data.Position)
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- NOCLIP - Runs continuously
-- ═══════════════════════════════════════════════════════════════════
task.spawn(function()
    while task.wait(0.1) do
        local char = LocalPlayer.Character
        if not char then continue end
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- SERVER HOP
-- ═══════════════════════════════════════════════════════════════════
local function ServerHop()
    if IsHopping then return end
    IsHopping = true
    LblHop.Text = "🌐 Hop : Searching..."
    LblHop.TextColor3 = C.yellow

    local placeId = game.PlaceId
    local success = false
    for attempt = 1, 8 do
        LblHop.Text = string.format("🌐 Hop : Attempt %d/8", attempt)
        local ok = pcall(TeleportService.Teleport, TeleportService, placeId, LocalPlayer)
        if not ok then
            ok = pcall(TeleportService.Teleport, TeleportService, placeId)
        end
        if ok then
            success = true
            break
        end
        task.wait(2.5)
    end

    LblHop.Text = success and "🌐 Hop : Connecting..." or "🌐 Hop : Failed"
    LblHop.TextColor3 = success and C.green or C.red
    IsHopping = false
end

-- ═══════════════════════════════════════════════════════════════════
-- AUTO TEAM
-- ═══════════════════════════════════════════════════════════════════
task.spawn(function()
    local targetTeamName = cfg["Team"] == "Pirate" and "Pirates" or "Marines"
    while task.wait(3) do
        if not cfg["Active"] then continue end
        local team = LocalPlayer.Team
        if team == nil or team.Name ~= targetTeamName then
            CommF("SetTeam", targetTeamName)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- CHARACTER ADDED - Reset state
-- ═══════════════════════════════════════════════════════════════════
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    TargetPlayer = nil
    LastTarget = nil
    DamageTimer = 0
    CombatTimeTracker = 0
    if moveTween then
        moveTween:Cancel()
        moveTween = nil
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- ANTI AFK
-- ═══════════════════════════════════════════════════════════════════
task.spawn(function()
    while task.wait(55) do
        if cfg["Active"] and IsAlive(LocalPlayer) then
            SendKey("Space", 0.05)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- PLAYER REMOVING
-- ═══════════════════════════════════════════════════════════════════
Players.PlayerRemoving:Connect(function(p)
    IgnoredPlayers[p.Name] = nil
    if p == TargetPlayer then
        TargetPlayer = nil
        LastTarget = nil
        DamageTimer = 0
        CombatTimeTracker = 0
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- ESP
-- ═══════════════════════════════════════════════════════════════════
task.spawn(function()
    while task.wait(1.2) do
        if not cfg["Hunt Method"]["ESP Player"] then continue end
        for _, p in pairs(Players:GetPlayers()) do
            if p == LocalPlayer or not IsAlive(p) then continue end
            local char = p.Character
            local isTarget = (p == TargetPlayer)
            local esp = char:FindFirstChild("BountyESP_V9")
            if not esp then
                esp = Instance.new("Highlight")
                esp.Name = "BountyESP_V9"
                esp.OutlineColor = Color3.fromRGB(255, 255, 255)
                esp.FillTransparency = 0.5
                esp.Parent = char
            end
            esp.FillColor = isTarget and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(50, 100, 255)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- AIMBOT
-- ═══════════════════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function()
    if not cfg["Hunt Method"]["Aimbot"] or not cfg["Active"] then return end
    if not (TargetPlayer and IsAlive(TargetPlayer) and IsAlive(LocalPlayer)) then return end
    local pred = GetPredicted(TargetPlayer.Character.HumanoidRootPart)
    Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, pred)
end)

-- ═══════════════════════════════════════════════════════════════════
-- AUTO HAKI / KEN
-- ═══════════════════════════════════════════════════════════════════
task.spawn(function()
    local kenCooldown = 0
    while task.wait(0.7) do
        if not cfg["Active"] or not IsAlive(LocalPlayer) then continue end
        local char = LocalPlayer.Character
        if cfg["Auto Haki"] then
            local hasBuso = char:FindFirstChild("HasBuso") or char:GetAttribute("HasBuso") or char:GetAttribute("Buso")
            if not hasBuso then
                CommF("Buso")
            end
        end
        if cfg["Auto Ken"] and TargetPlayer and IsAlive(TargetPlayer) then
            if tick() - kenCooldown > 0.5 then
                SendKey("E", 0.05)
                kenCooldown = tick()
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- RACE V3 / V4
-- ═══════════════════════════════════════════════════════════════════
task.spawn(function()
    while task.wait(0.08) do
        if not cfg["Active"] or IsInSafeZone or not TargetPlayer or not IsAlive(TargetPlayer) or not IsAlive(LocalPlayer) then continue end
        local dist = (LocalPlayer.Character.HumanoidRootPart.Position - TargetPlayer.Character.HumanoidRootPart.Position).Magnitude
        if dist <= cfg["Hunt Method"]["Orbit Radius"] + 20 then
            if cfg["Race V4"]["Enable"] then SendKey("Y", 0.05) end
            if cfg["Race V3"]["Enable"] then SendKey("T", 0.05) end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- AUTO PVP
-- ═══════════════════════════════════════════════════════════════════
task.spawn(function()
    while task.wait(3) do
        if cfg["Auto PvP"] and cfg["Active"] and IsAlive(LocalPlayer) then
            pcall(function() CommF("EnablePvp") end)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- KILL AURA LOOP
-- ═══════════════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(cfg.KillAura.Interval or 0.3)
        if not cfg.Active or not cfg.KillAura.Enable or IsInSafeZone then
            LblKA.Text = "⚔️ KillAura: OFF"
            LblKA.TextColor3 = C.gray
            continue
        end
        if not IsAlive(LocalPlayer) then continue end
        LblKA.Text = "⚔️ KillAura: ON"
        LblKA.TextColor3 = C.green

        local myPos = LocalPlayer.Character.HumanoidRootPart.Position
        local targets = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p == LocalPlayer or not IsAlive(p) or IgnoredPlayers[p.Name] then continue end
            local dist = (p.Character.HumanoidRootPart.Position - myPos).Magnitude
            if dist <= cfg.KillAura.Range then
                table.insert(targets, {player = p, dist = dist})
            end
        end
        if #targets == 0 then continue end

        if cfg.KillAura.Target == "Closest" then
            table.sort(targets, function(a, b) return a.dist < b.dist end)
            FireAttackRemote(targets[1].player)
        else
            for _, t in ipairs(targets) do
                FireAttackRemote(t.player)
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- COMBAT LOOP - ONLY MELEE
-- ═══════════════════════════════════════════════════════════════════
local meleeSkills = {"Z", "X", "C", "V", "F"}
local skillCooldowns = {}

local function UseSkill(key, hold, cooldown)
    cooldown = cooldown or 0.6
    local now = tick()
    if skillCooldowns[key] and now - skillCooldowns[key] < cooldown then return end
    SendKey(key, hold or 0.2)
    skillCooldowns[key] = now
end

RunService.Heartbeat:Connect(function(dt)
    if not cfg.Active or IsInSafeZone or not TargetPlayer or not IsAlive(TargetPlayer) then return end
    local myHRP = LocalPlayer.Character.HumanoidRootPart
    local enemyHRP = TargetPlayer.Character.HumanoidRootPart
    local dist = (myHRP.Position - enemyHRP.Position).Magnitude
    if dist > cfg.HuntMethod.OrbitRadius + 18 then return end

    local wData = cfg.Weapons["Melee"]
    if not (wData and wData.Enable) then return end

    local tool = EquipMelee()
    if not tool then return end
    task.wait(0.12)

    for _, skillKey in ipairs(meleeSkills) do
        local sData = wData.Skills[skillKey]
        if not (sData and sData.Enable) then continue end
        if not cfg.Active or IsInSafeZone or not IsAlive(TargetPlayer) then break end

        local curDist = (myHRP.Position - enemyHRP.Position).Magnitude
        if curDist > cfg.HuntMethod.OrbitRadius + 30 then break end

        local repeatCount = sData.Number or 1
        for i = 1, repeatCount do
            if not cfg.Active or IsInSafeZone or not IsAlive(TargetPlayer) then break end
            UseSkill(skillKey, sData.HoldTime, 0.5)
            task.wait(0.08)
        end
        task.wait(0.15)
    end
    task.wait(cfg.DelaySwitchWeapon)
end)

-- ═══════════════════════════════════════════════════════════════════
-- MAIN HUNT LOOP
-- ═══════════════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(0.05)
        if not cfg.Active or not IsAlive(LocalPlayer) then
            if moveTween then
                moveTween:Cancel()
                moveTween = nil
            end
            continue
        end

        local myHum = LocalPlayer.Character.Humanoid
        local myHRP = LocalPlayer.Character.HumanoidRootPart

        -- Reset Velocity
        myHRP.AssemblyLinearVelocity = Vector3.zero
        myHRP.AssemblyAngularVelocity = Vector3.zero

        -- SafeZone handling
        if cfg.SafeZone.Enable then
            if not IsInSafeZone and myHum.Health <= cfg.SafeZone.LowHealth then
                IsInSafeZone = true
                TargetPlayer = nil
                if moveTween then
                    moveTween:Cancel()
                    moveTween = nil
                end
                LblStatus.Text = "📡 Status : ⚠️ SafeZone!"
                LblStatus.TextColor3 = C.red
            elseif IsInSafeZone and myHum.Health >= cfg.SafeZone.MaxHealth then
                IsInSafeZone = false
                LblStatus.Text = "📡 Status : 🏹 Hunting"
                LblStatus.TextColor3 = C.green
            end
        end

        if IsInSafeZone then
            myHRP.CFrame = CFrame.new(0, cfg.SafeZone.TeleportY, 0)
            continue
        end

        -- PvP check
        if cfg["PvP Settings"]["Enable"] then
            local now = tick()
            if now - lastPvPCheck > cfg["PvP Settings"]["CheckInterval"] then
                pvpActive = CheckPvPStatus()
                lastPvPCheck = now
                if pvpActive then
                    pvpCooldown = now + cfg["PvP Settings"]["CooldownAfterPvP"]
                end
            end
            if pvpActive then
                LblStatus.Text = "📡 Status : ⚔️ PvP Active"
                LblStatus.TextColor3 = C.red
            elseif pvpCooldown > now then
                LblStatus.Text = string.format("📡 Status : ⏳ PvP Cooldown %.0fs", pvpCooldown - now)
                LblStatus.TextColor3 = C.yellow
            end
        end

        -- Select target
        if not TargetPlayer or not IsAlive(TargetPlayer) then
            TargetPlayer = GetTarget()
            NoTargetTimer = NoTargetTimer + 0.05
            if TargetPlayer then
                LastTarget = TargetPlayer
                TargetHpTracker = TargetPlayer.Character.Humanoid.Health
                DamageTimer = 0
                CombatTimeTracker = 0
            end
        else
            NoTargetTimer = 0
        end

        -- Server hop
        if cfg.AutoServerHop.Enable and (NoTargetTimer > cfg.AutoServerHop.NoTargetTimeout or #Players:GetPlayers() < 4) then
            if not IsHopping then
                NoTargetTimer = 0
                if moveTween then
                    moveTween:Cancel()
                    moveTween = nil
                end
                task.spawn(ServerHop)
            end
        end

        -- Reset Teleport tự động (cho phép nếu đang ở SafeZone và được cấu hình)
        local allowResetInSafeZone = cfg["SafeZone"]["AllowResetInSafeZone"] or false
        local canReset = true
        if IsInSafeZone and not allowResetInSafeZone then
            canReset = false
        end
        if cfg["PvP Settings"]["Enable"] then
            local now = tick()
            if pvpActive or pvpCooldown > now then
                canReset = false
            end
        end

        if canReset and cfg["Reset Teleport"]["Enable"] and cfg["Reset Teleport"]["AutoResetOnFar"] and TargetPlayer and IsAlive(TargetPlayer) and not isTeleporting then
            local enemyPos = TargetPlayer.Character.HumanoidRootPart.Position
            local distToTarget = (myHRP.Position - enemyPos).Magnitude
            if distToTarget > cfg["Reset Teleport"]["FarDistance"] then
                LblStatus.Text = "📡 Status : 🔄 Teleporting to enemy..."
                LblStatus.TextColor3 = C.pink
                if moveTween then
                    moveTween:Cancel()
                    moveTween = nil
                end
                local success = ResetTeleport(enemyPos, true)
                if success then
                    LblStatus.Text = "📡 Status : ✅ Teleported! Approaching..."
                    LblStatus.TextColor3 = C.green
                    task.wait(0.2)
                else
                    LblStatus.Text = "📡 Status : ❌ Teleport failed, retrying later"
                    LblStatus.TextColor3 = C.red
                    task.wait(2)
                end
                continue
            end
        end

        -- Auto Dodge
        if cfg.AutoDodge.Enable and TargetPlayer and IsAlive(TargetPlayer) then
            local now = tick()
            if now - lastDodgeTime >= cfg.AutoDodge.Cooldown then
                local targetHRP = TargetPlayer.Character.HumanoidRootPart
                local targetVel = targetHRP.AssemblyLinearVelocity
                local speed = targetVel.Magnitude
                if speed > cfg.AutoDodge.SpeedThreshold then
                    local dirToTarget = (myHRP.Position - targetHRP.Position).Unit
                    local targetDir = targetVel.Unit
                    if targetDir:Dot(dirToTarget) > 0.5 then
                        local randomAngle = math.rad(math.random(0, 360))
                        local offset = Vector3.new(
                            math.cos(randomAngle),
                            0,
                            math.sin(randomAngle)
                        ) * cfg.AutoDodge.TeleportDistance
                        local newPos = myHRP.Position + offset
                        newPos = Vector3.new(newPos.X, myHRP.Position.Y, newPos.Z)
                        myHRP.CFrame = CFrame.new(newPos)
                        if moveTween then
                            moveTween:Cancel()
                            moveTween = nil
                        end
                        lastDodgeTime = now
                        LblDodge.Text = "🛡️ Dodge : ✅ Dodged!"
                        LblDodge.TextColor3 = C.green
                    end
                end
            end
            LblDodge.Text = "🛡️ Dodge : ON"
            LblDodge.TextColor3 = C.green
        else
            LblDodge.Text = cfg.AutoDodge.Enable and "🛡️ Dodge : ON" or "🛡️ Dodge : OFF"
            LblDodge.TextColor3 = cfg.AutoDodge.Enable and C.green or C.gray
        end

        -- Update Reset TP status
        if cfg["Reset Teleport"]["Enable"] then
            LblReset.Text = "🔄 ResetTP : ON"
            LblReset.TextColor3 = C.green
        else
            LblReset.Text = "🔄 ResetTP : OFF"
            LblReset.TextColor3 = C.gray
        end

        if TargetPlayer and IsAlive(TargetPlayer) then
            local enemyHRP = TargetPlayer.Character.HumanoidRootPart
            local enemyHum = TargetPlayer.Character.Humanoid
            local predictPos = GetPredicted(enemyHRP)
            local dist = (myHRP.Position - enemyHRP.Position).Magnitude

            -- Combat time limit
            CombatTimeTracker = CombatTimeTracker + 0.05
            if CombatTimeTracker >= cfg.MaxCombatTime then
                IgnoredPlayers[TargetPlayer.Name] = tick() + 300
                TargetPlayer = nil
                LastTarget = nil
                DamageTimer = 0
                CombatTimeTracker = 0
                if moveTween then
                    moveTween:Cancel()
                    moveTween = nil
                end
                continue
            end

            -- Damage check
            if dist <= cfg.HuntMethod.OrbitRadius + 18 then
                DamageTimer = DamageTimer + 0.05
                if enemyHum.Health < TargetHpTracker then
                    TargetHpTracker = enemyHum.Health
                    DamageTimer = 0
                end
                if DamageTimer >= 5 then
                    IgnoredPlayers[TargetPlayer.Name] = tick() + 60
                    TargetPlayer = nil
                    LastTarget = nil
                    DamageTimer = 0
                    CombatTimeTracker = 0
                    if moveTween then
                        moveTween:Cancel()
                        moveTween = nil
                    end
                    continue
                end
            else
                DamageTimer = math.max(0, DamageTimer - 0.05)
            end

            -- Update UI
            LblTarget.Text = "🎯 Target : " .. TargetPlayer.Name
            LblHP.Text = string.format("❤️ HP : %.0f/%.0f", enemyHum.Health, enemyHum.MaxHealth)
            LblDist.Text = string.format("📍 Dist : %.1f", dist)
            if not pvpActive and pvpCooldown <= tick() then
                LblStatus.Text = DamageTimer > 1 and string.format("📡 Check PvP: %.1fs", 5 - DamageTimer) or "📡 Status : 🏹 Hunting"
                LblStatus.TextColor3 = DamageTimer > 1 and C.yellow or C.green
            end

            -- Tween movement
            orbitClock = orbitClock + 0.05 * cfg.HuntMethod.OrbitSpeed
            local offset = Vector3.new(
                math.cos(orbitClock) * cfg.HuntMethod.OrbitRadius,
                cfg.HuntMethod.OrbitHeight,
                math.sin(orbitClock) * cfg.HuntMethod.OrbitRadius
            )
            local targetPos = predictPos + offset

            local distanceToTarget = (myHRP.Position - targetPos).Magnitude
            if distanceToTarget > 2 then
                if moveTween then
                    moveTween:Cancel()
                    moveTween = nil
                end
                local speedFactor = (dist > 45) and 1.5 or 1.0
                local tweenTime = math.max(0.1, distanceToTarget / (cfg.FlySpeed * speedFactor))
                moveTween = TweenService:Create(myHRP, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {Position = targetPos})
                moveTween:Play()
                moveTween.Completed:Connect(function()
                    moveTween = nil
                end)
            else
                myHRP.Position = targetPos
                if moveTween then
                    moveTween:Cancel()
                    moveTween = nil
                end
            end

            if cfg.SpamDash then
                CommF("Dash")
            end

        else
            LblTarget.Text = "🎯 Target : Searching..."
            LblHP.Text = "❤️ HP      : --"
            LblDist.Text = "📍 Dist    : --"
            local remaining = math.max(0, cfg.AutoServerHop.NoTargetTimeout - NoTargetTimer)
            if not pvpActive and pvpCooldown <= tick() then
                LblStatus.Text = string.format("📡 No target (hop in %.0fs)", remaining)
                LblStatus.TextColor3 = C.yellow
            end
        end
    end
end)nd)