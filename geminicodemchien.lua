-- ================= KHỞI TẠO BẢO VỆ & AN TOÀN SERVICE =================
local function SafeGetService(serviceName)
    local success, service = pcall(game.GetService, game, serviceName)
    if success and service then
        if cloneref then return cloneref(service) end
        return service
    end
end

local RunService = SafeGetService("RunService")
local Players = SafeGetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = SafeGetService("UserInputService")
local TweenService = SafeGetService("TweenService")
local TeleportService = SafeGetService("TeleportService")
local HttpService = SafeGetService("HttpService")

-- ================= ANTI BAN / KICK PLUS+ (CHẠY NGẦM) =================
pcall(function()
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
end)

local SpoofActive = true
pcall(function()
    if hookmetamethod then
        local oldIndex
        oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
            if SpoofActive and not checkcaller() and self:IsA("Humanoid") and LocalPlayer.Character and self:IsDescendantOf(LocalPlayer.Character) then
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
        if getconnections then
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

local BypassTP = true

local function SecureTween(targetCFrame, speed)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        local distance = (root.Position - targetCFrame.Position).Magnitude
        if distance > 150 then
            root.CFrame = root.CFrame * CFrame.new(0, 80, 0)
            task.wait(0.06)
        end
        local duration = distance / speed
        local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
        tween:Play()
        return tween
    end
end

local function topos(targetPart)
    SecureTween(targetPart.CFrame * CFrame.new(0, 4, 0), 150)
end

local function BTP(targetPart)
    SecureTween(targetPart.CFrame * CFrame.new(0, 4, 0), 55)
end

-- ================= CẤU HÌNH THÔNG SỐ (SETTINGS) =================
local customSpeed = 130 
local flySpeed = 120
local spinSpeed = 55 
local currentLanguage = "VI"

-- ================= HỆ THỐNG ĐA NGÔN NGỮ (LOCALIZATION) =================
local LangConfig = {
    VI = {
        mainTab = "MAIN",
        toolTab = "CÔNG CỤ",
        settingsTab = "CÀI ĐẶT",
        selectTarget = "CHỌN MỤC TIÊU: KHÔNG CÓ",
        targetSelected = "MỤC TIÊU: ",
        speedHack = "TỐC ĐỘ CHẠY",
        noclip = "XUYÊN TƯỜNG",
        telePlayer = "TELE TO PLAYER",
        bringPlayer = "BRING PLAYER",
        esp = "HIỂN THỊ NGƯỜI CHƠI",
        fly = "BAY",
        autoWin = "TỰ ĐỘNG THẮNG",
        infJump = "NHẢY VÔ HẠN",
        autoParkour = "TỰ ĐỘNG PARKOUR",
        spinBot = "XOAY VÒNG VÒNG",
        forceSit = "TỰ ĐỘNG NGỒI",
        runSpeedSlider = "TỐC ĐỘ CHẠY",
        flySpeedSlider = "TỐC ĐỘ BAY",
        changeLangBtn = "NGÔN NGỮ:TIẾNG VIỆT",
        serverHop = "ĐỔI SERVER KHÁC",
        rejoinServer = "VÀO LẠI SERVER CŨ",
        tpToolBtn = "NHẬN GẬY CLICK TP",
        petModeBtnOn = "BÁM LƯNG BẠN NỮ: ON",
        petModeBtnOff = "BÁM LƯNG BẠN NỮ: OFF",
        copyToolsBtn = "COPY ĐỒ MỤC TIÊU",
        openDexBtn = "MỞ DARK DEX",
        openSpyBtn = "MỞ REMOTE SPY"
    },
    EN = {
        mainTab = "MAIN",
        toolTab = "TOOLS",
        settingsTab = "SETTINGS",
        selectTarget = "SELECT TARGET: NONE",
        targetSelected = "TARGET: ",
        speedHack = "SPEED HACK",
        noclip = "NOCLIP",
        telePlayer = "TELE TO PLAYER",
        bringPlayer = "BRING PLAYER",
        esp = "PLAYER ESP",
        fly = "FLY MODE",
        autoWin = "AUTO WIN",
        infJump = "INFINITE JUMP",
        autoParkour = "AUTO PARKOUR",
        spinBot = "SPIN BOT",
        forceSit = "FORCE SIT",
        runSpeedSlider = "WALK SPEED",
        flySpeedSlider = "FLY SPEED",
        changeLangBtn = "LANGUAGE: ENGLISH 🇺🇸",
        serverHop = "SERVER HOP 🌐",
        rejoinServer = "REJOIN SERVER 🔄",
        tpToolBtn = "GET CLICK TP TOOL 🪄",
        petModeBtnOn = "PIGGYBACK MODE: ON 🎒",
        petModeBtnOff = "PIGGYBACK MODE: OFF 🎒",
        copyToolsBtn = "COPY TARGET TOOLS 🎒✨",
        openDexBtn = "OPEN DARK DEX V4 📂",
        openSpyBtn = "OPEN REMOTE SPY 🕵️‍♂️"
    }
}

local uiRefreshRegistry = {}
local function RegisterUIUpdate(func)
    table.insert(uiRefreshRegistry, func)
    func()
end

local function ChangeLanguage(langCode)
    currentLanguage = langCode
    for _, refreshFunc in pairs(uiRefreshRegistry) do
        pcall(refreshFunc)
    end
end

-- ================= TẠO GIAO DIỆN CHÍNH =================
if LocalPlayer.PlayerGui:FindFirstChild("MinhChien") then 
    LocalPlayer.PlayerGui.MinhChien:Destroy() 
end

local ScreenGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
ScreenGui.Name = "MinhChien"
ScreenGui.ResetOnSpawn = false

local ClickSound = Instance.new("Sound", ScreenGui)
ClickSound.SoundId = "rbxassetid://452267918"
ClickSound.Volume = 1

local function Drag(gui)
    local drag, input, start, pos = false, nil, nil, nil
    gui.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = true start = i.Position pos = gui.Position
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
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
end

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 250, 0, 440)
Main.Position = UDim2.new(0.5, -125, 0.15, 0)
Main.BackgroundColor3 = Color3.fromRGB(5, 5, 10)
Main.Visible = false
Main.Active = true
Drag(Main)

local MainCorner = Instance.new("UICorner", Main)
MainCorner.CornerRadius = UDim.new(0, 12)

local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Thickness = 3
task.spawn(function() 
    while task.wait(0.01) do MainStroke.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1) end 
end)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Text = "MINHCHIEN HUB"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 13
Title.BackgroundTransparency = 1

-- ================= THANH PHÂN TAB (CHIA ĐỀU 3 PHẦN) =================
local TabBar = Instance.new("Frame", Main)
TabBar.Size = UDim2.new(0.9, 0, 0, 30)
TabBar.Position = UDim2.new(0.05, 0, 0.08, 0)
TabBar.BackgroundTransparency = 1

local TabMainBtn = Instance.new("TextButton", TabBar)
TabMainBtn.Size = UDim2.new(0.31, 0, 1, 0)
TabMainBtn.Position = UDim2.new(0, 0, 0, 0)
TabMainBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
TabMainBtn.TextColor3 = Color3.fromRGB(0, 255, 255)
TabMainBtn.Font = Enum.Font.GothamBold
TabMainBtn.TextSize = 10
local MCorn = Instance.new("UICorner", TabMainBtn) MCorn.CornerRadius = UDim.new(0, 6)

local TabToolBtn = Instance.new("TextButton", TabBar)
TabToolBtn.Size = UDim2.new(0.31, 0, 1, 0)
TabToolBtn.Position = UDim2.new(0.345, 0, 0, 0)
TabToolBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
TabToolBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
TabToolBtn.Font = Enum.Font.GothamBold
TabToolBtn.TextSize = 10
local TCorn = Instance.new("UICorner", TabToolBtn) TCorn.CornerRadius = UDim.new(0, 6)

local TabSettingsBtn = Instance.new("TextButton", TabBar)
TabSettingsBtn.Size = UDim2.new(0.31, 0, 1, 0)
TabSettingsBtn.Position = UDim2.new(0.69, 0, 0, 0)
TabSettingsBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
TabSettingsBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
TabSettingsBtn.Font = Enum.Font.GothamBold
TabSettingsBtn.TextSize = 10
local SCorn = Instance.new("UICorner", TabSettingsBtn) SCorn.CornerRadius = UDim.new(0, 6)

RegisterUIUpdate(function()
    TabMainBtn.Text = LangConfig[currentLanguage].mainTab
    TabToolBtn.Text = LangConfig[currentLanguage].toolTab
    TabSettingsBtn.Text = LangConfig[currentLanguage].settingsTab
end)

-- CONTAINER CHO CÁC TAB
local MainTabFrame = Instance.new("ScrollingFrame", Main)
MainTabFrame.Size = UDim2.new(0.9, 0, 0.78, 0)
MainTabFrame.Position = UDim2.new(0.05, 0, 0.17, 0)
MainTabFrame.BackgroundTransparency = 1
MainTabFrame.CanvasSize = UDim2.new(0, 0, 4.5, 0)
MainTabFrame.ScrollBarThickness = 0
MainTabFrame.Visible = true

local MainLayout = Instance.new("UIListLayout", MainTabFrame)
MainLayout.Padding = UDim.new(0, 8)
MainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local ToolTabFrame = Instance.new("ScrollingFrame", Main)
ToolTabFrame.Size = UDim2.new(0.9, 0, 0.78, 0)
ToolTabFrame.Position = UDim2.new(0.05, 0, 0.17, 0)
ToolTabFrame.BackgroundTransparency = 1
ToolTabFrame.CanvasSize = UDim2.new(0, 0, 2.5, 0) -- Mở rộng Canvas để chứa các nút công cụ mới mượt mà
ToolTabFrame.ScrollBarThickness = 0
ToolTabFrame.Visible = false

local ToolLayout = Instance.new("UIListLayout", ToolTabFrame)
ToolLayout.Padding = UDim.new(0, 8)
ToolLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local SettingsTabFrame = Instance.new("ScrollingFrame", Main)
SettingsTabFrame.Size = UDim2.new(0.9, 0, 0.78, 0)
SettingsTabFrame.Position = UDim2.new(0.05, 0, 0.17, 0)
SettingsTabFrame.BackgroundTransparency = 1
SettingsTabFrame.CanvasSize = UDim2.new(0, 0, 2.3, 0)
SettingsTabFrame.ScrollBarThickness = 0
SettingsTabFrame.Visible = false

local SettingsLayout = Instance.new("UIListLayout", SettingsTabFrame)
SettingsLayout.Padding = UDim.new(0, 10)
SettingsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- LOGIC CHUYỂN TAB 3 CỔNG
local function SwitchTab(activeFrame, activeBtn, inactiveBtn1, inactiveBtn2)
    MainTabFrame.Visible = (MainTabFrame == activeFrame)
    ToolTabFrame.Visible = (ToolTabFrame == activeFrame)
    SettingsTabFrame.Visible = (SettingsTabFrame == activeFrame)
    
    activeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    activeBtn.TextColor3 = Color3.fromRGB(0, 255, 255)
    
    inactiveBtn1.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    inactiveBtn1.TextColor3 = Color3.fromRGB(150, 150, 150)
    inactiveBtn2.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    inactiveBtn2.TextColor3 = Color3.fromRGB(150, 150, 150)
end

TabMainBtn.MouseButton1Click:Connect(function()
    ClickSound:Play()
    SwitchTab(MainTabFrame, TabMainBtn, TabToolBtn, TabSettingsBtn)
end)

TabToolBtn.MouseButton1Click:Connect(function()
    ClickSound:Play()
    SwitchTab(ToolTabFrame, TabToolBtn, TabMainBtn, TabSettingsBtn)
end)

TabSettingsBtn.MouseButton1Click:Connect(function()
    ClickSound:Play()
    SwitchTab(SettingsTabFrame, TabSettingsBtn, TabMainBtn, TabToolBtn)
end)

-- ================= NÚT MENU THU NHỎ =================
local Icon = Instance.new("Frame", ScreenGui)
Icon.Size = UDim2.new(0, 60, 0, 60)
Icon.Position = UDim2.new(0, 10, 0, 7)
Icon.BackgroundColor3 = Color3.new(0, 0, 0)
Icon.Active = true
Drag(Icon)

local IconCorner = Instance.new("UICorner", Icon)
IconCorner.CornerRadius = UDim.new(1, 0)

local IconStroke = Instance.new("UIStroke", Icon)
IconStroke.Thickness = 3
task.spawn(function() 
    while task.wait(0.01) do IconStroke.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1) end 
end)

local Img = Instance.new("ImageLabel", Icon)
Img.Size = UDim2.new(0.9, 0, 0.9, 0)
Img.Position = UDim2.new(0.05, 0, 0.05, 0)
Img.Image = "rbxassetid://74840524656036"
Img.BackgroundTransparency = 1
local ImgCorner = Instance.new("UICorner", Img)
ImgCorner.CornerRadius = UDim.new(1, 0)

local IconBtn = Instance.new("TextButton", Icon)
IconBtn.Size = UDim2.new(1, 0, 1, 0)
IconBtn.BackgroundTransparency = 1
IconBtn.Text = ""
IconBtn.Activated:Connect(function() ClickSound:Play() Main.Visible = not Main.Visible end)

local function CreateButton(langKey, parent)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 6)
    return btn
end

-- ================= TAB MAIN: NỘI DUNG CHỨC NĂNG =================

local SelectedPlayer = nil
local DropdownFrame = Instance.new("Frame", MainTabFrame)
DropdownFrame.Size = UDim2.new(1, 0, 0, 38)
DropdownFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
local DropdownCorner = Instance.new("UICorner", DropdownFrame) DropdownCorner.CornerRadius = UDim.new(0, 6)

local DropdownBtn = Instance.new("TextButton", DropdownFrame)
DropdownBtn.Size = UDim2.new(1, 0, 1, 0)
DropdownBtn.BackgroundTransparency = 1
DropdownBtn.TextColor3 = Color3.new(1, 1, 1)
DropdownBtn.Font = Enum.Font.GothamBold
DropdownBtn.TextSize = 10

RegisterUIUpdate(function()
    if SelectedPlayer then
        DropdownBtn.Text = LangConfig[currentLanguage].targetSelected .. SelectedPlayer.Name
    else
        DropdownBtn.Text = LangConfig[currentLanguage].selectTarget
    end
end)

local PlayerListFrame = Instance.new("Frame", MainTabFrame)
PlayerListFrame.Size = UDim2.new(1, 0, 0, 0)
PlayerListFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
PlayerListFrame.Visible = false
local ListCorner = Instance.new("UICorner", PlayerListFrame) ListCorner.CornerRadius = UDim.new(0, 6)
local ListLayout = Instance.new("UIListLayout", PlayerListFrame) ListLayout.Padding = UDim.new(0, 4)

local function UpdateDropdown()
    for _, child in pairs(PlayerListFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local pBtn = Instance.new("TextButton", PlayerListFrame)
            pBtn.Size = UDim2.new(1, 0, 0, 25)
            pBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
            pBtn.Text = p.Name
            pBtn.TextColor3 = Color3.new(1, 1, 1)
            pBtn.Font = Enum.Font.Gotham
            pBtn.TextSize = 10
            local pBtnCorner = Instance.new("UICorner", pBtn) pBtnCorner.CornerRadius = UDim.new(0, 4)
            pBtn.MouseButton1Click:Connect(function()
                SelectedPlayer = p 
                DropdownBtn.Text = LangConfig[currentLanguage].targetSelected .. p.Name
                PlayerListFrame.Visible = false PlayerListFrame.Size = UDim2.new(1, 0, 0, 0)
            end)
        end
    end
end

DropdownBtn.MouseButton1Click:Connect(function()
    local isVisible = not PlayerListFrame.Visible
    UpdateDropdown()
    PlayerListFrame.Visible = isVisible
    if isVisible then PlayerListFrame.Size = UDim2.new(1, 0, 0, #Players:GetPlayers() * 28) else PlayerListFrame.Size = UDim2.new(1, 0, 0, 0) end
end)
Players.PlayerAdded:Connect(UpdateDropdown)
Players.PlayerRemoving:Connect(UpdateDropdown)

-- 1. SPEED HACK
local speedBtn = CreateButton("speedHack", MainTabFrame)
local speedToggle = false

local function updateSpeedBtnText()
    if speedToggle then
        speedBtn.Text = LangConfig[currentLanguage].speedHack .. ": ON"
        speedBtn.TextColor3 = Color3.fromRGB(255, 255, 0)
    else
        speedBtn.Text = LangConfig[currentLanguage].speedHack .. ": OFF"
        speedBtn.TextColor3 = Color3.new(1, 1, 1)
    end
end
RegisterUIUpdate(updateSpeedBtnText)

speedBtn.MouseButton1Click:Connect(function()
    speedToggle = not speedToggle
    updateSpeedBtnText()
    if not speedToggle then
        pcall(function()
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0) end
        end)
    end
end)

RunService.Heartbeat:Connect(function()
    if speedToggle then
        pcall(function()
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.MoveDirection.Magnitude > 0 then
                local moveDir = hum.MoveDirection
                root.AssemblyLinearVelocity = Vector3.new(moveDir.X * customSpeed, root.AssemblyLinearVelocity.Y, moveDir.Z * customSpeed)
            end
        end)
    end
end)

-- 2. XUYÊN TƯỜNG (NOCLIP)
local noclipBtn = CreateButton("noclip", MainTabFrame)
local noclipToggle = false

local function updateNoclipBtnText()
    if noclipToggle then
        noclipBtn.Text = LangConfig[currentLanguage].noclip .. ": ON"
        noclipBtn.TextColor3 = Color3.fromRGB(255, 100, 0)
    else
        noclipBtn.Text = LangConfig[currentLanguage].noclip .. ": OFF"
        noclipBtn.TextColor3 = Color3.new(1, 1, 1)
    end
end
RegisterUIUpdate(updateNoclipBtnText)

noclipBtn.MouseButton1Click:Connect(function()
    noclipToggle = not noclipToggle
    updateNoclipBtnText()
end)

RunService.Stepped:Connect(function()
    if noclipToggle then
        pcall(function()
            if LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
end)

-- 3. TELE TO PLAYER
local tpPlayerBtn = CreateButton("telePlayer", MainTabFrame)
local tpPlayerToggle = false

local function updateTpBtnText()
    if tpPlayerToggle then
        tpPlayerBtn.Text = LangConfig[currentLanguage].telePlayer .. ": ON"
        tpPlayerBtn.TextColor3 = Color3.fromRGB(0, 255, 100)
    else
        tpPlayerBtn.Text = LangConfig[currentLanguage].telePlayer .. ": OFF"
        tpPlayerBtn.TextColor3 = Color3.new(1, 1, 1)
    end
end
RegisterUIUpdate(updateTpBtnText)

tpPlayerBtn.MouseButton1Click:Connect(function()
    tpPlayerToggle = not tpPlayerToggle
    updateTpBtnText()
end)

task.spawn(function()
    while task.wait(0.1) do
        if tpPlayerToggle and SelectedPlayer and SelectedPlayer.Character and SelectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                local myChar = LocalPlayer.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                local targetRoot = SelectedPlayer.Character.HumanoidRootPart
                
                if myRoot and targetRoot then
                    local targetPos = targetRoot.Position + Vector3.new(0, 3, 0)
                    local currentPos = myRoot.Position
                    local distance = (targetPos - currentPos).Magnitude
                    
                    if distance > 12 then
                        local steps = math.ceil(distance / 12)
                        for step = 1, steps do
                            if not tpPlayerToggle then break end
                            local interpolation = currentPos:Lerp(targetPos, step / steps)
                            myRoot.CFrame = CFrame.new(interpolation)
                            myRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                            RunService.Heartbeat:Wait()
                        end
                    else
                        myRoot.CFrame = CFrame.new(targetPos)
                        myRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    end
                end
            end)
        end
    end
end)

-- 4. BRING PLAYER
local bringPlayerBtn = CreateButton("bringPlayer", MainTabFrame)
local bringPlayerToggle = false

local function updateBringBtnText()
    if bringPlayerToggle then
        bringPlayerBtn.Text = LangConfig[currentLanguage].bringPlayer .. ": ON"
        bringPlayerBtn.TextColor3 = Color3.fromRGB(255, 30, 30)
    else
        bringPlayerBtn.Text = LangConfig[currentLanguage].bringPlayer .. ": OFF"
        bringPlayerBtn.TextColor3 = Color3.new(1, 1, 1)
    end
end
RegisterUIUpdate(updateBringBtnText)

bringPlayerBtn.MouseButton1Click:Connect(function()
    bringPlayerToggle = not bringPlayerToggle
    updateBringBtnText()
end)

task.spawn(function()
    while task.wait(0.1) do
        if bringPlayerToggle and SelectedPlayer and SelectedPlayer.Character and SelectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local targetRoot = SelectedPlayer.Character.HumanoidRootPart
                if myRoot and targetRoot then
                    targetRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -3)
                    targetRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                end
            end)
        end
    end
end)

-- 5. ESP
local espBtn = CreateButton("esp", MainTabFrame)
local espToggle = false

local function updateEspBtnText()
    if espToggle then
        espBtn.Text = LangConfig[currentLanguage].esp .. ": ON"
        espBtn.TextColor3 = Color3.fromRGB(255, 0, 255)
    else
        espBtn.Text = LangConfig[currentLanguage].esp .. ": OFF"
        espBtn.TextColor3 = Color3.new(1, 1, 1)
    end
end
RegisterUIUpdate(updateEspBtnText)

espBtn.MouseButton1Click:Connect(function()
    espToggle = not espToggle
    updateEspBtnText()
    if not espToggle then
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character then
                if p.Character:FindFirstChild("ESPHighlight") then p.Character.ESPHighlight:Destroy() end
                if p.Character:FindFirstChild("Head") and p.Character.Head:FindFirstChild("ESPBillboard") then p.Character.Head.ESPBillboard:Destroy() end
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if espToggle then
        pcall(function()
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChildOfClass("Humanoid") then
                    local char = p.Character
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if not char:FindFirstChild("ESPHighlight") then
                        local hl = Instance.new("Highlight", char)
                        hl.Name = "ESPHighlight" hl.FillColor = Color3.fromRGB(255, 0, 100) hl.FillTransparency = 0.5 hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    end
                    if char:FindFirstChild("Head") and not char.Head:FindFirstChild("ESPBillboard") then
                        local bill = Instance.new("BillboardGui", char.Head)
                        bill.Name = "ESPBillboard" bill.Size = UDim2.new(0, 150, 0, 40) bill.AlwaysOnTop = true bill.StudsOffset = Vector3.new(0, 3, 0)
                        local lbl = Instance.new("TextLabel", bill)
                        lbl.Name = "InfoLabel" lbl.Size = UDim2.new(1, 0, 1, 0) lbl.BackgroundTransparency = 1 lbl.TextColor3 = Color3.fromRGB(0, 255, 255) lbl.Font = Enum.Font.GothamBold lbl.TextSize = 10
                    end
                    if char:FindFirstChild("Head") and char.Head:FindFirstChild("ESPBillboard") then
                        char.Head.ESPBillboard.InfoLabel.Text = string.format("%s\n[HP: %d/%d]", p.Name, math.floor(hum.Health), math.floor(hum.MaxHealth))
                    end
                end
            end
        end)
    end
end)

-- 6. FLY
local flyBtn = CreateButton("fly", MainTabFrame)
local flyToggle = false
local bv, bg = nil, nil

local function updateFlyBtnText()
    if flyToggle then
        flyBtn.Text = LangConfig[currentLanguage].fly .. ": ON"
        flyBtn.TextColor3 = Color3.fromRGB(100, 255, 255)
    else
        flyBtn.Text = LangConfig[currentLanguage].fly .. ": OFF"
        flyBtn.TextColor3 = Color3.new(1, 1, 1)
    end
end
RegisterUIUpdate(updateFlyBtnText)

flyBtn.MouseButton1Click:Connect(function()
    flyToggle = not flyToggle
    updateFlyBtnText()
    if flyToggle then
        local char = LocalPlayer.Character local root = char and char:FindFirstChild("HumanoidRootPart") local hum = char and char:FindFirstChildOfClass("Humanoid")
        if root and hum then
            hum.PlatformStand = true bg = Instance.new("BodyGyro", root) bg.maxTorque = Vector3.new(9e9, 9e9, 9e9) bg.P = 9e4 bg.cframe = root.CFrame
            bv = Instance.new("BodyVelocity", root) bv.maxForce = Vector3.new(9e9, 9e9, 9e9) bv.velocity = Vector3.new(0, 0, 0)
            task.spawn(function()
                local camera = workspace.CurrentCamera
                while flyToggle and char and root and hum.Parent do
                    RunService.Heartbeat:Wait() bg.cframe = camera.CFrame 
                    if hum.MoveDirection.Magnitude > 0 then bv.velocity = camera.CFrame.LookVector * flySpeed else bv.velocity = Vector3.new(0, 0.15 * math.sin(tick() * 10), 0) end
                end
                if bg then bg:Destroy() end if bv then bv:Destroy() end if hum then hum.PlatformStand = false end
            end)
        end
    else
        if bg then bg:Destroy() end if bv then bv:Destroy() end local char = LocalPlayer.Character local hum = char and char:FindFirstChildOfClass("Humanoid") if hum then hum.PlatformStand = false end
    end
end)

-- 7. AUTO WIN
local winBtn = CreateButton("autoWin", MainTabFrame)
local winToggle = false

local function updateWinBtnText()
    if winToggle then
        winBtn.Text = LangConfig[currentLanguage].autoWin .. ": ON"
        winBtn.TextColor3 = Color3.fromRGB(0, 255, 100)
    else
        winBtn.Text = LangConfig[currentLanguage].autoWin .. ": OFF"
        winBtn.TextColor3 = Color3.new(1, 1, 1)
    end
end
RegisterUIUpdate(updateWinBtnText)

winBtn.MouseButton1Click:Connect(function() 
    winToggle = not winToggle
    updateWinBtnText()
end)

task.spawn(function() 
    while task.wait(1) do 
        if winToggle then 
            pcall(function() 
                local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") 
                if root then 
                    local target = nil 
                    for _, v in pairs(workspace:GetDescendants()) do 
                        if v:IsA("BasePart") or v:IsA("SpawnLocation") then 
                            local n = v.Name:lower() 
                            if n:find("win") or n:find("finish") or n:find("end") or n:find("đích") or n:find("reward") then target = v break end 
                        end 
                    end 
                    if target then 
                        if BypassTP then
                            if (root.Position - target.Position).Magnitude < 1500 then topos(target) else BTP(target) end
                        else
                            topos(target)
                        end
                    end 
                end 
            end) 
        end 
    end 
end)

-- 8. INF JUMP
local infJumpBtn = CreateButton("infJump", MainTabFrame)
local infJumpToggle = false

local function updateJumpBtnText()
    if infJumpToggle then
        infJumpBtn.Text = LangConfig[currentLanguage].infJump .. ": ON"
        infJumpBtn.TextColor3 = Color3.fromRGB(0, 255, 255)
    else
        infJumpBtn.Text = LangConfig[currentLanguage].infJump .. ": OFF"
        infJumpBtn.TextColor3 = Color3.new(1, 1, 1)
    end
end
RegisterUIUpdate(updateJumpBtnText)

infJumpBtn.MouseButton1Click:Connect(function() 
    infJumpToggle = not infJumpToggle
    updateJumpBtnText()
end)
UserInputService.JumpRequest:Connect(function() 
    if infJumpToggle and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping) end 
end)

-- 9. ANTI AFK 
local vu = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function() 
    pcall(function() vu:CaptureController() vu:ClickButton2(Vector2.new()) end)
end)

-- 10. AUTO PARKOUR
local parkourBtn = CreateButton("autoParkour", MainTabFrame)
local parkourToggle = false

local function updateParkourBtnText()
    if parkourToggle then
        parkourBtn.Text = LangConfig[currentLanguage].autoParkour .. ": ON"
        parkourBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
    else
        parkourBtn.Text = LangConfig[currentLanguage].autoParkour .. ": OFF"
        parkourBtn.TextColor3 = Color3.new(1, 1, 1)
    end
end
RegisterUIUpdate(updateParkourBtnText)

parkourBtn.MouseButton1Click:Connect(function() 
    parkourToggle = not parkourToggle
    updateParkourBtnText()
end)

RunService.Heartbeat:Connect(function()
    if parkourToggle then
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if hum and root and hum.MoveDirection.Magnitude > 0 then
                local lookVec = hum.MoveDirection
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {char}
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                local checkDropPos = root.Position + (lookVec * 4.5)
                local dropHit = workspace:Raycast(checkDropPos, Vector3.new(0, -7, 0), rayParams)
                local blockHit = workspace:Raycast(root.Position, lookVec * 3.5, rayParams)
                if not dropHit or blockHit then if hum.FloorMaterial ~= Enum.Material.Air then hum:ChangeState(Enum.HumanoidStateType.Jumping) end end
            end
        end)
    end
end)

-- 11. SPIN BOT
local spinBtn = CreateButton("spinBot", MainTabFrame)
local spinToggle = false

local function updateSpinBtnText()
    if spinToggle then
        spinBtn.Text = LangConfig[currentLanguage].spinBot .. ": ON"
        spinBtn.TextColor3 = Color3.fromRGB(255, 180, 0)
    else
        spinBtn.Text = LangConfig[currentLanguage].spinBot .. ": OFF"
        spinBtn.TextColor3 = Color3.new(1, 1, 1)
    end
end
RegisterUIUpdate(updateSpinBtnText)

spinBtn.MouseButton1Click:Connect(function() 
    spinToggle = not spinToggle
    updateSpinBtnText()
end)

RunService.Heartbeat:Connect(function()
    if spinToggle then
        pcall(function()
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0)
            end
        end)
    end
end)

-- 12. FORCE SIT
local sitBtn = CreateButton("forceSit", MainTabFrame)
local sitToggle = false

local function updateSitBtnText()
    if sitToggle then
        sitBtn.Text = LangConfig[currentLanguage].forceSit .. ": ON"
        sitBtn.TextColor3 = Color3.fromRGB(180, 100, 255)
    else
        sitBtn.Text = LangConfig[currentLanguage].forceSit .. ": OFF"
        sitBtn.TextColor3 = Color3.new(1, 1, 1)
    end
end
RegisterUIUpdate(updateSitBtnText)

sitBtn.MouseButton1Click:Connect(function() 
    sitToggle = not sitToggle
    updateSitBtnText()
end)

RunService.Heartbeat:Connect(function()
    if sitToggle then
        pcall(function()
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum and not hum.Sit then
                hum.Sit = true
            end
        end)
    end
end)


-- ================= TAB CÔNG CỤ (TOOLS) =================

local tpToolBtn = CreateButton("tpToolBtn", ToolTabFrame)
tpToolBtn.BackgroundColor3 = Color3.fromRGB(35, 45, 35)
RegisterUIUpdate(function() tpToolBtn.Text = LangConfig[currentLanguage].tpToolBtn end)

tpToolBtn.MouseButton1Click:Connect(function()
    ClickSound:Play()
    pcall(function()
        local tool = Instance.new("Tool")
        tool.Name = "Click TP Tool"
        tool.RequiresHandle = false
        tool.Activated:Connect(function()
            local mouse = LocalPlayer:GetMouse()
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root and mouse.Target then root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0)) end
        end)
        tool.Parent = LocalPlayer.Backpack
    end)
end)

-- NÚT MỚI 1: BÁM LƯNG BẠN NỮ (PIGGYBACK COMPANION)
local petModeBtn = CreateButton("petModeBtnOn", ToolTabFrame)
local petToggle = false
petModeBtn.BackgroundColor3 = Color3.fromRGB(45, 30, 45)

local function updatePetText()
    if petToggle then
        petModeBtn.Text = LangConfig[currentLanguage].petModeBtnOn
        petModeBtn.TextColor3 = Color3.fromRGB(255, 105, 180)
    else
        petModeBtn.Text = LangConfig[currentLanguage].petModeBtnOff
        petModeBtn.TextColor3 = Color3.new(1, 1, 1)
    end
end
RegisterUIUpdate(updatePetText)

petModeBtn.MouseButton1Click:Connect(function()
    ClickSound:Play()
    if not SelectedPlayer then
        DropdownBtn.Text = (currentLanguage == "VI" and "⚠️ HÃY CHỌN TARGET TRƯỚC!" or "⚠️ SELECT TARGET FIRST!")
        return
    end
    petToggle = not petToggle
    updatePetText()
    
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.Sit = petToggle end
end)

RunService.Heartbeat:Connect(function()
    if petToggle and SelectedPlayer and SelectedPlayer.Character and SelectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
        pcall(function()
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local targetRoot = SelectedPlayer.Character.HumanoidRootPart
            if myRoot and targetRoot then
                myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 1.5, 1)
                myRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                myRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
        end)
    end
end)

-- NÚT MỚI 2: SAO CHÉP ĐỒ NGƯỜI KHÁC (COPY TOOLS)
local copyToolsBtn = CreateButton("copyToolsBtn", ToolTabFrame)
copyToolsBtn.BackgroundColor3 = Color3.fromRGB(25, 45, 55)

RegisterUIUpdate(function()
    copyToolsBtn.Text = LangConfig[currentLanguage].copyToolsBtn
end)

copyToolsBtn.MouseButton1Click:Connect(function()
    ClickSound:Play()
    if not SelectedPlayer then
        DropdownBtn.Text = (currentLanguage == "VI" and "⚠️ HÃY CHỌN TARGET TRƯỚC!" or "⚠️ SELECT TARGET FIRST!")
        return
    end
    
    pcall(function()
        local copiedCount = 0
        if SelectedPlayer:FindFirstChild("Backpack") then
            for _, item in pairs(SelectedPlayer.Backpack:GetChildren()) do
                if item:IsA("Tool") then
                    local clonedTool = item:Clone()
                    clonedTool.Parent = LocalPlayer.Backpack
                    copiedCount = copiedCount + 1
                end
            end
        end
        if SelectedPlayer.Character then
            for _, item in pairs(SelectedPlayer.Character:GetChildren()) do
                if item:IsA("Tool") then
                    local clonedTool = item:Clone()
                    clonedTool.Parent = LocalPlayer.Backpack
                    copiedCount = copiedCount + 1
                end
            end
        end
        
        local oldText = copyToolsBtn.Text
        copyToolsBtn.Text = (currentLanguage == "VI" and "ĐÃ COPY " or "COPIED ") .. tostring(copiedCount) .. " ITEMS! ✅"
        copyToolsBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
        task.delay(2, function()
            copyToolsBtn.Text = oldText
            copyToolsBtn.TextColor3 = Color3.new(1, 1, 1)
        end)
    end)
end)

-- NÚT 1: DARK DEX V3 MOBILE (NHẸ, CHỐNG CRASH CHO ĐIỆN THOẠI)
local openDexBtn = CreateButton("openDexBtn", ToolTabFrame)
openDexBtn.BackgroundColor3 = Color3.fromRGB(50, 40, 20)
RegisterUIUpdate(function() openDexBtn.Text = LangConfig[currentLanguage].openDexBtn end)

openDexBtn.MouseButton1Click:Connect(function()
    ClickSound:Play()
    local oldText = openDexBtn.Text
    openDexBtn.Text = "⏳ LOADING DEX MOBILE..."
    openDexBtn.TextColor3 = Color3.fromRGB(255, 255, 0)
    
    task.spawn(function()
        local success, err = pcall(function()
            -- Link tải Dex V3 chuẩn tối ưu cho Delta
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Babyhamsta/RBLX_Scripts/main/Universal/BypassedDarkDexV3.lua", true))()
        end)
        if not success then
            openDexBtn.Text = "❌ ĐANG CHẠY BẢN DỰ PHÒNG..."
            task.wait(1)
            pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))()
            end)
        end
        openDexBtn.Text = oldText
        openDexBtn.TextColor3 = Color3.new(1, 1, 1)
    end)
end)

-- NÚT 2: MOBILE SPY (BẢN LITE CỦA REDZHUB, RẤT MƯỢT, KHÔNG LAG)
local openSpyBtn = CreateButton("openSpyBtn", ToolTabFrame)
openSpyBtn.BackgroundColor3 = Color3.fromRGB(20, 50, 45)
RegisterUIUpdate(function() openSpyBtn.Text = LangConfig[currentLanguage].openSpyBtn end)

openSpyBtn.MouseButton1Click:Connect(function()
    ClickSound:Play()
    local oldText = openSpyBtn.Text
    openSpyBtn.Text = "⏳ LOADING MOBILE SPY..."
    openSpyBtn.TextColor3 = Color3.fromRGB(255, 255, 0)
    
    task.spawn(function()
        local success, err = pcall(function()
            -- Dùng RedzHub SimpleSpyMobile thay vì bản PC
            loadstring(game:HttpGet("https://raw.githubusercontent.com/REDzHUB/RS/main/SimpleSpyMobile"))()
        end)
        if not success then
            openSpyBtn.Text = "❌ LỖI TẢI SPY!"
            openSpyBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
            warn("Spy Error: " .. tostring(err))
            task.wait(2)
        end
        openSpyBtn.Text = oldText
        openSpyBtn.TextColor3 = Color3.new(1, 1, 1)
    end)
end)

-- ================= TAB SETTINGS (ĐÃ SỬA LỖI SERVER HOP) =================

local changeLangBtn = Instance.new("TextButton", SettingsTabFrame)
changeLangBtn.Size = UDim2.new(1, 0, 0, 36)
changeLangBtn.BackgroundColor3 = Color3.fromRGB(45, 30, 30)
changeLangBtn.TextColor3 = Color3.new(1, 1, 1)
changeLangBtn.Font = Enum.Font.GothamBold
changeLangBtn.TextSize = 11
local L_Corn = Instance.new("UICorner", changeLangBtn) L_Corn.CornerRadius = UDim.new(0, 6)
RegisterUIUpdate(function() changeLangBtn.Text = LangConfig[currentLanguage].changeLangBtn end)

changeLangBtn.MouseButton1Click:Connect(function()
    ClickSound:Play()
    if currentLanguage == "VI" then ChangeLanguage("EN") else ChangeLanguage("VI") end
end)

-- SERVER HOP ĐƯỢC LÀM LẠI HOÀN TOÀN (CHỐNG LỖI HTTP 404 CỦA DELTA)
local hopBtn = CreateButton("serverHop", SettingsTabFrame)
hopBtn.BackgroundColor3 = Color3.fromRGB(25, 40, 50)
RegisterUIUpdate(function() hopBtn.Text = LangConfig[currentLanguage].serverHop end)

hopBtn.MouseButton1Click:Connect(function()
    ClickSound:Play()
    local oldText = hopBtn.Text
    hopBtn.Text = (currentLanguage == "VI" and "ĐANG TÌM SERVER..." or "SEARCHING SERVER...")
    hopBtn.TextColor3 = Color3.fromRGB(255, 255, 0)

    task.spawn(function()
        local placeId = game.PlaceId
        local successHop = false
        
        -- Dùng request() thay cho game:HttpGet() để loại bỏ lỗi màn hình đỏ 404
        local httprequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
        
        if httprequest then
            local reqSuccess, response = pcall(function()
                return httprequest({
                    Url = string.format("https://games.roblox.com/v1/places/%d/servers/Public?sortOrder=Desc&limit=100", placeId),
                    Method = "GET"
                })
            end)

            if reqSuccess and response and response.StatusCode == 200 then
                local body = HttpService:JSONDecode(response.Body)
                local servers = {}
                if body and body.data then
                    for _, v in pairs(body.data) do
                        if type(v) == "table" and tonumber(v.playing) and tonumber(v.maxPlayers) then
                            if v.playing < v.maxPlayers and v.id ~= game.JobId then
                                table.insert(servers, v.id)
                            end
                        end
                    end
                end
                
                if #servers > 0 then
                    local randomServer = servers[math.random(1, #servers)]
                    TeleportService:TeleportToPlaceInstance(placeId, randomServer, LocalPlayer)
                    successHop = true
                end
            end
        end

        -- Nếu API thất bại (do game là Sub-place hoặc bị chặn), dùng dự phòng an toàn
        if not successHop then
            pcall(function()
                TeleportService:Teleport(placeId, LocalPlayer)
            end)
        end

        task.wait(3)
        hopBtn.Text = oldText
        hopBtn.TextColor3 = Color3.new(1, 1, 1)
    end)
end)

local rejoinBtn = CreateButton("rejoinServer", SettingsTabFrame)
rejoinBtn.BackgroundColor3 = Color3.fromRGB(40, 25, 50)
RegisterUIUpdate(function() rejoinBtn.Text = LangConfig[currentLanguage].rejoinServer end)

rejoinBtn.MouseButton1Click:Connect(function()
    ClickSound:Play()
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
end)

local function CreateSlider(langKey, min, max, default, parent, callback)
    local SliderFrame = Instance.new("Frame", parent)
    SliderFrame.Size = UDim2.new(1, 0, 0, 50)
    SliderFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    local SCorn = Instance.new("UICorner", SliderFrame) SCorn.CornerRadius = UDim.new(0, 6)
    
    local Label = Instance.new("TextLabel", SliderFrame)
    Label.Size = UDim2.new(1, 0, 0, 20)
    Label.Position = UDim2.new(0, 10, 0, 2)
    Label.TextColor3 = Color3.new(1, 1, 1)
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 10
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.BackgroundTransparency = 1
    
    local SliderBar = Instance.new("Frame", SliderFrame)
    SliderBar.Size = UDim2.new(0.9, 0, 0, 6)
    SliderBar.Position = UDim2.new(0.05, 0, 0.65, 0)
    SliderBar.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    
    local SliderFill = Instance.new("Frame", SliderBar)
    SliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    SliderFill.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
    SliderFill.BorderSizePixel = 0
    
    local SliderBtn = Instance.new("TextButton", SliderBar)
    SliderBtn.Size = UDim2.new(0, 12, 0, 12)
    SliderBtn.Position = UDim2.new((default - min) / (max - min), -6, 0, -3)
    SliderBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SliderBtn.Text = ""
    local BCorn = Instance.new("UICorner", SliderBtn) BCorn.CornerRadius = UDim.new(1, 0)
    
    local dragging = false
    local currentValue = default
    
    local function refreshSliderLabel()
        Label.Text = LangConfig[currentLanguage][langKey] .. ": " .. tostring(currentValue)
    end
    RegisterUIUpdate(refreshSliderLabel)
    
    local function update(input)
        local pos = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
        SliderFill.Size = UDim2.new(pos, 0, 1, 0)
        SliderBtn.Position = UDim2.new(pos, -6, 0, -3)
        currentValue = math.floor(min + (pos * (max - min)))
        refreshSliderLabel()
        callback(currentValue)
    end
    
    SliderBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then update(input) end
    end)
end

CreateSlider("runSpeedSlider", 16, 300, customSpeed, SettingsTabFrame, function(value)
    customSpeed = value
end)

CreateSlider("flySpeedSlider", 20, 300, flySpeed, SettingsTabFrame, function(value)
    flySpeed = value
end)

setfpscap(60)