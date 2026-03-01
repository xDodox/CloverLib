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
	Accent = Color3.fromRGB(0,255,163),
	AccentD = Color3.fromRGB(0,191,122),
	White = Color3.new(1,1,1),
	Gray = Color3.fromRGB(160,160,160),
	GrayLt = Color3.fromRGB(200,200,200),
	Border = Color3.fromRGB(50,50,50),
	Track = Color3.fromRGB(60,60,60)
}

local NOTIF_COLORS = {
	info = Color3.fromRGB(50, 150, 255),
	success = Color3.fromRGB(0, 255, 163),
	error = Color3.fromRGB(255, 70, 70),
	warning = Color3.fromRGB(255, 180, 50),
}

local contextMenuFrame = nil
local contextMenuConnections = {}

local tooltipFrame = nil
local tooltipText = nil
local tooltipTimer = nil

local function showTooltip(text, element)
	if not tooltipFrame or not element then return end
	tooltipText.Text = text
	local screenWidth = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 1920
	local screenHeight = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 1080
	local padding = 10
	local textWidth = 160
	local textSize = game:GetService("TextService"):GetTextSize(text, 12, Enum.Font.Roboto, Vector2.new(textWidth, 500))
	local height = textSize.Y + padding * 2
	tooltipFrame.Size = UDim2.new(0, textWidth + padding * 2, 0, height)
	local absPos = element.AbsolutePosition
	local absSize = element.AbsoluteSize
	local targetX = absPos.X + (absSize.X / 2) - (tooltipFrame.AbsoluteSize.X / 2)
	local targetY = absPos.Y + absSize.Y + 6
	if targetY + tooltipFrame.AbsoluteSize.Y > screenHeight - 10 then
		targetY = absPos.Y - tooltipFrame.AbsoluteSize.Y - 6
	end
	targetX = math.clamp(targetX, 10, screenWidth - tooltipFrame.AbsoluteSize.X - 10)
	targetY = math.clamp(targetY, 10, screenHeight - tooltipFrame.AbsoluteSize.Y - 10)
	tooltipFrame.Position = UDim2.new(0, targetX, 0, targetY)
	tooltipFrame.Visible = true
end

local function hideTooltip()
	if tooltipTimer then
		task.cancel(tooltipTimer)
		tooltipTimer = nil
	end
	if tooltipFrame then
		tooltipFrame.Visible = false
	end
end

local function startTooltipDelay(text, element)
	hideTooltip()
	tooltipTimer = task.delay(0.5, function()
		showTooltip(text, element)
	end)
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
	label.Font = Enum.Font.Roboto
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

function UILib:_configDir()
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
	local path = self:_configDir() .. name .. ".json"
	local success, err = pcall(writefile, path, json)
	if success then self:notify("Saved: " .. name, "success")
	else self:notify("Save failed: " .. tostring(err), "error") end
end

function UILib:loadConfig(name)
	local path = self:_configDir() .. name .. ".json"
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
	local path = self:_configDir() .. name .. ".json"
	local success = pcall(delfile, path)
	if success then self:notify("Deleted: " .. name, "success")
	else self:notify("Delete failed", "error") end
end

function UILib:listConfigs()
	local dir = self:_configDir()
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
		self.theme.AccentD = Color3.new(color.r*0.75, color.g*0.75, color.b*0.75)
		for _, obj in ipairs(self.accentObjects) do
			pcall(function()
				if obj:IsA("Frame") or obj:IsA("ScrollingFrame") then
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
	end

	self.sg = Instance.new("ScreenGui")
	self.sg.Name = "Clover_" .. HS:GenerateGUID(false)
	self.sg.ResetOnSpawn = false
	self.sg.IgnoreGuiInset = true
	self.sg.Parent = self.parent
	self.sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	tooltipFrame = Instance.new("Frame")
	tooltipFrame.BackgroundColor3 = self.theme.Panel
	tooltipFrame.BorderSizePixel = 0
	tooltipFrame.Visible = false
	tooltipFrame.ZIndex = 1000
	tooltipFrame.Parent = self.sg
	Instance.new("UICorner", tooltipFrame).CornerRadius = UDim.new(0, 4)
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
	tooltipText.ZIndex = 1001
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

	local function getSidebarWidth()
		return math.max(MIN_SIDEBAR_WIDTH, math.min(MAX_SIDEBAR_WIDTH, math.floor(self.size.X * 0.22)))
	end

	local function getKeybindWidth()
		return math.max(MIN_KEYBIND_WIDTH, math.min(MAX_KEYBIND_WIDTH, math.floor(self.size.X * 0.13)))
	end

	local function updateResponsiveLayout()
		local sw = getSidebarWidth()
		if self.sidebar then
			self.sidebar.Size = UDim2.new(0, sw, 1, -92)
			for _, sub in ipairs(self.allSubTabs) do
				if sub.btn then
					sub.btn.Size = UDim2.new(1, -8, 0, 24)
				end
			end
		end
		if self.sidebarEdge then
			self.sidebarEdge.Position = UDim2.new(0, sw, 0, 46)
			self.sidebarEdge.Size = UDim2.new(0, 1, 1, -92)
		end
		if self.content then
			self.content.Size = UDim2.new(0, self.size.X - sw - 1, 1, -92)
			self.content.Position = UDim2.new(0, sw + 1, 0, 46)
		end
		local kw = getKeybindWidth()
		for _, kbtn in ipairs(self.keybindButtons) do
			pcall(function()
				kbtn.Size = UDim2.new(0, kw, 0, 22)
				kbtn.Position = UDim2.new(1, -(kw + 2), 0.5, -11)
			end)
		end
	end
	self.updateResponsiveLayout = updateResponsiveLayout

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
			updateResponsiveLayout()
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
	table.insert(self.accentObjects, headerLine)

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
		versionLabel.TextColor3 = Color3.fromRGB(20, 20, 20)
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
	hintLabel.Font = Enum.Font.RobotoMono
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
	Instance.new("UIPadding", sidebar).PaddingTop = UDim.new(0, 4)

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
	self.content = content

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
	local navbarStroke = Instance.new("UIStroke", navbar)
	navbarStroke.Color = self.theme.Border
	navbarStroke.Thickness = 1
	self.navbar = navbar
	local navList = Instance.new("UIListLayout", navbar)
	navList.FillDirection = Enum.FillDirection.Horizontal
	navList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	navList.VerticalAlignment = Enum.VerticalAlignment.Center
	navList.Padding = UDim.new(0, 0)

	self._navTabCount = 0
	self._navScrollEnabled = false

	local function updateNavScroll()
		self._navTabCount = self._navTabCount + 1
		if self._navTabCount >= 6 and not self._navScrollEnabled then
			self._navScrollEnabled = true
			navbar.ClipsDescendants = true
			for _, child in ipairs(navbar:GetChildren()) do
				if child:IsA("TextButton") then
					child.Size = UDim2.new(0, 90, 0, 46)
				end
			end
		end
	end
	self._updateNavScroll = updateNavScroll

	do
		local drag, dragStart, dragPos = false, nil, nil
		header.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true dragStart = i.Position dragPos = win.Position end end)
		table.insert(self.connections, UIS.InputChanged:Connect(function(i) if drag and i.UserInputType == Enum.UserInputType.MouseMovement then local delta = i.Position - dragStart win.Position = UDim2.new(dragPos.X.Scale, dragPos.X.Offset + delta.X, dragPos.Y.Scale, dragPos.Y.Offset + delta.Y) self.originalPosition = win.Position end end))
		table.insert(self.connections, UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end))
	end

	table.insert(self.connections, UIS.InputBegan:Connect(function(input, gpe) if input.KeyCode == self.toggleKey then self:setVisible(not win.Visible) end end))

	self.tabs = {}
	self.activeTab = nil
	self.navList = navList

	if includeUITab ~= false then
		self._includeUITab = true
		task.defer(function()
			if not self._uiTabCreated then
				self._uiTabCreated = true
				self:_createUITab()
			end
		end)
	end

	local ctxMenu = Instance.new("Frame")
	ctxMenu.Size = UDim2.new(0, 160, 0, 0)
	ctxMenu.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	ctxMenu.BorderSizePixel = 0
	ctxMenu.Visible = false
	ctxMenu.ZIndex = 900
	ctxMenu.Parent = self.sg
	Instance.new("UICorner", ctxMenu).CornerRadius = UDim.new(0, 5)
	local ctxStroke = Instance.new("UIStroke", ctxMenu)
	ctxStroke.Color = self.theme.Accent
	ctxStroke.Transparency = 0.4
	ctxStroke.Thickness = 1
	local ctxLayout = Instance.new("UIListLayout", ctxMenu)
	ctxLayout.Padding = UDim.new(0, 1)
	ctxLayout.SortOrder = Enum.SortOrder.LayoutOrder
	local ctxPadding = Instance.new("UIPadding", ctxMenu)
	ctxPadding.PaddingTop = UDim.new(0, 4)
	ctxPadding.PaddingBottom = UDim.new(0, 4)
	ctxPadding.PaddingLeft = UDim.new(0, 4)
	ctxPadding.PaddingRight = UDim.new(0, 4)
	contextMenuFrame = ctxMenu
	self.contextMenu = ctxMenu
	self.contextMenuLayout = ctxLayout

	local function closeContextMenu()
		ctxMenu.Visible = false
		for _, c in ipairs(contextMenuConnections) do pcall(c.Disconnect, c) end
		contextMenuConnections = {}
		for _, child in ipairs(ctxMenu:GetChildren()) do
			if child:IsA("TextButton") or child:IsA("Frame") then child:Destroy() end
		end
	end
	self.closeContextMenu = closeContextMenu

	local function addContextMenuItem(text, icon, callback)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 26)
		btn.BackgroundTransparency = 1
		btn.Text = ""
		btn.ZIndex = 901
		btn.Parent = ctxMenu
		local hov = Instance.new("Frame")
		hov.Size = UDim2.new(1, 0, 1, 0)
		hov.BackgroundColor3 = self.theme.ItemHov
		hov.BorderSizePixel = 0
		hov.Visible = false
		hov.ZIndex = 901
		hov.Parent = btn
		Instance.new("UICorner", hov).CornerRadius = UDim.new(0, 4)
		btn.MouseEnter:Connect(function() hov.Visible = true end)
		btn.MouseLeave:Connect(function() hov.Visible = false end)
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -12, 1, 0)
		lbl.Position = UDim2.new(0, 8, 0, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = text
		lbl.TextColor3 = self.theme.White
		lbl.Font = Enum.Font.Roboto
		lbl.TextSize = 12
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.ZIndex = 902
		lbl.Parent = btn
		btn.MouseButton1Click:Connect(function()
			if callback then callback() end
			closeContextMenu()
		end)
		return btn
	end
	self.addContextMenuItem = addContextMenuItem

	function self:showContextMenu(pos, elemConfig)
		closeContextMenu()
		local x, y = pos.X, pos.Y
		ctxMenu.Position = UDim2.new(0, x, 0, y)

		if elemConfig and elemConfig.DefaultValue ~= nil then
			addContextMenuItem("Reset to Default", "", function()
				if elemConfig.SetValue then
					elemConfig:SetValue(elemConfig.DefaultValue)
				end
			end)
		end

		if elemConfig and elemConfig.Value ~= nil then
			addContextMenuItem("Copy Value", "", function()
				local v = elemConfig.Value
				local str
				if type(v) == "boolean" then
					str = tostring(v)
				elseif type(v) == "number" then
					str = tostring(math.floor(v * 1000) / 1000)
				elseif type(v) == "string" then
					str = v
				elseif type(v) == "table" then
					str = table.concat(v, ", ")
				elseif typeof and typeof(v) == "Color3" then
					str = string.format("%d, %d, %d", math.floor(v.R*255+0.5), math.floor(v.G*255+0.5), math.floor(v.B*255+0.5))
				else
					str = tostring(v)
				end
				if setclipboard then
					pcall(setclipboard, str)
					self:notify("Copied: " .. str, "info", 2)
				else
					self:notify("Value: " .. str, "info", 2)
				end
			end)
		end

		if elemConfig and elemConfig.IsToggle then
			local sepA = Instance.new("Frame")
			sepA.Size = UDim2.new(1, 0, 0, 1)
			sepA.BackgroundColor3 = self.theme.Border
			sepA.BorderSizePixel = 0
			sepA.ZIndex = 901
			sepA.Parent = ctxMenu
		end

		if elemConfig and elemConfig.IsToggle then
			local currentMode = elemConfig.Mode or "toggle"
			local modes = {"always", "toggle", "hold"}
			local modeLabels = {always = "Always On", toggle = "Toggle", hold = "Hold"}
			for _, mode in ipairs(modes) do
				local isActive = (currentMode == mode)
				local prefix = isActive and "• " or "  "
				local item = addContextMenuItem(prefix .. (modeLabels[mode] or mode), "", function()
					elemConfig.Mode = mode
					if mode == "always" then
						elemConfig:SetValue(true)
					end
					self:notify("Mode: " .. mode, "info", 1.5)
				end)
				if isActive then
					local lbl = item:FindFirstChildWhichIsA("TextLabel")
					if lbl then lbl.TextColor3 = self.theme.Accent end
				end
			end

			local sep2 = Instance.new("Frame")
			sep2.Size = UDim2.new(1, 0, 0, 1)
			sep2.BackgroundColor3 = self.theme.Border
			sep2.BorderSizePixel = 0
			sep2.ZIndex = 901
			sep2.Parent = ctxMenu

			local hotkeyText = elemConfig.Hotkey and elemConfig.Hotkey.Name or "None"
			addContextMenuItem("Hotkey: [" .. hotkeyText .. "]", "", function()
				self:notify("Press a key to bind...", "info", 2)
				local con
				con = UIS.InputBegan:Connect(function(input, gpe)
					if gpe then return end
					con:Disconnect()
					if input.KeyCode == Enum.KeyCode.Escape then
						elemConfig.Hotkey = nil
						self:notify("Hotkey cleared", "info", 1.5)
					elseif input.UserInputType == Enum.UserInputType.Keyboard then
						elemConfig.Hotkey = input.KeyCode
						self:notify("Hotkey set: " .. input.KeyCode.Name, "success", 1.5)
					end
				end)
			end)
		end

		task.defer(function()
			ctxMenu.Size = UDim2.new(0, 160, 0, ctxLayout.AbsoluteContentSize.Y + 8)
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
				if mode == "toggle" then
					elem.SetValue(not elem.Value)
				elseif mode == "hold" then
					elem.SetValue(true)
				end
			end
		end
	end))
	table.insert(self.connections, UIS.InputEnded:Connect(function(input)
		for _, elem in pairs(self.configs) do
			if elem.IsToggle and elem.Hotkey and input.KeyCode == elem.Hotkey then
				local mode = elem.Mode or "toggle"
				if mode == "hold" then
					elem.SetValue(false)
				end
			end
		end
	end))

	self:notify("CloverLib Loaded", "success", 2)
	activeWindow = self
	return self
end

function UILib:addWatermark(name)
	if self.watermark then self.watermark:Destroy() end
	local wm = Instance.new("Frame")
	wm.AutomaticSize = Enum.AutomaticSize.X
	wm.Size = UDim2.new(0, 0, 0, 30)
	wm.Position = UDim2.new(1, -10, 0, 10)
	wm.AnchorPoint = Vector2.new(1, 0)
	wm.BackgroundColor3 = self.theme.Panel
	wm.BorderSizePixel = 0
	wm.ClipsDescendants = false
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
	fpsLabel.Font = Enum.Font.RobotoMono
	fpsLabel.TextSize = 10
	fpsLabel.ZIndex = 201
	fpsLabel.LayoutOrder = 3
	fpsLabel.Parent = row
	local pingLabel = Instance.new("TextLabel")
	pingLabel.AutomaticSize = Enum.AutomaticSize.X
	pingLabel.Size = UDim2.new(0, 0, 1, 0)
	pingLabel.BackgroundTransparency = 1
	pingLabel.Text = "0ms"
	pingLabel.TextColor3 = self.theme.Accent
	pingLabel.Font = Enum.Font.RobotoMono
	pingLabel.TextSize = 10
	pingLabel.ZIndex = 201
	pingLabel.LayoutOrder = 4
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
		pingLabel.Text = math.floor(ping + 0.5) .. "ms"
	end)
	self.wmConn = connection
	self.watermark = wm
	table.insert(self.accentObjects, sep)
	table.insert(self.accentObjects, fpsLabel)
	table.insert(self.accentObjects, pingLabel)
	return wm
end

function UILib:_createUITab()
	local uiTab = self:addTab("UI")
	local uiSub = uiTab:addSubTab("Settings")
	local uiL, uiR = uiSub:split()

	local grp = uiL:addGroup("Interface")

	grp:colorpicker("Accent Color", self.theme.Accent, function(c)
		self:updateAccent(c)
	end, "Update accent color")

	grp:keybind("Toggle Key", "RightShift", function(_, name)
		self.toggleKey = Enum.KeyCode[name] or Enum.KeyCode.RightShift
		if self.hintLabel then
			self.hintLabel.Text = "[ " .. name .. " ]  TOGGLE"
		end
	end, "Set key to show/hide menu")

	grp:toggle("Show Version", self.showVersion, function(v)
		self.showVersion = v
		if self.versionPill then self.versionPill.Visible = v end
	end, "Show version pill")

	grp:toggle("Show Watermark", false, function(v)
		if v then self:addWatermark(self.title) else if self.watermark then self.watermark:Destroy(); self.watermark = nil end end
	end, "Display FPS and ping")

	grp:button("Unload", function() self:Destroy() end, "Cleanly remove the UI", Enum.TextXAlignment.Center, Color3.fromRGB(255, 80, 80))

	local cfg = uiR:addGroup("Configs")
	local currentConfig = "default"

	cfg:textbox("Config Name", "default", function(val)
		currentConfig = (val ~= "" and val or "default")
	end, "Name for save/load/delete")

	cfg:dropdown("Load Config", self:listConfigs(), "", function(val)
		currentConfig = val
		self:loadConfig(val)
	end, "Select a saved config to load", function()
		local list = self:listConfigs()
		if #list == 0 then list = {"(no configs)"} end
		return list
	end)

	cfg:button("Save Config", function()
		if currentConfig and currentConfig ~= "" then
			self:saveConfig(currentConfig)
		else
			self:notify("Enter a config name first", "warning")
		end
	end, "Save current settings")

	cfg:button("Delete Config", function()
		if currentConfig and currentConfig ~= "" then
			self:confirm('Delete config "' .. currentConfig .. '"?', function()
				self:deleteConfig(currentConfig)
			end)
		else
			self:notify("No config selected", "warning")
		end
	end, "Delete selected config")
end

function UILib:setTitle(text)
	if self.titleLabel then
		self.titleLabel.Text = tostring(text)
	end
end

function UILib:Destroy()
	for _, conn in ipairs(self.connections) do conn:Disconnect() end
	if self.wmConn then self.wmConn:Disconnect(); self.wmConn = nil end
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
		self.originalSize = self.window.Size
		local centerPos = UDim2.new(self.originalPosition.X.Scale, self.originalPosition.X.Offset + self.originalSize.X.Offset/2, self.originalPosition.Y.Scale, self.originalPosition.Y.Offset + self.originalSize.Y.Offset/2)
		self.window.AnchorPoint = Vector2.new(0.5, 0.5)
		self.window.Position = centerPos
		for _, popup in ipairs(self.activePopups) do
			pcall(function() if popup then popup:Destroy() end end)
		end
		self.activePopups = {}
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
	tab.subtabOrder = {}
	tab.firstSub = nil

	self._navTabCount = (self._navTabCount or 0) + 1
	local TAB_WIDTH = self._navTabCount >= 6 and 90 or 110

	if self._navTabCount == 6 then
		for _, child in ipairs(self.navbar:GetChildren()) do
			if child:IsA("TextButton") then
				child.Size = UDim2.new(0, 90, 0, 46)
			end
		end
		self.navbar.ClipsDescendants = true
	end

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, TAB_WIDTH, 0, 46)
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
	table.insert(self.accentObjects, underline)
	btn.MouseEnter:Connect(function() if btn.TextColor3 ~= self.theme.White then btn.TextColor3 = self.theme.GrayLt end end)
	btn.MouseLeave:Connect(function() if btn.TextColor3 ~= self.theme.White then btn.TextColor3 = self.theme.Gray end end)
	tab.btn = btn
	tab.underline = underline

	local function activate()
		for _, t in pairs(self.tabs) do
			for _, sub in pairs(t.subtabs) do
				sub.btn.Visible = false
				sub.page.Visible = false
				if sub.selLine then sub.selLine.Visible = false end
				if sub.label then sub.label.TextColor3 = self.theme.Gray end
			end
		end
		if self.activeTab then
			self.activeTab.btn.TextColor3 = self.theme.Gray
			if self.activeTab.underline then self.activeTab.underline.Visible = false end
		end
		btn.TextColor3 = self.theme.White
		underline.Visible = true
		for _, sub in pairs(tab.subtabOrder) do
			if sub.btn then sub.btn.Visible = true end
		end
		if tab.firstSub then
			local first = tab.subtabs[tab.firstSub]
			if first then
				first:select()
			end
		end
		self.sidebar.CanvasSize = UDim2.new(0, 0, 0, #tab.subtabOrder * 26 + 10)
		self.activeTab = tab
	end
	btn.MouseButton1Click:Connect(activate)
	tab.activate = activate
	self.tabs[name] = tab

	if not self.activeTab then
		task.defer(function()
			if not self.activeTab then
				activate()
			end
		end)
	end

	return tab
end

function UILib.Tab:addSubTab(name)
	local sub = setmetatable({}, UILib.SubTab)
	sub.name = name
	sub.tab = self
	sub.window = self.window
	sub.groups = {}

	local btn = Instance.new("TextButton")
	table.insert(self.subtabOrder, sub)
	btn.Size = UDim2.new(1, -8, 0, 24)
	btn.Position = UDim2.new(0, 4, 0, 0)
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
	selLine.Size = UDim2.new(0, 2, 1, -8)
	selLine.Position = UDim2.new(0, 0, 0, 4)
	selLine.BackgroundColor3 = self.window.theme.Accent
	selLine.BorderSizePixel = 0
	selLine.Visible = false
	selLine.ZIndex = 6
	selLine.Parent = btn

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -12, 1, 0)
	label.Position = UDim2.new(0, 8, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = name
	label.TextColor3 = self.window.theme.Gray
	label.Font = Enum.Font.Roboto
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
		self.window.sidebar.CanvasSize = UDim2.new(0, 0, 0, #self.tab.subtabOrder * 26 + 10)
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

local function attachTooltip(element, text)
	if not text then return end
	element.MouseEnter:Connect(function()
		startTooltipDelay(text, element)
	end)
	element.MouseLeave:Connect(hideTooltip)
	element.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			hideTooltip()
		end
	end)
end

local function createSlider(group, items, window, text, minVal, maxVal, defaultVal, callback, step)
	step = step or 1
	local id = generateID()
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 50)
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
	track.Position = UDim2.new(0, 0, 0, 34)
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
	knob.Size = UDim2.new(0, 10, 0, 10)
	knob.Position = UDim2.new((defaultVal - minVal) / (maxVal - minVal), -5, 0.5, -5)
	knob.BackgroundColor3 = Color3.new(0, 0, 0)
	knob.BorderSizePixel = 0
	knob.ZIndex = 5
	knob.Parent = track
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
		knob.Position = UDim2.new(rel, -5, 0.5, -5)
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
	window.configs[id] = elem
	row.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			window:showContextMenu(UIS:GetMouseLocation(), elem)
		end
	end)
	return row
end

local function createColorPicker(group, items, window, text, default, callback)
	local id = generateID()
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 32)
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
	local colorBox = Instance.new("TextButton")
	colorBox.Size = UDim2.new(0, 40, 0, 20)
	colorBox.Position = UDim2.new(1, -44, 0.5, -10)
	colorBox.BackgroundColor3 = default
	colorBox.BorderSizePixel = 0
	colorBox.ZIndex = 4
	colorBox.Text = ""
	colorBox.Parent = row
	Instance.new("UICorner", colorBox).CornerRadius = UDim.new(0, 3)
	local stroke = Instance.new("UIStroke", colorBox)
	stroke.Color = window.theme.Border
	stroke.Thickness = 1
	local current = default or Color3.new(1,0,0)
	local elem = {ID = id, Value = current}
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
		local _pickerJustOpened = true
		task.delay(0.1, function() _pickerJustOpened = false end)
		pickerFrame = Instance.new("Frame")
		pickerFrame.Size = UDim2.new(0, 220, 0, 260)
		local absPos = colorBox.AbsolutePosition
		local posX = absPos.X + colorBox.AbsoluteSize.X + 6
		local screenW = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 1920
		if posX + 220 > screenW - 10 then posX = absPos.X - 226 end
		if posX < 10 then posX = 10 end
		pickerFrame.Position = UDim2.new(0, posX, 0, absPos.Y)
		pickerFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
		pickerFrame.BorderSizePixel = 0
		pickerFrame.ZIndex = 2000
		pickerFrame.Parent = window.sg
		table.insert(window.activePopups, pickerFrame)
		Instance.new("UICorner", pickerFrame).CornerRadius = UDim.new(0, 8)
		local pickerStroke = Instance.new("UIStroke", pickerFrame)
		pickerStroke.Color = window.theme.Accent
		pickerStroke.Transparency = 0.5
		table.insert(window.accentObjects, pickerStroke)

		local satValSquare, satValKnob, hueSlider, hueKnob, hexBox
		local hueDragging, svDragging = false, false

		local function update()
			local h = hueKnob.Position.X.Scale
			local s = math.clamp(satValKnob.Position.X.Scale, 0, 1)
			local v = math.clamp(1 - satValKnob.Position.Y.Scale, 0, 1)
			current = Color3.fromHSV(h, s, v)
			elem.Value = current
			satValSquare.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			colorBox.BackgroundColor3 = current
			hexBox.Text = "#" .. current:ToHex()
			if window.rainbowElements[elem] then window.rainbowElements[elem].s = s window.rainbowElements[elem].v = v end
			if window.pulseElements[elem] then window.pulseElements[elem].s = s window.pulseElements[elem].v = v end
			if callback then callback(current) end
		end

		local function updateHue(pos)
			local rel = math.clamp((pos.X - hueSlider.AbsolutePosition.X) / hueSlider.AbsoluteSize.X, 0, 1)
			hueKnob.Position = UDim2.new(rel, -6, 0.5, -6)
			update()
		end

		local function updateSV(pos)
			local relX = math.clamp((pos.X - satValSquare.AbsolutePosition.X) / satValSquare.AbsoluteSize.X, 0, 1)
			local relY = math.clamp((pos.Y - satValSquare.AbsolutePosition.Y) / satValSquare.AbsoluteSize.Y, 0, 1)
			satValKnob.Position = UDim2.new(relX, -5, relY, -5)
			update()
		end

		local tabContainer = Instance.new("Frame")
		tabContainer.Size = UDim2.new(1, -16, 0, 24)
		tabContainer.Position = UDim2.new(0, 8, 0, 8)
		tabContainer.BackgroundTransparency = 1
		tabContainer.Parent = pickerFrame
		local tabLayout = Instance.new("UIListLayout", tabContainer)
		tabLayout.FillDirection = Enum.FillDirection.Horizontal
		tabLayout.Padding = UDim.new(0, 4)

		local function createTab(name)
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(0.33, -3, 1, 0)
			btn.BackgroundTransparency = 1
			btn.Text = name
			btn.TextColor3 = (currentMode == name) and window.theme.White or window.theme.Gray
			btn.Font = Enum.Font.GothamBold
			btn.TextSize = 11
			btn.ZIndex = 2001
			btn.Parent = tabContainer
			btn.MouseButton1Click:Connect(function()
				currentMode = name
				for _, t in ipairs(tabContainer:GetChildren()) do
					if t:IsA("TextButton") then
						t.TextColor3 = (t.Text == name) and window.theme.White or window.theme.Gray
					end
				end
				local _, cs, cv = Color3.toHSV(current)
				if cs < 0.05 then cs = 1 end
				if cv < 0.05 then cv = 1 end
				window.rainbowElements[elem] = (name == "Rainbow") and {callback = callback, colorBox = colorBox, s = cs, v = cv} or nil
				window.pulseElements[elem] = (name == "Pulse") and {callback = callback, colorBox = colorBox, s = cs, v = cv} or nil
				if name == "Solid" then update() end
			end)
			return btn
		end

		createTab("Solid")
		createTab("Rainbow")
		createTab("Pulse")

		satValSquare = Instance.new("Frame")
		satValSquare.Size = UDim2.new(1, -16, 0, 110)
		satValSquare.Position = UDim2.new(0, 8, 0, 36)
		satValSquare.BackgroundColor3 = Color3.fromHSV(select(1, Color3.toHSV(current)), 1, 1)
		satValSquare.ZIndex = 2001
		satValSquare.Parent = pickerFrame
		local svWhite = Instance.new("Frame", satValSquare)
		svWhite.Size = UDim2.new(1, 0, 1, 0)
		svWhite.ZIndex = 2001
		Instance.new("UIGradient", svWhite).Color = ColorSequence.new(Color3.new(1, 1, 1))
		svWhite.BackgroundTransparency = 0
		svWhite.UIGradient.Transparency = NumberSequence.new(0, 1)
		svWhite.UIGradient.Rotation = 0
		local svBlack = Instance.new("Frame", satValSquare)
		svBlack.Size = UDim2.new(1, 0, 1, 0)
		svBlack.ZIndex = 2002
		Instance.new("UIGradient", svBlack).Color = ColorSequence.new(Color3.new(0, 0, 0))
		svBlack.UIGradient.Transparency = NumberSequence.new(1, 0)
		svBlack.UIGradient.Rotation = 90

		satValKnob = Instance.new("Frame")
		satValKnob.Size = UDim2.new(0, 10, 0, 10)
		local h_, s_, v_ = Color3.toHSV(current)
		satValKnob.Position = UDim2.new(s_, -5, 1 - v_, -5)
		satValKnob.BackgroundColor3 = window.theme.White
		satValKnob.ZIndex = 2003
		satValKnob.Parent = satValSquare
		Instance.new("UICorner", satValKnob).CornerRadius = UDim.new(1, 0)
		Instance.new("UIStroke", satValKnob).Color = Color3.new(0, 0, 0)

		hueSlider = Instance.new("Frame")
		hueSlider.Size = UDim2.new(1, -16, 0, 10)
		hueSlider.Position = UDim2.new(0, 8, 0, 154)
		hueSlider.BackgroundColor3 = Color3.new(1,1,1)
		hueSlider.ZIndex = 2001
		hueSlider.Parent = pickerFrame
		Instance.new("UICorner", hueSlider).CornerRadius = UDim.new(0, 5)
		local hueGradient = Instance.new("UIGradient", hueSlider)
		hueGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.new(1,0,0)), ColorSequenceKeypoint.new(0.17, Color3.new(1,1,0)), ColorSequenceKeypoint.new(0.33, Color3.new(0,1,0)), ColorSequenceKeypoint.new(0.5, Color3.new(0,1,1)), ColorSequenceKeypoint.new(0.67, Color3.new(0,0,1)), ColorSequenceKeypoint.new(0.83, Color3.new(1,0,1)), ColorSequenceKeypoint.new(1, Color3.new(1,0,0))}

		hueKnob = Instance.new("Frame")
		hueKnob.Size = UDim2.new(0, 12, 0, 12)
		hueKnob.Position = UDim2.new(h_, -6, 0.5, -6)
		hueKnob.BackgroundColor3 = window.theme.White
		hueKnob.ZIndex = 2002
		hueKnob.Parent = hueSlider
		Instance.new("UICorner", hueKnob).CornerRadius = UDim.new(1, 0)
		Instance.new("UIStroke", hueKnob).Color = Color3.new(0, 0, 0)

		local hexRow = Instance.new("Frame")
		hexRow.Size = UDim2.new(1, -16, 0, 24)
		hexRow.Position = UDim2.new(0, 8, 0, 172)
		hexRow.BackgroundTransparency = 1
		hexRow.Parent = pickerFrame
		hexBox = Instance.new("TextBox")
		hexBox.Size = UDim2.new(0.5, 0, 1, 0)
		hexBox.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
		hexBox.BorderSizePixel = 0
		hexBox.Text = "#" .. current:ToHex()
		hexBox.TextColor3 = window.theme.Accent
		hexBox.Font = Enum.Font.RobotoMono
		hexBox.TextSize = 12
		hexBox.ZIndex = 2001
		hexBox.Parent = hexRow
		Instance.new("UICorner", hexBox).CornerRadius = UDim.new(0, 4)

		local copyBtn = Instance.new("TextButton")
		copyBtn.Size = UDim2.new(0.25, -4, 1, 0)
		copyBtn.Position = UDim2.new(0.5, 4, 0, 0)
		copyBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
		copyBtn.Text = "COPY"
		copyBtn.TextColor3 = window.theme.White
		copyBtn.Font = Enum.Font.GothamBold
		copyBtn.TextSize = 10
		copyBtn.ZIndex = 2001
		copyBtn.Parent = hexRow
		Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 4)

		local applyBtn = Instance.new("TextButton")
		applyBtn.Size = UDim2.new(0.25, -4, 1, 0)
		applyBtn.Position = UDim2.new(0.75, 4, 0, 0)
		applyBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
		applyBtn.Text = "APPLY"
		applyBtn.TextColor3 = window.theme.White
		applyBtn.Font = Enum.Font.GothamBold
		applyBtn.TextSize = 10
		applyBtn.ZIndex = 2001
		applyBtn.Parent = hexRow
		Instance.new("UICorner", applyBtn).CornerRadius = UDim.new(0, 4)

		local footer = Instance.new("Frame")
		footer.Size = UDim2.new(1, -16, 0, 24)
		footer.Position = UDim2.new(0, 8, 0, 204)
		footer.BackgroundTransparency = 1
		footer.Parent = pickerFrame
		local resetBtn = Instance.new("TextButton")
		resetBtn.Size = UDim2.new(0.5, -4, 1, 0)
		resetBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
		resetBtn.Text = "RESET"
		resetBtn.TextColor3 = window.theme.White
		resetBtn.Font = Enum.Font.GothamBold
		resetBtn.TextSize = 10
		resetBtn.ZIndex = 2001
		resetBtn.Parent = footer
		Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 4)

		local pickBtn = Instance.new("TextButton")
		pickBtn.Size = UDim2.new(0.5, -4, 1, 0)
		pickBtn.Position = UDim2.new(0.5, 4, 0, 0)
		pickBtn.BackgroundColor3 = window.theme.Accent
		pickBtn.Text = "PICK"
		pickBtn.TextColor3 = Color3.new(1,1,1)
		pickBtn.Font = Enum.Font.GothamBold
		pickBtn.TextSize = 10
		pickBtn.ZIndex = 2001
		pickBtn.Parent = footer
		Instance.new("UICorner", pickBtn).CornerRadius = UDim.new(0, 4)

		local pickerHueDragConn = UIS.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				hueDragging = false
				svDragging = false
			end
		end)
		table.insert(window.connections, pickerHueDragConn)

		hueSlider.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then hueDragging = true updateHue(input.Position) end end)
		hueSlider.InputChanged:Connect(function(input) if hueDragging and input.UserInputType == Enum.UserInputType.MouseMovement then updateHue(input.Position) end end)
		satValSquare.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then svDragging = true updateSV(input.Position) end end)
		satValSquare.InputChanged:Connect(function(input) if svDragging and input.UserInputType == Enum.UserInputType.MouseMovement then updateSV(input.Position) end end)

		copyBtn.MouseButton1Click:Connect(function() pcall(setclipboard, hexBox.Text) end)
		applyBtn.MouseButton1Click:Connect(function()
			local success, hexColor = pcall(Color3.fromHex, hexBox.Text:gsub("#", ""))
			if success then
				current = hexColor
				local h, s, v = Color3.toHSV(current)
				hueKnob.Position = UDim2.new(h, -6, 0.5, -6)
				satValKnob.Position = UDim2.new(s, -5, 1 - v, -5)
				update()
			end
		end)
		resetBtn.MouseButton1Click:Connect(function()
			current = default
			local h, s, v = Color3.toHSV(current)
			hueKnob.Position = UDim2.new(h, -6, 0.5, -6)
			satValKnob.Position = UDim2.new(s, -5, 1 - v, -5)
			update()
		end)
		pickBtn.MouseButton1Click:Connect(function()
			if callback then callback(current) end
			colorBox.BackgroundColor3 = current
			closePicker()
		end)

		local inputBeganConn
		inputBeganConn = UIS.InputBegan:Connect(function(input)
			if _pickerJustOpened then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				local pos = UIS:GetMouseLocation()
				if not pickerFrame or not pickerFrame.Parent then
					inputBeganConn:Disconnect()
					return
				end
				local absPos_ = pickerFrame.AbsolutePosition
				local absSize_ = pickerFrame.AbsoluteSize
				local btnPos = colorBox.AbsolutePosition
				local btnSize = colorBox.AbsoluteSize
				if pos.X >= btnPos.X and pos.X <= btnPos.X + btnSize.X and pos.Y >= btnPos.Y and pos.Y <= btnPos.Y + btnSize.Y then
					return
				end
				if pos.X < absPos_.X or pos.X > absPos_.X + absSize_.X or pos.Y < absPos_.Y or pos.Y > absPos_.Y + absSize_.Y then
					closePicker()
					inputBeganConn:Disconnect()
				end
			end
		end)
	end
	colorBox.MouseButton1Click:Connect(openPicker)
	return row
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
	label.Font = Enum.Font.Roboto
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 11
	label.Parent = row
	local dbtn = Instance.new("TextButton")
	dbtn.Size = UDim2.new(1, 0, 0, 28)
	dbtn.Position = UDim2.new(0, 0, 0, 26)
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
	arrow.TextColor3 = window.theme.Gray
	arrow.Font = Enum.Font.GothamBold
	arrow.TextSize = 12
	arrow.ZIndex = 12
	arrow.Parent = dbtn
	local listH = #options * 26
	local dlist = Instance.new("ScrollingFrame")
	dlist.Size = UDim2.new(1, 0, 0, math.min(listH, 104))
	dlist.Position = UDim2.new(0, 0, 0, 56)
	dlist.BackgroundColor3 = window.theme.Item
	dlist.BorderSizePixel = 0
	dlist.ScrollBarThickness = 2
	dlist.ScrollBarImageColor3 = window.theme.Accent
	dlist.CanvasSize = UDim2.new(0, 0, 0, listH)
	dlist.Visible = false
	dlist.ZIndex = 50
	dlist.Parent = row
	Instance.new("UICorner", dlist).CornerRadius = UDim.new(0, 4)
	local listStroke = Instance.new("UIStroke", dlist)
	listStroke.Color = window.theme.Border
	listStroke.Thickness = 1
	table.insert(window.accentObjects, listStroke)
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
		row.Size = UDim2.new(1, 0, 0, 56 + (open and math.min(listH, 104) or 0))
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

function UILib.Column:addGroup(title)
	local window = self.window
	if not window then error("No window reference in column") end
	local group = {}
	group.title = title
	group.window = window
	group.tab = self.tab
	group.sub = self.sub
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

	function group:split()
		local splitRow = Instance.new("Frame")
		splitRow.Size = UDim2.new(1, 0, 0, 0)
		splitRow.BackgroundTransparency = 1
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
		local leftGroup = {window = window, frame = lFrame, items = lFrame, tab = self.tab, sub = self.sub, updateSize = updateSplitSize}
		local rightGroup = {window = window, frame = rFrame, items = rFrame, tab = self.tab, sub = self.sub, updateSize = updateSplitSize}
		for k, v in pairs(group) do
			if type(v) == "function" and k ~= "split" and k ~= "addGroup" then
				leftGroup[k] = function(self, ...) return v(leftGroup, ...) end
				rightGroup[k] = function(self, ...) return v(rightGroup, ...) end
			end
		end
		return leftGroup, rightGroup
	end

	function group:paragraph(title, text, tooltip)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 0)
		row.BackgroundTransparency = 1
		row.AutomaticSize = Enum.AutomaticSize.Y
		row.Parent = items
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -8, 0, 0)
		lbl.Position = UDim2.new(0, 4, 0, 2)
		lbl.BackgroundTransparency = 1
		lbl.Text = title
		lbl.TextColor3 = window.theme.Accent
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 12
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.AutomaticSize = Enum.AutomaticSize.Y
		lbl.Parent = row
		local body = Instance.new("TextLabel")
		body.Size = UDim2.new(1, -8, 0, 0)
		body.Position = UDim2.new(0, 4, 0, 18)
		body.BackgroundTransparency = 1
		body.Text = text
		body.TextColor3 = window.theme.Gray
		body.Font = Enum.Font.Roboto
		body.TextSize = 12
		body.TextXAlignment = Enum.TextXAlignment.Left
		body.TextWrapped = true
		body.AutomaticSize = Enum.AutomaticSize.Y
		body.Parent = row
		Instance.new("UIPadding", row).PaddingBottom = UDim.new(0, 6)
		if tooltip then attachTooltip(row, tooltip) end
		updateSize()
		return row
	end

	function group:toggle(text, default, callback, tooltip)
		local id = generateID()
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 32)
		row.BackgroundTransparency = 1
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
		local cbOuter = Instance.new("TextButton")
		cbOuter.Size = UDim2.new(0, 18, 0, 18)
		cbOuter.Position = UDim2.new(1, -22, 0.5, -9)
		cbOuter.BackgroundColor3 = default and window.theme.Accent or window.theme.Track
		cbOuter.BorderSizePixel = 0
		cbOuter.ZIndex = 4
		cbOuter.Text = ""
		cbOuter.Parent = row
		Instance.new("UICorner", cbOuter).CornerRadius = UDim.new(0, 4)
		local cbStroke = Instance.new("UIStroke", cbOuter)
		cbStroke.Color = default and window.theme.AccentD or window.theme.Border
		cbStroke.Thickness = 1
		local cbMark = Instance.new("TextLabel")
		cbMark.Size = UDim2.new(1, 0, 1, 0)
		cbMark.BackgroundTransparency = 1
		cbMark.Text = default and "x" or ""
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
		local elem = {ID = id, Value = state, DefaultValue = default, IsToggle = true, Mode = "toggle"}
		elem.SetValue = function(val)
			state = val
			elem.Value = state
			cbOuter.BackgroundColor3 = state and window.theme.Accent or window.theme.Track
			cbStroke.Color = state and window.theme.AccentD or window.theme.Border
			cbMark.Text = state and "x" or ""
			if callback then callback(state) end
			if window.configs[id] then window.configs[id].Value = state end
		end
		window.configs[id] = elem
		row.MouseEnter:Connect(function() rh.Visible = true end)
		row.MouseLeave:Connect(function() rh.Visible = false end)
		cbOuter.MouseButton1Click:Connect(function()
			if elem.Mode == "always" then return end
			state = not state
			elem.SetValue(state)
		end)
		row.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				window:showContextMenu(UIS:GetMouseLocation(), elem)
			end
		end)
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

	function group:dropdown(text, options, default, callback, tooltip, refreshCallback)
		local id = generateID()
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 56)
		row.BackgroundTransparency = 1
		row.ClipsDescendants = false
		row.ZIndex = 10
		row.Parent = items
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -60, 0, 18)
		lbl.Position = UDim2.new(0, 4, 0, 2)
		lbl.BackgroundTransparency = 1
		lbl.Text = text
		lbl.TextColor3 = window.theme.GrayLt
		lbl.Font = Enum.Font.Roboto
		lbl.TextSize = 12
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.ZIndex = 11
		lbl.Parent = row

		local refreshBtn = nil
		if refreshCallback then
			refreshBtn = Instance.new("TextButton")
			refreshBtn.Size = UDim2.new(0, 18, 0, 18)
			refreshBtn.Position = UDim2.new(1, -20, 0, 2)
			refreshBtn.BackgroundColor3 = window.theme.Track
			refreshBtn.Text = "↺"
			refreshBtn.TextColor3 = window.theme.Gray
			refreshBtn.Font = Enum.Font.GothamBold
			refreshBtn.TextSize = 13
			refreshBtn.ZIndex = 12
			refreshBtn.Parent = row
			Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 4)
		end

		local dbtn = Instance.new("TextButton")
		dbtn.Size = UDim2.new(1, 0, 0, 32)
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
		arrow.TextColor3 = window.theme.Gray
		arrow.Font = Enum.Font.GothamBold
		arrow.TextSize = 12
		arrow.ZIndex = 12
		arrow.Name = "arrow"
		table.insert(window.accentObjects, arrow)
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
		local dstroke2 = Instance.new("UIStroke", dlist)
		dstroke2.Color = window.theme.Border
		dstroke2.Thickness = 1
		local dlayout = Instance.new("UIListLayout", dlist)
		dlayout.SortOrder = Enum.SortOrder.LayoutOrder
		dlayout.Padding = UDim.new(0, 1)
		local dpad = Instance.new("UIPadding", dlist)
		dpad.PaddingTop = UDim.new(0, 3)
		dpad.PaddingBottom = UDim.new(0, 3)
		dpad.PaddingLeft = UDim.new(0, 3)
		dpad.PaddingRight = UDim.new(0, 3)

		local checks = {}
		local backgrounds = {}
		local currentOptions = options
		local currentSelection = default
		local open = false

		local function closeDropdown()
			open = false
			dlist.Visible = false
			arrow.Text = "▼"
			row.Size = UDim2.new(1, 0, 0, 52)
			updateSize()
		end

		local function buildOptions(opts)
			for _, child in ipairs(dlist:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
			checks = {}
			backgrounds = {}
			currentOptions = opts
			listH = #opts * 26
			dlist.CanvasSize = UDim2.new(0, 0, 0, listH)
			for _, opt in ipairs(opts) do
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
				bg.BackgroundTransparency = 0.85
				bg.BorderSizePixel = 0
				bg.Visible = (opt == currentSelection)
				bg.ZIndex = 50
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
				ol.TextColor3 = (opt == currentSelection) and window.theme.White or window.theme.GrayLt
				ol.Font = Enum.Font.Roboto
				ol.TextSize = 12
				ol.TextXAlignment = Enum.TextXAlignment.Left
				ol.ZIndex = 52
				ol.Parent = ob
				local ck = Instance.new("TextLabel")
				ck.Size = UDim2.new(0, 8, 0, 8)
				ck.Position = UDim2.new(1, -14, 0.5, -4)
				ck.BackgroundColor3 = window.theme.Accent
				ck.BackgroundTransparency = (opt == currentSelection) and 0 or 1
				ck.Text = ""
				ck.ZIndex = 52
				ck.Parent = ob
				Instance.new("UICorner", ck).CornerRadius = UDim.new(1, 0)
				checks[opt] = ck
				ob.MouseEnter:Connect(function() oh.Visible = true ol.TextColor3 = window.theme.White end)
				ob.MouseLeave:Connect(function() oh.Visible = false if opt ~= currentSelection then ol.TextColor3 = window.theme.GrayLt end end)
				ob.MouseButton1Click:Connect(function()
					currentSelection = opt
					selLbl.Text = opt
					for o, c in pairs(checks) do c.BackgroundTransparency = (o == opt) and 0 or 1 end
					for o, b in pairs(backgrounds) do b.Visible = (o == opt) end
					for _, child in ipairs(dlist:GetChildren()) do
						if child:IsA("TextButton") then
							local l = child:FindFirstChildOfClass("TextLabel")
							if l then l.TextColor3 = (l.Text == opt) and window.theme.White or window.theme.GrayLt end
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
			dlist.Visible = open
			arrow.Text = open and "▲" or "▼"
			row.Size = UDim2.new(1, 0, 0, 52 + (open and math.min(listH, 104) or 0))
			updateSize()
		end)

		local elem = {
			ID = id, Value = currentSelection, DefaultValue = default, Refresh = refresh,
			SetValue = function(val)
				currentSelection = val
				selLbl.Text = val
				for o, c in pairs(checks) do c.Text = (o == val) and "×" or "" end
				for o, b in pairs(backgrounds) do b.Visible = (o == val) end
				if callback then callback(val) end
			end
		}
		window.configs[id] = elem
		row.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton2 then window:showContextMenu(UIS:GetMouseLocation(), elem) end
		end)
		if tooltip then attachTooltip(row, tooltip) end
		updateSize()
		return row
	end

	function group:keybind(text, currentName, onChange, tooltip)
		local id = generateID()
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 34)
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
		local kw = math.max(MIN_KEYBIND_WIDTH, math.min(MAX_KEYBIND_WIDTH, math.floor(window.size.X * 0.13)))
		local kbtn = Instance.new("TextButton")
		kbtn.Size = UDim2.new(0, kw, 0, 22)
		kbtn.Position = UDim2.new(1, -(kw + 2), 0.5, -11)
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
		table.insert(window.keybindButtons, kbtn)
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

	function group:button(text, callback, tooltip, align, color)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 32)
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
		label.TextColor3 = color or window.theme.White
		label.Font = Enum.Font.Roboto
		label.TextSize = 13
		label.TextXAlignment = align or Enum.TextXAlignment.Left
		label.ZIndex = 4
		label.Parent = btn
		btn.MouseButton1Click:Connect(callback)
		if tooltip then attachTooltip(btn, tooltip) end
		updateSize()
		return btn
	end

	function group:expandableToggle(text, default, contentFunc, tooltip)
		local container = Instance.new("Frame")
		container.Size = UDim2.new(1, 0, 0, 34)
		container.BackgroundTransparency = 1
		container.ClipsDescendants = true
		container.Parent = items
		local toggleRow = Instance.new("Frame")
		toggleRow.Size = UDim2.new(1, 0, 0, 34)
		toggleRow.BackgroundTransparency = 1
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
		local cbOuter = Instance.new("TextButton")
		cbOuter.Size = UDim2.new(0, 18, 0, 18)
		cbOuter.Position = UDim2.new(1, -22, 0.5, -9)
		cbOuter.BackgroundColor3 = default and window.theme.Accent or window.theme.Track
		cbOuter.BorderSizePixel = 0
		cbOuter.ZIndex = 4
		cbOuter.Text = ""
		cbOuter.Parent = toggleRow
		Instance.new("UICorner", cbOuter).CornerRadius = UDim.new(0, 4)
		local cbStroke = Instance.new("UIStroke", cbOuter)
		cbStroke.Color = default and window.theme.AccentD or window.theme.Border
		cbStroke.Thickness = 1
		local cbMark = Instance.new("TextLabel")
		cbMark.Size = UDim2.new(1, 0, 1, 0)
		cbMark.BackgroundTransparency = 1
		cbMark.Text = default and "x" or ""
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
		contentFrame.Position = UDim2.new(0, 0, 0, 34)
		contentFrame.BackgroundTransparency = 1
		contentFrame.Parent = container
		local contentLayout = Instance.new("UIListLayout", contentFrame)
		contentLayout.Padding = UDim.new(0, 2)
		contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
		local function updateContentSize()
			local h = contentLayout.AbsoluteContentSize.Y
			contentFrame.Size = UDim2.new(1, 0, 0, h)
			container.Size = UDim2.new(1, 0, 0, 34 + (default and h or 0))
			updateSize()
		end
		contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateContentSize)
		local nestedGroup = {}
		function nestedGroup:toggle(subText, subDefault, subCallback, subTooltip) local r = group:toggle(subText, subDefault, subCallback, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:slider(subText, min, max, def, subCallback, step, subTooltip) local r = group:slider(subText, min, max, def, subCallback, step, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:dropdown(subText, opts, def, subCallback, subTooltip) local r = group:dropdown(subText, opts, def, subCallback, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:keybind(subText, cur, subCallback, subTooltip) local r = group:keybind(subText, cur, subCallback, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:label(subText, col, subTooltip) local r = group:label(subText, col, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:button(subText, subCallback, subTooltip, al, col) local r = group:button(subText, subCallback, subTooltip, al, col) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:colorpicker(subText, def, subCallback, subTooltip) local r = group:colorpicker(subText, def, subCallback, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:multidropdown(subText, opts, def, subCallback, subTooltip) local r = group:multidropdown(subText, opts, def, subCallback, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:textbox(subText, def, subCallback, subTooltip) local r = group:textbox(subText, def, subCallback, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:numberbox(subText, def, mn, mx, subCallback, subTooltip) local r = group:numberbox(subText, def, mn, mx, subCallback, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:rangeslider(subText, mn, mx, dMin, dMax, subCallback, subTooltip) local r = group:rangeslider(subText, mn, mx, dMin, dMax, subCallback, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		if contentFunc then contentFunc(nestedGroup) end
		local state = default
		cbOuter.MouseButton1Click:Connect(function()
			state = not state
			cbOuter.BackgroundColor3 = state and window.theme.Accent or window.theme.Track
			cbStroke.Color = state and window.theme.AccentD or window.theme.Border
			cbMark.Text = state and "x" or ""
			container.Size = UDim2.new(1, 0, 0, 34 + (state and contentLayout.AbsoluteContentSize.Y or 0))
			updateSize()
		end)
		if tooltip then attachTooltip(toggleRow, tooltip) end
		updateContentSize()
		return container
	end

	function group:collapsible(text, default, contentFunc, tooltip)
		local container = Instance.new("Frame")
		container.Size = UDim2.new(1, 0, 0, 34)
		container.BackgroundTransparency = 1
		container.ClipsDescendants = true
		container.Parent = items
		local toggleRow = Instance.new("TextButton")
		toggleRow.Size = UDim2.new(1, 0, 0, 34)
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
		arrow.Text = default and "v" or ">"
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
		contentFrame.Position = UDim2.new(0, 0, 0, 34)
		contentFrame.BackgroundTransparency = 1
		contentFrame.Parent = container
		local contentLayout = Instance.new("UIListLayout", contentFrame)
		contentLayout.Padding = UDim.new(0, 2)
		contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
		local function updateContentSize()
			local h = contentLayout.AbsoluteContentSize.Y
			contentFrame.Size = UDim2.new(1, 0, 0, h)
			container.Size = UDim2.new(1, 0, 0, 34 + (default and h or 0))
			updateSize()
		end
		contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateContentSize)
		local nestedGroup = {}
		function nestedGroup:toggle(subText, subDefault, subCallback, subTooltip) local r = group:toggle(subText, subDefault, subCallback, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:slider(subText, min, max, def, subCallback, step, subTooltip) local r = group:slider(subText, min, max, def, subCallback, step, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:dropdown(subText, opts, def, subCallback, subTooltip) local r = group:dropdown(subText, opts, def, subCallback, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:keybind(subText, cur, subCallback, subTooltip) local r = group:keybind(subText, cur, subCallback, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:label(subText, col, subTooltip) local r = group:label(subText, col, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:button(subText, subCallback, subTooltip, al, col) local r = group:button(subText, subCallback, subTooltip, al, col) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:colorpicker(subText, def, subCallback, subTooltip) local r = group:colorpicker(subText, def, subCallback, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:multidropdown(subText, opts, def, subCallback, subTooltip) local r = group:multidropdown(subText, opts, def, subCallback, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:textbox(subText, def, subCallback, subTooltip) local r = group:textbox(subText, def, subCallback, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:numberbox(subText, def, mn, mx, subCallback, subTooltip) local r = group:numberbox(subText, def, mn, mx, subCallback, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:rangeslider(subText, mn, mx, dMin, dMax, subCallback, subTooltip) local r = group:rangeslider(subText, mn, mx, dMin, dMax, subCallback, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		if contentFunc then contentFunc(nestedGroup) end
		local state = default
		toggleRow.MouseButton1Click:Connect(function() state = not state arrow.Text = state and "v" or ">" container.Size = UDim2.new(1, 0, 0, 34 + (state and contentLayout.AbsoluteContentSize.Y or 0)) updateSize() end)
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
		box.Size = UDim2.new(1, -8, 0, 22)
		box.Position = UDim2.new(0, 4, 1, -26)
		box.BackgroundColor3 = window.theme.Track
		box.ClipsDescendants = true
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
		local elem = {ID = id, Value = current, DefaultValue = default or "", SetValue = function(val) current = val box.Text = val if callback then callback(val) end window.configs[id].Value = val end}
		window.configs[id] = elem
		row.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				window:showContextMenu(UIS:GetMouseLocation(), elem)
			end
		end)
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
		box.ClipsDescendants = true
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
		local elem = {ID = id, Value = current, DefaultValue = default or 0, SetValue = function(val) val = math.clamp(val, min, max) current = val box.Text = tostring(val) if callback then callback(val) end window.configs[id].Value = val end}
		window.configs[id] = elem
		row.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				window:showContextMenu(UIS:GetMouseLocation(), elem)
			end
		end)
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
		local rsInputConn = UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then apply(i.Position.X, dragType) end end)
		local rsEndConn = UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
		table.insert(window.connections, rsInputConn)
		table.insert(window.connections, rsEndConn)
		local elem = {ID = id, Value = {currentMin, currentMax}, DefaultValue = {defaultMin, defaultMax}, SetValue = function(t) currentMin, currentMax = t[1], t[2]; updateDisplay() if callback then callback(currentMin, currentMax) end window.configs[id].Value = {currentMin, currentMax} end}
		window.configs[id] = elem
		row.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				window:showContextMenu(UIS:GetMouseLocation(), elem)
			end
		end)
		if tooltip then attachTooltip(row, tooltip) end
		updateSize()
		return row
	end

	return group
end

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
	end
	itemLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSize)

	group.frame = grp
	group.items = items
	group.itemLayout = itemLayout
	group.updateSize = updateSize

	function group:split(leftTitle, rightTitle)
		local splitRow = Instance.new("Frame")
		splitRow.Size = UDim2.new(1, 0, 0, 0)
		splitRow.BackgroundTransparency = 1
		splitRow.AutomaticSize = Enum.AutomaticSize.Y
		splitRow.Parent = items

		local function makeSplitColumn(xPos, title_)
			local col = Instance.new("Frame")
			col.Size = UDim2.new(0.5, -4, 0, 0)
			col.Position = xPos
			col.BackgroundColor3 = window.theme.Item
			col.BackgroundTransparency = 0.5
			col.BorderSizePixel = 0
			col.AutomaticSize = Enum.AutomaticSize.Y
			col.Parent = splitRow
			Instance.new("UICorner", col).CornerRadius = UDim.new(0, 6)
			local colStroke = Instance.new("UIStroke", col)
			colStroke.Color = window.theme.Border
			colStroke.Thickness = 1
			local hdr = Instance.new("Frame")
			hdr.Size = UDim2.new(1, 0, 0, 24)
			hdr.BackgroundTransparency = 1
			hdr.Parent = col
			local hdrLine = Instance.new("Frame")
			hdrLine.Size = UDim2.new(1, -12, 0, 1)
			hdrLine.Position = UDim2.new(0, 6, 1, -1)
			hdrLine.BackgroundColor3 = window.theme.Accent
			hdrLine.BackgroundTransparency = 0.7
			hdrLine.BorderSizePixel = 0
			hdrLine.Parent = hdr
			if title_ and title_ ~= "" then
				local hdrLbl = Instance.new("TextLabel")
				hdrLbl.Size = UDim2.new(1, -10, 1, 0)
				hdrLbl.Position = UDim2.new(0, 8, 0, 0)
				hdrLbl.BackgroundTransparency = 1
				hdrLbl.Text = title_:upper()
				hdrLbl.TextColor3 = window.theme.Accent
				hdrLbl.Font = Enum.Font.GothamBold
				hdrLbl.TextSize = 10
				hdrLbl.TextXAlignment = Enum.TextXAlignment.Left
				hdrLbl.Parent = hdr
			end
			local colItems = Instance.new("Frame")
			colItems.Size = UDim2.new(1, 0, 0, 0)
			colItems.Position = UDim2.new(0, 0, 0, 24)
			colItems.BackgroundTransparency = 1
			colItems.AutomaticSize = Enum.AutomaticSize.Y
			colItems.Parent = col
			local colLayout = Instance.new("UIListLayout", colItems)
			colLayout.Padding = UDim.new(0, 2)
			colLayout.SortOrder = Enum.SortOrder.LayoutOrder
			local colPad = Instance.new("UIPadding", colItems)
			colPad.PaddingLeft = UDim.new(0, 6)
			colPad.PaddingRight = UDim.new(0, 6)
			colPad.PaddingBottom = UDim.new(0, 6)
			return col, colItems, colLayout
		end

		local lCol, lItems, lLayout = makeSplitColumn(UDim2.new(0, 0, 0, 0), leftTitle or "")
		local rCol, rItems, rLayout = makeSplitColumn(UDim2.new(0.5, 4, 0, 0), rightTitle or "")

		local function updateSplitSize()
			local lh = lLayout.AbsoluteContentSize.Y + 32
			local rh = rLayout.AbsoluteContentSize.Y + 32
			local maxH = math.max(lh, rh)
			lCol.Size = UDim2.new(0.5, -4, 0, maxH)
			rCol.Size = UDim2.new(0.5, -4, 0, maxH)
			splitRow.Size = UDim2.new(1, 0, 0, maxH)
			updateSize()
		end
		lLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSplitSize)
		rLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSplitSize)

		local leftGroup = {window = window, frame = lCol, items = lItems, tab = group.tab, sub = group.subtab, updateSize = updateSplitSize}
		local rightGroup = {window = window, frame = rCol, items = rItems, tab = group.tab, sub = group.subtab, updateSize = updateSplitSize}

		for k, v in pairs(group) do
			if type(v) == "function" and k ~= "split" then
				leftGroup[k] = v
				rightGroup[k] = v
			end
		end

		return leftGroup, rightGroup
	end

	function group:paragraph(title, text, tooltip)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 0)
		row.BackgroundTransparency = 1
		row.AutomaticSize = Enum.AutomaticSize.Y
		row.Parent = items
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -8, 0, 0)
		lbl.Position = UDim2.new(0, 4, 0, 2)
		lbl.BackgroundTransparency = 1
		lbl.Text = title
		lbl.TextColor3 = window.theme.Accent
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 12
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.AutomaticSize = Enum.AutomaticSize.Y
		lbl.Parent = row
		local body = Instance.new("TextLabel")
		body.Size = UDim2.new(1, -8, 0, 0)
		body.Position = UDim2.new(0, 4, 0, 18)
		body.BackgroundTransparency = 1
		body.Text = text
		body.TextColor3 = window.theme.Gray
		body.Font = Enum.Font.Roboto
		body.TextSize = 12
		body.TextXAlignment = Enum.TextXAlignment.Left
		body.TextWrapped = true
		body.AutomaticSize = Enum.AutomaticSize.Y
		body.Parent = row
		Instance.new("UIPadding", row).PaddingBottom = UDim.new(0, 6)
		if tooltip then attachTooltip(row, tooltip) end
		updateSize()
		return row
	end

	function group:toggle(text, default, callback, tooltip)
		local id = generateID()
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 32)
		row.BackgroundTransparency = 1
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
		local cbOuter = Instance.new("TextButton")
		cbOuter.Size = UDim2.new(0, 18, 0, 18)
		cbOuter.Position = UDim2.new(1, -22, 0.5, -9)
		cbOuter.BackgroundColor3 = default and window.theme.Accent or window.theme.Track
		cbOuter.BorderSizePixel = 0
		cbOuter.ZIndex = 4
		cbOuter.Text = ""
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
		local elem = {ID = id, Value = state, DefaultValue = default, IsToggle = true, Mode = "toggle"}
		elem.SetValue = function(val)
			state = val
			elem.Value = state
			cbOuter.BackgroundColor3 = state and window.theme.Accent or window.theme.Track
			cbStroke.Color = state and window.theme.AccentD or window.theme.Border
			cbMark.Text = state and "×" or ""
			if callback then callback(state) end
			if window.configs[id] then window.configs[id].Value = state end
		end
		window.configs[id] = elem
		row.MouseEnter:Connect(function() rh.Visible = true end)
		row.MouseLeave:Connect(function() rh.Visible = false end)
		cbOuter.MouseButton1Click:Connect(function()
			if elem.Mode == "always" then return end
			state = not state
			elem.SetValue(state)
		end)
		row.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				window:showContextMenu(UIS:GetMouseLocation(), elem)
			end
		end)
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

	function group:dropdown(text, options, default, callback, tooltip, refreshCallback)
		local id = generateID()
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 56)
		row.BackgroundTransparency = 1
		row.ClipsDescendants = false
		row.ZIndex = 10
		row.Parent = items
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -60, 0, 18)
		lbl.Position = UDim2.new(0, 4, 0, 2)
		lbl.BackgroundTransparency = 1
		lbl.Text = text
		lbl.TextColor3 = window.theme.GrayLt
		lbl.Font = Enum.Font.Roboto
		lbl.TextSize = 12
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.ZIndex = 11
		lbl.Parent = row

		local refreshBtn = nil
		if refreshCallback then
			refreshBtn = Instance.new("TextButton")
			refreshBtn.Size = UDim2.new(0, 18, 0, 18)
			refreshBtn.Position = UDim2.new(1, -20, 0, 2)
			refreshBtn.BackgroundColor3 = window.theme.Track
			refreshBtn.Text = "↺"
			refreshBtn.TextColor3 = window.theme.Gray
			refreshBtn.Font = Enum.Font.GothamBold
			refreshBtn.TextSize = 13
			refreshBtn.ZIndex = 12
			refreshBtn.Parent = row
			Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 4)
		end

		local dbtn = Instance.new("TextButton")
		dbtn.Size = UDim2.new(1, 0, 0, 32)
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
		arrow.Name = "arrow"
		table.insert(window.accentObjects, arrow)
		arrow.Parent = dbtn
		local listH = #options * 26
		local dlist = Instance.new("ScrollingFrame")
		dlist.Size = UDim2.new(1, 0, 0, math.min(listH, 104))
		dlist.Position = UDim2.new(0, 0, 0, 56)
		dlist.BackgroundColor3 = window.theme.Item
		dlist.BorderSizePixel = 0
		dlist.ScrollBarThickness = 2
		dlist.ScrollBarImageColor3 = window.theme.Accent
		dlist.CanvasSize = UDim2.new(0, 0, 0, listH)
		dlist.Visible = false
		dlist.ZIndex = 50
		dlist.Parent = row
		Instance.new("UICorner", dlist).CornerRadius = UDim.new(0, 4)
		local dstroke2 = Instance.new("UIStroke", dlist)
		dstroke2.Color = window.theme.Border
		dstroke2.Thickness = 1
		local dlayout = Instance.new("UIListLayout", dlist)
		dlayout.SortOrder = Enum.SortOrder.LayoutOrder
		dlayout.Padding = UDim.new(0, 0)

		local checks = {}
		local backgrounds = {}
		local currentOptions = options
		local currentSelection = default
		local open = false

		local function closeDropdown()
			open = false
			dlist.Visible = false
			arrow.Text = "▼"
			row.Size = UDim2.new(1, 0, 0, 56)
			updateSize()
		end

		local function buildOptions(opts)
			for _, child in ipairs(dlist:GetChildren()) do
				if child:IsA("TextButton") then child:Destroy() end
			end
			checks = {}
			backgrounds = {}
			currentOptions = opts
			listH = #opts * 26
			dlist.CanvasSize = UDim2.new(0, 0, 0, listH)
			for _, opt in ipairs(opts) do
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
				bg.Visible = (opt == currentSelection)
				bg.ZIndex = 50
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
				ck.Text = (opt == currentSelection) and "×" or ""
				ck.TextColor3 = window.theme.Accent
				ck.Font = Enum.Font.GothamBold
				ck.TextSize = 12
				ck.ZIndex = 52
				ck.Parent = ob
				checks[opt] = ck
				ob.MouseEnter:Connect(function() oh.Visible = true ol.TextColor3 = window.theme.White end)
				ob.MouseLeave:Connect(function() oh.Visible = false ol.TextColor3 = window.theme.GrayLt end)
				ob.MouseButton1Click:Connect(function()
					currentSelection = opt
					selLbl.Text = opt
					for o, c in pairs(checks) do c.Text = (o == opt) and "×" or "" end
					for o, b in pairs(backgrounds) do b.Visible = (o == opt) end
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
			dlist.Visible = open
			arrow.Text = open and "▲" or "▼"
			row.Size = UDim2.new(1, 0, 0, 56 + (open and math.min(listH, 104) or 0))
			updateSize()
		end)

		local elem = {
			ID = id,
			Value = currentSelection,
			DefaultValue = default,
			Refresh = refresh,
			SetValue = function(val)
				currentSelection = val
				selLbl.Text = val
				for o, c in pairs(checks) do c.Text = (o == val) and "×" or "" end
				for o, b in pairs(backgrounds) do b.Visible = (o == val) end
				if callback then callback(val) end
			end
		}
		window.configs[id] = elem

		row.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				window:showContextMenu(UIS:GetMouseLocation(), elem)
			end
		end)

		if tooltip then attachTooltip(row, tooltip) end
		updateSize()
		return row
	end

	function group:keybind(text, currentName, onChange, tooltip)
		local id = generateID()
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 34)
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
		local kw = math.max(MIN_KEYBIND_WIDTH, math.min(MAX_KEYBIND_WIDTH, math.floor(window.size.X * 0.13)))
		local kbtn = Instance.new("TextButton")
		kbtn.Size = UDim2.new(0, kw, 0, 22)
		kbtn.Position = UDim2.new(1, -(kw + 2), 0.5, -11)
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
		table.insert(window.keybindButtons, kbtn)
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

	function group:button(text, callback, tooltip, align, color)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 32)
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
		label.TextColor3 = color or window.theme.White
		label.Font = Enum.Font.Roboto
		label.TextSize = 13
		label.TextXAlignment = align or Enum.TextXAlignment.Left
		label.ZIndex = 4
		label.Parent = btn
		btn.MouseButton1Click:Connect(callback)
		if tooltip then attachTooltip(btn, tooltip) end
		updateSize()
		return btn
	end

	function group:expandableToggle(text, default, contentFunc, tooltip)
		local container = Instance.new("Frame")
		container.Size = UDim2.new(1, 0, 0, 34)
		container.BackgroundTransparency = 1
		container.ClipsDescendants = true
		container.Parent = items
		local toggleRow = Instance.new("Frame")
		toggleRow.Size = UDim2.new(1, 0, 0, 34)
		toggleRow.BackgroundTransparency = 1
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
		local cbOuter = Instance.new("TextButton")
		cbOuter.Size = UDim2.new(0, 18, 0, 18)
		cbOuter.Position = UDim2.new(1, -22, 0.5, -9)
		cbOuter.BackgroundColor3 = default and window.theme.Accent or window.theme.Track
		cbOuter.BorderSizePixel = 0
		cbOuter.ZIndex = 4
		cbOuter.Text = ""
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
		contentFrame.Position = UDim2.new(0, 0, 0, 34)
		contentFrame.BackgroundTransparency = 1
		contentFrame.Parent = container
		local contentLayout = Instance.new("UIListLayout", contentFrame)
		contentLayout.Padding = UDim.new(0, 2)
		contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
		local function updateContentSize()
			local h = contentLayout.AbsoluteContentSize.Y
			contentFrame.Size = UDim2.new(1, 0, 0, h)
			container.Size = UDim2.new(1, 0, 0, 34 + (default and h or 0))
			updateSize()
		end
		contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateContentSize)
		local nestedGroup = {}
		function nestedGroup:toggle(subText, subDefault, subCallback, subTooltip) local r = group:toggle(subText, subDefault, subCallback, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:slider(subText, min, max, def, subCallback, step, subTooltip) local r = group:slider(subText, min, max, def, subCallback, step, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:dropdown(subText, opts, def, subCallback, subTooltip) local r = group:dropdown(subText, opts, def, subCallback, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:keybind(subText, cur, subCallback, subTooltip) local r = group:keybind(subText, cur, subCallback, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:label(subText, col, subTooltip) local r = group:label(subText, col, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:button(subText, subCallback, subTooltip, al, col) local r = group:button(subText, subCallback, subTooltip, al, col) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:colorpicker(subText, def, subCallback, subTooltip) local r = group:colorpicker(subText, def, subCallback, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:multidropdown(subText, opts, def, subCallback, subTooltip) local r = group:multidropdown(subText, opts, def, subCallback, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:textbox(subText, def, subCallback, subTooltip) local r = group:textbox(subText, def, subCallback, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:numberbox(subText, def, mn, mx, subCallback, subTooltip) local r = group:numberbox(subText, def, mn, mx, subCallback, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:rangeslider(subText, mn, mx, dMin, dMax, subCallback, subTooltip) local r = group:rangeslider(subText, mn, mx, dMin, dMax, subCallback, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		if contentFunc then contentFunc(nestedGroup) end
		local state = default
		cbOuter.MouseButton1Click:Connect(function()
			state = not state
			cbOuter.BackgroundColor3 = state and window.theme.Accent or window.theme.Track
			cbStroke.Color = state and window.theme.AccentD or window.theme.Border
			cbMark.Text = state and "×" or ""
			container.Size = UDim2.new(1, 0, 0, 34 + (state and contentLayout.AbsoluteContentSize.Y or 0))
			updateSize()
		end)
		if tooltip then attachTooltip(toggleRow, tooltip) end
		updateContentSize()
		return container
	end

	function group:collapsible(text, default, contentFunc, tooltip)
		local container = Instance.new("Frame")
		container.Size = UDim2.new(1, 0, 0, 34)
		container.BackgroundTransparency = 1
		container.ClipsDescendants = true
		container.Parent = items
		local toggleRow = Instance.new("TextButton")
		toggleRow.Size = UDim2.new(1, 0, 0, 34)
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
		contentFrame.Position = UDim2.new(0, 0, 0, 34)
		contentFrame.BackgroundTransparency = 1
		contentFrame.Parent = container
		local contentLayout = Instance.new("UIListLayout", contentFrame)
		contentLayout.Padding = UDim.new(0, 2)
		contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
		local function updateContentSize()
			local h = contentLayout.AbsoluteContentSize.Y
			contentFrame.Size = UDim2.new(1, 0, 0, h)
			container.Size = UDim2.new(1, 0, 0, 34 + (default and h or 0))
			updateSize()
		end
		contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateContentSize)
		local nestedGroup = {}
		function nestedGroup:toggle(subText, subDefault, subCallback, subTooltip) local r = group:toggle(subText, subDefault, subCallback, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:slider(subText, min, max, def, subCallback, step, subTooltip) local r = group:slider(subText, min, max, def, subCallback, step, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:dropdown(subText, opts, def, subCallback, subTooltip) local r = group:dropdown(subText, opts, def, subCallback, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:keybind(subText, cur, subCallback, subTooltip) local r = group:keybind(subText, cur, subCallback, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:label(subText, col, subTooltip) local r = group:label(subText, col, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:button(subText, subCallback, subTooltip, al, col) local r = group:button(subText, subCallback, subTooltip, al, col) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:colorpicker(subText, def, subCallback, subTooltip) local r = group:colorpicker(subText, def, subCallback, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:multidropdown(subText, opts, def, subCallback, subTooltip) local r = group:multidropdown(subText, opts, def, subCallback, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:textbox(subText, def, subCallback, subTooltip) local r = group:textbox(subText, def, subCallback, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:numberbox(subText, def, mn, mx, subCallback, subTooltip) local r = group:numberbox(subText, def, mn, mx, subCallback, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		function nestedGroup:rangeslider(subText, mn, mx, dMin, dMax, subCallback, subTooltip) local r = group:rangeslider(subText, mn, mx, dMin, dMax, subCallback, subTooltip) r.Parent = contentFrame updateContentSize() return r end
		if contentFunc then contentFunc(nestedGroup) end
		local state = default
		toggleRow.MouseButton1Click:Connect(function()
			state = not state
			arrow.Text = state and "▼" or "▶"
			container.Size = UDim2.new(1, 0, 0, 34 + (state and contentLayout.AbsoluteContentSize.Y or 0))
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
		row.Size = UDim2.new(1, 0, 0, 50)
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
		box.Size = UDim2.new(1, -8, 0, 22)
		box.Position = UDim2.new(0, 4, 1, -26)
		box.BackgroundColor3 = window.theme.Track
		box.ClipsDescendants = true
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
		local elem = {ID = id, Value = current, DefaultValue = default or "", SetValue = function(val) current = val box.Text = val if callback then callback(val) end window.configs[id].Value = val end}
		window.configs[id] = elem
		row.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				window:showContextMenu(UIS:GetMouseLocation(), elem)
			end
		end)
		if tooltip then attachTooltip(row, tooltip) end
		updateSize()
		return row
	end

	function group:numberbox(text, default, min, max, callback, tooltip)
		min = min or -math.huge
		max = max or math.huge
		local id = generateID()
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 50)
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
		box.ClipsDescendants = true
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
		local elem = {ID = id, Value = current, DefaultValue = default or 0, SetValue = function(val) val = math.clamp(val, min, max) current = val box.Text = tostring(val) if callback then callback(val) end window.configs[id].Value = val end}
		window.configs[id] = elem
		row.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				window:showContextMenu(UIS:GetMouseLocation(), elem)
			end
		end)
		if tooltip then attachTooltip(row, tooltip) end
		updateSize()
		return row
	end

	function group:rangeslider(text, minVal, maxVal, defaultMin, defaultMax, callback, tooltip)
		local id = generateID()
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 50)
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
		track.Position = UDim2.new(0, 0, 0, 32)
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
		local rsInputConn = UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then apply(i.Position.X, dragType) end end)
		local rsEndConn = UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
		table.insert(window.connections, rsInputConn)
		table.insert(window.connections, rsEndConn)
		local elem = {ID = id, Value = {currentMin, currentMax}, DefaultValue = {defaultMin, defaultMax}, SetValue = function(t) currentMin, currentMax = t[1], t[2]; updateDisplay() if callback then callback(currentMin, currentMax) end window.configs[id].Value = {currentMin, currentMax} end}
		window.configs[id] = elem
		row.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				window:showContextMenu(UIS:GetMouseLocation(), elem)
			end
		end)
		if tooltip then attachTooltip(row, tooltip) end
		updateSize()
		return row
	end

	return group
end

return UILib
