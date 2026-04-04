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

local allWindows = {}

local DEFAULT_THEME = {

	Accent  = Color3.fromRGB(0, 210, 135),
	AccentD = Color3.fromRGB(0, 150, 95),
	Surface = Color3.fromRGB(24, 24, 24),
	Base    = Color3.fromRGB(10, 10, 10),

	BG      = Color3.fromRGB(10, 10, 10),
	Panel   = Color3.fromRGB(24, 24, 24),
	Item    = Color3.fromRGB(24, 24, 24),
	ItemHov = Color3.fromRGB(32, 32, 32),
	Track   = Color3.fromRGB(10, 10, 10),
	Border  = Color3.fromRGB(42, 42, 42),

	White   = Color3.new(1, 1, 1),
	Gray    = Color3.fromRGB(110, 110, 110),
	GrayLt  = Color3.fromRGB(165, 165, 165),
}

local NOTIF_COLORS = {
	info = Color3.fromRGB(50, 150, 255),
	success = Color3.fromRGB(0, 255, 163),
	error = Color3.fromRGB(255, 70, 70),
	warning = Color3.fromRGB(255, 180, 50),
}

local contextMenuConnections = {}

local function makeTooltipSystem(sg, theme, connections)
	local tooltipFrame = Instance.new("Frame")
	tooltipFrame.BackgroundColor3 = theme.Panel
	tooltipFrame.BorderSizePixel = 0
	tooltipFrame.Visible = false
	tooltipFrame.ZIndex = 1000
	tooltipFrame.Parent = sg
	Instance.new("UICorner", tooltipFrame).CornerRadius = UDim.new(0, 4)
	local tipPadding = Instance.new("UIPadding", tooltipFrame)
	tipPadding.PaddingLeft  = UDim.new(0, 6)
	tipPadding.PaddingRight = UDim.new(0, 6)
	tipPadding.PaddingTop    = UDim.new(0, 4)
	tipPadding.PaddingBottom = UDim.new(0, 4)
	local tooltipText = Instance.new("TextLabel")
	tooltipText.Size = UDim2.new(1, 0, 1, 0)
	tooltipText.BackgroundTransparency = 1
	tooltipText.TextColor3 = theme.White
	tooltipText.Font = Enum.Font.GothamSemibold
	tooltipText.TextSize = 12
	tooltipText.TextWrapped = true
	tooltipText.ZIndex = 1001
	tooltipText.Parent = tooltipFrame

	local tooltipTimer = nil
	local tooltipActiveElement = nil

	local function showTooltip(text, element)
		if not element then return end
		local mp = UIS:GetMouseLocation()
		if element.AbsolutePosition and element.AbsoluteSize then
			local ap, as = element.AbsolutePosition, element.AbsoluteSize
			if mp.X < ap.X or mp.X > ap.X + as.X or mp.Y < ap.Y or mp.Y > ap.Y + as.Y then return end
		end
		tooltipText.Text = text
		tooltipActiveElement = element
		local screenWidth  = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 1920
		local screenHeight = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 1080
		local textWidth = 160
		local textSize  = game:GetService("TextService"):GetTextSize(text, 12, Enum.Font.GothamSemibold, Vector2.new(textWidth, 500))
		local tipW = textWidth + 24
		local tipH = textSize.Y + 16
		tooltipFrame.Size = UDim2.new(0, tipW, 0, tipH)
		local mousePos = UIS:GetMouseLocation()
		local targetX  = mousePos.X - tipW / 2
		local targetY  = mousePos.Y - tipH - 10
		if targetY < 8 then targetY = mousePos.Y + 18 end
		targetX = math.clamp(targetX, 8, screenWidth  - tipW - 8)
		targetY = math.clamp(targetY, 8, screenHeight - tipH - 8)
		tooltipFrame.Position = UDim2.new(0, targetX, 0, targetY)
		tooltipFrame.Visible = true
	end

	local function hideTooltip()
		if tooltipTimer then task.cancel(tooltipTimer); tooltipTimer = nil end
		tooltipFrame.Visible = false
		tooltipActiveElement = nil
	end

	local function startTooltipDelay(text, element)
		hideTooltip()
		tooltipTimer = task.delay(0.5, function() showTooltip(text, element) end)
	end

	table.insert(connections, UIS.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		if not tooltipActiveElement or not tooltipFrame.Visible then return end
		local ok, ap  = pcall(function() return tooltipActiveElement.AbsolutePosition end)
		local ok2, as = pcall(function() return tooltipActiveElement.AbsoluteSize end)
		if not ok or not ok2 then hideTooltip(); return end
		local mp = UIS:GetMouseLocation()
		if mp.X < ap.X or mp.X > ap.X + as.X or mp.Y < ap.Y or mp.Y > ap.Y + as.Y then
			hideTooltip()
		end
	end))

	return { show = showTooltip, hide = hideTooltip, start = startTooltipDelay }
end

function UILib:notify(message, notifType, duration)
	notifType = notifType or "info"
	duration = duration or 3
	if not self.notifications then self.notifications = {} end
	for i = #self.notifications, 1, -1 do
		if not self.notifications[i] or not self.notifications[i].Parent then
			table.remove(self.notifications, i)
		end
	end
	local accentColor = NOTIF_COLORS[notifType] or NOTIF_COLORS.info
	local index = #self.notifications + 1
	local yPos = 10 + (index - 1) * 50
	local notif = Instance.new("Frame")
	notif.Size = UDim2.new(0, 240, 0, 42)
	notif.Position = UDim2.new(1, 0, 0, yPos)
	notif.BackgroundColor3 = self.theme.Panel
	notif.BorderSizePixel = 0
	notif.ZIndex = 500
	notif.Parent = self.sg
	Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 6)
	local stroke = Instance.new("UIStroke", notif)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = self.theme.Border
	stroke.Thickness = 1
	local progressOuter = Instance.new("Frame")
	progressOuter.Size = UDim2.new(1, 0, 0, 2)
	progressOuter.Position = UDim2.new(0, 0, 1, -2)
	progressOuter.BackgroundTransparency = 1
	progressOuter.BorderSizePixel = 0
	progressOuter.ZIndex = 502
	progressOuter.Parent = notif
	Instance.new("UICorner", progressOuter).CornerRadius = UDim.new(0, 2)
	local progressBar = Instance.new("Frame")
	progressBar.Name = "indicator"
	progressBar.Size = UDim2.new(1, 0, 1, 0)
	progressBar.BackgroundColor3 = accentColor
	progressBar.BorderSizePixel = 0
	progressBar.ZIndex = 503
	progressBar.Parent = progressOuter
	Instance.new("UICorner", progressBar).CornerRadius = UDim.new(0, 2)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -16, 1, -4)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = message
	label.TextColor3 = self.theme.White
	label.Font = Enum.Font.GothamSemibold
	label.TextSize = 13
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 501
	label.Parent = notif
	table.insert(self.notifications, notif)
	local targetX = UDim2.new(1, -250, 0, yPos)
	notif.Position = UDim2.new(1, 0, 0, yPos)
	local tweenIn = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = targetX})
	tweenIn:Play()
	TweenService:Create(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 1, 0)}):Play()
	task.delay(duration, function()
		if not notif or not notif.Parent then return end
		local out = TweenService:Create(notif, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(1, 0, 0, yPos)})
		out:Play()
		out.Completed:Connect(function()
			if notif and notif.Parent then notif:Destroy() end
			if self.notifications then
				for i = #self.notifications, 1, -1 do
					if self.notifications[i] == notif or not self.notifications[i] or not self.notifications[i].Parent then
						table.remove(self.notifications, i)
					end
				end
				for i, n in ipairs(self.notifications) do
					if n and n.Parent then
						local newY = 10 + (i-1) * 50
						TweenService:Create(n, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							Position = UDim2.new(1, -250, 0, newY)
						}):Play()
					end
				end
			end
		end)
	end)
end

function UILib:getConfigDir()
	local gameName = (game and game.Name and game.Name ~= "" and game.Name) or "Unknown"
	gameName = gameName:gsub("[^%w%s%-_]", ""):gsub("%s+", "_"):sub(1, 40)
	local dir = "Clover/" .. gameName .. "/"
	pcall(makefolder, "Clover")
	pcall(makefolder, "Clover/" .. gameName)
	return dir
end

function UILib:saveConfig(name)
	local data = {}
	if not self.configs then return end
	for id, elem in pairs(self.configs) do
		if elem.Value ~= nil then data[id] = elem.Value end
	end
	local json = HS:JSONEncode(data)
	local path = self:getConfigDir() .. name .. ".json"
	local success, err = pcall(writefile, path, json)
	if success then self:notify("Saved: " .. name, "success")
	else self:notify("Save failed: " .. tostring(err), "error") end
end

function UILib:loadConfig(name)
	local path = self:getConfigDir() .. name .. ".json"
	local success, content = pcall(readfile, path)
	if not success then self:notify("Not found: " .. name, "error") return end
	local ok, data = pcall(HS.JSONDecode, HS, content)
	if not ok or not data then self:notify("Invalid config", "error") return end
	for id, value in pairs(data) do
		if self.configs and self.configs[id] then
			pcall(self.configs[id].SetValue, value)
		end
	end
	self:notify("Loaded: " .. name, "success")
end

function UILib:deleteConfig(name)
	local path = self:getConfigDir() .. name .. ".json"
	local success = pcall(delfile, path)
	if success then self:notify("Deleted: " .. name, "success")
	else self:notify("Delete failed", "error") end
end

function UILib:listConfigs()
	local dir = self:getConfigDir()
	local ok, files = pcall(listfiles, dir)
	if not ok or not files then return {} end
	local configs = {}
	for _, f in ipairs(files) do
		local name = f:match("([^/\\]+)$")
		if name and name:match("%.json$") then
			table.insert(configs, name:match("^(.+)%.json$"))
		end
	end
	return configs
end

local MIN_SIDEBAR_WIDTH = 100
local MAX_SIDEBAR_WIDTH = 152
local MIN_KEYBIND_WIDTH = 52
local MAX_KEYBIND_WIDTH = 76

function UILib.newWindow(title, size, theme, parent, showVersion, includeUITab)

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
	self.notifications = {}
	self.configPrefix = "clover_"
	self.accentObjects = {}
	self.rainbowElements = {}
	self.pulseElements = {}
	self.keybindButtons = {}

	local animConn = RunService.RenderStepped:Connect(function()
		if not self.sg or not self.sg.Parent then return end
		local h = (tick() * 0.2) % 1
		local p = (math.sin(tick() * 2) + 1) / 2
		for elem, data in pairs(self.rainbowElements) do
			local s = data.s or 1
			local v = data.v or 1
			local newCol = Color3.fromHSV(h, s, v)
			elem.Value = newCol
			if data.callback then data.callback(newCol) end
			if data.colorBox then data.colorBox.BackgroundColor3 = newCol end
		end
		for elem, data in pairs(self.pulseElements) do
			local h_, s, _ = Color3.toHSV(elem.Value)
			local targetS = data.s or s
			local newCol = Color3.fromHSV(h_, targetS, p)
			elem.Value = newCol
			if data.callback then data.callback(newCol) end
			if data.colorBox then data.colorBox.BackgroundColor3 = newCol end
		end
	end)
	table.insert(self.connections, animConn)
	self.allSubTabs = {}
	self.activePopups = {}

	function self:updateAccent(color)
		self.theme.Accent = color
		self.theme.AccentD = Color3.new(color.r*0.70, color.g*0.70, color.b*0.70)
		for _, obj in ipairs(self.accentObjects) do
			pcall(function()
				if obj:IsA("ScrollingFrame") then
					obj.ScrollBarImageColor3 = color
				elseif obj:IsA("Frame") then
					obj.BackgroundColor3 = color
				elseif obj:IsA("UIStroke") then
					obj.Color = color
				elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
					obj.TextColor3 = color
				elseif obj:IsA("TextBox") then
					obj.TextColor3 = color
				end
			end)
		end
		if self.configs then
			for _, elem in pairs(self.configs) do
				if elem.IsToggle and elem.Value == true then
					pcall(function() elem.SetValue(true) end)
				end
			end
		end
	end

	self.sg = Instance.new("ScreenGui")
	self.sg.Name = "Clover_" .. HS:GenerateGUID(false)
	self.sg.ResetOnSpawn = false
	self.sg.IgnoreGuiInset = true
	self.sg.Parent = self.parent
	self.sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	self.tooltip = makeTooltipSystem(self.sg, self.theme, self.connections)

	local win = Instance.new("CanvasGroup")
	win.Size = UDim2.new(0, size.X, 0, size.Y)
	win.Position = UDim2.new(0.5, 0, 0.5, 0)
	win.BackgroundColor3 = self.theme.BG
	win.BorderSizePixel = 0
	win.Parent = self.sg
	win.Active = true
	win.Selectable = false
	win.AnchorPoint = Vector2.new(0.5, 0.5)
	win.GroupTransparency = 1
	self.uiScale = Instance.new("UIScale", win)
	self.uiScale.Scale = 0.8
	Instance.new("UICorner", win).CornerRadius = UDim.new(0, 8)
	local winStroke = Instance.new("UIStroke", win)
	winStroke.Color = self.theme.Border
	winStroke.Thickness = 1
	self.window = win
	self.originalPosition = win.Position
	self.originalSize = win.Size
	self.visibleTarget = false

	local function getSidebarWidth()
		return math.max(MIN_SIDEBAR_WIDTH, math.min(MAX_SIDEBAR_WIDTH, math.floor(self.size.X * 0.22)))
	end

	local function getKeybindWidth()
		return math.max(MIN_KEYBIND_WIDTH, math.min(MAX_KEYBIND_WIDTH, math.floor(self.size.X * 0.13)))
	end

	local function updateLayout()
		local sw = getSidebarWidth()
		local showSidebar = not self.activeTab or self.activeTab.showSidebar ~= false
		if self.sidebar then
			self.sidebar.Size = UDim2.new(0, sw, 1, -92)
			self.sidebar.Visible = showSidebar
			for _, sub in ipairs(self.allSubTabs) do
				if sub.btn then
					sub.btn.Size = UDim2.new(1, 0, 0, 28)
					sub.btn.Position = UDim2.new(0, 0, 0, 0)
				end
			end
		end
		if self.sidebarEdge then
			self.sidebarEdge.Visible = showSidebar
			self.sidebarEdge.Position = UDim2.new(0, sw, 0, 46)
			self.sidebarEdge.Size = UDim2.new(0, 1, 1, -92)
		end
		if self.content then
			if showSidebar then
				self.content.Size = UDim2.new(0, self.size.X - sw - 1, 1, -92)
				self.content.Position = UDim2.new(0, sw + 1, 0, 46)
			else
				self.content.Size = UDim2.new(0, self.size.X, 1, -92)
				self.content.Position = UDim2.new(0, 0, 0, 46)
			end
		end
		if self.refreshTabWidths then self.refreshTabWidths() end
	end
	self.updateLayout = updateLayout

	local function createResizeHandle(pos, sz, cursor)
		local handle = Instance.new("Frame")
		handle.Size = sz
		handle.Position = pos
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
			updateLayout()
		end
	end))

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 46)
	header.BackgroundColor3 = self.theme.Panel
	header.BackgroundTransparency = 0
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
	table.insert(self.accentObjects, headerLine)
	
	local uiScale = self.uiScale
	
	local function updateScaling()
		local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
		local s = math.min(vp.X / size.X, (vp.Y-40) / size.Y, 1)
		uiScale.Scale = s
	end
	table.insert(self.connections, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScaling))
	updateScaling()

	local titleRow = Instance.new("Frame")
	titleRow.Size = UDim2.new(0, 0, 1, 0)
	titleRow.AutomaticSize = Enum.AutomaticSize.X
	titleRow.Position = UDim2.new(0, 10, 0, 0)
	titleRow.BackgroundTransparency = 1
	titleRow.ZIndex = 6
	titleRow.ClipsDescendants = false
	titleRow.Parent = header
	self.titleRow = titleRow
	local titleRowLayout = Instance.new("UIListLayout", titleRow)
	titleRowLayout.FillDirection = Enum.FillDirection.Horizontal
	titleRowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	titleRowLayout.Padding = UDim.new(0, 8)
	titleRowLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local logo = Instance.new("ImageLabel")
	logo.Size = UDim2.new(0, 22, 0, 22)
	logo.BackgroundTransparency = 1
	logo.Image = "rbxassetid://115924193030407"
	logo.ZIndex = 60
	logo.LayoutOrder = 0
	logo.Parent = titleRow
	logo.Visible = true

	local titleLabel = Instance.new("TextLabel")
	titleLabel.AutomaticSize = Enum.AutomaticSize.X
	titleLabel.Size = UDim2.new(0, 0, 1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = self.theme.White
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 20
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 6
	titleLabel.LayoutOrder = 1
	titleLabel.Parent = titleRow
	self.titleLabel = titleLabel

	if showVersion then
		local versionPill = Instance.new("Frame")
		versionPill.Size = UDim2.new(0, 48, 0, 18)
		versionPill.BackgroundColor3 = self.theme.Accent
		versionPill.BorderSizePixel = 0
		versionPill.ZIndex = 6
		versionPill.LayoutOrder = 2
		versionPill.Parent = titleRow
		Instance.new("UICorner", versionPill).CornerRadius = UDim.new(0, 4)
		table.insert(self.accentObjects, versionPill)
		self.versionPill = versionPill
		local versionLabel = Instance.new("TextLabel")
		versionLabel.Size = UDim2.new(1, 0, 1, 0)
		versionLabel.BackgroundTransparency = 1
		versionLabel.Text = "v1.0"
		versionLabel.TextColor3 = Color3.fromRGB(10,10,10)
		versionLabel.Font = Enum.Font.GothamBold
		versionLabel.TextSize = 10
		versionLabel.ZIndex = 7
		versionLabel.Parent = versionPill
		self.versionLabel = versionLabel
	end

	local hintLabel = Instance.new("TextLabel")
	hintLabel.Size = UDim2.new(0, 120, 0, 46)
	hintLabel.Position = UDim2.new(1, -10, 0.5, 0)
	hintLabel.AnchorPoint = Vector2.new(1, 0.5)
	hintLabel.BackgroundTransparency = 1
	hintLabel.Text = "[ " .. (self.toggleKey and self.toggleKey.Name or "RSHIFT") .. " ]  TOGGLE"
	hintLabel.TextColor3 = self.theme.Gray
	hintLabel.Font = Enum.Font.GothamSemibold
	hintLabel.TextSize = 9
	hintLabel.TextXAlignment = Enum.TextXAlignment.Right
	hintLabel.Parent = header
	self.hintLabel = hintLabel

	local initialSW = getSidebarWidth()

	local sidebar = Instance.new("ScrollingFrame")
	sidebar.Size = UDim2.new(0, initialSW, 1, -92)
	sidebar.Position = UDim2.new(0, 0, 0, 46)
	sidebar.BackgroundColor3 = self.theme.Panel
	sidebar.BackgroundTransparency = 0
	sidebar.BorderSizePixel = 0
	sidebar.ScrollBarThickness = 0
	sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
	sidebar.ClipsDescendants = true
	sidebar.Parent = win
	Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 6)
	self.sidebar = sidebar
	local sidebarLayout = Instance.new("UIListLayout", sidebar)
	sidebarLayout.Padding = UDim.new(0, 2)
	sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
	local sidebarPad = Instance.new("UIPadding", sidebar)
	sidebarPad.PaddingTop = UDim.new(0, 4)
	sidebarPad.PaddingBottom = UDim.new(0, 4)

	local sidebarEdge = Instance.new("Frame")
	sidebarEdge.Size = UDim2.new(0, 1, 1, -92)
	sidebarEdge.Position = UDim2.new(0, initialSW, 0, 46)
	sidebarEdge.BackgroundColor3 = self.theme.Border
	sidebarEdge.BorderSizePixel = 0
	sidebarEdge.Parent = win
	self.sidebarEdge = sidebarEdge

	local content = Instance.new("ScrollingFrame")
	content.Size = UDim2.new(0, size.X - initialSW - 1, 1, -92)
	content.Position = UDim2.new(0, initialSW + 1, 0, 46)
	content.BackgroundColor3 = self.theme.BG
	content.BorderSizePixel = 0
	content.Parent = win
	content.ScrollBarThickness = 0
	content.CanvasSize = UDim2.new(0, 0, 0, 0)
	content.ScrollingDirection = Enum.ScrollingDirection.XY
	content.ClipsDescendants = true
	self.content = content

	local tabOverlay = Instance.new("Frame")
	tabOverlay.Size = UDim2.new(1, 0, 1, -92)
	tabOverlay.Position = UDim2.new(0, 0, 0, 46)
	tabOverlay.BackgroundColor3 = self.theme.BG
	tabOverlay.BackgroundTransparency = 1
	tabOverlay.BorderSizePixel = 0
	tabOverlay.ZIndex = 50
	tabOverlay.Active = false
	tabOverlay.Parent = win
	self.tabOverlay = tabOverlay

	local navbar = Instance.new("ScrollingFrame")
	navbar.Size = UDim2.new(1, 0, 0, 46)
	navbar.Position = UDim2.new(0, 0, 1, -46)
	navbar.BackgroundColor3 = self.theme.Panel
	navbar.BorderSizePixel = 0
	navbar.ScrollBarThickness = 0
	navbar.ScrollingDirection = Enum.ScrollingDirection.X
	navbar.AutomaticCanvasSize = Enum.AutomaticSize.X
	navbar.CanvasSize = UDim2.new(0, 0, 0, 0)
	navbar.ClipsDescendants = true
	navbar.Parent = win
	Instance.new("UICorner", navbar).CornerRadius = UDim.new(0, 6)

	local navTopLine = Instance.new("Frame")
	navTopLine.Size = UDim2.new(1, 0, 0, 1)
	navTopLine.Position = UDim2.new(0, 0, 1, -46)
	navTopLine.BackgroundColor3 = self.theme.Border
	navTopLine.BorderSizePixel = 0
	navTopLine.ZIndex = 10
	navTopLine.Parent = win
	self.navTopLine = navTopLine
	self.navbar = navbar
	local navList = Instance.new("UIListLayout", navbar)
	navList.FillDirection = Enum.FillDirection.Horizontal
	navList.HorizontalAlignment = Enum.HorizontalAlignment.Left
	navList.VerticalAlignment = Enum.VerticalAlignment.Center
	navList.Padding = UDim.new(0, 0)

	self.navTabCount = 0
	self.navScrollEnabled = false

	local function updateNavScroll()
		self.navTabCount = self.navTabCount + 1
		if self.navTabCount >= 6 and not self.navScrollEnabled then
			self.navScrollEnabled = true
			navbar.ClipsDescendants = true
			for _, child in ipairs(navbar:GetChildren()) do
				if child:IsA("TextButton") then child.Size = UDim2.new(0, 90, 0, self.navbarHeight or 46) end
			end
		end
	end
	self.updateNavScroll = updateNavScroll

	do
		local drag, dragStart, dragPos = false, nil, nil
		header.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true dragStart = i.Position dragPos = win.Position end end)
		table.insert(self.connections, UIS.InputChanged:Connect(function(i) if drag and i.UserInputType == Enum.UserInputType.MouseMovement then local delta = i.Position - dragStart win.Position = UDim2.new(dragPos.X.Scale, dragPos.X.Offset + delta.X, dragPos.Y.Scale, dragPos.Y.Offset + delta.Y) self.originalPosition = win.Position self.savedPos = win.Position end end))
		table.insert(self.connections, UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end))
	end

	table.insert(self.connections, UIS.InputBegan:Connect(function(input, gpe) if input.KeyCode == self.toggleKey then self:setVisible(not self.visibleTarget) end end))

	self.tabs = {}
	self.tabOrder = {}
	self.activeTab = nil
	self.navList = navList

	if includeUITab ~= false then
		self.includeUITab = true
		task.defer(function()
			if not self.uiTabCreated then
				self.uiTabCreated = true
				self:buildUITab()
			end
		end)
	end

	local ctxMenu = Instance.new("TextButton")
	ctxMenu.Size = UDim2.new(0, 180, 0, 0)
	ctxMenu.BackgroundColor3 = self.theme.Surface
	ctxMenu.BorderSizePixel = 0
	ctxMenu.Text = ""
	ctxMenu.AutoButtonColor = false
	ctxMenu.Visible = false
	ctxMenu.ZIndex = 900
	ctxMenu.Parent = self.sg
	Instance.new("UICorner", ctxMenu).CornerRadius = UDim.new(0, 7)
	local ctxStroke = Instance.new("UIStroke", ctxMenu)
	ctxStroke.Color = self.theme.Border
	ctxStroke.Thickness = 1
	local ctxLayout = Instance.new("UIListLayout", ctxMenu)
	ctxLayout.Padding = UDim.new(0, 2)
	ctxLayout.SortOrder = Enum.SortOrder.LayoutOrder
	local ctxPadding = Instance.new("UIPadding", ctxMenu)
	ctxPadding.PaddingTop = UDim.new(0, 6)
	ctxPadding.PaddingBottom = UDim.new(0, 6)
	ctxPadding.PaddingLeft = UDim.new(0, 6)
	ctxPadding.PaddingRight = UDim.new(0, 6)
	self.contextMenuFrame = ctxMenu
	self.contextMenu = ctxMenu
	self.contextMenuLayout = ctxLayout

	local function closeContextMenu()
		ctxMenu.Visible = false
		for _, c in ipairs(contextMenuConnections) do pcall(c.Disconnect, c) end
		contextMenuConnections = {}
		for _, child in ipairs(ctxMenu:GetChildren()) do
			if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
				pcall(function() child:Destroy() end)
			end
		end
	end
	self.closeContextMenu = closeContextMenu

	local function addContextMenuItem(text, callback, accent)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 28)
		btn.BackgroundTransparency = 1
		btn.Text = ""
		btn.ZIndex = 901
		btn.Parent = ctxMenu
		local hov = Instance.new("Frame")
		hov.Size = UDim2.new(1, 0, 1, 0)
		hov.BackgroundColor3 = Color3.fromRGB(38,38,38)
		hov.BorderSizePixel = 0
		hov.BackgroundTransparency = 1
		hov.ZIndex = 901
		hov.Parent = btn
		Instance.new("UICorner", hov).CornerRadius = UDim.new(0, 5)
		btn.MouseEnter:Connect(function()
			TweenService:Create(hov, TweenInfo.new(0.1), {BackgroundTransparency = 0}):Play()
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(hov, TweenInfo.new(0.1), {BackgroundTransparency = 1}):Play()
		end)
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -12, 1, 0)
		lbl.Position = UDim2.new(0, 10, 0, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = text
		lbl.TextColor3 = accent and self.theme.Accent or self.theme.White
		lbl.Font = Enum.Font.GothamSemibold
		lbl.TextSize = 12
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.ZIndex = 902
		lbl.Parent = btn
		btn.MouseButton1Click:Connect(function()
			if callback then callback() end
			closeContextMenu()
		end)
		return lbl
	end
	local function addCtxSeparator()
		local sep = Instance.new("Frame")
		sep.Size = UDim2.new(1, 0, 0, 1)
		sep.BackgroundColor3 = self.theme.Border
		sep.BorderSizePixel = 0
		sep.ZIndex = 901
		sep.Parent = ctxMenu
	end
	self.addContextMenuItem = addContextMenuItem

	function self:showContextMenu(pos, elemConfig)
		closeContextMenu()
		local screenW = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 1920
		local screenH = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 1080
		local menuW = 180
		local x = math.clamp(pos.X, 4, screenW - menuW - 4)
		local y = math.clamp(pos.Y, 4, screenH - 200)
		ctxMenu.Position = UDim2.new(0, x, 0, y)

		local function addSection(txt)
			local f = Instance.new("Frame")
			f.Size = UDim2.new(1, 0, 0, 18)
			f.BackgroundTransparency = 1
			f.ZIndex = 901
			f.Parent = ctxMenu
			local l = Instance.new("TextLabel", f)
			l.Size = UDim2.new(1, -8, 1, 0)
			l.Position = UDim2.new(0, 8, 0, 0)
			l.BackgroundTransparency = 1
			l.Text = txt:upper()
			l.TextColor3 = self.theme.Gray
			l.Font = Enum.Font.GothamBold
			l.TextSize = 9
			l.TextXAlignment = Enum.TextXAlignment.Left
			l.ZIndex = 902
		end

		addSection("Actions")
		if elemConfig and elemConfig.DefaultValue ~= nil then
			addContextMenuItem("Reset to Default", function()
				if elemConfig.SetValue then elemConfig:SetValue(elemConfig.DefaultValue) end
			end)
		end
		if elemConfig and elemConfig.Value ~= nil then
			addContextMenuItem("Copy Value", function()
				local v = elemConfig.Value
				local str
				if type(v) == "boolean" then str = tostring(v)
				elseif type(v) == "number" then str = tostring(math.floor(v * 1000) / 1000)
				elseif type(v) == "string" then str = v
				elseif type(v) == "table" then str = table.concat(v, ", ")
				elseif typeof and typeof(v) == "Color3" then
					str = string.format("#%02x%02x%02x", math.floor(v.R*255+0.5), math.floor(v.G*255+0.5), math.floor(v.B*255+0.5))
				else str = tostring(v) end
				if setclipboard then pcall(setclipboard, str) end
				self:notify("Copied: " .. str, "info", 2)
			end)
		end

		if elemConfig and elemConfig.IsToggle then
			addCtxSeparator()
			addSection("Behavior")

			local modeNames = {always = "Always On", toggle = "Toggle", hold = "Hold"}
			local modeOrder = {"always", "toggle", "hold"}
			local currentMode = elemConfig.Mode or "toggle"

			local modeRow = Instance.new("Frame")
			modeRow.Size = UDim2.new(1, 0, 0, 28)
			modeRow.BackgroundColor3 = self.theme.Surface
			modeRow.BorderSizePixel = 0
			modeRow.ZIndex = 901
			modeRow.Parent = ctxMenu
			Instance.new("UICorner", modeRow).CornerRadius = UDim.new(0, 5)
			local modeStroke = Instance.new("UIStroke", modeRow)
			modeStroke.Color = self.theme.Border
			modeStroke.Thickness = 1

			local modeLbl = Instance.new("TextLabel")
			modeLbl.Size = UDim2.new(1, -24, 1, 0)
			modeLbl.Position = UDim2.new(0, 8, 0, 0)
			modeLbl.BackgroundTransparency = 1
			modeLbl.Text = modeNames[currentMode] or "Toggle"
			modeLbl.TextColor3 = self.theme.Accent
			modeLbl.Font = Enum.Font.GothamBold
			modeLbl.TextSize = 11
			modeLbl.TextXAlignment = Enum.TextXAlignment.Left
			modeLbl.ZIndex = 902
			modeLbl.Parent = modeRow

			local modeArrow = Instance.new("TextLabel")
			modeArrow.Size = UDim2.new(0, 18, 1, 0)
			modeArrow.Position = UDim2.new(1, -20, 0, 0)
			modeArrow.BackgroundTransparency = 1
			modeArrow.Text = "▼"
			modeArrow.TextColor3 = self.theme.Gray
			modeArrow.Font = Enum.Font.GothamBold
			modeArrow.TextSize = 9
			modeArrow.ZIndex = 902
			modeArrow.Parent = modeRow

			local modeList = Instance.new("Frame")
			modeList.Size = UDim2.new(1, 0, 0, #modeOrder * 26 + 6)
			modeList.Position = UDim2.new(0, 0, 1, 3)
			modeList.BackgroundColor3 = self.theme.Base
			modeList.BorderSizePixel = 0
			modeList.Visible = false
			modeList.ZIndex = 920
			modeList.Parent = modeRow
			Instance.new("UICorner", modeList).CornerRadius = UDim.new(0, 5)
			local mlStroke = Instance.new("UIStroke", modeList)
			mlStroke.Color = self.theme.Border
			mlStroke.Thickness = 1
			local mlLayout = Instance.new("UIListLayout", modeList)
			mlLayout.Padding = UDim.new(0, 1)
			Instance.new("UIPadding", modeList).PaddingTop = UDim.new(0, 3)

			for _, mode in ipairs(modeOrder) do
				local isActive = currentMode == mode
				local opt = Instance.new("TextButton")
				opt.Size = UDim2.new(1, 0, 0, 24)
				opt.BackgroundTransparency = 1
				opt.Text = ""
				opt.ZIndex = 921
				opt.Parent = modeList
				local optHov = Instance.new("Frame", opt)
				optHov.Size = UDim2.new(1, -6, 1, -2)
				optHov.Position = UDim2.new(0, 3, 0, 1)
				optHov.BackgroundColor3 = Color3.fromRGB(38,38,38)
				optHov.BackgroundTransparency = 1
				optHov.BorderSizePixel = 0
				optHov.ZIndex = 921
				Instance.new("UICorner", optHov).CornerRadius = UDim.new(0, 4)
				opt.MouseEnter:Connect(function() TweenService:Create(optHov, TweenInfo.new(0.08), {BackgroundTransparency = 0}):Play() end)
				opt.MouseLeave:Connect(function() TweenService:Create(optHov, TweenInfo.new(0.08), {BackgroundTransparency = 1}):Play() end)
				local optLbl = Instance.new("TextLabel", opt)
				optLbl.Size = UDim2.new(1, -28, 1, 0)
				optLbl.Position = UDim2.new(0, 10, 0, 0)
				optLbl.BackgroundTransparency = 1
				optLbl.Text = modeNames[mode]
				optLbl.TextColor3 = isActive and self.theme.Accent or self.theme.GrayLt
				optLbl.Font = Enum.Font.GothamSemibold
				optLbl.TextSize = 11
				optLbl.TextXAlignment = Enum.TextXAlignment.Left
				optLbl.ZIndex = 922
				local checkLbl = Instance.new("TextLabel", opt)
				checkLbl.Size = UDim2.new(0, 16, 1, 0)
				checkLbl.Position = UDim2.new(1, -18, 0, 0)
				checkLbl.BackgroundTransparency = 1
				checkLbl.Text = isActive and "✓" or ""
				checkLbl.TextColor3 = self.theme.Accent
				checkLbl.Font = Enum.Font.GothamBold
				checkLbl.TextSize = 11
				checkLbl.ZIndex = 922
				opt.MouseButton1Click:Connect(function()
					elemConfig.Mode = mode
					modeLbl.Text = modeNames[mode]
					if mode == "always" then elemConfig:SetValue(true) end
					self:notify("Mode: " .. modeNames[mode], "info", 1.5)
					modeList.Visible = false
					modeArrow.Text = "▼"
					closeContextMenu()
				end)
			end

			local modeBtn = Instance.new("TextButton")
			modeBtn.Size = UDim2.new(1, 0, 1, 0)
			modeBtn.BackgroundTransparency = 1
			modeBtn.Text = ""
			modeBtn.ZIndex = 910
			modeBtn.Parent = modeRow
			local modeOpen = false
			modeBtn.MouseButton1Click:Connect(function()
				modeOpen = not modeOpen
				modeList.Visible = modeOpen
				modeArrow.Text = modeOpen and "▲" or "▼"
				task.defer(function()
					ctxMenu.Size = UDim2.new(0, 180, 0, ctxLayout.AbsoluteContentSize.Y + 12
						+ (modeOpen and modeList.AbsoluteSize.Y or 0))
				end)
			end)

			addCtxSeparator()
			addSection("Hotkey")

			local hkRow = Instance.new("Frame")
			hkRow.Size = UDim2.new(1, 0, 0, 28)
			hkRow.BackgroundTransparency = 1
			hkRow.ZIndex = 901
			hkRow.Parent = ctxMenu
			local hkTextLbl = Instance.new("TextLabel")
			hkTextLbl.Size = UDim2.new(1, -60, 1, 0)
			hkTextLbl.Position = UDim2.new(0, 10, 0, 0)
			hkTextLbl.BackgroundTransparency = 1
			hkTextLbl.Text = "Bind Key"
			hkTextLbl.TextColor3 = self.theme.White
			hkTextLbl.Font = Enum.Font.GothamSemibold
			hkTextLbl.TextSize = 12
			hkTextLbl.TextXAlignment = Enum.TextXAlignment.Left
			hkTextLbl.ZIndex = 902

			local hkBox = Instance.new("TextButton")
			hkBox.Size = UDim2.new(0, 52, 0, 20)
			hkBox.Position = UDim2.new(1, -56, 0.5, -10)
			hkBox.BackgroundColor3 = self.theme.Surface
			hkBox.BorderSizePixel = 0
			hkBox.Text = elemConfig.Hotkey and elemConfig.Hotkey.Name or "None"
			hkBox.TextColor3 = self.theme.Accent
			hkBox.Font = Enum.Font.GothamBold
			hkBox.TextSize = 10
			hkBox.ZIndex = 902
			Instance.new("UICorner", hkBox).CornerRadius = UDim.new(0, 4)
			local hkStroke = Instance.new("UIStroke", hkBox)
			hkStroke.Color = self.theme.Border
			hkStroke.Thickness = 1
			hkTextLbl.Parent = hkRow
			hkBox.Parent = hkRow

			local listening = false
			hkBox.MouseButton1Click:Connect(function()
				if listening then return end
				listening = true
				hkBox.Text = "..."
				hkBox.TextColor3 = Color3.fromRGB(255, 255, 100)
				local con
				con = UIS.InputBegan:Connect(function(input, gpe)
					if gpe then return end
					con:Disconnect()
					listening = false
					if input.KeyCode == Enum.KeyCode.Escape then
						elemConfig.Hotkey = nil
						hkBox.Text = "None"
						hkBox.TextColor3 = self.theme.Accent
						self:notify("Hotkey cleared", "info", 1.5)
					elseif input.UserInputType == Enum.UserInputType.Keyboard then
						elemConfig.Hotkey = input.KeyCode
						hkBox.Text = input.KeyCode.Name
						hkBox.TextColor3 = self.theme.Accent
						self:notify("Hotkey: " .. input.KeyCode.Name, "success", 1.5)
					end
				end)
			end)
		end

		task.defer(function()
			ctxMenu.Size = UDim2.new(0, 180, 0, ctxLayout.AbsoluteContentSize.Y + 12)
		end)
		ctxMenu.Visible = true

		local dismissConn
		dismissConn = UIS.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
				local mp = UIS:GetMouseLocation()
				local ap, as = ctxMenu.AbsolutePosition, ctxMenu.AbsoluteSize
				if mp.X < ap.X or mp.X > ap.X + as.X or mp.Y < ap.Y or mp.Y > ap.Y + as.Y then
					closeContextMenu()
					dismissConn:Disconnect()
				end
			end
		end)
		table.insert(contextMenuConnections, dismissConn)
	end

	table.insert(self.connections, UIS.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		for _, elem in pairs(self.configs) do
			if elem.IsToggle and elem.Hotkey and input.KeyCode == elem.Hotkey then
				local mode = elem.Mode or "toggle"
				if mode == "toggle" then elem.SetValue(not elem.Value)
				elseif mode == "hold" then elem.SetValue(true) end
			end
		end
	end))
	table.insert(self.connections, UIS.InputEnded:Connect(function(input)
		for _, elem in pairs(self.configs) do
			if elem.IsToggle and elem.Hotkey and input.KeyCode == elem.Hotkey then
				local mode = elem.Mode or "toggle"
				if mode == "hold" then elem.SetValue(false) end
			end
		end
	end))

	self:notify("CloverLib Loaded", "success", 2)
	table.insert(allWindows, self)

	if includeUITab ~= false then
		self:buildUITab()
	end

	task.defer(function()
		self:setVisible(true)
	end)

	return self
end

function UILib:addWatermark(name)
	if self.watermark then self.watermark:Destroy() end
	local wm = Instance.new("CanvasGroup")
	wm.AutomaticSize = Enum.AutomaticSize.X
	wm.Size = UDim2.new(0, 0, 0, 30)
	wm.Position = UDim2.new(1, -10, 0, 10)
	wm.AnchorPoint = Vector2.new(1, 0)
	wm.BackgroundColor3 = self.theme.Panel
	wm.BorderSizePixel = 0
	wm.Parent = self.sg
	wm.ZIndex = 200
	Instance.new("UICorner", wm).CornerRadius = UDim.new(0, 6)
	local sep = Instance.new("Frame")
	sep.Size = UDim2.new(1, -16, 0, 1)
	sep.Position = UDim2.new(0, 8, 1, -4)
	sep.BackgroundColor3 = self.theme.Accent
	sep.BorderSizePixel = 0
	sep.ZIndex = 201
	sep.Parent = wm
	local row = Instance.new("Frame")
	row.AutomaticSize = Enum.AutomaticSize.X
	row.Size = UDim2.new(0, 0, 1, 0)
	row.BackgroundTransparency = 1
	row.ZIndex = 201
	row.Parent = wm
	local rowLayout = Instance.new("UIListLayout", row)
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rowLayout.Padding = UDim.new(0, 6)
	rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	local rowPad = Instance.new("UIPadding", row)
	rowPad.PaddingLeft = UDim.new(0, 10)
	rowPad.PaddingRight = UDim.new(0, 10)
	local watermarkScale = Instance.new("UIScale", wm)
	watermarkScale.Scale = 1
	local function updateWatermarkSize(delta)
		watermarkScale.Scale = math.clamp(watermarkScale.Scale + delta * 0.05, 0.5, 2)
	end
	wm.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			updateWatermarkSize(input.Position.Z > 0 and 1 or -1)
		end
	end)
	local dragBtn = Instance.new("TextButton")
	dragBtn.Size = UDim2.new(1, 0, 1, 0)
	dragBtn.BackgroundTransparency = 1
	dragBtn.Text = ""
	dragBtn.ZIndex = 205
	dragBtn.Parent = wm
	do
		local drag, dragStart, dragPos = false, nil, nil
		dragBtn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true dragStart = i.Position dragPos = wm.Position end end)
		table.insert(self.connections, UIS.InputChanged:Connect(function(i) if drag and i.UserInputType == Enum.UserInputType.MouseMovement then local delta = i.Position - dragStart wm.Position = UDim2.new(dragPos.X.Scale, dragPos.X.Offset + delta.X, dragPos.Y.Scale, dragPos.Y.Offset + delta.Y) end end))
		table.insert(self.connections, UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end))
	end
	local nameLbl = Instance.new("TextLabel")
	nameLbl.AutomaticSize = Enum.AutomaticSize.X
	nameLbl.Size = UDim2.new(0, 0, 1, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = name
	nameLbl.TextColor3 = self.theme.White
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextSize = 12
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.ZIndex = 201
	nameLbl.LayoutOrder = 1
	nameLbl.Parent = row
	local divider = Instance.new("Frame")
	divider.Size = UDim2.new(0, 1, 0, 14)
	divider.BackgroundColor3 = self.theme.Border
	divider.BorderSizePixel = 0
	divider.ZIndex = 201
	divider.LayoutOrder = 2
	divider.Parent = row
	local fpsLabel = Instance.new("TextLabel")
	fpsLabel.AutomaticSize = Enum.AutomaticSize.X
	fpsLabel.Size = UDim2.new(0, 0, 1, 0)
	fpsLabel.BackgroundTransparency = 1
	fpsLabel.Text = "FPS: 0"
	fpsLabel.TextColor3 = self.theme.Accent
	fpsLabel.Font = Enum.Font.GothamSemibold
	fpsLabel.TextSize = 10
	fpsLabel.ZIndex = 201
	fpsLabel.LayoutOrder = 3
	fpsLabel.Parent = row
	local pingDivider = Instance.new("Frame")
	pingDivider.Size = UDim2.new(0, 1, 0, 14)
	pingDivider.BackgroundColor3 = self.theme.Border
	pingDivider.BorderSizePixel = 0
	pingDivider.ZIndex = 201
	pingDivider.LayoutOrder = 4
	pingDivider.Parent = row
	local pingLabel = Instance.new("TextLabel")
	pingLabel.AutomaticSize = Enum.AutomaticSize.X
	pingLabel.Size = UDim2.new(0, 0, 1, 0)
	pingLabel.BackgroundTransparency = 1
	pingLabel.Text = "Ping: 0ms"
	pingLabel.TextColor3 = self.theme.Accent
	pingLabel.Font = Enum.Font.GothamSemibold
	pingLabel.TextSize = 10
	pingLabel.ZIndex = 201
	pingLabel.LayoutOrder = 5
	pingLabel.Parent = row
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
		pingLabel.Text = "Ping: " .. math.floor(ping + 0.5) .. "ms"
	end)
	self.wmConn = connection
	self.watermark = wm
	table.insert(self.accentObjects, sep)
	table.insert(self.accentObjects, fpsLabel)
	table.insert(self.accentObjects, pingLabel)
	return wm
end

function UILib:buildUITab()
	local uiTab = self:addTab("UI")
	local uiSub = uiTab:addSubTab("Settings")
	local uiL, uiR = uiSub:split()

	local grp = uiL:addGroup("Interface")

	grp:colorpicker("Accent Color", self.theme.Accent, function(c)
		self:updateAccent(c)
	end, "Update accent color")

	grp:keybind("Toggle Key", "RightShift", function(_, name)
		self.toggleKey = Enum.KeyCode[name] or Enum.KeyCode.RightShift
		if self.hintLabel then self.hintLabel.Text = "[ " .. name .. " ]  TOGGLE" end
	end, "Set key to show/hide menu")

	grp:toggle("Show Version", self.showVersion, function(v)
		self.showVersion = v
		if self.versionPill then self.versionPill.Visible = v end
	end, "Show version pill")

	grp:toggle("Show Watermark", false, function(v)
		if v then self:addWatermark(self.title)
		else if self.watermark then self.watermark:Destroy(); self.watermark = nil end end
	end, "Display FPS and ping")

	grp:button("Unload", function() self:Destroy() end, "Cleanly remove the UI",
		Enum.TextXAlignment.Center, Color3.fromRGB(255, 80, 80))

	local cfg = uiR:addGroup("Configs")
	local currentConfig = "default"

	local function getConfigList()
		local list = self:listConfigs()
		if #list == 0 then list = {"(no configs)"} end
		table.sort(list)
		return list
	end

	local nameElem = cfg:textbox("Config Name", "default", "", function(val)
		currentConfig = (val ~= "" and val or "default")
	end, "Name for save/load/delete")

	local loadElem = cfg:dropdown("Load Config", getConfigList(), "", function(val)
		if val == "" or val == "(no configs)" then return end
		currentConfig = val

		nameElem.SetValue(val)
		self:loadConfig(val)
	end, "Select a saved config to load", function()
		return getConfigList()
	end)

	local function refreshConfigDropdown(selectName)
		local list = getConfigList()
		loadElem:SetValues(list)

		local keep = selectName or currentConfig
		local exists = false
		for _, v in ipairs(list) do if v == keep then exists = true; break end end
		if exists then
			loadElem.Value = keep

			local selLbl = loadElem.frame and loadElem.frame:FindFirstChild("arrow", true)

			loadElem.SetValue(keep)
		else
			loadElem.SetValue(list[1] or "")
		end
	end

	cfg:button("Save Config", function() if self.saveConfig then self:saveConfig(nameElem.Value); refreshConfigDropdown(nameElem.Value) end end, nil, Enum.TextXAlignment.Center)
	cfg:button("Load Selected", function() if self.loadConfig then self:loadConfig(loadElem.Value); nameElem.SetValue(loadElem.Value) end end, nil, Enum.TextXAlignment.Center)
	cfg:button("Delete Config", function() if self.deleteConfig then self:deleteConfig(loadElem.Value); refreshConfigDropdown() end end, nil, Enum.TextXAlignment.Center)
end

function UILib:setTitle(text)
	if self.titleLabel then self.titleLabel.Text = tostring(text) end
end

function UILib:Destroy()
	for _, conn in ipairs(self.connections) do conn:Disconnect() end
	if self.wmConn then self.wmConn:Disconnect(); self.wmConn = nil end
	if self.sg then self.sg:Destroy() end
	for i, w in ipairs(allWindows) do
		if w == self then table.remove(allWindows, i); break end
	end
end

function UILib:setVisible(visible)
	if visible == self.visibleTarget then return end
	self.visibleTarget = visible
	
	if visible then
		self.window.Visible = true
		TweenService:Create(self.window, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { GroupTransparency = 0 }):Play()
		TweenService:Create(self.uiScale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	else
		TweenService:Create(self.window, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { GroupTransparency = 1 }):Play()
		TweenService:Create(self.uiScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0.8 }):Play()
		task.delay(0.35, function()
			if not self.visibleTarget then 
				self.window.Visible = false
			end
		end)
	end
end

function UILib:toggle()
	self:setVisible(not self.visibleTarget)
end

function UILib:confirm(message, onYes, onNo)
	local overlay = Instance.new("TextButton")
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 800
	overlay.Text = ""
	overlay.AutoButtonColor = false
	overlay.Parent = self.sg
	table.insert(self.activePopups, overlay)

	local modal = Instance.new("Frame")
	modal.Size = UDim2.new(0, 300, 0, 130)
	modal.AnchorPoint = Vector2.new(0.5, 0.5)
	modal.Position = UDim2.new(0.5, 0, 0.5, 0)
	modal.BackgroundColor3 = self.theme.Panel
	modal.BorderSizePixel = 0
	modal.ZIndex = 801
	modal.Parent = self.sg
	table.insert(self.activePopups, modal)
	Instance.new("UICorner", modal).CornerRadius = UDim.new(0, 8)

	local msgLabel = Instance.new("TextLabel")
	msgLabel.Size = UDim2.new(1, -32, 0, 54)
	msgLabel.Position = UDim2.new(0, 16, 0, 12)
	msgLabel.BackgroundTransparency = 1
	msgLabel.Text = message
	msgLabel.TextColor3 = Color3.new(1, 1, 1)
	msgLabel.Font = Enum.Font.GothamSemibold
	msgLabel.TextSize = 14
	msgLabel.TextWrapped = true
	msgLabel.TextXAlignment = Enum.TextXAlignment.Center
	msgLabel.TextYAlignment = Enum.TextYAlignment.Center
	msgLabel.ZIndex = 802
	msgLabel.Parent = modal

	local btnRow = Instance.new("Frame")
	btnRow.Size = UDim2.new(1, -32, 0, 34)
	btnRow.Position = UDim2.new(0, 16, 1, -44)
	btnRow.BackgroundTransparency = 1
	btnRow.ZIndex = 802
	btnRow.Parent = modal

	local function makeBtn(text, color, xPos, callback)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.5, -6, 1, 0)
		btn.Position = UDim2.new(xPos, xPos > 0 and 6 or 0, 0, 0)
		btn.BackgroundColor3 = color
		btn.BorderSizePixel = 0
		btn.Text = text
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 13
		btn.ZIndex = 803
		btn.Parent = btnRow
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
		btn.MouseButton1Click:Connect(function()
			overlay:Destroy()
			modal:Destroy()
			if callback then callback() end
		end)
	end

	makeBtn("Cancel", self.theme.Track, 0, onNo)
	makeBtn("Confirm", self.theme.Accent, 0.5, onYes)

	local tweenIn = TweenService:Create(modal, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 300, 0, 130)})
	modal.Size = UDim2.new(0, 260, 0, 100)
	tweenIn:Play()
end

function UILib:newMiniWindow(title, width, posX, posY)
	width = width or 240
	local mini = {}
	mini.window = self
	mini.rows = {}
	mini.connections = {}

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, width, 0, 32)
	frame.Position = UDim2.new(0, posX or 10, 0, posY or 10)
	frame.BackgroundColor3 = self.theme.Panel
	frame.BorderSizePixel = 0
	frame.ZIndex = 300
	frame.Parent = self.sg
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
	local fStroke = Instance.new("UIStroke", frame)
	fStroke.Color = self.theme.Border
	fStroke.Thickness = 1
	mini.frame = frame

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 32)
	header.BackgroundTransparency = 1
	header.ZIndex = 301
	header.Parent = frame

	local accentLine = Instance.new("Frame")
	accentLine.Size = UDim2.new(1, -2, 0, 2)
	accentLine.Position = UDim2.new(0, 1, 0, 30)
	accentLine.BackgroundColor3 = self.theme.Accent
	accentLine.BorderSizePixel = 0
	accentLine.ZIndex = 299
	accentLine.Parent = frame
	table.insert(self.accentObjects, accentLine)

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size = UDim2.new(1, -40, 1, 0)
	titleLbl.Position = UDim2.new(0, 10, 0, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = title:upper()
	titleLbl.TextColor3 = self.theme.GrayLt
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextSize = 10
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.ZIndex = 302
	titleLbl.Parent = header

	local collapseBtn = Instance.new("TextButton")
	collapseBtn.Size = UDim2.new(0, 24, 0, 24)
	collapseBtn.Position = UDim2.new(1, -28, 0.5, -12)
	collapseBtn.BackgroundTransparency = 1
	collapseBtn.Text = "−"
	collapseBtn.TextColor3 = self.theme.Gray
	collapseBtn.Font = Enum.Font.GothamBold
	collapseBtn.TextSize = 16
	collapseBtn.ZIndex = 303
	collapseBtn.Parent = header

	local body = Instance.new("Frame")
	body.Size = UDim2.new(1, 0, 0, 0)
	body.Position = UDim2.new(0, 0, 0, 32)
	body.BackgroundTransparency = 1
	body.ClipsDescendants = true
	body.ZIndex = 301
	body.Parent = frame
	mini.body = body

	local layout = Instance.new("UIListLayout", body)
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	local bodyPad = Instance.new("UIPadding", body)
	bodyPad.PaddingLeft = UDim.new(0, 8)
	bodyPad.PaddingRight = UDim.new(0, 8)
	bodyPad.PaddingTop = UDim.new(0, 6)
	bodyPad.PaddingBottom = UDim.new(0, 8)

	local collapsed = false
	local fullH = 32

	local function updateHeight()
		local contentH = layout.AbsoluteContentSize.Y + 14
		body.Size = UDim2.new(1, 0, 0, contentH)
		fullH = 32 + contentH
		if not collapsed then frame.Size = UDim2.new(0, width, 0, fullH) end
	end
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateHeight)

	collapseBtn.MouseButton1Click:Connect(function()
		collapsed = not collapsed
		collapseBtn.Text = collapsed and "+" or "−"
		local targetH = collapsed and 32 or fullH
		body.Visible = not collapsed
		TweenService:Create(frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, width, 0, targetH)
		}):Play()
	end)

	do
		local drag, dragStart, dragPos = false, nil, nil
		header.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true dragStart = i.Position dragPos = frame.Position end end)
		local dc = UIS.InputChanged:Connect(function(i) if drag and i.UserInputType == Enum.UserInputType.MouseMovement then local delta = i.Position - dragStart frame.Position = UDim2.new(dragPos.X.Scale, dragPos.X.Offset + delta.X, dragPos.Y.Scale, dragPos.Y.Offset + delta.Y) end end)
		local de = UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end)
		table.insert(mini.connections, dc)
		table.insert(mini.connections, de)
	end

	function mini:addRow(labelText, defaultValue, color)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 22)
		row.BackgroundTransparency = 1
		row.ZIndex = 302
		row.Parent = body
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(0.55, 0, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = labelText
		lbl.TextColor3 = self.window.theme.Gray
		lbl.Font = Enum.Font.GothamSemibold
		lbl.TextSize = 12
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.ZIndex = 303
		lbl.Parent = row
		local val = Instance.new("TextLabel")
		val.Size = UDim2.new(0.45, 0, 1, 0)
		val.Position = UDim2.new(0.55, 0, 0, 0)
		val.BackgroundTransparency = 1
		val.Text = tostring(defaultValue or "—")
		val.TextColor3 = color or self.window.theme.Accent
		val.Font = Enum.Font.GothamSemibold
		val.TextSize = 12
		val.TextXAlignment = Enum.TextXAlignment.Right
		val.ZIndex = 303
		val.Parent = row
		if not color then table.insert(self.window.accentObjects, val) end
		local rowRef = {label = lbl, value = val}
		function rowRef:set(newVal) val.Text = tostring(newVal) end
		function rowRef:setColor(c) val.TextColor3 = c end
		table.insert(mini.rows, rowRef)
		updateHeight()
		return rowRef
	end

	function mini:addDivider()
		local div = Instance.new("Frame")
		div.Size = UDim2.new(1, 0, 0, 1)
		div.BackgroundColor3 = self.window.theme.Border
		div.BorderSizePixel = 0
		div.ZIndex = 302
		div.Parent = body
		updateHeight()
	end

	function mini:addProgress(labelText, value, maxVal, color)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 36)
		row.BackgroundTransparency = 1
		row.ZIndex = 302
		row.Parent = body
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(0.6, 0, 0, 16)
		lbl.BackgroundTransparency = 1
		lbl.Text = labelText
		lbl.TextColor3 = self.window.theme.Gray
		lbl.Font = Enum.Font.GothamSemibold
		lbl.TextSize = 11
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.ZIndex = 303
		lbl.Parent = row
		local valLbl = Instance.new("TextLabel")
		valLbl.Size = UDim2.new(0.4, 0, 0, 16)
		valLbl.Position = UDim2.new(0.6, 0, 0, 0)
		valLbl.BackgroundTransparency = 1
		valLbl.Text = tostring(value) .. " / " .. tostring(maxVal)
		valLbl.TextColor3 = color or self.window.theme.Accent
		valLbl.Font = Enum.Font.GothamSemibold
		valLbl.TextSize = 11
		valLbl.TextXAlignment = Enum.TextXAlignment.Right
		valLbl.ZIndex = 303
		valLbl.Parent = row
		local track = Instance.new("Frame")
		track.Size = UDim2.new(1, 0, 0, 4)
		track.Position = UDim2.new(0, 0, 0, 22)
		track.BackgroundColor3 = self.window.theme.Track
		track.BorderSizePixel = 0
		track.ZIndex = 303
		track.Parent = row
		Instance.new("UICorner", track).CornerRadius = UDim.new(0, 2)
		local fill = Instance.new("Frame")
		fill.Size = UDim2.new(math.clamp(value / maxVal, 0, 1), 0, 1, 0)
		fill.BackgroundColor3 = color or self.window.theme.Accent
		fill.BorderSizePixel = 0
		fill.ZIndex = 304
		fill.Parent = track
		Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 2)
		local ref = {label = lbl, value = valLbl, fill = fill}
		function ref:set(newVal, newMax)
			newMax = newMax or maxVal
			maxVal = newMax
			value = newVal
			valLbl.Text = tostring(newVal) .. " / " .. tostring(newMax)
			TweenService:Create(fill, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
				Size = UDim2.new(math.clamp(newVal / newMax, 0, 1), 0, 1, 0)
			}):Play()
		end
		updateHeight()
		return ref
	end

	function mini:destroy()
		for _, c in ipairs(self.connections) do pcall(c.Disconnect, c) end
		frame:Destroy()
	end

	function mini:setVisible(v) frame.Visible = v end

	return mini
end

function UILib:addTab(name, options)
	options = options or {}
	local tab = setmetatable({}, UILib.Tab)
	tab.name = name
	tab.window = self
	tab.subtabs = {}
	tab.subtabOrder = {}
	tab.firstSub = nil
	tab.showSidebar = options.sidebar ~= false

	self.navTabCount = (self.navTabCount or 0) + 1

	local MIN_TAB_WIDTH = 80
	local function refreshTabWidths()
		local navW = self.navbar.AbsoluteSize.X
		if navW <= 0 then navW = self.size.X end
		local navH = self.navbar.AbsoluteSize.Y
		if navH <= 0 then navH = self.navbarHeight or 46 end
		local count = self.navTabCount
		local evenW = math.floor(navW / count)
		local useW = evenW >= MIN_TAB_WIDTH and evenW or MIN_TAB_WIDTH
		for _, child in ipairs(self.navbar:GetChildren()) do
			if child:IsA("TextButton") then child.Size = UDim2.new(0, useW, 0, navH) end
		end
	end
	self.refreshTabWidths = refreshTabWidths

	local tabIconId = options.icon
	if tabIconId then
		local s = tostring(tabIconId)
		if not s:find("rbxassetid://") then s = "rbxassetid://" .. s end
		tabIconId = s
	end

	if tabIconId and (not self.navbarHeight or self.navbarHeight < 58) then
		self.navbarHeight = 58
		self.navbar.Size = UDim2.new(1, 0, 0, 58)
		self.navbar.Position = UDim2.new(0, 0, 1, -58)

		if self.navTopLine then self.navTopLine.Position = UDim2.new(0, 0, 1, -58) end

		local sw = self.sidebar and self.sidebar.Size.X.Offset or 120
		if self.sidebar then self.sidebar.Size = UDim2.new(0, sw, 1, -104) end
		if self.sidebarEdge then self.sidebarEdge.Size = UDim2.new(0, 1, 1, -104) end
		if self.content then
			local showSidebar = self.activeTab and self.activeTab.showSidebar ~= false or true
			if showSidebar then
				self.content.Size = UDim2.new(0, self.size.X - sw - 1, 1, -104)
			else
				self.content.Size = UDim2.new(0, self.size.X, 1, -104)
			end
		end
		if self.tabOverlay then self.tabOverlay.Size = UDim2.new(1, 0, 1, -104) end

		for _, existingTab in ipairs(self.tabOrder) do
			if existingTab.btn then
				existingTab.btn.Size = UDim2.new(existingTab.btn.Size.X.Scale, existingTab.btn.Size.X.Offset, 0, 58)
			end
			if existingTab.tabLbl then

				if not existingTab.tabIconId then

					existingTab.tabLbl.Size = UDim2.new(1, 0, 1, 0)
					existingTab.tabLbl.Position = UDim2.new(0.5, 0, 0, 0)
					existingTab.tabLbl.AnchorPoint = Vector2.new(0.5, 0)
				else
					existingTab.tabLbl.Position = UDim2.new(0.5, 0, 0.5, 8)
				end
			end
		end
	end

	local iconOnly = options.iconOnly == true and tabIconId ~= nil
	local textOnly = options.textOnly == true or not tabIconId
	local showIcon = tabIconId ~= nil and not textOnly
	local showText = not iconOnly

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, MIN_TAB_WIDTH, 0, self.navbarHeight or 46)
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Parent = self.navbar

	local tabIcon = Instance.new("ImageLabel")
	tabIcon.Size = UDim2.new(0, 16, 0, 16)
	tabIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	if iconOnly then

		tabIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
	elseif showIcon then

		tabIcon.Position = UDim2.new(0.5, 0, 0.5, -9)
	else
		tabIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
	end
	tabIcon.BackgroundTransparency = 1
	tabIcon.Image = tabIconId or ""
	tabIcon.ImageColor3 = self.theme.Gray
	tabIcon.ScaleType = Enum.ScaleType.Fit
	tabIcon.ZIndex = 3
	tabIcon.Visible = showIcon
	tabIcon.Parent = btn

	local tabLbl = Instance.new("TextLabel")
	tabLbl.AnchorPoint = Vector2.new(0.5, 0)
	tabLbl.BackgroundTransparency = 1
	tabLbl.Text = name:upper()
	tabLbl.TextColor3 = self.theme.Gray
	tabLbl.Font = Enum.Font.GothamBold
	tabLbl.TextSize = 10
	tabLbl.TextXAlignment = Enum.TextXAlignment.Center
	tabLbl.TextYAlignment = Enum.TextYAlignment.Center
	tabLbl.Visible = showText
	tabLbl.ZIndex = 3
	tabLbl.Parent = btn

	if showIcon and showText then

		tabLbl.Size = UDim2.new(1, 0, 0, 14)
		tabLbl.Position = UDim2.new(0.5, 0, 0.5, 8)
	else

		tabLbl.Size = UDim2.new(1, 0, 1, 0)
		tabLbl.Position = UDim2.new(0.5, 0, 0, 0)
	end

	task.defer(refreshTabWidths)
	local underline = Instance.new("Frame")
	underline.Size = UDim2.new(0.5, 0, 0, 2)
	underline.AnchorPoint = Vector2.new(0.5, 1)
	underline.Position = UDim2.new(0.5, 0, 1, -1)
	underline.BackgroundColor3 = self.theme.Accent
	underline.BorderSizePixel = 0
	underline.Visible = false
	underline.Parent = btn
	table.insert(self.accentObjects, underline)
	btn.MouseEnter:Connect(function()
		if tabLbl.TextColor3 ~= self.theme.White then
			tabLbl.TextColor3 = self.theme.GrayLt
			if tabIconId then tabIcon.ImageColor3 = self.theme.GrayLt end
		end
	end)
	btn.MouseLeave:Connect(function()
		if tabLbl.TextColor3 ~= self.theme.White then
			tabLbl.TextColor3 = self.theme.Gray
			if tabIconId then tabIcon.ImageColor3 = self.theme.Gray end
		end
	end)
	tab.btn = btn
	tab.tabLbl = tabLbl
	tab.tabIcon = tabIcon
	tab.tabIconId = tabIconId
	tab.underline = underline

	local function activate()
		if self.tabOverlay and self.activeTab then
			self.tabOverlay.BackgroundTransparency = 0.15
			TweenService:Create(self.tabOverlay, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
		end

		for _, t in pairs(self.tabs) do
			for _, sub in pairs(t.subtabs) do
				sub.btn.Visible = false
				sub.page.Visible = false
				if sub.selLine then sub.selLine.Visible = false end
				if sub.label then sub.label.TextColor3 = self.theme.Gray end
			end
		end
		if self.activeTab then
			if self.activeTab.tabLbl then self.activeTab.tabLbl.TextColor3 = self.theme.Gray end
			if self.activeTab.tabIcon and self.activeTab.tabIconId then self.activeTab.tabIcon.ImageColor3 = self.theme.Gray end
			if self.activeTab.underline then self.activeTab.underline.Visible = false end
		end
		tabLbl.TextColor3 = self.theme.White
		if tabIconId then tabIcon.ImageColor3 = self.theme.Accent end
		underline.Visible = true
		for _, sub in pairs(tab.subtabOrder) do
			if sub.btn then sub.btn.Visible = true end
		end
		if tab.firstSub then
			local first = tab.subtabs[tab.firstSub]
			if first then first:select() end
		end
		self.sidebar.CanvasSize = UDim2.new(0, 0, 0, #tab.subtabOrder * 30 + 10)
		self.activeTab = tab

		local showSidebar = tab.showSidebar ~= false
		self.sidebar.Visible = showSidebar
		self.sidebarEdge.Visible = showSidebar
		local sw = math.max(MIN_SIDEBAR_WIDTH, math.min(MAX_SIDEBAR_WIDTH, math.floor(self.size.X * 0.22)))
		if showSidebar then
			self.content.Size = UDim2.new(0, self.size.X - sw - 1, 1, -92)
			self.content.Position = UDim2.new(0, sw + 1, 0, 46)
		else
			self.content.Size = UDim2.new(0, self.size.X, 1, -92)
			self.content.Position = UDim2.new(0, 0, 0, 46)
		end
	end
	btn.MouseButton1Click:Connect(activate)
	tab.activate = activate
	self.tabs[name] = tab
	table.insert(self.tabOrder, tab)

	if not self.activeTab then
		task.defer(function()
			if not self.activeTab then activate() end
		end)
	end

	return tab
end

function UILib:selectTab(n)
	local tab
	if type(n) == "number" then
		tab = self.tabOrder[n]
	elseif type(n) == "string" then
		tab = self.tabs[n]
	end
	if tab and tab.activate then tab.activate() end
end

function UILib.Tab:addSubTab(name)
	local sub = setmetatable({}, UILib.SubTab)
	sub.name = name
	sub.tab = self
	sub.window = self.window
	sub.groups = {}

	local btn = Instance.new("TextButton")
	table.insert(self.subtabOrder, sub)
	btn.Size = UDim2.new(1, 0, 0, 28)
	btn.Position = UDim2.new(0, 0, 0, 0)
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.ZIndex = 5
	btn.Parent = self.window.sidebar

	local hov = Instance.new("Frame")
	hov.Size = UDim2.new(1, 0, 1, 0)
	hov.BackgroundColor3 = self.window.theme.ItemHov
	hov.BorderSizePixel = 0
	hov.Visible = false
	hov.ZIndex = 4
	hov.Parent = btn
	Instance.new("UICorner", hov).CornerRadius = UDim.new(0, 4)

	local selLine = Instance.new("Frame")
	selLine.Size = UDim2.new(0, 3, 1, -8)
	selLine.Position = UDim2.new(0, 0, 0, 4)
	selLine.BackgroundColor3 = self.window.theme.Accent
	selLine.BorderSizePixel = 0
	selLine.Visible = false
	selLine.ZIndex = 6
	selLine.Parent = btn

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -10, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = name
	label.TextColor3 = self.window.theme.Gray
	label.Font = Enum.Font.GothamSemibold
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.ZIndex = 6
	label.Parent = btn

	function sub:select()
		for _, t in pairs(self.window.tabs) do
			t.btn.TextColor3 = self.window.theme.Gray
			if t.underline then t.underline.Visible = false end
			for _, s in pairs(t.subtabs) do
				s.btn.Visible = false
				s.page.Visible = false
				s.selLine.Visible = false
				s.label.TextColor3 = self.window.theme.Gray
			end
		end
		self.tab.btn.TextColor3 = self.window.theme.White
		if self.tab.underline then self.tab.underline.Visible = true end
		for _, s in pairs(self.tab.subtabs) do s.btn.Visible = true end
		self.window.activeTab = self.tab
		self.label.TextColor3 = self.window.theme.White
		self.selLine.Visible = true
		self.page.Visible = true
		self.window.sidebar.CanvasSize = UDim2.new(0, 0, 0, #self.tab.subtabOrder * 30 + 10)
	end

	btn.MouseEnter:Connect(function() hov.Visible = true end)
	btn.MouseLeave:Connect(function() hov.Visible = false end)

	local page = Instance.new("ScrollingFrame")
	page.Size = UDim2.new(1, -14, 1, -12)
	page.Position = UDim2.new(0, 7, 0, 6)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 0
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.Visible = false
	page.ZIndex = 2
	page.Parent = self.window.content
	local layout = Instance.new("UIListLayout", page)
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	local pagePadding = Instance.new("UIPadding", page)
	pagePadding.PaddingLeft = UDim.new(0, 8)
	pagePadding.PaddingRight = UDim.new(0, 8)
	pagePadding.PaddingTop = UDim.new(0, 8)
	pagePadding.PaddingBottom = UDim.new(0, 12)
	sub.btn = btn
	sub.hov = hov
	sub.selLine = selLine
	sub.label = label
	sub.page = page
	sub.layout = layout

	btn.MouseButton1Click:Connect(function() sub:select() end)

	if not self.firstSub then self.firstSub = name end
	self.subtabs[name] = sub
	table.insert(self.window.allSubTabs, {name = name, btn = btn, tab = self})
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
	local leftCol = setmetatable({ frame = left, window = self.window, tab = self.tab, sub = self }, UILib.Column)
	local rightCol = setmetatable({ frame = right, window = self.window, tab = self.tab, sub = self }, UILib.Column)
	return leftCol, rightCol
end

local function generateID() return "elem_" .. HS:GenerateGUID(false) end

local function attachTooltip(element, text, window)
	if not text or not window or not window.tooltip then return end
	local tt = window.tooltip
	element.MouseEnter:Connect(function()
		if window.tooltipSuppressed then return end
		tt.start(text, element)
	end)
	element.MouseLeave:Connect(function() tt.hide() end)
	element.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then tt.hide() end
	end)
end

function UILib.SubTab:addParagraph(ptitle, text)
	local window = self.window
	local r = Instance.new("Frame")
	r.Size = UDim2.new(1, 0, 0, 0)
	r.BackgroundColor3 = window.theme.Item
	r.BackgroundTransparency = 0.35
	r.BorderSizePixel = 0
	r.AutomaticSize = Enum.AutomaticSize.Y
	r.Parent = self.page
	Instance.new("UICorner", r).CornerRadius = UDim.new(0, 6)
	local stroke = Instance.new("UIStroke", r)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = window.theme.Border
	stroke.Thickness = 1
	local pad = Instance.new("UIPadding", r)
	pad.PaddingLeft  = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.PaddingTop   = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 10)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = ptitle
	lbl.TextColor3 = window.theme.Accent
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.AutomaticSize = Enum.AutomaticSize.Y
	lbl.TextWrapped = true
	lbl.LayoutOrder = 1
	lbl.ZIndex = 2
	lbl.Parent = r
	table.insert(window.accentObjects, lbl)
	local body = Instance.new("TextLabel")
	body.Size = UDim2.new(1, 0, 0, 0)
	body.BackgroundTransparency = 1
	body.Text = text
	body.TextColor3 = window.theme.Gray
	body.Font = Enum.Font.GothamSemibold
	body.TextSize = 12
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextWrapped = true
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.LayoutOrder = 2
	body.ZIndex = 2
	body.Parent = r
	local layout = Instance.new("UIListLayout", r)
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	local ref = {}
	function ref:setTitle(t) lbl.Text = t end
	function ref:setDesc(d)  body.Text = d end
	function ref:SetDesc(d)  body.Text = d end
	return ref
end

function UILib.SubTab:addInput(labelText, default, placeholder, callback, tooltip)
	local window = self.window
	local id = generateID()
	local r = Instance.new("Frame")
	r.Size = UDim2.new(1, 0, 0, 52)
	r.BackgroundColor3 = window.theme.Item
	r.BackgroundTransparency = 0.35
	r.BorderSizePixel = 0
	r.Parent = self.page
	Instance.new("UICorner", r).CornerRadius = UDim.new(0, 6)
	local stroke = Instance.new("UIStroke", r)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = window.theme.Border
	stroke.Thickness = 1
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -10, 0, 18)
	lbl.Position = UDim2.new(0, 8, 0, 5)
	lbl.BackgroundTransparency = 1
	lbl.Text = labelText
	lbl.TextColor3 = window.theme.GrayLt
	lbl.Font = Enum.Font.GothamSemibold
	lbl.TextSize = 12
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.ZIndex = 3
	lbl.Parent = r
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, -16, 0, 22)
	box.Position = UDim2.new(0, 8, 0, 25)
	box.BackgroundColor3 = window.theme.Track
	box.BorderSizePixel = 0
	box.ZIndex = 3
	box.Text = default or ""
	box.TextColor3 = window.theme.Accent
	box.Font = Enum.Font.GothamSemibold
	box.TextSize = 13
	box.ClearTextOnFocus = false
	box.PlaceholderText = placeholder or ""
	box.PlaceholderColor3 = window.theme.Gray
	box.Parent = r
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
	local boxStroke_ = Instance.new("UIStroke", box)
	boxStroke_.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	boxStroke_.Color = window.theme.Border
	boxStroke_.Thickness = 1
	local current = default or ""
	box.FocusLost:Connect(function(enter)
		if enter then current = box.Text if callback then callback(current) end end
	end)
	if tooltip then attachTooltip(r, tooltip, window) end
	local elem = {ID = id, Value = current, DefaultValue = default or "",
		SetValue = function(val) current = val box.Text = val end}
	function elem:SetDesc(d) lbl.Text = d end
	return elem
end

function UILib.SubTab:addButton(text, callback, tooltip, color)
	local window = self.window
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 36)
	btn.BackgroundColor3 = window.theme.Item
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.ZIndex = 3
	btn.Parent = self.page
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	local stroke = Instance.new("UIStroke", btn)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = window.theme.Border
	stroke.Thickness = 1
	local rh = Instance.new("Frame")
	rh.Size = UDim2.new(1, 0, 1, 0)
	rh.BackgroundColor3 = window.theme.ItemHov
	rh.BorderSizePixel = 0
	rh.Visible = false
	rh.ZIndex = 2
	rh.Parent = btn
	Instance.new("UICorner", rh).CornerRadius = UDim.new(0, 6)
	btn.MouseEnter:Connect(function() rh.Visible = true end)
	btn.MouseLeave:Connect(function() rh.Visible = false end)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -16, 1, 0)
	lbl.Position = UDim2.new(0, 8, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = color or window.theme.White
	lbl.Font = Enum.Font.GothamSemibold
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Center
	lbl.ZIndex = 4
	lbl.Parent = btn
	btn.MouseButton1Click:Connect(callback)
	if tooltip then attachTooltip(btn, tooltip, window) end
	return btn
end

local function createSlider(group, items, window, text, minVal, maxVal, defaultVal, callback, step)
	step = step or 1
	local id = generateID()
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 42)
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.Parent = items
	local rowPad = Instance.new("UIPadding", row)
	rowPad.PaddingLeft = UDim.new(0, 6)
	rowPad.PaddingRight = UDim.new(0, 6)
	rowPad.PaddingTop = UDim.new(0, 2)
	rowPad.PaddingBottom = UDim.new(0, 2)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -80, 0, 16)
	label.Position = UDim2.new(0, 4, 0, 2)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = window.theme.GrayLt
	label.Font = Enum.Font.GothamSemibold
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 3
	label.Parent = row

	local valueBox = Instance.new("Frame")
	valueBox.AutomaticSize = Enum.AutomaticSize.X
	valueBox.Size = UDim2.new(0, 0, 0, 18)
	valueBox.AnchorPoint = Vector2.new(1, 0)
	valueBox.Position = UDim2.new(1, -2, 0, 2)
	valueBox.BackgroundColor3 = window.theme.Track
	valueBox.BorderSizePixel = 0
	valueBox.ZIndex = 3
	valueBox.Parent = row
	Instance.new("UICorner", valueBox).CornerRadius = UDim.new(0, 4)
	local valuePad = Instance.new("UIPadding", valueBox)
	valuePad.PaddingLeft = UDim.new(0, 6)
	valuePad.PaddingRight = UDim.new(0, 6)
	local valueStroke = Instance.new("UIStroke", valueBox)
	valueStroke.Color = window.theme.Border
	valueStroke.Thickness = 1
	local valueLabel = Instance.new("TextLabel")
	valueLabel.AutomaticSize = Enum.AutomaticSize.X
	valueLabel.Size = UDim2.new(0, 0, 1, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = tostring(defaultVal)
	valueLabel.TextColor3 = window.theme.Accent
	valueLabel.Font = Enum.Font.GothamSemibold
	valueLabel.TextSize = 13
	valueLabel.ZIndex = 4
	valueLabel.Parent = valueBox
	table.insert(window.accentObjects, valueLabel)
	local valueBoxInput = Instance.new("TextBox")
	valueBoxInput.AutomaticSize = Enum.AutomaticSize.X
	valueBoxInput.Size = UDim2.new(0, 0, 1, 0)
	valueBoxInput.BackgroundTransparency = 1
	valueBoxInput.Text = tostring(defaultVal)
	valueBoxInput.TextColor3 = window.theme.Accent
	valueBoxInput.Font = Enum.Font.GothamSemibold
	valueBoxInput.TextSize = 12
	valueBoxInput.Visible = false
	valueBoxInput.ZIndex = 5
	valueBoxInput.Parent = valueBox
	Instance.new("UICorner", valueBoxInput).CornerRadius = UDim.new(0, 4)
	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, 0, 0, 4)
	track.Position = UDim2.new(0, 0, 0, 28)
	track.BackgroundColor3 = window.theme.Track
	track.BorderSizePixel = 0
	track.ZIndex = 3
	track.Parent = row
	Instance.new("UICorner", track).CornerRadius = UDim.new(0, 3)
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
	knob.Size = UDim2.new(0, 12, 0, 12)
	knob.Position = UDim2.new((defaultVal - minVal) / (maxVal - minVal), -6, 0.5, -6)
	knob.BackgroundColor3 = window.theme.BG
	knob.BorderSizePixel = 0
	knob.ZIndex = 5
	knob.Parent = track
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
	local knobStroke = Instance.new("UIStroke", knob)
	knobStroke.Color = window.theme.Accent
	knobStroke.Thickness = 2
	table.insert(window.accentObjects, fill)
	table.insert(window.accentObjects, knobStroke)
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
		knob.Position = UDim2.new(rel, -6, 0.5, -6)
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
	local sliderInputConn = UIS.InputChanged:Connect(function(i) if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then apply(i.Position.X) end end)
	local sliderEndConn = UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end end)
	table.insert(window.connections, sliderInputConn)
	table.insert(window.connections, sliderEndConn)
	valueLabel.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then valueLabel.Visible = false valueBoxInput.Visible = true valueBoxInput:CaptureFocus() valueBoxInput.Text = tostring(currentVal) valueBoxInput.TextColor3 = window.theme.Accent end end)
	valueBoxInput.FocusLost:Connect(function(enter)
		valueBoxInput.Visible = false valueLabel.Visible = true
		local num = tonumber(valueBoxInput.Text)
		if num then updateSlider(num) else valueLabel.Text = tostring(currentVal) end
	end)
	local elem = {ID = id, Value = currentVal, DefaultValue = defaultVal, SetValue = updateSlider}
	elem.SetDesc = function(self_or_d, d) if type(self_or_d) == "string" then label.Text = self_or_d else label.Text = d end end
	window.configs[id] = elem
	row.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			window:showContextMenu(UIS:GetMouseLocation(), elem)
		end
	end)
	elem.frame = row
	return row, elem
end

local function createColorPicker(group, items, window, text, default, callback)
	local id = generateID()
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 32)
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.Parent = items
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -62, 1, 0)
	label.Position = UDim2.new(0, 4, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = window.theme.White
	label.Font = Enum.Font.GothamSemibold
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 3
	label.Parent = row
	local colorBox = Instance.new("TextButton")
	colorBox.Size = UDim2.new(0, 22, 0, 22)
	colorBox.Position = UDim2.new(1, -26, 0.5, -11)
	colorBox.BackgroundColor3 = default
	colorBox.BorderSizePixel = 0
	colorBox.ZIndex = 4
	colorBox.Text = ""
	colorBox.AutoButtonColor = false
	colorBox.Parent = row
	Instance.new("UICorner", colorBox).CornerRadius = UDim.new(0, 3)
	local stroke = Instance.new("UIStroke", colorBox)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = window.theme.Border
	stroke.Thickness = 1
	local current = default or Color3.new(1, 0, 0)
	local elem = {ID = id, Value = current, Alpha = 0}
	local currentMode = "Solid"
	local pickerFrame = nil

	elem.SetValue = function(val)
		current = val
		elem.Value = val
		colorBox.BackgroundColor3 = val
		if callback then callback(val) end
	end
	window.configs[id] = elem

	local function closePicker()
		if pickerFrame then pickerFrame:Destroy() pickerFrame = nil end
	end

	local function openPicker()
		if pickerFrame then closePicker() return end
		local pickerJustOpened = true
		task.delay(0.1, function() pickerJustOpened = false end)

		local pickerW, pickerH = 240, 260
		pickerFrame = Instance.new("CanvasGroup")
		pickerFrame.Size = UDim2.new(0, pickerW, 0, pickerH)
		pickerFrame.BackgroundColor3 = window.theme.Surface
		pickerFrame.BorderSizePixel = 0
		pickerFrame.ZIndex = 2000
		pickerFrame.Parent = window.sg
		table.insert(window.activePopups, pickerFrame)
		
		-- Background Blocker to prevent clicking through the picker
		local blocker = Instance.new("TextButton", pickerFrame)
		blocker.Size = UDim2.fromScale(1, 1)
		blocker.BackgroundTransparency = 1
		blocker.Text = ""
		blocker.ZIndex = 0
		blocker.Active = true
		
		local pickerScale = Instance.new("UIScale", pickerFrame)
		pickerScale.Scale = 0.9
		pickerFrame.GroupTransparency = 1
		
		Instance.new("UICorner", pickerFrame).CornerRadius = UDim.new(0, 10)
		local pickerStroke = Instance.new("UIStroke", pickerFrame)
		pickerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		pickerStroke.Color = window.theme.Border
		pickerStroke.Transparency = 0.2
		pickerStroke.Thickness = 1.5
		
		local screenW = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 1920
		local screenH = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 1080
		local absPos = colorBox.AbsolutePosition
		local absSize = colorBox.AbsoluteSize
		local targetX = absPos.X + absSize.X + 12
		if targetX + pickerW > screenW - 10 then targetX = absPos.X - pickerW - 12 end
		local targetY = math.clamp(absPos.Y - (pickerH/2) + (absSize.Y/2), 10, screenH - pickerH - 10)
		pickerFrame.Position = UDim2.new(0, targetX, 0, targetY)
		
		TweenService:Create(pickerFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { GroupTransparency = 0 }):Play()
		TweenService:Create(pickerScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

		local satValSquare, satValKnob, hueSlider, hueKnob, hexBox, alphaKnob, alphaValLbl
		local hueDragging, svDragging = false, false
		local h_, s_, v_ = Color3.toHSV(current)

		local function update()
			local h = hueKnob.Position.X.Scale
			local s = math.clamp(satValKnob.Position.X.Scale, 0, 1)
			local v = math.clamp(1 - satValKnob.Position.Y.Scale, 0, 1)
			current = Color3.fromHSV(h, s, v)
			elem.Value = current
			satValSquare.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			colorBox.BackgroundColor3 = current
			hexBox.Text = "#" .. current:ToHex()
			if alphaValLbl then alphaValLbl.Text = "Transparency: " .. math.floor((1 - elem.Alpha) * 100 + 0.5) .. "%" end
			if callback then callback(current) end
		end

		local function updateHue(pos)
			local rel = math.clamp((pos.X - hueSlider.AbsolutePosition.X) / hueSlider.AbsoluteSize.X, 0, 1)
			hueKnob.Position = UDim2.new(rel, -7, 0.5, -7)
			update()
		end

		local function updateSV(pos)
			local relX = math.clamp((pos.X - satValSquare.AbsolutePosition.X) / satValSquare.AbsoluteSize.X, 0, 1)
			local relY = math.clamp((pos.Y - satValSquare.AbsolutePosition.Y) / satValSquare.AbsoluteSize.Y, 0, 1)
			satValKnob.Position = UDim2.new(relX, -6, relY, -6)
			update()
		end

		local PAD = 10
		local headerHeight = 32
		local hueSliderHeight = 12
		local svSquareSize = pickerW - (PAD * 2)

		local pickerHeader = Instance.new("Frame")
		pickerHeader.Size = UDim2.new(1, 0, 0, headerHeight)
		pickerHeader.BackgroundTransparency = 1
		pickerHeader.Parent = pickerFrame
		local pickerTitle = Instance.new("TextLabel")
		pickerTitle.Size = UDim2.new(1, -PAD*2, 1, 0)
		pickerTitle.Position = UDim2.new(0, PAD, 0, 0)
		pickerTitle.BackgroundTransparency = 1
		pickerTitle.Text = text
		pickerTitle.TextColor3 = window.theme.White
		pickerTitle.Font = Enum.Font.GothamBold
		pickerTitle.TextSize = 12
		pickerTitle.TextXAlignment = Enum.TextXAlignment.Left
		pickerTitle.Parent = pickerHeader

		satValSquare = Instance.new("Frame")
		satValSquare.Size = UDim2.new(1, -PAD*2, 0, 120)
		satValSquare.Position = UDim2.new(0, PAD, 0, headerHeight)
		satValSquare.BackgroundColor3 = Color3.fromHSV(h_, 1, 1)
		satValSquare.BorderSizePixel = 0
		satValSquare.ZIndex = 2001
		satValSquare.Parent = pickerFrame
		Instance.new("UICorner", satValSquare).CornerRadius = UDim.new(0, 4)
		
		-- White Saturation Gradient (Left = White, Right = Transparent)
		local satGrad = Instance.new("Frame", satValSquare)
		satGrad.Size = UDim2.fromScale(1, 1)
		satGrad.BackgroundTransparency = 0
		satGrad.BorderSizePixel = 0
		satGrad.ZIndex = 2002
		local satUIGrad = Instance.new("UIGradient", satGrad)
		satUIGrad.Color = ColorSequence.new(Color3.new(1,1,1))
		satUIGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0), -- Opaque White (Full Saturation/White)
			NumberSequenceKeypoint.new(1, 1)  -- Transparent Hue
		})
		
		-- Black Value Gradient (Top = Transparent, Bottom = Black)
		local valGrad = Instance.new("Frame", satValSquare)
		valGrad.Size = UDim2.fromScale(1, 1)
		valGrad.BackgroundTransparency = 0
		valGrad.BorderSizePixel = 0
		valGrad.ZIndex = 2003
		local valUIGrad = Instance.new("UIGradient", valGrad)
		valUIGrad.Rotation = 90
		valUIGrad.Color = ColorSequence.new(Color3.new(0,0,0))
		valUIGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), -- Transparent Top
			NumberSequenceKeypoint.new(1, 0)  -- Opaque Black Bottom
		})

		satValKnob = Instance.new("Frame")
		satValKnob.Size = UDim2.new(0, 12, 0, 12)
		satValKnob.Position = UDim2.new(s_, -6, 1 - v_, -6)
		satValKnob.BackgroundColor3 = Color3.new(1,1,1)
		satValKnob.ZIndex = 2003
		satValKnob.Parent = satValSquare
		Instance.new("UICorner", satValKnob).CornerRadius = UDim.new(1, 0)
		Instance.new("UIStroke", satValKnob).Thickness = 1.5

		local slidersY = headerHeight + 120 + 8
		hueSlider = Instance.new("Frame")
		hueSlider.Size = UDim2.new(1, -PAD*2, 0, hueSliderHeight)
		hueSlider.Position = UDim2.new(0, PAD, 0, slidersY)
		hueSlider.BorderSizePixel = 0
		hueSlider.ZIndex = 2001
		hueSlider.Parent = pickerFrame
		Instance.new("UICorner", hueSlider).CornerRadius = UDim.new(0, 6)
		local hueGrad = Instance.new("UIGradient", hueSlider)
		hueGrad.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0,    Color3.new(1,0,0)),
			ColorSequenceKeypoint.new(0.17, Color3.new(1,1,0)),
			ColorSequenceKeypoint.new(0.33, Color3.new(0,1,0)),
			ColorSequenceKeypoint.new(0.50, Color3.new(0,1,1)),
			ColorSequenceKeypoint.new(0.67, Color3.new(0,0,1)),
			ColorSequenceKeypoint.new(0.83, Color3.new(1,0,1)),
			ColorSequenceKeypoint.new(1,    Color3.new(1,0,0)),
		}
		hueKnob = Instance.new("Frame")
		hueKnob.Size = UDim2.new(0, 14, 0, 14)
		hueKnob.Position = UDim2.new(h_, -7, 0.5, -7)
		hueKnob.BackgroundColor3 = Color3.new(1,1,1)
		hueKnob.ZIndex = 2002
		hueKnob.Parent = hueSlider
		Instance.new("UICorner", hueKnob).CornerRadius = UDim.new(1, 0)
		Instance.new("UIStroke", hueKnob).Thickness = 1.5

		local alphaHeaderY = slidersY + 12 + 8
		alphaValLbl = Instance.new("TextLabel")
		alphaValLbl.Size = UDim2.new(1, -PAD*2, 0, 14)
		alphaValLbl.Position = UDim2.new(0, PAD, 0, alphaHeaderY)
		alphaValLbl.BackgroundTransparency = 1
		alphaValLbl.Text = "Transparency: " .. math.floor((1 - elem.Alpha) * 100 + 0.5) .. "%"
		alphaValLbl.TextColor3 = window.theme.GrayLt
		alphaValLbl.Font = Enum.Font.GothamSemibold
		alphaValLbl.TextSize = 10
		alphaValLbl.TextXAlignment = Enum.TextXAlignment.Left
		alphaValLbl.ZIndex = 2001
		alphaValLbl.Parent = pickerFrame

		local alphaSliderY = alphaHeaderY + 14 + 3
		local alphaTrack = Instance.new("Frame")
		alphaTrack.Size = UDim2.new(1, -PAD*2, 0, 12)
		alphaTrack.Position = UDim2.new(0, PAD, 0, alphaSliderY)
		alphaTrack.BorderSizePixel = 0
		alphaTrack.BackgroundColor3 = Color3.fromRGB(45,45,45)
		alphaTrack.ZIndex = 2001
		alphaTrack.Parent = pickerFrame
		Instance.new("UICorner", alphaTrack).CornerRadius = UDim.new(0, 6)
		local alphaColorBar = Instance.new("Frame")
		alphaColorBar.Size = UDim2.new(1, 0, 1, 0)
		alphaColorBar.BackgroundTransparency = 0
		alphaColorBar.BorderSizePixel = 0
		alphaColorBar.ZIndex = 2001
		alphaColorBar.Parent = alphaTrack
		Instance.new("UICorner", alphaColorBar).CornerRadius = UDim.new(0, 6)
		local alphaGrad = Instance.new("UIGradient", alphaColorBar)
		alphaGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		})

		alphaKnob = Instance.new("Frame")
		alphaKnob.Size = UDim2.new(0, 14, 0, 14)
		alphaKnob.Position = UDim2.new(1 - elem.Alpha, -7, 0.5, -7)
		alphaKnob.BackgroundColor3 = Color3.new(1,1,1)
		alphaKnob.ZIndex = 2003
		alphaKnob.Parent = alphaTrack
		Instance.new("UICorner", alphaKnob).CornerRadius = UDim.new(1, 0)
		Instance.new("UIStroke", alphaKnob).Thickness = 1.5

		local function applyAlpha(posX)
			local rel = math.clamp((posX - alphaTrack.AbsolutePosition.X) / alphaTrack.AbsoluteSize.X, 0, 1)
			alphaKnob.Position = UDim2.new(rel, -7, 0.5, -7)
			elem.Alpha = 1 - rel
			alphaValLbl.Text = "Transparency: " .. math.floor(rel * 100 + 0.5) .. "%"
			if callback then callback(current) end
		end

		local hexY = alphaSliderY + 12 + 10
		hexBox = Instance.new("TextBox")
		hexBox.Size = UDim2.new(1, -PAD*2, 0, 26)
		hexBox.Position = UDim2.new(0, PAD, 0, hexY)
		hexBox.BackgroundColor3 = window.theme.Track
		hexBox.BorderSizePixel = 0
		hexBox.Text = "#" .. current:ToHex()
		hexBox.TextColor3 = window.theme.White
		hexBox.Font = Enum.Font.GothamSemibold
		hexBox.TextSize = 12
		hexBox.ClearTextOnFocus = false
		hexBox.ZIndex = 2001
		hexBox.Parent = pickerFrame
		Instance.new("UICorner", hexBox).CornerRadius = UDim.new(0, 4)
		local hbStroke = Instance.new("UIStroke", hexBox)
		hbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		hbStroke.Color = window.theme.Border hbStroke.Thickness = 1

		local alphaDragging = false
		alphaTrack.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then alphaDragging = true applyAlpha(i.Position.X) end
		end)
		hueSlider.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then hueDragging = true updateHue(input.Position) end end)
		satValSquare.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then svDragging = true updateSV(input.Position) end end)

		local inputChangedConn = UIS.InputChanged:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseMovement then
				if alphaDragging then applyAlpha(i.Position.X) end
				if hueDragging then updateHue(i.Position) end
				if svDragging then updateSV(i.Position) end
			end
		end)
		local inputEndedConn = UIS.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				alphaDragging, hueDragging, svDragging = false, false, false
			end
		end)
		table.insert(window.connections, inputChangedConn)
		table.insert(window.connections, inputEndedConn)

		hexBox.FocusLost:Connect(function()
			local ok, hexColor = pcall(Color3.fromHex, hexBox.Text:gsub("#", ""))
			if ok then
				current = hexColor
				local h, s, v = Color3.toHSV(current)
				hueKnob.Position = UDim2.new(h, -7, 0.5, -7)
				satValKnob.Position = UDim2.new(s, -6, 1 - v, -6)
				update()
			end
		end)

		local inputBeganConn
		inputBeganConn = UIS.InputBegan:Connect(function(input)
			if pickerJustOpened then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				local pos = UIS:GetMouseLocation()
				if not pickerFrame or not pickerFrame.Parent then inputBeganConn:Disconnect() return end
				local ap, as = pickerFrame.AbsolutePosition, pickerFrame.AbsoluteSize
				local bp, bs2 = colorBox.AbsolutePosition, colorBox.AbsoluteSize
				if pos.X >= bp.X and pos.X <= bp.X + bs2.X and pos.Y >= bp.Y and pos.Y <= bp.Y + bs2.Y then return end
				if pos.X < ap.X or pos.X > ap.X + as.X or pos.Y < ap.Y or pos.Y > ap.Y + as.Y then
					task.spawn(closePicker)
					inputBeganConn:Disconnect()
				end
			end
		end)
	end
	colorBox.MouseButton1Click:Connect(openPicker)
	return row, elem
end

local function createMultiDropdown(group, items, window, text, options, default, callback)
	local id = generateID()
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 56)
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
	label.Font = Enum.Font.GothamSemibold
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 11
	label.Parent = row
	local dbtn = Instance.new("TextButton")
	dbtn.Size = UDim2.new(1, 0, 0, 28)
	dbtn.Position = UDim2.new(0, 0, 0, 26)
	dbtn.BackgroundColor3 = window.theme.BG
	dbtn.BorderSizePixel = 0
	dbtn.AutoButtonColor = false
	dbtn.Text = ""
	dbtn.ZIndex = 11
	dbtn.Parent = row
	Instance.new("UICorner", dbtn).CornerRadius = UDim.new(0, 4)

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
	local arrow = Instance.new("ImageLabel")
	arrow.Size = UDim2.new(0, 10, 0, 10)
	arrow.AnchorPoint = Vector2.new(1, 0.5)
	arrow.Position = UDim2.new(1, -10, 0.5, 0)
	arrow.BackgroundTransparency = 1
	arrow.Image = "rbxassetid://6034818379"
	arrow.ImageColor3 = window.theme.Accent
	arrow.ScaleType = Enum.ScaleType.Fit
	arrow.ZIndex = 12
	arrow.Parent = dbtn
	table.insert(window.accentObjects, arrow)
	local listH = #options * 28 + 8
	local dlist = Instance.new("ScrollingFrame")
	dlist.Size = UDim2.new(1, 0, 0, math.min(listH, 160))
	dlist.Position = UDim2.new(0, 0, 0, 54)
	dlist.BackgroundColor3 = window.theme.Base
	dlist.BorderSizePixel = 0
	dlist.ScrollBarThickness = listH > 160 and 2 or 0
	dlist.ScrollBarImageColor3 = window.theme.Accent
	dlist.CanvasSize = UDim2.new(0, 0, 0, listH)
	dlist.Visible = false
	dlist.ZIndex = 50
	dlist.Parent = row
	local multiDlistStroke = Instance.new("UIStroke", dlist)
	multiDlistStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	multiDlistStroke.Color = window.theme.Border
	multiDlistStroke.Transparency = 0
	multiDlistStroke.Thickness = 1

	local multiBridge = Instance.new("Frame")
	multiBridge.Size = UDim2.new(1, 0, 0, 6)
	multiBridge.Position = UDim2.new(0, 0, 0, 48)
	multiBridge.BackgroundColor3 = window.theme.Base
	multiBridge.BorderSizePixel = 0
	multiBridge.ZIndex = 49
	multiBridge.Visible = false
	multiBridge.Parent = row
	local multiDbtnCorner = Instance.new("UICorner", dbtn)
	multiDbtnCorner.CornerRadius = UDim.new(0, 4)
	local multiDbtnStroke = Instance.new("UIStroke", dbtn)
	multiDbtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	multiDbtnStroke.Color = window.theme.Border
	multiDbtnStroke.Thickness = 1
	local dlayout = Instance.new("UIListLayout", dlist)
	dlayout.SortOrder = Enum.SortOrder.LayoutOrder
	dlayout.Padding = UDim.new(0, 0)
	local selected = default or {}
	local checks = {}
	local backgrounds = {}
	for _, opt in ipairs(options) do
		local isSel = selected[opt] and true or false
		local ob = Instance.new("TextButton")
		ob.Size = UDim2.new(1, 0, 0, 28)
		ob.BackgroundColor3 = isSel and Color3.fromRGB(20,34,26) or window.theme.Base
		ob.BackgroundTransparency = 0
		ob.AutoButtonColor = false
		ob.Text = ""
		ob.ZIndex = 51
		ob.Parent = dlist

		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(0, 2, 0, 14)
		bar.Position = UDim2.new(0, 0, 0.5, -7)
		bar.BackgroundColor3 = window.theme.Accent
		bar.BorderSizePixel = 0
		bar.Visible = isSel
		bar.ZIndex = 53
		bar.Parent = ob
		Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 1)
		backgrounds[opt] = bar
		table.insert(window.accentObjects, bar)
		local ol = Instance.new("TextLabel")
		ol.Size = UDim2.new(1, -12, 1, 0)
		ol.Position = UDim2.new(0, 10, 0, 0)
		ol.BackgroundTransparency = 1
		ol.Text = opt
		ol.TextColor3 = isSel and window.theme.White or window.theme.Gray
		ol.Font = isSel and Enum.Font.GothamBold or Enum.Font.GothamSemibold
		ol.TextSize = 12
		ol.TextXAlignment = Enum.TextXAlignment.Left
		ol.ZIndex = 52
		ol.Parent = ob
		checks[opt] = ol
		ob.MouseEnter:Connect(function()
			if not selected[opt] then
				TweenService:Create(ob, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(32,32,32)}):Play()
				ol.TextColor3 = window.theme.GrayLt
			end
		end)
		ob.MouseLeave:Connect(function()
			if not selected[opt] then
				TweenService:Create(ob, TweenInfo.new(0.08), {BackgroundColor3 = window.theme.Base}):Play()
				ol.TextColor3 = window.theme.Gray
			end
		end)
		ob.MouseButton1Click:Connect(function()
			if selected[opt] then
				selected[opt] = nil
				bar.Visible = false
				ol.TextColor3 = window.theme.Gray
				ol.Font = Enum.Font.GothamSemibold
				TweenService:Create(ob, TweenInfo.new(0.08), {BackgroundColor3 = window.theme.Base}):Play()
			else
				selected[opt] = true
				bar.Visible = true
				ol.TextColor3 = window.theme.White
				ol.Font = Enum.Font.GothamBold
				TweenService:Create(ob, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(20,34,26)}):Play()
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
		window.tooltipSuppressed = open
		if window.tooltip then window.tooltip.hide() end
		TweenService:Create(arrow, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
			Rotation = open and 180 or 0
		}):Play()
		if open then
			multiDbtnCorner.CornerRadius = UDim.new(0, 0)
			multiBridge.Visible = true
			dlist.Visible = true
			dlist.Size = UDim2.new(1, 0, 0, 0)
			TweenService:Create(dlist, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 0, math.min(listH, 160))
			}):Play()
		else
			window.tooltipSuppressed = false
			multiDbtnCorner.CornerRadius = UDim.new(0, 4)
			multiBridge.Visible = false
			local tw = TweenService:Create(dlist, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Size = UDim2.new(1, 0, 0, 0)
			})
			tw.Completed:Connect(function() dlist.Visible = false end)
			tw:Play()
		end
		row.Size = UDim2.new(1, 0, 0, 56 + (open and math.min(listH, 160) or 0))
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
	return row, elem
end

local function buildDropdownRefreshBtn(row, window, refreshCallback)
	if not refreshCallback then return nil end
	local refreshBtn = Instance.new("TextButton")
	refreshBtn.Size = UDim2.new(0, 52, 0, 18)
	refreshBtn.Position = UDim2.new(1, -54, 0, 2)
	refreshBtn.BackgroundColor3 = window.theme.Track
	refreshBtn.Text = "Refresh"
	refreshBtn.TextColor3 = window.theme.GrayLt
	refreshBtn.Font = Enum.Font.GothamSemibold
	refreshBtn.TextSize = 10
	refreshBtn.ZIndex = 12
	refreshBtn.Parent = row
	Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 4)
	local rStroke = Instance.new("UIStroke", refreshBtn)
	rStroke.Color = window.theme.Border
	rStroke.Thickness = 1
	refreshBtn.MouseEnter:Connect(function()
		refreshBtn.TextColor3 = window.theme.White
	end)
	refreshBtn.MouseLeave:Connect(function()
		refreshBtn.TextColor3 = window.theme.GrayLt
	end)
	return refreshBtn
end

function UILib.Column:addGroup(title)
	local window = self.window
	if not window then error("No window reference in column") end
	local tab = self.tab
	local subtab = self.sub
	local group = {}
	group.title = title
	group.window = window
	group.tab = tab
	group.sub = subtab
	group.columnFrame = self.frame

	local grp = Instance.new("Frame")
	grp.Size = UDim2.new(1, 0, 0, 36)
	grp.BackgroundColor3 = window.theme.Item
	grp.BorderSizePixel = 0
	grp.Parent = self.frame
	Instance.new("UICorner", grp).CornerRadius = UDim.new(0, 6)
	local stroke = Instance.new("UIStroke", grp)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = window.theme.Border
	stroke.Thickness = 1

	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 30)
	row.BackgroundTransparency = 1
	row.Parent = grp

	local iconImg = Instance.new("ImageLabel")
	iconImg.Size = UDim2.new(0, 16, 0, 16)
	iconImg.Position = UDim2.new(0, 8, 0.5, -8)
	iconImg.BackgroundTransparency = 1
	iconImg.Image = ""
	iconImg.ImageColor3 = window.theme.Accent
	iconImg.ScaleType = Enum.ScaleType.Fit
	iconImg.ZIndex = 2
	iconImg.Visible = false
	iconImg.Parent = row
	table.insert(window.accentObjects, iconImg)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -52, 1, 0)
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

	function group:setIcon(assetId)
		if assetId then
			local id = tostring(assetId)
			if not id:find("rbxassetid://") then id = "rbxassetid://" .. id end
			iconImg.Image = id
			iconImg.Visible = true
			label.Position = UDim2.new(0, 30, 0, 0)
			label.Size = UDim2.new(1, -54, 1, 0)
		else
			iconImg.Visible = false
			label.Position = UDim2.new(0, 10, 0, 0)
			label.Size = UDim2.new(1, -52, 1, 0)
		end
	end

	local function applyRowIcon(rowFrame, mainLabel, assetId, baseX)
		if not assetId then return end
		local id = tostring(assetId)
		if not id:find("rbxassetid://") then id = "rbxassetid://" .. id end
		local iImg = Instance.new("ImageLabel")
		iImg.Size = UDim2.new(0, 14, 0, 14)
		iImg.Position = UDim2.new(0, baseX or 4, 0.5, -7)
		iImg.BackgroundTransparency = 1
		iImg.Image = id
		iImg.ImageColor3 = window.theme.Accent
		iImg.ScaleType = Enum.ScaleType.Fit
		iImg.ZIndex = (mainLabel.ZIndex or 3)
		iImg.Parent = rowFrame
		table.insert(window.accentObjects, iImg)

		mainLabel.Position = UDim2.new(0, (baseX or 4) + 18, mainLabel.Position.Y.Scale, mainLabel.Position.Y.Offset)
		mainLabel.Size = UDim2.new(mainLabel.Size.X.Scale, mainLabel.Size.X.Offset - 18, mainLabel.Size.Y.Scale, mainLabel.Size.Y.Offset)
	end

	function group:paragraph(ptitle, text, tooltip)
		local r = Instance.new("Frame")
		r.Size = UDim2.new(1, 0, 0, 0)
		r.BackgroundTransparency = 1
		r.AutomaticSize = Enum.AutomaticSize.Y
		r.Parent = items
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -8, 0, 0)
		lbl.Position = UDim2.new(0, 4, 0, 2)
		lbl.BackgroundTransparency = 1
		lbl.Text = ptitle
		lbl.TextColor3 = window.theme.Accent
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 12
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.AutomaticSize = Enum.AutomaticSize.Y
		lbl.Parent = r
		local body = Instance.new("TextLabel")
		body.Size = UDim2.new(1, -8, 0, 0)
		body.Position = UDim2.new(0, 4, 0, 18)
		body.BackgroundTransparency = 1
		body.Text = text
		body.TextColor3 = window.theme.Gray
		body.Font = Enum.Font.GothamSemibold
		body.TextSize = 12
		body.TextXAlignment = Enum.TextXAlignment.Left
		body.TextWrapped = true
		body.AutomaticSize = Enum.AutomaticSize.Y
		body.Parent = r
		Instance.new("UIPadding", r).PaddingBottom = UDim.new(0, 6)
		if tooltip then attachTooltip(r, tooltip, window) end
		updateSize()
		local ref = {}
		function ref:setTitle(t) lbl.Text = t end
		function ref:setDesc(d) body.Text = d updateSize() end
		return ref
	end

	function group:toggle(text, default, callback, tooltip, icon)
		local id = generateID()
		local r = Instance.new("Frame")
		r.Size = UDim2.new(1, 0, 0, 36)
		r.BackgroundTransparency = 1
		r.BorderSizePixel = 0
		r.ZIndex = 3
		r.Parent = items
		local cbOuter = Instance.new("TextButton")
		cbOuter.Size = UDim2.new(0, 22, 0, 22)
		cbOuter.Position = UDim2.new(1, -26, 0.5, -11)
		cbOuter.BackgroundColor3 = default and window.theme.Accent or window.theme.BG
		cbOuter.BorderSizePixel = 0
		cbOuter.AutoButtonColor = false
		cbOuter.ZIndex = 4
		cbOuter.Text = ""
		cbOuter.Parent = r
		Instance.new("UICorner", cbOuter).CornerRadius = UDim.new(0, 4)
		local cbStroke = Instance.new("UIStroke", cbOuter)
		cbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		cbStroke.Color = default and window.theme.AccentD or window.theme.Border
		cbStroke.Thickness = 1
		local cbMark = Instance.new("TextLabel")
		cbMark.Size = UDim2.new(1, 0, 1, 0)
		cbMark.BackgroundTransparency = 1
		cbMark.Text = default and "X" or ""
		cbMark.TextColor3 = Color3.fromRGB(10,10,10)
		cbMark.Font = Enum.Font.GothamBold
		cbMark.TextSize = 14
		cbMark.ZIndex = 5
		cbMark.Parent = cbOuter
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -38, 1, 0)
		lbl.Position = UDim2.new(0, 4, 0, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = text
		lbl.TextColor3 = window.theme.White
		lbl.Font = Enum.Font.GothamSemibold
		lbl.TextSize = 13
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.ZIndex = 4
		lbl.Parent = r
		if icon then applyRowIcon(r, lbl, icon, 4) end
		local state = default
		local elem = {ID = id, Value = state, DefaultValue = default, IsToggle = true, Mode = "toggle"}
		elem.SetValue = function(val)
			state = val
			elem.Value = state
			TweenService:Create(cbOuter, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
				BackgroundColor3 = state and window.theme.Accent or window.theme.BG
			}):Play()
			cbStroke.Color = state and window.theme.AccentD or window.theme.Border
			cbMark.Text = state and "X" or ""
			if callback then callback(state) end
			if window.configs[id] then window.configs[id].Value = state end
		end
		window.configs[id] = elem
		cbOuter.MouseButton1Click:Connect(function()
			if elem.Mode == "always" then return end
			state = not state
			elem.SetValue(state)
		end)
		local function openCtx() window:showContextMenu(UIS:GetMouseLocation(), elem) end
		r.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton2 then openCtx() end
		end)
		cbOuter.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton2 then openCtx() end
		end)
		if tooltip then attachTooltip(r, tooltip, window) end
		updateSize()
		elem.frame = r
		elem.SetDesc = function(self_or_d, d) if type(self_or_d) == "string" then lbl.Text = self_or_d else lbl.Text = d end end
		return elem
	end

	function group:slider(text, minVal, maxVal, defaultVal, callback, step, tooltip, icon)
		local r, elem = createSlider(group, items, window, text, minVal, maxVal, defaultVal, callback, step)
		if tooltip then attachTooltip(r, tooltip, window) end
		if icon then
			local iLabel = r:FindFirstChildOfClass("TextLabel")
			if iLabel then applyRowIcon(r, iLabel, icon, 4) end
		end
		updateSize()
		return elem
	end

	function group:dropdown(text, options, default, callback, tooltip, refreshCallback, icon)
		local id = generateID()
		local r = Instance.new("Frame")
		r.Size = UDim2.new(1, 0, 0, 56)
		r.BackgroundTransparency = 1
		r.ClipsDescendants = false
		r.ZIndex = 10
		r.Parent = items

		local lbl = Instance.new("TextLabel")
		local lblWidth = refreshCallback and UDim2.new(1, -64, 0, 18) or UDim2.new(1, -10, 0, 18)
		lbl.Size = lblWidth
		lbl.Position = UDim2.new(0, 4, 0, 2)
		lbl.BackgroundTransparency = 1
		lbl.Text = text
		lbl.TextColor3 = window.theme.GrayLt
		lbl.Font = Enum.Font.GothamSemibold
		lbl.TextSize = 12
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.ZIndex = 11
		lbl.Parent = r

		if icon then applyRowIcon(r, lbl, icon, 4) end
		local refreshBtn = buildDropdownRefreshBtn(r, window, refreshCallback)

		local dbtn = Instance.new("TextButton")
		dbtn.Size = UDim2.new(1, 0, 0, 32)
		dbtn.Position = UDim2.new(0, 0, 0, 22)
		dbtn.BackgroundColor3 = window.theme.Track
		dbtn.BorderSizePixel = 0
		dbtn.AutoButtonColor = false
		dbtn.Text = ""
		dbtn.ZIndex = 11
		dbtn.Parent = r
		local dbtnCorner = Instance.new("UICorner", dbtn)
		dbtnCorner.CornerRadius = UDim.new(0, 4)
		local dbtnStroke = Instance.new("UIStroke", dbtn)
		dbtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		dbtnStroke.Color = window.theme.Border
		dbtnStroke.Thickness = 1
		local selLbl = Instance.new("TextLabel")
		selLbl.Size = UDim2.new(1, -34, 1, 0)
		selLbl.Position = UDim2.new(0, 10, 0, 0)
		selLbl.BackgroundTransparency = 1
		selLbl.Text = default or ""
		selLbl.TextColor3 = window.theme.White
		selLbl.Font = Enum.Font.GothamBold
		selLbl.TextSize = 12
		selLbl.TextXAlignment = Enum.TextXAlignment.Left
		selLbl.ZIndex = 12
		selLbl.Parent = dbtn

		local arrow = Instance.new("ImageLabel")
		arrow.Size = UDim2.new(0, 10, 0, 10)
		arrow.AnchorPoint = Vector2.new(1, 0.5)
		arrow.Position = UDim2.new(1, -10, 0.5, 0)
		arrow.BackgroundTransparency = 1
		arrow.Image = "rbxassetid://6034818379"
		arrow.ImageColor3 = window.theme.Accent
		arrow.ScaleType = Enum.ScaleType.Fit
		arrow.ZIndex = 12
		arrow.Name = "arrow"
		table.insert(window.accentObjects, arrow)
		arrow.Parent = dbtn

		local itemH = 28
		local listH = #options * itemH + 8

		local expandPanel = Instance.new("Frame")
		expandPanel.Size = UDim2.new(1, 0, 0, 0)
		expandPanel.Position = UDim2.new(0, 0, 0, 52)
		expandPanel.BackgroundColor3 = window.theme.Track
		expandPanel.BorderSizePixel = 0
		expandPanel.ClipsDescendants = true
		expandPanel.ZIndex = 50
		expandPanel.Visible = false
		expandPanel.Parent = r
		local expandCorner = Instance.new("UICorner", expandPanel)
		expandCorner.CornerRadius = UDim.new(0, 4)

		local expandStroke = Instance.new("UIStroke", expandPanel)
		expandStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		expandStroke.Color = window.theme.Border
		expandStroke.Thickness = 1

		local SEARCH_H = 32
		local searchRow = Instance.new("Frame")
		searchRow.Size = UDim2.new(1, 0, 0, SEARCH_H)
		searchRow.Position = UDim2.new(0, 0, 0, 0)
		searchRow.BackgroundTransparency = 1
		searchRow.BorderSizePixel = 0
		searchRow.ZIndex = 52
		searchRow.Visible = false
		searchRow.Parent = expandPanel
		local searchBox = Instance.new("TextBox")
		searchBox.Size = UDim2.new(1, -16, 0, 22)
		searchBox.Position = UDim2.new(0, 8, 0.5, -11)
		searchBox.BackgroundColor3 = window.theme.Surface
		searchBox.BorderSizePixel = 0
		searchBox.PlaceholderText = "Search..."
		searchBox.PlaceholderColor3 = window.theme.Gray
		searchBox.Text = ""
		searchBox.TextColor3 = window.theme.White
		searchBox.Font = Enum.Font.GothamSemibold
		searchBox.TextSize = 12
		searchBox.ClearTextOnFocus = false
		searchBox.ZIndex = 53
		searchBox.Parent = searchRow
		Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 4)
		local searchStroke = Instance.new("UIStroke", searchBox)
		searchStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		searchStroke.Color = window.theme.Border
		searchStroke.Thickness = 1

		local searchSep = Instance.new("Frame")
		searchSep.Size = UDim2.new(1, 0, 0, 1)
		searchSep.BackgroundColor3 = window.theme.Border
		searchSep.BorderSizePixel = 0
		searchSep.ZIndex = 52
		searchSep.Visible = false
		searchSep.Parent = expandPanel

		local dlist = Instance.new("ScrollingFrame")
		dlist.Size = UDim2.new(1, 0, 0, 0)
		dlist.Position = UDim2.new(0, 0, 0, 0)
		dlist.BackgroundTransparency = 1
		dlist.BorderSizePixel = 0
		dlist.ScrollBarThickness = listH > 160 and 2 or 0
		dlist.ScrollBarImageColor3 = window.theme.Accent
		dlist.CanvasSize = UDim2.new(0, 0, 0, listH)
		dlist.ZIndex = 51
		dlist.Parent = expandPanel
		local dlayout = Instance.new("UIListLayout", dlist)
		dlayout.SortOrder = Enum.SortOrder.LayoutOrder
		dlayout.Padding = UDim.new(0, 0)

		local checks = {}
		local backgrounds = {}
		local currentOptions = options
		local currentSelection = default or ""
		local open = false

		local function getListMaxH() return math.min(listH, 160) end

		local function applyFilter(query)
			query = query:lower()
			local filteredCount = 0
			for _, child in ipairs(dlist:GetChildren()) do
				if child:IsA("TextButton") then
					local lbl2 = child:FindFirstChildOfClass("TextLabel")
					if lbl2 then
						local match = query == "" or lbl2.Text:lower():find(query, 1, true)
						child.Visible = match ~= nil and match ~= false
						if child.Visible then filteredCount = filteredCount + 1 end
					end
				end
			end
			local visH = filteredCount * 28 + 4
			dlist.CanvasSize = UDim2.new(0, 0, 0, visH)
			local clampedListH = math.min(visH, 132)
			local showSearch = #currentOptions >= 5
			local searchExtra = showSearch and SEARCH_H or 0
			local totalPanelH = searchExtra + clampedListH
			if open then
				dlist.Size = UDim2.new(1, 0, 0, clampedListH)
				expandPanel.Size = UDim2.new(1, 0, 0, totalPanelH)
				r.Size = UDim2.new(1, 0, 0, 56 + totalPanelH)
				updateSize()
			end
		end
		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			applyFilter(searchBox.Text)
		end)

		local function closeDropdown()
			open = false
			window.tooltipSuppressed = false
			TweenService:Create(arrow, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Rotation = 0}):Play()

			dbtnCorner.CornerRadius = UDim.new(0, 4)
			dbtnStroke.Color = window.theme.Border
			expandCorner.CornerRadius = UDim.new(0, 4)
			searchRow.Visible = false
			searchSep.Visible = false
			searchBox.Text = ""
			for _, child in ipairs(dlist:GetChildren()) do
				if child:IsA("TextButton") then child.Visible = true end
			end
			local tw = TweenService:Create(expandPanel, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Size = UDim2.new(1, 0, 0, 0)
			})
			tw.Completed:Connect(function() expandPanel.Visible = false end)
			tw:Play()
			r.Size = UDim2.new(1, 0, 0, 56)
			updateSize()
		end

		local function buildOptions(opts)
			for _, child in ipairs(dlist:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
			checks = {}
			backgrounds = {}
			currentOptions = opts
			searchBox.Text = ""
			listH = #opts * 28 + 4
			dlist.CanvasSize = UDim2.new(0, 0, 0, listH)
			dlist.ScrollBarThickness = listH > 160 and 2 or 0
			for _, opt in ipairs(opts) do
				local isSelected = (opt == currentSelection)
				local ob = Instance.new("TextButton")
				ob.Size = UDim2.new(1, 0, 0, 28)
				ob.BackgroundColor3 = isSelected and Color3.fromRGB(20,34,26) or Color3.fromRGB(0,0,0,0)
				ob.BackgroundTransparency = isSelected and 0 or 1
				ob.AutoButtonColor = false
				ob.Text = ""
				ob.ZIndex = 51
				ob.Parent = dlist
				local bar = Instance.new("Frame")
				bar.Size = UDim2.new(0, 2, 0, 14)
				bar.Position = UDim2.new(0, 0, 0.5, -7)
				bar.BackgroundColor3 = window.theme.Accent
				bar.BorderSizePixel = 0
				bar.Visible = isSelected
				bar.ZIndex = 53
				bar.Parent = ob
				Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 1)
				backgrounds[opt] = bar
				table.insert(window.accentObjects, bar)
				local ol = Instance.new("TextLabel")
				ol.Size = UDim2.new(1, -12, 1, 0)
				ol.Position = UDim2.new(0, 12, 0, 0)
				ol.BackgroundTransparency = 1
				ol.Text = opt
				ol.TextColor3 = isSelected and window.theme.White or window.theme.Gray
				ol.Font = isSelected and Enum.Font.GothamBold or Enum.Font.GothamSemibold
				ol.TextSize = 12
				ol.TextXAlignment = Enum.TextXAlignment.Left
				ol.ZIndex = 52
				ol.Parent = ob
				checks[opt] = ol
				ob.MouseEnter:Connect(function()
					if opt ~= currentSelection then
						TweenService:Create(ob, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(32,32,32), BackgroundTransparency = 0}):Play()
						ol.TextColor3 = window.theme.GrayLt
					end
				end)
				ob.MouseLeave:Connect(function()
					if opt ~= currentSelection then
						TweenService:Create(ob, TweenInfo.new(0.08), {BackgroundColor3 = window.theme.Track, BackgroundTransparency = 1}):Play()
						ol.TextColor3 = window.theme.Gray
					end
				end)
				ob.MouseButton1Click:Connect(function()
					currentSelection = opt
					selLbl.Text = opt
					for o, lbl2 in pairs(checks) do
						local sel = (o == opt)
						lbl2.TextColor3 = sel and window.theme.White or window.theme.Gray
						lbl2.Font = sel and Enum.Font.GothamBold or Enum.Font.GothamSemibold
					end
					for o, b in pairs(backgrounds) do b.Visible = (o == opt) end
					for _, child in ipairs(dlist:GetChildren()) do
						if child:IsA("TextButton") then
							local isSel = child:FindFirstChildOfClass("TextLabel") and
								child:FindFirstChildOfClass("TextLabel").Text == opt
							if isSel then
								child.BackgroundColor3 = Color3.fromRGB(20,34,26)
								child.BackgroundTransparency = 0
							else
								child.BackgroundTransparency = 1
							end
						end
					end
					if callback then callback(opt) end
					window.configs[id].Value = opt
					closeDropdown()
				end)
			end
		end
		buildOptions(options)

		local function refresh()
			if refreshCallback then
				local newOpts = refreshCallback()
				if newOpts then
					buildOptions(newOpts)
					local exists = false
					for _, o in ipairs(newOpts) do if o == currentSelection then exists = true break end end
					if not exists then
						currentSelection = newOpts[1] or ""
						selLbl.Text = currentSelection
						if callback then callback(currentSelection) end
					end
				end
			end
		end
		if refreshBtn then refreshBtn.MouseButton1Click:Connect(refresh) end

		dbtn.MouseButton1Click:Connect(function()
			open = not open
			window.tooltipSuppressed = open
			if window.tooltip then window.tooltip.hide() end
			TweenService:Create(arrow, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
				Rotation = open and 180 or 0
			}):Play()
			if open then
				local showSearch = #currentOptions >= 5
				local extraH = showSearch and SEARCH_H or 0
				local clampedListH = getListMaxH()
				local totalPanelH = extraH + clampedListH

				dbtnCorner.CornerRadius = UDim.new(0, 4)
				dbtnStroke.Color = window.theme.Border
				expandCorner.CornerRadius = UDim.new(0, 0)

				if showSearch then
					searchRow.Visible = true
					searchSep.Visible = true
					searchSep.Position = UDim2.new(0, 0, 0, SEARCH_H)
					dlist.Position = UDim2.new(0, 0, 0, SEARCH_H + 1)
					dlist.Size = UDim2.new(1, 0, 0, clampedListH)
					task.defer(function() searchBox:CaptureFocus() end)
				else
					searchRow.Visible = false
					searchSep.Visible = false
					dlist.Position = UDim2.new(0, 0, 0, 0)
					dlist.Size = UDim2.new(1, 0, 0, clampedListH)
				end

				expandPanel.Size = UDim2.new(1, 0, 0, 0)
				expandPanel.Visible = true
				TweenService:Create(expandPanel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.new(1, 0, 0, totalPanelH)
				}):Play()
				r.Size = UDim2.new(1, 0, 0, 56 + totalPanelH)
				if showSearch then
					task.defer(function() searchBox:CaptureFocus() end)
				end
			else
				closeDropdown()
			end
			updateSize()
		end)

		local elem = {
			ID = id, Value = currentSelection, DefaultValue = default, Refresh = refresh,
			SetValue = function(val)
				currentSelection = val
				selLbl.Text = val
				for o, lbl2 in pairs(checks) do
					local sel = (o == val)
					lbl2.TextColor3 = sel and window.theme.White or window.theme.Gray
					lbl2.Font = sel and Enum.Font.GothamBold or Enum.Font.GothamSemibold
				end
				for o, b in pairs(backgrounds) do b.Visible = (o == val) end
				if callback then callback(val) end
			end,
			SetValues = function(self, newOpts)
				closeDropdown()
				buildOptions(newOpts)
				local exists = false
				for _, o in ipairs(newOpts) do if o == currentSelection then exists = true break end end
				if not exists then
					currentSelection = newOpts[1] or ""
					selLbl.Text = currentSelection
				end
			end
		}
		window.configs[id] = elem
		r.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton2 then window:showContextMenu(UIS:GetMouseLocation(), elem) end
		end)

		if tooltip then
			local tt = window.tooltip
			if tt then
				dbtn.MouseEnter:Connect(function() if not open then tt.start(tooltip, dbtn) end end)
				dbtn.MouseLeave:Connect(function() tt.hide() end)
				dbtn.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then tt.hide() end end)
			end
		end
		updateSize()
		elem.frame = r
		elem.SetDesc = function(self_or_d, d) if type(self_or_d) == "string" then lbl.Text = self_or_d else lbl.Text = d end end
		return elem
	end

	function group:keybind(text, currentName, onChange, tooltip)
		local id = generateID()
		local r = Instance.new("Frame")
		r.Size = UDim2.new(1, 0, 0, 34)
		r.BackgroundTransparency = 1
		r.BorderSizePixel = 0
		r.Parent = items
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -82, 1, 0)
		lbl.Position = UDim2.new(0, 4, 0, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = text
		lbl.TextColor3 = window.theme.White
		lbl.Font = Enum.Font.GothamSemibold
		lbl.TextSize = 13
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.ZIndex = 3
		lbl.Parent = r

		local kbtn = Instance.new("TextButton")
		kbtn.AutomaticSize = Enum.AutomaticSize.X
		kbtn.Size = UDim2.new(0, 0, 0, 22)
		kbtn.AnchorPoint = Vector2.new(1, 0.5)
		kbtn.Position = UDim2.new(1, -4, 0.5, 0)
		kbtn.BackgroundColor3 = window.theme.BG
		kbtn.BackgroundTransparency = 0
		kbtn.BorderSizePixel = 0
		kbtn.Text = currentName
		kbtn.TextColor3 = window.theme.GrayLt
		kbtn.Font = Enum.Font.GothamSemibold
		kbtn.TextSize = 12
		kbtn.TextXAlignment = Enum.TextXAlignment.Center
		kbtn.TextYAlignment = Enum.TextYAlignment.Center
		kbtn.AutoButtonColor = false
		kbtn.ZIndex = 4
		kbtn.Parent = r
		Instance.new("UICorner", kbtn).CornerRadius = UDim.new(0, 4)
		local kbtnPad = Instance.new("UIPadding", kbtn)
		kbtnPad.PaddingLeft = UDim.new(0, 8)
		kbtnPad.PaddingRight = UDim.new(0, 8)
		local kstroke = Instance.new("UIStroke", kbtn)
		kstroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		kstroke.Color = window.theme.Border
		kstroke.Thickness = 1
		table.insert(window.keybindButtons, kbtn)
		local listening = false
		local skipNext = false
		kbtn.MouseButton1Click:Connect(function()
			if listening then return end
			listening = true
			skipNext = true
			kbtn.Text = "..."
			kbtn.TextColor3 = window.theme.White
			kbtn.BackgroundTransparency = 0
			local con
			con = UIS.InputBegan:Connect(function(i)
				if skipNext and i.UserInputType == Enum.UserInputType.MouseButton1 then skipNext = false return end
				listening = false
				con:Disconnect()
				kbtn.BackgroundColor3 = window.theme.BG
				kbtn.BackgroundTransparency = 0
				kbtn.TextColor3 = window.theme.GrayLt
				kstroke.Color = window.theme.Border
				if i.KeyCode == Enum.KeyCode.Escape then kbtn.Text = currentName kbtn.TextColor3 = window.theme.GrayLt return end
				local u = i.UserInputType
				if u == Enum.UserInputType.Keyboard then
					kbtn.Text = i.KeyCode.Name
					kbtn.TextColor3 = window.theme.GrayLt
					onChange(i.KeyCode, i.KeyCode.Name)
					window.configs[id].Value = i.KeyCode.Name
				elseif u == Enum.UserInputType.MouseButton2 then
					kbtn.Text = "RMB" kbtn.TextColor3 = window.theme.GrayLt
					onChange(Enum.UserInputType.MouseButton2, "RMB") window.configs[id].Value = "RMB"
				elseif u == Enum.UserInputType.MouseButton1 then
					kbtn.Text = "LMB" kbtn.TextColor3 = window.theme.GrayLt
					onChange(Enum.UserInputType.MouseButton1, "LMB") window.configs[id].Value = "LMB"
				elseif u == Enum.UserInputType.MouseButton3 then
					kbtn.Text = "MMB" kbtn.TextColor3 = window.theme.GrayLt
					onChange(Enum.UserInputType.MouseButton3, "MMB") window.configs[id].Value = "MMB"
				else kbtn.Text = currentName kbtn.TextColor3 = window.theme.GrayLt end
			end)
		end)
		local elem = {ID = id, Value = currentName, SetValue = function(val) kbtn.Text = val end}
		window.configs[id] = elem
		if tooltip then attachTooltip(r, tooltip, window) end
		updateSize()
		elem.frame = r
		elem.SetDesc = function(self_or_d, d) if type(self_or_d) == "string" then lbl.Text = self_or_d else lbl.Text = d end end
		return elem
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
		lbl.Font = Enum.Font.GothamSemibold
		lbl.TextSize = 11
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.ZIndex = 3
		lbl.Parent = f
		if tooltip then attachTooltip(f, tooltip, window) end
		updateSize()
		local ref = {frame = f}
		function ref:setText(t) lbl.Text = t end
		function ref:setColor(c) lbl.TextColor3 = c end
		return ref
	end

	function group:separator(text)
		local f = Instance.new("Frame")
		f.Size = UDim2.new(1, 0, 0, text and 18 or 10)
		f.BackgroundTransparency = 1
		f.Parent = items
		if text and text ~= "" then
			local line1 = Instance.new("Frame")
			line1.Size = UDim2.new(0.28, 0, 0, 1)
			line1.Position = UDim2.new(0, 0, 0.5, 0)
			line1.BackgroundColor3 = window.theme.Border
			line1.BorderSizePixel = 0
			line1.ZIndex = 3
			line1.Parent = f
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(0.44, 0, 1, 0)
			lbl.Position = UDim2.new(0.28, 0, 0, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text = text:upper()
			lbl.TextColor3 = window.theme.Gray
			lbl.Font = Enum.Font.GothamBold
			lbl.TextSize = 9
			lbl.ZIndex = 3
			lbl.Parent = f
			local line2 = Instance.new("Frame")
			line2.Size = UDim2.new(0.28, 0, 0, 1)
			line2.Position = UDim2.new(0.72, 0, 0.5, 0)
			line2.BackgroundColor3 = window.theme.Border
			line2.BorderSizePixel = 0
			line2.ZIndex = 3
			line2.Parent = f
			updateSize()
		else
			local line = Instance.new("Frame")
			line.Size = UDim2.new(1, 0, 0, 1)
			line.Position = UDim2.new(0, 0, 0.5, 0)
			line.BackgroundColor3 = window.theme.Border
			line.BorderSizePixel = 0
			line.ZIndex = 3
			line.Parent = f
			updateSize()
		end
		return f
	end

	function group:button(text, callback, tooltip, align, color, style, bgColor, icon)
		style = style or "bg"
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 32)
		btn.BorderSizePixel = 0
		btn.Text = ""
		btn.ZIndex = 3
		btn.Parent = items

		if style == "split" then
			btn.BackgroundColor3 = window.theme.Item
			btn.BackgroundTransparency = 0
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
			local bstroke = Instance.new("UIStroke", btn)
			bstroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			bstroke.Color = window.theme.Border
			bstroke.Thickness = 1
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
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, 0, 1, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text = text
			lbl.TextColor3 = color or window.theme.Accent
			lbl.Font = Enum.Font.GothamBold
			lbl.TextSize = 13
			lbl.TextXAlignment = align or Enum.TextXAlignment.Center
			lbl.ZIndex = 4
			lbl.Parent = btn
		elseif style == "text" then
			btn.BackgroundTransparency = 1
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, 0, 1, 0)
			lbl.Position = UDim2.new(0, 4, 0, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text = text
			lbl.TextColor3 = color or window.theme.Accent
			lbl.Font = Enum.Font.GothamSemibold
			lbl.TextSize = 13
			lbl.TextXAlignment = align or Enum.TextXAlignment.Left
			lbl.ZIndex = 4
			lbl.Parent = btn
			btn.MouseEnter:Connect(function() lbl.TextColor3 = window.theme.White end)
			btn.MouseLeave:Connect(function() lbl.TextColor3 = color or window.theme.Accent end)
		else
			local btnBg = bgColor or window.theme.Track
			btn.BackgroundColor3 = btnBg
			btn.BackgroundTransparency = 0
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
			local bstroke = Instance.new("UIStroke", btn)
			bstroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			bstroke.Color = bgColor and Color3.new(bgColor.r*0.7, bgColor.g*0.7, bgColor.b*0.7) or window.theme.Border
			bstroke.Thickness = 1
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, 0, 1, 0)
			lbl.Position = UDim2.new(0, 4, 0, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text = text
			lbl.TextColor3 = color or window.theme.White
			lbl.Font = Enum.Font.GothamSemibold
			lbl.TextSize = 13
			lbl.TextXAlignment = align or Enum.TextXAlignment.Left
			lbl.ZIndex = 4
			lbl.Parent = btn
			if icon then applyRowIcon(btn, lbl, icon, 4) end
		end

		btn.MouseButton1Click:Connect(callback)
		if tooltip then attachTooltip(btn, tooltip, window) end
		updateSize()
		return btn
	end

	function group:progress(text, value, maxVal, color, tooltip)
		local r = Instance.new("Frame")
		r.Size = UDim2.new(1, 0, 0, 42)
		r.BackgroundTransparency = 1
		r.Parent = items
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(0.6, 0, 0, 16)
		lbl.Position = UDim2.new(0, 4, 0, 3)
		lbl.BackgroundTransparency = 1
		lbl.Text = text
		lbl.TextColor3 = window.theme.GrayLt
		lbl.Font = Enum.Font.GothamSemibold
		lbl.TextSize = 12
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.ZIndex = 3
		lbl.Parent = r
		local valLbl = Instance.new("TextLabel")
		valLbl.Size = UDim2.new(0.4, -8, 0, 16)
		valLbl.Position = UDim2.new(0.6, 0, 0, 3)
		valLbl.BackgroundTransparency = 1
		valLbl.Text = tostring(value) .. " / " .. tostring(maxVal)
		valLbl.TextColor3 = color or window.theme.Accent
		valLbl.Font = Enum.Font.GothamSemibold
		valLbl.TextSize = 11
		valLbl.TextXAlignment = Enum.TextXAlignment.Right
		valLbl.ZIndex = 3
		valLbl.Parent = r
		local track = Instance.new("Frame")
		track.Size = UDim2.new(1, -8, 0, 5)
		track.Position = UDim2.new(0, 4, 0, 24)
		track.BackgroundColor3 = window.theme.Track
		track.BorderSizePixel = 0
		track.ZIndex = 3
		track.Parent = r
		Instance.new("UICorner", track).CornerRadius = UDim.new(0, 3)
		local fill = Instance.new("Frame")
		fill.Size = UDim2.new(math.clamp(value / maxVal, 0, 1), 0, 1, 0)
		fill.BackgroundColor3 = color or window.theme.Accent
		fill.BorderSizePixel = 0
		fill.ZIndex = 4
		fill.Parent = track
		Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 3)
		table.insert(window.accentObjects, fill)
		local ref = {}
		function ref:set(newVal, newMax)
			newMax = newMax or maxVal
			maxVal = newMax
			value = newVal
			valLbl.Text = tostring(newVal) .. " / " .. tostring(newMax)
			TweenService:Create(fill, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
				Size = UDim2.new(math.clamp(newVal / newMax, 0, 1), 0, 1, 0)
			}):Play()
		end
		if tooltip then attachTooltip(r, tooltip, window) end
		updateSize()
		return ref
	end

	function group:image(url, height, tooltip)
		height = height or 80
		local r = Instance.new("Frame")
		r.Size = UDim2.new(1, 0, 0, height + 8)
		r.BackgroundTransparency = 1
		r.Parent = items
		local img = Instance.new("ImageLabel")
		img.Size = UDim2.new(1, -8, 0, height)
		img.Position = UDim2.new(0, 4, 0, 4)
		img.BackgroundColor3 = window.theme.Track
		img.BorderSizePixel = 0
		img.Image = url or ""
		img.ScaleType = Enum.ScaleType.Fit
		img.ZIndex = 3
		img.Parent = r
		Instance.new("UICorner", img).CornerRadius = UDim.new(0, 4)
		local ref = {}
		function ref:setImage(newUrl) img.Image = newUrl end
		function ref:setHeight(h)
			r.Size = UDim2.new(1, 0, 0, h + 8)
			img.Size = UDim2.new(1, -8, 0, h)
			updateSize()
		end
		if tooltip then attachTooltip(r, tooltip, window) end
		updateSize()
		return ref
	end

	function group:badge(text, color, tooltip, position)
		position = position or "below"
		local r = Instance.new("Frame")
		r.BackgroundTransparency = 1
		r.Parent = items

		if position == "inline" then
			r.Size = UDim2.new(1, 0, 0, 24)
			local pill = Instance.new("Frame")
			pill.AutomaticSize = Enum.AutomaticSize.X
			pill.Size = UDim2.new(0, 0, 0, 18)
			pill.Position = UDim2.new(0, 4, 0.5, -9)
			pill.BackgroundColor3 = color or window.theme.Accent
			pill.BackgroundTransparency = 0.75
			pill.BorderSizePixel = 0
			pill.ZIndex = 3
			pill.Parent = r
			Instance.new("UICorner", pill).CornerRadius = UDim.new(0, 4)
			local pillStroke = Instance.new("UIStroke", pill)
			pillStroke.Color = color or window.theme.Accent
			pillStroke.Transparency = 0.4
			pillStroke.Thickness = 1
			local pillPad = Instance.new("UIPadding", pill)
			pillPad.PaddingLeft = UDim.new(0, 6)
			pillPad.PaddingRight = UDim.new(0, 6)
			local lbl = Instance.new("TextLabel")
			lbl.AutomaticSize = Enum.AutomaticSize.X
			lbl.Size = UDim2.new(0, 0, 1, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text = text:upper()
			lbl.TextColor3 = color or window.theme.Accent
			lbl.Font = Enum.Font.GothamBold
			lbl.TextSize = 9
			lbl.ZIndex = 4
			lbl.Parent = pill
			local ref = {}
			function ref:set(newText, newColor)
				lbl.Text = newText:upper()
				if newColor then pill.BackgroundColor3 = newColor pillStroke.Color = newColor lbl.TextColor3 = newColor end
			end
			if tooltip then attachTooltip(r, tooltip, window) end
			updateSize()
			return ref
		else
			r.Size = UDim2.new(1, 0, 0, 28)
			local pill = Instance.new("Frame")
			pill.AutomaticSize = Enum.AutomaticSize.X
			pill.Size = UDim2.new(0, 0, 0, 20)
			pill.Position = UDim2.new(0, 4, 0.5, -10)
			pill.BackgroundColor3 = color or window.theme.Accent
			pill.BackgroundTransparency = 0.75
			pill.BorderSizePixel = 0
			pill.ZIndex = 3
			pill.Parent = r
			Instance.new("UICorner", pill).CornerRadius = UDim.new(0, 4)
			local pillStroke = Instance.new("UIStroke", pill)
			pillStroke.Color = color or window.theme.Accent
			pillStroke.Transparency = 0.4
			pillStroke.Thickness = 1
			local pillPad = Instance.new("UIPadding", pill)
			pillPad.PaddingLeft = UDim.new(0, 8)
			pillPad.PaddingRight = UDim.new(0, 8)
			local lbl = Instance.new("TextLabel")
			lbl.AutomaticSize = Enum.AutomaticSize.X
			lbl.Size = UDim2.new(0, 0, 1, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text = text:upper()
			lbl.TextColor3 = color or window.theme.Accent
			lbl.Font = Enum.Font.GothamBold
			lbl.TextSize = 10
			lbl.ZIndex = 4
			lbl.Parent = pill
			local ref = {}
			function ref:set(newText, newColor)
				lbl.Text = newText:upper()
				if newColor then pill.BackgroundColor3 = newColor pillStroke.Color = newColor lbl.TextColor3 = newColor end
			end
			if tooltip then attachTooltip(r, tooltip, window) end
			updateSize()
			return ref
		end
	end

	local function buildNestedGroup(contentFrame, updateContentSize)
		local ng = {}
		local function reparent(r, useFrame)
			local target = useFrame or contentFrame
			;(r.frame or r).Parent = target
			updateContentSize()
			return r
		end
		function ng:toggle(t,d,cb,tt2)       return reparent(group:toggle(t,d,cb,tt2)) end
		function ng:slider(t,mn,mx,d,cb,s,tt2) return reparent(group:slider(t,mn,mx,d,cb,s,tt2)) end
		function ng:dropdown(t,o,d,cb,tt2)   return reparent(group:dropdown(t,o,d,cb,tt2)) end
		function ng:keybind(t,cur,cb,tt2)    return reparent(group:keybind(t,cur,cb,tt2)) end
		function ng:label(t,col,tt2)         return reparent(group:label(t,col,tt2)) end
		function ng:separator(t)             return reparent(group:separator(t)) end
		function ng:button(t,cb,tt2,al,col,sty) return reparent(group:button(t,cb,tt2,al,col,sty)) end
		function ng:colorpicker(t,d,cb,tt2)  return reparent(group:colorpicker(t,d,cb,tt2)) end
		function ng:multidropdown(t,o,d,cb,tt2) return reparent(group:multidropdown(t,o,d,cb,tt2)) end
		function ng:textbox(t,d,ph,cb,tt2)   return reparent(group:textbox(t,d,ph or "",cb,tt2)) end
		function ng:numberbox(t,d,mn,mx,cb,tt2) return reparent(group:numberbox(t,d,mn,mx,cb,tt2)) end
		function ng:rangeslider(t,mn,mx,dMn,dMx,cb,tt2) return reparent(group:rangeslider(t,mn,mx,dMn,dMx,cb,tt2)) end
		function ng:badge(t,col,tt2,pos)     return reparent(group:badge(t,col,tt2,pos)) end
		function ng:paragraph(tit,txt,tt2)   group:paragraph(tit,txt,tt2); updateContentSize() end
		function ng:progress(t,v,mx,col,tt2) return reparent(group:progress(t,v,mx,col,tt2)) end
		function ng:image(url,h,tt2)         return reparent(group:image(url,h,tt2)) end
		function ng:split()
			local splitRow = Instance.new("Frame")
			splitRow.Size = UDim2.new(1,0,0,0)
			splitRow.BackgroundTransparency = 1
			splitRow.AutomaticSize = Enum.AutomaticSize.Y
			splitRow.Parent = contentFrame
			local lFrame = Instance.new("Frame")
			lFrame.Size = UDim2.new(0.5,-4,0,0)
			lFrame.BackgroundTransparency = 1
			lFrame.AutomaticSize = Enum.AutomaticSize.Y
			lFrame.Parent = splitRow
			Instance.new("UIListLayout", lFrame).Padding = UDim.new(0,2)
			local rFrame = Instance.new("Frame")
			rFrame.Size = UDim2.new(0.5,-4,0,0)
			rFrame.Position = UDim2.new(0.5,4,0,0)
			rFrame.BackgroundTransparency = 1
			rFrame.AutomaticSize = Enum.AutomaticSize.Y
			rFrame.Parent = splitRow
			Instance.new("UIListLayout", rFrame).Padding = UDim.new(0,2)
			local function updateSplit()
				local lh = lFrame.UIListLayout.AbsoluteContentSize.Y
				local rh = rFrame.UIListLayout.AbsoluteContentSize.Y
				splitRow.Size = UDim2.new(1,0,0,math.max(lh,rh))
				updateContentSize()
			end
			lFrame.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSplit)
			rFrame.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSplit)
			local function wrapSide(frame)
				local g = {window=window, items=frame, updateSize=updateSplit}
				for k,v in pairs(ng) do
					if type(v)=="function" and k~="split" then
						local fn=v
						g[k]=function(self2,...) return fn(self2,...) end
					end
				end
				return g
			end
			return wrapSide(lFrame), wrapSide(rFrame)
		end
		return ng
	end

	function group:expandableToggle(text, default, contentFunc, tooltip)
		local container = Instance.new("Frame")
		container.Size = UDim2.new(1,0,0,34)
		container.BackgroundTransparency = 1
		container.ClipsDescendants = true
		container.Parent = items

		local toggleRow = Instance.new("Frame")
		toggleRow.Size = UDim2.new(1,0,0,34)
		toggleRow.BackgroundTransparency = 1
		toggleRow.ZIndex = 3
		toggleRow.Parent = container

		local cbOuter = Instance.new("TextButton")
		cbOuter.Size = UDim2.new(0,18,0,18)
		cbOuter.Position = UDim2.new(1,-22,0.5,-9)
		cbOuter.BackgroundColor3 = default and window.theme.Accent or window.theme.BG
		cbOuter.BorderSizePixel = 0
		cbOuter.AutoButtonColor = false
		cbOuter.ZIndex = 4
		cbOuter.Text = ""
		cbOuter.Parent = toggleRow
		Instance.new("UICorner", cbOuter).CornerRadius = UDim.new(0,4)
		local cbStroke = Instance.new("UIStroke", cbOuter)
		cbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		cbStroke.Color = default and window.theme.AccentD or window.theme.Border
		cbStroke.Thickness = 1
		local cbMark = Instance.new("TextLabel")
		cbMark.Size = UDim2.new(1,0,1,0)
		cbMark.BackgroundTransparency = 1
		cbMark.Text = default and "X" or ""
		cbMark.TextColor3 = Color3.fromRGB(10,10,10)
		cbMark.Font = Enum.Font.GothamBold
		cbMark.TextSize = 14
		cbMark.ZIndex = 5
		cbMark.Parent = cbOuter

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1,-32,1,0)
		lbl.Position = UDim2.new(0,4,0,0)
		lbl.BackgroundTransparency = 1
		lbl.Text = text
		lbl.TextColor3 = window.theme.White
		lbl.Font = Enum.Font.GothamSemibold
		lbl.TextSize = 13
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.ZIndex = 4
		lbl.Parent = toggleRow

		local contentFrame = Instance.new("Frame")
		contentFrame.Size = UDim2.new(1,0,0,0)
		contentFrame.Position = UDim2.new(0,0,0,34)
		contentFrame.BackgroundTransparency = 1
		contentFrame.Parent = container
		local contentLayout = Instance.new("UIListLayout", contentFrame)
		contentLayout.Padding = UDim.new(0,2)
		contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
		local state = default
		local function updateContentSize()
			local h = contentLayout.AbsoluteContentSize.Y
			contentFrame.Size = UDim2.new(1,0,0,h)
			container.Size = UDim2.new(1,0,0, 34 + (state and h or 0))
			updateSize()
		end
		contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateContentSize)
		local nestedGroup = buildNestedGroup(contentFrame, updateContentSize)
		if contentFunc then contentFunc(nestedGroup) end
		cbOuter.MouseButton1Click:Connect(function()
			state = not state
			TweenService:Create(cbOuter, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
				BackgroundColor3 = state and window.theme.Accent or window.theme.BG
			}):Play()
			cbStroke.Color = state and window.theme.AccentD or window.theme.Border
			cbMark.Text = state and "X" or ""
			local targetH = 34 + (state and contentLayout.AbsoluteContentSize.Y or 0)
			TweenService:Create(container, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(1,0,0,targetH)
			}):Play()
			task.delay(0.2, updateSize)
		end)
		if tooltip then attachTooltip(toggleRow, tooltip, window) end
		updateContentSize()
		return container
	end

	function group:collapsible(text, default, contentFunc, tooltip)
		local container = Instance.new("Frame")
		container.Size = UDim2.new(1,0,0,34)
		container.BackgroundTransparency = 1
		container.ClipsDescendants = true
		container.Parent = items

		local toggleRow = Instance.new("TextButton")
		toggleRow.Size = UDim2.new(1,0,0,34)
		toggleRow.BackgroundTransparency = 1
		toggleRow.Text = ""
		toggleRow.ZIndex = 3
		toggleRow.Parent = container

		local arrow = Instance.new("TextLabel")
		arrow.Size = UDim2.new(0,20,1,0)
		arrow.Position = UDim2.new(1,-22,0,0)
		arrow.BackgroundTransparency = 1
		arrow.Text = default and "▼" or "▶"
		arrow.TextColor3 = window.theme.Accent
		arrow.Font = Enum.Font.GothamBold
		arrow.TextSize = 14
		arrow.ZIndex = 4
		arrow.Parent = toggleRow

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1,-28,1,0)
		lbl.Position = UDim2.new(0,4,0,0)
		lbl.BackgroundTransparency = 1
		lbl.Text = text
		lbl.TextColor3 = window.theme.White
		lbl.Font = Enum.Font.GothamSemibold
		lbl.TextSize = 13
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.ZIndex = 4
		lbl.Parent = toggleRow

		local contentFrame = Instance.new("Frame")
		contentFrame.Size = UDim2.new(1,0,0,0)
		contentFrame.Position = UDim2.new(0,0,0,34)
		contentFrame.BackgroundTransparency = 1
		contentFrame.Parent = container
		local contentLayout = Instance.new("UIListLayout", contentFrame)
		contentLayout.Padding = UDim.new(0,2)
		contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
		local state = default
		local function updateContentSize()
			local h = contentLayout.AbsoluteContentSize.Y
			contentFrame.Size = UDim2.new(1,0,0,h)
			container.Size = UDim2.new(1,0,0, 34 + (state and h or 0))
			updateSize()
		end
		contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateContentSize)
		local nestedGroup = buildNestedGroup(contentFrame, updateContentSize)
		if contentFunc then contentFunc(nestedGroup) end
		toggleRow.MouseButton1Click:Connect(function()
			state = not state
			arrow.Text = state and "▼" or "▶"
			container.Size = UDim2.new(1,0,0, 34 + (state and contentLayout.AbsoluteContentSize.Y or 0))
			updateSize()
		end)
		if tooltip then attachTooltip(toggleRow, tooltip, window) end
		updateContentSize()
		return container
	end

	function group:colorpicker(text, default, callback, tooltip, icon)
		local r, elem = createColorPicker(group, items, window, text, default, callback)
		if tooltip then attachTooltip(r, tooltip, window) end
		if icon then
			local iLabel = r:FindFirstChildOfClass("TextLabel")
			if iLabel then applyRowIcon(r, iLabel, icon, 4) end
		end
		updateSize()
		return elem
	end

	function group:multidropdown(text, options, default, callback, tooltip)
		local r, elem = createMultiDropdown(group, items, window, text, options, default, callback)
		if tooltip then attachTooltip(r, tooltip, window) end
		updateSize()
		return elem
	end

	function group:textbox(text, default, placeholder, callback, tooltip)
		local id = generateID()
		local r = Instance.new("Frame")
		r.Size = UDim2.new(1, 0, 0, 46)
		r.BackgroundTransparency = 1
		r.BorderSizePixel = 0
		r.Parent = items
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -48, 0, 18)
		lbl.Position = UDim2.new(0, 4, 0, 3)
		lbl.BackgroundTransparency = 1
		lbl.Text = text
		lbl.TextColor3 = window.theme.GrayLt
		lbl.Font = Enum.Font.GothamSemibold
		lbl.TextSize = 12
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.ZIndex = 3
		lbl.Parent = r
		local box = Instance.new("TextBox")
		box.Size = UDim2.new(1, -8, 0, 22)
		box.Position = UDim2.new(0, 4, 1, -26)
		box.BackgroundColor3 = window.theme.Track
		box.ClipsDescendants = true
		box.BorderSizePixel = 0
		box.ZIndex = 3
		box.Parent = r
		box.Text = default or ""
		box.TextColor3 = window.theme.Accent
		box.Font = Enum.Font.GothamSemibold
		box.TextSize = 13
		box.ClearTextOnFocus = false
		box.PlaceholderText = placeholder or ""
		box.PlaceholderColor3 = window.theme.Gray
		Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
		local tbStroke = Instance.new("UIStroke", box)
		tbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		tbStroke.Color = window.theme.Border
		tbStroke.Thickness = 1
		table.insert(window.accentObjects, box)
		local current = default or ""
		box.FocusLost:Connect(function(enter) if enter then current = box.Text if callback then callback(current) end window.configs[id].Value = current end end)
		local elem = {ID = id, Value = current, DefaultValue = default or "", SetValue = function(val) current = val box.Text = val if callback then callback(val) end window.configs[id].Value = val end}
		window.configs[id] = elem
		r.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton2 then window:showContextMenu(UIS:GetMouseLocation(), elem) end
		end)
		if tooltip then attachTooltip(r, tooltip, window) end
		updateSize()
		elem.frame = r
		elem.SetDesc = function(self_or_d, d) if type(self_or_d) == "string" then lbl.Text = self_or_d else lbl.Text = d end end
		return elem
	end

	function group:numberbox(text, default, min, max, callback, tooltip)
		min = min or -math.huge
		max = max or math.huge
		local id = generateID()
		local r = Instance.new("Frame")
		r.Size = UDim2.new(1, 0, 0, 46)
		r.BackgroundTransparency = 1
		r.BorderSizePixel = 0
		r.Parent = items
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(0.45, -8, 0, 18)
		lbl.Position = UDim2.new(0, 4, 0, 3)
		lbl.BackgroundTransparency = 1
		lbl.Text = text
		lbl.TextColor3 = window.theme.GrayLt
		lbl.Font = Enum.Font.GothamSemibold
		lbl.TextSize = 12
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.ZIndex = 3
		lbl.Parent = r
		local box = Instance.new("TextBox")
		box.Size = UDim2.new(0.55, 0, 0, 22)
		box.Position = UDim2.new(0.45, 0, 0, 2)
		box.BackgroundColor3 = window.theme.Track
		box.ClipsDescendants = true
		box.BorderSizePixel = 0
		box.ZIndex = 3
		box.Parent = r
		box.Text = tostring(default or 0)
		box.TextColor3 = window.theme.Accent
		box.Font = Enum.Font.GothamSemibold
		box.TextSize = 13
		box.ClearTextOnFocus = false
		Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
		local nbStroke = Instance.new("UIStroke", box)
		nbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		nbStroke.Color = window.theme.Border
		nbStroke.Thickness = 1
		local current = default or 0
		local function validate()
			local num = tonumber(box.Text)
			if num then num = math.clamp(num, min, max) current = num box.Text = tostring(num) if callback then callback(num) end window.configs[id].Value = num else box.Text = tostring(current) end
		end
		box.FocusLost:Connect(function(enter) if enter then validate() end end)
		local elem = {ID = id, Value = current, DefaultValue = default or 0, SetValue = function(val) val = math.clamp(val, min, max) current = val box.Text = tostring(val) if callback then callback(val) end window.configs[id].Value = val end}
		window.configs[id] = elem
		r.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton2 then window:showContextMenu(UIS:GetMouseLocation(), elem) end
		end)
		if tooltip then attachTooltip(r, tooltip, window) end
		updateSize()
		elem.frame = r
		elem.SetDesc = function(self_or_d, d) if type(self_or_d) == "string" then lbl.Text = self_or_d else lbl.Text = d end end
		return elem
	end

	function group:rangeslider(text, minVal, maxVal, defaultMin, defaultMax, callback, tooltip)
		local id = generateID()
		local r = Instance.new("Frame")
		r.Size = UDim2.new(1, 0, 0, 46)
		r.BackgroundTransparency = 1
		r.BorderSizePixel = 0
		r.Parent = items
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -48, 0, 18)
		lbl.Position = UDim2.new(0, 4, 0, 3)
		lbl.BackgroundTransparency = 1
		lbl.Text = text
		lbl.TextColor3 = window.theme.GrayLt
		lbl.Font = Enum.Font.GothamSemibold
		lbl.TextSize = 12
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.ZIndex = 3
		lbl.Parent = r
		local valueBox = Instance.new("Frame")
		valueBox.Size = UDim2.new(0, 80, 0, 20)
		valueBox.Position = UDim2.new(1, -84, 0, 2)
		valueBox.BackgroundColor3 = window.theme.Track
		valueBox.BorderSizePixel = 0
		valueBox.ZIndex = 3
		valueBox.Parent = r
		Instance.new("UICorner", valueBox).CornerRadius = UDim.new(0, 4)
		local rsVbStroke = Instance.new("UIStroke", valueBox)
		rsVbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		rsVbStroke.Color = window.theme.Border
		rsVbStroke.Thickness = 1
		local valueLabel = Instance.new("TextLabel")
		valueLabel.Size = UDim2.new(1, 0, 1, 0)
		valueLabel.BackgroundTransparency = 1
		valueLabel.Text = tostring(defaultMin) .. " - " .. tostring(defaultMax)
		valueLabel.TextColor3 = window.theme.Accent
		valueLabel.Font = Enum.Font.GothamSemibold
		valueLabel.TextSize = 11
		valueLabel.ZIndex = 4
		valueLabel.Parent = valueBox
		table.insert(window.accentObjects, valueLabel)
		local track = Instance.new("Frame")
		track.Size = UDim2.new(1, 0, 0, 4)
		track.Position = UDim2.new(0, 0, 0, 28)
		track.BackgroundColor3 = window.theme.Track
		track.BorderSizePixel = 0
		track.ZIndex = 3
		track.Parent = r
		Instance.new("UICorner", track).CornerRadius = UDim.new(0, 2)
		local pctMin = (defaultMin - minVal) / (maxVal - minVal)
		local pctMax = (defaultMax - minVal) / (maxVal - minVal)
		local fill = Instance.new("Frame")
		fill.Size = UDim2.new(pctMax - pctMin, 0, 1, 0)
		fill.Position = UDim2.new(pctMin, 0, 0, 0)
		fill.BackgroundColor3 = window.theme.Accent
		fill.BorderSizePixel = 0
		fill.ZIndex = 4
		fill.Parent = track
		Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 2)
		local knobLeft = Instance.new("Frame")
		knobLeft.Size = UDim2.new(0, 12, 0, 12)
		knobLeft.Position = UDim2.new(pctMin, -6, 0.5, -6)
		knobLeft.BackgroundColor3 = window.theme.BG
		knobLeft.BorderSizePixel = 0
		knobLeft.ZIndex = 5
		knobLeft.Parent = track
		Instance.new("UICorner", knobLeft).CornerRadius = UDim.new(1, 0)
		local knobLeftStroke = Instance.new("UIStroke", knobLeft)
		knobLeftStroke.Color = window.theme.Accent
		knobLeftStroke.Thickness = 2
		table.insert(window.accentObjects, knobLeftStroke)
		local knobRight = Instance.new("Frame")
		knobRight.Size = UDim2.new(0, 12, 0, 12)
		knobRight.Position = UDim2.new(pctMax, -6, 0.5, -6)
		knobRight.BackgroundColor3 = window.theme.BG
		knobRight.BorderSizePixel = 0
		knobRight.ZIndex = 5
		knobRight.Parent = track
		Instance.new("UICorner", knobRight).CornerRadius = UDim.new(1, 0)
		local knobRightStroke = Instance.new("UIStroke", knobRight)
		knobRightStroke.Color = window.theme.Accent
		knobRightStroke.Thickness = 2
		table.insert(window.accentObjects, knobRightStroke)
		local hitLeft = Instance.new("TextButton")
		hitLeft.Size = UDim2.new(0, 16, 0, 22)
		hitLeft.Position = UDim2.new(pctMin, -8, 0.5, -11)
		hitLeft.BackgroundTransparency = 1
		hitLeft.Text = ""
		hitLeft.ZIndex = 6
		hitLeft.Parent = track
		local hitRight = Instance.new("TextButton")
		hitRight.Size = UDim2.new(0, 16, 0, 22)
		hitRight.Position = UDim2.new(pctMax, -8, 0.5, -11)
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
			knobLeft.Position = UDim2.new(pctMin, -6, 0.5, -6)
			knobRight.Position = UDim2.new(pctMax, -6, 0.5, -6)
			hitLeft.Position = UDim2.new(pctMin, -10, 0.5, -11)
			hitRight.Position = UDim2.new(pctMax, -10, 0.5, -11)
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
		local rsInputConn = UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then apply(i.Position.X, dragType) end end)
		local rsEndConn = UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
		table.insert(window.connections, rsInputConn)
		table.insert(window.connections, rsEndConn)
		local elem = {ID = id, Value = {currentMin, currentMax}, DefaultValue = {defaultMin, defaultMax}, SetValue = function(t) currentMin, currentMax = t[1], t[2]; updateDisplay() if callback then callback(currentMin, currentMax) end window.configs[id].Value = {currentMin, currentMax} end}
		window.configs[id] = elem
		r.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton2 then window:showContextMenu(UIS:GetMouseLocation(), elem) end
		end)
		if tooltip then attachTooltip(r, tooltip, window) end
		updateSize()
		elem.frame = r
		elem.SetDesc = function(self_or_d, d) if type(self_or_d) == "string" then lbl.Text = self_or_d else lbl.Text = d end end
		return elem
	end

	function group:split()
		local splitRow = Instance.new("Frame")
		splitRow.Size = UDim2.new(1, 0, 0, 0)
		splitRow.BackgroundTransparency = 1
		splitRow.AutomaticSize = Enum.AutomaticSize.Y
		splitRow.Parent = items
		local lFrame = Instance.new("Frame")
		lFrame.Size = UDim2.new(0.5, -4, 0, 0)
		lFrame.BackgroundTransparency = 1
		lFrame.AutomaticSize = Enum.AutomaticSize.Y
		lFrame.Parent = splitRow
		Instance.new("UIListLayout", lFrame).Padding = UDim.new(0, 2)
		local rFrame = Instance.new("Frame")
		rFrame.Size = UDim2.new(0.5, -4, 0, 0)
		rFrame.Position = UDim2.new(0.5, 4, 0, 0)
		rFrame.BackgroundTransparency = 1
		rFrame.AutomaticSize = Enum.AutomaticSize.Y
		rFrame.Parent = splitRow
		Instance.new("UIListLayout", rFrame).Padding = UDim.new(0, 2)
		local function updateSplitSize()
			local lh = lFrame.UIListLayout.AbsoluteContentSize.Y
			local rh = rFrame.UIListLayout.AbsoluteContentSize.Y
			splitRow.Size = UDim2.new(1, 0, 0, math.max(lh, rh))
			updateSize()
		end
		lFrame.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSplitSize)
		rFrame.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSplitSize)
		local leftGroup = {window = window, frame = lFrame, items = lFrame, tab = group.tab, sub = group.sub, updateSize = updateSplitSize}
		local rightGroup = {window = window, frame = rFrame, items = rFrame, tab = group.tab, sub = group.sub, updateSize = updateSplitSize}
		for k, v in pairs(group) do
			if type(v) == "function" and k ~= "split" and k ~= "addGroup" then
				leftGroup[k] = function(self_, ...) return v(leftGroup, ...) end
				rightGroup[k] = function(self_, ...) return v(rightGroup, ...) end
			end
		end
		return leftGroup, rightGroup
	end

	return group
end

function UILib.SubTab:addGroup(title)

	local window = self.window
	if not window then error("SubTab has no window reference") end
	local col = Instance.new("Frame")
	col.Size = UDim2.new(1, 0, 0, 0)
	col.BackgroundTransparency = 1
	col.AutomaticSize = Enum.AutomaticSize.Y
	col.Parent = self.page
	Instance.new("UIListLayout", col).Padding = UDim.new(0, 8)
	local colObj = setmetatable({frame = col, window = window, tab = self.tab, sub = self}, UILib.Column)
	return colObj:addGroup(title)
end

return UILib
