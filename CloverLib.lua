local UILib = {}
UILib.__index = UILib

UILib.Tab = {}
UILib.Tab.__index = UILib.Tab

UILib.SubTab = {}
UILib.SubTab.__index = UILib.SubTab

UILib.Column = {}
UILib.Column.__index = UILib.Column

local UIS = game:GetService("UserInputService")
local HS = game:GetService("HttpService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local activeWindow = nil
local DEFAULT_THEME = {
    BG = Color3.fromRGB(20,20,20),
    Panel = Color3.fromRGB(30,30,30),
    Item = Color3.fromRGB(35,35,35),
    ItemHov = Color3.fromRGB(45,45,45),
    Accent = Color3.fromRGB(0,200,80),
    AccentD = Color3.fromRGB(0,150,60),
    White = Color3.new(1,1,1),
    Gray = Color3.fromRGB(160,160,160),
    GrayLt = Color3.fromRGB(200,200,200),
    Border = Color3.fromRGB(50,50,50),
    Track = Color3.fromRGB(60,60,60)
}

-- Tooltip system
local tooltipFrame = nil
local tooltipText = nil
local tooltipTimer = nil

local function showTooltip(text, pos)
    if not tooltipFrame then return end
    tooltipText.Text = text
    tooltipFrame.Position = UDim2.new(0, pos.X + 15, 0, pos.Y + 15)
    tooltipFrame.Visible = true
end

local function hideTooltip()
    if tooltipTimer then
        tooltipTimer:Cancel()
        tooltipTimer = nil
    end
    if tooltipFrame then
        tooltipFrame.Visible = false
    end
end

local function startTooltipDelay(text, pos)
    hideTooltip()
    tooltipTimer = task.delay(0.5, function()
        showTooltip(text, pos)
    end)
end

function UILib:notify(message, duration)
    duration = duration or 3
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 200, 0, 40)
    notif.Position = UDim2.new(1, -220, 0, 10)
    notif.BackgroundColor3 = self.theme.Panel
    notif.BorderSizePixel = 0
    notif.Parent = self.sg
    Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 4)
    local stroke = Instance.new("UIStroke", notif)
    stroke.Color = self.theme.Border
    stroke.Thickness = 1
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 1, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = message
    label.TextColor3 = self.theme.White
    label.Font = Enum.Font.Roboto
    label.TextSize = 14
    label.TextWrapped = true
    label.Parent = notif
    notif.Position = UDim2.new(1, 0, 0, 10)
    local tween = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(1, -220, 0, 10)})
    tween:Play()
    task.delay(duration, function()
        if notif and notif.Parent then
            local out = TweenService:Create(notif, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(1, 0, 0, 10)})
            out:Play()
            out.Completed:Connect(function() notif:Destroy() end)
        end
    end)
end

function UILib:saveConfig(filename)
    local data = {}
    if not self.configs then return end
    for id, elem in pairs(self.configs) do
        data[id] = elem.Value
    end
    local json = HS:JSONEncode(data)
    local success, err = pcall(writefile, filename, json)
    if success then self:notify("Config saved to " .. filename) else self:notify("Save failed: " .. tostring(err)) end
end

function UILib:loadConfig(filename)
    local success, content = pcall(readfile, filename)
    if not success then self:notify("Load failed: file not found") return end
    local data = HS:JSONDecode(content)
    if not data then return end
    for id, value in pairs(data) do
        if self.configs and self.configs[id] then
            self.configs[id]:SetValue(value)
        end
    end
    self:notify("Config loaded from " .. filename)
end

function UILib:deleteConfig(filename)
    local success = pcall(delfile, filename)
    if success then self:notify("Config deleted: " .. filename) else self:notify("Delete failed") end
end

function UILib:listConfigs()
    local files = pcall(listfiles, "") or {}
    local configs = {}
    for _, f in ipairs(files) do if f:match("%.json$") then table.insert(configs, f) end end
    return configs
end

function UILib.newWindow(title, size, theme, parent, showVersion, includeUITab)
    if activeWindow then activeWindow:Destroy() end
    local self = setmetatable({}, UILib)
    self.theme = theme or {}
    for k, v in pairs(DEFAULT_THEME) do if self.theme[k] == nil then self.theme[k] = v end end
    self.size = size
    self.title = title
    self.parent = parent or (gethui and gethui()) or LP:WaitForChild("PlayerGui")
    self.connections = {}
    self.showVersion = showVersion ~= false
    self.configs = {}
    self.resizing = nil
    self.toggleKey = Enum.KeyCode.RightShift
    self.watermark = nil

    self.sg = Instance.new("ScreenGui")
    self.sg.Name = "Clover_" .. HS:GenerateGUID(false)
    self.sg.ResetOnSpawn = false
    self.sg.IgnoreGuiInset = false
    self.sg.Parent = self.parent
    self.sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Tooltip frame
    tooltipFrame = Instance.new("Frame")
    tooltipFrame.Size = UDim2.new(0, 0, 0, 0)
    tooltipFrame.BackgroundColor3 = self.theme.Panel
    tooltipFrame.BorderSizePixel = 0
    tooltipFrame.Visible = false
    tooltipFrame.ZIndex = 1000
    tooltipFrame.Parent = self.sg
    Instance.new("UICorner", tooltipFrame).CornerRadius = UDim.new(0, 4)
    local tipStroke = Instance.new("UIStroke", tooltipFrame)
    tipStroke.Color = self.theme.Accent
    tipStroke.Thickness = 1
    local tipPadding = Instance.new("UIPadding", tooltipFrame)
    tipPadding.PaddingLeft = UDim.new(0, 6)
    tipPadding.PaddingRight = UDim.new(0, 6)
    tipPadding.PaddingTop = UDim.new(0, 4)
    tipPadding.PaddingBottom = UDim.new(0, 4)
    tooltipText = Instance.new("TextLabel")
    tooltipText.Size = UDim2.new(1, 0, 1, 0)
    tooltipText.BackgroundTransparency = 1
    tooltipText.TextColor3 = self.theme.White
    tooltipText.Font = Enum.Font.Roboto
    tooltipText.TextSize = 12
    tooltipText.TextWrapped = true
    tooltipText.Parent = tooltipFrame

    local win = Instance.new("Frame")
    win.Size = UDim2.new(0, size.X, 0, size.Y)
    win.Position = UDim2.new(0, 80, 0, 60)
    win.BackgroundColor3 = self.theme.BG
    win.BorderSizePixel = 0
    win.ClipsDescendants = true
    win.Parent = self.sg
    win.Active = true
    win.Selectable = false
    win.AnchorPoint = Vector2.new(0, 0)
    Instance.new("UICorner", win).CornerRadius = UDim.new(0, 8)
    local winStroke = Instance.new("UIStroke", win)
    winStroke.Color = self.theme.Border
    winStroke.Thickness = 1
    self.window = win
    self.originalPosition = win.Position
    self.originalSize = win.Size

    local function createResizeHandle(pos, size, cursor)
        local handle = Instance.new("Frame")
        handle.Size = size
        handle.Position = pos
        handle.BackgroundColor3 = self.theme.Accent
        handle.BackgroundTransparency = 1
        handle.BorderSizePixel = 0
        handle.ZIndex = 10
        handle.Parent = win
        handle.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then self.resizing = {type = cursor, startPos = input.Position, startSize = win.Size, startPosWin = win.Position} end end)
        handle.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then self.resizing = nil end end)
    end
    createResizeHandle(UDim2.new(0, 0, 1, -6), UDim2.new(1, 0, 0, 12), "s")
    createResizeHandle(UDim2.new(1, -6, 0, 0), UDim2.new(0, 12, 1, 0), "e")
    createResizeHandle(UDim2.new(1, -12, 1, -12), UDim2.new(0, 24, 0, 24), "se")

    table.insert(self.connections, UIS.InputChanged:Connect(function(input)
        if self.resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - self.resizing.startPos
            local newSize = self.resizing.startSize
            if self.resizing.type == "s" then newSize = UDim2.new(newSize.X.Scale, newSize.X.Offset, newSize.Y.Scale, newSize.Y.Offset + delta.Y)
            elseif self.resizing.type == "e" then newSize = UDim2.new(newSize.X.Scale, newSize.X.Offset + delta.X, newSize.Y.Scale, newSize.Y.Offset)
            elseif self.resizing.type == "se" then newSize = UDim2.new(newSize.X.Scale, newSize.X.Offset + delta.X, newSize.Y.Scale, newSize.Y.Offset + delta.Y) end
            newSize = UDim2.new(0, math.max(400, newSize.X.Offset), 0, math.max(300, newSize.Y.Offset))
            win.Size = newSize
            self.size = Vector2.new(newSize.X.Offset, newSize.Y.Offset)
            self.content.Size = UDim2.new(0, self.size.X - 152, 1, -92)
        end
    end))

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 46)
    header.BackgroundColor3 = self.theme.BG
    header.BorderSizePixel = 0
    header.ZIndex = 5
    header.Parent = win
    self.header = header
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 8)
    local headerLine = Instance.new("Frame")
    headerLine.Size = UDim2.new(1, 0, 0, 2)
    headerLine.Position = UDim2.new(0, 0, 1, -2)
    headerLine.BackgroundColor3 = self.theme.Accent
    headerLine.BorderSizePixel = 0
    headerLine.ZIndex = 6
    headerLine.Parent = header
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0, 240, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = self.theme.White
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 20
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 6
    titleLabel.Parent = header
    self.titleLabel = titleLabel

    if self.showVersion then
        local titleWidth = math.min(#title * 11, 240)
        local versionPill = Instance.new("Frame")
        versionPill.Size = UDim2.new(0, 52, 0, 18)
        versionPill.Position = UDim2.new(0, 10 + titleWidth + 8, 0.5, -9)
        versionPill.BackgroundColor3 = self.theme.AccentD
        versionPill.BorderSizePixel = 0
        versionPill.ZIndex = 6
        versionPill.Parent = header
        Instance.new("UICorner", versionPill).CornerRadius = UDim.new(0, 4)
        local versionLabel = Instance.new("TextLabel")
        versionLabel.Size = UDim2.new(1, 0, 1, 0)
        versionLabel.BackgroundTransparency = 1
        versionLabel.Text = "v1.0"
        versionLabel.TextColor3 = self.theme.White
        versionLabel.Font = Enum.Font.GothamBold
        versionLabel.TextSize = 10
        versionLabel.ZIndex = 7
        versionLabel.Parent = versionPill
        self.versionPill = versionPill
    end

    local hintLabel = Instance.new("TextLabel")
    hintLabel.Size = UDim2.new(0, 180, 1, 0)
    hintLabel.Position = UDim2.new(1, -188, 0, 0)
    hintLabel.BackgroundTransparency = 1
    hintLabel.Text = "[RSHIFT]  TOGGLE"
    hintLabel.TextColor3 = self.theme.Gray
    hintLabel.Font = Enum.Font.RobotoMono
    hintLabel.TextSize = 9
    hintLabel.TextXAlignment = Enum.TextXAlignment.Right
    hintLabel.ZIndex = 6
    hintLabel.Parent = header

    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 152, 1, -92)
    sidebar.Position = UDim2.new(0, 0, 0, 46)
    sidebar.BackgroundColor3 = self.theme.Panel
    sidebar.BorderSizePixel = 0
    sidebar.ClipsDescendants = true
    sidebar.Parent = win
    Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 6)
    self.sidebar = sidebar
    local sidebarEdge = Instance.new("Frame")
    sidebarEdge.Size = UDim2.new(0, 1, 1, 0)
    sidebarEdge.Position = UDim2.new(1, -1, 0, 0)
    sidebarEdge.BackgroundColor3 = self.theme.Border
    sidebarEdge.BorderSizePixel = 0
    sidebarEdge.Parent = sidebar

    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(0, size.X - 152, 1, -92)
    content.Position = UDim2.new(0, 152, 0, 46)
    content.BackgroundColor3 = self.theme.BG
    content.BorderSizePixel = 0
    content.Parent = win
    content.ScrollBarThickness = 4
    content.ScrollBarImageColor3 = self.theme.Accent
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.ScrollingDirection = Enum.ScrollingDirection.XY
    self.content = content

    local navbar = Instance.new("Frame")
    navbar.Size = UDim2.new(1, 0, 0, 46)
    navbar.Position = UDim2.new(0, 0, 1, -46)
    navbar.BackgroundColor3 = self.theme.Panel
    navbar.BorderSizePixel = 0
    navbar.Parent = win
    Instance.new("UICorner", navbar).CornerRadius = UDim.new(0, 6)
    local navbarStroke = Instance.new("UIStroke", navbar)
    navbarStroke.Color = self.theme.Border
    navbarStroke.Thickness = 1
    self.navbar = navbar
    local navList = Instance.new("UIListLayout", navbar)
    navList.FillDirection = Enum.FillDirection.Horizontal
    navList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    navList.VerticalAlignment = Enum.VerticalAlignment.Center
    navList.Padding = UDim.new(0, 0)

    do
        local drag, dragStart, dragPos = false, nil, nil
        header.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true dragStart = i.Position dragPos = win.Position end end)
        table.insert(self.connections, UIS.InputChanged:Connect(function(i) if drag and i.UserInputType == Enum.UserInputType.MouseMovement then local delta = i.Position - dragStart win.Position = UDim2.new(dragPos.X.Scale, dragPos.X.Offset + delta.X, dragPos.Y.Scale, dragPos.Y.Offset + delta.Y) self.originalPosition = win.Position end end))
        table.insert(self.connections, UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end))
    end

    table.insert(self.connections, UIS.InputBegan:Connect(function(input, gpe) if not gpe and input.KeyCode == self.toggleKey then self:setVisible(not win.Visible) end end))

    self.tabs = {}
    self.activeTab = nil
    self.navList = navList

    -- UI Settings Tab
    if includeUITab ~= false then
        local uiTab = self:addTab("UI")
        local uiSub = uiTab:addSubTab("Settings")
        local grp = uiSub:addGroup("Interface")
        grp:colorpicker("Accent Color", self.theme.Accent, function(c) self.theme.Accent = c; self.theme.AccentD = Color3.new(c.r*0.75, c.g*0.75, c.b*0.75) end, "Change accent color (requires restart)")
        grp:keybind("Toggle Key", "RightShift", function(_, name) self.toggleKey = name == "RightShift" and Enum.KeyCode.RightShift or Enum.KeyCode[name] or Enum.KeyCode.RightShift end, "Set key to show/hide menu")
        grp:toggle("Show Version", self.showVersion, function(v) self.showVersion = v end, "Show version pill in header")
        grp:toggle("Show Watermark", false, function(v) if v then self:addWatermark("CloverHub") elseif self.watermark then self.watermark:Destroy() self.watermark = nil end end, "Display FPS and ping")
        grp:button("Unload", function() self:Destroy() end, "Destroy the UI")
        local cfg = uiSub:addGroup("Config")
        cfg:button("Save Config", function() self:saveConfig("clover_config.json") end)
        cfg:button("Load Config", function() self:loadConfig("clover_config.json") end)
    end

    self:notify("CloverLib Loaded", 2)
    activeWindow = self
    return self
end

function UILib:addWatermark(name)
    if self.watermark then self.watermark:Destroy() end
    local wm = Instance.new("Frame")
    wm.Size = UDim2.new(0, 160, 0, 30)
    wm.Position = UDim2.new(0, 10, 0, 10)
    wm.BackgroundColor3 = self.theme.Panel
    wm.BorderSizePixel = 0
    wm.Parent = self.sg
    wm.ZIndex = 200
    Instance.new("UICorner", wm).CornerRadius = UDim.new(0, 6)
    local wmStroke = Instance.new("UIStroke", wm)
    wmStroke.Color = self.theme.Accent
    wmStroke.Thickness = 1
    local wmName = Instance.new("TextLabel")
    wmName.Size = UDim2.new(0, 60, 1, 0)
    wmName.Position = UDim2.new(0, 5, 0, 0)
    wmName.BackgroundTransparency = 1
    wmName.Text = name
    wmName.TextColor3 = self.theme.White
    wmName.Font = Enum.Font.GothamBold
    wmName.TextSize = 12
    wmName.TextXAlignment = Enum.TextXAlignment.Left
    wmName.ZIndex = 201
    wmName.Parent = wm
    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Size = UDim2.new(0, 40, 1, 0)
    fpsLabel.Position = UDim2.new(0, 70, 0, 0)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Text = "FPS: 0"
    fpsLabel.TextColor3 = self.theme.Accent
    fpsLabel.Font = Enum.Font.RobotoMono
    fpsLabel.TextSize = 10
    fpsLabel.ZIndex = 201
    fpsLabel.Parent = wm
    local pingLabel = Instance.new("TextLabel")
    pingLabel.Size = UDim2.new(0, 40, 1, 0)
    pingLabel.Position = UDim2.new(0, 115, 0, 0)
    pingLabel.BackgroundTransparency = 1
    pingLabel.Text = "0ms"
    pingLabel.TextColor3 = self.theme.Accent
    pingLabel.Font = Enum.Font.RobotoMono
    pingLabel.TextSize = 10
    pingLabel.ZIndex = 201
    pingLabel.Parent = wm
    local frameCount = 0
    local lastTime = tick()
    local connection = RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        local now = tick()
        if now - lastTime >= 1 then
            fpsLabel.Text = "FPS: " .. math.floor(frameCount / (now - lastTime) + 0.5)
            frameCount = 0
            lastTime = now
        end
        local ping = LP:GetNetworkPing() * 1000
        pingLabel.Text = math.floor(ping + 0.5) .. "ms"
    end)
    wm:SetAttribute("Connection", connection)
    self.watermark = wm
    return wm
end

function UILib:Destroy()
    for _, conn in ipairs(self.connections) do conn:Disconnect() end
    if self.watermark then
        local conn = self.watermark:GetAttribute("Connection")
        if conn then conn:Disconnect() end
        self.watermark:Destroy()
    end
    if self.sg then self.sg:Destroy() end
    if activeWindow == self then activeWindow = nil end
end

function UILib:setVisible(visible)
    if not self.window then return end
    if visible then
        self.window.Visible = true
        self.window.AnchorPoint = Vector2.new(0, 0)
        self.window.Size = UDim2.new(0, 0, 0, 0)
        self.window.Position = self.originalPosition
        local tween = TweenService:Create(self.window, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = self.originalSize})
        tween:Play()
    else
        self.originalPosition = self.window.Position
        self.originalSize = self.window.Size
        local centerPos = UDim2.new(self.originalPosition.X.Scale, self.originalPosition.X.Offset + self.originalSize.X.Offset/2, self.originalPosition.Y.Scale, self.originalPosition.Y.Offset + self.originalSize.Y.Offset/2)
        self.window.AnchorPoint = Vector2.new(0.5, 0.5)
        self.window.Position = centerPos
        local tween = TweenService:Create(self.window, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)})
        tween:Play()
        tween.Completed:Connect(function() self.window.Visible = false self.window.AnchorPoint = Vector2.new(0, 0) self.window.Size = self.originalSize self.window.Position = self.originalPosition end)
    end
end

function UILib:addTab(name)
    local tab = setmetatable({}, UILib.Tab)
    tab.name = name
    tab.window = self
    tab.subtabs = {}
    tab.firstSub = nil
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 110, 0, 46)
    btn.BackgroundTransparency = 1
    btn.Text = name:upper()
    btn.TextColor3 = self.theme.Gray
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Parent = self.navbar
    local underline = Instance.new("Frame")
    underline.Size = UDim2.new(0.55, 0, 0, 2)
    underline.Position = UDim2.new(0.225, 0, 1, -3)
    underline.BackgroundColor3 = self.theme.Accent
    underline.BorderSizePixel = 0
    underline.Visible = false
    underline.Parent = btn
    btn.MouseEnter:Connect(function() if btn.TextColor3 ~= self.theme.White then btn.TextColor3 = self.theme.GrayLt end end)
    btn.MouseLeave:Connect(function() if btn.TextColor3 ~= self.theme.White then btn.TextColor3 = self.theme.Gray end end)
    tab.btn = btn
    tab.underline = underline
    local function activate()
        if self.activeTab then
            self.activeTab.btn.TextColor3 = self.theme.Gray
            if self.activeTab.underline then self.activeTab.underline.Visible = false end
            for _, sub in pairs(self.activeTab.subtabs) do sub.btn.Visible = false sub.page.Visible = false sub.ind.Visible = false sub.lbl.TextColor3 = self.theme.Gray end
        end
        btn.TextColor3 = self.theme.White
        underline.Visible = true
        for _, sub in pairs(tab.subtabs) do sub.btn.Visible = true end
        if tab.firstSub then local first = tab.subtabs[tab.firstSub] if first then first.page.Visible = true first.ind.Visible = true first.lbl.TextColor3 = self.theme.White end end
        self.activeTab = tab
    end
    btn.MouseButton1Click:Connect(activate)
    tab.activate = activate
    self.tabs[name] = tab
    return tab
end

function UILib.Tab:addSubTab(subName)
    local sub = setmetatable({}, UILib.SubTab)
    sub.name = subName
    sub.tab = self
    sub.window = self.window
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Visible = false
    btn.Parent = self.window.sidebar
    local hover = Instance.new("Frame")
    hover.Size = UDim2.new(1, -2, 1, -1)
    hover.Position = UDim2.new(0, 1, 0, 0)
    hover.BackgroundColor3 = self.window.theme.ItemHov
    hover.BorderSizePixel = 0
    hover.Visible = false
    hover.ZIndex = 1
    hover.Parent = btn
    Instance.new("UICorner", hover).CornerRadius = UDim.new(0, 4)
    btn.MouseEnter:Connect(function() hover.Visible = true end)
    btn.MouseLeave:Connect(function() hover.Visible = false end)
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 3, 0.5, 0)
    indicator.Position = UDim2.new(0, 0, 0.25, 0)
    indicator.BackgroundColor3 = self.window.theme.Accent
    indicator.BorderSizePixel = 0
    indicator.Visible = false
    indicator.ZIndex = 3
    indicator.Parent = btn
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 2)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -8, 1, 0)
    lbl.Position = UDim2.new(0, 15, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = subName
    lbl.TextColor3 = self.window.theme.Gray
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 3
    lbl.Parent = btn
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, -14, 1, -12)
    page.Position = UDim2.new(0, 7, 0, 6)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 2
    page.ScrollBarImageColor3 = self.window.theme.Accent
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.ZIndex = 2
    page.Parent = self.window.content
    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    sub.btn = btn
    sub.ind = indicator
    sub.lbl = lbl
    sub.page = page
    sub.layout = layout
    sub.groups = {}
    local function activateSub()
        if self.window.activeTab ~= self then self:activate() end
        for _, s in pairs(self.subtabs) do s.page.Visible = false s.ind.Visible = false s.lbl.TextColor3 = self.window.theme.Gray end
        page.Visible = true indicator.Visible = true lbl.TextColor3 = self.window.theme.White
    end
    btn.MouseButton1Click:Connect(activateSub)
    if not self.firstSub then self.firstSub = subName end
    self.subtabs[subName] = sub
    return sub
end

function UILib.SubTab:split()
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 0)
    row.BackgroundTransparency = 1
    row.AutomaticSize = Enum.AutomaticSize.Y
    row.Parent = self.page
    row.LayoutOrder = 0
    local left = Instance.new("Frame")
    left.Size = UDim2.new(0.5, -6, 0, 0)
    left.BackgroundTransparency = 1
    left.AutomaticSize = Enum.AutomaticSize.Y
    left.Parent = row
    local right = Instance.new("Frame")
    right.Size = UDim2.new(0.5, -6, 0, 0)
    right.Position = UDim2.new(0.5, 6, 0, 0)
    right.BackgroundTransparency = 1
    right.AutomaticSize = Enum.AutomaticSize.Y
    right.Parent = row
    local leftLayout = Instance.new("UIListLayout", left)
    leftLayout.Padding = UDim.new(0, 8)
    leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
    local rightLayout = Instance.new("UIListLayout", right)
    rightLayout.Padding = UDim.new(0, 8)
    rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
    local leftCol = setmetatable({ frame = left, window = self.window, tab = self.tab }, UILib.Column)
    local rightCol = setmetatable({ frame = right, window = self.window, tab = self.tab }, UILib.Column)
    return leftCol, rightCol
end

local function generateID() return "elem_" .. HS:GenerateGUID(false) end

-- Tooltip attachment helper
local function attachTooltip(element, text)
    if not text then return end
    element.MouseEnter:Connect(function()
        local mousePos = UIS:GetMouseLocation()
        startTooltipDelay(text, Vector2.new(mousePos.X, mousePos.Y))
    end)
    element.MouseLeave:Connect(hideTooltip)
    element.MouseButton1Down:Connect(hideTooltip)
end

-- Enhanced slider with step and new design
local function createSlider(group, items, window, text, minVal, maxVal, defaultVal, callback, step)
    step = step or 1
    local id = generateID()
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 46)
    row.BackgroundTransparency = 1
    row.Parent = items
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 0, 18)
    label.Position = UDim2.new(0, 4, 0, 3)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = window.theme.GrayLt
    label.Font = Enum.Font.Roboto
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 3
    label.Parent = row
    local valueBox = Instance.new("Frame")
    valueBox.Size = UDim2.new(0, 60, 0, 22)
    valueBox.Position = UDim2.new(1, -64, 0, 1)
    valueBox.BackgroundColor3 = window.theme.Track
    valueBox.BorderSizePixel = 0
    valueBox.ZIndex = 3
    valueBox.Parent = row
    Instance.new("UICorner", valueBox).CornerRadius = UDim.new(0, 4)
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(1, 0, 1, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(defaultVal)
    valueLabel.TextColor3 = window.theme.Accent
    valueLabel.Font = Enum.Font.RobotoMono
    valueLabel.TextSize = 12
    valueLabel.ZIndex = 4
    valueLabel.Parent = valueBox
    local valueBoxInput = Instance.new("TextBox")
    valueBoxInput.Size = UDim2.new(1, 0, 1, 0)
    valueBoxInput.BackgroundTransparency = 1
    valueBoxInput.Text = tostring(defaultVal)
    valueBoxInput.TextColor3 = window.theme.Accent
    valueBoxInput.Font = Enum.Font.RobotoMono
    valueBoxInput.TextSize = 12
    valueBoxInput.Visible = false
    valueBoxInput.ZIndex = 5
    valueBoxInput.Parent = valueBox
    Instance.new("UICorner", valueBoxInput).CornerRadius = UDim.new(0, 4)
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, 0, 0, 4)
    track.Position = UDim2.new(0, 0, 0, 30)
    track.BackgroundColor3 = window.theme.Track
    track.BorderSizePixel = 0
    track.ZIndex = 3
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(0, 2)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = window.theme.Accent
    fill.BorderSizePixel = 0
    fill.ZIndex = 4
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 2)
    local gradient = Instance.new("UIGradient", fill)
    gradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, window.theme.Accent), ColorSequenceKeypoint.new(1, Color3.new(window.theme.Accent.r*0.8, window.theme.Accent.g*0.8, window.theme.Accent.b*0.8))})
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new((defaultVal - minVal) / (maxVal - minVal), -8, 0.5, -8)
    knob.BackgroundColor3 = window.theme.White
    knob.BorderSizePixel = 0
    knob.ZIndex = 5
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 8)
    local knobStroke = Instance.new("UIStroke", knob)
    knobStroke.Color = window.theme.Accent
    knobStroke.Thickness = 2
    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, 0, 0, 22)
    hit.Position = UDim2.new(0, 0, 0.5, -11)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.ZIndex = 6
    hit.Parent = track
    local sliding = false
    local currentVal = defaultVal
    local function roundToStep(val) return math.floor((val - minVal) / step + 0.5) * step + minVal end
    local function updateSlider(val)
        val = math.clamp(val, minVal, maxVal)
        val = roundToStep(val)
        currentVal = val
        local rel = (val - minVal) / (maxVal - minVal)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, -8, 0.5, -8)
        valueLabel.Text = tostring(val)
        valueBoxInput.Text = tostring(val)
        if callback then callback(val) end
        window.configs[id].Value = val
    end
    local function apply(mx)
        local rel = math.clamp((mx - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = minVal + (maxVal - minVal) * rel
        updateSlider(val)
    end
    hit.MouseButton1Down:Connect(function() sliding = true apply(UIS:GetMouseLocation().X) end)
    UIS.InputChanged:Connect(function(i) if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then apply(i.Position.X) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end end)
    valueLabel.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then valueLabel.Visible = false valueBoxInput.Visible = true valueBoxInput:CaptureFocus() valueBoxInput.Text = tostring(currentVal) valueBoxInput.TextColor3 = window.theme.Accent end end)
    valueBoxInput.FocusLost:Connect(function(enter)
        valueBoxInput.Visible = false valueLabel.Visible = true
        local num = tonumber(valueBoxInput.Text)
        if num then updateSlider(num) else valueLabel.Text = tostring(currentVal) end
    end)
    local elem = {ID = id, Value = currentVal, SetValue = updateSlider}
    window.configs[id] = elem
    return row
end

-- Color picker dropdown version
local function createColorPicker(group, items, window, text, default, callback)
    local id = generateID()
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 28)
    row.BackgroundTransparency = 1
    row.Parent = items
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -62, 1, 0)
    label.Position = UDim2.new(0, 4, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = window.theme.White
    label.Font = Enum.Font.Roboto
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 3
    label.Parent = row
    local colorBox = Instance.new("Frame")
    colorBox.Size = UDim2.new(0, 40, 0, 20)
    colorBox.Position = UDim2.new(1, -44, 0.5, -10)
    colorBox.BackgroundColor3 = default or Color3.new(1,0,0)
    colorBox.BorderSizePixel = 0
    colorBox.ZIndex = 4
    colorBox.Parent = row
    Instance.new("UICorner", colorBox).CornerRadius = UDim.new(0, 3)
    local stroke = Instance.new("UIStroke", colorBox)
    stroke.Color = window.theme.Border
    stroke.Thickness = 1
    local current = default or Color3.new(1,0,0)
    local pickerFrame = nil
    local function closePicker()
        if pickerFrame then pickerFrame:Destroy() pickerFrame = nil end
    end
    local function openPicker()
        if pickerFrame then closePicker() return end
        pickerFrame = Instance.new("Frame")
        pickerFrame.Size = UDim2.new(0, 200, 0, 160)
        pickerFrame.Position = UDim2.new(0, 0, 1, 2)
        pickerFrame.BackgroundColor3 = window.theme.Panel
        pickerFrame.BorderSizePixel = 0
        pickerFrame.ZIndex = 50
        pickerFrame.Parent = row
        Instance.new("UICorner", pickerFrame).CornerRadius = UDim.new(0, 6)
        local pickerStroke = Instance.new("UIStroke", pickerFrame)
        pickerStroke.Color = window.theme.Accent
        local hueSlider = Instance.new("Frame")
        hueSlider.Size = UDim2.new(0, 180, 0, 16)
        hueSlider.Position = UDim2.new(0.5, -90, 0, 8)
        hueSlider.BackgroundColor3 = Color3.new(1,1,1)
        hueSlider.ZIndex = 51
        hueSlider.Parent = pickerFrame
        local hueGradient = Instance.new("UIGradient", hueSlider)
        hueGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.new(1,0,0)), ColorSequenceKeypoint.new(0.17, Color3.new(1,1,0)), ColorSequenceKeypoint.new(0.33, Color3.new(0,1,0)), ColorSequenceKeypoint.new(0.5, Color3.new(0,1,1)), ColorSequenceKeypoint.new(0.67, Color3.new(0,0,1)), ColorSequenceKeypoint.new(0.83, Color3.new(1,0,1)), ColorSequenceKeypoint.new(1, Color3.new(1,0,0))}
        hueGradient.Rotation = 90
        local hueKnob = Instance.new("Frame")
        hueKnob.Size = UDim2.new(0, 10, 0, 10)
        hueKnob.Position = UDim2.new(0, 0, 0.5, -5)
        hueKnob.BackgroundColor3 = window.theme.White
        hueKnob.BorderSizePixel = 0
        hueKnob.ZIndex = 52
        hueKnob.Parent = hueSlider
        Instance.new("UICorner", hueKnob).CornerRadius = UDim.new(0, 5)
        local hueKnobStroke = Instance.new("UIStroke", hueKnob)
        hueKnobStroke.Color = window.theme.Accent
        local satValSquare = Instance.new("Frame")
        satValSquare.Size = UDim2.new(0, 160, 0, 80)
        satValSquare.Position = UDim2.new(0.5, -80, 0, 32)
        satValSquare.BackgroundColor3 = Color3.new(1,1,1)
        satValSquare.ZIndex = 51
        satValSquare.Parent = pickerFrame
        local satValKnob = Instance.new("Frame")
        satValKnob.Size = UDim2.new(0, 10, 0, 10)
        satValKnob.Position = UDim2.new(0, 0, 0, 0)
        satValKnob.BackgroundColor3 = window.theme.White
        satValKnob.BorderSizePixel = 0
        satValKnob.ZIndex = 52
        satValKnob.Parent = satValSquare
        Instance.new("UICorner", satValKnob).CornerRadius = UDim.new(0, 5)
        local satValKnobStroke = Instance.new("UIStroke", satValKnob)
        satValKnobStroke.Color = window.theme.Accent
        local hueDragging = false
        local svDragging = false
        local function updateHue(pos)
            local rel = math.clamp((pos - hueSlider.AbsolutePosition.X) / hueSlider.AbsoluteSize.X, 0, 1)
            hueKnob.Position = UDim2.new(rel, -5, 0.5, -5)
            local h = rel
            local c = Color3.fromHSV(h, 1, 1)
            satValSquare.BackgroundColor3 = c
            local svRelX = satValKnob.Position.X.Scale + satValKnob.Position.X.Offset / satValSquare.AbsoluteSize.X
            local svRelY = satValKnob.Position.Y.Scale + satValKnob.Position.Y.Offset / satValSquare.AbsoluteSize.Y
            svRelX = math.clamp(svRelX, 0, 1)
            svRelY = math.clamp(svRelY, 0, 1)
            current = Color3.fromHSV(h, svRelX, 1 - svRelY)
            colorBox.BackgroundColor3 = current
            if callback then callback(current) end
        end
        local function updateSV(pos)
            local relX = math.clamp((pos.X - satValSquare.AbsolutePosition.X) / satValSquare.AbsoluteSize.X, 0, 1)
            local relY = math.clamp((pos.Y - satValSquare.AbsolutePosition.Y) / satValSquare.AbsoluteSize.Y, 0, 1)
            satValKnob.Position = UDim2.new(relX, -5, relY, -5)
            local h = hueKnob.Position.X.Scale + hueKnob.Position.X.Offset / hueSlider.AbsoluteSize.X
            h = math.clamp(h, 0, 1)
            current = Color3.fromHSV(h, relX, 1 - relY)
            colorBox.BackgroundColor3 = current
            if callback then callback(current) end
        end
        hueSlider.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then hueDragging = true updateHue(input.Position) end end)
        hueSlider.InputChanged:Connect(function(input) if hueDragging and input.UserInputType == Enum.UserInputType.MouseMovement then updateHue(input.Position) end end)
        satValSquare.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then svDragging = true updateSV(input.Position) end end)
        satValSquare.InputChanged:Connect(function(input) if svDragging and input.UserInputType == Enum.UserInputType.MouseMovement then updateSV(input.Position) end end)
        UIS.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then hueDragging = false svDragging = false end end)
        local inputBeganConn
        inputBeganConn = UIS.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local pos = UIS:GetMouseLocation()
                local absPos = pickerFrame.AbsolutePosition
                local absSize = pickerFrame.AbsoluteSize
                if pos.X < absPos.X or pos.X > absPos.X + absSize.X or pos.Y < absPos.Y or pos.Y > absPos.Y + absSize.Y then
                    closePicker()
                    inputBeganConn:Disconnect()
                end
            end
        end)
    end
    colorBox.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then openPicker() end end)
    local elem = {ID = id, Value = current, SetValue = function(val) current = val colorBox.BackgroundColor3 = val if callback then callback(val) end end}
    window.configs[id] = elem
    return row
end

-- Multi-select with selected highlight
local function createMultiDropdown(group, items, window, text, options, default, callback)
    local id = generateID()
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 52)
    row.BackgroundTransparency = 1
    row.ClipsDescendants = false
    row.ZIndex = 10
    row.Parent = items
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 18)
    label.Position = UDim2.new(0, 4, 0, 2)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = window.theme.GrayLt
    label.Font = Enum.Font.Roboto
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 11
    label.Parent = row
    local dbtn = Instance.new("TextButton")
    dbtn.Size = UDim2.new(1, 0, 0, 28)
    dbtn.Position = UDim2.new(0, 0, 0, 22)
    dbtn.BackgroundColor3 = window.theme.Track
    dbtn.BorderSizePixel = 0
    dbtn.Text = ""
    dbtn.ZIndex = 11
    dbtn.Parent = row
    Instance.new("UICorner", dbtn).CornerRadius = UDim.new(0, 4)
    local dstroke = Instance.new("UIStroke", dbtn)
    dstroke.Color = window.theme.Border
    dstroke.Thickness = 1
    local selLbl = Instance.new("TextLabel")
    selLbl.Size = UDim2.new(1, -34, 1, 0)
    selLbl.Position = UDim2.new(0, 10, 0, 0)
    selLbl.BackgroundTransparency = 1
    selLbl.Text = default and #default > 0 and table.concat(default, ", ") or "None"
    selLbl.TextColor3 = window.theme.White
    selLbl.Font = Enum.Font.GothamBold
    selLbl.TextSize = 12
    selLbl.TextXAlignment = Enum.TextXAlignment.Left
    selLbl.ZIndex = 12
    selLbl.Parent = dbtn
    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 24, 1, 0)
    arrow.Position = UDim2.new(1, -26, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.TextColor3 = window.theme.Accent
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 12
    arrow.ZIndex = 12
    arrow.Parent = dbtn
    local listH = #options * 26
    local dlist = Instance.new("ScrollingFrame")
    dlist.Size = UDim2.new(1, 0, 0, math.min(listH, 104))
    dlist.Position = UDim2.new(0, 0, 0, 52)
    dlist.BackgroundColor3 = window.theme.Item
    dlist.BorderSizePixel = 0
    dlist.ScrollBarThickness = 2
    dlist.ScrollBarImageColor3 = window.theme.Accent
    dlist.CanvasSize = UDim2.new(0, 0, 0, listH)
    dlist.Visible = false
    dlist.ZIndex = 50
    dlist.Parent = row
    Instance.new("UICorner", dlist).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", dlist).Color = window.theme.Accent
    local dlayout = Instance.new("UIListLayout", dlist)
    dlayout.SortOrder = Enum.SortOrder.LayoutOrder
    dlayout.Padding = UDim.new(0, 0)
    local selected = default or {}
    local checks = {}
    local backgrounds = {}
    for _, opt in ipairs(options) do
        local ob = Instance.new("TextButton")
        ob.Size = UDim2.new(1, 0, 0, 26)
        ob.BackgroundTransparency = 1
        ob.Text = ""
        ob.ZIndex = 51
        ob.Parent = dlist
        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1, -4, 1, -2)
        bg.Position = UDim2.new(0, 2, 0, 1)
        bg.BackgroundColor3 = window.theme.Accent
        bg.BackgroundTransparency = 0.8
        bg.BorderSizePixel = 0
        bg.Visible = selected[opt] and true or false
        bg.ZIndex = 51
        bg.Parent = ob
        Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 4)
        backgrounds[opt] = bg
        local oh = Instance.new("Frame")
        oh.Size = UDim2.new(1, -4, 1, -2)
        oh.Position = UDim2.new(0, 2, 0, 1)
        oh.BackgroundColor3 = window.theme.ItemHov
        oh.BorderSizePixel = 0
        oh.Visible = false
        oh.ZIndex = 51
        oh.Parent = ob
        Instance.new("UICorner", oh).CornerRadius = UDim.new(0, 4)
        local ol = Instance.new("TextLabel")
        ol.Size = UDim2.new(1, -22, 1, 0)
        ol.Position = UDim2.new(0, 10, 0, 0)
        ol.BackgroundTransparency = 1
        ol.Text = opt
        ol.TextColor3 = window.theme.GrayLt
        ol.Font = Enum.Font.Roboto
        ol.TextSize = 12
        ol.TextXAlignment = Enum.TextXAlignment.Left
        ol.ZIndex = 52
        ol.Parent = ob
        local ck = Instance.new("TextLabel")
        ck.Size = UDim2.new(0, 18, 1, 0)
        ck.Position = UDim2.new(1, -20, 0, 0)
        ck.BackgroundTransparency = 1
        ck.Text = selected[opt] and "×" or ""
        ck.TextColor3 = window.theme.Accent
        ck.Font = Enum.Font.GothamBold
        ck.TextSize = 12
        ck.ZIndex = 52
        ck.Parent = ob
        checks[opt] = ck
        ob.MouseEnter:Connect(function() oh.Visible = true ol.TextColor3 = window.theme.White end)
        ob.MouseLeave:Connect(function() oh.Visible = false ol.TextColor3 = window.theme.GrayLt end)
        ob.MouseButton1Click:Connect(function()
            if selected[opt] then
                selected[opt] = nil
                ck.Text = ""
                bg.Visible = false
            else
                selected[opt] = true
                ck.Text = "×"
                bg.Visible = true
            end
            local keys = {}
            for k, _ in pairs(selected) do table.insert(keys, k) end
            selLbl.Text = #keys > 0 and table.concat(keys, ", ") or "None"
            if callback then callback(keys) end
            window.configs[id].Value = keys
        end)
    end
    local open = false
    dbtn.MouseButton1Click:Connect(function()
        open = not open
        dlist.Visible = open
        arrow.Text = open and "▲" or "▼"
        row.Size = UDim2.new(1, 0, 0, 52 + (open and math.min(listH, 104) or 0))
        group.updateSize()
    end)
    local elem = {ID = id, Value = selected, SetValue = function(t)
        selected = {}
        for _, opt in ipairs(t) do selected[opt] = true end
        for opt, ck in pairs(checks) do
            local sel = selected[opt] or false
            ck.Text = sel and "×" or ""
            if backgrounds[opt] then backgrounds[opt].Visible = sel end
        end
        local keys = {}
        for k, _ in pairs(selected) do table.insert(keys, k) end
        selLbl.Text = #keys > 0 and table.concat(keys, ", ") or "None"
        if callback then callback(keys) end
    end}
    window.configs[id] = elem
    return row
end

-- Column:addGroup (element methods)
function UILib.Column:addGroup(title)
    local window = self.window
    if not window then error("No window reference in column") end
    local group = {}
    group.title = title
    group.window = window
    group.tab = self.tab
    group.columnFrame = self.frame
    local grp = Instance.new("Frame")
    grp.Size = UDim2.new(1, 0, 0, 36)
    grp.BackgroundColor3 = window.theme.Item
    grp.BorderSizePixel = 0
    grp.Parent = self.frame
    Instance.new("UICorner", grp).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke", grp)
    stroke.Color = window.theme.Border
    stroke.Thickness = 1
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundTransparency = 1
    row.Parent = grp
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -30, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = title:upper()
    label.TextColor3 = window.theme.GrayLt
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 2
    label.Parent = row
    local items = Instance.new("Frame")
    items.Position = UDim2.new(0, 0, 0, 30)
    items.Size = UDim2.new(1, 0, 0, 0)
    items.BackgroundTransparency = 1
    items.BorderSizePixel = 0
    items.Parent = grp
    local itemLayout = Instance.new("UIListLayout", items)
    itemLayout.Padding = UDim.new(0, 2)
    itemLayout.SortOrder = Enum.SortOrder.LayoutOrder
    local padding = Instance.new("UIPadding", items)
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 6)
    local function updateSize()
        local ih = itemLayout.AbsoluteContentSize.Y
        items.Size = UDim2.new(1, 0, 0, ih + 8)
        grp.Size = UDim2.new(1, 0, 0, ih + 46)
    end
    itemLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSize)
    group.frame = grp
    group.items = items
    group.itemLayout = itemLayout
    group.updateSize = updateSize

    -- Element methods with tooltip support
    function group:toggle(text, default, callback, tooltip)
        local id = generateID()
        local row = Instance.new("TextButton")
        row.Size = UDim2.new(1, 0, 0, 28)
        row.BackgroundTransparency = 1
        row.Text = ""
        row.ZIndex = 3
        row.Parent = items
        local rh = Instance.new("Frame")
        rh.Size = UDim2.new(1, 0, 1, 0)
        rh.BackgroundColor3 = window.theme.ItemHov
        rh.BorderSizePixel = 0
        rh.Visible = false
        rh.ZIndex = 2
        rh.Parent = row
        Instance.new("UICorner", rh).CornerRadius = UDim.new(0, 4)
        row.MouseEnter:Connect(function() rh.Visible = true end)
        row.MouseLeave:Connect(function() rh.Visible = false end)
        local cbOuter = Instance.new("Frame")
        cbOuter.Size = UDim2.new(0, 18, 0, 18)
        cbOuter.Position = UDim2.new(1, -22, 0.5, -9)
        cbOuter.BackgroundColor3 = default and window.theme.Accent or window.theme.Track
        cbOuter.BorderSizePixel = 0
        cbOuter.ZIndex = 4
        cbOuter.Parent = row
        Instance.new("UICorner", cbOuter).CornerRadius = UDim.new(0, 4)
        local cbStroke = Instance.new("UIStroke", cbOuter)
        cbStroke.Color = default and window.theme.AccentD or window.theme.Border
        cbStroke.Thickness = 1
        local cbMark = Instance.new("TextLabel")
        cbMark.Size = UDim2.new(1, 0, 1, 0)
        cbMark.BackgroundTransparency = 1
        cbMark.Text = default and "×" or ""
        cbMark.TextColor3 = Color3.new(1,1,1)
        cbMark.Font = Enum.Font.GothamBold
        cbMark.TextSize = 16
        cbMark.ZIndex = 5
        cbMark.Parent = cbOuter
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -32, 1, 0)
        label.Position = UDim2.new(0, 4, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = window.theme.White
        label.Font = Enum.Font.Roboto
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 4
        label.Parent = row
        local state = default
        local elem = {ID = id, Value = state, SetValue = function(val) state = val cbOuter.BackgroundColor3 = state and window.theme.Accent or window.theme.Track cbStroke.Color = state and window.theme.AccentD or window.theme.Border cbMark.Text = state and "×" or "" if callback then callback(state) end end}
        window.configs[id] = elem
        row.MouseButton1Click:Connect(function() state = not state elem:SetValue(state) end)
        if tooltip then attachTooltip(row, tooltip) end
        updateSize()
        return row
    end

    function group:slider(text, minVal, maxVal, defaultVal, callback, step, tooltip)
        local row = createSlider(group, items, window, text, minVal, maxVal, defaultVal, callback, step)
        if tooltip then attachTooltip(row, tooltip) end
        updateSize()
        return row
    end

    function group:dropdown(text, options, default, callback, tooltip)
        local id = generateID()
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 52)
        row.BackgroundTransparency = 1
        row.ClipsDescendants = false
        row.ZIndex = 10
        row.Parent = items
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 18)
        label.Position = UDim2.new(0, 4, 0, 2)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = window.theme.GrayLt
        label.Font = Enum.Font.Roboto
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 11
        label.Parent = row
        local dbtn = Instance.new("TextButton")
        dbtn.Size = UDim2.new(1, 0, 0, 28)
        dbtn.Position = UDim2.new(0, 0, 0, 22)
        dbtn.BackgroundColor3 = window.theme.Track
        dbtn.BorderSizePixel = 0
        dbtn.Text = ""
        dbtn.ZIndex = 11
        dbtn.Parent = row
        Instance.new("UICorner", dbtn).CornerRadius = UDim.new(0, 4)
        local dstroke = Instance.new("UIStroke", dbtn)
        dstroke.Color = window.theme.Border
        dstroke.Thickness = 1
        local selLbl = Instance.new("TextLabel")
        selLbl.Size = UDim2.new(1, -34, 1, 0)
        selLbl.Position = UDim2.new(0, 10, 0, 0)
        selLbl.BackgroundTransparency = 1
        selLbl.Text = default
        selLbl.TextColor3 = window.theme.White
        selLbl.Font = Enum.Font.GothamBold
        selLbl.TextSize = 12
        selLbl.TextXAlignment = Enum.TextXAlignment.Left
        selLbl.ZIndex = 12
        selLbl.Parent = dbtn
        local arrow = Instance.new("TextLabel")
        arrow.Size = UDim2.new(0, 24, 1, 0)
        arrow.Position = UDim2.new(1, -26, 0, 0)
        arrow.BackgroundTransparency = 1
        arrow.Text = "▼"
        arrow.TextColor3 = window.theme.Accent
        arrow.Font = Enum.Font.GothamBold
        arrow.TextSize = 12
        arrow.ZIndex = 12
        arrow.Parent = dbtn
        local listH = #options * 26
        local dlist = Instance.new("ScrollingFrame")
        dlist.Size = UDim2.new(1, 0, 0, math.min(listH, 104))
        dlist.Position = UDim2.new(0, 0, 0, 52)
        dlist.BackgroundColor3 = window.theme.Item
        dlist.BorderSizePixel = 0
        dlist.ScrollBarThickness = 2
        dlist.ScrollBarImageColor3 = window.theme.Accent
        dlist.CanvasSize = UDim2.new(0, 0, 0, listH)
        dlist.Visible = false
        dlist.ZIndex = 50
        dlist.Parent = row
        Instance.new("UICorner", dlist).CornerRadius = UDim.new(0, 4)
        Instance.new("UIStroke", dlist).Color = window.theme.Accent
        local dlayout = Instance.new("UIListLayout", dlist)
        dlayout.SortOrder = Enum.SortOrder.LayoutOrder
        dlayout.Padding = UDim.new(0, 0)
        local checks = {}
        for _, opt in ipairs(options) do
            local ob = Instance.new("TextButton")
            ob.Size = UDim2.new(1, 0, 0, 26)
            ob.BackgroundTransparency = 1
            ob.Text = ""
            ob.ZIndex = 51
            ob.Parent = dlist
            local oh = Instance.new("Frame")
            oh.Size = UDim2.new(1, -4, 1, -2)
            oh.Position = UDim2.new(0, 2, 0, 1)
            oh.BackgroundColor3 = window.theme.ItemHov
            oh.BorderSizePixel = 0
            oh.Visible = false
            oh.ZIndex = 51
            oh.Parent = ob
            Instance.new("UICorner", oh).CornerRadius = UDim.new(0, 4)
            local ol = Instance.new("TextLabel")
            ol.Size = UDim2.new(1, -22, 1, 0)
            ol.Position = UDim2.new(0, 10, 0, 0)
            ol.BackgroundTransparency = 1
            ol.Text = opt
            ol.TextColor3 = window.theme.GrayLt
            ol.Font = Enum.Font.Roboto
            ol.TextSize = 12
            ol.TextXAlignment = Enum.TextXAlignment.Left
            ol.ZIndex = 52
            ol.Parent = ob
            local ck = Instance.new("TextLabel")
            ck.Size = UDim2.new(0, 18, 1, 0)
            ck.Position = UDim2.new(1, -20, 0, 0)
            ck.BackgroundTransparency = 1
            ck.Text = (opt == default) and "×" or ""
            ck.TextColor3 = window.theme.Accent
            ck.Font = Enum.Font.GothamBold
            ck.TextSize = 12
            ck.ZIndex = 52
            ck.Parent = ob
            checks[opt] = ck
            if opt == default then
                local bg = Instance.new("Frame")
                bg.Size = UDim2.new(1, 0, 1, 0)
                bg.BackgroundColor3 = window.theme.Accent
                bg.BackgroundTransparency = 0.8
                bg.ZIndex = 50
                bg.Parent = ob
            end
            ob.MouseEnter:Connect(function() oh.Visible = true ol.TextColor3 = window.theme.White end)
            ob.MouseLeave:Connect(function() oh.Visible = false ol.TextColor3 = window.theme.GrayLt end)
            ob.MouseButton1Click:Connect(function()
                selLbl.Text = opt
                for _, c in pairs(checks) do c.Text = "" end
                ck.Text = "×"
                dlist.Visible = false
                arrow.Text = "▼"
                row.Size = UDim2.new(1, 0, 0, 52)
                if callback then callback(opt) end
                window.configs[id].Value = opt
            end)
        end
        local open = false
        dbtn.MouseButton1Click:Connect(function()
            open = not open
            dlist.Visible = open
            arrow.Text = open and "▲" or "▼"
            row.Size = UDim2.new(1, 0, 0, 52 + (open and math.min(listH, 104) or 0))
            updateSize()
        end)
        local elem = {ID = id, Value = default, SetValue = function(val) selLbl.Text = val for opt, ck in pairs(checks) do ck.Text = (opt == val) and "×" or "" end if callback then callback(val) end end}
        window.configs[id] = elem
        if tooltip then attachTooltip(row, tooltip) end
        updateSize()
        return row
    end

    function group:keybind(text, currentName, onChange, tooltip)
        local id = generateID()
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 30)
        row.BackgroundTransparency = 1
        row.Parent = items
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -82, 1, 0)
        label.Position = UDim2.new(0, 4, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = window.theme.White
        label.Font = Enum.Font.Roboto
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 3
        label.Parent = row
        local kbtn = Instance.new("TextButton")
        kbtn.Size = UDim2.new(0, 76, 0, 22)
        kbtn.Position = UDim2.new(1, -78, 0.5, -11)
        kbtn.BackgroundColor3 = window.theme.Track
        kbtn.BorderSizePixel = 0
        kbtn.Text = currentName
        kbtn.TextColor3 = window.theme.Accent
        kbtn.Font = Enum.Font.GothamBold
        kbtn.TextSize = 11
        kbtn.ZIndex = 4
        kbtn.Parent = row
        Instance.new("UICorner", kbtn).CornerRadius = UDim.new(0, 4)
        local kstroke = Instance.new("UIStroke", kbtn)
        kstroke.Color = window.theme.Border
        kstroke.Thickness = 1
        local listening = false
        local skipNext = false
        kbtn.MouseButton1Click:Connect(function()
            if listening then return end
            listening = true
            skipNext = true
            kbtn.Text = "[...]"
            kbtn.TextColor3 = window.theme.White
            kbtn.BackgroundColor3 = window.theme.Accent
            kstroke.Color = window.theme.AccentD
            local con
            con = UIS.InputBegan:Connect(function(i)
                if skipNext and i.UserInputType == Enum.UserInputType.MouseButton1 then skipNext = false return end
                listening = false
                con:Disconnect()
                kbtn.BackgroundColor3 = window.theme.Track
                kstroke.Color = window.theme.Border
                if i.KeyCode == Enum.KeyCode.Escape then kbtn.Text = currentName kbtn.TextColor3 = window.theme.Accent return end
                local u = i.UserInputType
                if u == Enum.UserInputType.Keyboard then
                    kbtn.Text = i.KeyCode.Name
                    kbtn.TextColor3 = window.theme.Accent
                    onChange(i.KeyCode, i.KeyCode.Name)
                    window.configs[id].Value = i.KeyCode.Name
                elseif u == Enum.UserInputType.MouseButton2 then
                    kbtn.Text = "RMB"
                    kbtn.TextColor3 = window.theme.Accent
                    onChange(Enum.UserInputType.MouseButton2, "RMB")
                    window.configs[id].Value = "RMB"
                elseif u == Enum.UserInputType.MouseButton1 then
                    kbtn.Text = "LMB"
                    kbtn.TextColor3 = window.theme.Accent
                    onChange(Enum.UserInputType.MouseButton1, "LMB")
                    window.configs[id].Value = "LMB"
                elseif u == Enum.UserInputType.MouseButton3 then
                    kbtn.Text = "MMB"
                    kbtn.TextColor3 = window.theme.Accent
                    onChange(Enum.UserInputType.MouseButton3, "MMB")
                    window.configs[id].Value = "MMB"
                else
                    kbtn.Text = currentName
                    kbtn.TextColor3 = window.theme.Accent
                end
            end)
        end)
        local elem = {ID = id, Value = currentName, SetValue = function(val) kbtn.Text = val end}
        window.configs[id] = elem
        if tooltip then attachTooltip(row, tooltip) end
        updateSize()
        return row
    end

    function group:label(text, color, tooltip)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, 20)
        f.BackgroundTransparency = 1
        f.Parent = items
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.Position = UDim2.new(0, 4, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = color or window.theme.Gray
        lbl.Font = Enum.Font.Roboto
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 3
        lbl.Parent = f
        if tooltip then attachTooltip(f, tooltip) end
        updateSize()
        return f
    end

    function group:button(text, callback, tooltip)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 28)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.ZIndex = 3
        btn.Parent = items
        local rh = Instance.new("Frame")
        rh.Size = UDim2.new(1, 0, 1, 0)
        rh.BackgroundColor3 = window.theme.ItemHov
        rh.BorderSizePixel = 0
        rh.Visible = false
        rh.ZIndex = 2
        rh.Parent = btn
        Instance.new("UICorner", rh).CornerRadius = UDim.new(0, 4)
        btn.MouseEnter:Connect(function() rh.Visible = true end)
        btn.MouseLeave:Connect(function() rh.Visible = false end)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.Position = UDim2.new(0, 4, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = window.theme.White
        label.Font = Enum.Font.Roboto
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 4
        label.Parent = btn
        btn.MouseButton1Click:Connect(callback)
        if tooltip then attachTooltip(btn, tooltip) end
        updateSize()
        return btn
    end

    function group:expandableToggle(text, default, contentFunc, tooltip)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, 0, 0, 30)
        container.BackgroundTransparency = 1
        container.ClipsDescendants = true
        container.Parent = items
        local toggleRow = Instance.new("TextButton")
        toggleRow.Size = UDim2.new(1, 0, 0, 30)
        toggleRow.BackgroundTransparency = 1
        toggleRow.Text = ""
        toggleRow.ZIndex = 3
        toggleRow.Parent = container
        local rh = Instance.new("Frame")
        rh.Size = UDim2.new(1, 0, 1, 0)
        rh.BackgroundColor3 = window.theme.ItemHov
        rh.BorderSizePixel = 0
        rh.Visible = false
        rh.ZIndex = 2
        rh.Parent = toggleRow
        Instance.new("UICorner", rh).CornerRadius = UDim.new(0, 4)
        toggleRow.MouseEnter:Connect(function() rh.Visible = true end)
        toggleRow.MouseLeave:Connect(function() rh.Visible = false end)
        local cbOuter = Instance.new("Frame")
        cbOuter.Size = UDim2.new(0, 18, 0, 18)
        cbOuter.Position = UDim2.new(1, -22, 0.5, -9)
        cbOuter.BackgroundColor3 = default and window.theme.Accent or window.theme.Track
        cbOuter.BorderSizePixel = 0
        cbOuter.ZIndex = 4
        cbOuter.Parent = toggleRow
        Instance.new("UICorner", cbOuter).CornerRadius = UDim.new(0, 4)
        local cbStroke = Instance.new("UIStroke", cbOuter)
        cbStroke.Color = default and window.theme.AccentD or window.theme.Border
        cbStroke.Thickness = 1
        local cbMark = Instance.new("TextLabel")
        cbMark.Size = UDim2.new(1, 0, 1, 0)
        cbMark.BackgroundTransparency = 1
        cbMark.Text = default and "×" or ""
        cbMark.TextColor3 = Color3.new(1,1,1)
        cbMark.Font = Enum.Font.GothamBold
        cbMark.TextSize = 16
        cbMark.ZIndex = 5
        cbMark.Parent = cbOuter
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -32, 1, 0)
        label.Position = UDim2.new(0, 4, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = window.theme.White
        label.Font = Enum.Font.Roboto
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 4
        label.Parent = toggleRow
        local contentFrame = Instance.new("Frame")
        contentFrame.Size = UDim2.new(1, 0, 0, 0)
        contentFrame.Position = UDim2.new(0, 0, 0, 30)
        contentFrame.BackgroundTransparency = 1
        contentFrame.Parent = container
        local contentLayout = Instance.new("UIListLayout", contentFrame)
        contentLayout.Padding = UDim.new(0, 2)
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        local function updateContentSize()
            local h = contentLayout.AbsoluteContentSize.Y
            contentFrame.Size = UDim2.new(1, 0, 0, h)
            container.Size = UDim2.new(1, 0, 0, 30 + (default and h or 0))
            updateSize()
        end
        contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateContentSize)
        local nestedGroup = {}
        function nestedGroup:toggle(subText, subDefault, subCallback, subTooltip) local row = group:toggle(subText, subDefault, subCallback, subTooltip) row.Parent = contentFrame updateContentSize() return row end
        function nestedGroup:slider(subText, min, max, default, subCallback, step, subTooltip) local row = group:slider(subText, min, max, default, subCallback, step, subTooltip) row.Parent = contentFrame updateContentSize() return row end
        function nestedGroup:dropdown(subText, options, default, subCallback, subTooltip) local row = group:dropdown(subText, options, default, subCallback, subTooltip) row.Parent = contentFrame updateContentSize() return row end
        function nestedGroup:keybind(subText, current, subCallback, subTooltip) local row = group:keybind(subText, current, subCallback, subTooltip) row.Parent = contentFrame updateContentSize() return row end
        function nestedGroup:label(subText, color, subTooltip) local row = group:label(subText, color, subTooltip) row.Parent = contentFrame updateContentSize() return row end
        function nestedGroup:button(subText, subCallback, subTooltip) local row = group:button(subText, subCallback, subTooltip) row.Parent = contentFrame updateContentSize() return row end
        function nestedGroup:colorpicker(subText, subDefault, subCallback, subTooltip) local row = group:colorpicker(subText, subDefault, subCallback, subTooltip) row.Parent = contentFrame updateContentSize() return row end
        function nestedGroup:multidropdown(subText, options, default, subCallback, subTooltip) local row = group:multidropdown(subText, options, default, subCallback, subTooltip) row.Parent = contentFrame updateContentSize() return row end
        function nestedGroup:textbox(subText, default, subCallback, subTooltip) local row = group:textbox(subText, default, subCallback, subTooltip) row.Parent = contentFrame updateContentSize() return row end
        function nestedGroup:numberbox(subText, default, min, max, subCallback, subTooltip) local row = group:numberbox(subText, default, min, max, subCallback, subTooltip) row.Parent = contentFrame updateContentSize() return row end
        function nestedGroup:rangeslider(subText, min, max, defaultMin, defaultMax, subCallback, subTooltip) local row = group:rangeslider(subText, min, max, defaultMin, defaultMax, subCallback, subTooltip) row.Parent = contentFrame updateContentSize() return row end
        if contentFunc then contentFunc(nestedGroup) end
        local state = default
        toggleRow.MouseButton1Click:Connect(function() state = not state cbOuter.BackgroundColor3 = state and window.theme.Accent or window.theme.Track cbStroke.Color = state and window.theme.AccentD or window.theme.Border cbMark.Text = state and "×" or "" container.Size = UDim2.new(1, 0, 0, 30 + (state and contentLayout.AbsoluteContentSize.Y or 0)) updateSize() end)
        if tooltip then attachTooltip(toggleRow, tooltip) end
        updateContentSize()
        return container
    end

    function group:collapsible(text, default, contentFunc, tooltip)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, 0, 0, 30)
        container.BackgroundTransparency = 1
        container.ClipsDescendants = true
        container.Parent = items
        local toggleRow = Instance.new("TextButton")
        toggleRow.Size = UDim2.new(1, 0, 0, 30)
        toggleRow.BackgroundTransparency = 1
        toggleRow.Text = ""
        toggleRow.ZIndex = 3
        toggleRow.Parent = container
        local rh = Instance.new("Frame")
        rh.Size = UDim2.new(1, 0, 1, 0)
        rh.BackgroundColor3 = window.theme.ItemHov
        rh.BorderSizePixel = 0
        rh.Visible = false
        rh.ZIndex = 2
        rh.Parent = toggleRow
        Instance.new("UICorner", rh).CornerRadius = UDim.new(0, 4)
        toggleRow.MouseEnter:Connect(function() rh.Visible = true end)
        toggleRow.MouseLeave:Connect(function() rh.Visible = false end)
        local arrow = Instance.new("TextLabel")
        arrow.Size = UDim2.new(0, 20, 1, 0)
        arrow.Position = UDim2.new(1, -22, 0, 0)
        arrow.BackgroundTransparency = 1
        arrow.Text = default and "▼" or "▶"
        arrow.TextColor3 = window.theme.Accent
        arrow.Font = Enum.Font.GothamBold
        arrow.TextSize = 14
        arrow.ZIndex = 4
        arrow.Parent = toggleRow
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -28, 1, 0)
        label.Position = UDim2.new(0, 4, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = window.theme.White
        label.Font = Enum.Font.Roboto
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 4
        label.Parent = toggleRow
        local contentFrame = Instance.new("Frame")
        contentFrame.Size = UDim2.new(1, 0, 0, 0)
        contentFrame.Position = UDim2.new(0, 0, 0, 30)
        contentFrame.BackgroundTransparency = 1
        contentFrame.Parent = container
        local contentLayout = Instance.new("UIListLayout", contentFrame)
        contentLayout.Padding = UDim.new(0, 2)
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        local function updateContentSize()
            local h = contentLayout.AbsoluteContentSize.Y
            contentFrame.Size = UDim2.new(1, 0, 0, h)
            container.Size = UDim2.new(1, 0, 0, 30 + (default and h or 0))
            updateSize()
        end
        contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateContentSize)
        local nestedGroup = {}
        function nestedGroup:toggle(subText, subDefault, subCallback, subTooltip) local row = group:toggle(subText, subDefault, subCallback, subTooltip) row.Parent = contentFrame updateContentSize() return row end
        function nestedGroup:slider(subText, min, max, default, subCallback, step, subTooltip) local row = group:slider(subText, min, max, default, subCallback, step, subTooltip) row.Parent = contentFrame updateContentSize() return row end
        function nestedGroup:dropdown(subText, options, default, subCallback, subTooltip) local row = group:dropdown(subText, options, default, subCallback, subTooltip) row.Parent = contentFrame updateContentSize() return row end
        function nestedGroup:keybind(subText, current, subCallback, subTooltip) local row = group:keybind(subText, current, subCallback, subTooltip) row.Parent = contentFrame updateContentSize() return row end
        function nestedGroup:label(subText, color, subTooltip) local row = group:label(subText, color, subTooltip) row.Parent = contentFrame updateContentSize() return row end
        function nestedGroup:button(subText, subCallback, subTooltip) local row = group:button(subText, subCallback, subTooltip) row.Parent = contentFrame updateContentSize() return row end
        function nestedGroup:colorpicker(subText, subDefault, subCallback, subTooltip) local row = group:colorpicker(subText, subDefault, subCallback, subTooltip) row.Parent = contentFrame updateContentSize() return row end
        function nestedGroup:multidropdown(subText, options, default, subCallback, subTooltip) local row = group:multidropdown(subText, options, default, subCallback, subTooltip) row.Parent = contentFrame updateContentSize() return row end
        function nestedGroup:textbox(subText, default, subCallback, subTooltip) local row = group:textbox(subText, default, subCallback, subTooltip) row.Parent = contentFrame updateContentSize() return row end
        function nestedGroup:numberbox(subText, default, min, max, subCallback, subTooltip) local row = group:numberbox(subText, default, min, max, subCallback, subTooltip) row.Parent = contentFrame updateContentSize() return row end
        function nestedGroup:rangeslider(subText, min, max, defaultMin, defaultMax, subCallback, subTooltip) local row = group:rangeslider(subText, min, max, defaultMin, defaultMax, subCallback, subTooltip) row.Parent = contentFrame updateContentSize() return row end
        if contentFunc then contentFunc(nestedGroup) end
        local state = default
        toggleRow.MouseButton1Click:Connect(function() state = not state arrow.Text = state and "▼" or "▶" container.Size = UDim2.new(1, 0, 0, 30 + (state and contentLayout.AbsoluteContentSize.Y or 0)) updateSize() end)
        if tooltip then attachTooltip(toggleRow, tooltip) end
        updateContentSize()
        return container
    end

    function group:colorpicker(text, default, callback, tooltip)
        local row = createColorPicker(group, items, window, text, default, callback)
        if tooltip then attachTooltip(row, tooltip) end
        updateSize()
        return row
    end

    function group:multidropdown(text, options, default, callback, tooltip)
        local row = createMultiDropdown(group, items, window, text, options, default, callback)
        if tooltip then attachTooltip(row, tooltip) end
        updateSize()
        return row
    end

    function group:textbox(text, default, callback, tooltip)
        local id = generateID()
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 46)
        row.BackgroundTransparency = 1
        row.Parent = items
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -48, 0, 18)
        label.Position = UDim2.new(0, 4, 0, 3)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = window.theme.GrayLt
        label.Font = Enum.Font.Roboto
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 3
        label.Parent = row
        local box = Instance.new("TextBox")
        box.Size = UDim2.new(0, 150, 0, 22)
        box.Position = UDim2.new(1, -154, 0, 2)
        box.BackgroundColor3 = window.theme.Track
        box.BorderSizePixel = 0
        box.ZIndex = 3
        box.Parent = row
        box.Text = default or ""
        box.TextColor3 = window.theme.Accent
        box.Font = Enum.Font.RobotoMono
        box.TextSize = 13
        box.ClearTextOnFocus = false
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
        local current = default or ""
        box.FocusLost:Connect(function(enter) if enter then current = box.Text if callback then callback(current) end window.configs[id].Value = current end end)
        local elem = {ID = id, Value = current, SetValue = function(val) current = val box.Text = val if callback then callback(val) end end}
        window.configs[id] = elem
        if tooltip then attachTooltip(row, tooltip) end
        updateSize()
        return row
    end

    function group:numberbox(text, default, min, max, callback, tooltip)
        min = min or -math.huge
        max = max or math.huge
        local id = generateID()
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 46)
        row.BackgroundTransparency = 1
        row.Parent = items
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -48, 0, 18)
        label.Position = UDim2.new(0, 4, 0, 3)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = window.theme.GrayLt
        label.Font = Enum.Font.Roboto
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 3
        label.Parent = row
        local box = Instance.new("TextBox")
        box.Size = UDim2.new(0, 150, 0, 22)
        box.Position = UDim2.new(1, -154, 0, 2)
        box.BackgroundColor3 = window.theme.Track
        box.BorderSizePixel = 0
        box.ZIndex = 3
        box.Parent = row
        box.Text = tostring(default or 0)
        box.TextColor3 = window.theme.Accent
        box.Font = Enum.Font.RobotoMono
        box.TextSize = 13
        box.ClearTextOnFocus = false
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
        local current = default or 0
        local function validate()
            local num = tonumber(box.Text)
            if num then num = math.clamp(num, min, max) current = num box.Text = tostring(num) if callback then callback(num) end window.configs[id].Value = num else box.Text = tostring(current) end
        end
        box.FocusLost:Connect(function(enter) if enter then validate() end end)
        local elem = {ID = id, Value = current, SetValue = function(val) val = math.clamp(val, min, max) current = val box.Text = tostring(val) if callback then callback(val) end end}
        window.configs[id] = elem
        if tooltip then attachTooltip(row, tooltip) end
        updateSize()
        return row
    end

    function group:rangeslider(text, minVal, maxVal, defaultMin, defaultMax, callback, tooltip)
        local id = generateID()
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 46)
        row.BackgroundTransparency = 1
        row.Parent = items
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -48, 0, 18)
        label.Position = UDim2.new(0, 4, 0, 3)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = window.theme.GrayLt
        label.Font = Enum.Font.Roboto
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 3
        label.Parent = row
        local valueBox = Instance.new("Frame")
        valueBox.Size = UDim2.new(0, 80, 0, 20)
        valueBox.Position = UDim2.new(1, -84, 0, 2)
        valueBox.BackgroundColor3 = window.theme.Track
        valueBox.BorderSizePixel = 0
        valueBox.ZIndex = 3
        valueBox.Parent = row
        Instance.new("UICorner", valueBox).CornerRadius = UDim.new(0, 4)
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(1, 0, 1, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = tostring(defaultMin) .. " - " .. tostring(defaultMax)
        valueLabel.TextColor3 = window.theme.Accent
        valueLabel.Font = Enum.Font.RobotoMono
        valueLabel.TextSize = 11
        valueLabel.ZIndex = 4
        valueLabel.Parent = valueBox
        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, 0, 0, 6)
        track.Position = UDim2.new(0, 0, 0, 28)
        track.BackgroundColor3 = window.theme.Track
        track.BorderSizePixel = 0
        track.ZIndex = 3
        track.Parent = row
        Instance.new("UICorner", track).CornerRadius = UDim.new(0, 3)
        local pctMin = (defaultMin - minVal) / (maxVal - minVal)
        local pctMax = (defaultMax - minVal) / (maxVal - minVal)
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(pctMax - pctMin, 0, 1, 0)
        fill.Position = UDim2.new(pctMin, 0, 0, 0)
        fill.BackgroundColor3 = window.theme.Accent
        fill.BorderSizePixel = 0
        fill.ZIndex = 4
        fill.Parent = track
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 3)
        local knobLeft = Instance.new("Frame")
        knobLeft.Size = UDim2.new(0, 14, 0, 14)
        knobLeft.Position = UDim2.new(pctMin, -7, 0.5, -7)
        knobLeft.BackgroundColor3 = window.theme.White
        knobLeft.BorderSizePixel = 0
        knobLeft.ZIndex = 5
        knobLeft.Parent = track
        Instance.new("UICorner", knobLeft).CornerRadius = UDim.new(0, 7)
        local knobLeftStroke = Instance.new("UIStroke", knobLeft)
        knobLeftStroke.Color = window.theme.Accent
        local knobRight = Instance.new("Frame")
        knobRight.Size = UDim2.new(0, 14, 0, 14)
        knobRight.Position = UDim2.new(pctMax, -7, 0.5, -7)
        knobRight.BackgroundColor3 = window.theme.White
        knobRight.BorderSizePixel = 0
        knobRight.ZIndex = 5
        knobRight.Parent = track
        Instance.new("UICorner", knobRight).CornerRadius = UDim.new(0, 7)
        local knobRightStroke = Instance.new("UIStroke", knobRight)
        knobRightStroke.Color = window.theme.Accent
        local hitLeft = Instance.new("TextButton")
        hitLeft.Size = UDim2.new(0, 20, 0, 20)
        hitLeft.Position = UDim2.new(pctMin, -10, 0.5, -10)
        hitLeft.BackgroundTransparency = 1
        hitLeft.Text = ""
        hitLeft.ZIndex = 6
        hitLeft.Parent = track
        local hitRight = Instance.new("TextButton")
        hitRight.Size = UDim2.new(0, 20, 0, 20)
        hitRight.Position = UDim2.new(pctMax, -10, 0.5, -10)
        hitRight.BackgroundTransparency = 1
        hitRight.Text = ""
        hitRight.ZIndex = 6
        hitRight.Parent = track
        local dragging = false
        local dragType = nil
        local currentMin = defaultMin
        local currentMax = defaultMax
        local function updateDisplay()
            valueLabel.Text = tostring(currentMin) .. " - " .. tostring(currentMax)
            pctMin = (currentMin - minVal) / (maxVal - minVal)
            pctMax = (currentMax - minVal) / (maxVal - minVal)
            fill.Size = UDim2.new(pctMax - pctMin, 0, 1, 0)
            fill.Position = UDim2.new(pctMin, 0, 0, 0)
            knobLeft.Position = UDim2.new(pctMin, -7, 0.5, -7)
            knobRight.Position = UDim2.new(pctMax, -7, 0.5, -7)
            hitLeft.Position = UDim2.new(pctMin, -10, 0.5, -10)
            hitRight.Position = UDim2.new(pctMax, -10, 0.5, -10)
        end
        local function apply(pos, which)
            local rel = math.clamp((pos - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local val = minVal + (maxVal - minVal) * rel
            if which == "left" then val = math.min(val, currentMax) currentMin = math.floor(val + 0.5)
            else val = math.max(val, currentMin) currentMax = math.floor(val + 0.5) end
            updateDisplay()
            if callback then callback(currentMin, currentMax) end
            window.configs[id].Value = {currentMin, currentMax}
        end
        hitLeft.MouseButton1Down:Connect(function() dragging = true dragType = "left" end)
        hitRight.MouseButton1Down:Connect(function() dragging = true dragType = "right" end)
        UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then apply(i.Position.X, dragType) end end)
        UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
        local elem = {ID = id, Value = {currentMin, currentMax}, SetValue = function(t) currentMin, currentMax = t[1], t[2] updateDisplay() if callback then callback(currentMin, currentMax) end end}
        window.configs[id] = elem
        if tooltip then attachTooltip(row, tooltip) end
        updateSize()
        return row
    end

    return group
end

-- SubTab:addGroup (uses same element methods as columns)
function UILib.SubTab:addGroup(title)
    local window = self.window
    if not window then error("SubTab has no window reference") end
    local group = {}
    group.title = title
    group.window = window
    group.tab = self.tab
    group.subtab = self
    local grp = Instance.new("Frame")
    grp.Size = UDim2.new(1, 0, 0, 36)
    grp.BackgroundColor3 = window.theme.Item
    grp.BorderSizePixel = 0
    grp.Parent = self.page
    Instance.new("UICorner", grp).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke", grp)
    stroke.Color = window.theme.Border
    stroke.Thickness = 1
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundTransparency = 1
    row.Parent = grp
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -30, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = title:upper()
    label.TextColor3 = window.theme.GrayLt
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 2
    label.Parent = row
    local items = Instance.new("Frame")
    items.Position = UDim2.new(0, 0, 0, 30)
    items.Size = UDim2.new(1, 0, 0, 0)
    items.BackgroundTransparency = 1
    items.BorderSizePixel = 0
    items.Parent = grp
    local itemLayout = Instance.new("UIListLayout", items)
    itemLayout.Padding = UDim.new(0, 2)
    itemLayout.SortOrder = Enum.SortOrder.LayoutOrder
    local padding = Instance.new("UIPadding", items)
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 6)
    local function updateSize()
        local ih = itemLayout.AbsoluteContentSize.Y
        items.Size = UDim2.new(1, 0, 0, ih + 8)
        grp.Size = UDim2.new(1, 0, 0, ih + 46)
        self.layout:GetPropertyChangedSignal("AbsoluteContentSize"):Wait(0)
        self.page.CanvasSize = UDim2.new(0, 0, 0, self.layout.AbsoluteContentSize.Y + 20)
    end
    itemLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSize)
    group.frame = grp
    group.items = items
    group.itemLayout = itemLayout
    group.updateSize = updateSize

    -- Delegate to column's methods (no recursion)
    local colGroup = setmetatable({}, {__index = function(_, k) return function(_, ...) return group[k] and group[k](group, ...) end end})
    for name, _ in pairs({toggle=true,slider=true,dropdown=true,keybind=true,label=true,button=true,expandableToggle=true,collapsible=true,colorpicker=true,multidropdown=true,textbox=true,numberbox=true,rangeslider=true}) do
        group[name] = function(_, ...) return colGroup[name](colGroup, ...) end
    end
    return group
end

return UILib
