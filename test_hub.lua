if _G.CloverTestLoaded then
	_G.CloverTestAlive = false
	task.wait(0.5)
end
_G.CloverTestLoaded = true
_G.CloverTestAlive = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer

local Lib = loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/xDodox/CloverLib/refs/heads/main/CloverLib.lua"
))()

local Window = Lib.newWindow(
	"CloverHub Test",
	Vector2.new(620, 500),
	nil, nil, false, true, true,
	"lucide:monitor"
)
Window:setVisible(false)
Window:addWatermark("CloverHUB | Test")

local function unload()
	_G.CloverTestAlive = false
	_G.CloverTestLoaded = false
	local char = LP.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = 16; hum.JumpPower = 50 end
	end
end
table.insert(Window.connections, Window.sg.AncestryChanged:Connect(function()
	if not Window.sg.Parent then unload() end
end))

-- ====== TABS ======
local mainTab = Window:addTab("Main", { icon = "lucide:home" })
local visualsTab = Window:addTab("Visuals", { icon = "lucide:eye" })
local miscTab = Window:addTab("Misc", { icon = "lucide:settings" })

-- ====== MAIN TAB ======
local combat = mainTab:addSubTab("Combat")
local cL, cR = combat:split()

local aimGrp = cL:addGroup("Aimbot")
aimGrp:toggle("Aimbot", false, function(v)
	print("Aimbot:", v)
end, "Enable aimbot with configurable FOV and hit parts", nil, nil, nil, nil, function(anchor)
	Window:openAdvancedPanel(anchor, function(popup)
		popup:toggle("Silent Aim", false, function(v2) print("Silent Aim:", v2) end)
		popup:toggle("Visibility Check", true, function(v2) print("Vis Check:", v2) end)
		popup:slider("FOV Radius", 30, 360, 120, function(v2) print("FOV:", v2) end)
		popup:dropdown("Hit Part", {"Head", "Torso", "Legs", "Random"}, "Head", function(v2) print("Hit:", v2) end)
		popup:keybind("Aim Key", "E", function(v2) print("AimKey:", v2) end)
		popup:colorpicker("FOV Color", Color3.new(1, 0, 0), function(v2) print("FOVColor:", v2) end, "Color of the FOV circle", nil, "fov_color")
	end)
end, "aimbot")

aimGrp:slider("Smoothness", 1, 20, 5, function(v) print("Smooth:", v) end, 1, "Higher = smoother but slower", nil, nil, "%", "aim_smooth")
aimGrp:dropdown("Target Part", {"Head", "Torso", "Legs"}, "Head", function(v) print("Target:", v) end, "Which body part to aim at", nil, nil, "target_part")

local farmGrp = cR:addGroup("Auto Farm")
farmGrp:toggle("Auto Farm", false, function(v) print("Farm:", v) end, "Automatically farm nearby mobs", nil, nil, nil, nil, function(anchor)
	Window:openAdvancedPanel(anchor, function(popup)
		popup:toggle("Auto Attack", true, function(v2) print("AutoAttack:", v2) end)
		popup:slider("Attack Speed", 1, 10, 2, function(v2) print("AtkSpd:", v2) end)
		popup:toggle("Auto Quest", false, function(v2) print("Quest:", v2) end)
		popup:multidropdown("Mob List", {"Skeleton", "Zombie", "Dragon", "Spider", "Wolf"}, {"Skeleton"}, function(v2) print("Mobs:", v2) end, "Select mobs to farm")
		popup:slider("Farm Radius", 100, 5000, 1000, function(v2) print("Radius:", v2) end)
	end)
end, "autofarm")

farmGrp:toggle("Auto Sell", false, function(v) print("Sell:", v) end, "Sell items when inventory is full", nil, nil, nil, nil, nil, "autosell")
farmGrp:slider("Sell Threshold", 50, 100, 80, function(v) print("Sell%:", v) end, 5, "Inventory % before auto-sell", nil, nil, "%", "sell_pct")
farmGrp:numberbox("Max Coins", 0, 100000, 50000, function(v) print("MaxCoins:", v) end, "Stop farming when reaching this", "coins_max")

-- ====== VISUALS TAB ======
local esp = visualsTab:addSubTab("ESP")
local eL, eR = esp:split()

local espGrp = eL:addGroup("Player ESP")
espGrp:toggle("Enable ESP", false, function(v) print("ESP:", v) end, "Show boxes, names, health around players", nil, nil, nil, nil, nil, "esp_players")
espGrp:colorpicker("ESP Color", Color3.new(0, 1, 0), function(v) print("ESPColor:", v) end, "Color of ESP boxes and text", nil, "esp_color", function(anchor)
	Window:openAdvancedPanel(anchor, function(popup)
		popup:slider("Box Thickness", 1, 5, 1, function(v2) print("BoxT:", v2) end)
		popup:slider("Text Size", 8, 18, 11, function(v2) print("TextSz:", v2) end)
		popup:toggle("Show Distance", true, function(v2) print("Dist:", v2) end)
		popup:toggle("Show Weapon", true, function(v2) print("Wpn:", v2) end)
	end)
end)

espGrp:toggle("Tracers", false, function(v) print("Tracers:", v) end)
espGrp:multidropdown("Features", {"Box", "Name", "Health", "Distance", "Weapon", "Skeleton"}, {"Box", "Name"}, function(v) print("Features:", v) end, "What to show", nil, "esp_features")
espGrp:slider("Max Distance", 100, 5000, 2000, function(v) print("Dist:", v) end, 100, "How far to render", nil, nil, "k", "esp_distance")

local lgtGrp = eR:addGroup("Lighting")
lgtGrp:toggle("Fullbright", false, function(v) print("Fullbright:", v) end)
lgtGrp:slider("FOV", 30, 120, 70, function(v) print("FOV:", v) end)

-- ====== MISC TAB ======
local move = miscTab:addSubTab("Movement")
local mL, mR = move:split()

local speedGrp = mL:addGroup("Speed")
speedGrp:toggle("Custom Speed", false, function(v) print("Speed:", v) end, "Override walk speed", nil, nil, nil, nil, nil, "customspeed")
speedGrp:slider("Walk Speed", 16, 200, 27, function(v) print("WS:", v) end, 1, nil, nil, nil, nil, "walkspeed")
speedGrp:keybind("Speed Key", "LeftShift", function(v) print("SpeedKey:", v) end, "Hold to activate speed", "speedkey")

local otherGrp = mR:addGroup("Other")
otherGrp:toggle("NoClip", false, function(v) print("Noclip:", v) end, "Walk through walls", nil, nil, nil, nil, nil, "noclip")
otherGrp:toggle("Anti AFK", true, function(v) print("AFK:", v) end)
otherGrp:button("Unload", function() Window:Destroy() unload() end, "Cleanly remove the UI", nil, nil, Color3.fromRGB(255, 80, 80))

-- ====== STARTUP ======
Window:tryAutoLoad()
Window:setVisible(true)
