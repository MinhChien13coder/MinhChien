local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

_G.AutoBounty = false
_G.KillAura = false   
_G.AttackDistance = 6 
_G.TweenSpeed = 250   
_G.WeaponToUse = "Melee" 

_G.AimMethod = false             
local ABmethod = "Auto Aimbots"  
local MousePos = Vector3.new()   
_G.AimCam = false

_G.AutoDodge = false
_G.IsDodging = false
_G.CurrentTarget = nil

_G.WeaponConfig = {
    ["Weapons"] = {
        ["Melee"] = {
            ["Enable"] = false, 
            ["Skills"] = {
                ["Z"] = {["Enable"] = true, ["HoldTime"] = 0.3, ["Number"] = 1},
                ["X"] = {["Enable"] = true, ["HoldTime"] = 0.3, ["Number"] = 3},
                ["C"] = {["Enable"] = true, ["HoldTime"] = 0.3, ["Number"] = 2},
            },
        }
    }
}

local StartBounty = 0
local BountyGained = 0
local LabelCurrentBounty
local LabelBountyGained

local function getPlayerBounty()
    local b = LocalPlayer:FindFirstChild("leaderstats") and (LocalPlayer.leaderstats:FindFirstChild("Bounty") or LocalPlayer.leaderstats:FindFirstChild("Honor"))
    return b and b.Value or 0
end
StartBounty = getPlayerBounty()

-- ==========================================
-- TỰ ĐỘNG GIA NHẬP HẢI TẶC
-- ==========================================
task.spawn(function()
    while true do
        task.wait(1)
        if LocalPlayer.Team == nil or tostring(LocalPlayer.Team) == "Choosing" or tostring(LocalPlayer.Team) == "" then
            pcall(function()
                game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("SetTeam", "Pirates")
            end)
        else
            break
        end
    end
end)

-- ==========================================
-- KIỂM TRA VÙNG AN TOÀN
-- ==========================================
local function CheckSafeZone(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return true end
    local char = targetPlayer.Character
    if char:GetAttribute("SafeZone") or char:GetAttribute("InSafeZone") or char:GetAttribute("PvPDisabled") then
        return true
    end
    if char:FindFirstChildOfClass("ForceField") then
        return true
    end
    return false
end

-- ==========================================
-- HÀM XẢ CHIÊU - FIX: xoay character về phía target trước khi fire
-- ==========================================
local function UseSkillKey(keyName, holdTime)
    local keyCode = Enum.KeyCode[keyName]
    if keyCode then
        pcall(function()
            -- FIX AIM SKILL: xoay HRP nhìn về phía target trước khi xả skill
            if _G.CurrentTarget and _G.CurrentTarget.Character then
                local targetRoot = _G.CurrentTarget.Character:FindFirstChild("HumanoidRootPart")
                local myChar = LocalPlayer.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if myRoot and targetRoot then
                    myRoot.CFrame = CFrame.new(
                        myRoot.Position,
                        Vector3.new(targetRoot.Position.X, myRoot.Position.Y, targetRoot.Position.Z)
                    )
                end
            end
            VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
            task.wait(holdTime)
            VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
        end)
    end
end

-- ==========================================
-- ATTACK REMOTE - FIX: FindFirstChild (không WaitForChild) + VirtualUser backup
-- ==========================================
local function FireAttackRemote(targetChar)
    pcall(function()
        if not targetChar then return end
        local hrp = targetChar:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        -- FIX: FindFirstChild thay WaitForChild - tránh treo vĩnh viễn
        local rs = game:GetService("ReplicatedStorage")
        local Net = rs:FindFirstChild("Modules") and rs.Modules:FindFirstChild("Net")
        local HitRemote = Net and Net:FindFirstChild("RE/RegisterHit")
        local AttackRemote = Net and Net:FindFirstChild("RE/RegisterAttack")

        if HitRemote then
            HitRemote:FireServer(hrp, {}, nil, "560b7197")
        end
        if AttackRemote then
            AttackRemote:FireServer(0.4000000059604645)
        end
    end)

    -- FIX KILL AURA: backup VirtualUser click khi remote không có
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(0, 0))
    end)
end

-- ==========================================
-- DI CHUYỂN BYPASS
-- ==========================================
local function bypassMove(targetCFrame)
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    
    local startCFrame = myRoot.CFrame
    local distance = (startCFrame.Position - targetCFrame.Position).Magnitude
    local duration = distance / _G.TweenSpeed
    local startTime = os.clock()
    
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Parent = myRoot
    
    local bodyGyro = Instance.new("BodyGyro")
    bodyGyro.CFrame = targetCFrame
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.P = 9000
    bodyGyro.Parent = myRoot

    local noclipConn
    noclipConn = RunService.Stepped:Connect(function()
        if myChar then
            for _, part in pairs(myChar:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
        myRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        myRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end)
    
    while os.clock() - startTime < duration and _G.AutoBounty and not _G.IsDodging do
        local alpha = math.clamp((os.clock() - startTime) / duration, 0, 1)
        myRoot.CFrame = startCFrame:Lerp(targetCFrame, alpha)
        RunService.Heartbeat:Wait()
    end
    
    if _G.AutoBounty and not _G.IsDodging then
        myRoot.CFrame = targetCFrame
    end
    
    bodyVelocity:Destroy()
    bodyGyro:Destroy()
    noclipConn:Disconnect()
end

-- ==========================================
-- AIMBOT HOOK (nil-safe)
-- ==========================================
pcall(function()
    local MetaTable = getrawmetatable and getrawmetatable(game)
    if MetaTable then
        local OldIndex = MetaTable.__index
        if setreadonly then setreadonly(MetaTable, false) end
        local wrapFn = newcclosure or function(f) return f end
        MetaTable.__index = wrapFn(function(self, index)
            if _G.AimMethod and index == "Hit" and self:IsA("Mouse") then
                return CFrame.new(MousePos)
            end
            return OldIndex(self, index)
        end)
        if setreadonly then setreadonly(MetaTable, true) end
    end
end)

task.spawn(function()
    while task.wait() do
        pcall(function()
            if _G.AimMethod and ABmethod == "AimBots Skill" then
                if _G.CurrentTarget and _G.CurrentTarget.Character and _G.CurrentTarget.Character:FindFirstChild("HumanoidRootPart") then
                    if not CheckSafeZone(_G.CurrentTarget) then
                        MousePos = _G.CurrentTarget.Character.HumanoidRootPart.Position
                    end
                end
            end
        end)
    end
end)

task.spawn(function()
    while task.wait() do
        pcall(function()
            if _G.AimMethod and ABmethod == "Auto Aimbots" then
                local MaxDistance = math.huge
                for _, v in pairs(Players:GetPlayers()) do
                    if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                        if v.Team ~= LocalPlayer.Team and not CheckSafeZone(v) then
                            local Distance = LocalPlayer:DistanceFromCharacter(v.Character.HumanoidRootPart.Position)
                            if Distance < MaxDistance then
                                MaxDistance = Distance
                                MousePos = v.Character.HumanoidRootPart.Position
                            end
                        end
                    end
                end
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(0.01) do
        pcall(function()
            if _G.AimCam then
                local function getClosestPlayerForCam()
                    if _G.AutoBounty and _G.CurrentTarget and _G.CurrentTarget.Character and _G.CurrentTarget.Character:FindFirstChild("HumanoidRootPart") then
                        if not CheckSafeZone(_G.CurrentTarget) then
                            return _G.CurrentTarget
                        end
                    end
                    local dist = math.huge
                    local target = nil
                    for _, v in next, Players:GetPlayers() do
                        if v ~= LocalPlayer and v.Team ~= LocalPlayer.Team then
                            if v.Character and v.Character:FindFirstChild("Head") and v.Character:FindFirstChild("Humanoid") then
                                local hum = v.Character.Humanoid
                                -- FIX: .Parent check
                                if hum.Parent and hum.Health > 0 and not CheckSafeZone(v) then
                                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then
                                        local Mag = (v.Character.Head.Position - LocalPlayer.Character.Head.Position).Magnitude
                                        if Mag < dist then
                                            dist = Mag
                                            target = v
                                        end
                                    end
                                end
                            end
                        end
                    end
                    return target
                end
                local targetPlayer = getClosestPlayerForCam()
                if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPlayer.Character.HumanoidRootPart.Position)
                end
            end
        end)
    end
end)

-- ==========================================
-- GUI
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BloxBountyHub"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 320, 0, 395)
MainFrame.Position = UDim2.new(0.5, -160, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
Title.Text = "MINH CHIEN - BOUNTY"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 15
Title.Parent = MainFrame

local TabStatsBtn = Instance.new("TextButton")
TabStatsBtn.Size = UDim2.new(0, 95, 0, 30)
TabStatsBtn.Position = UDim2.new(0, 10, 0, 45)
TabStatsBtn.Text = "Thống Kê"
TabStatsBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
TabStatsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TabStatsBtn.Font = Enum.Font.SourceSansBold
TabStatsBtn.Parent = MainFrame

local TabConfigBtn = Instance.new("TextButton")
TabConfigBtn.Size = UDim2.new(0, 95, 0, 30)
TabConfigBtn.Position = UDim2.new(0, 110, 0, 45)
TabConfigBtn.Text = "Cấu Hình"
TabConfigBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
TabConfigBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
TabConfigBtn.Font = Enum.Font.SourceSansBold
TabConfigBtn.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 95, 0, 30)
ToggleBtn.Position = UDim2.new(0, 215, 0, 45)
ToggleBtn.Text = "BẬT"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.Parent = MainFrame

local StatsFrame = Instance.new("Frame")
StatsFrame.Size = UDim2.new(1, -20, 1, -90)
StatsFrame.Position = UDim2.new(0, 10, 0, 80)
StatsFrame.BackgroundTransparency = 1
StatsFrame.Parent = MainFrame

local ConfigFrame = Instance.new("Frame")
ConfigFrame.Size = UDim2.new(1, -20, 1, -90)
ConfigFrame.Position = UDim2.new(0, 10, 0, 80)
ConfigFrame.BackgroundTransparency = 1
ConfigFrame.Visible = false
ConfigFrame.Parent = MainFrame

LabelCurrentBounty = Instance.new("TextLabel")
LabelCurrentBounty.Size = UDim2.new(1, 0, 0, 25)
LabelCurrentBounty.Position = UDim2.new(0, 0, 0, 10)
LabelCurrentBounty.BackgroundTransparency = 1
LabelCurrentBounty.Text = "Bounty Hiện Tại: " .. StartBounty
LabelCurrentBounty.TextColor3 = Color3.fromRGB(220, 220, 220)
LabelCurrentBounty.TextXAlignment = Enum.TextXAlignment.Left
LabelCurrentBounty.Font = Enum.Font.SourceSans
LabelCurrentBounty.TextSize = 16
LabelCurrentBounty.Parent = StatsFrame

LabelBountyGained = Instance.new("TextLabel")
LabelBountyGained.Size = UDim2.new(1, 0, 0, 25)
LabelBountyGained.Position = UDim2.new(0, 0, 0, 40)
LabelBountyGained.BackgroundTransparency = 1
LabelBountyGained.Text = "Bounty Nhận Được: 0"
LabelBountyGained.TextColor3 = Color3.fromRGB(220, 220, 220)
LabelBountyGained.TextXAlignment = Enum.TextXAlignment.Left
LabelBountyGained.Font = Enum.Font.SourceSans
LabelBountyGained.TextSize = 16
LabelBountyGained.Parent = StatsFrame

local function createConfigInput(labelTxt, defaultVal, posy, callback)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 160, 0, 30)
    lbl.Position = UDim2.new(0, 0, 0, posy)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelTxt
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.SourceSans
    lbl.TextSize = 15
    lbl.Parent = ConfigFrame
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 100, 0, 25)
    box.Position = UDim2.new(0, 180, 0, posy)
    box.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Text = tostring(defaultVal)
    box.Font = Enum.Font.SourceSans
    box.TextSize = 14
    box.Parent = ConfigFrame
    box.FocusLost:Connect(function() callback(box.Text) end)
end

createConfigInput("Tốc độ bay (Tween):", _G.TweenSpeed, 5, function(val) _G.TweenSpeed = tonumber(val) or 250 end)
createConfigInput("Loại vũ khí (Melee/Sword):", _G.WeaponToUse, 35, function(val) _G.WeaponToUse = val end)

local AimToggleBtn = Instance.new("TextButton")
AimToggleBtn.Size = UDim2.new(0, 280, 0, 28)
AimToggleBtn.Position = UDim2.new(0, 0, 0, 70)
AimToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
AimToggleBtn.Text = "Aim Đòn Đánh: TẮT"
AimToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AimToggleBtn.Font = Enum.Font.SourceSansBold
AimToggleBtn.TextSize = 14
AimToggleBtn.Parent = ConfigFrame
AimToggleBtn.MouseButton1Click:Connect(function()
    _G.AimMethod = not _G.AimMethod
    AimToggleBtn.Text = _G.AimMethod and "Aim Đòn Đánh: BẬT" or "Aim Đòn Đánh: TẮT"
    AimToggleBtn.BackgroundColor3 = _G.AimMethod and Color3.fromRGB(60, 180, 60) or Color3.fromRGB(200, 60, 60)
end)

local AimMethodBtn = Instance.new("TextButton")
AimMethodBtn.Size = UDim2.new(0, 280, 0, 28)
AimMethodBtn.Position = UDim2.new(0, 0, 0, 105)
AimMethodBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
AimMethodBtn.Text = "Chế độ: " .. ABmethod
AimMethodBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
AimMethodBtn.Font = Enum.Font.SourceSansBold
AimMethodBtn.TextSize = 14
AimMethodBtn.Parent = ConfigFrame
AimMethodBtn.MouseButton1Click:Connect(function()
    ABmethod = (ABmethod == "Auto Aimbots") and "AimBots Skill" or "Auto Aimbots"
    AimMethodBtn.Text = "Chế độ: " .. ABmethod
end)

local AimCamToggleBtn = Instance.new("TextButton")
AimCamToggleBtn.Size = UDim2.new(0, 280, 0, 28)
AimCamToggleBtn.Position = UDim2.new(0, 0, 0, 140)
AimCamToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
AimCamToggleBtn.Text = "Aimbot Camera: TẮT"
AimCamToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AimCamToggleBtn.Font = Enum.Font.SourceSansBold
AimCamToggleBtn.TextSize = 14
AimCamToggleBtn.Parent = ConfigFrame
AimCamToggleBtn.MouseButton1Click:Connect(function()
    _G.AimCam = not _G.AimCam
    AimCamToggleBtn.Text = _G.AimCam and "Aimbot Camera: BẬT" or "Aimbot Camera: TẮT"
    AimCamToggleBtn.BackgroundColor3 = _G.AimCam and Color3.fromRGB(60, 180, 60) or Color3.fromRGB(200, 60, 60)
end)

local KillAuraToggleBtn = Instance.new("TextButton")
KillAuraToggleBtn.Size = UDim2.new(0, 280, 0, 28)
KillAuraToggleBtn.Position = UDim2.new(0, 0, 0, 175)
KillAuraToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
KillAuraToggleBtn.Text = "Kill Aura Người Chơi: TẮT"
KillAuraToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
KillAuraToggleBtn.Font = Enum.Font.SourceSansBold
KillAuraToggleBtn.TextSize = 14
KillAuraToggleBtn.Parent = ConfigFrame
KillAuraToggleBtn.MouseButton1Click:Connect(function()
    _G.KillAura = not _G.KillAura
    KillAuraToggleBtn.Text = _G.KillAura and "Kill Aura Người Chơi: BẬT" or "Kill Aura Người Chơi: TẮT"
    KillAuraToggleBtn.BackgroundColor3 = _G.KillAura and Color3.fromRGB(60, 180, 60) or Color3.fromRGB(200, 60, 60)
end)

local SkillMeleeToggleBtn = Instance.new("TextButton")
SkillMeleeToggleBtn.Size = UDim2.new(0, 280, 0, 28)
SkillMeleeToggleBtn.Position = UDim2.new(0, 0, 0, 210)
SkillMeleeToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
SkillMeleeToggleBtn.Text = "Auto Skill Melee: TẮT"
SkillMeleeToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SkillMeleeToggleBtn.Font = Enum.Font.SourceSansBold
SkillMeleeToggleBtn.TextSize = 14
SkillMeleeToggleBtn.Parent = ConfigFrame
SkillMeleeToggleBtn.MouseButton1Click:Connect(function()
    _G.WeaponConfig.Weapons.Melee.Enable = not _G.WeaponConfig.Weapons.Melee.Enable
    SkillMeleeToggleBtn.Text = _G.WeaponConfig.Weapons.Melee.Enable and "Auto Skill Melee: BẬT" or "Auto Skill Melee: TẮT"
    SkillMeleeToggleBtn.BackgroundColor3 = _G.WeaponConfig.Weapons.Melee.Enable and Color3.fromRGB(60, 180, 60) or Color3.fromRGB(200, 60, 60)
end)

local DodgeToggleBtn = Instance.new("TextButton")
DodgeToggleBtn.Size = UDim2.new(0, 280, 0, 28)
DodgeToggleBtn.Position = UDim2.new(0, 0, 0, 245)
DodgeToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
DodgeToggleBtn.Text = "Auto Né Skill Đối Thủ: TẮT"
DodgeToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DodgeToggleBtn.Font = Enum.Font.SourceSansBold
DodgeToggleBtn.TextSize = 14
DodgeToggleBtn.Parent = ConfigFrame
DodgeToggleBtn.MouseButton1Click:Connect(function()
    _G.AutoDodge = not _G.AutoDodge
    DodgeToggleBtn.Text = _G.AutoDodge and "Auto Né Skill Đối Thủ: BẬT" or "Auto Né Skill Đối Thủ: TẮT"
    DodgeToggleBtn.BackgroundColor3 = _G.AutoDodge and Color3.fromRGB(60, 180, 60) or Color3.fromRGB(200, 60, 60)
end)

TabStatsBtn.MouseButton1Click:Connect(function()
    StatsFrame.Visible = true; ConfigFrame.Visible = false
    TabStatsBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    TabConfigBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
end)
TabConfigBtn.MouseButton1Click:Connect(function()
    StatsFrame.Visible = false; ConfigFrame.Visible = true
    TabConfigBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    TabStatsBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
end)
ToggleBtn.MouseButton1Click:Connect(function()
    _G.AutoBounty = not _G.AutoBounty
    ToggleBtn.Text = _G.AutoBounty and "TẮT" or "BẬT"
    ToggleBtn.BackgroundColor3 = _G.AutoBounty and Color3.fromRGB(60, 180, 60) or Color3.fromRGB(200, 60, 60)
end)

-- ==========================================
-- VÒNG LẶP NÉ SKILL
-- ==========================================
local lastDodgeTime = 0
task.spawn(function()
    while true do
        task.wait(0.05)
        if _G.AutoBounty and _G.AutoDodge and _G.CurrentTarget then
            local target = _G.CurrentTarget
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                local targetRoot = target.Character.HumanoidRootPart
                local targetHumanoid = target.Character:FindFirstChildOfClass("Humanoid")
                local myChar = LocalPlayer.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                -- FIX: .Parent check
                if targetHumanoid and targetHumanoid.Parent and myRoot
                    and not _G.IsDodging and (os.clock() - lastDodgeTime > 0.6) then
                    local isCasting = #targetHumanoid:GetPlayingAnimationTracks() > 0
                    if isCasting then
                        local toMeDirection = (myRoot.Position - targetRoot.Position).Unit
                        local dotProduct = targetRoot.CFrame.LookVector:Dot(toMeDirection)
                        local distance = (myRoot.Position - targetRoot.Position).Magnitude
                        if dotProduct > 0.7 and distance < 40 then
                            _G.IsDodging = true
                            lastDodgeTime = os.clock()
                            local dodgeOffsets = {
                                CFrame.new(22, 0, 0),
                                CFrame.new(-22, 0, 0),
                                CFrame.new(0, 0, 20)
                            }
                            myRoot.CFrame = targetRoot.CFrame * dodgeOffsets[math.random(1, 3)]
                            task.wait(0.3)
                            _G.IsDodging = false
                        end
                    end
                end
            end
        end
    end
end)

-- ==========================================
-- VÒNG LẶP AUTO SKILL MELEE
-- ==========================================
task.spawn(function()
    while true do
        task.wait(0.1)
        if _G.AutoBounty and _G.WeaponConfig.Weapons.Melee.Enable and _G.CurrentTarget and not _G.IsDodging then
            local target = _G.CurrentTarget
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                -- FIX: .Parent check trước .Health
                if humanoid and humanoid.Parent and humanoid.Health > 0 and myRoot and not CheckSafeZone(target) then
                    local dist = (myRoot.Position - target.Character.HumanoidRootPart.Position).Magnitude
                    if dist <= 40 then
                        local skillQueue = {}
                        for key, config in pairs(_G.WeaponConfig.Weapons.Melee.Skills) do
                            if config.Enable then
                                table.insert(skillQueue, {Key = key, HoldTime = config.HoldTime, Number = config.Number})
                            end
                        end
                        table.sort(skillQueue, function(a, b) return a.Number < b.Number end)
                        for _, skill in ipairs(skillQueue) do
                            -- FIX: .Parent check trong điều kiện break
                            if not _G.AutoBounty or not _G.WeaponConfig.Weapons.Melee.Enable
                                or not target.Parent or not humanoid.Parent or humanoid.Health <= 0
                                or CheckSafeZone(target) or _G.IsDodging then
                                break
                            end
                            UseSkillKey(skill.Key, skill.HoldTime)
                            task.wait(0.15)
                        end
                        task.wait(1)
                    end
                end
            end
        end
    end
end)

-- ==========================================
-- KILL AURA LOOP - FIX: FindFirstChild + .Parent check
-- ==========================================
task.spawn(function()
    while true do
        task.wait(0.05)
        if _G.KillAura and _G.AutoBounty and _G.CurrentTarget then
            local target = _G.CurrentTarget
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
                -- FIX: .Parent check trước .Health - tránh "Instance has been destroyed"
                if humanoid and humanoid.Parent and humanoid.Health > 0 and not CheckSafeZone(target) then
                    FireAttackRemote(target.Character)
                end
            end
        end
    end
end)

-- ==========================================
-- HỖ TRỢ
-- ==========================================
local function ensureKenHaki()
    if _G.AutoBounty and LocalPlayer.Character and not _G.IsDodging then
        if not LocalPlayer.Character:FindFirstChild("HasKenHaki") then
            pcall(function()
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                task.wait(0.1)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
            end)
        end
    end
end

local function equipWeapon()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local character = LocalPlayer.Character
    if backpack and character and not _G.IsDodging then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and tool:FindFirstChild("ToolTip") then
                if tool.ToolTip == _G.WeaponToUse then
                    pcall(function()
                        character:FindFirstChildOfClass("Humanoid"):EquipTool(tool)
                    end)
                    break
                end
            end
        end
    end
end

-- getValidTarget - FIX: .Parent check trước .Health
local function getValidTarget()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            -- FIX: check .Parent trước để tránh lỗi khi Humanoid đã bị Destroy
            if humanoid and humanoid.Parent and humanoid.Health > 0 and player.Team ~= LocalPlayer.Team then
                if not CheckSafeZone(player) and player.Character.HumanoidRootPart.Position.Y > -100 then
                    return player
                end
            end
        end
    end
    return nil
end

-- Cập nhật bounty stats
task.spawn(function()
    while task.wait(1) do
        if _G.AutoBounty then
            local current = getPlayerBounty()
            if current > 0 then
                BountyGained = current - StartBounty
                LabelCurrentBounty.Text = "Bounty Hiện Tại: " .. current
                LabelBountyGained.Text = "Bounty Nhận Được: " .. BountyGained
            end
        end
    end
end)

-- ==========================================
-- VÒNG LẶP CHÍNH - FIX QUAN TRỌNG NHẤT
-- Thay nested while bằng flat loop
-- Refresh target mỗi iteration → không bao giờ bị stuck sau kill
-- ==========================================
task.spawn(function()
    while true do
        if not _G.AutoBounty then
            task.wait(0.3)
        else
            -- FIX: luôn lấy target mới mỗi vòng, không giữ ref cũ
            local target = getValidTarget()
            _G.CurrentTarget = target

            if target and target.Character then
                local myChar = LocalPlayer.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                local targetChar = target.Character
                local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")

                -- FIX: .Parent check trước .Health → tránh "Instance has been destroyed"
                local isAlive = targetHumanoid
                    and targetHumanoid.Parent ~= nil
                    and targetHumanoid.Health > 0

                if myRoot and targetRoot and isAlive and not _G.IsDodging and not CheckSafeZone(target) then
                    equipWeapon()
                    ensureKenHaki()

                    local targetPos = targetRoot.CFrame * CFrame.new(0, _G.AttackDistance, 0)
                    local dist = (myRoot.Position - targetPos.Position).Magnitude

                    if dist > 15 then
                        bypassMove(targetPos)
                    else
                        myRoot.CFrame = targetPos
                        myRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        myRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

                        if not _G.KillAura then
                            pcall(function()
                                VirtualUser:CaptureController()
                                VirtualUser:ClickButton1(Vector2.new(0, 0))
                            end)
                        end

                        RunService.Heartbeat:Wait()
                    end
                else
                    RunService.Heartbeat:Wait()
                end
            else
                task.wait(0.4) -- không có target, thử lại sau
            end
        end
    end
end)
