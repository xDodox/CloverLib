function UILib.SubTab:addGroup(title)
    local window = self.window
    if not window then error("SubTab has no window reference") end

    local group = {}
    group.title = title
    group.window = window
    group.tab = self.tab
    group.subtab = self

    -- Create group frame
    local grp = Instance.new("Frame")
    grp.Size = UDim2.new(1, 0, 0, 36)
    grp.BackgroundColor3 = window.theme.Item
    grp.BorderSizePixel = 0
    grp.Parent = self.page
    Instance.new("UICorner", grp).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke", grp)
    stroke.Color = window.theme.Border
    stroke.Thickness = 1

    -- Header row
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

    -- Items container
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

    -- === Element methods (identical to Column:addGroup) ===
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
        local elem = {ID = id, Value = state, SetValue = function(val)
            state = val
            cbOuter.BackgroundColor3 = state and window.theme.Accent or window.theme.Track
            cbStroke.Color = state and window.theme.AccentD or window.theme.Border
            cbMark.Text = state and "×" or ""
            if callback then callback(state) end
        end}
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

        local elem = {ID = id, Value = default, SetValue = function(val)
            selLbl.Text = val
            for opt, ck in pairs(checks) do ck.Text = (opt == val) and "×" or "" end
            if callback then callback(val) end
        end}
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
        function nestedGroup:toggle(subText, subDefault, subCallback, subTooltip)
            local row = group:toggle(subText, subDefault, subCallback, subTooltip)
            row.Parent = contentFrame
            updateContentSize()
            return row
        end
        function nestedGroup:slider(subText, min, max, default, subCallback, step, subTooltip)
            local row = group:slider(subText, min, max, default, subCallback, step, subTooltip)
            row.Parent = contentFrame
            updateContentSize()
            return row
        end
        function nestedGroup:dropdown(subText, options, default, subCallback, subTooltip)
            local row = group:dropdown(subText, options, default, subCallback, subTooltip)
            row.Parent = contentFrame
            updateContentSize()
            return row
        end
        function nestedGroup:keybind(subText, current, subCallback, subTooltip)
            local row = group:keybind(subText, current, subCallback, subTooltip)
            row.Parent = contentFrame
            updateContentSize()
            return row
        end
        function nestedGroup:label(subText, color, subTooltip)
            local row = group:label(subText, color, subTooltip)
            row.Parent = contentFrame
            updateContentSize()
            return row
        end
        function nestedGroup:button(subText, subCallback, subTooltip)
            local row = group:button(subText, subCallback, subTooltip)
            row.Parent = contentFrame
            updateContentSize()
            return row
        end
        function nestedGroup:colorpicker(subText, subDefault, subCallback, subTooltip)
            local row = group:colorpicker(subText, subDefault, subCallback, subTooltip)
            row.Parent = contentFrame
            updateContentSize()
            return row
        end
        function nestedGroup:multidropdown(subText, options, default, subCallback, subTooltip)
            local row = group:multidropdown(subText, options, default, subCallback, subTooltip)
            row.Parent = contentFrame
            updateContentSize()
            return row
        end
        function nestedGroup:textbox(subText, default, subCallback, subTooltip)
            local row = group:textbox(subText, default, subCallback, subTooltip)
            row.Parent = contentFrame
            updateContentSize()
            return row
        end
        function nestedGroup:numberbox(subText, default, min, max, subCallback, subTooltip)
            local row = group:numberbox(subText, default, min, max, subCallback, subTooltip)
            row.Parent = contentFrame
            updateContentSize()
            return row
        end
        function nestedGroup:rangeslider(subText, min, max, defaultMin, defaultMax, subCallback, subTooltip)
            local row = group:rangeslider(subText, min, max, defaultMin, defaultMax, subCallback, subTooltip)
            row.Parent = contentFrame
            updateContentSize()
            return row
        end

        if contentFunc then contentFunc(nestedGroup) end

        local state = default
        toggleRow.MouseButton1Click:Connect(function()
            state = not state
            cbOuter.BackgroundColor3 = state and window.theme.Accent or window.theme.Track
            cbStroke.Color = state and window.theme.AccentD or window.theme.Border
            cbMark.Text = state and "×" or ""
            container.Size = UDim2.new(1, 0, 0, 30 + (state and contentLayout.AbsoluteContentSize.Y or 0))
            updateSize()
        end)

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
        function nestedGroup:toggle(subText, subDefault, subCallback, subTooltip)
            local row = group:toggle(subText, subDefault, subCallback, subTooltip)
            row.Parent = contentFrame
            updateContentSize()
            return row
        end
        function nestedGroup:slider(subText, min, max, default, subCallback, step, subTooltip)
            local row = group:slider(subText, min, max, default, subCallback, step, subTooltip)
            row.Parent = contentFrame
            updateContentSize()
            return row
        end
        function nestedGroup:dropdown(subText, options, default, subCallback, subTooltip)
            local row = group:dropdown(subText, options, default, subCallback, subTooltip)
            row.Parent = contentFrame
            updateContentSize()
            return row
        end
        function nestedGroup:keybind(subText, current, subCallback, subTooltip)
            local row = group:keybind(subText, current, subCallback, subTooltip)
            row.Parent = contentFrame
            updateContentSize()
            return row
        end
        function nestedGroup:label(subText, color, subTooltip)
            local row = group:label(subText, color, subTooltip)
            row.Parent = contentFrame
            updateContentSize()
            return row
        end
        function nestedGroup:button(subText, subCallback, subTooltip)
            local row = group:button(subText, subCallback, subTooltip)
            row.Parent = contentFrame
            updateContentSize()
            return row
        end
        function nestedGroup:colorpicker(subText, subDefault, subCallback, subTooltip)
            local row = group:colorpicker(subText, subDefault, subCallback, subTooltip)
            row.Parent = contentFrame
            updateContentSize()
            return row
        end
        function nestedGroup:multidropdown(subText, options, default, subCallback, subTooltip)
            local row = group:multidropdown(subText, options, default, subCallback, subTooltip)
            row.Parent = contentFrame
            updateContentSize()
            return row
        end
        function nestedGroup:textbox(subText, default, subCallback, subTooltip)
            local row = group:textbox(subText, default, subCallback, subTooltip)
            row.Parent = contentFrame
            updateContentSize()
            return row
        end
        function nestedGroup:numberbox(subText, default, min, max, subCallback, subTooltip)
            local row = group:numberbox(subText, default, min, max, subCallback, subTooltip)
            row.Parent = contentFrame
            updateContentSize()
            return row
        end
        function nestedGroup:rangeslider(subText, min, max, defaultMin, defaultMax, subCallback, subTooltip)
            local row = group:rangeslider(subText, min, max, defaultMin, defaultMax, subCallback, subTooltip)
            row.Parent = contentFrame
            updateContentSize()
            return row
        end

        if contentFunc then contentFunc(nestedGroup) end

        local state = default
        toggleRow.MouseButton1Click:Connect(function()
            state = not state
            arrow.Text = state and "▼" or "▶"
            container.Size = UDim2.new(1, 0, 0, 30 + (state and contentLayout.AbsoluteContentSize.Y or 0))
            updateSize()
        end)

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
        box.FocusLost:Connect(function(enter)
            if enter then
                current = box.Text
                if callback then callback(current) end
                window.configs[id].Value = current
            end
        end)

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
            if num then
                num = math.clamp(num, min, max)
                current = num
                box.Text = tostring(num)
                if callback then callback(num) end
                window.configs[id].Value = num
            else
                box.Text = tostring(current)
            end
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
            if which == "left" then
                val = math.min(val, currentMax)
                currentMin = math.floor(val + 0.5)
            else
                val = math.max(val, currentMin)
                currentMax = math.floor(val + 0.5)
            end
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
