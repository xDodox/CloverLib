local UILib = {}
UILib.__index = UILib

local UIS = game:GetService("UserInputService")
local HS = game:GetService("HttpService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local activeWindow = nil

function UILib.newWindow(title, size, theme, parent)
    if activeWindow then
        activeWindow:Destroy()
    end

    local self = setmetatable({}, UILib)
    self.theme = theme
    self.size = size
    self.title = title
    self.parent = parent or (gethui and gethui()) or LP:WaitForChild("PlayerGui")
    self.connections = {}

    self.sg = Instance.new("ScreenGui")
    self.sg.Name = "Clover_" .. HS:GenerateGUID(false)
    self.sg.ResetOnSpawn = false
    self.sg.IgnoreGuiInset = false
    self.sg.Parent = self.parent

    local win = Instance.new("Frame")
    win.Size = UDim2.new(0, size.X, 0, size.Y)
    win.Position = UDim2.new(0, 80, 0, 60)
    win.BackgroundColor3 = theme.BG
    win.BorderSizePixel = 0
    win.ClipsDescendants = true
    win.Parent = self.sg
    Instance.new("UICorner", win).CornerRadius = UDim.new(0, 5)
    local winStroke = Instance.new("UIStroke", win)
    winStroke.Color = theme.Border
    winStroke.Thickness = 1
    self.window = win

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 46)
    header.BackgroundColor3 = theme.BG
    header.BorderSizePixel = 0
    header.ZIndex = 5
    header.Parent = win
    self.header = header

    local headerLine = Instance.new("Frame")
    headerLine.Size = UDim2.new(1, 0, 0, 2)
    headerLine.Position = UDim2.new(0, 0, 1, -2)
    headerLine.BackgroundColor3 = theme.Accent
    headerLine.BorderSizePixel = 0
    headerLine.ZIndex = 6
    headerLine.Parent = header

    local logoBar = Instance.new("Frame")
    logoBar.Size = UDim2.new(0, 3, 0, 18)
    logoBar.Position = UDim2.new(0, 14, 0.5, -9)
    logoBar.BackgroundColor3 = theme.Accent
    logoBar.BorderSizePixel = 0
    logoBar.ZIndex = 6
    logoBar.Parent = header
    Instance.new("UICorner", logoBar).CornerRadius = UDim.new(0, 2)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0, 240, 1, 0)
    titleLabel.Position = UDim2.new(0, 23, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = theme.White
    titleLabel.Font = Enum.Font.RobotoMono
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 6
    titleLabel.Parent = header

    local versionPill = Instance.new("Frame")
    versionPill.Size = UDim2.new(0, 52, 0, 18)
    versionPill.Position = UDim2.new(0, 222, 0.5, -9)
    versionPill.BackgroundColor3 = theme.AccentD
    versionPill.BorderSizePixel = 0
    versionPill.ZIndex = 6
    versionPill.Parent = header
    Instance.new("UICorner", versionPill).CornerRadius = UDim.new(0, 4)
    local versionLabel = Instance.new("TextLabel")
    versionLabel.Size = UDim2.new(1, 0, 1, 0)
    versionLabel.BackgroundTransparency = 1
    versionLabel.Text = "v1.0"
    versionLabel.TextColor3 = theme.White
    versionLabel.Font = Enum.Font.GothamBold
    versionLabel.TextSize = 10
    versionLabel.ZIndex = 7
    versionLabel.Parent = versionPill

    local hintLabel = Instance.new("TextLabel")
    hintLabel.Size = UDim2.new(0, 180, 1, 0)
    hintLabel.Position = UDim2.new(1, -188, 0, 0)
    hintLabel.BackgroundTransparency = 1
    hintLabel.Text = "[RSHIFT]  TOGGLE"
    hintLabel.TextColor3 = theme.Gray
    hintLabel.Font = Enum.Font.RobotoMono
    hintLabel.TextSize = 9
    hintLabel.TextXAlignment = Enum.TextXAlignment.Right
    hintLabel.ZIndex = 6
    hintLabel.Parent = header

    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 152, 1, -92)
    sidebar.Position = UDim2.new(0, 0, 0, 46)
    sidebar.BackgroundColor3 = theme.Panel
    sidebar.BorderSizePixel = 0
    sidebar.ClipsDescendants = true
    sidebar.Parent = win
    self.sidebar = sidebar

    local sidebarEdge = Instance.new("Frame")
    sidebarEdge.Size = UDim2.new(0, 1, 1, 0)
    sidebarEdge.Position = UDim2.new(1, -1, 0, 0)
    sidebarEdge.BackgroundColor3 = theme.Border
    sidebarEdge.BorderSizePixel = 0
    sidebarEdge.Parent = sidebar

    local content = Instance.new("Frame")
    content.Size = UDim2.new(0, size.X - 152, 1, -92)
    content.Position = UDim2.new(0, 152, 0, 46)
    content.BackgroundColor3 = theme.BG
    content.BorderSizePixel = 0
    content.Parent = win
    self.content = content

    local navbar = Instance.new("Frame")
    navbar.Size = UDim2.new(1, 0, 0, 46)
    navbar.Position = UDim2.new(0, 0, 1, -46)
    navbar.BackgroundColor3 = theme.Panel
    navbar.BorderSizePixel = 0
    navbar.Parent = win
    self.navbar = navbar

    local navLine = Instance.new("Frame")
    navLine.Size = UDim2.new(1, 0, 0, 1)
    navLine.Position = UDim2.new(0, 0, 0, 0)
    navLine.BackgroundColor3 = theme.Border
    navLine.BorderSizePixel = 0
    navLine.ZIndex = 4
    navLine.Parent = navbar

    local navList = Instance.new("UIListLayout", navbar)
    navList.FillDirection = Enum.FillDirection.Horizontal
    navList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    navList.VerticalAlignment = Enum.VerticalAlignment.Center
    navList.Padding = UDim.new(0, 0)

    do
        local drag, dragStart, dragPos = false, nil, nil
        header.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                drag = true
                dragStart = i.Position
                dragPos = win.Position
            end
        end)
        table.insert(self.connections, UIS.InputChanged:Connect(function(i)
            if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = i.Position - dragStart
                win.Position = UDim2.new(
                    dragPos.X.Scale, dragPos.X.Offset + delta.X,
                    dragPos.Y.Scale, dragPos.Y.Offset + delta.Y
                )
            end
        end))
        table.insert(self.connections, UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                drag = false
            end
        end))
    end

    self.tabs = {}
    self.activeTab = nil
    self.navList = navList

    activeWindow = self
    return self
end

function UILib:Destroy()
    for _, conn in ipairs(self.connections) do
        conn:Disconnect()
    end
    if self.sg then
        self.sg:Destroy()
    end
    if activeWindow == self then
        activeWindow = nil
    end
end

function UILib:setVisible(visible)
    if self.window then
        self.window.Visible = visible
    end
end

function UILib:addTab(name)
    local tab = {}
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

    btn.MouseEnter:Connect(function()
        if btn.TextColor3 ~= self.theme.White then
            btn.TextColor3 = self.theme.GrayLt
        end
    end)
    btn.MouseLeave:Connect(function()
        if btn.TextColor3 ~= self.theme.White then
            btn.TextColor3 = self.theme.Gray
        end
    end)

    tab.btn = btn
    tab.underline = underline

    local function activate()
        if self.activeTab then
            self.activeTab.btn.TextColor3 = self.theme.Gray
            if self.activeTab.underline then
                self.activeTab.underline.Visible = false
            end
            for _, sub in pairs(self.activeTab.subtabs) do
                sub.btn.Visible = false
                sub.page.Visible = false
                sub.ind.Visible = false
                sub.lbl.TextColor3 = self.theme.Gray
            end
        end
        btn.TextColor3 = self.theme.White
        underline.Visible = true
        for _, sub in pairs(tab.subtabs) do
            sub.btn.Visible = true
        end
        if tab.firstSub then
            local first = tab.subtabs[tab.firstSub]
            if first then
                first.page.Visible = true
                first.ind.Visible = true
                first.lbl.TextColor3 = self.theme.White
            end
        end
        self.activeTab = tab
    end

    btn.MouseButton1Click:Connect(activate)
    tab.activate = activate

    self.tabs[name] = tab
    return tab
end

function UILib.Tab:addSubTab(subName)
    local sub = {}
    sub.name = subName
    sub.tab = self

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
    Instance.new("UICorner", hover).CornerRadius = UDim.new(0, 3)

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
        if self.window.activeTab ~= self then
            self:activate()
        end
        for _, s in pairs(self.subtabs) do
            s.page.Visible = false
            s.ind.Visible = false
            s.lbl.TextColor3 = self.window.theme.Gray
        end
        page.Visible = true
        indicator.Visible = true
        lbl.TextColor3 = self.window.theme.White
    end

    btn.MouseButton1Click:Connect(activateSub)

    if not self.firstSub then
        self.firstSub = subName
    end
    self.subtabs[subName] = sub
    return sub
end

-- ============= ADDED SECTION START =============
function UILib.SubTab:addGroup(title)
    local group = {}
    group.title = title
    group.subtab = self
    group.elements = {}

    local grp = Instance.new("Frame")
    grp.Size = UDim2.new(1, 0, 0, 36)
    grp.BackgroundColor3 = self.tab.window.theme.Item
    grp.BorderSizePixel = 0
    grp.Parent = self.page
    Instance.new("UICorner", grp).CornerRadius = UDim.new(0, 4)
    local stroke = Instance.new("UIStroke", grp)
    stroke.Color = self.tab.window.theme.Border
    stroke.Thickness = 1

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundTransparency = 1
    row.Parent = grp

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 2, 0, 14)
    bar.Position = UDim2.new(0, 10, 0.5, -7)
    bar.BackgroundColor3 = self.tab.window.theme.Accent
    bar.BorderSizePixel = 0
    bar.Parent = row
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 1)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -30, 1, 0)
    label.Position = UDim2.new(0, 18, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = title:upper()
    label.TextColor3 = self.tab.window.theme.GrayLt
    label.Font = Enum.Font.GothamBold
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 2
    label.Parent = row

    local separator = Instance.new("Frame")
    separator.Size = UDim2.new(1, -16, 0, 1)
    separator.Position = UDim2.new(0, 8, 0, 30)
    separator.BackgroundColor3 = self.tab.window.theme.Border
    separator.BorderSizePixel = 0
    separator.Parent = grp

    local items = Instance.new("Frame")
    items.Position = UDim2.new(0, 0, 0, 33)
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

    function group:toggle(text, default, callback)
        local row = Instance.new("TextButton")
        row.Size = UDim2.new(1, 0, 0, 28)
        row.BackgroundTransparency = 1
        row.Text = ""
        row.ZIndex = 3
        row.Parent = items

        local rh = Instance.new("Frame")
        rh.Size = UDim2.new(1, 0, 1, 0)
        rh.BackgroundColor3 = self.tab.window.theme.ItemHov
        rh.BorderSizePixel = 0
        rh.Visible = false
        rh.ZIndex = 2
        rh.Parent = row
        Instance.new("UICorner", rh).CornerRadius = UDim.new(0, 3)

        row.MouseEnter:Connect(function() rh.Visible = true end)
        row.MouseLeave:Connect(function() rh.Visible = false end)

        local cbOuter = Instance.new("Frame")
        cbOuter.Size = UDim2.new(0, 16, 0, 16)
        cbOuter.Position = UDim2.new(1, -20, 0.5, -8)
        cbOuter.BackgroundColor3 = default and self.tab.window.theme.Accent or self.tab.window.theme.Track
        cbOuter.BorderSizePixel = 0
        cbOuter.ZIndex = 4
        cbOuter.Parent = row
        Instance.new("UICorner", cbOuter).CornerRadius = UDim.new(0, 3)

        local cbStroke = Instance.new("UIStroke", cbOuter)
        cbStroke.Color = default and self.tab.window.theme.AccentD or self.tab.window.theme.Border
        cbStroke.Thickness = 1

        local cbMark = Instance.new("TextLabel")
        cbMark.Size = UDim2.new(1, 0, 1, 0)
        cbMark.BackgroundTransparency = 1
        cbMark.Text = default and "✓" or ""
        cbMark.TextColor3 = Color3.new(1,1,1)
        cbMark.Font = Enum.Font.GothamBold
        cbMark.TextSize = 11
        cbMark.ZIndex = 5
        cbMark.Parent = cbOuter

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -28, 1, 0)
        label.Position = UDim2.new(0, 4, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = self.tab.window.theme.White
        label.Font = Enum.Font.Roboto
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 4
        label.Parent = row

        local state = default
        row.MouseButton1Click:Connect(function()
            state = not state
            cbOuter.BackgroundColor3 = state and self.tab.window.theme.Accent or self.tab.window.theme.Track
            cbStroke.Color = state and self.tab.window.theme.AccentD or self.tab.window.theme.Border
            cbMark.Text = state and "✓" or ""
            callback(state)
        end)

        group.updateSize()
        return row
    end

    function group:slider(text, minVal, maxVal, defaultVal, callback)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 46)
        row.BackgroundTransparency = 1
        row.Parent = items

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -48, 0, 18)
        label.Position = UDim2.new(0, 4, 0, 3)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = self.tab.window.theme.GrayLt
        label.Font = Enum.Font.Roboto
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 3
        label.Parent = row

        local valueBox = Instance.new("Frame")
        valueBox.Size = UDim2.new(0, 40, 0, 18)
        valueBox.Position = UDim2.new(1, -42, 0, 3)
        valueBox.BackgroundColor3 = self.tab.window.theme.Track
        valueBox.BorderSizePixel = 0
        valueBox.ZIndex = 3
        valueBox.Parent = row
        Instance.new("UICorner", valueBox).CornerRadius = UDim.new(0, 3)

        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(1, 0, 1, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = tostring(defaultVal)
        valueLabel.TextColor3 = self.tab.window.theme.Accent
        valueLabel.Font = Enum.Font.RobotoMono
        valueLabel.TextSize = 11
        valueLabel.ZIndex = 4
        valueLabel.Parent = valueBox

        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, 0, 0, 6)
        track.Position = UDim2.new(0, 0, 0, 28)
        track.BackgroundColor3 = self.tab.window.theme.Track
        track.BorderSizePixel = 0
        track.ZIndex = 3
        track.Parent = row
        Instance.new("UICorner", track).CornerRadius = UDim.new(0, 3)

        local pct = (defaultVal - minVal) / (maxVal - minVal)
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(pct, 0, 1, 0)
        fill.BackgroundColor3 = self.tab.window.theme.Accent
        fill.BorderSizePixel = 0
        fill.ZIndex = 4
        fill.Parent = track
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 3)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 12, 0, 12)
        knob.Position = UDim2.new(pct, -6, 0.5, -6)
        knob.BackgroundColor3 = self.tab.window.theme.White
        knob.BorderSizePixel = 0
        knob.ZIndex = 5
        knob.Parent = track
        Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 6)
        local knobStroke = Instance.new("UIStroke", knob)
        knobStroke.Color = self.tab.window.theme.Accent
        knobStroke.Thickness = 1.5

        local hit = Instance.new("TextButton")
        hit.Size = UDim2.new(1, 0, 0, 22)
        hit.Position = UDim2.new(0, 0, 0.5, -11)
        hit.BackgroundTransparency = 1
        hit.Text = ""
        hit.ZIndex = 6
        hit.Parent = track

        local sliding = false
        local function apply(mx)
            local rel = math.clamp((mx - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local val = math.floor(minVal + (maxVal - minVal) * rel + 0.5)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            knob.Position = UDim2.new(rel, -6, 0.5, -6)
            valueLabel.Text = tostring(val)
            callback(val)
        end

        hit.MouseButton1Down:Connect(function()
            sliding = true
            apply(UIS:GetMouseLocation().X)
        end)

        UIS.InputChanged:Connect(function(i)
            if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then
                apply(i.Position.X)
            end
        end)

        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                sliding = false
            end
        end)

        group.updateSize()
        return row
    end

    function group:dropdown(text, options, default, callback)
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
        label.TextColor3 = self.tab.window.theme.GrayLt
        label.Font = Enum.Font.Roboto
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 11
        label.Parent = row

        local dbtn = Instance.new("TextButton")
        dbtn.Size = UDim2.new(1, 0, 0, 28)
        dbtn.Position = UDim2.new(0, 0, 0, 22)
        dbtn.BackgroundColor3 = self.tab.window.theme.Track
        dbtn.BorderSizePixel = 0
        dbtn.Text = ""
        dbtn.ZIndex = 11
        dbtn.Parent = row
        Instance.new("UICorner", dbtn).CornerRadius = UDim.new(0, 4)
        local dstroke = Instance.new("UIStroke", dbtn)
        dstroke.Color = self.tab.window.theme.Border
        dstroke.Thickness = 1

        local selLbl = Instance.new("TextLabel")
        selLbl.Size = UDim2.new(1, -34, 1, 0)
        selLbl.Position = UDim2.new(0, 10, 0, 0)
        selLbl.BackgroundTransparency = 1
        selLbl.Text = default
        selLbl.TextColor3 = self.tab.window.theme.White
        selLbl.Font = Enum.Font.GothamBold
        selLbl.TextSize = 12
        selLbl.TextXAlignment = Enum.TextXAlignment.Left
        selLbl.ZIndex = 12
        selLbl.Parent = dbtn

        local arrow = Instance.new("TextLabel")
        arrow.Size = UDim2.new(0, 24, 1, 0)
        arrow.Position = UDim2.new(1, -26, 0, 0)
        arrow.BackgroundTransparency = 1
        arrow.Text = "▾"
        arrow.TextColor3 = self.tab.window.theme.Accent
        arrow.Font = Enum.Font.GothamBold
        arrow.TextSize = 14
        arrow.ZIndex = 12
        arrow.Parent = dbtn

        local listH = #options * 26
        local dlist = Instance.new("ScrollingFrame")
        dlist.Size = UDim2.new(1, 0, 0, math.min(listH, 104))
        dlist.Position = UDim2.new(0, 0, 0, 52)
        dlist.BackgroundColor3 = self.tab.window.theme.Item
        dlist.BorderSizePixel = 0
        dlist.ScrollBarThickness = 2
        dlist.ScrollBarImageColor3 = self.tab.window.theme.Accent
        dlist.CanvasSize = UDim2.new(0, 0, 0, listH)
        dlist.Visible = false
        dlist.ZIndex = 50
        dlist.Parent = row
        Instance.new("UICorner", dlist).CornerRadius = UDim.new(0, 4)
        Instance.new("UIStroke", dlist).Color = self.tab.window.theme.Accent

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
            oh.BackgroundColor3 = self.tab.window.theme.ItemHov
            oh.BorderSizePixel = 0
            oh.Visible = false
            oh.ZIndex = 51
            oh.Parent = ob
            Instance.new("UICorner", oh).CornerRadius = UDim.new(0, 3)

            local ol = Instance.new("TextLabel")
            ol.Size = UDim2.new(1, -22, 1, 0)
            ol.Position = UDim2.new(0, 10, 0, 0)
            ol.BackgroundTransparency = 1
            ol.Text = opt
            ol.TextColor3 = self.tab.window.theme.GrayLt
            ol.Font = Enum.Font.Roboto
            ol.TextSize = 12
            ol.TextXAlignment = Enum.TextXAlignment.Left
            ol.ZIndex = 52
            ol.Parent = ob

            local ck = Instance.new("TextLabel")
            ck.Size = UDim2.new(0, 18, 1, 0)
            ck.Position = UDim2.new(1, -20, 0, 0)
            ck.BackgroundTransparency = 1
            ck.Text = (opt == default) and "✓" or ""
            ck.TextColor3 = self.tab.window.theme.Accent
            ck.Font = Enum.Font.GothamBold
            ck.TextSize = 12
            ck.ZIndex = 52
            ck.Parent = ob
            checks[opt] = ck

            ob.MouseEnter:Connect(function()
                oh.Visible = true
                ol.TextColor3 = self.tab.window.theme.White
            end)
            ob.MouseLeave:Connect(function()
                oh.Visible = false
                ol.TextColor3 = self.tab.window.theme.GrayLt
            end)
            ob.MouseButton1Click:Connect(function()
                selLbl.Text = opt
                for _, c in pairs(checks) do c.Text = "" end
                ck.Text = "✓"
                dlist.Visible = false
                arrow.Text = "▾"
                row.Size = UDim2.new(1, 0, 0, 52)
                callback(opt)
            end)
        end

        local open = false
        dbtn.MouseButton1Click:Connect(function()
            open = not open
            dlist.Visible = open
            arrow.Text = open and "▴" or "▾"
            row.Size = UDim2.new(1, 0, 0, 52 + (open and math.min(listH, 104) or 0))
        end)

        group.updateSize()
        return row
    end

    function group:keybind(text, currentName, onChange)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 30)
        row.BackgroundTransparency = 1
        row.Parent = items

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -82, 1, 0)
        label.Position = UDim2.new(0, 4, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = self.tab.window.theme.White
        label.Font = Enum.Font.Roboto
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 3
        label.Parent = row

        local kbtn = Instance.new("TextButton")
        kbtn.Size = UDim2.new(0, 76, 0, 22)
        kbtn.Position = UDim2.new(1, -78, 0.5, -11)
        kbtn.BackgroundColor3 = self.tab.window.theme.Track
        kbtn.BorderSizePixel = 0
        kbtn.Text = currentName
        kbtn.TextColor3 = self.tab.window.theme.Accent
        kbtn.Font = Enum.Font.RobotoMono
        kbtn.TextSize = 11
        kbtn.ZIndex = 4
        kbtn.Parent = row
        Instance.new("UICorner", kbtn).CornerRadius = UDim.new(0, 3)
        local kstroke = Instance.new("UIStroke", kbtn)
        kstroke.Color = self.tab.window.theme.Border
        kstroke.Thickness = 1

        local listening = false
        local skipNext = false
        kbtn.MouseButton1Click:Connect(function()
            if listening then return end
            listening = true
            skipNext = true
            kbtn.Text = "[press key]"
            kbtn.TextColor3 = self.tab.window.theme.GrayLt
            kstroke.Color = self.tab.window.theme.Accent
            local con
            con = UIS.InputBegan:Connect(function(i)
                if skipNext and i.UserInputType == Enum.UserInputType.MouseButton1 then
                    skipNext = false
                    return
                end
                listening = false
                con:Disconnect()
                kstroke.Color = self.tab.window.theme.Border
                if i.KeyCode == Enum.KeyCode.Escape then
                    kbtn.Text = currentName
                    kbtn.TextColor3 = self.tab.window.theme.Accent
                    return
                end
                local u = i.UserInputType
                if u == Enum.UserInputType.Keyboard then
                    kbtn.Text = i.KeyCode.Name
                    kbtn.TextColor3 = self.tab.window.theme.Accent
                    onChange(i.KeyCode, i.KeyCode.Name)
                elseif u == Enum.UserInputType.MouseButton2 then
                    kbtn.Text = "RMB"
                    kbtn.TextColor3 = self.tab.window.theme.Accent
                    onChange(Enum.UserInputType.MouseButton2, "RMB")
                elseif u == Enum.UserInputType.MouseButton1 then
                    kbtn.Text = "LMB"
                    kbtn.TextColor3 = self.tab.window.theme.Accent
                    onChange(Enum.UserInputType.MouseButton1, "LMB")
                elseif u == Enum.UserInputType.MouseButton3 then
                    kbtn.Text = "MMB"
                    kbtn.TextColor3 = self.tab.window.theme.Accent
                    onChange(Enum.UserInputType.MouseButton3, "MMB")
                else
                    kbtn.Text = currentName
                    kbtn.TextColor3 = self.tab.window.theme.Accent
                end
            end)
        end)

        group.updateSize()
        return row
    end

    function group:label(text, color)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, 20)
        f.BackgroundTransparency = 1
        f.Parent = items

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.Position = UDim2.new(0, 4, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = color or self.tab.window.theme.Gray
        lbl.Font = Enum.Font.Roboto
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 3
        lbl.Parent = f

        group.updateSize()
        return f
    end

    table.insert(self.groups, group)
    group.updateSize()
    return group
end
-- ============= ADDED SECTION END =============

return UILib
