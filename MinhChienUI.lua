local RedzUiEngine = {}
local openState = true

function RedzUiEngine:CreateWindow()
    -- SỬA LỖI: Dùng PlayerGui thay vì CoreGui
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    if not player then return end
    local playerGui = player:WaitForChild("PlayerGui")

    if playerGui:FindFirstChild("MinhChienDev") then
        playerGui:FindFirstChild("MinhChienDev"):Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MinhChienDev"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = playerGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 540, 0, 360)
    MainFrame.Position = UDim2.new(0.5, -270, 0.5, -180)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 8)
    MainCorner.Parent = MainFrame

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Color3.fromRGB(255, 30, 60)
    MainStroke.Thickness = 1.5
    MainStroke.Parent = MainFrame

    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 35)
    TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame

    local TopCorner = Instance.new("UICorner")
    TopCorner.CornerRadius = UDim.new(0, 8)
    TopCorner.Parent = TopBar

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(0.7, 0, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "MINHCHIEN HUB"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 14
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TopBar

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 30, 0, 25)
    CloseBtn.Position = UDim2.new(1, -40, 0.5, -12)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 20)
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 12
    CloseBtn.Parent = TopBar

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 5)
    CloseCorner.Parent = CloseBtn

    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    local SideBar = Instance.new("ScrollingFrame")
    SideBar.Name = "SideBar"
    SideBar.Size = UDim2.new(0, 130, 1, -45)
    SideBar.Position = UDim2.new(0, 5, 0, 40)
    SideBar.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    SideBar.BorderSizePixel = 0
    SideBar.ScrollBarThickness = 2
    SideBar.ScrollBarImageColor3 = Color3.fromRGB(255, 30, 60)
    SideBar.Parent = MainFrame

    local SideLayout = Instance.new("UIListLayout")
    SideLayout.Padding = UDim.new(0, 4)
    SideLayout.Parent = SideBar

    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(1, -145, 1, -45)
    ContentContainer.Position = UDim2.new(0, 140, 0, 40)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Parent = MainFrame

    -- ĐÃ SỬA THÀNH ImageButton VỚI ẢNH TỪ rbxassetid
    local MobileToggle = Instance.new("ImageButton")
    MobileToggle.Name = "MinhChienDev"
    MobileToggle.Size = UDim2.new(0, 50, 0, 50)
    MobileToggle.Position = UDim2.new(0, 10, 0, 80)
    MobileToggle.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    MobileToggle.Image = "rbxassetid://74840524656036"
    MobileToggle.ImageColor3 = Color3.fromRGB(255, 30, 60)
    MobileToggle.ScaleType = Enum.ScaleType.Stretch
    MobileToggle.Active = true
    MobileToggle.Draggable = true
    MobileToggle.Parent = ScreenGui

    local MobileCorner = Instance.new("UICorner")
    MobileCorner.CornerRadius = UDim.new(0, 25)
    MobileCorner.Parent = MobileToggle

    local MobileStroke = Instance.new("UIStroke")
    MobileStroke.Color = Color3.fromRGB(255, 255, 255)
    MobileStroke.Thickness = 2
    MobileStroke.Parent = MobileToggle

    MobileToggle.MouseButton1Click:Connect(function()
        openState = not openState
        MainFrame.Visible = openState
    end)

    local tabs = {}
    local firstTab = true

    function tabs:CreateTab(tabName)
        local TabPage = Instance.new("ScrollingFrame")
        TabPage.Name = tabName .. "Page"
        TabPage.Size = UDim2.new(1, 0, 1, 0)
        TabPage.BackgroundTransparency = 1
        TabPage.Visible = firstTab
        TabPage.ScrollBarThickness = 3
        TabPage.ScrollBarImageColor3 = Color3.fromRGB(255, 30, 60)
        TabPage.Parent = ContentContainer

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Padding = UDim.new(0, 6)
        PageLayout.Parent = TabPage

        local TabBtn = Instance.new("TextButton")
        TabBtn.Name = tabName .. "Btn"
        TabBtn.Size = UDim2.new(1, -5, 0, 32)
        TabBtn.BackgroundColor3 = firstTab and Color3.fromRGB(30, 15, 18) or Color3.fromRGB(22, 22, 22)
        TabBtn.Text = tabName
        TabBtn.TextColor3 = firstTab and Color3.fromRGB(255, 30, 60) or Color3.fromRGB(180, 180, 180)
        TabBtn.Font = Enum.Font.GothamBold
        TabBtn.TextSize = 12
        TabBtn.Parent = SideBar

        local TabBtnCorner = Instance.new("UICorner")
        TabBtnCorner.CornerRadius = UDim.new(0, 5)
        TabBtnCorner.Parent = TabBtn

        local TabBtnStroke = Instance.new("UIStroke")
        TabBtnStroke.Color = firstTab and Color3.fromRGB(255, 30, 60) or Color3.fromRGB(40, 40, 40)
        TabBtnStroke.Thickness = 1
        TabBtnStroke.Parent = TabBtn

        TabBtn.MouseButton1Click:Connect(function()
            for _, page in ipairs(ContentContainer:GetChildren()) do
                if page:IsA("ScrollingFrame") then page.Visible = false end
            end
            for _, btn in ipairs(SideBar:GetChildren()) do
                if btn:IsA("TextButton") then
                    btn.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
                    btn.TextColor3 = Color3.fromRGB(180, 180, 180)
                    local stroke = btn:FindFirstChildOfClass("UIStroke")
                    if stroke then stroke.Color = Color3.fromRGB(40, 40, 40) end
                end
            end
            TabPage.Visible = true
            TabBtn.BackgroundColor3 = Color3.fromRGB(30, 15, 18)
            TabBtn.TextColor3 = Color3.fromRGB(255, 30, 60)
            TabBtnStroke.Color = Color3.fromRGB(255, 30, 60)
        end)

        firstTab = false

        local elements = {}

        function elements:CreateSection(sectionText)
            local SecLabel = Instance.new("TextLabel")
            SecLabel.Size = UDim2.new(1, 0, 0, 20)
            SecLabel.BackgroundTransparency = 1
            SecLabel.Text = "—— " .. sectionText .. " ——"
            SecLabel.TextColor3 = Color3.fromRGB(255, 30, 60)
            SecLabel.Font = Enum.Font.GothamBold
            SecLabel.TextSize = 11
            SecLabel.Parent = TabPage
        end

        function elements:CreateButton(btnText, callback)
            local ActionBtn = Instance.new("TextButton")
            ActionBtn.Size = UDim2.new(1, -10, 0, 35)
            ActionBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
            ActionBtn.Text = "  " .. btnText
            ActionBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
            ActionBtn.Font = Enum.Font.GothamMedium
            ActionBtn.TextSize = 12
            ActionBtn.TextXAlignment = Enum.TextXAlignment.Left
            ActionBtn.Parent = TabPage

            local BtnCorner = Instance.new("UICorner")
            BtnCorner.CornerRadius = UDim.new(0, 5)
            BtnCorner.Parent = ActionBtn

            local BtnStroke = Instance.new("UIStroke")
            BtnStroke.Color = Color3.fromRGB(35, 35, 35)
            BtnStroke.Thickness = 1
            BtnStroke.Parent = ActionBtn

            ActionBtn.MouseButton1Click:Connect(function()
                ActionBtn.BackgroundColor3 = Color3.fromRGB(40, 24, 26)
                task.wait(0.1)
                ActionBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
                pcall(callback)
            end)
        end

        function elements:CreateToggle(toggleText, defaultState, callback)
            local toggled = defaultState

            local ToggleFrame = Instance.new("TextButton")
            ToggleFrame.Size = UDim2.new(1, -10, 0, 38)
            ToggleFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
            ToggleFrame.Text = ""
            ToggleFrame.Parent = TabPage

            local TFCorner = Instance.new("UICorner")
            TFCorner.CornerRadius = UDim.new(0, 5)
            TFCorner.Parent = ToggleFrame

            local TFStroke = Instance.new("UIStroke")
            TFStroke.Color = Color3.fromRGB(35, 35, 35)
            TFStroke.Thickness = 1
            TFStroke.Parent = ToggleFrame

            local Txt = Instance.new("TextLabel")
            Txt.Size = UDim2.new(0.7, 0, 1, 0)
            Txt.Position = UDim2.new(0, 10, 0, 0)
            Txt.BackgroundTransparency = 1
            Txt.Text = toggleText
            Txt.TextColor3 = toggled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(170, 170, 170)
            Txt.Font = Enum.Font.GothamMedium
            Txt.TextSize = 12
            Txt.TextXAlignment = Enum.TextXAlignment.Left
            Txt.Parent = ToggleFrame

            local Switch = Instance.new("Frame")
            Switch.Size = UDim2.new(0, 34, 0, 18)
            Switch.Position = UDim2.new(1, -45, 0.5, -9)
            Switch.BackgroundColor3 = toggled and Color3.fromRGB(255, 30, 60) or Color3.fromRGB(45, 45, 45)
            Switch.Parent = ToggleFrame

            local SwitchCorner = Instance.new("UICorner")
            SwitchCorner.CornerRadius = UDim.new(0, 9)
            SwitchCorner.Parent = Switch

            local Indicator = Instance.new("Frame")
            Indicator.Size = UDim2.new(0, 14, 0, 14)
            Indicator.Position = toggled and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
            Indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Indicator.Parent = Switch

            local IndCorner = Instance.new("UICorner")
            IndCorner.CornerRadius = UDim.new(0, 7)
            IndCorner.Parent = Indicator

            local function updateToggle()
                Txt.TextColor3 = toggled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(170, 170, 170)
                Switch.BackgroundColor3 = toggled and Color3.fromRGB(255, 30, 60) or Color3.fromRGB(45, 45, 45)
                Indicator.Position = toggled and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
            end

            ToggleFrame.MouseButton1Click:Connect(function()
                toggled = not toggled
                updateToggle()
                pcall(callback, toggled)
            end)
        end

        function elements:CreateInput(inputText, placeholder, callback)
            local InputFrame = Instance.new("Frame")
            InputFrame.Size = UDim2.new(1, -10, 0, 42)
            InputFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
            InputFrame.Parent = TabPage

            local IFCorner = Instance.new("UICorner")
            IFCorner.CornerRadius = UDim.new(0, 5)
            IFCorner.Parent = InputFrame

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(0.5, 0, 1, 0)
            Label.Position = UDim2.new(0, 10, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = inputText
            Label.TextColor3 = Color3.fromRGB(200, 200, 200)
            Label.Font = Enum.Font.GothamMedium
            Label.TextSize = 12
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = InputFrame

            local TextBox = Instance.new("TextBox")
            TextBox.Size = UDim2.new(0.45, 0, 0, 26)
            TextBox.Position = UDim2.new(1, -155, 0.5, -13)
            TextBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            TextBox.Text = ""
            TextBox.PlaceholderText = placeholder
            TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
            TextBox.PlaceholderColor3 = Color3.fromRGB(80, 80, 80)
            TextBox.Font = Enum.Font.Gotham
            TextBox.TextSize = 11
            TextBox.ClipsDescendants = true
            TextBox.Parent = InputFrame

            local TBCorner = Instance.new("UICorner")
            TBCorner.CornerRadius = UDim.new(0, 4)
            TBCorner.Parent = TextBox

            local TBStroke = Instance.new("UIStroke")
            TBStroke.Color = Color3.fromRGB(255, 30, 60)
            TBStroke.Thickness = 0.8
            TBStroke.Parent = TextBox

            TextBox.FocusLost:Connect(function()
                pcall(callback, TextBox.Text)
            end)
        end

        function elements:CreateDropdown(dropText, listData, callback)
            local expanded = false

            local DropFrame = Instance.new("Frame")
            DropFrame.Size = UDim2.new(1, -10, 0, 38)
            DropFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
            DropFrame.ClipsDescendants = true
            DropFrame.Parent = TabPage

            local DFCorner = Instance.new("UICorner")
            DFCorner.CornerRadius = UDim.new(0, 5)
            DFCorner.Parent = DropFrame

            local MainBtn = Instance.new("TextButton")
            MainBtn.Size = UDim2.new(1, 0, 0, 38)
            MainBtn.BackgroundTransparency = 1
            MainBtn.Text = "  " .. dropText .. " : " .. tostring(listData[1] or "None")
            MainBtn.TextColor3 = Color3.fromRGB(255, 30, 60)
            MainBtn.Font = Enum.Font.GothamBold
            MainBtn.TextSize = 12
            MainBtn.TextXAlignment = Enum.TextXAlignment.Left
            MainBtn.Parent = DropFrame

            local ItemsScroll = Instance.new("ScrollingFrame")
            ItemsScroll.Size = UDim2.new(1, -10, 0, 100)
            ItemsScroll.Position = UDim2.new(0, 5, 0, 40)
            ItemsScroll.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            ItemsScroll.BorderSizePixel = 0
            ItemsScroll.ScrollBarThickness = 2
            ItemsScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 30, 60)
            ItemsScroll.Parent = DropFrame

            local ScrollLayout = Instance.new("UIListLayout")
            ScrollLayout.Padding = UDim.new(0, 2)
            ScrollLayout.Parent = ItemsScroll

            for _, itemValue in ipairs(listData) do
                local ItemBtn = Instance.new("TextButton")
                ItemBtn.Size = UDim2.new(1, 0, 0, 25)
                ItemBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                ItemBtn.Text = tostring(itemValue)
                ItemBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
                ItemBtn.Font = Enum.Font.Gotham
                ItemBtn.TextSize = 11
                ItemBtn.Parent = ItemsScroll

                ItemBtn.MouseButton1Click:Connect(function()
                    MainBtn.Text = "  " .. dropText .. " : " .. tostring(itemValue)
                    expanded = false
                    DropFrame.Size = UDim2.new(1, -10, 0, 38)
                    pcall(callback, itemValue)
                end)
            end

            MainBtn.MouseButton1Click:Connect(function()
                expanded = not expanded
                if expanded then
                    DropFrame.Size = UDim2.new(1, -10, 0, 145)
                else
                    DropFrame.Size = UDim2.new(1, -10, 0, 38)
                end
            end)
        end

        function elements:CreateSlider(sliderText, min, max, default, callback)
            local SliderFrame = Instance.new("Frame")
            SliderFrame.Size = UDim2.new(1, -10, 0, 45)
            SliderFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
            SliderFrame.Parent = TabPage

            local SFCorner = Instance.new("UICorner")
            SFCorner.CornerRadius = UDim.new(0, 5)
            SFCorner.Parent = SliderFrame

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(0.6, 0, 0, 20)
            Label.Position = UDim2.new(0, 10, 0, 2)
            Label.BackgroundTransparency = 1
            Label.Text = sliderText
            Label.TextColor3 = Color3.fromRGB(200, 200, 200)
            Label.Font = Enum.Font.GothamMedium
            Label.TextSize = 12
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = SliderFrame

            local ValLabel = Instance.new("TextLabel")
            ValLabel.Size = UDim2.new(0.3, 0, 0, 20)
            ValLabel.Position = UDim2.new(1, -110, 0, 2)
            ValLabel.BackgroundTransparency = 1
            ValLabel.Text = tostring(default)
            ValLabel.TextColor3 = Color3.fromRGB(255, 30, 60)
            ValLabel.Font = Enum.Font.GothamBold
            ValLabel.TextSize = 12
            ValLabel.TextXAlignment = Enum.TextXAlignment.Right
            ValLabel.Parent = SliderFrame

            local SliderBar = Instance.new("TextButton")
            SliderBar.Size = UDim2.new(1, -20, 0, 6)
            SliderBar.Position = UDim2.new(0, 10, 0, 28)
            SliderBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            SliderBar.Text = ""
            SliderBar.Parent = SliderFrame

            local SBCorner = Instance.new("UICorner")
            SBCorner.CornerRadius = UDim.new(0, 3)
            SBCorner.Parent = SliderBar

            local Fill = Instance.new("Frame")
            local initPercent = (default - min) / (max - min)
            Fill.Size = UDim2.new(initPercent, 0, 1, 0)
            Fill.BackgroundColor3 = Color3.fromRGB(255, 30, 60)
            Fill.Parent = SliderBar

            local FillCorner = Instance.new("UICorner")
            FillCorner.CornerRadius = UDim.new(0, 3)
            FillCorner.Parent = Fill

            local uis = game:GetService("UserInputService")
            local holding = false

            local function updateSliderInput(input)
                local pos = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                Fill.Size = UDim2.new(pos, 0, 1, 0)
                local finalVal = math.floor(min + (max - min) * pos)
                ValLabel.Text = tostring(finalVal)
                pcall(callback, finalVal)
            end

            SliderBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    holding = true
                    updateSliderInput(input)
                end
            end)

            uis.InputChanged:Connect(function(input)
                if holding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateSliderInput(input)
                end
            end)

            uis.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    holding = false
                end
            end)
        end

        return elements
    end

    return tabs
end

-- ✅ SỬA QUAN TRỌNG: Trả về RedzUiEngine thay vì tabs
return RedzUiEngine
