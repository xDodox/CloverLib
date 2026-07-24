local UILib = {}
UILib.__index = UILib


UILib.Tab = {}
UILib.Tab.__index = UILib.Tab

UILib.SubTab = {}
UILib.SubTab.__index = UILib.SubTab

UILib.Column = {}
UILib.Column.__index = UILib.Column

local _raw_cloneref = cloneref
local function cloneref(ref)
	if _raw_cloneref then
		local ok, result = pcall(_raw_cloneref, ref)
		if ok then return result end
	end
	return ref
end
local UIS = cloneref(game:GetService("UserInputService"))
local HS = cloneref(game:GetService("HttpService"))
local Players = cloneref(game:GetService("Players"))
local LP = Players.LocalPlayer
local TweenService = cloneref(game:GetService("TweenService"))
local RunService = cloneref(game:GetService("RunService"))

local function cleanNum(n)
	if type(n) ~= "number" then return tostring(n) end
	if n == math.floor(n) then return tostring(math.floor(n)) end
	return string.format("%.4g", n)
end

local allWindows = {}
local _configLoading = false

local LUCIDE_ICONS = nil

local function tryParseIcons(src)
	if type(src) ~= "string" or src == "" then return nil end
	local ok, fn = pcall(loadstring, src)
	if ok and type(fn) == "function" then
		local data = fn()
		if type(data) == "table" and data.assets then return data end
	end
	ok, fn = pcall(loadstring, "return " .. src)
	if ok and type(fn) == "function" then
		local data = fn()
		if type(data) == "table" and data.assets then return data end
	end
	return nil
end

local function fetchUrl(url)
	local req = (syn and syn.request) or (http and http.request) or http_request or (Fluxus and Fluxus.request) or request
	if req then
		local ok, res = pcall(req, { Url = url, Method = "GET" })
		if ok and type(res) == "table" then
			return res.Body or res.body or res["Body"] or nil
		end
	end
	local ok, body = pcall(game.GetService, game, "HttpService")
	if ok then
		ok, body = pcall(function() return game:GetService("HttpService"):GetAsync(url) end)
		if ok then return body end
	end
	return nil
end

local function ensureIcons()
	if LUCIDE_ICONS then return LUCIDE_ICONS end
	local body = fetchUrl("https://cloverhub.fun/scripts/Icons.lua")
	if body then
		local data = tryParseIcons(body)
		if data then LUCIDE_ICONS = data; return data end
	end
	return nil
end

function UILib.lucide(nameOrSelf, maybeName)
	local name = maybeName or nameOrSelf
	if type(name) ~= "string" then return nil end
	local icons = ensureIcons()
	if icons and icons.assets then
		return icons.assets["lucide-" .. name:lower()]
	end
	return nil
end

function UILib.resolveIcon(icon)
	if not icon then return nil end
	local s = tostring(icon)
	local lucideName = s:match("^lucide:(.+)$")
	if lucideName then
		return UILib.lucide(lucideName)
	end
	if not s:find("^https?://") and not s:find("rbxassetid://") then
		s = "rbxassetid://" .. s
	end
	return s
end

function UILib:SafeCallback(fn, ...)
	if not fn then return end
	local ok, err = pcall(fn, ...)
	if not ok then
		print("[CloverLib] Callback error:", err)
		if self and self.notify then
			self:notify("Script error — check console", "error", 5)
		end
	end
end

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
	GrayLt  = Color3.fromRGB(200, 200, 200),
}

local NOTIF_COLORS = {
	info = Color3.fromRGB(50, 150, 255),
	success = Color3.fromRGB(0, 255, 163),
	error = Color3.fromRGB(255, 70, 70),
	warning = Color3.fromRGB(255, 180, 50),
}

local function makeTooltipSystem(sg, theme, connections)
	local tooltipFrame                                  = Instance.new("Frame")
	tooltipFrame.BackgroundColor3                       = theme.Panel
	tooltipFrame.BorderSizePixel                        = 0
	tooltipFrame.Visible                                = false
	tooltipFrame.ZIndex                                 = 10000
	tooltipFrame.Parent                                 = sg
	Instance.new("UICorner", tooltipFrame).CornerRadius = UDim.new(0, 4)
	local tipStroke = Instance.new("UIStroke", tooltipFrame)
	tipStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	tipStroke.Color = theme.Border
	tipStroke.Thickness = 1
	local tipPadding                                    = Instance.new("UIPadding", tooltipFrame)
	tipPadding.PaddingLeft                              = UDim.new(0, 10)
	tipPadding.PaddingRight                             = UDim.new(0, 10)
	tipPadding.PaddingTop                               = UDim.new(0, 8)
	tipPadding.PaddingBottom                            = UDim.new(0, 8)
	local tooltipText                                   = Instance.new("TextLabel")
	tooltipText.Size                                    = UDim2.new(1, 0, 1, 0)
	tooltipText.BackgroundTransparency                  = 1
	tooltipText.TextColor3                              = theme.White
	tooltipText.Font                                    = Enum.Font.GothamSemibold
	tooltipText.TextSize                                = 12
	tooltipText.TextWrapped                             = true
	tooltipText.ZIndex                                  = 1001
	tooltipText.Parent                                  = tooltipFrame

	local tooltipActiveElement                          = nil

	local function showTooltip(text, element)
		if not element or not text or text == "" then return end
		tooltipText.Text     = text
		tooltipActiveElement = element
		local screenWidth    = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 1920
		local screenHeight   = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 1080
		local textWidth      = 200
		local tipW, tipH     = textWidth + 30, 36
		pcall(function()
			local ts = game:GetService("TextService"):GetTextSize(text, 12, Enum.Font.GothamSemibold, Vector2.new(textWidth, 500))
			tipW = textWidth + 24
			tipH = ts.Y + 18
		end)
		tooltipFrame.Size    = UDim2.new(0, tipW, 0, tipH)
		local ePos = element.AbsolutePosition or Vector2.new(200, 200)
		local eSize = element.AbsoluteSize or Vector2.new(14, 14)
		local targetX = ePos.X + eSize.X / 2 - tipW / 2
		local targetY = ePos.Y + eSize.Y + 4
		if targetY + tipH > screenHeight - 8 then targetY = ePos.Y - tipH - 4 end
		targetX = math.clamp(targetX, 8, screenWidth - tipW - 8)
		targetY = math.clamp(targetY, 8, screenHeight - tipH - 8)
		tooltipFrame.Position = UDim2.new(0, targetX, 0, targetY)
		tooltipFrame.Visible = true
	end

	local function hideTooltip()
		tooltipFrame.Visible = false
		tooltipActiveElement = nil
	end

	return { show = showTooltip, hide = hideTooltip, frame = tooltipFrame }
end

function UILib:notify(message, notifType, duration)
	if self._loadingConfig then return end
	notifType = notifType or "info"
	duration = duration or 3
	if not self.notifications then self.notifications = {} end
	if not self.notifQueue then self.notifQueue = {} end
	for i = #self.notifications, 1, -1 do
		if not self.notifications[i] or not self.notifications[i].Parent then
			table.remove(self.notifications, i)
		end
	end
	local MAX_NOTIFS = 8
	if #self.notifications >= MAX_NOTIFS then
		table.insert(self.notifQueue, { message = message, notifType = notifType, duration = duration })
		return
	end
	local accentColor = NOTIF_COLORS[notifType] or NOTIF_COLORS.info
	local index = #self.notifications + 1
	local yPos = 10 + (index - 1) * 50
	local NOTIF_W = 260
	local notif = Instance.new("Frame")
	notif.Size = UDim2.new(0, NOTIF_W, 0, 42)
	notif.AnchorPoint = Vector2.new(0, 1)
	notif.Position = UDim2.new(1, 0, 1, -yPos)
	notif.BackgroundColor3 = self.theme.Surface
	notif.BorderSizePixel = 0
	notif.ZIndex = 500
	notif.Parent = self.sg
	notif.ClipsDescendants = true
	Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 8)

	local accentBar = Instance.new("Frame")
	accentBar.Size = UDim2.new(0, 5, 1, 0)
	accentBar.BackgroundColor3 = accentColor
	accentBar.BorderSizePixel = 0
	accentBar.ZIndex = 502
	accentBar.Parent = notif

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -16, 1, -8)
	label.Position = UDim2.new(0, 12, 0, 4)
	label.BackgroundTransparency = 1
	label.Text = message
	label.TextColor3 = self.theme.White
	label.Font = Enum.Font.GothamSemibold
	label.TextSize = 13
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.ZIndex = 501
	label.Parent = notif

	local progressBar = Instance.new("Frame")
	progressBar.Size = UDim2.new(1, 0, 0, 2)
	progressBar.Position = UDim2.new(0, 0, 1, -2)
	progressBar.BackgroundColor3 = accentColor
	progressBar.BackgroundTransparency = 0.65
	progressBar.BorderSizePixel = 0
	progressBar.ZIndex = 503
	progressBar.Parent = notif

	table.insert(self.notifications, notif)
	local targetX = UDim2.new(1, -(NOTIF_W + 10), 1, -yPos)
	notif.Position = UDim2.new(1, 0, 1, -yPos)
	local tweenIn = TweenService:Create(notif, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = targetX })
	tweenIn:Play()
	TweenService:Create(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) }):Play()
	task.delay(duration, function()
		task.defer(function()
		if not notif or not notif.Parent then return end
		local out = TweenService:Create(notif, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(1, 0, 1, -yPos), BackgroundTransparency = 0.3 })
		out:Play()
		out.Completed:Connect(function()
			if notif and notif.Parent then notif:Destroy() end
			if self.notifications then
				for i = #self.notifications, 1, -1 do
					if self.notifications[i] == notif or not self.notifications[i] or not self.notifications[i].Parent then
						table.remove(self.notifications, i)
					end
				end
				if self.notifQueue and #self.notifQueue > 0 then
					local next = table.remove(self.notifQueue, 1)
					task.defer(function() self:notify(next.message, next.notifType, next.duration) end)
				end
				for i, n in ipairs(self.notifications) do
					if n and n.Parent then
						local newY = 10 + (i - 1) * 50
						TweenService:Create(n, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							Position = UDim2.new(1, -(NOTIF_W + 10), 1, -newY)
						}):Play()
					end
				end
			end
		end)
	end)
end)
end

function UILib:getConfigDir()
	local gameName = (game and game.Name and game.Name ~= "" and game.Name) or "Unknown"
	gameName = gameName:gsub("[^%w%s%-_]", ""):gsub("%s+", "_"):sub(1, 40)
	local scriptName = (self.title and self.title ~= "" and self.title) or "CloverHub"
	scriptName = scriptName:gsub("[^%w%s%-_]", ""):gsub("%s+", "_"):sub(1, 40)
	local dir = "Clover/" .. gameName .. "/" .. scriptName .. "/"
	pcall(makefolder, "Clover")
	pcall(makefolder, "Clover/" .. gameName)
	pcall(makefolder, "Clover/" .. gameName .. "/" .. scriptName)
	return dir
end

function UILib:saveConfig(name)
	local data = {}
	if not self.configs then return end
	for id, elem in pairs(self.configs) do
		if elem.Value ~= nil and not elem._noConfig then
			if typeof(elem.Value) == "Color3" then
				data[id] = {__type = "Color3", r = elem.Value.r, g = elem.Value.g, b = elem.Value.b}
			else
				data[id] = elem.Value
			end
		end
	end
	local json = HS:JSONEncode(data)
	local path = self:getConfigDir() .. name .. ".json"
	local success, err = pcall(writefile, path, json)
	if success then
		self:notify("Saved: " .. name, "success")
	else
		self:notify("Save failed: " .. tostring(err), "error")
	end
end

function UILib:loadConfig(name)
	local path = self:getConfigDir() .. name .. ".json"
	local success, content = pcall(readfile, path)
	if not success then
		self:notify("Not found: " .. name, "error")
		return
	end
	local ok, data = pcall(HS.JSONDecode, HS, content)
	if not ok or not data then
		self:notify("Invalid config", "error")
		return
	end
	self._loadingConfig = true
	for id, value in pairs(data) do
		if self.configs and self.configs[id] and not self.configs[id]._noConfig then
			if type(value) == "table" and value.__type == "Color3" then
				local colorVal = Color3.new(value.r or 1, value.g or 0, value.b or 0)
				local elem = self.configs[id]
				pcall(function() elem:SetColor(colorVal) end)
			else
				local elem = self.configs[id]
				if elem.SetValue then
					if elem._confirmMessage then
						elem.Value = value
						if elem.frame then
							local cbOuter = elem.frame:FindFirstChildOfClass("TextButton")
							if cbOuter then
								cbOuter.BackgroundColor3 = value and self.theme.Accent or self.theme.BG
								local stroke = cbOuter:FindFirstChildOfClass("UIStroke")
								if stroke then stroke.Color = value and self.theme.AccentD or self.theme.Border end
								local mark = cbOuter:FindFirstChildOfClass("TextLabel")
								if mark then mark.Text = value and "X" or "" end
							end
						end
					else
						pcall(elem.SetValue, value, true)
					end
				end
			end
		end
	end
	self._loadingConfig = nil
	if name ~= "autosave" then
		self:notify("Loaded: " .. name, "success")
	end
end

function UILib:deleteConfig(name)
	local path = self:getConfigDir() .. name .. ".json"
	local success = pcall(delfile, path)
	if success then
		self:notify("Deleted: " .. name, "success")
	else
		self:notify("Delete failed", "error")
	end
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

function UILib:exportConfigToString()
	local data = {}
	if not self.configs then return nil end
	for id, elem in pairs(self.configs) do
		if elem.Value ~= nil and not elem._noConfig then
			local label = ""
			if elem.frame then
				for _, child in ipairs(elem.frame:GetChildren()) do
					if child:IsA("TextLabel") and child.Text and child.Text ~= "" then
						label = child.Text
						break
					end
				end
			end
			if typeof(elem.Value) == "Color3" then
				data[id] = {value = {__type = "Color3", r = elem.Value.r, g = elem.Value.g, b = elem.Value.b}, _label = label}
			else
				data[id] = {value = elem.Value, _label = label}
			end
		end
	end
	local json = HS:JSONEncode(data)
	local success = pcall(setclipboard, json)
	if success then
		self:notify("Config copied to clipboard!", "success")
	else
		self:notify("Clipboard not supported on this executor", "error")
	end
	return json
end

function UILib:importConfigFromString(json)
	if not json or json == "" then return end
	local ok, data = pcall(HS.JSONDecode, HS, json)
	if not ok or not data then
		self:notify("Invalid config data", "error")
		return
	end
	local count = 0
	self._loadingConfig = true
	for id, value in pairs(data) do
		if self.configs and self.configs[id] and not self.configs[id]._noConfig then
			local raw
			if type(value) == "table" and value.value ~= nil then
				raw = value.value
			else
				raw = value
			end
			if type(raw) == "table" and raw.__type == "Color3" then
				local colorVal = Color3.new(raw.r or 1, raw.g or 0, raw.b or 0)
				local elem = self.configs[id]
				if elem._confirmMessage then
					elem.Value = colorVal
					local colorBox = elem.frame and elem.frame:FindFirstChild("Frame", true)
					if colorBox and colorBox:IsA("Frame") then colorBox.BackgroundColor3 = colorVal end
				else
					pcall(elem.SetValue, colorVal, true)
				end
			else
				local elem = self.configs[id]
				if elem._confirmMessage then
					elem.Value = raw
					if elem.frame then
						local cbOuter = elem.frame:FindFirstChildOfClass("TextButton")
						if cbOuter then
							cbOuter.BackgroundColor3 = raw and self.theme.Accent or self.theme.BG
							local st = cbOuter:FindFirstChildOfClass("UIStroke")
							if st then st.Color = raw and self.theme.AccentD or self.theme.Border end
							local mk = cbOuter:FindFirstChildOfClass("TextLabel")
							if mk then mk.Text = raw and "X" or "" end
						end
					end
				else
					pcall(elem.SetValue, raw, true)
				end
			end
			count = count + 1
		end
	end
	self._loadingConfig = nil
end

-- ════════════════════════════════════════
-- Structured Config — category-based JSON
-- ════════════════════════════════════════
function UILib:getElementLabel(elem)
	if elem.label then return elem.label end
	if elem._label then return elem._label end
	if elem.frame then
		local best = nil
		for _, child in ipairs(elem.frame:GetDescendants()) do
			if child:IsA("TextLabel") and child.Visible and child.Text ~= "" then
				local t = child.Text
				if tonumber(t) then continue end
				if #t <= 2 then continue end
				if t == "None" then continue end
				if not best or child.TextSize > best.TextSize then best = child end
			end
		end
		if best then elem._label = best.Text; return elem._label end
	end
	return nil
end

function UILib:getElementType(elem)
	if elem.IsToggle then return "Toggle" end
	if elem._mode == "keybind" then return "Keybind" end
	if typeof(elem.Value) == "Color3" then return "ColorPicker" end
	if elem._isRange then return "RangeSlider" end
	if type(elem.Value) == "number" and elem.DefaultHeight and elem._isSlider ~= false then
		if elem._isNumber then return "NumberBox" end
		return "Slider"
	end
	if type(elem.Value) == "table" and not elem._display then return "MultiDropdown" end
	if type(elem.Value) == "string" and elem._values then return "Dropdown" end
	if type(elem.Value) == "string" and elem.DefaultHeight then return "TextBox" end
	return nil
end

UILib.Parser = {
	Toggle = {
		Save = function(label, elem)
			return { type = "Toggle", label = label, value = elem.Value == true }
		end,
		Load = function(data, elem)
			local v = data.value
			if type(v) == "table" then v = v[1] end
			if type(v) == "boolean" then
				elem.SetValue(v)
			else
				elem.SetValue(tostring(v or ""))
			end
		end,
	},
	Slider = {
		Save = function(label, elem)
			return { type = "Slider", label = label, value = tonumber(elem.Value) or 0 }
		end,
		Load = function(data, elem)
			local v = data.value
			local n = tonumber(type(v) == "table" and v[1] or v) or 0
			pcall(elem.SetValue, n)
		end,
	},
	Dropdown = {
		Save = function(label, elem)
			return { type = "Dropdown", label = label, value = tostring(elem.Value) }
		end,
		Load = function(data, elem)
			local v = data.value
			if type(v) == "table" then v = v[1] end
			elem.SetValue(tostring(v or ""))
		end,
	},
	MultiDropdown = {
		Save = function(label, elem)
			local clean = {}
			if type(elem.Value) == "table" then
				for k, v in pairs(elem.Value) do
					if type(k) == "number" then
						table.insert(clean, tostring(v))
					else
						table.insert(clean, tostring(k))
					end
				end
			end
			return { type = "MultiDropdown", label = label, value = clean }
		end,
		Load = function(data, elem)
			if data.value then
				local v = data.value
				if type(v) == "table" and #v > 0 and type(v[1]) == "table" then v = v[1] end
				elem.SetValue(v)
			end
		end,
	},
	ColorPicker = {
		Save = function(label, elem)
			local val = elem.Value
			if typeof(val) == "Color3" then
				return { type = "ColorPicker", label = label, color = { math.floor(val.R * 255), math.floor(val.G * 255), math.floor(val.B * 255) } }
			end
			return nil
		end,
		Load = function(data, elem)
			if data.color then
				local c = data.color
				local r = tonumber(type(c[1]) == "table" and c[1][1] or c[1]) or 0
				local g = tonumber(type(c[2]) == "table" and c[2][1] or c[2]) or 0
				local b = tonumber(type(c[3]) == "table" and c[3][1] or c[3]) or 0
				elem.SetValue(Color3.new(r / 255, g / 255, b / 255))
			end
		end,
	},
	Keybind = {
		Save = function(label, elem)
			return { type = "Keybind", label = label, value = tostring(elem.Value) }
		end,
		Load = function(data, elem)
			local v = data.value
			if type(v) == "table" then v = v[1] end
			elem.SetValue(tostring(v or ""))
		end,
	},
	TextBox = {
		Save = function(label, elem)
			return { type = "TextBox", label = label, value = tostring(elem.Value) }
		end,
		Load = function(data, elem)
			local v = data.value
			if type(v) == "table" then v = v[1] end
			elem.SetValue(tostring(v or ""))
		end,
	},
	NumberBox = {
		Save = function(label, elem)
			return { type = "NumberBox", label = label, value = tonumber(elem.Value) or 0 }
		end,
		Load = function(data, elem)
			local v = type(data.value) == "table" and data.value[1] or data.value
			elem.SetValue(tonumber(v) or 0)
		end,
	},
	RangeSlider = {
		Save = function(label, elem)
			local v = elem.Value
			local a, b = tonumber(type(v[1]) == "table" and v[1][1] or v[1]) or 0, tonumber(type(v[2]) == "table" and v[2][1] or v[2]) or 0
			return { type = "RangeSlider", label = label, min = a, max = b }
		end,
		Load = function(data, elem)
			local lo = tonumber(type(data.min) == "table" and data.min[1] or data.min) or 0
			local hi = tonumber(type(data.max) == "table" and data.max[1] or data.max) or 0
			elem.SetValue({ lo, hi })
		end,
	},
}

	local function _buildLabelMap(self)
	local map = {}
	for id, elem in pairs(self.configs) do
		local label = self:getElementLabel(elem)
		if label and not elem._noConfig and not (self.configIgnore and self.configIgnore[label]) then
			map[label] = elem
		end
	end
	return map
end

local function _configStructuredToJSON(self)
	local data = { _version = 3, _timestamp = os.time(), objects = {} }
	for id, elem in pairs(self.configs) do
		if elem._noConfig then continue end
		local val = elem.Value
		if val == nil then continue end
		local label = self:getElementLabel(elem) or id
		if self.configIgnore and self.configIgnore[label] then continue end
		local etype = self:getElementType(elem)
		if not etype then continue end
		local parser = UILib.Parser[etype]
		if parser then
			local obj = parser.Save(label, elem)
			if obj then table.insert(data.objects, obj) end
		end
	end
	return HS:JSONEncode(data)
end

local function _applyStructuredJSON(self, decoded)
	local labelMap = _buildLabelMap(self)
	local count = 0
	self._loadingConfig = true
	_configLoading = true

	if decoded.objects then
		for _, obj in ipairs(decoded.objects) do
			local elem = labelMap[obj.label]
			if not elem then continue end
			local parser = UILib.Parser[obj.type]
			if not parser then continue end
			pcall(parser.Load, obj, elem)
			count = count + 1
		end
	else
		local legacyTypes = { Toggle = "state", Slider = "value", Dropdown = "value", MultiDropdown = "value", ColorPicker = "color", TextBox = "text", Keybind = "keybind" }
		for etype, items in pairs(decoded) do
			if type(items) ~= "table" then continue end
			if etype:sub(1, 1) == "_" then continue end
			local parser = UILib.Parser[etype]
			if not parser then continue end
			for label, sdata in pairs(items) do
				local elem = labelMap[label]
				if not elem then continue end
				local legacyField = legacyTypes[etype] or etype:lower()
				local obj = { type = etype, label = label, value = sdata[legacyField], color = sdata.color }
				local ok = pcall(parser.Load, obj, elem)
				if ok then count = count + 1 end
			end
		end
	end

	self._loadingConfig = nil
	_configLoading = false
	task.wait(0.05)
	_configLoading = true
	self._loadingConfig = true
	for id, elem in pairs(self.configs) do
		local label = self:getElementLabel(elem)
		if label and not (self.configIgnore and self.configIgnore[label]) and not elem._noConfig then
			local etype = self:getElementType(elem)
			if etype == "Toggle" or etype == "Dropdown" or etype == "ColorPicker" then
				pcall(elem.SetValue, elem.Value)
			end
		end
	end
	_configLoading = false
	self._loadingConfig = nil
	return count
end

function UILib:ignoreConfig(...)
	if not self.configIgnore then self.configIgnore = {} end
	for i = 1, select("#", ...) do
		self.configIgnore[select(i, ...)] = true
	end
end

function UILib:getConfigDir()
	local gameName = (game and game.Name and game.Name ~= "" and game.Name) or "Unknown"
	gameName = gameName:gsub("[^%w%s%-_]", ""):gsub("%s+", "_"):sub(1, 40)
	local dir = "CloverHub/configs/" .. gameName .. "/"
	pcall(makefolder, "CloverHub/configs")
	pcall(makefolder, dir)
	return dir
end

function UILib:saveConfigStructured(name)
	local json = _configStructuredToJSON(self)
	local dir = self:getConfigDir()
	local ok, err = pcall(writefile, dir .. name .. ".json", json)
	if ok then self:notify("Saved: " .. name, "success", 2) else self:notify("Save failed: " .. tostring(err), "error", 3) end
end

function UILib:loadConfigStructured(name)
	local path = self:getConfigDir() .. name .. ".json"
	local ok, content = pcall(readfile, path)
	if not ok then self:notify("Not found: " .. name, "error", 3); return end
	local decoded = HS:JSONDecode(content)
	if type(decoded) ~= "table" then self:notify("Invalid config", "error", 3); return end
	_applyStructuredJSON(self, decoded)
	self:notify("Loaded: " .. name, "success", 2)
end

function UILib:exportConfigStructured()
	local json = _configStructuredToJSON(self)
	pcall(setclipboard, json)
	self:notify("Config copied to clipboard!", "success", 2)
end

function UILib:importConfigStructured(json)
	local ok, decoded = pcall(HS.JSONDecode, HS, json)
	if not ok or type(decoded) ~= "table" then self:notify("Invalid JSON", "error", 3); return end
	_applyStructuredJSON(self, decoded)
end

function UILib:listConfigsStructured()
	local list = {}
	local dir = self:getConfigDir()
	local ok, files = pcall(listfiles, dir)
	if ok and files then
		for _, f in ipairs(files) do
			local name = f:match("([^/\\]+)%.json$")
			if name then table.insert(list, name) end
		end
	end
	return list
end

function UILib:getAutoLoadConfig()
	local ok, name = pcall(readfile, self:getConfigDir() .. "_autoload.txt")
	if ok and name and name ~= "" then return name end
	return nil
end

function UILib:setAutoLoadConfig(name)
	pcall(makefolder, self:getConfigDir())
	pcall(writefile, self:getConfigDir() .. "_autoload.txt", name or "")
end

function UILib:tryAutoLoad()
	local name = self:getAutoLoadConfig()
	if name then
		task.wait(0.5)
		local path = self:getConfigDir() .. name .. ".json"
		if isfile and isfile(path) then
			self:loadConfigStructured(name)
			self:notify("Auto-loaded: " .. name, "success", 3)
		end
	end
end

function UILib.new(opts)
	opts = opts or {}
	local theme = {}
	if opts.Accent then theme.Accent = opts.Accent end
	return UILib.newWindow(
		opts.Title or opts.title or "Window",
		opts.Size or opts.size or UDim2.new(0, 500, 0, 400),
		theme,
		nil,
		opts.showVersion ~= false,
		opts.includeUITab,
		opts.showLogo ~= false,
		opts.uiTabIcon ~= false and (opts.uiTabIcon or "lucide:monitor")
	)
end

	local MIN_KEYBIND_WIDTH = 52
local MAX_KEYBIND_WIDTH = 76

function UILib.newWindow(title, size, theme, parent, showVersion, includeUITab, showLogo, uiTabIcon)
	local self = setmetatable({}, UILib)
	self.theme = theme or {}
	for k, v in pairs(DEFAULT_THEME) do if self.theme[k] == nil then self.theme[k] = v end end
	self.size = type(size.X) == "number" and size or Vector2.new(size.X.Offset, size.Y.Offset)
	self.title = title
	self.parent = parent or (gethui and gethui()) or LP:WaitForChild("PlayerGui")
	self.connections = {}
	self.showVersion = showVersion ~= false
	self.showLogo = showLogo ~= false
	self.uiTabIcon = uiTabIcon
	self.configs = {}
	self.resizing = nil
	self.toggleKey = Enum.KeyCode.RightShift
	self.watermark = nil
	self.notifications = {}
	self.configPrefix = "clover_"
	self.accentObjects = {}
	self.accentDarkObjects = {}
	self.rainbowElements = {}
	self.pulseElements = {}
	self.keybindButtons = {}
	self._dirty = false
	self._autosaveConn = nil

	self.allSubTabs = {}
	self.activePopups = {}

	function self:updateAccent(color)
		self.theme.Accent = color
		self.theme.AccentD = Color3.new(color.r * 0.70, color.g * 0.70, color.b * 0.70)
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
				elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
					obj.ImageColor3 = color
				elseif obj:IsA("UIGradient") then
					obj.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, color),
						ColorSequenceKeypoint.new(1, Color3.new(color.r * 0.8, color.g * 0.8, color.b * 0.8))
					})
				end
			end)
		end
		local dark = Color3.new(color.r * 0.55, color.g * 0.55, color.b * 0.55)
		for _, obj in ipairs(self.accentDarkObjects) do
			pcall(function() obj.BackgroundColor3 = dark end)
		end
		for _, t in pairs(self.tabs) do
			if t.tabIcon and t.tabIconId then
				pcall(function() t.tabIcon.ImageColor3 = t == self.activeTab and color or self.theme.Gray end)
			end
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
	local function generateRandomName()
		local length = math.random(10, 16)
		local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
		local name = ""
		for i = 1, length do
			local rand = math.random(1, #chars)
			name = name .. chars:sub(rand, rand)
		end
		return name
	end
	self.sg.Name = generateRandomName()
	self.sg.ResetOnSpawn = false
	self.sg.IgnoreGuiInset = true
	self.sg.Parent = self.parent
	self.sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	self.sg.Destroying:Connect(function()
		pcall(function() self:Destroy() end)
	end)

	self.tooltip = makeTooltipSystem(self.sg, self.theme, self.connections)

	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
	if vp.X < 800 then
		self.size = Vector2.new(math.max(300, vp.X - 12), math.max(260, math.min(self.size.Y, math.min(vp.Y - 30, 520))))
	end
	local win = Instance.new("Frame")
	win.Size = UDim2.new(0, self.size.X, 0, self.size.Y)
	win.Position = UDim2.new(0.5, 0, 0.5, 0)
	win.BackgroundColor3 = self.theme.BG
	win.BorderSizePixel = 0
	win.Parent = self.sg
	win.Active = true
	win.Selectable = false
	win.AnchorPoint = Vector2.new(0.5, 0.5)
	win.ClipsDescendants = true
	win.Visible = false
	self.uiScale = Instance.new("UIScale", win)
	Instance.new("UICorner", win).CornerRadius = UDim.new(0, 10)
	self.window = win

	local animOverlay = Instance.new("Frame")
	animOverlay.Size = UDim2.new(1, 0, 1, 0)
	animOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
	animOverlay.BackgroundTransparency = 0
	animOverlay.BorderSizePixel = 0
	animOverlay.ZIndex = 999
	animOverlay.Parent = win
	self._animOverlay = animOverlay

	local winStrokeFrame = Instance.new("Frame")
	winStrokeFrame.Name = "WindowStrokeFrame"
	winStrokeFrame.Size = UDim2.new(1, 0, 1, 0)
	winStrokeFrame.Position = UDim2.new(0, 0, 0, 0)
	winStrokeFrame.BackgroundTransparency = 1
	winStrokeFrame.ZIndex = 100
	winStrokeFrame.Parent = win
	Instance.new("UICorner", winStrokeFrame).CornerRadius = UDim.new(0, 10)
	local winStroke = Instance.new("UIStroke", winStrokeFrame)
	winStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	winStroke.Color = Color3.fromRGB(40, 40, 40)
	winStroke.Thickness = 1
	self.originalPosition = win.Position
	self.originalSize = win.Size
	self.visibleTarget = false

	self.sidebarWidth = 140
	local function getSidebarWidth()
		return self.sidebarWidth
	end
	self.getSidebarWidth = getSidebarWidth

	local function updateLayout()
		local sw = getSidebarWidth()
		local showSidebar = not self.activeTab or self.activeTab.showSidebar ~= false
		if self.sidebar then
			self.sidebar.Size = UDim2.new(0, sw, 1, -92)
			self.sidebar.Visible = showSidebar
			for _, sub in ipairs(self.allSubTabs) do
				if sub.btn then
					sub.btn.Position = UDim2.new(0, 4, 0, 0)
				end
			end
		end
		if self.sidebarEdge then
			self.sidebarEdge.Visible = showSidebar
			self.sidebarEdge.Position = UDim2.new(0, sw, 0, 46)
			self.sidebarEdge.Size = UDim2.new(0, 1, 1, -92)
		end
		if self.content then
			local offset = showSidebar and (sw + 1) or 0
			local contentW = showSidebar and (self.size.X - sw - 1) or self.size.X
			self.content.Size = UDim2.new(0, contentW, 1, -92)
			self.content.Position = UDim2.new(0, offset, 0, 46)
		end

		if self.hamburgerBtn then self.hamburgerBtn.Visible = false end
		if self.refreshTabWidths then self.refreshTabWidths() end
	end
	self.updateLayout = updateLayout



	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 46)
	header.BackgroundColor3 = self.theme.Panel
	header.BackgroundTransparency = 0
	header.BorderSizePixel = 0
	header.ZIndex = 5
	header.Parent = win
	self.header = header
	Instance.new("UICorner", header).CornerRadius = UDim.new(0, 10)
	local headerCover = Instance.new("Frame")
	headerCover.Size = UDim2.new(1, 0, 0, 10)
	headerCover.Position = UDim2.new(0, 0, 1, -10)
	headerCover.BackgroundColor3 = header.BackgroundColor3
	headerCover.BorderSizePixel = 0
	headerCover.ZIndex = 6
	headerCover.Parent = header
	self.headerCover = headerCover
	local headerLine = Instance.new("Frame")
	headerLine.Size = UDim2.new(1, 0, 0, 2)
	headerLine.Position = UDim2.new(0, 0, 1, -2)
	headerLine.BackgroundColor3 = self.theme.Accent
	headerLine.BorderSizePixel = 0
	headerLine.ZIndex = 7
	headerLine.Parent = header
	table.insert(self.accentObjects, headerLine)

	local uiScale = self.uiScale

	local function updateScaling()
		local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
		self._targetScale = math.min(vp.X / self.size.X, (vp.Y - 40) / self.size.Y, 1)
		if self.visibleTarget ~= false then uiScale.Scale = self._targetScale end
	end
	table.insert(self.connections,
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScaling))
	updateScaling()
	table.insert(self.connections,
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			task.defer(function() self:updateLayout() end)
		end))

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

	if self.showLogo then
		local logo = Instance.new("ImageLabel")
		logo.Size = UDim2.new(0, 28, 0, 28)
		logo.BackgroundTransparency = 1
		logo.Image = "rbxassetid://128385522450957"
		logo.ZIndex = 60
		logo.LayoutOrder = 0
		logo.Parent = titleRow
		logo.Visible = true
	end

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
		versionLabel.TextColor3 = Color3.fromRGB(10, 10, 10)
		versionLabel.Font = Enum.Font.GothamBold
		versionLabel.TextSize = 10
		versionLabel.ZIndex = 7
		versionLabel.Parent = versionPill
		self.versionLabel = versionLabel
	end

	-- Player info card (top-right of header)
	local playerCard = Instance.new("Frame")
	playerCard.Size = UDim2.new(0, 140, 0, 36)
	playerCard.Position = UDim2.new(1, -8, 0.5, 0)
	playerCard.AnchorPoint = Vector2.new(1, 0.5)
	playerCard.BackgroundTransparency = 1
	playerCard.ZIndex = 6
	playerCard.Parent = header

	local pcLayout = Instance.new("UIListLayout", playerCard)
	pcLayout.FillDirection = Enum.FillDirection.Horizontal
	pcLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	pcLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	pcLayout.Padding = UDim.new(0, 6)

	-- Avatar thumbnail (right side, loaded async)
	local avatarImg = Instance.new("ImageLabel")
	avatarImg.Size = UDim2.new(0, 30, 0, 30)
	avatarImg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	avatarImg.BorderSizePixel = 0
	avatarImg.ZIndex = 7
	avatarImg.LayoutOrder = 2
	avatarImg.Image = ""
	avatarImg.Parent = playerCard
	Instance.new("UICorner", avatarImg).CornerRadius = UDim.new(1, 0)

	task.spawn(function()
		local ok, thumbUrl = pcall(function()
			return game:GetService("Players"):GetUserThumbnailAsync(
				LP.UserId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size48x48
			)
		end)
		if ok and thumbUrl then
			avatarImg.Image = thumbUrl
		end
	end)

	-- Text column: name on top, tier below
	local textCol = Instance.new("Frame")
	textCol.Size = UDim2.new(0, 96, 0, 36)
	textCol.BackgroundTransparency = 1
	textCol.ZIndex = 7
	textCol.LayoutOrder = 1
	textCol.Parent = playerCard
	local textColLayout = Instance.new("UIListLayout", textCol)
	textColLayout.FillDirection = Enum.FillDirection.Vertical
	textColLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	textColLayout.Padding = UDim.new(0, 1)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 16)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = LP.DisplayName or LP.Name
	nameLabel.TextColor3 = self.theme.White
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 12
	nameLabel.TextXAlignment = Enum.TextXAlignment.Right
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.ZIndex = 7
	nameLabel.Parent = textCol

	local TIER_COLORS = {
		Standard = Color3.fromRGB(140, 140, 140),
		Premium  = Color3.fromRGB(255, 170, 0),
		Beta     = Color3.fromRGB(150, 80, 255),
		Admin    = Color3.fromRGB(255, 60, 60),
	}

	local tierLabel = Instance.new("TextLabel")
	tierLabel.Size = UDim2.new(1, 0, 0, 13)
	tierLabel.BackgroundTransparency = 1
	tierLabel.Text = "Standard"
	tierLabel.TextColor3 = TIER_COLORS["Standard"]
	tierLabel.Font = Enum.Font.GothamSemibold
	tierLabel.TextSize = 10
	tierLabel.TextXAlignment = Enum.TextXAlignment.Right
	tierLabel.ZIndex = 7
	tierLabel.Parent = textCol

	self.playerCard = playerCard
	self.tierLabel = tierLabel

	function self:setTier(tier)
		tierLabel.Text = tier
		tierLabel.TextColor3 = TIER_COLORS[tier] or TIER_COLORS.Standard
	end

	-- Invisible hintLabel kept for internal setToggleKey compatibility
	local hintLabel = Instance.new("TextLabel")
	hintLabel.Size = UDim2.new(0, 0, 0, 0)
	hintLabel.BackgroundTransparency = 1
	hintLabel.Text = ""
	hintLabel.Visible = false
	hintLabel.ZIndex = 3
	hintLabel.Parent = header
	self.hintLabel = hintLabel

	-- Search toggle + bar anchored right, left of player card
	local searchBtn = Instance.new("ImageButton")
	searchBtn.Size = UDim2.new(0, 26, 0, 26)
	searchBtn.AnchorPoint = Vector2.new(1, 0.5)
	searchBtn.Position = UDim2.new(1, -155, 0.5, 0)
	searchBtn.BackgroundTransparency = 1
	searchBtn.Image = "rbxassetid://10734943674"
	searchBtn.ImageColor3 = self.theme.Gray
	searchBtn.ScaleType = Enum.ScaleType.Fit
	searchBtn.ZIndex = 8
	searchBtn.Parent = header
	searchBtn.AutoButtonColor = false

	local searchFrame = Instance.new("Frame")
	searchFrame.Size = UDim2.new(0, 0, 0, 28)
	searchFrame.AnchorPoint = Vector2.new(1, 0.5)
	searchFrame.Position = UDim2.new(1, -155, 0.5, 0)
	searchFrame.BackgroundColor3 = self.theme.BG
	searchFrame.BorderSizePixel = 0
	searchFrame.ZIndex = 9
	searchFrame.Parent = header
	searchFrame.Visible = false
	searchFrame.ClipsDescendants = true
	Instance.new("UICorner", searchFrame).CornerRadius = UDim.new(0, 5)
	local sfStroke = Instance.new("UIStroke", searchFrame)
	sfStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	sfStroke.Color = self.theme.Border
	sfStroke.Thickness = 1

	local headerSearchBox = Instance.new("TextBox")
	headerSearchBox.Size = UDim2.new(1, -24, 1, 0)
	headerSearchBox.Position = UDim2.new(0, 6, 0, 0)
	headerSearchBox.BackgroundTransparency = 1
	headerSearchBox.PlaceholderText = "Filter subtabs..."
	headerSearchBox.PlaceholderColor3 = self.theme.Gray
	headerSearchBox.Text = ""
	headerSearchBox.TextColor3 = self.theme.White
	headerSearchBox.Font = Enum.Font.GothamSemibold
	headerSearchBox.TextSize = 12
	headerSearchBox.ClearTextOnFocus = false
	headerSearchBox.ZIndex = 10
	headerSearchBox.Parent = searchFrame

	local searchClose = Instance.new("ImageButton")
	searchClose.Size = UDim2.new(0, 16, 0, 16)
	searchClose.AnchorPoint = Vector2.new(1, 0.5)
	searchClose.Position = UDim2.new(1, -5, 0.5, 0)
	searchClose.BackgroundTransparency = 1
	searchClose.Image = "rbxassetid://10747384394"
	searchClose.ImageColor3 = self.theme.Gray
	searchClose.ScaleType = Enum.ScaleType.Fit
	searchClose.ZIndex = 10
	searchClose.Parent = searchFrame
	searchClose.AutoButtonColor = false

	local _searchClearing = false

	local function restoreAllVisibility()
		if self.activeTab and self.activeTab.subtabOrder then
			for _, sub in ipairs(self.activeTab.subtabOrder) do
				if sub.btn then sub.btn.Visible = true end
				if sub.groups then
					for _, g in ipairs(sub.groups) do
						if g.frame then g.frame.Visible = true end
					end
				end
			end
		end
	end

	local function closeSearch()
		if not searchFrame.Visible then return end
		TweenService:Create(searchFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(0, 0, 0, 28) }):Play()
		_searchClearing = true
		headerSearchBox.Text = ""
		_searchClearing = false
		restoreAllVisibility()
		task.delay(0.2, function()
			searchFrame.Visible = false
		end)
	end

	local function openSearch()
		local targetW = math.min(self.size.X * 0.4, 200)
		searchFrame.Size = UDim2.new(0, 0, 0, 28)
		searchFrame.Visible = true
		TweenService:Create(searchFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(0, targetW, 0, 28) }):Play()
		task.delay(0.1, function()
			headerSearchBox:CaptureFocus()
		end)
	end

	searchClose.MouseButton1Click:Connect(closeSearch)
	local escConn = UIS.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.Escape and searchFrame.Visible then closeSearch() end
	end)
	table.insert(self.connections, escConn)

	searchBtn.MouseButton1Click:Connect(function()
		if searchFrame.Visible then closeSearch() else openSearch() end
	end)

	-- Global search across all tabs and subtabs
	headerSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		if _searchClearing then return end
		local query = headerSearchBox.Text:lower()

		for _, tab in ipairs(self.tabOrder or {}) do
			if tab.subtabOrder then
				for _, sub in ipairs(tab.subtabOrder) do
					if sub.btn then
						local nameMatch = query == "" or (sub.name and sub.name:lower():find(query, 1, true))
						local contentMatch = false
						if not nameMatch and sub.groups then
							for _, g in ipairs(sub.groups) do
								if contentMatch then break end
								local gTitle = g.frame and g.frame:FindFirstChildOfClass("TextLabel")
								if gTitle and gTitle.Text:lower():find(query, 1, true) then contentMatch = true; break end
								if g.items then
									for _, c in ipairs(g.items:GetDescendants()) do
										if c:IsA("TextLabel") or c:IsA("TextButton") then
											if c.Text and c.Text:lower():find(query, 1, true) then
												contentMatch = true; break
											end
										elseif c:IsA("TextBox") then
											if (c.Text and c.Text:lower():find(query, 1, true)) or (c.PlaceholderText and c.PlaceholderText:lower():find(query, 1, true)) then
												contentMatch = true; break
											end
										end
									end
								end
							end
						end
						sub.btn.Visible = query == "" or nameMatch or contentMatch
					end
				end
			end
		end
	end)

	-- Press Enter to navigate to first visible subtab (switching tabs if needed)
	headerSearchBox.FocusLost:Connect(function(enter)
		if enter and searchFrame.Visible and headerSearchBox.Text ~= "" then
			for _, tab in ipairs(self.tabOrder or {}) do
				if tab.subtabOrder then
					for _, sub in ipairs(tab.subtabOrder) do
						if sub.btn and sub.btn.Visible and sub.select then
							-- Activate the subtab's parent tab if not already active
							if self.activeTab ~= tab and tab.activate then
								tab.activate()
							end
							closeSearch()
							sub:select()
							return
						end
					end
				end
			end
			closeSearch()
		end
		if not enter then return end
	end)

	self.headerSearchBox = headerSearchBox
	self.headerSearchFrame = searchFrame

	local initialSW = getSidebarWidth()

	local sidebar = Instance.new("ScrollingFrame")
	sidebar.Size = UDim2.new(0, initialSW, 1, -92)
	sidebar.Position = UDim2.new(0, 0, 0, 46)
	sidebar.BackgroundColor3 = self.theme.Panel
	sidebar.BackgroundTransparency = 0
	sidebar.BorderSizePixel = 0
	sidebar.ScrollBarThickness = 0
	sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sidebar.CanvasSize = UDim2.new(1, 0, 0, 0)
	sidebar.ScrollingDirection = Enum.ScrollingDirection.Y
	sidebar.ClipsDescendants = true
	sidebar.Parent = win
	self.sidebar = sidebar
	local sidebarLayout = Instance.new("UIListLayout", sidebar)
	sidebarLayout.Padding = UDim.new(0, 2)
	sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
	local sidebarPad = Instance.new("UIPadding", sidebar)
	sidebarPad.PaddingTop = UDim.new(0, 6)
	sidebarPad.PaddingBottom = UDim.new(0, 6)

	local sidebarEdge = Instance.new("Frame")
	sidebarEdge.Size = UDim2.new(0, 1, 1, -92)
	sidebarEdge.Position = UDim2.new(0, initialSW, 0, 46)
	sidebarEdge.BackgroundColor3 = self.theme.Border
	sidebarEdge.BorderSizePixel = 0
	sidebarEdge.ZIndex = 5
	sidebarEdge.Parent = win
	self.sidebarEdge = sidebarEdge

	local content = Instance.new("ScrollingFrame")
	content.Size = UDim2.new(0, self.size.X - initialSW - 1, 1, -92)
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

	local navbarBG = Instance.new("Frame")
	navbarBG.Name = "NavbarBG"
	navbarBG.Size = UDim2.new(1, 0, 0, 46)
	navbarBG.Position = UDim2.new(0, 0, 1, -46)
	navbarBG.BackgroundColor3 = self.theme.Panel
	navbarBG.BorderSizePixel = 0
	navbarBG.ZIndex = 58
	navbarBG.Parent = win
	self.navbarBG = navbarBG
	Instance.new("UICorner", navbarBG).CornerRadius = UDim.new(0, 10)

	local navbarCover = Instance.new("Frame")
	navbarCover.Name = "NavbarCover"
	navbarCover.Size = UDim2.new(1, 0, 0, 10)
	navbarCover.Position = UDim2.new(0, 0, 0, 0)
	navbarCover.BackgroundColor3 = navbarBG.BackgroundColor3
	navbarCover.BorderSizePixel = 0
	navbarCover.ZIndex = 59
	navbarCover.Parent = navbarBG
	self.navbarCover = navbarCover
	local navbar = Instance.new("ScrollingFrame")
	navbar.Size = UDim2.new(1, 0, 0, 46)
	navbar.Position = UDim2.new(0, 0, 1, -46)
	navbar.BackgroundTransparency = 1
	navbar.BorderSizePixel = 0
	navbar.ZIndex = 60
	navbar.ScrollBarThickness = 0
	navbar.ScrollingDirection = Enum.ScrollingDirection.X
	navbar.AutomaticCanvasSize = Enum.AutomaticSize.X
	navbar.CanvasSize = UDim2.new(0, 0, 0, 0)
	navbar.ClipsDescendants = true
	navbar.Parent = win

	local navTopLine = Instance.new("Frame")
	navTopLine.Size = UDim2.new(1, 0, 0, 2)
	navTopLine.Position = UDim2.new(0, 0, 1, -46)
	navTopLine.BackgroundColor3 = self.theme.Accent
	navTopLine.BorderSizePixel = 0
	navTopLine.ZIndex = 61
	navTopLine.Parent = win
	self.navTopLine = navTopLine
	self.navbar = navbar
	local navList = Instance.new("UIListLayout", navbar)
	navList.FillDirection = Enum.FillDirection.Horizontal
	navList.HorizontalAlignment = Enum.HorizontalAlignment.Left
	navList.VerticalAlignment = Enum.VerticalAlignment.Center
	navList.SortOrder = Enum.SortOrder.LayoutOrder
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
		header.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				drag = true
				dragStart = i.Position
				dragPos = win.Position
			end
		end)
			table.insert(self.connections,
			UIS.InputChanged:Connect(function(i)
				if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
					local delta = i.Position - dragStart
					win.Position = UDim2.new(dragPos.X.Scale, dragPos.X.Offset + delta.X, dragPos.Y.Scale,
						dragPos.Y.Offset + delta.Y)
					self.originalPosition = win.Position
					self.savedPos = win.Position
				end
			end))
		table.insert(self.connections,
			UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end end))
	end

		table.insert(self.connections,
		UIS.InputBegan:Connect(function(input, gpe)
			if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == self.toggleKey then
				self:setVisible(not self.visibleTarget)
			end
		end))

	table.insert(self.connections,
		UIS.InputBegan:Connect(function(input, gpe)
			if gpe then return end
			if input.KeyCode == Enum.KeyCode.Escape then
				local popups = self.activePopups or {}
				if #popups > 0 then
					local top = popups[#popups]
					pcall(function() top:Destroy() end)
					table.remove(popups, #popups)
				elseif self.sidebarOverlay and self.sidebarOverlay.Visible then
					self.sidebarOverlay.Visible = false
					self.sidebar.Visible = false
					self.sidebarEdge.Visible = false
					self.mobileSidebarOpen = false
				elseif self.headerSearchFrame and self.headerSearchFrame.Visible then
					self.headerSearchFrame.Visible = false
					self.headerSearchBox.Text = ""
				end
			end
		end))

	if UIS.TouchEnabled then
		local mobileBtn = Instance.new("TextButton")
		mobileBtn.Name = "MobileToggle"
		mobileBtn.Size = UDim2.new(0, 45, 0, 45)
		mobileBtn.AutoButtonColor = false
		mobileBtn.Position = UDim2.new(1, -60, 0.5, -22)
		mobileBtn.BackgroundColor3 = self.theme.Panel
		mobileBtn.BorderSizePixel = 0
		mobileBtn.Text = ""
		mobileBtn.ZIndex = 1000
		mobileBtn.Parent = self.sg
		self.mobileToggleButton = mobileBtn
		
		Instance.new("UICorner", mobileBtn).CornerRadius = UDim.new(0, 10)
		local btnStroke = Instance.new("UIStroke", mobileBtn)
		btnStroke.Color = self.theme.Border
		btnStroke.Thickness = 1
		
		local btnLogo = Instance.new("ImageLabel")
		btnLogo.Size = UDim2.new(0, 26, 0, 26)
		btnLogo.Position = UDim2.new(0.5, 0, 0.5, 0)
		btnLogo.AnchorPoint = Vector2.new(0.5, 0.5)
		btnLogo.BackgroundTransparency = 1
		btnLogo.Image = "rbxassetid://128385522450957"
		btnLogo.ZIndex = 1001
		btnLogo.Parent = mobileBtn
		
				local dragging, dragStart, startPos
		local dragDisplacement = 0
		mobileBtn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				dragStart = input.Position
				startPos = mobileBtn.Position
				dragDisplacement = 0
			end
		end)
		
		local mChanged = UIS.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
				local delta = input.Position - dragStart
				dragDisplacement = dragDisplacement + delta.Magnitude
				mobileBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			end
		end)
		
		local mEnded = UIS.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
			end
		end)
		
		table.insert(self.connections, mChanged)
		table.insert(self.connections, mEnded)
		
		mobileBtn.MouseButton1Click:Connect(function()
			if dragDisplacement < 8 then
				self:toggle()
			end
		end)
	end

	self.tabs = {}
	self.tabOrder = {}
	self.activeTab = nil
	self.navList = navList

	if includeUITab ~= false then
		self.includeUITab = true
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
				if mode == "hold" then elem.SetValue(false) end
			end
		end
	end))

	table.insert(allWindows, self)

	self:updateLayout()

		task.defer(function()
			if self.includeUITab and not self.uiTabCreated then
				self.uiTabCreated = true
		self:buildUITab()
			end
		self:setVisible(true)
	end)

	return self
end

function UILib:addWatermark(name)
	self._wmName = name
	if self.watermark then
		if self.wmDragConns then
			for _, c in ipairs(self.wmDragConns) do pcall(function() c:Disconnect() end) end
		end
		self.watermark:Destroy()
	end
	local wm = Instance.new("Frame")
	wm.AutomaticSize = Enum.AutomaticSize.X
	wm.Size = UDim2.new(0, 0, 0, 24)
	wm.Position = self._wmPos or UDim2.new(1, -10, 0, 10)
	wm.AnchorPoint = Vector2.new(1, 0)
	wm.BackgroundColor3 = self.theme.Panel
	wm.BackgroundTransparency = 0.25
	wm.BorderSizePixel = 0
	wm.Parent = self.sg
	wm.ZIndex = 200
	Instance.new("UICorner", wm).CornerRadius = UDim.new(0, 6)
	local wmStroke = Instance.new("UIStroke", wm)
	wmStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	wmStroke.Color = self.theme.Border
	wmStroke.Thickness = 1
	wmStroke.Transparency = 0.6
	local row = Instance.new("Frame")
	row.AutomaticSize = Enum.AutomaticSize.X
	row.Size = UDim2.new(0, 0, 1, 0)
	row.BackgroundTransparency = 1
	row.ZIndex = 201
	row.Parent = wm
	local rowLayout = Instance.new("UIListLayout", row)
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rowLayout.Padding = UDim.new(0, 8)
	rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	local rowPad = Instance.new("UIPadding", row)
	rowPad.PaddingLeft = UDim.new(0, 10)
	rowPad.PaddingRight = UDim.new(0, 10)
	local watermarkScale = Instance.new("UIScale", wm)
	watermarkScale.Scale = self._wmScale or 1
	local function updateWatermarkSize(delta)
		watermarkScale.Scale = math.clamp(watermarkScale.Scale + delta * 0.05, 0.5, 2)
		self._wmScale = watermarkScale.Scale
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
		dragBtn.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				drag = true
				dragStart = i.Position
				dragPos = wm.Position
			end
		end)
		local wmDragMove = UIS.InputChanged:Connect(function(i)
			if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
				local delta = i.Position - dragStart
				wm.Position = UDim2.new(dragPos.X.Scale, dragPos.X.Offset + delta.X, dragPos.Y.Scale,
					dragPos.Y.Offset + delta.Y)
				self._wmPos = wm.Position
			end
		end)
		local wmDragEnd = UIS.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end
		end)
		-- store so they can be cleaned up when watermark is toggled off
		self.wmDragConns = { wmDragMove, wmDragEnd }
	end

	local nameLbl = Instance.new("TextLabel")
	nameLbl.AutomaticSize = Enum.AutomaticSize.X
	nameLbl.Size = UDim2.new(0, 0, 1, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = name
	nameLbl.TextColor3 = self.theme.White
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextSize = 11
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.TextYAlignment = Enum.TextYAlignment.Center
	nameLbl.ZIndex = 201
	nameLbl.LayoutOrder = 1
	nameLbl.Parent = row

	local function addDivider(order)
		local div = Instance.new("Frame")
		div.Size = UDim2.new(0, 3, 0, 3)
		div.BackgroundColor3 = self.theme.Border
		div.BackgroundTransparency = 0.5
		div.BorderSizePixel = 0
		div.ZIndex = 201
		div.LayoutOrder = order
		div.Parent = row
		Instance.new("UICorner", div).CornerRadius = UDim.new(0, 2)
	end
	addDivider(2)

	local fpsLabel = Instance.new("TextLabel")
	fpsLabel.AutomaticSize = Enum.AutomaticSize.X
	fpsLabel.Size = UDim2.new(0, 0, 1, 0)
	fpsLabel.BackgroundTransparency = 1
	fpsLabel.Text = "0 FPS"
	fpsLabel.TextColor3 = self.theme.GrayLt
	fpsLabel.Font = Enum.Font.GothamSemibold
	fpsLabel.TextSize = 10
	fpsLabel.ZIndex = 201
	fpsLabel.LayoutOrder = 3
	fpsLabel.Parent = row

	addDivider(4)

	local pingLabel = Instance.new("TextLabel")
	pingLabel.AutomaticSize = Enum.AutomaticSize.X
	pingLabel.Size = UDim2.new(0, 0, 1, 0)
	pingLabel.BackgroundTransparency = 1
	pingLabel.Text = "0ms"
	pingLabel.TextColor3 = self.theme.GrayLt
	pingLabel.Font = Enum.Font.GothamSemibold
	pingLabel.TextSize = 10
	pingLabel.ZIndex = 201
	pingLabel.LayoutOrder = 5
	pingLabel.Parent = row

	addDivider(6)

	local uptimeLabel = Instance.new("TextLabel")
	uptimeLabel.AutomaticSize = Enum.AutomaticSize.X
	uptimeLabel.Size = UDim2.new(0, 0, 1, 0)
	uptimeLabel.BackgroundTransparency = 1
	uptimeLabel.Text = "00:00:00"
	uptimeLabel.TextColor3 = self.theme.GrayLt
	uptimeLabel.Font = Enum.Font.GothamSemibold
	uptimeLabel.TextSize = 10
	uptimeLabel.ZIndex = 201
	uptimeLabel.LayoutOrder = 7
	uptimeLabel.Parent = row

	local frameCount = 0
	local lastTime = tick()
	local lastPingUpdate = 0
		local connection
	connection = RunService.RenderStepped:Connect(function()
		if not wm or not wm.Parent then
			if connection then connection:Disconnect() end
			return
		end
		frameCount = frameCount + 1
		local now = tick()
		if now - lastTime >= 1 then
			fpsLabel.Text = math.floor(frameCount / (now - lastTime) + 0.5) .. " FPS"
			frameCount = 0
			lastTime = now
		end
		if now - lastPingUpdate >= 0.5 then
			lastPingUpdate = now
			local ping = LP:GetNetworkPing() * 1000
			pingLabel.Text = math.floor(ping + 0.5) .. "ms"
			local up = math.floor(workspace.DistributedGameTime)
			uptimeLabel.Text = string.format("%02d:%02d:%02d", math.floor(up/3600), math.floor((up%3600)/60), up%60)
		end
	end)
	self.wmConn = connection
	self.watermark = wm
	return wm
end

function UILib:setupKeybindHUD()
	if self._hudFrame then return end
	local hud = Instance.new("Frame")
	hud.Size = UDim2.new(0, 200, 0, 0)
	hud.Position = self._hudPos or UDim2.new(0, 10, 1, -10)
	hud.AnchorPoint = Vector2.new(0, 1)
	hud.BackgroundColor3 = self.theme.Panel
	hud.BackgroundTransparency = 0.25
	hud.BorderSizePixel = 0
	hud.ZIndex = 200
	hud.Visible = false
	hud.Parent = self.sg
	Instance.new("UICorner", hud).CornerRadius = UDim.new(0, 6)
	local hudStroke = Instance.new("UIStroke", hud)
	hudStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	hudStroke.Color = self.theme.Border
	hudStroke.Thickness = 1
	hudStroke.Transparency = 0.6

	local hudPad = Instance.new("UIPadding", hud)
	hudPad.PaddingLeft = UDim.new(0, 10)
	hudPad.PaddingRight = UDim.new(0, 10)
	hudPad.PaddingTop = UDim.new(0, 8)
	hudPad.PaddingBottom = UDim.new(0, 8)

	local hudLayout = Instance.new("UIListLayout", hud)
	hudLayout.SortOrder = Enum.SortOrder.LayoutOrder
	hudLayout.Padding = UDim.new(0, 6)

	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, 0, 0, 16)
	header.BackgroundTransparency = 1
	header.Text = "KEYBINDS"
	header.TextColor3 = self.theme.GrayLt
	header.Font = Enum.Font.GothamBold
	header.TextSize = 9
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.ZIndex = 201
	header.LayoutOrder = 1
	header.Parent = hud

	local hudDrag = Instance.new("TextButton")
	hudDrag.Size = UDim2.new(1, 0, 1, 0)
	hudDrag.BackgroundTransparency = 1
	hudDrag.Text = ""
	hudDrag.ZIndex = 205
	hudDrag.Parent = hud
	local hDrag, hDragStart, hDragPos = false, nil, nil
	hudDrag.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			hDrag, hDragStart, hDragPos = true, i.Position, hud.Position
		end
	end)
	local hMove = UIS.InputChanged:Connect(function(i)
		if hDrag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local delta = i.Position - hDragStart
			hud.Position = UDim2.new(hDragPos.X.Scale, hDragPos.X.Offset + delta.X, hDragPos.Y.Scale, hDragPos.Y.Offset + delta.Y)
			self._hudPos = hud.Position
		end
	end)
	local hEnd = UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then hDrag = false end
	end)
	table.insert(self.connections, hMove)
	table.insert(self.connections, hEnd)

	local function updateHudSize()
		hud.Size = UDim2.new(0, 200, 0, hudLayout.AbsoluteContentSize.Y + 16)
	end
	hudLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateHudSize)

	self._hudFrame = hud
	self._hudLayout = hudLayout
	self._hudEntries = {}
	self._hudUpdate = updateHudSize
end

function UILib:addKeybindHUD(name, key, mode)
	if not self._hudFrame then self:setupKeybindHUD() end
	mode = mode or "Hold"
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 18)
	row.BackgroundTransparency = 1
	row.ZIndex = 201
	row.LayoutOrder = #self._hudEntries + 2
	row.Parent = self._hudFrame

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(0.55, 0, 1, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = name
	nameLbl.TextColor3 = self.theme.White
	nameLbl.Font = Enum.Font.GothamSemibold
	nameLbl.TextSize = 10
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.ZIndex = 202
	nameLbl.Parent = row

	local modeLbl = Instance.new("TextLabel")
	modeLbl.Size = UDim2.new(0.25, 0, 1, 0)
	modeLbl.Position = UDim2.new(0.55, 0, 0, 0)
	modeLbl.BackgroundTransparency = 1
	modeLbl.Text = "[" .. mode .. "]"
	modeLbl.TextColor3 = self.theme.Gray
	modeLbl.Font = Enum.Font.GothamSemibold
	modeLbl.TextSize = 10
	modeLbl.TextXAlignment = Enum.TextXAlignment.Left
	modeLbl.ZIndex = 202
	modeLbl.Parent = row

	local keyLbl = Instance.new("TextLabel")
	keyLbl.Size = UDim2.new(0.2, 0, 1, 0)
	keyLbl.Position = UDim2.new(0.8, 0, 0, 0)
	keyLbl.BackgroundTransparency = 1
	keyLbl.Text = key
	keyLbl.TextColor3 = self.theme.Accent
	keyLbl.Font = Enum.Font.GothamBold
	keyLbl.TextSize = 10
	keyLbl.TextXAlignment = Enum.TextXAlignment.Right
	keyLbl.ZIndex = 202
	keyLbl.Parent = row

	local entry = { row = row, keyLabel = keyLbl, modeLabel = modeLbl }
	table.insert(self._hudEntries, entry)
	self._hudUpdate()
	self._hudFrame.Visible = true
	return entry
end

function UILib:removeKeybindHUD(entry)
	local idx = table.find(self._hudEntries, entry)
	if idx then
		entry.row:Destroy()
		table.remove(self._hudEntries, idx)
		self._hudUpdate()
		if #self._hudEntries == 0 then
			self._hudFrame.Visible = false
		end
	end
end

function UILib:updateKeybindHUD(entry, key, mode)
	if key then entry.keyLabel.Text = key end
	if mode then entry.modeLabel.Text = "[" .. mode .. "]" end
end

function UILib:buildUITab()
	if self.uiTabBuilt then return end
	self.uiTabBuilt = true
	local uiTab = self:addTab("UI", self.uiTabIcon and { icon = self.uiTabIcon } or {})
	if uiTab and uiTab.btn then uiTab.btn.LayoutOrder = 999 end
	local uiSub = uiTab:addSubTab("Settings")
	local uiL, uiR = uiSub:split()

	local grp = uiL:addGroup("Interface")

	local widthSlider = grp:slider("Window Width", 450, 1200, self.size.X, function(val)
		self.size = Vector2.new(val, self.size.Y)
		self.window.Size = UDim2.new(0, val, 0, self.size.Y)
		self.updateLayout()
	end, 10, "Adjust the width of the menu", nil, nil, "ui_width")
	widthSlider.frame.Visible = false

	local heightSlider = grp:slider("Window Height", 350, 800, self.size.Y, function(val)
		self.size = Vector2.new(self.size.X, val)
		self.window.Size = UDim2.new(0, self.size.X, 0, val)
		self.updateLayout()
	end, 10, "Adjust the height of the menu", nil, nil, "ui_height")
	heightSlider.frame.Visible = false

	grp:button("Resize Mode", function()
		self:enterResizeMode(widthSlider, heightSlider)
	end, "Enter drag resize mode to scale the window from the bottom-right corner")

	grp:keybind("Toggle Key", "RightShift", function(_, name)
		self.toggleKey = Enum.KeyCode[name] or Enum.KeyCode.RightShift
	end, "Set key to show/hide menu", "ui_togglekey")

	grp:toggle("Show Watermark", self.watermark ~= nil, function(v)
		if v then
			if not self.watermark then
				self:addWatermark(self._wmName or self.title or "CloverHUB")
			end
		else
			if self.wmConn then
				self.wmConn:Disconnect(); self.wmConn = nil
			end
			if self.wmDragConns then
				for _, c in ipairs(self.wmDragConns) do pcall(function() c:Disconnect() end) end
				self.wmDragConns = nil
			end
			if self.watermark then
				self.watermark:Destroy(); self.watermark = nil
			end
		end
	end, "Display FPS and ping", nil, nil, nil, nil, nil, "ui_watermark")

	grp:toggle("Show Keybinds", self._hudFrame ~= nil and self._hudFrame.Visible, function(v)
		if not self._hudFrame then self:setupKeybindHUD() end
		self._hudFrame.Visible = v
	end, "Show active keybinds on screen", nil, nil, nil, nil, nil, "ui_keybindhud")

	grp:button("Unload", function()
		self:confirm("Are you sure you want to unload?", function(ok)
			if ok then self:Destroy() end
		end)
	end, "Cleanly remove the UI",
		Enum.TextXAlignment.Center, Color3.fromRGB(255, 80, 80))

	-- Theme section on left column

	local function refreshAllBorders(b)
		for _, s in ipairs(self.window:GetDescendants()) do
			if s:IsA("UIStroke") and s.Parent and s.Parent.Name ~= "WindowStrokeFrame" then
				pcall(function() s.Color = b end)
			end
		end
		for _, tab in ipairs(self.tabOrder or {}) do
			if tab.tabLbl then pcall(function() tab.tabLbl.TextColor3 = self.theme.Gray end) end
		end
		if self.activeTab then
			if self.activeTab.tabLbl then self.activeTab.tabLbl.TextColor3 = self.theme.White end
			if self.activeTab.tabIcon and self.activeTab.tabIconId then
				self.activeTab.tabIcon.ImageColor3 = self.theme.Accent
			end
		end
	end

	local function refreshAllUI()
		for _, tab in ipairs(self.tabOrder or {}) do
			if tab.subtabs then
				for _, sub in pairs(tab.subtabs) do
					if sub.selGradient and sub.selGradient.Visible then
						if sub.label then sub.label.TextColor3 = self.theme.White end
					end
					if sub.selLine then sub.selLine.BackgroundColor3 = self.theme.Accent end
				end
			end
			if tab.subtabOrder then
				for _, sub in ipairs(tab.subtabOrder) do
					if sub.hovFrame then sub.hovFrame.BackgroundColor3 = self.theme.ItemHov end
					if sub.groups then
						for _, gr in ipairs(sub.groups) do
							if gr.frame then gr.frame.BackgroundColor3 = self.theme.Item end
							if gr.headerRow then
								gr.headerRow.BackgroundColor3 = Color3.new(
									math.min(1, self.theme.ItemHov.r * 1.15),
									math.min(1, self.theme.ItemHov.g * 1.15),
									math.min(1, self.theme.ItemHov.b * 1.15)
								)
							end
							if gr.headerSep then gr.headerSep.BackgroundColor3 = self.theme.Accent end
						if gr.headerLabel then gr.headerLabel.TextColor3 = self.theme.GrayLt end
						end
					end
				end
			end
		end
		for _, sg in ipairs(self.window:GetDescendants()) do
			if sg.Name == "SelectionBG" and sg:IsA("Frame") then
				pcall(function() sg.BackgroundColor3 = self.theme.Accent end)
			end
		end
	end

	local function applyFullTheme(theme)
		local accent, bg, panel, item, itemHov, track, border = unpack(theme, 2)
		self.theme.Accent = accent
		self.theme.AccentD = Color3.new(accent.r * 0.70, accent.g * 0.70, accent.b * 0.70)
		self.theme.BG = bg
		self.theme.Base = bg
		self.theme.Panel = panel
		self.theme.Surface = panel
		self.theme.Item = item
		self.theme.ItemHov = itemHov
		self.theme.Track = track
		self.theme.Border = border
		self:updateAccent(accent)
		if self.window then self.window.BackgroundColor3 = bg end
		if self.content then self.content.BackgroundColor3 = bg end
		if self.header then self.header.BackgroundColor3 = panel end
		if self.headerCover then self.headerCover.BackgroundColor3 = panel end
		if self.sidebar then self.sidebar.BackgroundColor3 = panel end
		if self.navbar then self.navbar.BackgroundColor3 = panel end
		if self.navbarBG then self.navbarBG.BackgroundColor3 = panel end
		if self.navbarCover then self.navbarCover.BackgroundColor3 = panel end
		if self.navTopLine then self.navTopLine.BackgroundColor3 = accent end
		if self.sidebarEdge then self.sidebarEdge.BackgroundColor3 = border end
		if self.tooltip then self.tooltip.frame.BackgroundColor3 = panel end
		if self.watermark then self.watermark.BackgroundColor3 = panel end
		for _, d in pairs(self._panels or {}) do
			if d.popup then d.popup.BackgroundColor3 = panel end
		end
		for _, tab in ipairs(self.tabOrder or {}) do
			if tab.subtabs then
				for _, s in pairs(tab.subtabs) do
					if s.selLine then s.selLine.BackgroundColor3 = accent end
				end
			end
		end
		refreshAllUI()
		refreshAllBorders(border)
	end

	local function applyCurrentTheme()
		self:updateAccent(self.theme.Accent)
		if self.window then self.window.BackgroundColor3 = self.theme.BG end
		if self.content then self.content.BackgroundColor3 = self.theme.BG end
		if self.header then self.header.BackgroundColor3 = self.theme.Panel end
		if self.headerCover then self.headerCover.BackgroundColor3 = self.theme.Panel end
		if self.sidebar then self.sidebar.BackgroundColor3 = self.theme.Panel end
		if self.navbar then self.navbar.BackgroundColor3 = self.theme.Panel end
		if self.navbarBG then self.navbarBG.BackgroundColor3 = self.theme.Panel end
		if self.navbarCover then self.navbarCover.BackgroundColor3 = self.theme.Panel end
		if self.navTopLine then self.navTopLine.BackgroundColor3 = self.theme.Accent end
		if self.sidebarEdge then self.sidebarEdge.BackgroundColor3 = self.theme.Border end
		if refreshAllUI then refreshAllUI() end
		if refreshAllBorders then refreshAllBorders(self.theme.Border) end
	end

	local THEMES = {
		{ "Default",  Color3.fromRGB(0, 210, 135), Color3.fromRGB(10, 10, 10), Color3.fromRGB(24, 24, 24), Color3.fromRGB(24, 24, 24), Color3.fromRGB(32, 32, 32), Color3.fromRGB(10, 10, 10), Color3.fromRGB(42, 42, 42) },
		{ "Midnight", Color3.fromRGB(100, 140, 255), Color3.fromRGB(8, 8, 12), Color3.fromRGB(18, 20, 28), Color3.fromRGB(20, 22, 30), Color3.fromRGB(26, 28, 38), Color3.fromRGB(10, 10, 14), Color3.fromRGB(35, 40, 55) },
		{ "Blood",    Color3.fromRGB(220, 50, 50), Color3.fromRGB(12, 8, 8), Color3.fromRGB(28, 18, 18), Color3.fromRGB(28, 20, 20), Color3.fromRGB(38, 24, 24), Color3.fromRGB(14, 8, 8), Color3.fromRGB(50, 30, 30) },
		{ "Ocean",    Color3.fromRGB(0, 180, 220), Color3.fromRGB(8, 12, 15), Color3.fromRGB(18, 24, 30), Color3.fromRGB(20, 26, 32), Color3.fromRGB(26, 32, 40), Color3.fromRGB(8, 10, 14), Color3.fromRGB(30, 42, 52) },
		{ "Gold",     Color3.fromRGB(255, 180, 50), Color3.fromRGB(15, 12, 8), Color3.fromRGB(30, 26, 18), Color3.fromRGB(32, 28, 20), Color3.fromRGB(40, 34, 24), Color3.fromRGB(14, 10, 6), Color3.fromRGB(55, 45, 30) },
		{ "Lime",     Color3.fromRGB(100, 255, 100), Color3.fromRGB(10, 15, 10), Color3.fromRGB(24, 30, 24), Color3.fromRGB(26, 32, 26), Color3.fromRGB(34, 40, 34), Color3.fromRGB(10, 14, 10), Color3.fromRGB(40, 50, 40) },
		{ "Purple",   Color3.fromRGB(180, 100, 255), Color3.fromRGB(12, 8, 15), Color3.fromRGB(24, 18, 30), Color3.fromRGB(26, 20, 32), Color3.fromRGB(34, 26, 40), Color3.fromRGB(12, 8, 14), Color3.fromRGB(42, 30, 55) },
	}
	local themeNames = {}
	for _, t in ipairs(THEMES) do themeNames[#themeNames + 1] = t[1] end

	local themeGrp = uiL:addGroup("Theme")
	local themeDropdown = themeGrp:dropdown("Preset", themeNames, "Default", function(val)
		if val == "" then return end
		for _, t in ipairs(THEMES) do
			if t[1] == val then applyFullTheme(t); break end
		end
	end, "Apply a pre-made color theme", nil, nil, "ui_theme")


	local cfg = uiR:addGroup("Save Manager")
	cfg:separator("Load")

	local function getConfigListStructured()
		local list = self:listConfigsStructured()
		table.sort(list)
		return list
	end

	local selectedCfg = ""
	local cfgDropdown = cfg:dropdown("", getConfigListStructured(), "", function(v)
		if type(v) == "string" and v ~= "" then selectedCfg = v end
	end, "Select a config to load/delete", function() return getConfigListStructured() end, nil, "ui_cfgdropdown")

	local function cfgRefreshDropdown()
		local list = getConfigListStructured()
		cfgDropdown._values = list
		pcall(function()
			cfgDropdown:SetValues(list)
		end)
	end

	cfg:button("Load Config", function()
		if selectedCfg == "" then self:notify("No config selected", "warning", 2); return end
		self:loadConfigStructured(selectedCfg)
	end, nil, Enum.TextXAlignment.Center)
	cfg:button("Delete Config", function()
		if selectedCfg == "" then return end
		pcall(delfile, self:getConfigDir() .. selectedCfg .. ".json")
		self:notify("Deleted: " .. selectedCfg, "success", 2)
		selectedCfg = ""
		cfgRefreshDropdown()
	end, nil, Enum.TextXAlignment.Center, Color3.fromRGB(255, 80, 80))

	local hasAutoLoad = self:getAutoLoadConfig() ~= nil
	local autoLoadToggle = cfg:toggle("Set as Auto Load", hasAutoLoad, function(v)
		if _configLoading then return end
		if v then
			if selectedCfg == "" then
				self:notify("Select a config first", "warning", 2); return
			end
			self:setAutoLoadConfig(selectedCfg)
			self:notify("Auto-load: " .. selectedCfg, "success", 2)
		else
			self:setAutoLoadConfig(nil)
			self:notify("Auto-load off", "info", 2)
		end
	end, "Auto-load this config on script start", nil, nil, nil, nil, nil, "ui_autoload")
	cfg:separator("Create")

	local cfgNameBox = cfg:textbox("Config Name", "", "Enter name...", function(_) end, nil, "ui_cfgname")

	cfg:button("Save Config", function()
		local nameBox = cfgNameBox.frame and cfgNameBox.frame:FindFirstChildOfClass("TextBox")
		local name = (nameBox and nameBox.Text and nameBox.Text ~= "" and nameBox.Text) or ""
		if name == "" then self:notify("Enter a name", "warning", 2); return end
		self:saveConfigStructured(name)
		selectedCfg = name
		pcall(function() if nameBox then nameBox.Text = "" end end)
		cfgRefreshDropdown()
	end, nil, Enum.TextXAlignment.Center)
	cfg:button("Rename Config", function()
		if selectedCfg == "" or selectedCfg == "(no configs)" then self:notify("Select a config first", "warning", 2); return end
		local nameBox = cfgNameBox.frame and cfgNameBox.frame:FindFirstChildOfClass("TextBox")
		local newName = (nameBox and nameBox.Text and nameBox.Text ~= "" and nameBox.Text) or ""
		if newName == "" then self:notify("Enter a new name first", "warning", 2); return end
		if newName == selectedCfg then self:notify("Name is the same", "warning", 2); return end
		self:confirm("Rename '" .. selectedCfg .. "' to '" .. newName .. "'?", function(ok)
			if not ok then return end
			local dir = self:getConfigDir()
			local oldPath = dir .. selectedCfg .. ".json"
			local newPath = dir .. newName .. ".json"
			if isfile and isfile(newPath) then self:notify("Name already exists", "error", 3); return end
			local okMove = pcall(function()
				local content = readfile(oldPath)
				writefile(newPath, content)
				delfile(oldPath)
			end)
			if not okMove then self:notify("Rename failed", "error", 3); return end
			if self:getAutoLoadConfig() == selectedCfg then self:setAutoLoadConfig(newName) end
			self:notify("Renamed to " .. newName, "success", 2)
			selectedCfg = newName
			pcall(function() if nameBox then nameBox.Text = "" end end)
			cfgRefreshDropdown()
		end)
	end, nil, Enum.TextXAlignment.Center, Color3.fromRGB(255, 200, 80))
	cfg:separator("Share & Import")

	cfg:button("Export Config", function()
		self:shareConfigCode(self.configShareUrl or "https://cloverhub.fun")
	end, "Upload config and get a short share code", Enum.TextXAlignment.Center, Color3.fromRGB(100, 180, 255))

	local shareCodeBox = cfg:textbox("Share Code", "", "e.g. A1B2C3", function(_) end, nil, "ui_sharecode")

	cfg:button("Import Config", function()
		local box = shareCodeBox.frame and shareCodeBox.frame:FindFirstChildOfClass("TextBox")
		local code = (box and box.Text and box.Text ~= "" and box.Text) or ""
		if code == "" then self:notify("Enter a share code first", "warning", 2); return end
		self:importConfigCode(self.configShareUrl or "https://cloverhub.fun", code)
		pcall(function() if box then box.Text = "" end end)
		cfgRefreshDropdown()
	end, "Fetch and apply config from share code", Enum.TextXAlignment.Center, Color3.fromRGB(100, 255, 180))

	self:ignoreConfig("ui_width", "ui_height", "ui_togglekey", 	"ui_watermark", "ui_theme", "ui_cfgdropdown", "ui_autoload", "ui_cfgname", "ui_sharecode", "ui_keybindhud")
	self:tryAutoLoad()
end

function UILib:shareConfigCode(baseUrl)
	local json = _configStructuredToJSON(self)
	local req = (syn and syn.request) or (http and http.request) or http_request
	if req then
		local ok, res = pcall(req, {
			Url = baseUrl .. "/api/config/share",
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HS:JSONEncode({ json = json })
		})
		if ok and res and res.Body then
			local data = HS:JSONDecode(res.Body)
			if data and data.success and data.code then
				pcall(setclipboard, data.code)
				self:notify("Code copied: " .. data.code, "success", 4)
			else
				self:notify("Share failed: " .. tostring(data and data.message or "unknown"), "error", 3)
			end
			return
		end
	end
	pcall(function()
		local body = HS:PostAsync(baseUrl .. "/api/config/share", HS:JSONEncode({ json = json }), Enum.HttpContentType.ApplicationJson)
		local data = HS:JSONDecode(body)
		if data and data.success and data.code then
			pcall(setclipboard, data.code)
			self:notify("Code copied: " .. data.code, "success", 4)
		else
			self:notify("Share failed", "error", 3)
		end
	end)
end

function UILib:importConfigCode(baseUrl, code)
	self:notify("Fetching config...", "info", 2)
	local req = (syn and syn.request) or (http and http.request) or http_request
	if req then
		local ok, res = pcall(req, {
			Url = baseUrl .. "/api/config/" .. code,
			Method = "GET"
		})
		if ok and res and res.Body then
			local data = HS:JSONDecode(res.Body)
			if data and data.success and data.json then
				self:importConfigStructured(data.json)
				local dir = self:getConfigDir()
				pcall(makefolder, dir)
				pcall(writefile, dir .. code .. ".json", data.json)
			else
				self:notify("Config not found: " .. code, "error", 3)
			end
			return
		end
	end
	pcall(function()
		local body = game:HttpGet(baseUrl .. "/api/config/" .. code)
		local data = HS:JSONDecode(body)
		if data and data.success and data.json then
			self:importConfigStructured(data.json)
			local dir = self:getConfigDir()
			pcall(makefolder, dir)
			pcall(writefile, dir .. code .. ".json", data.json)
		else
			self:notify("Config not found: " .. code, "error", 3)
		end
	end)
end

function UILib:setTitle(text)
	if self.titleLabel then self.titleLabel.Text = tostring(text) end
end

function UILib:setVersion(text)
	if self.versionLabel then self.versionLabel.Text = tostring(text) end
	if self.versionPill then self.versionPill.Visible = true end
end

function UILib:Destroy()
	for _, conn in ipairs(self.connections) do conn:Disconnect() end
	if self.wmConn then
		self.wmConn:Disconnect(); self.wmConn = nil
	end
	if self.wmDragConns then
		for _, c in ipairs(self.wmDragConns) do pcall(function() c:Disconnect() end) end
		self.wmDragConns = nil
	end
	if _pickerCons then
		for frame, cons in pairs(_pickerCons) do
			if not frame.Parent then
				for _, c in ipairs(cons) do pcall(c.Disconnect, c) end
				_pickerCons[frame] = nil
			end
		end
	end
	if self.sg then self.sg:Destroy() end
	for i, w in ipairs(allWindows) do
		if w == self then
			table.remove(allWindows, i); break
		end
	end
end

function UILib:setVisible(visible)
	if visible == self.visibleTarget then return end
	self.visibleTarget = visible

	if visible then
		self.window.Visible = true
		if self._animOverlay then
			TweenService:Create(self._animOverlay, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play()
		end
		TweenService:Create(self.uiScale, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Scale = self._targetScale }):Play()
	else
		self.uiScale.Scale = self._targetScale
		TweenService:Create(self.uiScale, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Scale = 0 }):Play()
		task.delay(0.16, function() if not self.visibleTarget then self.window.Visible = false end end)
	end
end

function UILib:toggle()
	self:setVisible(not self.visibleTarget)
end

-- ── Dialog system ──────────────────────────────────────────
function UILib:showDialog(opts)
	opts = opts or {}
	local title = opts.title or "Dialog"
	local message = opts.message or ""
	local buttons = opts.buttons or { "OK" }
	local callbacks = opts.callbacks or {}
	local textInput = opts.textInput
	local inputDefault = opts.inputDefault or ""

	local overlay = Instance.new("TextButton")
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0
	overlay.Text = ""
	overlay.AutoButtonColor = false
	overlay.ZIndex = 5000
	overlay.Parent = self.sg

	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
	local dialogW = math.clamp(math.floor(vp.X * 0.45), 260, 380)

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, dialogW, 0, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.BackgroundColor3 = self.theme.Panel
	frame.BorderSizePixel = 0
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.ZIndex = 5001
	frame.Parent = self.sg
	local frameScale = Instance.new("UIScale", frame)
	frameScale.Scale = 0
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
	local stroke = Instance.new("UIStroke", frame)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = self.theme.Border
	stroke.Thickness = 1

	local layout = Instance.new("UIListLayout", frame)
	layout.Padding = UDim.new(0, 12)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	local pad = Instance.new("UIPadding", frame)
	pad.PaddingLeft = UDim.new(0, 16)
	pad.PaddingRight = UDim.new(0, 16)
	pad.PaddingTop = UDim.new(0, 16)
	pad.PaddingBottom = UDim.new(0, 16)

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size = UDim2.new(1, 0, 0, 20)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = title:upper()
	titleLbl.TextColor3 = self.theme.Accent
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextSize = 14
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.ZIndex = 5002
	titleLbl.Parent = frame

	local msgLbl = Instance.new("TextLabel")
	msgLbl.Size = UDim2.new(1, 0, 0, 0)
	msgLbl.BackgroundTransparency = 1
	msgLbl.Text = message
	msgLbl.TextColor3 = self.theme.White
	msgLbl.Font = Enum.Font.GothamSemibold
	msgLbl.TextSize = 13
	msgLbl.TextWrapped = true
	msgLbl.TextXAlignment = Enum.TextXAlignment.Left
	msgLbl.AutomaticSize = Enum.AutomaticSize.Y
	msgLbl.ZIndex = 5002
	msgLbl.Parent = frame

	local inputBox
	if textInput then
		inputBox = Instance.new("TextBox")
		inputBox.Size = UDim2.new(1, 0, 0, 28)
		inputBox.BackgroundColor3 = self.theme.Track
		inputBox.BorderSizePixel = 0
		inputBox.Text = inputDefault
		inputBox.TextColor3 = self.theme.White
		inputBox.Font = Enum.Font.GothamSemibold
		inputBox.TextSize = 13
		inputBox.ZIndex = 5002
		inputBox.ClearTextOnFocus = false
		inputBox.Parent = frame
		Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 4)
		local ibStroke = Instance.new("UIStroke", inputBox)
		ibStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		ibStroke.Color = self.theme.Border
		ibStroke.Thickness = 1
	end

	local btnRow = Instance.new("Frame")
	btnRow.Size = UDim2.new(1, 0, 0, 32)
	btnRow.BackgroundTransparency = 1
	btnRow.ZIndex = 5002
	btnRow.Parent = frame
	local btnLayout = Instance.new("UIListLayout", btnRow)
	btnLayout.FillDirection = Enum.FillDirection.Horizontal
	btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	btnLayout.Padding = UDim.new(0, 8)

	local function cleanup()
		TweenService:Create(frameScale, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Scale = 0 }):Play()
		TweenService:Create(overlay, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
		task.delay(0.16, function()
			pcall(function() overlay:Destroy() end)
			pcall(function() frame:Destroy() end)
		end)
	end

	for i, btnText in ipairs(buttons) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, math.max(60, #btnText * 10 + 20), 0, 28)
		btn.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
		btn.BorderSizePixel = 0
		btn.Text = btnText
		btn.TextColor3 = self.theme.White
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 12
		btn.ZIndex = 5003
		btn.AutoButtonColor = false
		btn.Parent = btnRow
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
		local btnStroke = Instance.new("UIStroke", btn)
		btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		btnStroke.Color = self.theme.Border
		btnStroke.Thickness = 1
		btn.MouseButton1Click:Connect(function()
			local cb = callbacks[i]
			if cb then
				local result = inputBox and inputBox.Text or true
				cb(result)
			end
			cleanup()
		end)
	end

	table.insert(self.activePopups or {}, overlay)
	table.insert(self.activePopups or {}, frame)
	TweenService:Create(frameScale, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	if inputBox then task.defer(function() inputBox:CaptureFocus() end) end
end

function UILib:alert(title, message, buttonText, callback)
	if type(buttonText) == "function" then callback, buttonText = buttonText, "OK" end
	self:showDialog({ title = title, message = message, buttons = { buttonText or "OK" }, callbacks = { callback } })
end

function UILib:prompt(label, default, callback)
	if type(default) == "function" then callback, default = default, "" end
	self:showDialog({ title = label, message = "", textInput = true, inputDefault = default or "", buttons = { "Cancel", "OK" }, callbacks = { function() end, callback } })
end

function UILib:enterResizeMode(widthSlider, heightSlider)
	if self.inResizeMode then return end
	self.inResizeMode = true

	local originalZIndex = self.window.ZIndex
	local originalClipsDescendants = self.window.ClipsDescendants
	
	self.window.ZIndex = 100
	self.window.ClipsDescendants = false

	local backdrop = Instance.new("TextButton")
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 1
	backdrop.Text = ""
	backdrop.AutoButtonColor = false
	backdrop.ZIndex = 99
	backdrop.Parent = self.sg
	
	TweenService:Create(backdrop, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { BackgroundTransparency = 0.45 }):Play()

	local resizePanel = Instance.new("Frame")
	resizePanel.Size = UDim2.new(0, 220, 0, 80)
	resizePanel.Position = UDim2.new(0.5, -110, 1, -110)
	resizePanel.BackgroundColor3 = self.theme.Panel
	resizePanel.BorderSizePixel = 0
	resizePanel.ZIndex = 101
	resizePanel.Parent = backdrop
	Instance.new("UICorner", resizePanel).CornerRadius = UDim.new(0, 8)
	local rpStroke = Instance.new("UIStroke", resizePanel)
	rpStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	rpStroke.Color = self.theme.Border

	local rpTitle = Instance.new("TextLabel")
	rpTitle.Size = UDim2.new(1, -20, 0, 16)
	rpTitle.Position = UDim2.new(0, 10, 0, 10)
	rpTitle.BackgroundTransparency = 1
	rpTitle.Text = "Resize"
	rpTitle.TextColor3 = self.theme.White
	rpTitle.Font = Enum.Font.GothamBold
	rpTitle.TextSize = 14
	rpTitle.TextXAlignment = Enum.TextXAlignment.Left
	rpTitle.ZIndex = 102
	rpTitle.Parent = resizePanel

	local rpHint = Instance.new("TextLabel")
	rpHint.Size = UDim2.new(1, -20, 0, 14)
	rpHint.Position = UDim2.new(0, 10, 0, 30)
	rpHint.BackgroundTransparency = 1
	rpHint.Text = "Drag corner handles to resize"
	rpHint.TextColor3 = self.theme.Gray
	rpHint.Font = Enum.Font.GothamSemibold
	rpHint.TextSize = 10
	rpHint.TextXAlignment = Enum.TextXAlignment.Left
	rpHint.ZIndex = 102
	rpHint.Parent = resizePanel

	local rpShortcut = Instance.new("TextLabel")
	rpShortcut.Size = UDim2.new(1, -20, 0, 14)
	rpShortcut.Position = UDim2.new(0, 10, 0, 46)
	rpShortcut.BackgroundTransparency = 1
	rpShortcut.Text = "ESC to cancel  Â·  Double-click to apply"
	rpShortcut.TextColor3 = self.theme.Gray
	rpShortcut.Font = Enum.Font.GothamSemibold
	rpShortcut.TextSize = 10
	rpShortcut.TextXAlignment = Enum.TextXAlignment.Left
	rpShortcut.ZIndex = 102
	rpShortcut.Parent = resizePanel

	local applyBtn = Instance.new("TextButton")
	applyBtn.Size = UDim2.new(0, 130, 0, 34)
	applyBtn.Position = UDim2.new(0.5, -65, 0, 120)
	applyBtn.BackgroundColor3 = self.theme.Panel
	applyBtn.AutoButtonColor = false
	applyBtn.BorderSizePixel = 0
	applyBtn.Text = "SAVE"
	applyBtn.TextColor3 = self.theme.White
	applyBtn.Font = Enum.Font.GothamBold
	applyBtn.TextSize = 12
	applyBtn.ZIndex = 102
	applyBtn.Parent = backdrop
	Instance.new("UICorner", applyBtn).CornerRadius = UDim.new(0, 5)
	local apStroke = Instance.new("UIStroke", applyBtn)
	apStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	apStroke.Color = self.theme.Border
	apStroke.Thickness = 1

	local winStroke = self.window:FindFirstChildOfClass("UIStroke")
	local originalColor = winStroke and winStroke.Color or self.theme.Border
	local pulseConn
	if winStroke then
		pulseConn = RunService.RenderStepped:Connect(function()
			local p = (math.sin(tick() * 4) + 1) / 2
			winStroke.Color = Color3.new(
				self.theme.Accent.r * p + originalColor.r * (1 - p),
				self.theme.Accent.g * p + originalColor.g * (1 - p),
				self.theme.Accent.b * p + originalColor.b * (1 - p)
			)
		end)
	end

	local handles = {}
	local activeCorner = nil

	local cornerConfigs = {
		BR = { Pos = UDim2.new(1, 0, 1, 0), Rot = 0 },
		BL = { Pos = UDim2.new(0, 0, 1, 0), Rot = 90 },
		TL = { Pos = UDim2.new(0, 0, 0, 0), Rot = 180 },
		TR = { Pos = UDim2.new(1, 0, 0, 0), Rot = 270 }
	}

	local dragging = false
	local startMouse = Vector2.new(0, 0)
	local startSize = Vector2.new(0, 0)
	local startPos = UDim2.new(0, 0, 0, 0)
	local dragConn
	local dragEndConn

	for cornerName, config in pairs(cornerConfigs) do
		local handle = Instance.new("ImageButton")
		handle.Name = "ResizeHandle_" .. cornerName
		handle.Size = UDim2.new(0, 36, 0, 36)
		handle.Position = config.Pos
		handle.AnchorPoint = Vector2.new(0.5, 0.5)
		handle.BackgroundTransparency = 1
		handle.Image = "rbxassetid://16168010419"
		handle.Rotation = config.Rot
		handle.ImageColor3 = self.theme.Accent
		handle.ZIndex = 105
		handle.Parent = self.window
		handles[cornerName] = handle

		handle.MouseEnter:Connect(function()
			TweenService:Create(handle, TweenInfo.new(0.15, Enum.EasingStyle.Quad), { Size = UDim2.new(0, 42, 0, 42) }):Play()
		end)
		handle.MouseLeave:Connect(function()
			TweenService:Create(handle, TweenInfo.new(0.15, Enum.EasingStyle.Quad), { Size = UDim2.new(0, 36, 0, 36) }):Play()
		end)

		handle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				activeCorner = cornerName
				dragging = true
				startMouse = UIS:GetMouseLocation()
				startSize = self.size
				startPos = self.window.Position
			end
		end)
	end

	local function exitMode()
		self.inResizeMode = false
		self.window.ZIndex = originalZIndex
		self.window.ClipsDescendants = originalClipsDescendants
		if pulseConn then pulseConn:Disconnect() end
		if dragConn then dragConn:Disconnect() end
		if dragEndConn then dragEndConn:Disconnect() end
		if winStroke then winStroke.Color = originalColor end
		
		TweenService:Create(backdrop, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play()
		task.delay(0.2, function()
			backdrop:Destroy()
		end)
		for _, h in pairs(handles) do
			pcall(function() h:Destroy() end)
		end

		local finalW = math.floor(self.size.X)
		local finalH = math.floor(self.size.Y)
		self.size = Vector2.new(finalW, finalH)
		self.window.Size = UDim2.new(0, finalW, 0, finalH)
		self.originalPosition = self.window.Position
		self.updateLayout()
		task.defer(function() if self.updateLayout then self:updateLayout() end end)

		if widthSlider and widthSlider.SetValue then
			pcall(function() widthSlider:SetValue(finalW) end)
		end
		if heightSlider and heightSlider.SetValue then
			pcall(function() heightSlider:SetValue(finalH) end)
		end

		self:notify("Menu resized: " .. finalW .. "x" .. finalH, "success", 2)
	end

	dragConn = UIS.InputChanged:Connect(function(input)
		if dragging and activeCorner and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local mousePos = UIS:GetMouseLocation()
			local deltaX, deltaY
			
			if activeCorner == "BR" then
				deltaX = mousePos.X - startMouse.X
				deltaY = mousePos.Y - startMouse.Y
			elseif activeCorner == "BL" then
				deltaX = startMouse.X - mousePos.X
				deltaY = mousePos.Y - startMouse.Y
			elseif activeCorner == "TR" then
				deltaX = mousePos.X - startMouse.X
				deltaY = startMouse.Y - mousePos.Y
			elseif activeCorner == "TL" then
				deltaX = startMouse.X - mousePos.X
				deltaY = startMouse.Y - mousePos.Y
			end
			
			local newW = math.max(450, math.min(1200, startSize.X + deltaX))
			local newH = math.max(350, math.min(800, startSize.Y + deltaY))

			local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
			newW = math.min(newW, vp.X - 40)
			newH = math.min(newH, vp.Y - 60)

			local changeX = newW - startSize.X
			local changeY = newH - startSize.Y

			self.size = Vector2.new(newW, newH)
			self.window.Size = UDim2.new(0, newW, 0, newH)
			
			local offsetX, offsetY
			if activeCorner == "BR" then
				offsetX = changeX / 2
				offsetY = changeY / 2
			elseif activeCorner == "BL" then
				offsetX = -changeX / 2
				offsetY = changeY / 2
			elseif activeCorner == "TR" then
				offsetX = changeX / 2
				offsetY = -changeY / 2
			elseif activeCorner == "TL" then
				offsetX = -changeX / 2
				offsetY = -changeY / 2
			end
			
			self.window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + offsetX, startPos.Y.Scale, startPos.Y.Offset + offsetY)
			self.updateLayout()
		end
	end)

	dragEndConn = UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	applyBtn.MouseButton1Click:Connect(exitMode)
	backdrop.MouseButton1Click:Connect(function()
		local lastClick = backdrop:GetAttribute("LastClick") or 0
		if tick() - lastClick < 0.35 then
			exitMode()
		else
			backdrop:SetAttribute("LastClick", tick())
		end
	end)

	local escConn
	escConn = UIS.InputBegan:Connect(function(input, gpe)
		if not self.inResizeMode then
			escConn:Disconnect()
			return
		end
		if input.KeyCode == Enum.KeyCode.Escape then
			escConn:Disconnect()
			exitMode()
		end
	end)
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
		btn.AutoButtonColor = false
		btn.Parent = btnRow
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
		local btnBdr = Instance.new("UIStroke", btn)
		btnBdr.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		btnBdr.Color = self.theme.Border
		btnBdr.Thickness = 1
		btn.MouseButton1Click:Connect(function()
			overlay:Destroy()
			modal:Destroy()
			self:SafeCallback(callback)
		end)
	end

	makeBtn("Cancel", self.theme.Track, 0, function() if onNo then onNo() end; if onYes then onYes(false) end end)
	makeBtn("Confirm", self.theme.Track, 0.5, function() if onYes then onYes(true) end end)

	local tweenIn = TweenService:Create(modal, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.new(0, 300, 0, 130) })
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
	collapseBtn.Text = "-"
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
		collapseBtn.Text = collapsed and "+" or "-"
		local targetH = collapsed and 32 or fullH
		body.Visible = not collapsed
		TweenService:Create(frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, width, 0, targetH)
		}):Play()
	end)

	do
		local drag, dragStart, dragPos = false, nil, nil
		header.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				drag = true
				dragStart = i.Position
				dragPos = frame.Position
			end
		end)
		local dc = UIS.InputChanged:Connect(function(i)
			if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
				local delta = i.Position - dragStart
				frame.Position = UDim2.new(dragPos.X.Scale, dragPos.X.Offset + delta.X, dragPos.Y.Scale,
					dragPos.Y.Offset + delta.Y)
			end
		end)
		local de = UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end end)
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
		val.Text = tostring(defaultValue or "-")
		val.TextColor3 = color or self.window.theme.Accent
		val.Font = Enum.Font.GothamSemibold
		val.TextSize = 12
		val.TextXAlignment = Enum.TextXAlignment.Right
		val.ZIndex = 303
		val.Parent = row
		if not color then table.insert(self.window.accentObjects, val) end
		local rowRef = { label = lbl, value = val }
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
	track.Position = UDim2.new(0, 0, 0, 26)
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
		local ref = { label = lbl, value = valLbl, fill = fill }
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
		local navW = self.size.X
		local count = self.navTabCount
		if count == 0 then return end
		local navH = self.navbarHeight or 46
		if navW / count < MIN_TAB_WIDTH then
			for _, child in ipairs(self.navbar:GetChildren()) do
				if child:IsA("TextButton") then child.Size = UDim2.new(0, MIN_TAB_WIDTH, 0, navH) end
			end
		else
			for _, child in ipairs(self.navbar:GetChildren()) do
				if child:IsA("TextButton") then child.Size = UDim2.new(1 / count, 0, 0, navH) end
			end
		end
	end
	self.refreshTabWidths = refreshTabWidths

	local tabIconId = UILib.resolveIcon(options.icon)

	if tabIconId and (not self.navbarHeight or self.navbarHeight < 58) then
		self.navbarHeight = 58
		self.navbar.Size = UDim2.new(1, 0, 0, 58)
		self.navbar.Position = UDim2.new(0, 0, 1, -58)
		if self.navbarBG then
			self.navbarBG.Size = UDim2.new(1, 0, 0, 58)
			self.navbarBG.Position = UDim2.new(0, 0, 1, -58)
		end

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
		if self.tabOverlay then self.tabOverlay.Size = UDim2.new(1, 0, 1, -138) end

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
	btn.ZIndex = 2
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
	tabLbl.TextSize = 12
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
	underline.Size = UDim2.new(0.4, 0, 0, 2)
	underline.AnchorPoint = Vector2.new(0.5, 1)
	underline.Position = UDim2.new(0.5, 0, 1, 0)
	underline.BackgroundColor3 = self.theme.Accent
	underline.BorderSizePixel = 0
	underline.ZIndex = 3
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
		if self.activeTab == tab then return end
		-- Clear search on tab switch
		if self.headerSearchFrame and self.headerSearchFrame.Visible then
			self.headerSearchBox.Text = ""
			self.headerSearchFrame.Visible = false
		end
		for _, panel in ipairs(self.sg:GetDescendants()) do
			if panel.Name == "ExpandPanel" and panel.Visible then
				panel.Visible = false
				panel.Parent = panel.Parent
				panel.Size = UDim2.new(1, 0, 0, 0)
				local p = panel.Parent
				if p and p:IsA("Frame") and p.Size.Y.Offset > 56 then
					p.Size = UDim2.new(1, 0, 0, 56)
				end
			end
		end
		-- Animate tab switch with tweened overlay
		if self.content then
			local overlay = Instance.new("Frame")
			overlay.Size = UDim2.new(1, 0, 1, 0)
			overlay.BackgroundColor3 = self.theme.BG
			overlay.BorderSizePixel = 0
			overlay.ZIndex = 500
			overlay.Parent = self.content
			TweenService:Create(overlay, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ BackgroundTransparency = 1 }):Play()
			task.delay(0.16, function() pcall(function() overlay:Destroy() end) end)
		end

		for _, t in pairs(self.tabs) do
			for _, sub in pairs(t.subtabs) do
				sub.btn.Visible = false
				sub.page.Visible = false
				if sub.selGradient then sub.selGradient.Visible = false end
				if sub.label then sub.label.TextColor3 = self.theme.Gray end
			end
		end
		if self.activeTab then
			if self.activeTab.tabLbl then self.activeTab.tabLbl.TextColor3 = self.theme.Gray end
			if self.activeTab.tabIcon and self.activeTab.tabIconId then
				self.activeTab.tabIcon.ImageColor3 = self.theme
					.Gray
			end
			if self.activeTab.underline then self.activeTab.underline.Visible = false end
		end
		tabLbl.TextColor3 = self.theme.White
		if tabIconId then tabIcon.ImageColor3 = self.theme.Accent end
		underline.Size = UDim2.new(0, 0, 0, 3)
		underline.Visible = true
		TweenService:Create(underline, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = UDim2.new(0.4, 0, 0, 3) }):Play()
		for _, sub in pairs(tab.subtabOrder) do
			if sub.btn then
				sub.btn.Visible = true
				-- Slide-in animation for subtab buttons
				sub.btn.Position = UDim2.new(0, -30, 0, 0)
				TweenService:Create(sub.btn, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Position = UDim2.new(0, 4, 0, 0) }):Play()
			end
		end
		if tab.firstSub then
			local target = tab.lastSub or tab.subtabs[tab.firstSub]
			if target then target:select() end
		end
		self.sidebar.CanvasSize = UDim2.new(1, 0, 0, #tab.subtabOrder * 40 + 10)
		self.activeTab = tab

		local showSidebar = tab.showSidebar ~= false
		self.sidebar.Visible = showSidebar
		self.sidebarEdge.Visible = showSidebar
		local sw = self.getSidebarWidth()
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
	if self.headerSearchBox then
		self.headerSearchBox.Text = ""
	end
	if self.headerSearchFrame then
		self.headerSearchFrame.Visible = false
	end
end

function UILib.Tab:addSubTab(name, description)
	local sub = setmetatable({}, UILib.SubTab)
	sub.name = name
	sub.tab = self
	sub.window = self.window
	sub.groups = {}

	local btn = Instance.new("TextButton")
	table.insert(self.subtabOrder, sub)
	btn.Size = UDim2.new(1, -8, 0, 36)
	btn.Position = UDim2.new(0, 4, 0, 0)
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Visible = false
	btn.ZIndex = 5
	btn.ClipsDescendants = false
	btn.Parent = self.window.sidebar

	local hov = Instance.new("Frame")
	hov.Size = UDim2.new(1, 0, 1, 0)
	hov.BackgroundColor3 = self.window.theme.ItemHov
	hov.BorderSizePixel = 0
	hov.BackgroundTransparency = 1
	hov.ZIndex = 4
	hov.Parent = btn
	Instance.new("UICorner", hov).CornerRadius = UDim.new(0, 5)
	sub.hovFrame = hov

	local selLine = Instance.new("Frame")
	selLine.Size = UDim2.new(0, 3, 1, 0)
	selLine.BackgroundColor3 = self.window.theme.Accent
	selLine.BorderSizePixel = 0
	selLine.Visible = false
	selLine.ZIndex = 7
	selLine.Parent = btn
	sub.selLine = selLine

	local selGradient = Instance.new("Frame")
	selGradient.Size = UDim2.new(1, 0, 1, 0)
	selGradient.BackgroundColor3 = Color3.new(1, 1, 1)
	selGradient.BackgroundTransparency = 0.95
	selGradient.BorderSizePixel = 0
	selGradient.Visible = false
	selGradient.ZIndex = 4
	selGradient.Parent = btn
	local grad = Instance.new("UIGradient", selGradient)
	grad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	sub.selGradient = selGradient

	local textCol = Instance.new("Frame")
	textCol.Size = UDim2.new(1, -12, 1, -4)
	textCol.Position = UDim2.new(0, 8, 0, 1)
	textCol.BackgroundTransparency = 1
	textCol.ZIndex = 6
	textCol.Parent = btn
	local colLayout = Instance.new("UIListLayout", textCol)
	colLayout.SortOrder = Enum.SortOrder.LayoutOrder
	colLayout.Padding = UDim.new(0, 0)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 15)
	label.BackgroundTransparency = 1
	label.Text = name
	label.TextColor3 = self.window.theme.Gray
	label.Font = Enum.Font.GothamBold
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 6
	label.LayoutOrder = 1
	label.Parent = textCol

	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, 0, 0, 0)
	desc.BackgroundTransparency = 1
	desc.Text = description or ""
	desc.TextColor3 = self.window.theme.Gray
	desc.Font = Enum.Font.GothamSemibold
	desc.TextSize = 10
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextWrapped = true
	desc.AutomaticSize = Enum.AutomaticSize.Y
	desc.ZIndex = 6
	desc.LayoutOrder = 2
	desc.Parent = textCol
	sub.desc = desc

	function sub:select()
		for _, t in pairs(self.window.tabs) do
			if t.tabLbl then t.tabLbl.TextColor3 = self.window.theme.Gray end
			if t.underline then t.underline.Visible = false end
			for _, s in pairs(t.subtabs) do
				s.btn.Visible = false
				s.page.Visible = false
				if s.selGradient then s.selGradient.Visible = false end
				if s.selLine then s.selLine.Visible = false end
				s.label.TextColor3 = self.window.theme.Gray
			end
		end
		self.tab.tabLbl.TextColor3 = self.window.theme.White
		if self.tab.underline then self.tab.underline.Visible = true end
		for _, s in pairs(self.tab.subtabs) do s.btn.Visible = true end
		self.window.activeTab = self.tab
		self.label.TextColor3 = self.window.theme.White
		if self.selGradient then self.selGradient.Visible = true end
		if self.selLine then self.selLine.Visible = true end
		self.page.Visible = true
		self.tab.lastSub = self
		self.window.sidebar.CanvasSize = UDim2.new(1, 0, 0, #self.tab.subtabOrder * 40 + 10)
	end

	btn.MouseEnter:Connect(function()
		TweenService:Create(hov, TweenInfo.new(0.08), { BackgroundTransparency = 0 }):Play()
		if label.TextColor3 ~= self.window.theme.White then
			TweenService:Create(label, TweenInfo.new(0.08), { TextColor3 = self.window.theme.White }):Play()
		end
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(hov, TweenInfo.new(0.08), { BackgroundTransparency = 1 }):Play()
		if label.TextColor3 ~= self.window.theme.White then
			TweenService:Create(label, TweenInfo.new(0.08), { TextColor3 = self.window.theme.Gray }):Play()
		end
	end)

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
	sub.label = label
	sub.page = page
	sub.layout = layout

	btn.MouseButton1Click:Connect(function() sub:select() end)

	if not self.firstSub then self.firstSub = name end
	self.subtabs[name] = sub
	table.insert(self.window.allSubTabs, { name = name, btn = btn, tab = self })
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

local elemCounter = 0
local function generateID() elemCounter = elemCounter + 1; return "elem_" .. elemCounter end

local function attachTooltip(element, text, window)
	if not text or not window or not window.tooltip then return end
	local tt = window.tooltip
	element.MouseEnter:Connect(function()
		if window.tooltipSuppressed then return end
		tt.show(text, element)
	end)
	element.MouseLeave:Connect(function() tt.hide() end)
end

function UILib.SubTab:addParagraph(ptitle, text)
	local window                             = self.window
	local r                                  = Instance.new("Frame")
	r.Size                                   = UDim2.new(1, 0, 0, 0)
	r.BackgroundColor3                       = window.theme.Item
	r.BackgroundTransparency                 = 0.35
	r.BorderSizePixel                        = 0
	r.AutomaticSize                          = Enum.AutomaticSize.Y
	r.Parent                                 = self.page
	Instance.new("UICorner", r).CornerRadius = UDim.new(0, 6)
	local stroke                             = Instance.new("UIStroke", r)
	stroke.ApplyStrokeMode                   = Enum.ApplyStrokeMode.Border
	stroke.Color                             = window.theme.Border
	stroke.Thickness                         = 1
	local pad                                = Instance.new("UIPadding", r)
	pad.PaddingLeft                          = UDim.new(0, 10)
	pad.PaddingRight                         = UDim.new(0, 10)
	pad.PaddingTop                           = UDim.new(0, 8)
	pad.PaddingBottom                        = UDim.new(0, 10)
	local lbl                                = Instance.new("TextLabel")
	lbl.Size                                 = UDim2.new(1, 0, 0, 0)
	lbl.BackgroundTransparency               = 1
	lbl.Text                                 = ptitle
	lbl.TextColor3                           = window.theme.Accent
	lbl.Font                                 = Enum.Font.GothamBold
	lbl.TextSize                             = 13
	lbl.TextXAlignment                       = Enum.TextXAlignment.Left
	lbl.AutomaticSize                        = Enum.AutomaticSize.Y
	lbl.TextWrapped                          = true
	lbl.LayoutOrder                          = 1
	lbl.ZIndex                               = 2
	lbl.Parent                               = r
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

	function ref:setDesc(d) body.Text = d end

	function ref:SetDesc(d) body.Text = d end

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
	lbl.TextWrapped = true
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
			current = box.Text
			window:SafeCallback(callback, current)
	end)
	local elem = {
		ID = id,
		Value = current,
		DefaultValue = default or "",
		label = labelText,
		frame = r,
		DefaultHeight = 52,
		SetValue = function(val)
			current = val
			box.Text = val
		end
	}
	function elem:SetVisible(v, anim)
		if not anim then
			r.Visible = v
			r.Size = UDim2.new(1, 0, 0, v and 52 or 0)
			return
		end
		r.ClipsDescendants = true
		if v then r.Visible = true end
		local tw = TweenService:Create(r, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 0, v and 52 or 0)
		})
		tw.Completed:Connect(function() if not v then r.Visible = false end end)
		tw:Play()
	end
	function elem:SetDesc(d) lbl.Text = d end

	return elem
end

function UILib.SubTab:addButton(text, callback, tooltip, color)
	local window = self.window
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 36)
	btn.BackgroundColor3 = window.theme.Item
	btn.AutoButtonColor = false
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
		lbl.TextColor3 = window.theme.GrayLt
		lbl.Font = Enum.Font.GothamSemibold
		lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Center
	lbl.ZIndex = 4
	lbl.Parent = btn
	btn.MouseButton1Click:Connect(callback)
	btn.remove = function() btn:Destroy() end
	return btn
end

	local function finalizeElement(elem, win, grp)
	local _origValue = elem.Value
	setmetatable(elem, {
		__index = function(t, k)
			if k == "Value" then return _origValue end
			return rawget(t, k)
		end,
		__newindex = function(t, k, v)
			if k == "Value" then
				_origValue = v
				if win and win._dirty ~= nil then win._dirty = true end
			end
			rawset(t, k, v)
		end
	})
	elem.Value = _origValue
	function elem:remove()
		if self.frame and self.frame.Parent then self.frame:Destroy() end
		if win and win.configs then win.configs[self.ID] = nil end
		if grp and grp.updateSize then grp.updateSize() end
	end
	return elem
end

local function createSlider(group, items, window, text, minVal, maxVal, defaultVal, callback, step, cfgId, settingsCallback)
	step = step or 1
	local id = generateID()
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 52)
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.Parent = items

	local topRow = Instance.new("Frame")
	topRow.Size = UDim2.new(1, 0, 0, 18)
	topRow.Position = UDim2.new(0, 0, 0, 4)
	topRow.BackgroundTransparency = 1
	topRow.Parent = row
	local topLayout = Instance.new("UIListLayout", topRow)
	topLayout.FillDirection = Enum.FillDirection.Horizontal
	topLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	topLayout.Padding = UDim.new(0, 6)
	topLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 0, 0, 16)
	label.AutomaticSize = Enum.AutomaticSize.X
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = window.theme.White
	label.Font = Enum.Font.GothamSemibold
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.ZIndex = 3
	label.LayoutOrder = 1
	label.Parent = topRow

	local valueBox = Instance.new("Frame")
	valueBox.AutomaticSize = Enum.AutomaticSize.X
	valueBox.Size = UDim2.new(0, 0, 0, 18)
	valueBox.BackgroundColor3 = window.theme.Track
	valueBox.BorderSizePixel = 0
	valueBox.ZIndex = 3
	valueBox.LayoutOrder = 2
	valueBox.Parent = topRow
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
		valueLabel.Text = cleanNum(defaultVal)
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
	valueBoxInput.Text = cleanNum(defaultVal)
	valueBoxInput.TextColor3 = window.theme.Accent
	valueBoxInput.Font = Enum.Font.GothamSemibold
	valueBoxInput.TextSize = 12
	valueBoxInput.Visible = false
	valueBoxInput.ZIndex = 5
	valueBoxInput.Parent = valueBox
	Instance.new("UICorner", valueBoxInput).CornerRadius = UDim.new(0, 4)
	if type(settingsCallback) == "function" then
		local gearBtn = Instance.new("ImageLabel")
		local gi = window:lucide("settings")
		gearBtn.Size = UDim2.new(0, 14, 0, 14)
		gearBtn.Position = UDim2.new(1, -18, 0.5, -7)
		gearBtn.BackgroundTransparency = 1
		gearBtn.Image = gi or ""
		gearBtn.ImageColor3 = window.theme.GrayLt
		gearBtn.ScaleType = Enum.ScaleType.Fit
		gearBtn.ZIndex = 5
		gearBtn.Parent = topRow
		local gb = Instance.new("TextButton")
		gb.Size = UDim2.new(1, 8, 1, 8)
		gb.BackgroundTransparency = 1
		gb.Text = ""
		gb.ZIndex = 6
		gb.Parent = gearBtn
		gb.MouseButton1Click:Connect(function()
			if type(settingsCallback) == "function" then
				settingsCallback(gearBtn)
			end
		end)
	end
	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, 0, 0, 22)
	track.Position = UDim2.new(0, 0, 0, 26)
	track.BackgroundColor3 = window.theme.Track
	track.BorderSizePixel = 0
	track.ZIndex = 3
	track.Parent = row
	Instance.new("UICorner", track).CornerRadius = UDim.new(0, 4)
	local trackStroke = Instance.new("UIStroke", track)
	trackStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	trackStroke.Color = window.theme.Border
	trackStroke.Thickness = 1
	local numSteps = math.floor((maxVal - minVal) / step)
	if numSteps > 1 and numSteps <= 50 then
		for i = 0, numSteps do
			local pct = i / numSteps
			local tickMark = Instance.new("Frame")
				tickMark.Size = UDim2.new(0, 1, 0, 6)
				tickMark.Position = UDim2.new(pct, 0, 0.5, -3)
				tickMark.BackgroundColor3 = window.theme.Border
				tickMark.BorderSizePixel = 0
				tickMark.ZIndex = 5
				tickMark.Parent = track
		end
	end

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
	fill.BackgroundColor3 = window.theme.Accent
	fill.BorderSizePixel = 0
	fill.ZIndex = 4
	fill.Parent = track
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)
	table.insert(window.accentObjects, fill)
	local sliderHandle = Instance.new("Frame")
	sliderHandle.Name = "SliderHandle"
	sliderHandle.Size = UDim2.new(0, 5, 0, 22)
	sliderHandle.BackgroundColor3 = Color3.new(window.theme.Accent.r * 0.55, window.theme.Accent.g * 0.55, window.theme.Accent.b * 0.55)
	sliderHandle.BorderSizePixel = 0
	sliderHandle.ZIndex = 5
	sliderHandle.Parent = track
	local relInit = (defaultVal - minVal) / (maxVal - minVal)
	sliderHandle.Position = UDim2.new(relInit, relInit > 0.01 and -4 or 0, 0, 0)
	sliderHandle.Visible = true
	table.insert(window.accentDarkObjects, sliderHandle)

	local hit = Instance.new("TextButton")
	hit.Size = UDim2.new(1, 0, 1, 0)
	hit.Position = UDim2.new(0, 0, 0, 0)
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.ZIndex = 6
	hit.Parent = track
	local sliding = false
	local currentVal = defaultVal
	local sliderDisplay = nil
	local function roundToStep(val) return math.floor((val - minVal) / step + 0.5) * step + minVal end
	local function formatVal(val)
		if type(sliderDisplay) == "function" then return sliderDisplay(val) end
		if sliderDisplay == "%" then return math.floor(val * 100 + 0.5) .. "%" end
		if sliderDisplay == "k" then
			if val >= 1000000 then return ("%.1fM"):format(val / 1000000)
			elseif val >= 1000 then return ("%.1fk"):format(val / 1000)
			else return cleanNum(val) end
		end
		return cleanNum(val)
	end
	local function updateSlider(val)
		val = math.clamp(val, minVal, maxVal)
		val = roundToStep(val)
		currentVal = val
		local rel = (val - minVal) / (maxVal - minVal)
		fill.Size = UDim2.new(rel, 0, 1, 0)
		if sliderHandle then sliderHandle.Position = UDim2.new(rel, rel > 0.01 and -4 or 0, 0, 0) end
		valueLabel.Text = formatVal(val)
		valueBoxInput.Text = cleanNum(val)
		window:SafeCallback(callback, val)
		window.configs[id].Value = val
	end
		local function apply(mx)
		local trackSize = track.AbsoluteSize.X
		if trackSize == 0 then trackSize = 1 end
		local rel = math.clamp((mx - track.AbsolutePosition.X) / trackSize, 0, 1)
		local val = minVal + (maxVal - minVal) * rel
		updateSlider(val)
	end
	hit.MouseButton1Down:Connect(function()
		sliding = true
		apply(UIS:GetMouseLocation().X)
	end)
	local sliderInputConn = UIS.InputChanged:Connect(function(i)
		if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			apply(i.Position.X)
		end
	end)
	local sliderEndConn = UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sliding = false end end)
	table.insert(window.connections, sliderInputConn)
	table.insert(window.connections, sliderEndConn)
	valueLabel.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			valueLabel.Visible = false
			valueBoxInput.Visible = true
			valueBoxInput:CaptureFocus()
			valueBoxInput.Text = cleanNum(currentVal)
			valueBoxInput.TextColor3 = window.theme.Accent
		end
	end)
	valueBoxInput.FocusLost:Connect(function(enter)
		valueBoxInput.Visible = false
		valueLabel.Visible = true
		local num = tonumber(valueBoxInput.Text)
		if num then updateSlider(num) else valueLabel.Text = cleanNum(currentVal) end
	end)
	local elem = { ID = id, Value = currentVal, DefaultValue = defaultVal, label = cfgId or text, SetValue = updateSlider, frame = row, DefaultHeight = 42, _display = nil }
	function elem:setDisplay(mode) sliderDisplay = mode end
	function elem:SetVisible(v, anim)
		if not anim then
			row.Visible = v
			row.Size = UDim2.new(1, 0, 0, v and 52 or 0)
			if v then row.ClipsDescendants = false end
			if group and group.updateSize then group.updateSize() end
			return
		end
		row.ClipsDescendants = true
		if v then row.Visible = true end
		local tw = TweenService:Create(row, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 0, v and 52 or 0)
		})
		tw.Completed:Connect(function()
			if not v then row.Visible = false end
			if v then row.ClipsDescendants = false end
			if group and group.updateSize then group.updateSize() end
		end)
		tw:Play()
	end
	elem.SetDesc = function(self_or_d, d) if type(self_or_d) == "string" then label.Text = self_or_d else label.Text = d end end
	window.configs[id] = finalizeElement(elem, window, group)
	return row, elem
end

local _pickerCons = {}

local function createColorPicker(group, items, window, text, default, callback, cfgId, settingsCallback)
	local id = generateID()
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 32)
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.Parent = items
	local rightOffset = 0
	local colorBox = Instance.new("TextButton")
	colorBox.Size = UDim2.new(0, 22, 0, 22)
	colorBox.Position = UDim2.new(1, -(26 + rightOffset), 0.5, -11)
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
	rightOffset = rightOffset + 30
	if type(settingsCallback) == "function" then
		local gearBtn = Instance.new("ImageLabel")
		local gi = window:lucide("settings")
		gearBtn.Size = UDim2.new(0, 14, 0, 14)
		gearBtn.Position = UDim2.new(1, -(rightOffset + 14), 0.5, -7)
		gearBtn.BackgroundTransparency = 1
		gearBtn.Image = gi or ""
		gearBtn.ImageColor3 = window.theme.GrayLt
		gearBtn.ScaleType = Enum.ScaleType.Fit
		gearBtn.ZIndex = 5
		gearBtn.Parent = row
		local gb = Instance.new("TextButton")
		gb.Size = UDim2.new(1, 8, 1, 8)
		gb.BackgroundTransparency = 1
		gb.Text = ""
		gb.ZIndex = 6
		gb.Parent = gearBtn
		gb.MouseButton1Click:Connect(function()
			if type(settingsCallback) == "function" then
				settingsCallback(gearBtn)
			end
		end)
		rightOffset = rightOffset + 16
	end
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -(62 + rightOffset), 1, 0)
	label.Position = UDim2.new(0, 4, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = window.theme.White
	label.Font = Enum.Font.GothamSemibold
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.ZIndex = 3
	label.Parent = row
	local current = default or Color3.new(1, 0, 0)
	local elem = { ID = id, Value = current, label = cfgId or text }
	local pickerFrame = nil

	elem.SetValue = function(val)
		current = val
		elem.Value = val
		colorBox.BackgroundColor3 = val
		window:SafeCallback(callback, val)
	end
	function elem:SetColor(val)
		current = val
		elem.Value = val
		colorBox.BackgroundColor3 = val
	end
	elem.colorBox = colorBox
	elem.frame = row
	elem.DefaultHeight = 32
	function elem:SetVisible(v, anim)
		if not anim then
			row.Visible = v
			row.Size = UDim2.new(1, 0, 0, v and 32 or 0)
			if group and group.updateSize then group.updateSize() end
			return
		end
		row.ClipsDescendants = true
		if v then row.Visible = true end
		local tw = TweenService:Create(row, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 0, v and 32 or 0)
		})
		tw.Completed:Connect(function()
			if not v then row.Visible = false end
			if group and group.updateSize then group.updateSize() end
		end)
		tw:Play()
	end
	window.configs[id] = finalizeElement(elem, window, group)

	local function closePicker()
		if pickerFrame then
			window._pickerOpen = false
			local p = pickerFrame
			local cons = _pickerCons[p]
			if cons then
				for _, c in ipairs(cons) do
					pcall(c.Disconnect, c)
				end
				_pickerCons[p] = nil
			end
			local sc = p:FindFirstChildOfClass("UIScale")
			if sc then
				local t = TweenService:Create(sc, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{ Scale = 0 })
				t:Play()
				t.Completed:Connect(function()
					pcall(function() p:Destroy() end)
				end)
			else
				p:Destroy()
			end
		end
	end

	local function openPicker()
		if window.tooltip then window.tooltip.hide() end
		window._pickerOpen = true
		if pickerFrame and pickerFrame.Parent then return end
		if window._openingPicker then return end
		window._openingPicker = true
		task.delay(0.15, function() window._openingPicker = nil end)
		local pickerJustOpened = true
		task.delay(0.1, function() pickerJustOpened = false end)

		local pickerW, pickerH = 240, 230
		pickerFrame = Instance.new("Frame")
		pickerFrame.Size = UDim2.new(0, pickerW, 0, pickerH)
		pickerFrame.BackgroundColor3 = window.theme.Surface
		pickerFrame.BorderSizePixel = 0
		pickerFrame.ZIndex = 9999
		pickerFrame.Parent = window.sg
		pickerFrame.Destroying:Connect(function()
			local cons = _pickerCons[pickerFrame]
			if cons then
				for _, c in ipairs(cons) do pcall(c.Disconnect, c) end
				_pickerCons[pickerFrame] = nil
			end
			pickerFrame = nil
		end)
		table.insert(window.activePopups, pickerFrame)

		local blocker = Instance.new("TextButton", pickerFrame)
		blocker.Size = UDim2.fromScale(1, 1)
		blocker.BackgroundTransparency = 1
		blocker.Text = ""
		blocker.ZIndex = 0
		blocker.Active = true

		local pickerScale = Instance.new("UIScale", pickerFrame)
		pickerScale.Scale = 0

		Instance.new("UICorner", pickerFrame).CornerRadius = UDim.new(0, 10)
		local pickerStroke = Instance.new("UIStroke", pickerFrame)
		pickerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		pickerStroke.Color = window.theme.Border
		pickerStroke.Transparency = 0.2
		pickerStroke.Thickness = 1.5

		local screenW = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 1920
		local screenH = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 1080
		local pad = 5
		local boxAbs = colorBox.AbsolutePosition
		local boxSize = colorBox.AbsoluteSize
		local targetX = boxAbs.X
		if not boxAbs or boxAbs.X < 1 then
			local wa = window.window.AbsolutePosition or Vector2.new(200, 200)
			local ws = window.window.AbsoluteSize or Vector2.new(500, 400)
			targetX = wa.X + ws.X - pickerW - 30
		end
		targetX = math.clamp(targetX, pad, screenW - pickerW - pad)
		local targetY = boxAbs.Y + boxSize.Y + 65
		if not boxAbs or boxAbs.Y < 1 then
			local wa = window.window.AbsolutePosition or Vector2.new(200, 200)
			targetY = wa.Y + 120
		end
		if targetY + pickerH > screenH - pad then targetY = boxAbs.Y - pickerH - 30 end
		targetY = math.clamp(targetY, pad, screenH - pickerH - pad)
		pickerFrame.Position = UDim2.new(0, targetX, 0, targetY)

		TweenService:Create(pickerScale, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{ Scale = 1 }):Play()

		local satValSquare, satValKnob, hueSlider, hueKnob, hexBox
		local hueDragging, svDragging = false, false
		local h_, s_, v_
		if typeof(current) == "Color3" then
			h_, s_, v_ = Color3.toHSV(current)
		else
			h_, s_, v_ = 0, 1, 1
		end

		local function update()
			local h = hueKnob.Position.X.Scale
			local s = math.clamp(satValKnob.Position.X.Scale, 0, 1)
			local v = math.clamp(1 - satValKnob.Position.Y.Scale, 0, 1)
			current = Color3.fromHSV(h, s, v)
			elem.Value = current
			satValSquare.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			colorBox.BackgroundColor3 = current
		hexBox.Text = "#" .. (typeof(current) == "Color3" and current:ToHex() or "FFFFFF")
			window:SafeCallback(callback, current)
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
		pickerTitle.Size = UDim2.new(1, -PAD * 2, 1, 0)
		pickerTitle.Position = UDim2.new(0, PAD, 0, 0)
		pickerTitle.BackgroundTransparency = 1
		pickerTitle.Text = text
		pickerTitle.TextColor3 = window.theme.White
		pickerTitle.Font = Enum.Font.GothamBold
		pickerTitle.TextSize = 12
		pickerTitle.TextXAlignment = Enum.TextXAlignment.Left
		pickerTitle.Parent = pickerHeader

		satValSquare = Instance.new("Frame")
		satValSquare.Size = UDim2.new(1, -PAD * 2, 0, 120)
		satValSquare.Position = UDim2.new(0, PAD, 0, headerHeight)
		satValSquare.BackgroundColor3 = Color3.fromHSV(h_, 1, 1)
		satValSquare.BorderSizePixel = 0
		satValSquare.ZIndex = 2001
		satValSquare.Parent = pickerFrame
		Instance.new("UICorner", satValSquare).CornerRadius = UDim.new(0, 4)

		local satGrad = Instance.new("Frame", satValSquare)
		satGrad.Size = UDim2.fromScale(1, 1)
		satGrad.BackgroundTransparency = 0
		satGrad.BorderSizePixel = 0
		satGrad.ZIndex = 2002
		local satUIGrad = Instance.new("UIGradient", satGrad)
		satUIGrad.Color = ColorSequence.new(Color3.new(1, 1, 1))
		satUIGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1)
		})

		local valGrad = Instance.new("Frame", satValSquare)
		valGrad.Size = UDim2.fromScale(1, 1)
		valGrad.BackgroundTransparency = 0
		valGrad.BorderSizePixel = 0
		valGrad.ZIndex = 2003
		local valUIGrad = Instance.new("UIGradient", valGrad)
		valUIGrad.Rotation = 90
		valUIGrad.Color = ColorSequence.new(Color3.new(0, 0, 0))
		valUIGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0)
		})

		satValKnob = Instance.new("Frame")
		satValKnob.Size = UDim2.new(0, 12, 0, 12)
		satValKnob.Position = UDim2.new(s_, -6, 1 - v_, -6)
		satValKnob.BackgroundColor3 = Color3.new(1, 1, 1)
		satValKnob.ZIndex = 2003
		satValKnob.Parent = satValSquare
		Instance.new("UICorner", satValKnob).CornerRadius = UDim.new(1, 0)
		Instance.new("UIStroke", satValKnob).Thickness = 1.5

		local slidersY = headerHeight + 120 + 8
		hueSlider = Instance.new("Frame")
		hueSlider.Size = UDim2.new(1, -PAD * 2, 0, hueSliderHeight)
		hueSlider.Position = UDim2.new(0, PAD, 0, slidersY)
		hueSlider.BorderSizePixel = 0
		hueSlider.ZIndex = 2001
		hueSlider.Parent = pickerFrame
		Instance.new("UICorner", hueSlider).CornerRadius = UDim.new(0, 6)
		local hueGrad = Instance.new("UIGradient", hueSlider)
		hueGrad.Color = ColorSequence.new {
			ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),
			ColorSequenceKeypoint.new(0.17, Color3.new(1, 1, 0)),
			ColorSequenceKeypoint.new(0.33, Color3.new(0, 1, 0)),
			ColorSequenceKeypoint.new(0.50, Color3.new(0, 1, 1)),
			ColorSequenceKeypoint.new(0.67, Color3.new(0, 0, 1)),
			ColorSequenceKeypoint.new(0.83, Color3.new(1, 0, 1)),
			ColorSequenceKeypoint.new(1, Color3.new(1, 0, 0)),
		}
		hueKnob = Instance.new("Frame")
		hueKnob.Size = UDim2.new(0, 14, 0, 14)
		hueKnob.Position = UDim2.new(h_, -7, 0.5, -7)
		hueKnob.BackgroundColor3 = Color3.new(1, 1, 1)
		hueKnob.ZIndex = 2002
		hueKnob.Parent = hueSlider
		Instance.new("UICorner", hueKnob).CornerRadius = UDim.new(1, 0)
		Instance.new("UIStroke", hueKnob).Thickness = 1.5

		local hexY = slidersY + 12 + 10
		hexBox = Instance.new("TextBox")
		hexBox.Size = UDim2.new(1, -PAD * 2, 0, 26)
		hexBox.Position = UDim2.new(0, PAD, 0, hexY)
		hexBox.BackgroundColor3 = window.theme.Track
		hexBox.BorderSizePixel = 0
		hexBox.Text = "#" .. (typeof(current) == "Color3" and current:ToHex() or "FFFFFF")
		hexBox.TextColor3 = window.theme.White
		hexBox.Font = Enum.Font.GothamSemibold
		hexBox.TextSize = 12
		hexBox.ClearTextOnFocus = false
		hexBox.ZIndex = 2001
		hexBox.Parent = pickerFrame
		Instance.new("UICorner", hexBox).CornerRadius = UDim.new(0, 4)
		local hbStroke = Instance.new("UIStroke", hexBox)
		hbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		hbStroke.Color = window.theme.Border
		hbStroke.Thickness = 1

		local alphaDragging = false
		hueSlider.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				hueDragging = true
				updateHue(input.Position)
			end
		end)
		satValSquare.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				svDragging = true
				updateSV(input.Position)
			end
		end)

		local inputChangedConn = UIS.InputChanged:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
				if hueDragging then updateHue(i.Position) end
				if svDragging then updateSV(i.Position) end
			end
		end)
		local inputEndedConn = UIS.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				hueDragging, svDragging = false, false
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
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				local pos = UIS:GetMouseLocation()
				if not pickerFrame or not pickerFrame.Parent then
					inputBeganConn:Disconnect()
					return
				end
				local bp, bs2 = colorBox.AbsolutePosition, colorBox.AbsoluteSize
				if pos.X >= bp.X and pos.X <= bp.X + bs2.X and pos.Y >= bp.Y and pos.Y <= bp.Y + bs2.Y then return end
				if pos.X < targetX or pos.X > targetX + pickerW or pos.Y < targetY or pos.Y > targetY + pickerH then
					task.spawn(closePicker)
					inputBeganConn:Disconnect()
				end
			end
		end)
		if pickerFrame then _pickerCons[pickerFrame] = { inputChangedConn, inputEndedConn, inputBeganConn } end
	end
	colorBox.MouseButton1Click:Connect(openPicker)
	return row, elem
end

local function buildDropdownRefreshBtn(row, window, refreshCallback)
	if not refreshCallback then return nil end
	local refreshBtn = Instance.new("TextButton")
	refreshBtn.Size = UDim2.new(0, 50, 0, 16)
	refreshBtn.Position = UDim2.new(1, -54, 0, 3)
	refreshBtn.BackgroundColor3 = window.theme.Track
	refreshBtn.AutoButtonColor = false
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

local function createMultiDropdown(group, items, window, text, options, default, callback, refreshCallback, cfgId)
	local id = generateID()
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 56)
	row.BackgroundTransparency = 1
	row.ClipsDescendants = false
	row.ZIndex = 10
	row.Parent = items
	local label = Instance.new("TextLabel")
	local labelWidth = refreshCallback and UDim2.new(1, -64, 0, 18) or UDim2.new(1, -10, 0, 18)
	label.Size = labelWidth
	label.Position = UDim2.new(0, 4, 0, 2)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = window.theme.White
	label.Font = Enum.Font.GothamSemibold
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.ZIndex = 11
	label.Parent = row

	local refreshBtn = buildDropdownRefreshBtn(row, window, refreshCallback)
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
	arrow.Image = window:lucide("align-justify") or "rbxassetid://6034818379"
	arrow.ImageColor3 = window.theme.Accent
	arrow.ScaleType = Enum.ScaleType.Fit
	arrow.ZIndex = 12
	arrow.Parent = dbtn
	table.insert(window.accentObjects, arrow)
	local listH = #options * 28 + 8
	local dlist = Instance.new("ScrollingFrame")
	dlist.Size = UDim2.new(1, 0, 0, math.min(listH, 220))
	dlist.Position = UDim2.new(0, 0, 0, 54)
	dlist.BackgroundColor3 = window.theme.Base
	dlist.BorderSizePixel = 0
	dlist.ScrollBarThickness = listH > 220 and 2 or 0
	dlist.ScrollBarImageColor3 = window.theme.Accent
	dlist.CanvasSize = UDim2.new(0, 0, 0, listH)
	dlist.Visible = false
	dlist.ZIndex = 50
	dlist.Parent = row
	table.insert(window.accentObjects, dlist)
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
	local selected = {}
	if default then for _, v in ipairs(default) do selected[v] = true end end
	local checks = {}
	local backgrounds = {}
	local selectionBGs = {}
	local open = false

	local function buildOptions(opts)
		for _, child in ipairs(dlist:GetChildren()) do
			if not child:IsA("UIListLayout") then child:Destroy() end
		end
		checks = {}
		backgrounds = {}
		selectionBGs = {}
		
		local filtered = {}
		for _, opt in ipairs(opts) do
			if opt ~= "None" and opt ~= "" then
				table.insert(filtered, opt)
			end
		end

		if #filtered == 0 then
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, 0, 0, 28)
			lbl.BackgroundTransparency = 1
			lbl.Text = "No active mobs found"
			lbl.TextColor3 = window.theme.Gray
			lbl.Font = Enum.Font.GothamSemibold
			lbl.TextSize = 11
			lbl.ZIndex = 52
			lbl.Parent = dlist
			listH = 36
		else
			for _, opt in ipairs(filtered) do
				local isSel = selected[opt] and true or false
				local ob = Instance.new("TextButton")
				ob.Size = UDim2.new(1, 0, 0, 28)
				ob.BackgroundTransparency = 1
				ob.AutoButtonColor = false
				ob.Text = ""
				ob.ZIndex = 51
				ob.Parent = dlist

				local bg = Instance.new("Frame")
				bg.Name = "SelectionBG"
				bg.Size = UDim2.new(1, 0, 1, 0)
				bg.BackgroundColor3 = window.theme.Accent
				bg.BackgroundTransparency = isSel and 0.8 or 1
				bg.BorderSizePixel = 0
				bg.ZIndex = 50
				bg.Parent = ob
				table.insert(window.accentObjects, bg)
				selectionBGs[opt] = bg

				local bar = Instance.new("Frame")
				bar.Size = UDim2.new(0, 4, 1, 0)
				bar.Position = UDim2.new(0, 0, 0, 0)
				bar.BackgroundColor3 = window.theme.Accent
				bar.BorderSizePixel = 0
				bar.Visible = isSel
				bar.ZIndex = 53
				bar.Parent = ob
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
						TweenService:Create(bg, TweenInfo.new(0.08), { BackgroundTransparency = 0.85 }):Play()
						ol.TextColor3 = window.theme.GrayLt
					end
				end)
				ob.MouseLeave:Connect(function()
					if not selected[opt] then
						TweenService:Create(bg, TweenInfo.new(0.08), { BackgroundTransparency = 1 }):Play()
						ol.TextColor3 = window.theme.Gray
					end
				end)
				ob.MouseButton1Click:Connect(function()
					if selected[opt] then
						selected[opt] = nil
						bar.Visible = false
						bg.BackgroundTransparency = 1
						ol.TextColor3 = window.theme.Gray
						ol.Font = Enum.Font.GothamSemibold
					else
						selected[opt] = true
						bar.Visible = true
						bg.BackgroundTransparency = 0.8
						ol.TextColor3 = window.theme.White
						ol.Font = Enum.Font.GothamBold
					end
					local keys = {}
					for k, _ in pairs(selected) do table.insert(keys, k) end
					local s = #keys > 0 and table.concat(keys, ", ") or "None"
					if #s > 25 then
						selLbl.Text = #keys .. " Items Selected"
					else
						selLbl.Text = s
					end
					window:SafeCallback(callback, keys)
					window.configs[id].Value = selected
				end)
			end
			listH = #filtered * 28 + 8
		end
		dlist.CanvasSize = UDim2.new(0, 0, 0, listH)
		if open then
			local targetListH = math.min(listH, 220)
			dlist.Size = UDim2.new(1, 0, 0, targetListH)
			row.Size = UDim2.new(1, 0, 0, 56 + targetListH)
			group.updateSize()
		end
	end

	buildOptions(options)

	if refreshBtn then
		refreshBtn.MouseButton1Click:Connect(function()
			if refreshCallback then
				local newOpts = refreshCallback()
				if newOpts then
					buildOptions(newOpts)
				end
			end
		end)
	end
	dbtn.MouseButton1Click:Connect(function()
		open = not open
		window.tooltipSuppressed = open
		if window.tooltip then window.tooltip.hide() end
		if open then
			multiDbtnCorner.CornerRadius = UDim.new(0, 0)
			multiBridge.Visible = true
			dlist.Visible = true
			dlist.Size = UDim2.new(1, 0, 0, 0)
			local targetListH = math.min(listH, 220)
			TweenService:Create(dlist, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 0, targetListH)
			}):Play()
			TweenService:Create(row, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 0, 56 + targetListH)
			}):Play()
		else
			window.tooltipSuppressed = false
			multiDbtnCorner.CornerRadius = UDim.new(0, 4)
			multiBridge.Visible = false
			local tw = TweenService:Create(dlist, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
				Size = UDim2.new(1, 0, 0, 0)
			})
			TweenService:Create(row, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
				Size = UDim2.new(1, 0, 0, 56)
			}):Play()
			tw.Completed:Connect(function() dlist.Visible = false end)
			tw:Play()
		end
		task.delay(0.21, group.updateSize)
	end)
	local elem = {
		ID = id,
		Value = selected,
		label = cfgId or text,
		frame = row,
		DefaultHeight = 56,
		SetValue = function(t)
			selected = {}
			for _, opt in ipairs(t) do selected[opt] = true end
			for opt, ck in pairs(checks) do
				local isSel = selected[opt] or false
				ck.TextColor3 = isSel and window.theme.White or window.theme.Gray
				ck.Font = isSel and Enum.Font.GothamBold or Enum.Font.GothamSemibold
				if backgrounds[opt] then backgrounds[opt].Visible = isSel end
				if selectionBGs[opt] then
					selectionBGs[opt].BackgroundTransparency = isSel and 0.8 or 1
					selectionBGs[opt].BackgroundColor3 = window.theme.Accent
				end
			end
			local keys = {}
			for k, _ in pairs(selected) do table.insert(keys, k) end
			local s = #keys > 0 and table.concat(keys, ", ") or "None"
			if #s > 25 then
				selLbl.Text = #keys .. " Items Selected"
			else
				selLbl.Text = s
			end
			if not _configLoading then
				window:SafeCallback(callback, keys)
			end
			window.configs[id].Value = selected
		end
	}
	function elem:SetVisible(v, anim)
		if not anim then
			row.Visible = v
			row.Size = UDim2.new(1, 0, 0, v and 56 or 0)
			if group and group.updateSize then group.updateSize() end
			return
		end
		row.ClipsDescendants = true
		if v then row.Visible = true end
		local target = v and 56 or 0
		local tw = TweenService:Create(row, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 0, target)
		})
		tw.Completed:Connect(function()
			if not v then row.Visible = false end
			if group and group.updateSize then group.updateSize() end
		end)
		tw:Play()
	end
	window.configs[id] = finalizeElement(elem, window, group)
	return row, elem
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
	grp.ClipsDescendants = true
	local grpStroke = Instance.new("UIStroke", grp)
	grpStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	grpStroke.Color = window.theme.Border
	grpStroke.Thickness = 1

	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 30)
	row.BackgroundColor3 = Color3.new(
		math.min(1, window.theme.ItemHov.r * 1.15),
		math.min(1, window.theme.ItemHov.g * 1.15),
		math.min(1, window.theme.ItemHov.b * 1.15)
	)
	row.BackgroundTransparency = 0
	row.Parent = grp
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

	local headerSep = Instance.new("Frame")
	headerSep.Size = UDim2.new(1, 0, 0, 1)
	headerSep.Position = UDim2.new(0, 0, 0, 30)
	headerSep.BackgroundColor3 = window.theme.Accent
	headerSep.BorderSizePixel = 0
	headerSep.ZIndex = 4
	headerSep.Parent = grp

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
	itemLayout.Padding = UDim.new(0, 4)
	itemLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local padding = Instance.new("UIPadding", items)
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 6)

		local sizeUpdateScheduled = false
	local function updateSize()
		if group._collapsed then
			grp.Size = UDim2.new(1, 0, 0, 36)
			items.Size = UDim2.new(1, 0, 0, 0)
			items.Visible = false
			return
		end
		items.Visible = true
		local ih = itemLayout.AbsoluteContentSize.Y
		local targetH = ih + 46
		items.Size = UDim2.new(1, 0, 0, ih + 8)
		grp.Size = UDim2.new(1, 0, 0, targetH)
	end
	local function deferredUpdateSize()
		if sizeUpdateScheduled then return end
		sizeUpdateScheduled = true
		task.defer(function()
			sizeUpdateScheduled = false
			updateSize()
		end)
	end
	itemLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(deferredUpdateSize)

	local collapseBtn = Instance.new("TextButton")
	collapseBtn.Size = UDim2.new(0, 24, 0, 24)
	collapseBtn.Position = UDim2.new(1, -28, 0.5, -12)
	collapseBtn.BackgroundTransparency = 1
	collapseBtn.Text = "▼"
	collapseBtn.TextColor3 = window.theme.Gray
	collapseBtn.Font = Enum.Font.GothamBold
	collapseBtn.TextSize = 13
	collapseBtn.ZIndex = 5
	collapseBtn.Parent = row
	local function doCollapse()
		grp.ClipsDescendants = true
		local tw = TweenService:Create(grp, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 0, 36)
		})
		tw.Completed:Connect(function() updateSize() end)
		tw:Play()
	end

	local function doExpand()
		grp.ClipsDescendants = true
		items.Visible = true
		items.Size = UDim2.new(1, 0, 0, 0)
		task.wait()
		local ih = itemLayout.AbsoluteContentSize.Y
		if ih == 0 then ih = 36 end
		items.Size = UDim2.new(1, 0, 0, ih + 8)
		grp.Size = UDim2.new(1, 0, 0, 36)
		TweenService:Create(grp, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 0, ih + 46)
		}):Play()
	end

	group._collapsed = false
	collapseBtn.MouseButton1Click:Connect(function()
		group._collapsed = not group._collapsed
		collapseBtn.Text = group._collapsed and "▶" or "▼"
		if group._collapsed then doCollapse() else doExpand() end
	end)

	group.frame = grp
	group.headerRow = row
	group.headerSep = headerSep
	group.headerLabel = label
	group.items = items
	group.itemLayout = itemLayout
	group.updateSize = deferredUpdateSize
	function group:SetVisible(v, anim)
		if not anim then
			grp.Visible = v
			if v and not group._collapsed then items.Visible = true end
			return
		end
		grp.ClipsDescendants = true
		if v then grp.Visible = true; if not group._collapsed then items.Visible = true end end
		local target = v and (itemLayout.AbsoluteContentSize.Y + 46) or 0
		local tw = TweenService:Create(grp, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 0, target)
		})
		tw.Completed:Connect(function() if not v then grp.Visible = false end end)
		tw:Play()
	end

	function group:setIcon(assetId)
		if assetId then
			local id = UILib.resolveIcon(assetId)
			if not id then id = tostring(assetId) end
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
		updateSize()
		local ref = {}
		function ref:setTitle(t) lbl.Text = t end

		function ref:setDesc(d)
			body.Text = d
			updateSize()
		end

		ref.remove = function() r:Destroy(); updateSize() end
		return ref
	end

	local function buildNestedGroup(contentFrame, updateContentSize)
		local ng = {}
		local function reparent(r, useFrame)
			local target = useFrame or contentFrame
			local obj = r
			if type(r) == "table" and r.frame then obj = r.frame end
			if typeof(obj) == "Instance" then obj.Parent = target end
			updateContentSize()
			return r
		end
		setmetatable(ng, {
			__index = function(t, key)
				if key == "split" or key == "paragraph" then return nil end
				local fn = group[key]
				if type(fn) ~= "function" then return nil end
				return function(_, ...)
					return reparent(fn(group, ...))
				end
			end
		})
		function ng:paragraph(tit, txt, tt2)
			group:paragraph(tit, txt, tt2); updateContentSize()
		end
		function ng:split()
			local splitRow = Instance.new("Frame")
			splitRow.Size = UDim2.new(1, 0, 0, 0)
			splitRow.BackgroundTransparency = 1
			splitRow.AutomaticSize = Enum.AutomaticSize.Y
			splitRow.Parent = contentFrame
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
			local function updateSplit()
				local lh = lFrame.UIListLayout.AbsoluteContentSize.Y
				local rh = rFrame.UIListLayout.AbsoluteContentSize.Y
				splitRow.Size = UDim2.new(1, 0, 0, math.max(lh, rh))
				updateContentSize()
			end
			lFrame.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSplit)
			rFrame.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSplit)
			local function wrapSide(frame)
				local g = { window = window, items = frame, updateSize = updateSplit }
				for k, v in pairs(ng) do
					if type(v) == "function" and k ~= "split" then
						local fn = v
						g[k] = function(self2, ...) return fn(self2, ...) end
					end
				end
				return g
			end
			return wrapSide(lFrame), wrapSide(rFrame)
		end
		return ng
	end

	function UILib:openAdvancedPanel(anchorElement, builder)
		if self.tooltip then self.tooltip.hide() end
		anchorElement = anchorElement or self.window
		local cacheKey = anchorElement
		if not self._panels then self._panels = {} end
		if not self._repositionPanel then
			self._repositionPanel = function(data, anchor)
				local a = anchor.AbsolutePosition
				if not a or a.X < 1 then a = self.window.AbsolutePosition end
				if not a then a = Vector2.new(200, 200) end
				local sh = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 1080
				local sw = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 1920
				local pw = data.popup.AbsoluteSize.X
				local ph = data.popup.AbsoluteSize.Y
				if pw < 10 then pw, ph = 240, 100 end
				local tx = math.clamp(a.X + 0, 4, sw - pw - 4)
				local ty = a.Y + 80
				if ty + ph > sh - 4 then ty = a.Y - ph - 4 end
				ty = math.max(4, ty)
				data.popup.Position = UDim2.new(0, tx, 0, ty)
				data.tx, data.ty = tx, ty
			end
		end
		if not self._makeCloseConn then
			self._makeCloseConn = function(data, ck, anchorEl)
				local conn
				conn = UIS.InputBegan:Connect(function(input)
					if self._panelJustOpened then return end
					if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
					local mp = UIS:GetMouseLocation()
					local d = self._panels[ck]
					if not d then conn:Disconnect(); return end
				local pp = d.popup
				local as = pp.AbsoluteSize or Vector2.new(240, 100)
				local px = d.tx or 200
				local py = d.ty or 200
				if mp.X >= px - 8 and mp.X <= px + as.X + 8 and mp.Y >= py - 8 and mp.Y <= py + as.Y + 8 then return end
			if window._pickerOpen then return end
			for pf, _ in pairs(_pickerCons) do
				if pf and pf.Parent and pf.Visible then
					local pa = pf.AbsolutePosition
					local ps = pf.AbsoluteSize
					if pa and ps and ps.X > 10 then
						if mp.X >= pa.X - 4 and mp.X <= pa.X + ps.X + 4 and mp.Y >= pa.Y - 4 and mp.Y <= pa.Y + ps.Y + 4 then return end
					end
				end
			end
					local bp = (anchorEl or d.anchor).AbsolutePosition
					local bs = (anchorEl or d.anchor).AbsoluteSize
					if bp and bs and mp.X >= bp.X - 4 and mp.X <= bp.X + bs.X + 4 and mp.Y >= bp.Y - 4 and mp.Y <= bp.Y + bs.Y + 4 then return end
					TweenService:Create(d.scale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0 }):Play()
					task.delay(0.16, function() pcall(function() pp.Visible = false end) end)
					d.open = false
					conn:Disconnect()
					d.conn = nil
				end)
				return conn
			end
		end
		local repositionPanel = self._repositionPanel
		local makeCloseConn = self._makeCloseConn
		local data = self._panels[cacheKey]
		if data then
			if data.animating then return end
			data.animating = true
			if data.open then
				TweenService:Create(data.scale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0 }):Play()
				task.delay(0.16, function() pcall(function() data.popup.Visible = false end); data.animating = false end)
				data.open = false
				if data.conn then data.conn:Disconnect(); data.conn = nil end
			else
				repositionPanel(data, anchorElement)
				data.popup.Visible = true
				TweenService:Create(data.scale, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Scale = 1 }):Play()
				data.open = true
				data.conn = makeCloseConn(data, cacheKey, anchorElement)
				task.delay(0.21, function() data.animating = false end)
			end
			return
		end
		local popup = Instance.new("Frame")
		popup.BackgroundColor3 = self.theme.Surface
		popup.BorderSizePixel = 0
		popup.ZIndex = 9997
		popup.ClipsDescendants = false
		popup.Position = UDim2.new(0, -1000, 0, -1000)
		popup.Visible = false
		popup.Parent = self.sg
		popup.Size = UDim2.new(0, 240, 0, 10)
		Instance.new("UICorner", popup).CornerRadius = UDim.new(0, 8)
		local ps = Instance.new("UIStroke", popup)
		ps.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		ps.Color = self.theme.Border
		ps.Thickness = 1.5
		ps.Transparency = 0.2

		local pad = Instance.new("UIPadding", popup)
		pad.PaddingLeft = UDim.new(0, 14)
		pad.PaddingRight = UDim.new(0, 14)
		pad.PaddingTop = UDim.new(0, 12)
		pad.PaddingBottom = UDim.new(0, 12)

		local layout = Instance.new("UIListLayout", popup)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 4)

		local popupScale = Instance.new("UIScale", popup)
		popupScale.Scale = 0

		local function updateSize()
			local h = layout.AbsoluteContentSize.Y + 24
			popup.Size = UDim2.new(0, 240, 0, math.max(h, 40))
		end
		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSize)

		local ng = buildNestedGroup(popup, updateSize)
		builder(ng)
		task.wait(0.08)
		updateSize()
		task.wait(0.02)
		updateSize()

		local anchorAbs = anchorElement.AbsolutePosition
		if not anchorAbs or anchorAbs.X < 1 then anchorAbs = self.window.AbsolutePosition end
		if not anchorAbs then anchorAbs = Vector2.new(200, 200) end
		local screenH = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 1080
		local screenW = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 1920
		local pw = popup.AbsoluteSize.X
		local ph = popup.AbsoluteSize.Y
		if pw < 10 then pw, ph = 240, 100 end
		local tx = math.clamp(anchorAbs.X, 4, screenW - pw - 4)
		local ty = anchorAbs.Y + 36
		if ty + ph > screenH - 4 then ty = anchorAbs.Y - ph - 4 end
		ty = math.max(4, ty)
		popup.Position = UDim2.new(0, tx, 0, ty)
		popup.Visible = true

		data = { popup = popup, scale = popupScale, anchor = anchorElement, open = true }
		repositionPanel(data, anchorElement)
		TweenService:Create(popupScale, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Scale = 1 }):Play()

		self._panelJustOpened = true
		task.delay(0.15, function() self._panelJustOpened = false end)
		data.conn = makeCloseConn(data, cacheKey, anchorElement)
		self._panels[cacheKey] = data
	end

	local function createToggleCheckbox(parent, default, window, text, rightOffset)
		rightOffset = rightOffset or 4
		local CB_SIZE = 22
		local cbOuter = Instance.new("TextButton")
		cbOuter.Size = UDim2.new(0, CB_SIZE, 0, CB_SIZE)
		cbOuter.Position = UDim2.new(0, 0, 0.5, -CB_SIZE/2)
		cbOuter.BackgroundColor3 = default and window.theme.Accent or window.theme.BG
		cbOuter.BorderSizePixel = 0
		cbOuter.AutoButtonColor = false
		cbOuter.ZIndex = 4
		cbOuter.Text = ""
		cbOuter.Parent = parent
		local cbOverlay = Instance.new("Frame")
		cbOverlay.Size = UDim2.fromScale(1, 1)
		cbOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
		cbOverlay.BackgroundTransparency = 0.7
		cbOverlay.BorderSizePixel = 0
		cbOverlay.Visible = false
		cbOverlay.ZIndex = 10
		cbOverlay.Parent = cbOuter
		cbOverlay.BackgroundTransparency = 1
		cbOuter.MouseButton1Down:Connect(function() TweenService:Create(cbOverlay, TweenInfo.new(0.05, Enum.EasingStyle.Quad), { BackgroundTransparency = 0.7 }):Play(); cbOverlay.Visible = true end)
		cbOuter.MouseButton1Up:Connect(function() TweenService:Create(cbOverlay, TweenInfo.new(0.05, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play(); task.delay(0.06, function() cbOverlay.Visible = false end) end)
		cbOuter.MouseLeave:Connect(function() TweenService:Create(cbOverlay, TweenInfo.new(0.05, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play(); task.delay(0.06, function() cbOverlay.Visible = false end) end)
		Instance.new("UICorner", cbOuter).CornerRadius = UDim.new(0, 4)
		local cbStroke = Instance.new("UIStroke", cbOuter)
		cbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		cbStroke.Color = default and window.theme.AccentD or window.theme.Border
		cbStroke.Thickness = 1
		local cbMark = Instance.new("TextLabel")
		cbMark.Size = UDim2.new(1, 0, 1, 0)
		cbMark.BackgroundTransparency = 1
		cbMark.Text = default and "X" or ""
		cbMark.TextColor3 = Color3.fromRGB(10, 10, 10)
		cbMark.Font = Enum.Font.GothamBold
		cbMark.TextSize = 14
		cbMark.ZIndex = 5
		cbMark.Parent = cbOuter
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -(46 + rightOffset), 1, 0)
		lbl.Position = UDim2.new(0, 29, 0, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = text
		lbl.TextColor3 = window.theme.White
		lbl.Font = Enum.Font.GothamSemibold
		lbl.TextSize = 13
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextWrapped = true
		lbl.TextYAlignment = Enum.TextYAlignment.Center
		lbl.ZIndex = 4
		lbl.Parent = parent
		return cbOuter, cbStroke, cbMark, lbl
	end

	local function updateToggleCheckbox(cbOuter, cbStroke, cbMark, state, window)
		cbOuter.BackgroundColor3 = state and window.theme.Accent or window.theme.BG
		cbStroke.Color = state and window.theme.AccentD or window.theme.Border
		cbMark.Text = state and "X" or ""
	end

	function group:toggle(text, default, callback, tooltip, icon, expandable, contentFunc, colorCallback, settingsCallback, cfgId)
		assert(text ~= nil and text ~= "", "Toggle - Missing text")
		local id = generateID()
		local TOGGLE_H = 36
		if expandable then
			local container = Instance.new("Frame")
			container.Size = UDim2.new(1, 0, 0, TOGGLE_H)
			container.BackgroundTransparency = 1
			container.ClipsDescendants = true
			container.Parent = items
			local toggleRow = Instance.new("Frame")
			toggleRow.Size = UDim2.new(1, 0, 0, TOGGLE_H)
			toggleRow.BackgroundTransparency = 1
			toggleRow.ZIndex = 3
			toggleRow.Parent = container
			local cbOuter, cbStroke, cbMark, lbl = createToggleCheckbox(toggleRow, default, window, text, 4)
			lbl.Size = UDim2.new(1, -46, 1, 0)
			local contentFrame = Instance.new("Frame")
			contentFrame.Size = UDim2.new(1, 0, 0, 0)
			contentFrame.Position = UDim2.new(0, 0, 0, TOGGLE_H)
			contentFrame.BackgroundTransparency = 1
			contentFrame.Parent = container
			local contentLayout = Instance.new("UIListLayout", contentFrame)
			contentLayout.Padding = UDim.new(0, 2)
			contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
			local state = default
			local function updateContentSize()
				local h = contentLayout.AbsoluteContentSize.Y
				contentFrame.Size = UDim2.new(1, 0, 0, h)
				container.Size = UDim2.new(1, 0, 0, TOGGLE_H + (state and h or 0))
				updateSize()
			end
			contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateContentSize)
			local nestedGroup = buildNestedGroup(contentFrame, updateContentSize)
			if contentFunc then contentFunc(nestedGroup) end
			local elem = { ID = id, Value = state, DefaultValue = default, label = cfgId or text, IsToggle = true, Mode = "toggle", frame = container, DefaultHeight = TOGGLE_H }
			elem.SetValue = function(val)
				state = val
				elem.Value = state
				updateToggleCheckbox(cbOuter, cbStroke, cbMark, state, window)
				local targetH = TOGGLE_H + (state and contentLayout.AbsoluteContentSize.Y or 0)
				TweenService:Create(container, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					Size = UDim2.new(1, 0, 0, targetH)
				}):Play()
				task.delay(0.21, updateSize)
				window:SafeCallback(callback, state)
				if window.configs[id] then window.configs[id].Value = state end
			end
		function elem:SetVisible(v, anim)
			if not anim then
				if not v then
					state = false
					cbOuter.BackgroundColor3 = window.theme.BG
					cbStroke.Color = window.theme.Border
					cbMark.Text = ""
				end
				container.Visible = v
				container.Size = UDim2.new(1, 0, 0, v and (TOGGLE_H + (state and contentLayout and contentLayout.AbsoluteContentSize.Y or 0)) or 0)
				if group and group.updateSize then group.updateSize() end
				return
			end
			if not v then
				state = false
				TweenService:Create(cbOuter, TweenInfo.new(0.12, Enum.EasingStyle.Quart), {
					BackgroundColor3 = window.theme.BG
				}):Play()
				cbStroke.Color = window.theme.Border
				cbMark.Text = ""
			end
			if v then container.Visible = true end
			local tw = TweenService:Create(container, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 0, v and (TOGGLE_H + (state and contentLayout.AbsoluteContentSize.Y or 0)) or 0)
			})
			tw.Completed:Connect(function()
				if not v then container.Visible = false end
				if group and group.updateSize then group.updateSize() end
			end)
			tw:Play()
		end
			window.configs[id] = finalizeElement(elem, window, group)
			cbOuter.MouseButton1Click:Connect(function()
				if elem.Mode == "always" then return end
				state = not state
				elem.SetValue(state)
			end)
			updateContentSize()
			elem.frame = container
		elem.SetDesc = function(self_or_d, d) if type(self_or_d) == "string" then lbl.Text = self_or_d else lbl.Text = d end end
		return elem
	end

		local r = Instance.new("Frame")
		r.Size = UDim2.new(1, 0, 0, TOGGLE_H)
		r.BackgroundTransparency = 1
		r.BorderSizePixel = 0
		r.ZIndex = 3
		r.Parent = items
		local rightIcons, rightOffset = {}, 4
		if colorCallback then
			local colorBtn = Instance.new("TextButton")
			colorBtn.Size = UDim2.new(0, 16, 0, 16)
			colorBtn.Position = UDim2.new(1, -(rightOffset + 16), 0.5, -8)
			colorBtn.BackgroundColor3 = default or Color3.new(1, 1, 1)
			colorBtn.BorderSizePixel = 0
			colorBtn.Text = ""
			colorBtn.AutoButtonColor = false
			colorBtn.ZIndex = 5
			colorBtn.Parent = r
			Instance.new("UICorner", colorBtn).CornerRadius = UDim.new(1, 0)
			colorBtn.MouseButton1Click:Connect(function()
				colorCallback(colorBtn.BackgroundColor3)
			end)
			rightOffset = rightOffset + 18
		end
		if type(settingsCallback) == "function" then
			local gearBtn = Instance.new("ImageLabel")
			local gi = window:lucide("settings")
			gearBtn.Size = UDim2.new(0, 14, 0, 14)
			gearBtn.Position = UDim2.new(1, -(rightOffset + 14), 0.5, -7)
			gearBtn.BackgroundTransparency = 1
			gearBtn.Image = gi or ""
			gearBtn.ImageColor3 = window.theme.GrayLt
			gearBtn.ScaleType = Enum.ScaleType.Fit
			gearBtn.ZIndex = 5
			gearBtn.Parent = r
			local gb = Instance.new("TextButton")
			gb.Size = UDim2.new(1, 8, 1, 8)
			gb.BackgroundTransparency = 1
			gb.Text = ""
			gb.ZIndex = 6
			gb.Parent = gearBtn
			gb.MouseButton1Click:Connect(function()
				if type(settingsCallback) == "function" then
					settingsCallback(gearBtn)
				end
			end)
			rightOffset = rightOffset + 20
		end
		if tooltip then
			local tipIcon = Instance.new("ImageLabel")
			local ti = window:lucide("info")
			tipIcon.Size = UDim2.new(0, 14, 0, 14)
			tipIcon.Position = UDim2.new(1, -(rightOffset + 14), 0.5, -7)
			tipIcon.BackgroundTransparency = 1
			tipIcon.Image = ti or ""
			tipIcon.ImageColor3 = window.theme.GrayLt
			tipIcon.ScaleType = Enum.ScaleType.Fit
			tipIcon.ZIndex = 5
			tipIcon.Parent = r
			local tb = Instance.new("TextButton")
			tb.Size = UDim2.new(1, 8, 1, 8)
			tb.BackgroundTransparency = 1
			tb.Text = ""
			tb.ZIndex = 6
			tb.Parent = tipIcon
			tb.MouseEnter:Connect(function()
				if not window.tooltip or window.tooltipSuppressed then return end
				window.tooltip.show(tooltip, tb)
			end)
			tb.MouseLeave:Connect(function()
				if window.tooltip then window.tooltip.hide() end
			end)
			rightOffset = rightOffset + 20
		end
		local cbOuter, cbStroke, cbMark, lbl = createToggleCheckbox(r, default, window, text, rightOffset)
		local state = default
		local elem = { ID = id, Value = state, DefaultValue = default, label = cfgId or text, IsToggle = true, Mode = "toggle", frame = r, DefaultHeight = TOGGLE_H }
		elem.SetValue = function(val)
			state = val
			elem.Value = state
			updateToggleCheckbox(cbOuter, cbStroke, cbMark, state, window)
			window:SafeCallback(callback, state)
			if window.configs[id] then window.configs[id].Value = state end
		end
		function elem:SetVisible(v, anim)
			if not anim then
				r.Visible = v
				r.Size = UDim2.new(1, 0, 0, v and TOGGLE_H or 0)
				if group and group.updateSize then group.updateSize() end
				return
			end
			r.ClipsDescendants = true
			if v then r.Visible = true end
			local tw = TweenService:Create(r, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 0, v and TOGGLE_H or 0)
			})
			tw.Completed:Connect(function()
				if not v then r.Visible = false end
				if group and group.updateSize then group.updateSize() end
			end)
			tw:Play()
		end
		window.configs[id] = finalizeElement(elem, window, group)
		cbOuter.MouseButton1Click:Connect(function()
			if elem.Mode == "always" then return end
			state = not state
			elem.SetValue(state)
		end)
		updateSize()
		elem.frame = r
		elem.SetDesc = function(self_or_d, d) if type(self_or_d) == "string" then lbl.Text = self_or_d else lbl.Text = d end end
		return elem
	end

	function group:confirmToggle(text, default, confirmMessage, callback, tooltip, icon)
		local elem = self:toggle(text, default, nil, tooltip, icon)
		elem._confirmMessage = confirmMessage
		local origSetValue = elem.SetValue
		local lastConfirm = 0
		elem.SetValue = function(val, _silent)
			if (window._loadingConfig or (_configLoading) or (_silent)) and val and elem._confirmMessage then
				origSetValue(val)
				window:SafeCallback(callback, val)
				return
			end
			if val and elem._confirmMessage and not _silent then
				if tick() - lastConfirm < 0.5 then return end
				local msg = type(elem._confirmMessage) == "function" and elem._confirmMessage() or elem._confirmMessage
				window:confirm(msg, function(ok)
					if ok then
						lastConfirm = tick()
						origSetValue(true)
						window:SafeCallback(callback, true)
					else
						origSetValue(false)
					end
				end)
			else
				origSetValue(val)
				window:SafeCallback(callback, val)
			end
		end
		function elem:setConfirmMessage(msg) elem._confirmMessage = msg end
		return elem
	end

	local function formatSliderVal(val, mode)
		if type(mode) == "function" then return mode(val) end
		if mode == "%" then return math.floor(val * 100 + 0.5) .. "%" end
		if mode == "k" then
			if val >= 1000000 then return ("%.1fM"):format(val / 1000000)
			elseif val >= 1000 then return ("%.1fk"):format(val / 1000)
			else return cleanNum(val) end
		end
		return cleanNum(val)
	end

	function group:slider(text, minVal, maxVal, defaultVal, callback, step, tooltip, icon, display, cfgId, settingsCallback)
		local r, elem = createSlider(group, items, window, text, minVal, maxVal, defaultVal, callback, step, cfgId, settingsCallback)
		if display then elem:setDisplay(display) end
		updateSize()
		return elem
	end

	function group:dropdown(text, options, default, callback, tooltip, refreshCallback, icon, cfgId, settingsCallback)
		assert(text ~= nil, "Dropdown - Missing text")
		local id = generateID()
		local r = Instance.new("Frame")
		r.Size = UDim2.new(1, 0, 0, 56)
		r.BackgroundTransparency = 1
		r.ClipsDescendants = false
		r.ZIndex = 10
		r.Parent = items

		local lbl = Instance.new("TextLabel")
		local gearWidth = settingsCallback and 16 or 0
		local refWidth = (refreshCallback and 54 or 0)
		local lblWidth = UDim2.new(1, -(10 + refWidth + gearWidth), 0, 18)
		lbl.Size = lblWidth
		lbl.Position = UDim2.new(0, 4, 0, 2)
		lbl.BackgroundTransparency = 1
		lbl.Text = text
		lbl.TextColor3 = window.theme.White
		lbl.Font = Enum.Font.GothamSemibold
		lbl.TextSize = 12
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextWrapped = true
		lbl.ZIndex = 11
		lbl.Parent = r

		local refreshBtn = buildDropdownRefreshBtn(r, window, refreshCallback)

		if type(settingsCallback) == "function" then
			local gearBtn = Instance.new("ImageLabel")
			local gi = window:lucide("settings")
			gearBtn.Size = UDim2.new(0, 14, 0, 14)
			gearBtn.Position = UDim2.new(1, -(10 + gearWidth), 0, 4)
			gearBtn.BackgroundTransparency = 1
			gearBtn.Image = gi or ""
			gearBtn.ImageColor3 = window.theme.GrayLt
			gearBtn.ScaleType = Enum.ScaleType.Fit
			gearBtn.ZIndex = 12
			gearBtn.Parent = r
			local gb = Instance.new("TextButton")
			gb.Size = UDim2.new(1, 8, 1, 8)
			gb.BackgroundTransparency = 1
			gb.Text = ""
			gb.ZIndex = 13
			gb.Parent = gearBtn
			gb.MouseButton1Click:Connect(function()
				settingsCallback(gearBtn)
			end)
		end

		local dbtn = Instance.new("TextButton")
		dbtn.Size = UDim2.new(1, 0, 0, 32)
		dbtn.Position = UDim2.new(0, 0, 0, 22)
		dbtn.BackgroundColor3 = window.theme.Track
		dbtn.BorderSizePixel = 0
		dbtn.AutoButtonColor = false
		dbtn.Text = ""
		dbtn.ZIndex = 11
		dbtn.Parent = r
		local dbtnOverlay = Instance.new("Frame")
		dbtnOverlay.Size = UDim2.fromScale(1, 1)
		dbtnOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
		dbtnOverlay.BackgroundTransparency = 0.8
		dbtnOverlay.BorderSizePixel = 0
		dbtnOverlay.Visible = false
		dbtnOverlay.ZIndex = 20
		dbtnOverlay.Parent = dbtn
		dbtnOverlay.BackgroundTransparency = 1
		Instance.new("UICorner", dbtnOverlay).CornerRadius = UDim.new(0, 4)
		dbtn.MouseButton1Down:Connect(function() TweenService:Create(dbtnOverlay, TweenInfo.new(0.05, Enum.EasingStyle.Quad), { BackgroundTransparency = 0.8 }):Play(); dbtnOverlay.Visible = true end)
		dbtn.MouseButton1Up:Connect(function() TweenService:Create(dbtnOverlay, TweenInfo.new(0.05, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play(); task.delay(0.06, function() dbtnOverlay.Visible = false end) end)
		dbtn.MouseLeave:Connect(function() TweenService:Create(dbtnOverlay, TweenInfo.new(0.05, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play(); task.delay(0.06, function() dbtnOverlay.Visible = false end) end)
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
		arrow.Image = window:lucide("align-justify") or "rbxassetid://6034818379"
		arrow.ImageColor3 = window.theme.Accent
		arrow.ScaleType = Enum.ScaleType.Fit
		arrow.ZIndex = 12
		arrow.Name = "arrow"
		table.insert(window.accentObjects, arrow)
		arrow.Parent = dbtn

		local itemH = 28
		local listH = #options * itemH + 8

		local expandPanel = Instance.new("Frame")
		expandPanel.Name = "ExpandPanel"
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
		table.insert(window.accentObjects, dlist)
		local dlayout = Instance.new("UIListLayout", dlist)
		dlayout.SortOrder = Enum.SortOrder.LayoutOrder
		dlayout.Padding = UDim.new(0, 0)

		local noResultsLbl = Instance.new("TextLabel")
		noResultsLbl.Size = UDim2.new(1, 0, 0, 28)
		noResultsLbl.BackgroundTransparency = 1
		noResultsLbl.Text = "No results"
		noResultsLbl.TextColor3 = window.theme.Gray
		noResultsLbl.Font = Enum.Font.GothamSemibold
		noResultsLbl.TextSize = 12
		noResultsLbl.ZIndex = 51
		noResultsLbl.Visible = false
		noResultsLbl.Parent = dlist

		local checks = {}
		local backgrounds = {}
		local selectionBGs = {}
		local currentOptions = options
		local currentSelection = default or ""
		local open = false

		local function getListMaxH() return math.min(listH, 220) end

		local function closeDropdown()
			open = false
			window.tooltipSuppressed = false

			dbtnCorner.CornerRadius = UDim.new(0, 4)
			dbtnStroke.Color = window.theme.Border
			expandCorner.CornerRadius = UDim.new(0, 4)

			local tw = TweenService:Create(expandPanel,
				TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
					Size = UDim2.new(1, 0, 0, 0)
				})
			TweenService:Create(r, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
				Size = UDim2.new(1, 0, 0, 56)
			}):Play()
			tw.Completed:Connect(function()
				expandPanel.Visible = false
				dlist.Position = UDim2.new(0, 0, 0, 0)
				for _, child in ipairs(dlist:GetChildren()) do
					if child:IsA("TextButton") then child.Visible = true end
				end
			end)
			tw:Play()
			task.delay(0.16, updateSize)
		end

		local function buildOptions(opts)
			for _, child in ipairs(dlist:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
			checks = {}
			backgrounds = {}
			selectionBGs = {}
			currentOptions = opts
			listH = #opts * 28 + 4
			dlist.CanvasSize = UDim2.new(0, 0, 0, listH)
		dlist.ScrollBarThickness = listH > 220 and 2 or 0
			for _, opt in ipairs(opts) do
				local isSelected = (opt == currentSelection)
				local ob = Instance.new("TextButton")
				ob.Size = UDim2.new(1, 0, 0, 28)
				ob.BackgroundTransparency = 1
				ob.AutoButtonColor = false
				ob.Text = ""
				ob.ZIndex = 51
				ob.Parent = dlist
				
				local bg = Instance.new("Frame")
				bg.Name = "SelectionBG"
				bg.Size = UDim2.new(1, 0, 1, 0)
			bg.BackgroundColor3 = window.theme.Accent
			bg.BackgroundTransparency = isSelected and 0.8 or 1
				bg.BorderSizePixel = 0
				bg.ZIndex = 50
				bg.Parent = ob
				table.insert(window.accentObjects, bg)
				selectionBGs[opt] = bg
				
				local bar = Instance.new("Frame")
				bar.Size = UDim2.new(0, 4, 1, 0)
				bar.Position = UDim2.new(0, 0, 0, 0)
				bar.BackgroundColor3 = window.theme.Accent
				bar.BorderSizePixel = 0
				bar.Visible = isSelected
				bar.ZIndex = 53
				bar.Parent = ob
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
						ol.TextColor3 = window.theme.White
					end
				end)
				ob.MouseLeave:Connect(function()
					if opt ~= currentSelection then
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
							local sBg = child:FindFirstChild("SelectionBG")
							if sBg then
								local isSel = child:FindFirstChildOfClass("TextLabel") and
									child:FindFirstChildOfClass("TextLabel").Text == opt
								sBg.BackgroundTransparency = isSel and 0.8 or 1
								sBg.BackgroundColor3 = window.theme.Accent
							end
						end
					end
					window:SafeCallback(callback, opt)
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
					for _, o in ipairs(newOpts) do
						if o == currentSelection then
							exists = true
							break
						end
					end
					if not exists then
						currentSelection = newOpts[1] or ""
						selLbl.Text = currentSelection
						window:SafeCallback(callback, currentSelection)
					end
				end
			end
		end
		if refreshBtn then refreshBtn.MouseButton1Click:Connect(refresh) end

		dbtn.MouseButton1Click:Connect(function()
			open = not open
			window.tooltipSuppressed = open
			if window.tooltip then window.tooltip.hide() end
			if open then
				local clampedListH = getListMaxH()
				local totalPanelH = clampedListH

				dbtnCorner.CornerRadius = UDim.new(0, 4)
				dbtnStroke.Color = window.theme.Border
				expandCorner.CornerRadius = UDim.new(0, 0)

				dlist.Position = UDim2.new(0, 0, 0, 0)
				dlist.Size = UDim2.new(1, 0, 0, clampedListH)

				expandPanel.Size = UDim2.new(1, 0, 0, 0)
				expandPanel.Visible = true
				local spaceBelow = workspace.CurrentCamera.ViewportSize.Y - (r.AbsolutePosition.Y + r.AbsoluteSize.Y)
				local flipUp = spaceBelow < totalPanelH + 8
				if flipUp then
					expandPanel.Position = UDim2.new(0, 0, 0, -totalPanelH)
				else
					expandPanel.Position = UDim2.new(0, 0, 0, 52)
				end
				local panelSize = totalPanelH
				TweenService:Create(expandPanel, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					Size = UDim2.new(1, 0, 0, panelSize)
				}):Play()
				local rNewH = 56 + (flipUp and 0 or totalPanelH)
				TweenService:Create(r, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					Size = UDim2.new(1, 0, 0, rNewH)
				}):Play()
				task.delay(0.21, updateSize)
			else
				closeDropdown()
			end
		end)

		local elem = {
			ID = id,
			Value = currentSelection,
			DefaultValue = default,
			label = cfgId or text,
			_values = options,
			Refresh = refresh,
		SetValue = function(val)
				if type(val) ~= "string" then return end
				currentSelection = val
				selLbl.Text = val
			for o, lbl2 in pairs(checks) do
				local sel = (o == val)
				lbl2.TextColor3 = sel and window.theme.White or window.theme.Gray
				lbl2.Font = sel and Enum.Font.GothamBold or Enum.Font.GothamSemibold
			end
			for o, b in pairs(backgrounds) do b.Visible = (o == val) end
			for o, sbg in pairs(selectionBGs) do
				sbg.BackgroundTransparency = (o == val) and 0.8 or 1
				sbg.BackgroundColor3 = window.theme.Accent
			end
			if not _configLoading then
				window:SafeCallback(callback, val)
			end
			window.configs[id].Value = val
		end,
			SetValues = function(self, newOpts)
				closeDropdown()
				local prevSelection = currentSelection
				currentSelection = ""
				for _, o in ipairs(newOpts) do
					if o == prevSelection then currentSelection = o; break end
				end
				if currentSelection == "" then currentSelection = newOpts[1] or "" end
				if type(currentSelection) ~= "string" then currentSelection = "" end
				buildOptions(newOpts)
				selLbl.Text = currentSelection
				window.configs[id].Value = currentSelection
			end
		}
		window.configs[id] = finalizeElement(elem, window, group)

		updateSize()
		elem.frame = r
		elem.SetDesc = function(self_or_d, d) if type(self_or_d) == "string" then lbl.Text = self_or_d else lbl.Text = d end end
		return elem
	end

	function group:keybind(text, currentName, onChange, tooltip, cfgId)
		assert(text ~= nil and text ~= "", "Keybind - Missing text")
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
		lbl.TextWrapped = true
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
		local kbtnOverlay = Instance.new("Frame")
		kbtnOverlay.Size = UDim2.fromScale(1, 1)
		kbtnOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
		kbtnOverlay.BackgroundTransparency = 0.8
		kbtnOverlay.BorderSizePixel = 0
		kbtnOverlay.Visible = false
		kbtnOverlay.ZIndex = 10
		kbtnOverlay.Parent = kbtn
		kbtnOverlay.BackgroundTransparency = 1
		Instance.new("UICorner", kbtnOverlay).CornerRadius = UDim.new(0, 4)
		kbtn.MouseButton1Down:Connect(function() TweenService:Create(kbtnOverlay, TweenInfo.new(0.05, Enum.EasingStyle.Quad), { BackgroundTransparency = 0.8 }):Play(); kbtnOverlay.Visible = true end)
		kbtn.MouseButton1Up:Connect(function() TweenService:Create(kbtnOverlay, TweenInfo.new(0.05, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play(); task.delay(0.06, function() kbtnOverlay.Visible = false end) end)
		kbtn.MouseLeave:Connect(function() TweenService:Create(kbtnOverlay, TweenInfo.new(0.05, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play(); task.delay(0.06, function() kbtnOverlay.Visible = false end) end)
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
				if skipNext and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
					skipNext = false
					return
				end
				listening = false
				con:Disconnect()
				kbtn.BackgroundColor3 = window.theme.BG
				kbtn.BackgroundTransparency = 0
				kbtn.TextColor3 = window.theme.GrayLt
				kstroke.Color = window.theme.Border
				if i.KeyCode == Enum.KeyCode.Escape then
					kbtn.Text = currentName
					kbtn.TextColor3 = window.theme.GrayLt
					return
				end
				local u = i.UserInputType
				if u == Enum.UserInputType.Keyboard then
					kbtn.Text = i.KeyCode.Name
					kbtn.TextColor3 = window.theme.GrayLt
					onChange(i.KeyCode, i.KeyCode.Name)
					if window.configs[id] then window.configs[id].Value = i.KeyCode.Name end
				elseif u == Enum.UserInputType.MouseButton2 then
					kbtn.Text = "RMB"
					kbtn.TextColor3 = window.theme.GrayLt
					onChange(Enum.UserInputType.MouseButton2, "RMB")
					if window.configs[id] then window.configs[id].Value = "RMB" end
				elseif u == Enum.UserInputType.MouseButton1 or u == Enum.UserInputType.Touch then
					kbtn.Text = u == Enum.UserInputType.Touch and "Touch" or "LMB"
					kbtn.TextColor3 = window.theme.GrayLt
					onChange(u, u == Enum.UserInputType.Touch and "Touch" or "LMB")
					if window.configs[id] then window.configs[id].Value = u == Enum.UserInputType.Touch and "Touch" or "LMB" end
				elseif u == Enum.UserInputType.MouseButton3 then
					kbtn.Text = "MMB"
					kbtn.TextColor3 = window.theme.GrayLt
					onChange(Enum.UserInputType.MouseButton3, "MMB")
					if window.configs[id] then window.configs[id].Value = "MMB" end
				else
					kbtn.Text = currentName
					kbtn.TextColor3 = window.theme.GrayLt
				end
			end)
		end)
		local elem = { ID = id, Value = currentName, label = cfgId or text, _mode = "keybind" }
		elem.SetValue = function(val)
			kbtn.Text = type(val) == "string" and val or tostring(val)
			window.configs[id].Value = val
		end
		local keyMode = "Hold"
		kbtn.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton2 then
				keyMode = keyMode == "Hold" and "Toggle" or "Hold"
				self:notify(keyMode, "info", 1)
			end
		end)
		elem._keybindMode = keyMode

		updateSize()
		elem.frame = r
		elem.SetDesc = function(self_or_d, d) if type(self_or_d) == "string" then lbl.Text = self_or_d else lbl.Text = d end end
		return elem
	end

	function group:label(text, color, tooltip)
		local f = Instance.new("Frame")
		f.Size = UDim2.new(1, 0, 0, 0)
		f.BackgroundTransparency = 1
		f.AutomaticSize = Enum.AutomaticSize.Y
		f.Parent = items
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -8, 0, 0)
		lbl.Position = UDim2.new(0, 4, 0, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = text
		lbl.TextColor3 = color or window.theme.Gray
		lbl.Font = Enum.Font.GothamSemibold
		lbl.TextSize = 11
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextWrapped = true
		lbl.AutomaticSize = Enum.AutomaticSize.Y
		lbl.ZIndex = 3
		lbl.Parent = f
		updateSize()
		local ref = { frame = f }
		function ref:setText(t)
			lbl.Text = t
			updateSize()
		end

		function ref:setColor(c) lbl.TextColor3 = c end

		ref.remove = function() f:Destroy(); updateSize() end
		function ref:SetVisible(v, anim)
			if not anim then
				f.Visible = v
				f.Size = UDim2.new(1, 0, 0, v and 0 or 0)
				if group and group.updateSize then group.updateSize() end
				return
			end
			f.ClipsDescendants = true
			if v then f.Visible = true end
			local target = v and (lbl.TextBounds.Y + 6) or 0
			local tw = TweenService:Create(f, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 0, target)
			})
			tw.Completed:Connect(function() if not v then f.Visible = false end; if group and group.updateSize then group.updateSize() end end)
			tw:Play()
		end
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
		pcall(function() f.remove = function() f:Destroy(); updateSize() end end)
		local ref = { frame = f }
		function ref:SetVisible(v, anim)
			local h = text and 18 or 10
			if not anim then
				f.Visible = v
				f.Size = UDim2.new(1, 0, 0, v and h or 0)
				if group and group.updateSize then group.updateSize() end
				return
			end
			f.ClipsDescendants = true
			if v then f.Visible = true end
			local tw = TweenService:Create(f, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 0, v and h or 0)
			})
			tw.Completed:Connect(function() if not v then f.Visible = false end; if group and group.updateSize then group.updateSize() end end)
			tw:Play()
		end
		ref.remove = function() f:Destroy(); updateSize() end
		return ref
	end

	function group:button(text, callback, tooltip, align, color, style, bgColor, icon)
		style = style or "bg"
		local ALIGN_MAP = { left = Enum.TextXAlignment.Left, center = Enum.TextXAlignment.Center, right = Enum.TextXAlignment.Right }
		local resolvedAlign = Enum.TextXAlignment.Center
		if align then
			if type(align) == "string" then
				resolvedAlign = ALIGN_MAP[align:lower()] or Enum.TextXAlignment.Center
			else
				resolvedAlign = align
			end
		end
		local btn = Instance.new("TextButton")
		btn.AutoButtonColor = false
		btn.Size = UDim2.new(1, 0, 0, 32)
		btn.BorderSizePixel = 0
		btn.Text = ""
		btn.ZIndex = 3
		btn.Parent = items
		local btnOverlay = Instance.new("Frame")
		btnOverlay.Size = UDim2.fromScale(1, 1)
		btnOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
		btnOverlay.BackgroundTransparency = 0.7
		btnOverlay.BorderSizePixel = 0
		btnOverlay.Visible = false
		btnOverlay.ZIndex = 10
		btnOverlay.Parent = btn
		Instance.new("UICorner", btnOverlay).CornerRadius = UDim.new(0, 4)
		local function showPress() TweenService:Create(btnOverlay, TweenInfo.new(0.06, Enum.EasingStyle.Quad), { BackgroundTransparency = 0.7 }):Play(); btnOverlay.Visible = true end
		local function hidePress() TweenService:Create(btnOverlay, TweenInfo.new(0.06, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play(); task.delay(0.07, function() btnOverlay.Visible = false end) end
		btn.MouseButton1Down:Connect(showPress)
		btn.MouseButton1Up:Connect(hidePress)
		btn.MouseLeave:Connect(hidePress)

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
			lbl.TextXAlignment = resolvedAlign
			lbl.ZIndex = 4
			lbl.Parent = btn
		elseif style == "text" then
			btn.BackgroundTransparency = 1
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, 0, 1, 0)
			lbl.Position = UDim2.new(0, 0, 0, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text = text
			lbl.TextColor3 = color or window.theme.Accent
			lbl.Font = Enum.Font.GothamSemibold
			lbl.TextSize = 13
			lbl.TextXAlignment = resolvedAlign
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
			bstroke.Color = window.theme.Border
			bstroke.Thickness = 1
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, 0, 1, 0)
			lbl.Position = UDim2.new(0, 0, 0, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text = text
			lbl.TextColor3 = color or window.theme.White
			lbl.Font = Enum.Font.GothamSemibold
			lbl.TextSize = 13
			lbl.TextXAlignment = resolvedAlign
			lbl.ZIndex = 4
			lbl.Parent = btn
		end

		btn.MouseButton1Click:Connect(callback)
		updateSize()
		pcall(function() btn.remove = function() btn:Destroy(); updateSize() end end)
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

		updateSize()
		ref.remove = function() r:Destroy(); updateSize() end
			function ref:SetVisible(v, anim)
				if not anim then
					r.Visible = v
					r.Size = UDim2.new(1, 0, 0, v and 42 or 0)
					if group and group.updateSize then group.updateSize() end
					return
				end
				r.ClipsDescendants = true
				if v then r.Visible = true end
				local tw = TweenService:Create(r, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					Size = UDim2.new(1, 0, 0, v and 42 or 0)
				})
				tw.Completed:Connect(function() if not v then r.Visible = false end; if group and group.updateSize then group.updateSize() end end)
				tw:Play()
			end
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

		updateSize()
		ref.remove = function() r:Destroy(); updateSize() end
		function ref:SetVisible(v, anim)
			local h = height + 8
			if not anim then
				r.Visible = v
				r.Size = UDim2.new(1, 0, 0, v and h or 0)
				if group and group.updateSize then group.updateSize() end
				return
			end
			r.ClipsDescendants = true
			if v then r.Visible = true end
			local tw = TweenService:Create(r, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 0, v and h or 0)
			})
			tw.Completed:Connect(function() if not v then r.Visible = false end; if group and group.updateSize then group.updateSize() end end)
			tw:Play()
		end
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
				if newColor then
					pill.BackgroundColor3 = newColor
					pillStroke.Color = newColor
					lbl.TextColor3 = newColor
				end
			end

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
				if newColor then
					pill.BackgroundColor3 = newColor
					pillStroke.Color = newColor
					lbl.TextColor3 = newColor
				end
			end

			updateSize()
			ref.remove = function() r:Destroy(); updateSize() end
			function ref:SetVisible(v, anim)
				local h = position == "inline" and 24 or 28
				if not anim then
					r.Visible = v
					r.Size = UDim2.new(1, 0, 0, v and h or 0)
					if group and group.updateSize then group.updateSize() end
					return
				end
				r.ClipsDescendants = true
				if v then r.Visible = true end
				local tw = TweenService:Create(r, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					Size = UDim2.new(1, 0, 0, v and h or 0)
				})
				tw.Completed:Connect(function() if not v then r.Visible = false end; if group and group.updateSize then group.updateSize() end end)
				tw:Play()
			end
			return ref
		end
	end

	function group:expandableToggle(text, default, contentFunc, tooltip)
		return self:toggle(text, default, nil, tooltip, nil, true, contentFunc)
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

		local arrow = Instance.new("TextLabel")
		arrow.Size = UDim2.new(0, 20, 1, 0)
		arrow.Position = UDim2.new(1, -22, 0, 0)
		arrow.BackgroundTransparency = 1
		arrow.Text = default and string.char(226, 150, 188) or string.char(226, 150, 182)
		arrow.TextColor3 = window.theme.Accent
		arrow.Font = Enum.Font.GothamBold
		arrow.TextSize = 14
		arrow.ZIndex = 4
		arrow.Parent = toggleRow
		table.insert(window.accentObjects, arrow)

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -28, 1, 0)
		lbl.Position = UDim2.new(0, 4, 0, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = text
	lbl.TextColor3 = window.theme.GrayLt
	lbl.Font = Enum.Font.GothamSemibold
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextYAlignment = Enum.TextYAlignment.Center
	lbl.ZIndex = 4
		lbl.Parent = toggleRow
		local contentFrame = Instance.new("Frame")
		contentFrame.Size = UDim2.new(1, 0, 0, 0)
		contentFrame.Position = UDim2.new(0, 0, 0, 34)
		contentFrame.BackgroundTransparency = 1
		contentFrame.Parent = container
		local contentLayout = Instance.new("UIListLayout", contentFrame)
		contentLayout.Padding = UDim.new(0, 2)
		contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
		local state = default
		local function updateContentSize()
			local h = contentLayout.AbsoluteContentSize.Y
			contentFrame.Size = UDim2.new(1, 0, 0, h)
			container.Size = UDim2.new(1, 0, 0, 34 + (state and h or 0))
			updateSize()
		end
		contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateContentSize)
		local nestedGroup = buildNestedGroup(contentFrame, updateContentSize)
		if contentFunc then contentFunc(nestedGroup) end
		toggleRow.MouseButton1Click:Connect(function()
			state = not state
			arrow.Text = state and string.char(226, 150, 188) or string.char(226, 150, 182)
			local targetH = 34 + (state and contentLayout.AbsoluteContentSize.Y or 0)
			TweenService:Create(container, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 0, targetH)
			}):Play()
			task.delay(0.21, updateSize)
		end)
		updateContentSize()
		return container
	end

	function group:colorpicker(text, default, callback, tooltip, icon, cfgId, settingsCallback)
		assert(text ~= nil and text ~= "", "ColorPicker - Missing text")
		local r, elem = createColorPicker(group, items, window, text, default, callback, cfgId, settingsCallback)
		updateSize()
		return elem
	end

	function 	group:multidropdown(text, options, default, callback, tooltip, refreshCallback, cfgId)
		assert(text ~= nil and text ~= "", "MultiDropdown - Missing text")
		local r, elem = createMultiDropdown(group, items, window, text, options, default, callback, refreshCallback, cfgId)
		updateSize()
		return elem
	end

	function group:textbox(text, default, placeholder, callback, tooltip, cfgId)
		assert(text ~= nil and text ~= "", "Textbox - Missing text")
		local id = generateID()
		local r = Instance.new("Frame")
		r.Size = UDim2.new(1, 0, 0, 50)
		r.BackgroundTransparency = 1
		r.BorderSizePixel = 0
		r.Parent = items
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -4, 0, 16)
		lbl.Position = UDim2.new(0, 4, 0, 3)
		lbl.BackgroundTransparency = 1
		lbl.Text = text
		lbl.TextColor3 = window.theme.White
		lbl.Font = Enum.Font.GothamSemibold
		lbl.TextSize = 12
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextWrapped = true
		lbl.ZIndex = 3
		lbl.Parent = r
		local box = Instance.new("TextBox")
		box.Size = UDim2.new(1, 0, 0, 22)
		box.Position = UDim2.new(0, 0, 0, 24)
		box.BackgroundColor3 = window.theme.Track
		box.BorderSizePixel = 0
		box.ZIndex = 3
		box.Parent = r
		box.Text = default or ""
		box.TextColor3 = window.theme.Accent
		box.Font = Enum.Font.GothamSemibold
		box.TextSize = 13
		box.ClearTextOnFocus = false
		box.TextWrapped = true
		box.PlaceholderText = placeholder or ""
		box.PlaceholderColor3 = window.theme.Gray
		Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
		local tbStroke = Instance.new("UIStroke", box)
		tbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		tbStroke.Color = window.theme.Border
		tbStroke.Thickness = 1
		table.insert(window.accentObjects, box)
		local current = default or ""
		box.FocusLost:Connect(function(enter)
				current = box.Text
				window:SafeCallback(callback, current)
				window.configs[id].Value = current
		end)
		local elem = {
			ID = id,
			Value = current,
			DefaultValue = default or "",
			label = cfgId or text,
			DefaultHeight = 50,
			SetValue = function(val)
				current = val
				box.Text = val
				window:SafeCallback(callback, val)
				window.configs[id].Value = val
			end
		}
		window.configs[id] = finalizeElement(elem, window, group)
		updateSize()
		elem.frame = r
		elem.SetDesc = function(self_or_d, d) if type(self_or_d) == "string" then lbl.Text = self_or_d else lbl.Text = d end end
		return elem
	end

	function group:numberbox(text, default, min, max, callback, tooltip, cfgId)
		assert(text ~= nil and text ~= "", "Numberbox - Missing text")
		min = min or -math.huge
		max = max or math.huge
		local id = generateID()
		local r = Instance.new("Frame")
		r.Size = UDim2.new(1, 0, 0, 50)
		r.BackgroundTransparency = 1
		r.BorderSizePixel = 0
		r.Parent = items
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -66, 0, 18)
		lbl.Position = UDim2.new(0, 4, 0, 6)
		lbl.BackgroundTransparency = 1
		lbl.Text = text
		lbl.TextColor3 = window.theme.White
		lbl.Font = Enum.Font.GothamSemibold
		lbl.TextSize = 12
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextWrapped = true
		lbl.ZIndex = 3
		lbl.Parent = r
		local box = Instance.new("TextBox")
		box.Size = UDim2.new(0, 54, 0, 22)
		box.Position = UDim2.new(1, -58, 0, 5)
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
		table.insert(window.accentObjects, box)
		local current = default or 0
		local function validate()
			local num = tonumber(box.Text)
			if num then
				num = math.clamp(num, min, max)
				current = num
				box.Text = tostring(num)
				window:SafeCallback(callback, num)
				window.configs[id].Value = num
			else
				box.Text = tostring(current)
			end
		end
		box.FocusLost:Connect(function() validate() end)
		local elem = {
			ID = id,
			Value = current,
			DefaultValue = default or 0,
			label = cfgId or text,
			_isNumber = true,
			DefaultHeight = 50,
			SetValue = function(val)
				val = math.clamp(val, min, max)
				current = val
				box.Text = tostring(val)
				window:SafeCallback(callback, val)
				window.configs[id].Value = val
			end
		}
		window.configs[id] = finalizeElement(elem, window, group)
		updateSize()
		elem.frame = r
		elem.SetDesc = function(self_or_d, d) if type(self_or_d) == "string" then lbl.Text = self_or_d else lbl.Text = d end end
		return elem
	end

	function group:rangeslider(text, minVal, maxVal, defaultMin, defaultMax, callback, step, tooltip, cfgId)
		assert(text ~= nil and text ~= "", "RangeSlider - Missing text")
		local id = generateID()
		step = step or 1
		local pctMin, pctMax = 0, 1
		local function roundToStep(val) return math.floor((val - minVal) / step + 0.5) * step + minVal end
		local r = Instance.new("Frame")
		r.Size = UDim2.new(1, 0, 0, 52)
		r.BackgroundTransparency = 1
		r.BorderSizePixel = 0
		r.Parent = items
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -90, 0, 16)
		lbl.Position = UDim2.new(0, 4, 0, 4)
		lbl.BackgroundTransparency = 1
		lbl.Text = text
		lbl.TextColor3 = window.theme.White
		lbl.Font = Enum.Font.GothamSemibold
		lbl.TextSize = 12
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextWrapped = true
		lbl.ZIndex = 3
		lbl.Parent = r
		local valueBox = Instance.new("Frame")
		valueBox.AutomaticSize = Enum.AutomaticSize.X
		valueBox.Size = UDim2.new(0, 0, 0, 18)
		valueBox.AnchorPoint = Vector2.new(1, 0)
		valueBox.Position = UDim2.new(1, -2, 0, 4)
		valueBox.BackgroundColor3 = window.theme.Track
		valueBox.BorderSizePixel = 0
		valueBox.ZIndex = 3
		valueBox.Parent = r
		Instance.new("UICorner", valueBox).CornerRadius = UDim.new(0, 4)
		local vbPad = Instance.new("UIPadding", valueBox)
		vbPad.PaddingLeft = UDim.new(0, 6)
		vbPad.PaddingRight = UDim.new(0, 6)
		local rsVbStroke = Instance.new("UIStroke", valueBox)
		rsVbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		rsVbStroke.Color = window.theme.Border
		rsVbStroke.Thickness = 1
		local valueLabel = Instance.new("TextLabel")
		valueLabel.AutomaticSize = Enum.AutomaticSize.X
		valueLabel.Size = UDim2.new(0, 0, 1, 0)
		valueLabel.BackgroundTransparency = 1
		valueLabel.Text = tostring(roundToStep(defaultMin)) .. " - " .. tostring(roundToStep(defaultMax))
		valueLabel.TextColor3 = window.theme.Accent
		valueLabel.Font = Enum.Font.GothamSemibold
		valueLabel.TextSize = 12
		valueLabel.ZIndex = 4
		valueLabel.Parent = valueBox
		table.insert(window.accentObjects, valueLabel)
		local track = Instance.new("Frame")
		track.Size = UDim2.new(1, 0, 0, 20)
		track.Position = UDim2.new(0, 0, 0, 28)
		track.BackgroundColor3 = window.theme.Track
		track.BorderSizePixel = 0
		track.ZIndex = 3
		track.Parent = r
		Instance.new("UICorner", track).CornerRadius = UDim.new(0, 4)
		local trackStroke = Instance.new("UIStroke", track)
		trackStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		trackStroke.Color = window.theme.Border
		trackStroke.Thickness = 1

		local numSteps = math.floor((maxVal - minVal) / step)
		if numSteps > 1 and numSteps <= 50 then
			for i = 0, numSteps do
				local pct = i / numSteps
				local tickMark = Instance.new("Frame")
				tickMark.Size = UDim2.new(0, 1, 0, 6)
				tickMark.Position = UDim2.new(pct, 0, 0.5, -3)
				tickMark.BackgroundColor3 = window.theme.Border
				tickMark.BorderSizePixel = 0
				tickMark.ZIndex = 5
				tickMark.Parent = track
			end
		end

		local fill = Instance.new("Frame")
		fill.Size = UDim2.new(pctMax - pctMin, 0, 1, 0)
		fill.Position = UDim2.new(pctMin, 0, 0, 0)
		fill.BackgroundColor3 = window.theme.Accent
		fill.BorderSizePixel = 0
		fill.ZIndex = 4
		fill.Parent = track
		table.insert(window.accentObjects, fill)
		Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 2)
		local HANDLE_W = 5
		local accentDark = Color3.new(window.theme.Accent.r * 0.55, window.theme.Accent.g * 0.55, window.theme.Accent.b * 0.55)
		local handleLeft = Instance.new("Frame")
		handleLeft.Size = UDim2.new(0, HANDLE_W, 0, 20)
		handleLeft.Position = UDim2.new(pctMin, -HANDLE_W/2, 0, 0)
		handleLeft.BackgroundColor3 = accentDark
		handleLeft.BorderSizePixel = 0
		handleLeft.ZIndex = 5
		handleLeft.Parent = track
		table.insert(window.accentDarkObjects, handleLeft)
		local handleRight = Instance.new("Frame")
		handleRight.Size = UDim2.new(0, HANDLE_W, 0, 20)
		handleRight.Position = UDim2.new(pctMax, -HANDLE_W/2, 0, 0)
		handleRight.BackgroundColor3 = accentDark
		handleRight.BorderSizePixel = 0
		handleRight.ZIndex = 5
		handleRight.Parent = track
		table.insert(window.accentDarkObjects, handleRight)
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
		local currentMin = roundToStep(defaultMin)
		local currentMax = roundToStep(defaultMax)
		local function updateDisplay()
			valueLabel.Text = tostring(currentMin) .. " - " .. tostring(currentMax)
			pctMin = (currentMin - minVal) / (maxVal - minVal)
			pctMax = (currentMax - minVal) / (maxVal - minVal)
			fill.Size = UDim2.new(pctMax - pctMin, 0, 1, 0)
			fill.Position = UDim2.new(pctMin, 0, 0, 0)
			handleLeft.Position = UDim2.new(pctMin, -HANDLE_W/2, 0, 0)
			handleRight.Position = UDim2.new(pctMax, -HANDLE_W/2, 0, 0)
			hitLeft.Position = UDim2.new(pctMin, -8, 0.5, -11)
			hitRight.Position = UDim2.new(pctMax, -8, 0.5, -11)
		end
				local function apply(pos, which)
			local trackSize = track.AbsoluteSize.X
			if trackSize == 0 then trackSize = 1 end
			local rel = math.clamp((pos - track.AbsolutePosition.X) / trackSize, 0, 1)
			local val = minVal + (maxVal - minVal) * rel
			val = roundToStep(val)
			if which == "left" then
				val = math.min(val, currentMax)
				currentMin = val
			else
				val = math.max(val, currentMin)
				currentMax = val
			end
			updateDisplay()
			window:SafeCallback(callback, currentMin, currentMax)
			window.configs[id].Value = { currentMin, currentMax }
		end
		hitLeft.MouseButton1Down:Connect(function()
			dragging = true
			dragType = "left"
		end)
		hitRight.MouseButton1Down:Connect(function()
			dragging = true
			dragType = "right"
		end)
		local rsInputConn = UIS.InputChanged:Connect(function(i)
			if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
				apply(i.Position.X, dragType)
			end
		end)
		local rsEndConn = UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
		table.insert(window.connections, rsInputConn)
		table.insert(window.connections, rsEndConn)
		local elem = {
			ID = id,
			Value = { currentMin, currentMax },
			DefaultValue = { roundToStep(defaultMin), roundToStep(defaultMax) },
			label = cfgId or text,
			_isRange = true,
			SetValue = function(
				t)
				currentMin, currentMax = roundToStep(t[1]), roundToStep(t[2]); updateDisplay()
				window:SafeCallback(callback, currentMin, currentMax)
				window.configs[id].Value = { currentMin, currentMax }
			end
		}
		window.configs[id] = finalizeElement(elem, window, group)
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
		local splitRatio = 0.5
		local SPLIT_GAP = 8
		local function applySplitRatio()
			local w = splitRow.AbsoluteSize.X
			if w == 0 then w = 400 end
			local lw = math.floor(w * splitRatio - SPLIT_GAP / 2)
			local rw = w - lw - SPLIT_GAP
			lFrame.Size = UDim2.new(0, math.max(lw, 50), 0, 0)
			rFrame.Size = UDim2.new(0, math.max(rw, 50), 0, 0)
		end
		local lFrame = Instance.new("Frame")
		lFrame.Size = UDim2.new(0.5, -(SPLIT_GAP / 2), 0, 0)
		lFrame.BackgroundTransparency = 1
		lFrame.AutomaticSize = Enum.AutomaticSize.Y
		lFrame.ClipsDescendants = true
		lFrame.Parent = splitRow
		Instance.new("UIListLayout", lFrame).Padding = UDim.new(0, 2)
		local rFrame = Instance.new("Frame")
		rFrame.Size = UDim2.new(0.5, -(SPLIT_GAP / 2), 0, 0)
		rFrame.Position = UDim2.new(0.5, SPLIT_GAP / 2, 0, 0)
		rFrame.BackgroundTransparency = 1
		rFrame.AutomaticSize = Enum.AutomaticSize.Y
		rFrame.ClipsDescendants = true
		rFrame.Parent = splitRow
		Instance.new("UIListLayout", rFrame).Padding = UDim.new(0, 2)
		local divider = Instance.new("Frame")
		divider.Size = UDim2.new(0, 4, 1, 0)
		divider.Position = UDim2.new(0.5, -2, 0, 0)
		divider.BackgroundColor3 = window.theme.Border
		divider.BorderSizePixel = 0
		divider.ZIndex = 50
		divider.Parent = splitRow
		local dividerHit = Instance.new("TextButton")
		dividerHit.Size = UDim2.new(0, 10, 1, 0)
		dividerHit.Position = UDim2.new(0.5, -5, 0, 0)
		dividerHit.BackgroundTransparency = 1
		dividerHit.Text = ""
		dividerHit.ZIndex = 51
		pcall(function() dividerHit.Cursor = Enum.CursorSystem.ResizeWidth end)
		dividerHit.Parent = splitRow
		local draggingSplit = false
		dividerHit.MouseButton1Down:Connect(function()
			draggingSplit = true
		end)
		local splitInputConn = UIS.InputChanged:Connect(function(i)
			if not draggingSplit or (i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch) then return end
			local w = splitRow.AbsoluteSize.X
			if w == 0 then return end
			splitRatio = math.clamp((i.Position.X - splitRow.AbsolutePosition.X) / w, 0.15, 0.85)
			applySplitRatio()
			updateSplitSize()
		end)
		local splitEndConn = UIS.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then draggingSplit = false end
		end)
		table.insert(window.connections, splitInputConn)
		table.insert(window.connections, splitEndConn)
		local function updateSplitSize()
			local lh = lFrame.UIListLayout.AbsoluteContentSize.Y
			local rh = rFrame.UIListLayout.AbsoluteContentSize.Y
			splitRow.Size = UDim2.new(1, 0, 0, math.max(lh, rh))
			updateSize()
		end
		local rsConn1 = lFrame.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			applySplitRatio()
			updateSplitSize()
		end)
		local rsConn2 = rFrame.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			applySplitRatio()
			updateSplitSize()
		end)
		table.insert(window.connections, rsConn1)
		table.insert(window.connections, rsConn2)
		local leftGroup = {
			window = window,
			frame = lFrame,
			items = lFrame,
			tab = group.tab,
			sub = group.sub,
			updateSize =
				updateSplitSize
		}
		local rightGroup = {
			window = window,
			frame = rFrame,
			items = rFrame,
			tab = group.tab,
			sub = group.sub,
			updateSize =
				updateSplitSize
		}
		for k, v in pairs(group) do
			if type(v) == "function" and k ~= "split" and k ~= "addGroup" then
				leftGroup[k] = function(self_, ...) return v(leftGroup, ...) end
				rightGroup[k] = function(self_, ...) return v(rightGroup, ...) end
			end
		end
		task.defer(applySplitRatio)
		return leftGroup, rightGroup
	end

	if subtab and subtab.groups then table.insert(subtab.groups, group) end
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
	local colObj = setmetatable({ frame = col, window = window, tab = self.tab, sub = self }, UILib.Column)
	return colObj:addGroup(title)
end

return UILib
