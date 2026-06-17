local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Khai báo cấu hình toàn cục
if not getgenv()._G then getgenv()._G = {} end
getgenv()._G.AutoDooHee = false
getgenv()._G.TweenMGear = false
getgenv()._G.KillAura = false          -- Bật/tắt Kill Aura (cả quái và người)
getgenv()._G.AutoKillV4 = false
getgenv()._G.AutoQuestRace = false
getgenv()._G.AutoHopFullMoon = false
getgenv()._G.SelectWeapon = nil
getgenv()._G.MovementMethod = "Tween"  -- Tùy chọn mặc định: Tween hoặc Teleport
getgenv()._G.FriendsList = {}          -- Danh sách bạn bè để ngoại trừ (Whitelist)

local Pos = CFrame.new(0, 40, 0)
local ATTACK_DELAY = 0.01 -- Cải thiện tốc độ mô phỏng giữ nút liên tục

--- ========================================================
--- HỆ THỐNG BYPASS ANTI-CHEAT
--- ========================================================

pcall(function()
    if typeof(getrawmetatable) == "function" then
        local gmt = getrawmetatable(game)
        setreadonly(gmt, false)
        local oldNamecall = gmt.__namecall

        gmt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "Kick" or method == "kick" then
                return nil
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(gmt, true)
    end
end)

local SpoofActive = true
pcall(function()
    if typeof(hookmetamethod) == "function" then
        local oldIndex
        oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
            if SpoofActive and not checkcaller() and self:IsA("Humanoid")
                and LocalPlayer.Character and self:IsDescendantOf(LocalPlayer.Character) then
                if key == "WalkSpeed" then return 16 end
                if key == "PlatformStand" then return false end
                if key == "HipHeight" then return 0 end
            end
            return oldIndex(self, key)
        end))
    end
end)

local function AutoNukeAntiCheat()
    pcall(function()
        if typeof(getconnections) == "function" then
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local hum = char:WaitForChild("Humanoid", 5) or char:FindFirstChildOfClass("Humanoid")
            if hum then
                local signals = {"Changed", "GetPropertyChangedSignal"}
                for _, sigName in pairs(signals) do
                    local signal = (sigName == "Changed") and hum.Changed or hum:GetPropertyChangedSignal("WalkSpeed")
                    for _, connection in pairs(getconnections(signal)) do
                        connection:Disable()
                    end
                end
            end
        end
    end)
end

task.spawn(AutoNukeAntiCheat)
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    AutoNukeAntiCheat()
end)

local function SendNotification(title, text, duration)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = duration or 4})
    end)
end

--- ========================================================
--- HÀM GÂY SÁT THƯƠNG QUA REMOTE
--- ========================================================
local function FireAttackRemote(targetEnemy)
    pcall(function()
        if targetEnemy and targetEnemy:FindFirstChild("HumanoidRootPart") then
            local argsHit = {
                targetEnemy:WaitForChild("HumanoidRootPart"),
                {},
                [4] = "560b7197"
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Net"):WaitForChild("RE/RegisterHit"):FireServer(unpack(argsHit))

            local argsAttack = { 0.4000000059604645 }
            game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Net"):WaitForChild("RE/RegisterAttack"):FireServer(unpack(argsAttack))
        end
    end)
end

--- ========================================================
--- HỆ THỐNG DI CHUYỂN AN TOÀN - FIX GIẬT VỀ
--- ========================================================
local function SafeMove(targetCFrame)
    pcall(function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not root or not hum then return end

        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end

        if getgenv()._G.MovementMethod == "Tween" then
            -- Tính toán thời gian dựa trên tốc độ (Tránh Anti-cheat quét lùi)
            local dist = (root.Position - targetCFrame.Position).Magnitude
            local speed = 300 
            local tweenTime = dist / speed
            if tweenTime < 0.1 then tweenTime = 0.1 end 
            
            local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear)
            local tween = TweenService:Create(root, tweenInfo, {CFrame = targetCFrame})
            hum:ChangeState(Enum.HumanoidStateType.Physics)
            tween:Play()
            tween.Completed:Wait()
            hum:ChangeState(Enum.HumanoidStateType.Running)
        else
            -- Kỹ thuật Teleport chống lùi (Anchor & Reset State)
            hum:ChangeState(Enum.HumanoidStateType.Physics)
            root.Anchored = true
            task.wait(0.05)
            root.CFrame = targetCFrame
            task.wait(0.05)
            root.Anchored = false
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end)
end

--- ========================================================
--- HỆ THỐNG HOP SERVER
--- ========================================================
local function HopServer()
    SendNotification("Hệ thống", "Đang quét Server qua Proxy...", 3)

    local PlaceID = game.PlaceId
    local AllIDs = {}
    local actualHour = os.date("!*t").hour

    local fileSuccess, fileContent = pcall(function() return readfile("NotSameServers.json") end)
    if fileSuccess and fileContent then
        pcall(function() AllIDs = HttpService:JSONDecode(fileContent) end)
    end

    if #AllIDs == 0 or tonumber(AllIDs[1]) ~= tonumber(actualHour) then
        AllIDs = {actualHour}
        pcall(function() writefile("NotSameServers.json", HttpService:JSONEncode(AllIDs)) end)
    end

    local cursor = ""
    local hopped = false

    for page = 1, 10 do
        if hopped then break end

        local url = 'https://games.roproxy.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Asc&limit=100'
        if cursor ~= "" then
            url = url .. '&cursor=' .. cursor
        end

        local httpOk, httpResult = pcall(function() return game:HttpGet(url) end)
        if not httpOk or not httpResult then
            task.wait(0.5)
            break
        end

        local decodeOk, site = pcall(function() return HttpService:JSONDecode(httpResult) end)
        if not decodeOk or not site or not site.data then break end

        cursor = (site.nextPageCursor and site.nextPageCursor ~= "null") and site.nextPageCursor or ""

        for _, v in pairs(site.data) do
            if hopped then break end

            local id = tostring(v.id)
            local currentPlayers = tonumber(v.playing)
            local maxPlayers = tonumber(v.maxPlayers)

            if id ~= game.JobId and currentPlayers and maxPlayers
                and currentPlayers < maxPlayers and currentPlayers >= 1 then

                local isOld = false
                for _, existing in pairs(AllIDs) do
                    if id == tostring(existing) then
                        isOld = true
                        break
                    end
                end

                if not isOld then
                    table.insert(AllIDs, id)
                    pcall(function() writefile("NotSameServers.json", HttpService:JSONEncode(AllIDs)) end)

                    SendNotification("Tìm thấy!", "Đang chuyển server...", 3)
                    task.wait(0.3)

                    local teleOptions = Instance.new("TeleportOptions")
                    teleOptions.ServerInstanceId = id

                    local ok, _ = pcall(function()
                        TeleportService:TeleportAsync(PlaceID, {LocalPlayer}, teleOptions)
                    end)

                    if ok then
                        hopped = true
                        break
                    else
                        SendNotification("Bỏ qua", "Server bị chặn, thử tiếp...", 2)
                        task.wait(0.3)
                    end
                end
            end
        end

        if cursor == "" then break end
        task.wait(0.3)
    end

    if not hopped then
        SendNotification("Cứu hộ", "Đang cưỡng chế đổi server...", 3)
        task.wait(0.5)
        pcall(function()
            TeleportService:Teleport(PlaceID, LocalPlayer)
        end)
    end
end

local function AutoHaki()
    pcall(function()
        if not LocalPlayer.Character:FindFirstChild("HasBuso") then
            ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
        end
    end)
end

local function EquipWeapon(weaponName)
    pcall(function()
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        local character = LocalPlayer.Character
        if backpack and character then
            if weaponName and backpack:FindFirstChild(weaponName) then
                backpack[weaponName].Parent = character
            elseif not character:FindFirstChildOfClass("Tool") then
                local tool = backpack:FindFirstChildOfClass("Tool")
                if tool then tool.Parent = character end
            end
        end
    end)
end

local function EquipByToolTip(toolTipType)
    pcall(function()
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        local character = LocalPlayer.Character
        if backpack and character then
            for _, tool in pairs(backpack:GetChildren()) do
                if tool:IsA("Tool") and tool.ToolTip == toolTipType then
                    character.Humanoid:EquipTool(tool)
                    break
                end
            end
        end
    end)
end

--- ========================================================
--- GIAO DIỆN NGƯỜI DÙNG (UI)
--- ========================================================

if LocalPlayer.PlayerGui:FindFirstChild("MinhChien") then
    LocalPlayer.PlayerGui.MinhChien:Destroy()
end

local ScreenGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
ScreenGui.Name = "MinhChien"
ScreenGui.ResetOnSpawn = false

local function Drag(gui)
    local drag, input, start, pos
    gui.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = true; start = i.Position; pos = gui.Position
        end
    end)
    gui.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then input = i end
    end)
    RunService.RenderStepped:Connect(function()
        if drag and input then
            local d = input.Position - start
            gui.Position = UDim2.new(pos.X.Scale, pos.X.Offset + d.X, pos.Y.Scale, pos.Y.Offset + d.Y)
        end
    end)
end

local Icon = Instance.new("Frame", ScreenGui)
Icon.Size = UDim2.new(0, 60, 0, 60)
Icon.Position = UDim2.new(0, 10, 0, 7)
Icon.BackgroundColor3 = Color3.new(0, 0, 0)
Icon.Active = true
Drag(Icon)
Instance.new("UICorner", Icon).CornerRadius = UDim.new(1, 0)

local IconStroke = Instance.new("UIStroke", Icon)
IconStroke.Thickness = 3
task.spawn(function() while task.wait(0.01) do IconStroke.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1) end end)

local Img = Instance.new("ImageLabel", Icon)
Img.Size = UDim2.new(0.9, 0, 0.9, 0)
Img.Position = UDim2.new(0.05, 0, 0.05, 0)
Img.Image = "rbxassetid://74840524656036"
Img.BackgroundTransparency = 1
Instance.new("UICorner", Img).CornerRadius = UDim.new(1, 0)

local IconBtn = Instance.new("TextButton", Icon)
IconBtn.Size = UDim2.new(1, 0, 1, 0)
IconBtn.BackgroundTransparency = 1
IconBtn.Text = ""

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 240, 0, 480)
Main.Position = UDim2.new(0.5, -120, 0.2, 0)
Main.BackgroundColor3 = Color3.fromRGB(5, 5, 10)
Main.Visible = false
Main.Active = true
Drag(Main)

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Thickness = 3
task.spawn(function() while task.wait(0.01) do MainStroke.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1) end end)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "MINHCHIEN HUB V4"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 14
Title.BackgroundTransparency = 1

local Holder = Instance.new("ScrollingFrame", Main)
Holder.Size = UDim2.new(0.9, 0, 0.85, 0)
Holder.Position = UDim2.new(0.05, 0, 0.12, 0)
Holder.BackgroundTransparency = 1
Holder.CanvasSize = UDim2.new(0, 0, 6.5, 0)
Holder.ScrollBarThickness = 2

local Layout = Instance.new("UIListLayout", Holder)
Layout.Padding = UDim.new(0, 8)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

IconBtn.Activated:Connect(function() Main.Visible = not Main.Visible end)

local function CreateToggle(text, startState, callback)
    local Btn = Instance.new("TextButton", Holder)
    Btn.Size = UDim2.new(0.9, 0, 0, 40)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 12
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)
    local state = startState
    local function updateVisual()
        if state then
            Btn.BackgroundColor3 = Color3.fromRGB(0, 150, 70)
            Btn.Text = text .. ": [BẬT]"
            Btn.TextColor3 = Color3.new(1, 1, 1)
        else
            Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            Btn.Text = text .. ": [TẮT]"
            Btn.TextColor3 = Color3.fromRGB(180, 180, 180)
        end
    end
    updateVisual()
    Btn.MouseButton1Click:Connect(function() state = not state; updateVisual(); callback(state) end)
    return Btn
end

local function CreateButton(text, callback)
    local Btn = Instance.new("TextButton", Holder)
    Btn.Size = UDim2.new(0.9, 0, 0, 40)
    Btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 12
    Btn.Text = text
    Btn.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)
    Btn.MouseButton1Click:Connect(function()
        Btn.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
        task.wait(0.1)
        Btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    end)
    Btn.MouseButton1Click:Connect(callback)
    return Btn
end

--- ========================================================
--- ĐĂNG KÝ CÁC CHỨC NĂNG VÀO MENU UI
--- ========================================================

CreateToggle("Kiểu di chuyển: TWEEN", true, function(bool)
    if bool then
        getgenv()._G.MovementMethod = "Tween"
    else
        getgenv()._G.MovementMethod = "Teleport"
    end
end)

-- Tạo ô nhập Username bạn bè cần Bypass
local FriendBox = Instance.new("TextBox", Holder)
FriendBox.Size = UDim2.new(0.9, 0, 0, 35)
FriendBox.PlaceholderText = "Nhập tên Player cần tha..."
FriendBox.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
FriendBox.TextColor3 = Color3.new(1, 1, 1)
FriendBox.Font = Enum.Font.Gotham
FriendBox.TextSize = 11
Instance.new("UICorner", FriendBox).CornerRadius = UDim.new(0, 5)

CreateButton("Thêm bạn bè vào danh sách", function()
    local name = FriendBox.Text
    if name ~= "" then
        table.insert(getgenv()._G.FriendsList, name)
        SendNotification("Whitelist", "Đã chừa ra: " .. name, 3)
        FriendBox.Text = ""
    end
end)

CreateToggle("Auto Hop Full Moon", getgenv()._G.AutoHopFullMoon, function(bool)
    getgenv()._G.AutoHopFullMoon = bool
end)

CreateButton("Check Full Moon Hiện Tại", function()
    pcall(function()
        local sky = game:GetService("Lighting"):FindFirstChildOfClass("Sky")
        if sky then
            local moonId = tostring(sky.MoonTextureId)
            if string.find(moonId, "9709149431") then
                SendNotification("✅ Check", "ĐANG CÓ TRĂNG TRÒN!", 5)
            else
                SendNotification("❌ Check", "CHƯA CÓ trăng tròn.", 5)
            end
        else
            SendNotification("❌ Check", "Không tìm thấy Sky.", 5)
        end
    end)
end)

CreateToggle("Look Moon + V3", getgenv()._G.AutoDooHee, function(bool) getgenv()._G.AutoDooHee = bool end)
CreateToggle("Auto Tween To Gear", getgenv()._G.TweenMGear, function(bool) getgenv()._G.TweenMGear = bool end)
CreateToggle("Kill Aura (Mobs + Người)", getgenv()._G.KillAura, function(bool) getgenv()._G.KillAura = bool end)
CreateToggle("Auto Kill Player Trial", getgenv()._G.AutoKillV4, function(bool) getgenv()._G.AutoKillV4 = bool end)
CreateToggle("Auto Trial All Race", getgenv()._G.AutoQuestRace, function(bool) getgenv()._G.AutoQuestRace = bool end)

CreateButton("Teleport To Top GreatTree", function()
    pcall(function() SafeMove(CFrame.new(3030.39453125, 2280.6171875, -7320.18359375)) end)
end)

CreateButton("Teleport Lever Pull", function()
    pcall(function() SafeMove(CFrame.new(28575.181640625, 14936.6279296875, 72.31636810302734)) end)
end)

CreateButton("Teleport Temple Of Time", function()
    pcall(function() SafeMove(CFrame.new(28286.35546875, 14895.3017578125, 102.62469482421875)) end)
end)

CreateButton("Buy Ancient One Quest", function()
    pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("UpgradeRace", "Buy") end)
end)

CreateButton("Auto Race Door", function()
    pcall(function()
        local character = LocalPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            SafeMove(CFrame.new(28286.35546875, 14895.3017578125, 102.62469482421875))
            task.wait(1.5)
            local raceValue = LocalPlayer.Data.Race.Value
            if raceValue == "Human" then
                SafeMove(CFrame.new(29221.822265625, 14890.9755859375, -205.99114990234375))
            elseif raceValue == "Skypiea" then
                SafeMove(CFrame.new(28960.158203125, 14919.6240234375, 235.03948974609375))
            elseif raceValue == "Fishman" then
                SafeMove(CFrame.new(28231.17578125, 14890.9755859375, -211.64173889160156))
            elseif raceValue == "Cyborg" then
                SafeMove(CFrame.new(28502.681640625, 14895.9755859375, -423.7279357910156))
            elseif raceValue == "Ghoul" then
                SafeMove(CFrame.new(28674.244140625, 14890.6767578125, 445.4310607910156))
            elseif raceValue == "Mink" then
                SafeMove(CFrame.new(29012.341796875, 14890.9755859375, -380.1492614746094))
            end
        end
    end)
end)

--- ========================================================
--- CÁC VÒNG LẶP XỬ LÝ (LOOPS)
--- ========================================================

-- Luồng Auto Hop Full Moon
task.spawn(function()
    while true do
        task.wait(2)
        if getgenv()._G.AutoHopFullMoon then
            pcall(function()
                local lighting = game:GetService("Lighting")
                local sky = lighting:FindFirstChildOfClass("Sky")
                if not sky then
                    sky = lighting:WaitForChild("Sky", 15)
                end
                if sky then
                    task.wait(2)
                    local moonId = tostring(sky.MoonTextureId)
                    if string.find(moonId, "9709149431") then
                        getgenv()._G.AutoHopFullMoon = false
                        SendNotification("✅ THÀNH CÔNG", "Server này ĐANG CÓ TRĂNG TRÒN!", 10)
                    else
                        SendNotification("🔍 Tìm kiếm", "Chưa có trăng, đang đổi server...", 3)
                        HopServer()
                        task.wait(12)
                    end
                end
            end)
        end
    end
end)

-- Luồng Look Moon + TỰ ĐỘNG BẬT TỘC V3
task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(function()
            if getgenv()._G.AutoDooHee and LocalPlayer.Character then
                local moonDir = game.Lighting:GetMoonDirection()
                local targetPos = game.Workspace.CurrentCamera.CFrame.p + moonDir * 100
                game.Workspace.CurrentCamera.CFrame = CFrame.lookAt(game.Workspace.CurrentCamera.CFrame.p, targetPos)
                local args = { "ActivateAbility" }
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommE"):FireServer(unpack(args))
            end
        end)
    end
end)

-- Luồng Tween Mystic Island Gear
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if getgenv()._G.TweenMGear and game:GetService("Workspace").Map:FindFirstChild("MysticIsland") then
                for _, object in pairs(game:GetService("Workspace").Map.MysticIsland:GetChildren()) do
                    if object:IsA("MeshPart") and object.Material == Enum.Material.Neon then
                        SafeMove(object.CFrame)
                        task.wait(0.5)
                    end
                end
            end
        end)
    end
end)

-- Luồng Kill Aura (PvE + PvP có lọc bạn bè)
task.spawn(function()
    while task.wait(ATTACK_DELAY) do
        pcall(function()
            if getgenv()._G.KillAura then
                local character = LocalPlayer.Character
                local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                local tool = character and character:FindFirstChildOfClass("Tool")
                if rootPart and tool then
                    local closestTarget = nil
                    local closestDist = 65

                    -- Quét quái trong Enemies
                    local enemiesFolder = game:GetService("Workspace"):FindFirstChild("Enemies")
                    if enemiesFolder then
                        for _, enemy in pairs(enemiesFolder:GetChildren()) do
                            local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
                            local enemyHuman = enemy:FindFirstChild("Humanoid")
                            if enemyRoot and enemyHuman and enemyHuman.Health > 0 then
                                local dist = (rootPart.Position - enemyRoot.Position).Magnitude
                                if dist < closestDist then
                                    closestDist = dist
                                    closestTarget = enemy
                                end
                            end
                        end
                    end

                    -- Quét người chơi trong Characters (Lọc trừ bản thân và bạn bè)
                    local charactersFolder = game:GetService("Workspace"):FindFirstChild("Characters")
                    if charactersFolder then
                        for _, targetPlayer in pairs(charactersFolder:GetChildren()) do
                            if targetPlayer.Name ~= LocalPlayer.Name and not table.find(getgenv()._G.FriendsList, targetPlayer.Name) then
                                local enemyRoot = targetPlayer:FindFirstChild("HumanoidRootPart")
                                local enemyHuman = targetPlayer:FindFirstChild("Humanoid")
                                if enemyRoot and enemyHuman and enemyHuman.Health > 0 then
                                    local dist = (rootPart.Position - enemyRoot.Position).Magnitude
                                    if dist < closestDist then
                                        closestDist = dist
                                        closestTarget = targetPlayer
                                    end
                                end
                            end
                        end
                    end

                    if closestTarget then
                        FireAttackRemote(closestTarget)
                    end
                end
            end
        end)
    end
end)

-- Luồng PvP Auto Kill Player Trial (Có check danh sách ngoại lệ bạn bè)
task.spawn(function()
    while task.wait(0.2) do
        if getgenv()._G.AutoKillV4 then
            pcall(function()
                local charsFolder = game.Workspace:FindFirstChild("Characters")
                if charsFolder then
                    for _, targetPlayer in pairs(charsFolder:GetChildren()) do
                        -- Kiểm tra nếu người chơi này không nằm trong danh sách bạn bè
                        if targetPlayer.Name ~= LocalPlayer.Name and not table.find(getgenv()._G.FriendsList, targetPlayer.Name) then
                            local enemyHuman = targetPlayer:FindFirstChild("Humanoid")
                            local enemyRoot = targetPlayer:FindFirstChild("HumanoidRootPart")
                            local enemyHead = targetPlayer:FindFirstChild("Head")
                            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

                            if enemyHuman and enemyRoot and enemyHead and myRoot and enemyHuman.Health > 0 then
                                if (myRoot.Position - enemyRoot.Position).Magnitude <= 230 then
                                    repeat
                                        task.wait(ATTACK_DELAY)
                                        AutoHaki()
                                        EquipWeapon(getgenv()._G.SelectWeapon)
                                        SafeMove(enemyRoot.CFrame * CFrame.new(1, 1, 2))
                                        enemyRoot.Size = Vector3.new(60, 60, 60)
                                        enemyRoot.CanCollide = false
                                        enemyHead.CanCollide = false
                                        enemyHuman.WalkSpeed = 0
                                        FireAttackRemote(targetPlayer)
                                    until not getgenv()._G.AutoKillV4 or enemyHuman.Health <= 0
                                        or not targetPlayer.Parent or not targetPlayer:FindFirstChild("HumanoidRootPart")
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- Luồng Auto Quest Trial các Tộc
task.spawn(function()
    while task.wait(0.5) do
        if getgenv()._G.AutoQuestRace then
            pcall(function()
                local currentRace = LocalPlayer.Data.Race.Value
                if currentRace == "Human" or currentRace == "Ghoul" then
                    local enemies = game.Workspace:FindFirstChild("Enemies")
                    if enemies then
                        for _, enemy in pairs(enemies:GetDescendants()) do
                            if enemy:FindFirstChild("Humanoid") and enemy:FindFirstChild("HumanoidRootPart")
                                and enemy.Humanoid.Health > 0 then
                                repeat
                                    task.wait(0.2)
                                    enemy.Humanoid.Health = 0
                                    enemy.HumanoidRootPart.CanCollide = false
                                until not getgenv()._G.AutoQuestRace or not enemy.Parent or enemy.Humanoid.Health <= 0
                            end
                        end
                    end
                elseif currentRace == "Skypiea" then
                    local skyTrialModel = game:GetService("Workspace").Map:FindFirstChild("SkyTrial")
                        and game:GetService("Workspace").Map.SkyTrial:FindFirstChild("Model")
                    if skyTrialModel then
                        for _, part in pairs(skyTrialModel:GetDescendants()) do
                            if part.Name == "snowisland_Cylinder.081" then SafeMove(part.CFrame) end
                        end
                    end
                elseif currentRace == "Cyborg" then
                    SafeMove(CFrame.new(28654, 14898.7832, -30))
                elseif currentRace == "Mink" then
                    for _, part in pairs(game:GetService("Workspace"):GetDescendants()) do
                        if part.Name == "StartPoint" then
                            SafeMove(part.CFrame * CFrame.new(0, 3, 0))
                            getgenv()._G.AutoQuestRace = false
                        end
                    end
                elseif currentRace == "Fishman" then
                    local seaBeasts = game:GetService("Workspace"):FindFirstChild("SeaBeasts")
                        and game:GetService("Workspace").SeaBeasts:FindFirstChild("SeaBeast1")
                    if seaBeasts then
                        for _, part in pairs(seaBeasts:GetDescendants()) do
                            if part.Name == "HumanoidRootPart" then
                                SafeMove(part.CFrame * Pos)
                                EquipByToolTip("Melee")
                                EquipByToolTip("Blox Fruit")
                                EquipByToolTip("Sword")
                                EquipByToolTip("Gun")
                            end
                        end
                    end
                end
            end)
        end
    end
end)