-- VESTA LOADING SCREEN (black screen, bubbly title, small "loading" at the bottom)
do
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local TweenService = game:GetService("TweenService")
	local genv = (getgenv and getgenv()) or _G
	genv.VestaLoadDone = nil

	local FONT = Enum.Font.FredokaOne -- bubbly font
	local TITLE = "VESTA RECOLOR"
	local MIN_TIME = 2.5   -- shortest time the screen shows (seconds)
	local MAX_TIME = 5     -- gives up waiting after this long and fades anyway

	local old = genv.VestaLoaderGui
	if old then pcall(function() old:Destroy() end) end

	local sg = Instance.new("ScreenGui")
	sg.Name = "VestaLoader"
	sg.IgnoreGuiInset = true
	sg.ResetOnSpawn = false
	sg.DisplayOrder = 999999
	pcall(function() sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling end)
	local okParent = pcall(function()
		sg.Parent = (gethui and gethui()) or game:GetService("CoreGui")
	end)
	if not okParent or not sg.Parent then
		sg.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end
	genv.VestaLoaderGui = sg

	-- CanvasGroup so the whole screen can fade out in one go
	local root = Instance.new("CanvasGroup")
	root.Size = UDim2.new(1, 0, 1, 0)
	root.BackgroundColor3 = Color3.new(0, 0, 0)
	root.BorderSizePixel = 0
	root.Active = true -- blocks clicks going through to the game
	root.Parent = sg

	-- floating bubbles
	local bubbles = {}
	for i = 1, 22 do
		local size = math.random(14, 46)
		local b = Instance.new("Frame")
		b.Size = UDim2.new(0, size, 0, size)
		b.AnchorPoint = Vector2.new(0.5, 0.5)
		local shade = math.random(90, 255)
		b.BackgroundColor3 = Color3.fromRGB(shade, shade, shade)
		b.BackgroundTransparency = 0.9
		b.BorderSizePixel = 0
		b.Parent = root
		Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
		local s = Instance.new("UIStroke")
		s.Color = Color3.fromRGB(shade, shade, shade)
		s.Thickness = 1.5
		s.Transparency = 0.6
		s.Parent = b
		bubbles[i] = { f = b, x = math.random(), speed = 0.04 + math.random() * 0.08, phase = math.random(), sway = 0.01 + math.random() * 0.03 }
	end

	-- title, one label per letter so each can bounce
	local holder = Instance.new("Frame")
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.new(0.5, 0, 0.45, 0)
	holder.Size = UDim2.new(0.88, 0, 0.14, 0)
	holder.BackgroundTransparency = 1
	holder.Parent = root
	local cap = Instance.new("UISizeConstraint")
	cap.MaxSize = Vector2.new(720, 90)
	cap.Parent = holder

	local letters = {}
	local n = #TITLE
	for i = 1, n do
		local ch = string.sub(TITLE, i, i)
		if ch ~= " " then
			local l = Instance.new("TextLabel")
			l.AnchorPoint = Vector2.new(0.5, 0.5)
			l.Position = UDim2.new((i - 0.5) / n, 0, 0.5, 0)
			l.Size = UDim2.new(1 / n, 0, 1, 0)
			l.BackgroundTransparency = 1
			l.Font = FONT
			l.Text = ch
			l.TextScaled = true
			l.TextColor3 = Color3.new(1, 1, 1)
			l.TextTransparency = 1
			l.Parent = holder
			local lim = Instance.new("UITextSizeConstraint")
			lim.MaxTextSize = 80
			lim.Parent = l
			local glow = Instance.new("UIStroke")
			glow.Thickness = 3
			glow.Transparency = 1
			glow.Parent = l
			letters[#letters + 1] = { l = l, g = glow, i = i }
		end
	end

	-- progress bar (sliding shine) + small "loading" text at the bottom
	local barBack = Instance.new("Frame")
	barBack.AnchorPoint = Vector2.new(0.5, 1)
	barBack.Position = UDim2.new(0.5, 0, 1, -62)
	barBack.Size = UDim2.new(0.5, 0, 0, 6)
	barBack.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	barBack.BorderSizePixel = 0
	barBack.ClipsDescendants = true
	barBack.Parent = root
	local barCap = Instance.new("UISizeConstraint")
	barCap.MaxSize = Vector2.new(320, 6)
	barCap.Parent = barBack
	Instance.new("UICorner", barBack).CornerRadius = UDim.new(1, 0)

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0.35, 0, 1, 0)
	bar.BackgroundColor3 = Color3.new(1, 1, 1)
	bar.BorderSizePixel = 0
	bar.Parent = barBack
	Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
	local barGrad = Instance.new("UIGradient")
	barGrad.Parent = bar

	local loadText = Instance.new("TextLabel")
	loadText.AnchorPoint = Vector2.new(0.5, 1)
	loadText.Position = UDim2.new(0.5, 0, 1, -30)
	loadText.Size = UDim2.new(0, 200, 0, 22)
	loadText.BackgroundTransparency = 1
	loadText.Font = FONT
	loadText.TextSize = 14
	loadText.TextColor3 = Color3.fromRGB(190, 190, 210)
	loadText.Text = "loading"
	loadText.Parent = root

	local start = os.clock()
	local finishing = false
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - start
		for _, d in ipairs(letters) do
			local p = math.clamp((t - d.i * 0.06) / 0.45, 0, 1)
			local pop = 1 - (1 - p) ^ 3
			local bounce = math.sin(t * 4 + d.i * 0.55) * 0.1
			d.l.Position = UDim2.new((d.i - 0.5) / n, 0, 0.5 + bounce + (1 - pop) * 0.7, 0)
			d.l.Rotation = math.sin(t * 3 + d.i) * 4
			d.l.TextTransparency = 1 - pop
			local gray = 0.62 + 0.38 * math.sin(t * 2.2 - d.i * 0.5)
			local c = Color3.new(gray, gray, gray)
			d.l.TextColor3 = c
			d.g.Color = c
			d.g.Transparency = 1 - pop * 0.55
		end
		for _, b in ipairs(bubbles) do
			local y = 1.1 - ((t * b.speed + b.phase) % 1) * 1.25
			b.f.Position = UDim2.new(b.x + math.sin(t * 1.5 + b.phase * 6) * b.sway, 0, y, 0)
		end
		local slide = (t * 0.9) % 1.7 - 0.5
		bar.Position = UDim2.new(slide, 0, 0, 0)
		barGrad.Color = ColorSequence.new(Color3.fromRGB(110, 110, 115), Color3.fromRGB(245, 245, 245))
		loadText.Text = "loading" .. string.rep(".", math.floor(t * 2.5) % 4)
	end)

	local function finish()
		if finishing then return end
		finishing = true
		loadText.Text = "ready!"
		local tw = TweenService:Create(root, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 1 })
		tw:Play()
		tw.Completed:Wait()
		if conn then conn:Disconnect() end
		sg:Destroy()
		genv.VestaLoaderGui = nil
	end

	-- waits for the script to say it's done (VestaLoadDone), but never longer than MAX_TIME
	task.spawn(function()
		while true do
			local t = os.clock() - start
			if t >= MAX_TIME or (t >= MIN_TIME and genv.VestaLoadDone) then break end
			task.wait(0.1)
		end
		finish()
	end)
end

print("[Voidscope Recolor] loading...")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local ContentProvider = game:GetService("ContentProvider")
local LocalPlayer = Players.LocalPlayer

local SHOT_WINDOW = 1.0          -- seconds after you fire during which new effects count as your shot
local SHOT_RADIUS = 30           -- studs from you within which a new effect counts as your shot
local OVERLAY_TRANSPARENCY = 0.6 -- only used if the texture tint isn't supported (colour wash)
local BUBBLY_FONT = Enum.Font.FredokaOne   -- bubbly menu font used everywhere (try Enum.Font.GothamBlack for a sharper look)
local GUI_SCALE = 1.25       -- how big the whole menu is (1 = old size, 1.5 = even bigger)
local MENU_OUTLINE = Color3.fromRGB(70, 74, 88)
local BUTTON_OUTLINE = Color3.fromRGB(120, 125, 142)  -- glass rim around every button
local BUTTON_SELECTED = Color3.fromRGB(0, 150, 235)

-- TRAIL SETTINGS
local TRAIL_LIFETIME = 0.6   -- how long the trail lingers (seconds)
local TRAIL_WIDTH = 0.22     -- how thick the trail is (studs), smaller = thinner
local TRAIL_END = "back"     -- "back" = comes off the very back of the gun, "front" = off the tip
local TRAIL_FLIP = false     -- if the trail comes off the wrong end of the gun, set this to true
local TRAIL_DROP = 0.25      -- how far to move the trail DOWN from where it is now (studs). Bigger = lower, 0 = old position

-- EDITABLE IMAGE SPEED SETTINGS (only used by the built-in backup textures, see SKIN_TEXTURES below)
local MAX_TEX = 512              -- sharper; built once in the background so it doesn't hurt switching (384 = lighter)
local BUDGET_BACKGROUND = 0.006  -- seconds of each frame used while quietly pre-building textures
local BUDGET_WAITING = 0.03      -- if you click a style that isn't ready, it gets most of the frame
local PREBUILD_DELAY = 4         -- seconds before the built-in backup looks (Rainbow / Pink) start building; skins are readied instantly
local MARBLE_SCALE = 1.6         -- backup Diamond / Ruby / Beast pattern size

-- WHITE SCOPE (backup texture only): if the black ends up on the wrong parts, set this to true
local WHITE_INVERT = false

---------------------------------------------------------------------
-- SKIN TEXTURES: the pictures that Gold / Pink / Diamond / Black / Ruby / Beast / White use.
-- Each picture is a full texture for the gun (same layout as the gun's own texture), so the skin shows exactly
-- like the picture. Fill in one value per skin, in any of these forms:
--   1) a Roblox image id:     "rbxassetid://1234567890"  or just  "1234567890"
--      (upload the PNG at create.roblox.com > Dashboard > Creations > Decals, copy the Image id)
--   2) a link to the PNG:     "https://.../gold.png"     (executors with writefile + getcustomasset only)
--   3) a file name in your executor's workspace folder: "gold.png"   (same executor requirement)
-- A skin you leave empty ("") uses the older built-in look for that colour instead, so nothing breaks.
-- (If the game blocks the built-in texture editing, the skin falls back to a plain colour tint.)
--
-- INSTANT SWITCHING: every picture is downloaded into memory when the script starts, and its gun appearance is made in advance
-- for every gun part, so clicking a skin only swaps it in (nothing is loaded or built at click time).
---------------------------------------------------------------------
local SKIN_TEXTURES = {
	gold    = "91851946033992",
	diamond = "82154314380330",
	ruby    = "92501356713156",
	beast   = "78396157128775",
	kitty   = "125707015473446",
	galaxy  = "105612826347881",
}

-- button shine for the special scopes (gold bands / icy diamond facets / ruby / beast)
local GOLD_SEQ = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 160)),
	ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 200, 40)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(190, 130, 15)),
	ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 218, 85)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 240, 160)),
})
local DIAMOND_SEQ = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(230, 252, 255)),
	ColorSequenceKeypoint.new(0.3, Color3.fromRGB(130, 215, 255)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(0.7, Color3.fromRGB(150, 225, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(225, 248, 255)),
})
local RUBY_SEQ = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 120, 130)),
	ColorSequenceKeypoint.new(0.3, Color3.fromRGB(215, 20, 45)),
	ColorSequenceKeypoint.new(0.55, Color3.fromRGB(95, 0, 15)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(230, 40, 60)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 130, 140)),
})
local BEAST_SEQ = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(190, 90, 255)),
	ColorSequenceKeypoint.new(0.3, Color3.fromRGB(110, 40, 220)),
	ColorSequenceKeypoint.new(0.55, Color3.fromRGB(50, 130, 255)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0, 220, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 90, 220)),
})
local KITTY_SEQ = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 225)),
	ColorSequenceKeypoint.new(0.35, Color3.fromRGB(255, 130, 190)),
	ColorSequenceKeypoint.new(0.65, Color3.fromRGB(255, 235, 245)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 170, 210)),
})
local GALAXY_SEQ = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 10, 80)),
	ColorSequenceKeypoint.new(0.3, Color3.fromRGB(110, 50, 210)),
	ColorSequenceKeypoint.new(0.6, Color3.fromRGB(40, 90, 230)),
	ColorSequenceKeypoint.new(0.85, Color3.fromRGB(220, 90, 220)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 10, 80)),
})

-- "skin" = which picture from SKIN_TEXTURES the colour uses. mode / texStyle = the older built-in look, used as the
-- backup when that skin's picture isn't filled in above.
local COLORS = {
	{ name = "Red",        color = Color3.fromRGB(255, 0, 0) },
	{ name = "Green",      color = Color3.fromRGB(0, 255, 0) },
	{ name = "Black",      color = Color3.fromRGB(0, 0, 0) },
	{ name = "Orange",     color = Color3.fromRGB(255, 128, 0) },
	{ name = "Yellow",     color = Color3.fromRGB(255, 255, 0) },
	{ name = "Blue",       color = Color3.fromRGB(0, 100, 255) },
	{ name = "Purple",     color = Color3.fromRGB(160, 32, 240) },
	{ name = "Cyan",       color = Color3.fromRGB(0, 255, 255) },
	{ name = "Pink",       color = Color3.fromRGB(255, 190, 215), mode = "texture", texStyle = "pink" },
	{ name = "White",      color = Color3.fromRGB(238, 238, 244), mode = "texture", texStyle = "white" },
	{ name = "Rainbow",    color = Color3.fromRGB(255, 60, 200), mode = "texture", texStyle = "rainbow", gradient = true, rainbowFx = true },
	{ name = "Gold",       color = Color3.fromRGB(255, 200, 40), mode = "texture", texStyle = "gold", skin = "gold", reflectance = 0.45,
		btnGradient = GOLD_SEQ, effectSeq = GOLD_SEQ },
	{ name = "Diamond",    color = Color3.fromRGB(185, 242, 255), mode = "texture", texStyle = "diamond", skin = "diamond", reflectance = 0.2,
		btnGradient = DIAMOND_SEQ, effectSeq = DIAMOND_SEQ },
	{ name = "Ruby",       color = Color3.fromRGB(190, 15, 40), mode = "texture", texStyle = "ruby", skin = "ruby", reflectance = 0.12,
		btnGradient = RUBY_SEQ, effectSeq = RUBY_SEQ },
	{ name = "Beast",      color = Color3.fromRGB(150, 60, 230), mode = "texture", texStyle = "beast", skin = "beast", reflectance = 0.12,
		btnGradient = BEAST_SEQ, effectSeq = BEAST_SEQ },
	{ name = "Kitty",      color = Color3.fromRGB(255, 150, 200), mode = "texture", texStyle = "pink", skin = "kitty",
		btnGradient = KITTY_SEQ, effectSeq = KITTY_SEQ },
	{ name = "Galaxy",     color = Color3.fromRGB(100, 60, 220), mode = "texture", texStyle = "beast", skin = "galaxy",
		btnGradient = GALAXY_SEQ, effectSeq = GALAXY_SEQ },
}

local RAINBOW_SPIN = 0.08
local RAINBOW = { name = "Chroma", color = Color3.fromRGB(255, 80, 200), mode = "rainbow" }
local RAINBOW_KEYS = {}
for i = 0, 6 do
	table.insert(RAINBOW_KEYS, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(0.83 * i / 6, 0.9, 1)))
end
local RAINBOW_SEQUENCE = ColorSequence.new(RAINBOW_KEYS) -- used for beams / trails / particles and the menu button

local GLASS_TRANSPARENCY = 0.55
local CHROME_REFLECTANCE = 0.45
local SHEEN_BRIGHTNESS = 3
local SHEEN_PINK = Color3.fromRGB(255, 120, 190)
local SHEEN_TEAL = Color3.fromRGB(90, 255, 230)
local GLASS_SHEEN = false
local GLASS = { name = "Glass", color = Color3.fromRGB(255, 255, 255), mode = "pearl", forceGlass = true, sheen = GLASS_SHEEN }

-- MINIMISED ICON
-- To use your orb picture as the minimised icon:
--   1) upload the picture to Roblox (Creator Hub > Assets > Decals/Images)
--   2) paste its id below, e.g. "rbxassetid://1234567890"
-- OR paste a base64 string of the PNG into ICON_PNG_B64 (executors with writefile + getcustomasset only).
-- The built-in picture is the chrome VESTA logo. If it can't be loaded, a plain 'vesta' text button is used.
local MINI_ICON_ASSET = ""
local ICON_SIZE = 170          -- width of the minimised logo
local ICON_ASPECT = 0.325      -- height / width of the logo picture
local ICON_URL = ""
local ICON_PNG_B64 = [=[
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
G5uAC4R/JalAQQHJYbBVKRQKZJiampq++uori8WCB4RMSiQStVrt8XhaW1sVCkVSUtKaNWucTqdYLPb7/T6fD/cHppskBybR4XCU
lJSkpKTY7fZQKNTf3z8wMLBhwwYul6vValNTU1UqFRQEDhr1Kh6PJ5PJFArF0NBQU1OT2WwOh8ONjY0CgQDxM6vCUNSUSqXAYBsM
BgCNoEHw1Kxm4YzBPkQkcbF47A/F8B6Pp7+/H6gVm83mdrtlMllsbGx/fz9EQywWczgcn88nkUgUCsXo6OjQ0BC1PY91HNjfjGeB
8crLyxMIBFarNSkpKS4u7s4775wzZ86ePXt27tzJ5/PVarVUKsUzC4VCnC5UGkIdi8UyMjKiUqmSkpKUSuXLL7+8f/9+gUAQHR3t
dDrxV1DDLKJ1IqBrZPkCgUBRUVFRUZHT6WxtbS0sLMzNze3s7Dx+/Diq/9hNJM80Go3BYNDpdPPmzZsxY4Zer9+3b99f/vKX/v5+
h8Ph9XrpsrIp/tHRUbVanZOTM3369JSUlN7e3sbGRpPJ5PV6Q6HQ0NAQLitL0QahJYsHTgmBQCCVSnU6XUJCQnx8/PTp0zMyMmJi
Yux2+4EDBzZt2tTZ2YmUgc/ng4kmBXeqkjjsoVgsViqVSUlJCHCgzoeGhqxWK0ovdM8gq+Rjj23igVuLfcCbqREfb8b54l/lcnlK
SkpycnJhYWFxcbFarT58+LDRaBSJRIODg3Pnzr3++uvr6uo++eSTYDBYXl7+97//ncPhoDHY6/V6vV7Uh/GiJ8VD9fT0hEKhq666
6tlnnz1y5MiBAweysrKys7PhbTocjt7eXrgAdF5w6xQKRUJCQkJCwuLFix0OB4fDmTFjxnvvvYfHgRrCa3R0tKSk5Oqrr0aa5tix
Y42NjUNDQ7hd8CxoYbQt0INg8IINZ50X8j7kcrlCodBqtXq9/uKLL87PzxcKhR6P5/Dhw7t37x4aGkpISEhMTIyKikIDVmxsLEk7
ZIH8yoi6938F4eNI7+joqE6nu+eee+CN7N69u7CwcPny5U899VRjY2N6enphYaFer4+NjVWr1QqFQqlUyuVyuCJ6vT4+Pl4qleJC
4BLz+fyurq5//OMfLpdLLBYfOnTIaDSOjo5CEoj36KTRxViRhtszZcqU3Nxch8MhlUrnzZtnMplsNltvb6/b7UYTDAIq/Ax5Btwn
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
]=]

local env = (getgenv and getgenv()) or _G
-- every edited image is kept alive here so the recolours keep working after the script is closed
local KEEP = env.VoidscopeKeep or {}
env.VoidscopeKeep = KEEP
if env.VoidscopeRecolorCleanup then
	pcall(env.VoidscopeRecolorCleanup)
end

-- turns a SKIN_TEXTURES value into something a texture can use (or nil if that skin is empty / unusable)
local skinCache = {}
-- SurfaceAppearance needs an IMAGE id. If you gave a DECAL id, this asks the game for the decal and uses the image inside it
local function decalToImage(id)
	local ok, tex = pcall(function()
		local objs = game:GetObjects("rbxassetid://" .. id)
		local o = objs and objs[1]
		if o and (o:IsA("Decal") or o:IsA("Texture")) then return o.Texture end
		return nil
	end)
	if ok and type(tex) == "string" and tex ~= "" then return tex end
	return nil
end
local function resolveSkin(key)
	if not key then return nil end
	local cached = skinCache[key]
	if cached ~= nil then return cached or nil end
	local result = false
	local raw = SKIN_TEXTURES[key]
	do -- a file called gold.png / pink.png / ... in the executor's workspace folder always wins (works in any game)
		local toAssetLocal = getcustomasset or getsynasset
		if toAssetLocal and isfile then
			for _, fname in ipairs({ key .. ".png", "VSSkin_" .. key .. ".png" }) do
				local okf, exists = pcall(isfile, fname)
				if okf and exists then
					local oka, asset = pcall(function() return toAssetLocal(fname) end)
					if oka and type(asset) == "string" and asset ~= "" then
						skinCache[key] = asset
						return asset
					end
				end
			end
		end
	end
	if type(raw) == "string" then
		raw = (string.gsub(raw, "^%s+", ""))
		raw = (string.gsub(raw, "%s+$", ""))
		local toAsset = getcustomasset or getsynasset
		if raw == "" then
			result = false
		elseif string.find(raw, "^%d+$") then
			result = decalToImage(raw) or ("rbxassetid://" .. raw)
		elseif string.find(raw, "^rbxassetid://") or string.find(raw, "^rbxasset://") then
			result = raw
		elseif string.find(raw, "^https?://") then
			if writefile and toAsset then
				local ok, asset = pcall(function()
					local name = "VSSkin_" .. key .. ".png"
					writefile(name, game:HttpGet(raw))
					return toAsset(name)
				end)
				if ok and type(asset) == "string" and asset ~= "" then
					result = asset
				else
					warn("[Voidscope Recolor] couldn't download the '" .. key .. "' skin, using the built-in look instead")
				end
			else
				warn("[Voidscope Recolor] this executor can't download skins (needs writefile + getcustomasset)")
			end
		else
			if toAsset and isfile and isfile(raw) then
				local ok, asset = pcall(function() return toAsset(raw) end)
				if ok and type(asset) == "string" and asset ~= "" then result = asset end
			else
				warn("[Voidscope Recolor] skin file '" .. raw .. "' not found, using the built-in look instead")
			end
		end
	end
	skinCache[key] = result
	return result or nil
end

local function skinOf(entry)
	if entry and entry.skin then return resolveSkin(entry.skin) end
	return nil
end

local selected = nil -- current entry from COLORS, or nil for default
local shotUntil = 0
local shotCount = 0
local conns = {}
local originals = setmetatable({}, { __mode = "k" }) -- inst -> { prop = originalValue }
local hooked = setmetatable({}, { __mode = "k" })    -- tools we've hooked
local guarded = setmetatable({}, { __mode = "k" })   -- effects / sounds we already listen to
local texWatched = setmetatable({}, { __mode = "k" })
local applied = setmetatable({}, { __mode = "k" })    -- meshPart -> edited texture image it is showing right now
local surfaces = setmetatable({}, { __mode = "k" })  -- meshPart -> the SurfaceAppearance currently showing
local saCache = setmetatable({}, { __mode = "k" })   -- meshPart -> { tint = SA, rainbow = SA, skin_gold = SA, ... } (one per style, swapped by re-parenting)
local imgOf = setmetatable({}, { __mode = "k" })     -- SurfaceAppearance -> the edited image / picture it was built from
local ours = setmetatable({}, { __mode = "k" })      -- SurfaceAppearances made by this run of the script
local overlays = setmetatable({}, { __mode = "k" })  -- meshPart -> Highlight we added (colour wash)
local watchedTargets = setmetatable({}, { __mode = "k" })
local rainbowT = setmetatable({}, { __mode = "k" })       -- part -> 0..1, where it sits along the gun
local glassed = setmetatable({}, { __mode = "k" })       -- parts currently showing our glass look
local glassGuarded = setmetatable({}, { __mode = "k" })  -- parts we already watch for the game making them solid again
local glassOverlay = false  -- the "See-through" switch
local trailOn = false       -- the "Trail" switch
local trails = setmetatable({}, { __mode = "k" })        -- tool -> { trail, a0, a1 }
local unglassing = false
local chromed = setmetatable({}, { __mode = "k" })       -- meshes currently showing the chrome look
local flatSpread = setmetatable({}, { __mode = "k" })    -- parts of a gun that is a single piece
local sheens = setmetatable({}, { __mode = "k" })        -- gun part -> the two glow lights we added to it
local lastSpin = 0
local hipQueued = false

local gui, gunLabel, hipLabel, statusLabel, noteLabel
local glassToggleBtn, glassToggleBg, trailToggleBtn, trailToggleBg
local buttons = {}

local function connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(conns, c)
	return c
end

local function setNote(text)
	if noteLabel then noteLabel.Text = text or "" end
end
local function setGunStatus(text)
	if gunLabel then gunLabel.Text = text end
end
local function setHipStatus(text)
	if hipLabel then hipLabel.Text = text end
end

local function set(inst, prop, value)
	local saved = originals[inst]
	if not saved then
		saved = {}
		originals[inst] = saved
	end
	if saved[prop] == nil then
		local ok, v = pcall(function() return inst[prop] end)
		if ok then saved[prop] = v end
	end
	return (pcall(function() inst[prop] = value end))
end

local function colorsClose(a, b)
	return math.abs(a.R - b.R) < 0.01 and math.abs(a.G - b.G) < 0.01 and math.abs(a.B - b.B) < 0.01
end

local function seqIsColor(seq, color)
	for _, kp in ipairs(seq.Keypoints) do
		if not colorsClose(kp.Value, color) then return false end
	end
	return true
end

local function isEffect(inst)
	return inst:IsA("Beam") or inst:IsA("Trail") or inst:IsA("ParticleEmitter")
end

-- the shiny looks (Glass) use the chrome path
local function isChrome()
	return selected ~= nil and (selected.mode == "pearl" or selected.mode == "metal" or selected.mode == "diamond")
end

local function glassT()
	return (selected and selected.glassT) or GLASS_TRANSPARENCY
end

local function partsUnder(root)
	local list = {}
	if root:IsA("BasePart") then table.insert(list, root) end
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then table.insert(list, d) end
	end
	return list
end

local function mapRainbow(parts)
	if not (selected and (selected.mode == "rainbow" or isChrome()
		or (selected.mode == "texture" and selected.texStyle == "rainbow"))) then return end
	local seen = {}
	for _, p in ipairs(parts) do
		if p.Transparency < 1 then table.insert(seen, p) end
	end
	if #seen == 0 then return end
	local ref = seen[1]
	for _, p in ipairs(seen) do
		if p.Size.Magnitude > ref.Size.Magnitude then ref = p end
	end
	local pts = {}
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = Vector3.new(-math.huge, -math.huge, -math.huge)
	for i, p in ipairs(seen) do
		local v = ref.CFrame:PointToObjectSpace(p.Position)
		pts[i] = v
		lo = Vector3.new(math.min(lo.X, v.X), math.min(lo.Y, v.Y), math.min(lo.Z, v.Z))
		hi = Vector3.new(math.max(hi.X, v.X), math.max(hi.Y, v.Y), math.max(hi.Z, v.Z))
	end
	local ext = hi - lo
	local axis = "X"
	if ext.Y > ext[axis] then axis = "Y" end
	if ext.Z > ext[axis] then axis = "Z" end
	local range = ext[axis]
	for i, p in ipairs(seen) do
		if range > 0.05 then
			rainbowT[p] = (pts[i][axis] - lo[axis]) / range
			flatSpread[p] = nil
		else
			rainbowT[p] = 0.5
			flatSpread[p] = true
		end
	end
	return ref
end

local function colorFor(inst)
	local mode = selected and selected.mode
	if mode == "rainbow" or (mode == "texture" and selected.texStyle == "rainbow") then
		local t = rainbowT[inst] or ((os.clock() * 0.6) % 1)
		return Color3.fromHSV((0.65 - t * 0.9 + os.clock() * RAINBOW_SPIN) % 1, 0.9, 1)
	elseif mode == "pearl" then
		local t = rainbowT[inst]
		if not t or flatSpread[inst] then return Color3.fromRGB(238, 238, 244) end
		return Color3.fromHSV(0.5 + t * 0.42, 0.16, 0.95)
	elseif mode == "metal" then
		local t = rainbowT[inst]
		if not t or flatSpread[inst] then return selected.color end
		local w = 0.5 + 0.5 * math.sin(t * math.pi * 5)
		return Color3.fromRGB(math.floor(190 + 65 * w), math.floor(130 + 85 * w), math.floor(15 + 75 * w))
	elseif mode == "diamond" then
		local t = rainbowT[inst]
		if not t or flatSpread[inst] then return selected.color end
		local w = 0.5 + 0.5 * math.sin(t * math.pi * 4)
		return Color3.fromHSV(0.47 + 0.1 * w, 0.22 + 0.2 * (1 - w), 1)
	end
	return selected and selected.color or Color3.new(1, 1, 1)
end

connect(RunService.Heartbeat, function()
	if RAINBOW_SPIN == 0 or not (selected and selected.mode == "rainbow") then return end
	local now = os.clock()
	if now - lastSpin < 0.08 then return end
	lastSpin = now
	for mp in pairs(rainbowT) do
		local sa = surfaces[mp]
		if sa and sa.Parent then
			sa.Color = colorFor(mp)
		end
	end
end)

local function removeOverlay(mp)
	local hl = overlays[mp]
	if hl then
		pcall(function() hl:Destroy() end)
		overlays[mp] = nil
	end
end

local function setOverlay(mp, color, transparency)
	local hl = overlays[mp]
	if not hl or not hl.Parent then
		local existing = mp:FindFirstChild("VSOverlay")
		if existing and existing:IsA("Highlight") then
			hl = existing
			hl.Adornee = mp
		else
			hl = Instance.new("Highlight")
			hl.Name = "VSOverlay"
			hl.Adornee = mp
			hl.OutlineTransparency = 1
			hl.DepthMode = Enum.HighlightDepthMode.Occluded
			hl.Parent = mp
		end
		overlays[mp] = hl
	end
	hl.FillColor = color
	hl.FillTransparency = transparency
end

-- takes every appearance we added off the mesh (they stay cached, so showing one again is instant)
local function hideSurfaces(mp)
	local cache = saCache[mp]
	if cache then
		for _, o in pairs(cache) do
			if o.Parent then o.Parent = nil end
		end
	end
	surfaces[mp] = nil
	applied[mp] = nil
end

-- appearances left on a mesh by an earlier run of the script (the effect stays after closing) get cleared away
-- so the new run's look is the one that shows
local purged = setmetatable({}, { __mode = "k" })
local function purgeStray(mp)
	if purged[mp] then return end
	purged[mp] = true
	for _, c in ipairs(mp:GetChildren()) do
		if c.Name == "VSSurface" and c:IsA("SurfaceAppearance") and not ours[c] then
			pcall(function() c:Destroy() end)
		end
	end
end

-- plain colour tint (Red, Green, Chroma...). Uses its own appearance, never mixed with the edited-image ones
local function setSurfaceTint(mp, color)
	local tex
	pcall(function() tex = mp.TextureID end)
	if type(tex) ~= "string" or tex == "" then
		return "notex"
	end
	local cache = saCache[mp]
	if not cache then
		cache = {}
		saCache[mp] = cache
	end
	local sa = cache.tint
	if not sa then
		sa = Instance.new("SurfaceAppearance")
		sa.Name = "VSSurface"
		if not pcall(function() sa.ColorMap = tex end) then
			pcall(function() sa:Destroy() end)
			return "fail"
		end
		ours[sa] = true
		cache.tint = sa
	end
	if not pcall(function() sa.Color = color end) then
		pcall(function() sa:Destroy() end)
		cache.tint = nil
		return "fail"
	end
	sa.Parent = mp
	for _, o in pairs(cache) do
		if o ~= sa and o.Parent then o.Parent = nil end
	end
	surfaces[mp] = sa
	return "ok"
end

local function removeSurface(mp)
	applied[mp] = nil
	local cache = saCache[mp]
	if cache then
		for _, o in pairs(cache) do
			pcall(function() o:Destroy() end)
		end
		saCache[mp] = nil
	end
	surfaces[mp] = nil
	for _, c in ipairs(mp:GetChildren()) do
		if c.Name == "VSSurface" then pcall(function() c:Destroy() end) end
	end
end

local function chromeMesh(mp, color)
	removeOverlay(mp)
	removeSurface(mp)
	set(mp, "TextureID", "")
	set(mp, "Material", glassed[mp] and Enum.Material.Glass or Enum.Material.Metal)
	set(mp, "Reflectance", (selected and selected.reflectance) or CHROME_REFLECTANCE)
	set(mp, "Color", color)
	chromed[mp] = true
end

local function unchromeMesh(mp)
	if not chromed[mp] then return end
	chromed[mp] = nil
	local saved = originals[mp]
	if saved then
		pcall(function()
			if saved.Material ~= nil then mp.Material = saved.Material end
			if saved.Reflectance ~= nil then mp.Reflectance = saved.Reflectance end
			if saved.TextureID ~= nil then mp.TextureID = saved.TextureID end
		end)
		saved.Material = nil
		saved.Reflectance = nil
		saved.TextureID = nil
	end
end

local function removeSheen(part)
	local made = sheens[part]
	if made then
		for _, o in ipairs(made) do
			pcall(function() o:Destroy() end)
		end
		sheens[part] = nil
	end
end

local function addSheen(part)
	if SHEEN_BRIGHTNESS <= 0 then return end
	local existing = sheens[part]
	if existing and existing[1] and existing[1].Parent then return end
	removeSheen(part)
	local axes = { { "X", part.Size.X }, { "Y", part.Size.Y }, { "Z", part.Size.Z } }
	table.sort(axes, function(a, b) return a[2] > b[2] end)
	local function along(name, v)
		return Vector3.new(name == "X" and v or 0, name == "Y" and v or 0, name == "Z" and v or 0)
	end
	local offset = along(axes[2][1], axes[2][2] / 2 + 0.8) + along(axes[3][1], axes[3][2] / 2 + 0.8)
	local made = {}
	local cA = (selected and selected.sheenA) or SHEEN_PINK
	local cB = (selected and selected.sheenB) or SHEEN_TEAL
	local specs = { { cA, offset }, { cB, -offset } }
	for _, spec in ipairs(specs) do
		local att = Instance.new("Attachment")
		att.Name = "VSSheen"
		att.Position = spec[2]
		att.Parent = part
		local light = Instance.new("PointLight")
		light.Name = "VSSheen"
		light.Color = spec[1]
		light.Range = 7
		light.Brightness = SHEEN_BRIGHTNESS
		light.Shadows = false
		light.Parent = att
		table.insert(made, att)
	end
	sheens[part] = made
end

local function wantsSheen()
	return isChrome() and selected.sheen ~= false
end

local AssetService = game:GetService("AssetService")
local pinkCache = {}                     -- "style|texture id" -> { state, image, waiters }
local TEX_STYLES = {}
-- (Luau allows only 200 local variables per scope, so the texture-style helpers live in their own block)
do
-- Rainbow texture settings (matched to the reference photo: near-black body, vivid bright parts)
local RB_BRIGHTNESS = 1.0
local RB_X_WEIGHT = 0.6
local RB_Y_WEIGHT = 0.4
local RB_REVERSE = false
local RB_BODY_TINT = 0.15
local RB_BODY_COLOR = { 40, 5, 60 }
local RB_STOPS = {
	{ 255, 40, 200 }, { 140, 40, 255 }, { 30, 110, 255 }, { 0, 230, 240 }, { 60, 235, 70 },
	{ 255, 235, 20 }, { 255, 120, 10 }, { 255, 40, 120 }, { 255, 40, 200 },
}

local GR, GG, GB = {}, {}, {}
for k = 1, 256 do
	local s = (k - 1) / 255
	if RB_REVERSE then s = 1 - s end
	local pos = s * (#RB_STOPS - 1)
	local i = math.min(math.floor(pos) + 1, #RB_STOPS - 1)
	local f = pos - (i - 1)
	local c0, c1 = RB_STOPS[i], RB_STOPS[i + 1]
	GR[k] = c0[1] + (c1[1] - c0[1]) * f
	GG[k] = c0[2] + (c1[2] - c0[2]) * f
	GB[k] = c0[3] + (c1[3] - c0[3]) * f
end

-- each style gets the texture's stats and gives back a function that turns one pixel
-- (brightness 0-1, position u/v 0-1 across the texture) into r, g, b (0-255)
TEX_STYLES.rainbow = (
	function(stats)
		local lo, hi = stats.q(0.05), stats.q(0.95)
		local span = math.max(hi - lo, 0.05)
		local sw = RB_X_WEIGHT + RB_Y_WEIGHT
		local xw, yw = RB_X_WEIGHT / sw, RB_Y_WEIGHT / sw
		local bc1, bc2, bc3 = RB_BODY_COLOR[1], RB_BODY_COLOR[2], RB_BODY_COLOR[3]
		return function(lum, u, v)
			local rel = (lum - lo) / span
			if rel < 0 then rel = 0 elseif rel > 1 then rel = 1 end
			local s = u * xw + v * yw
			if s < 0 then s = 0 elseif s > 1 then s = 1 end
			local k = math.floor(s * 255) + 1
			local r, g, b = GR[k], GG[k], GB[k]
			local d = (0.35 - rel) / 0.35
			if d > 0 then
				d = d * RB_BODY_TINT
				r, g, b = r + (bc1 - r) * d, g + (bc2 - g) * d, b + (bc3 - b) * d
			end
			local shade = (0.1 + 0.9 * rel) * RB_BRIGHTNESS
			r, g, b = r * shade, g * shade, b * shade
			local w = (rel - 0.88) / 0.12
			if w > 0 then
				if w > 1 then w = 1 end
				w = w * 0.55
				r, g, b = r + (215 - r) * w, g + (215 - g) * w, b + (215 - b) * w
			end
			return r, g, b
		end
	end
)

local function buildRamp(stops)
	local R, G, B = {}, {}, {}
	for k = 1, 256 do
		local pos = ((k - 1) / 255) * (#stops - 1)
		local i = math.min(math.floor(pos) + 1, #stops - 1)
		local f = pos - (i - 1)
		local a, b = stops[i], stops[i + 1]
		R[k] = a[1] + (b[1] - a[1]) * f
		G[k] = a[2] + (b[2] - a[2]) * f
		B[k] = a[3] + (b[3] - a[3]) * f
	end
	return R, G, B
end

local GOLD_R, GOLD_G, GOLD_B = buildRamp({
	{ 90, 40, 0 }, { 170, 80, 5 }, { 225, 130, 10 }, { 255, 175, 25 }, { 255, 215, 80 }, { 255, 245, 170 },
})
-- DIAMOND: steel-blue shadows -> icy blue -> white
local DIA_R, DIA_G, DIA_B = buildRamp({
	{ 40, 65, 110 }, { 80, 115, 165 }, { 125, 160, 200 }, { 180, 208, 232 }, { 228, 241, 252 }, { 255, 255, 255 },
})
-- RUBY: near-black maroon -> deep red -> bright red -> pink highlight
local RUBY_R, RUBY_G, RUBY_B = buildRamp({
	{ 20, 0, 4 }, { 85, 2, 16 }, { 150, 8, 30 }, { 205, 22, 44 }, { 245, 60, 75 }, { 255, 150, 158 },
})
-- BEAST: near-black violet -> purple -> blue -> cyan -> white
local BEAST_R, BEAST_G, BEAST_B = buildRamp({
	{ 14, 0, 30 }, { 60, 8, 110 }, { 120, 40, 210 }, { 60, 110, 255 }, { 0, 210, 255 }, { 255, 255, 255 },
})
-- PINK: dark parts of the gun = pastel pink, the gun's detail / bright parts fade up to pure white
local PINK_R, PINK_G, PINK_B = buildRamp({
	{ 244, 160, 196 }, { 255, 184, 212 }, { 255, 208, 228 }, { 255, 235, 244 }, { 255, 255, 255 },
})
-- WHITE: the gun's body = pale white, the gun's detail / bright parts go down to black
local WHITE_R, WHITE_G, WHITE_B = buildRamp({
	{ 238, 238, 244 }, { 236, 236, 242 }, { 226, 226, 232 }, { 150, 150, 158 }, { 45, 45, 50 }, { 6, 6, 8 },
})

-- soft marble swirl 0..1, shared by gold / diamond / ruby
local function marble(u, v, scale)
	local sin = math.sin
	return 0.5 + 0.25 * sin(u * 34 * scale + sin(v * 21 * scale) * 2.2)
		+ 0.25 * sin(v * 38 * scale + sin(u * 17 * scale) * 2.2)
end

local function makeMarbleStyle(R, G, B, strength, glintLevel)
	return function(stats)
		local lo, hi = stats.q(0.05), stats.q(0.95)
		local span = math.max(hi - lo, 0.05)
		local sin, floor = math.sin, math.floor
		return function(lum, u, v)
			local rel = (lum - lo) / span
			if rel < 0 then rel = 0 elseif rel > 1 then rel = 1 end
			local t = rel * 0.7 + (marble(u, v, 1) - 0.5) * strength + 0.12
			if t < 0 then t = 0 elseif t > 1 then t = 1 end
			local k = floor(t * 255) + 1
			local r, g, b = R[k], G[k], B[k]
			if glintLevel then
				local h = sin(floor(u * 110) * 12.9898 + floor(v * 110) * 78.233) * 43758.5453
				h = h - floor(h)
				if h > glintLevel then
					local w = (h - glintLevel) / (1 - glintLevel)
					r, g, b = r + (255 - r) * w, g + (255 - g) * w, b + (255 - b) * w
				end
			end
			return r, g, b
		end
	end
end

TEX_STYLES.gold = makeMarbleStyle(GOLD_R, GOLD_G, GOLD_B, 0.45, 0.992)
-- gem look: soft blotches + thin veins from the noise fields, the gun's own detail on top,
-- soft highlights on bright detail and tiny sparkles
local function makeGemStyle(R, G, B, o)
	return function(stats)
		local lo, hi = stats.q(0.05), stats.q(0.95)
		local span = math.max(hi - lo, 0.05)
		local floor = math.floor
		local hl = o.hl
		return function(lum, u, v, a, vn, gr)
			local rel = (lum - lo) / span
			if rel < 0 then rel = 0 elseif rel > 1 then rel = 1 end
			local t = o.bias + o.lumW * rel + o.aW * a + o.vW * vn
			t = (t - 0.5) * o.contrast + 0.5
			if t < 0 then t = 0 elseif t > 1 then t = 1 end
			local k = floor(t * 255) + 1
			local r, g, b = R[k], G[k], B[k]
			local s = (rel - 0.8) / 0.2
			if s > 0 then
				s = s * o.spec
				r, g, b = r + (hl[1] - r) * s, g + (hl[2] - g) * s, b + (hl[3] - b) * s
			end
			local w = (gr - o.glintAt) / (1 - o.glintAt)
			if w > 0 then
				w = w * o.glint
				r, g, b = r + (hl[1] - r) * w, g + (hl[2] - g) * w, b + (hl[3] - b) * w
			end
			return r, g, b
		end
	end
end

TEX_STYLES.diamond = makeGemStyle(DIA_R, DIA_G, DIA_B, {
	bias = 0.1, lumW = 0.15, aW = 0.7, vW = 0.35, contrast = 1.6,
	spec = 0.35, hl = { 255, 255, 255 }, glintAt = 0.93, glint = 0.85,
})
TEX_STYLES.ruby = makeGemStyle(RUBY_R, RUBY_G, RUBY_B, {
	bias = -0.02, lumW = 0.22, aW = 0.6, vW = 0.55, contrast = 1.8,
	spec = 0.45, hl = { 255, 175, 185 }, glintAt = 0.94, glint = 0.7,
})
TEX_STYLES.beast = makeGemStyle(BEAST_R, BEAST_G, BEAST_B, {
	bias = 0.0, lumW = 0.25, aW = 0.6, vW = 0.5, contrast = 1.7,
	spec = 0.4, hl = { 230, 200, 255 }, glintAt = 0.94, glint = 0.7,
})

TEX_STYLES.pink = function(stats)
	local lo, hi = stats.q(0.05), stats.q(0.95)
	local span = math.max(hi - lo, 0.05)
	local floor = math.floor
	return function(lum)
		local rel = (lum - lo) / span
		if rel < 0 then rel = 0 elseif rel > 1 then rel = 1 end
		-- slight curve so the gun's detail pops out white instead of everything going pale
		local t = rel * rel * 0.55 + rel * 0.45
		local k = floor(t * 255) + 1
		return PINK_R[k], PINK_G[k], PINK_B[k]
	end
end

-- WHITE: pale white body, the gun's detail (the bright parts of its texture) painted black
TEX_STYLES.white = function(stats)
	local lo, hi = stats.q(0.05), stats.q(0.95)
	local span = math.max(hi - lo, 0.05)
	local floor = math.floor
	return function(lum)
		local rel = (lum - lo) / span
		if rel < 0 then rel = 0 elseif rel > 1 then rel = 1 end
		if WHITE_INVERT then rel = 1 - rel end
		-- curve keeps the body pale and only lets real detail drop to black
		local t = rel ^ 2.5
		local k = floor(t * 255) + 1
		return WHITE_R[k], WHITE_G[k], WHITE_B[k]
	end
end
end -- end of texture-style block

-- built-in looks that are prepared in the background (a style is skipped when its skin picture is filled in)
local PREBUILD_STYLES = { "rainbow", "gold", "diamond", "ruby", "pink", "white", "beast" }
local SKIN_OF_STYLE = { gold = "gold", diamond = "diamond", ruby = "ruby", beast = "beast" }

local function percentileOf(hist, total, p)
	if total == 0 then return p end
	local target, run = p * total, 0
	for k = 0, 255 do
		run += hist[k]
		if run >= target then return k / 255 end
	end
	return 1
end

local sources = {} -- texture id -> { w, h, buf, lum, hist, seen, nA, nV, nG }

-- smooth value noise (tileable), used to make the Diamond / Ruby / Beast marbling
local NOISE_N = 64
local lattice = {}
do
	local seed = 1234567
	for i = 1, NOISE_N * NOISE_N do
		seed = (seed * 16807) % 2147483647
		lattice[i] = seed / 2147483647
	end
end
local function vnoise(x, y)
	local floor = math.floor
	local ix, iy = floor(x), floor(y)
	local fx, fy = x - ix, y - iy
	fx = fx * fx * (3 - 2 * fx)
	fy = fy * fy * (3 - 2 * fy)
	local x0, y0 = ix % NOISE_N, iy % NOISE_N
	local x1, y1 = (x0 + 1) % NOISE_N, (y0 + 1) % NOISE_N
	local a = lattice[x0 + y0 * NOISE_N + 1]
	local b = lattice[x1 + y0 * NOISE_N + 1]
	local c = lattice[x0 + y1 * NOISE_N + 1]
	local d = lattice[x1 + y1 * NOISE_N + 1]
	local top = a + (b - a) * fx
	local bot = c + (d - c) * fx
	return top + (bot - top) * fy
end

local function makeBreather(budgetFn)
	local mark = os.clock()
	return function()
		if os.clock() - mark > budgetFn() then
			task.wait()
			mark = os.clock()
		end
	end
end

-- Step 1 (once per texture, shared by every style): load it, shrink it, work out every pixel's brightness
local function loadSource(tex, budgetFn)
	local ei
	local okLoad, errLoad = pcall(function()
		ei = AssetService:CreateEditableImageAsync(Content.fromUri(tex))
	end)
	if not (okLoad and ei) then return nil, "couldn't load the texture (" .. tostring(errLoad) .. ")" end
	local src
	local okRead, errRead = pcall(function()
		local size = ei.Size
		local sw, sh = size.X, size.Y
		local step = math.max(math.ceil(math.max(sw, sh) / MAX_TEX), 1)
		local w, h = math.max(math.floor(sw / step), 1), math.max(math.floor(sh / step), 1)
		local raw = ei:ReadPixelsBuffer(Vector2.zero, size)
		local readu8, writeu8 = buffer.readu8, buffer.writeu8
		local readu32, writeu32 = buffer.readu32, buffer.writeu32
		local breathe = makeBreather(budgetFn)
		local buf = raw
		if step > 1 then
			buf = buffer.create(w * h * 4)
			for y = 0, h - 1 do
				local srow, drow = y * step * sw, y * w
				for x = 0, w - 1 do
					writeu32(buf, (drow + x) * 4, readu32(raw, (srow + x * step) * 4))
				end
				breathe()
			end
		end
		local lumBuf = buffer.create(w * h)
		local hist, seen = {}, 0
		for k = 0, 255 do hist[k] = 0 end
		for y = 0, h - 1 do
			local row = y * w
			for x = 0, w - 1 do
				local i = row + x
				local o = i * 4
				local l = math.floor(0.299 * readu8(buf, o) + 0.587 * readu8(buf, o + 1) + 0.114 * readu8(buf, o + 2) + 0.5)
				writeu8(lumBuf, i, l)
				if readu8(buf, o + 3) > 10 then
					hist[l] += 1
					seen += 1
				end
			end
			breathe()
		end
		-- marble fields, worked out once per texture and shared by Diamond / Ruby / Beast
		-- nA = soft blotches, nV = thin bright veins / cracks, nG = fine grain for sparkles
		local nA, nV, nG = buffer.create(w * h), buffer.create(w * h), buffer.create(w * h)
		local S = MARBLE_SCALE
		local mfloor, mabs, mmax = math.floor, math.abs, math.max
		for y = 0, h - 1 do
			local v = y / h
			local row = y * w
			for x = 0, w - 1 do
				local u = x / w
				local a = 0.5 * vnoise(u * 5 * S, v * 5 * S) + 0.3 * vnoise(u * 11 * S, v * 11 * S) + 0.2 * vnoise(u * 23 * S, v * 23 * S)
				local wx = vnoise(u * 7 * S + 3.1, v * 7 * S + 1.7)
				local r1 = vnoise(u * 9 * S + wx * 1.8, v * 9 * S + a * 1.8)
				r1 = 1 - mabs(2 * r1 - 1)
				r1 = r1 * r1
				r1 = r1 * r1
				local r2 = vnoise(u * 20 * S + a * 2.2, v * 20 * S + wx * 2.2)
				r2 = 1 - mabs(2 * r2 - 1)
				r2 = r2 * r2
				r2 = r2 * r2
				r2 = r2 * r2
				local vein = mmax(r1, r2 * 0.8)
				local grain = vnoise(u * 110 * S, v * 110 * S)
				local i = row + x
				writeu8(nA, i, mfloor(math.clamp(a, 0, 1) * 255 + 0.5))
				writeu8(nV, i, mfloor(math.clamp(vein, 0, 1) * 255 + 0.5))
				writeu8(nG, i, mfloor(math.clamp(grain, 0, 1) * 255 + 0.5))
			end
			breathe()
		end
		src = { w = w, h = h, buf = buf, lum = lumBuf, hist = hist, seen = seen, nA = nA, nV = nV, nG = nG }
	end)
	pcall(function() ei:Destroy() end)
	if not okRead then return nil, "couldn't read the texture (" .. tostring(errRead) .. ")" end
	return src
end

-- Step 2 (per style): repaint a copy of the pixels and put them in a fresh small image
local function paintSource(src, makePixel, budgetFn)
	local image
	local ok, err = pcall(function()
		local w, h = src.w, src.h
		local readu8, writeu8 = buffer.readu8, buffer.writeu8
		local breathe = makeBreather(budgetFn)
		local hist, seen = src.hist, src.seen
		local qCache = {}
		local stats = {
			q = function(p)
				local cached = qCache[p]
				if cached then return cached end
				cached = percentileOf(hist, seen, p)
				qCache[p] = cached
				return cached
			end,
		}
		local out = buffer.create(w * h * 4)
		buffer.copy(out, 0, src.buf, 0, w * h * 4) -- keeps the see-through (alpha) values
		local lumBuf = src.lum
		local nA, nV, nG = src.nA, src.nV, src.nG
		local pixel = makePixel(stats)
		for y = 0, h - 1 do
			local row = y * w
			local v = y / h
			for x = 0, w - 1 do
				local i = row + x
				local o = i * 4
				local nr, ng, nb = pixel(readu8(lumBuf, i) / 255, x / w, v,
					readu8(nA, i) / 255, readu8(nV, i) / 255, readu8(nG, i) / 255)
				writeu8(out, o, nr < 0 and 0 or (nr > 255 and 255 or math.floor(nr)))
				writeu8(out, o + 1, ng < 0 and 0 or (ng > 255 and 255 or math.floor(ng)))
				writeu8(out, o + 2, nb < 0 and 0 or (nb > 255 and 255 or math.floor(nb)))
			end
			breathe()
		end
		local img = AssetService:CreateEditableImage({ Size = Vector2.new(w, h) })
		img:WritePixelsBuffer(Vector2.zero, Vector2.new(w, h), out)
		table.insert(KEEP, img) -- keeps the image alive so the recolour stays after the script is closed
		image = img
	end)
	if not ok then return nil, "couldn't edit the texture (" .. tostring(err) .. ")" end
	return image
end

-- puts the edited image on the mesh. Returns true if it is showing.
-- Every style gets its OWN SurfaceAppearance on the mesh. Switching styles just swaps which one is
-- parented, so no image is ever re-assigned on a live appearance (that was the cause of the flat colour).
local function applyEdited(mp, image, style)
	local cache = saCache[mp]
	if not cache then
		cache = {}
		saCache[mp] = cache
	end
	local sa = cache[style]
	if sa and imgOf[sa] ~= image then -- the image was rebuilt, so this appearance is out of date
		pcall(function() sa:Destroy() end)
		cache[style] = nil
		sa = nil
	end
	if sa and surfaces[mp] == sa and sa.Parent == mp then
		applied[mp] = image
		return true
	end
	if not sa then
		sa = Instance.new("SurfaceAppearance")
		sa.Name = "VSSurface"
		local ok = pcall(function()
			sa.ColorMapContent = Content.fromObject(image)
			sa.Color = Color3.new(1, 1, 1)
		end)
		if not ok then
			pcall(function() sa:Destroy() end)
			return false
		end
		ours[sa] = true
		cache[style] = sa
		imgOf[sa] = image
	end
	sa.Parent = mp -- show the new one first, then hide the others, so there is never a gap
	for _, o in pairs(cache) do
		if o ~= sa and o.Parent then o.Parent = nil end
	end
	surfaces[mp] = sa
	applied[mp] = image
	return true
end

-- SKIN LOADER: every skin picture is downloaded into memory ONCE (at startup), and its gun appearance is made
-- ahead of time on every gun part. Clicking a skin then only swaps an already-made appearance in, so there is
-- no loading and no flat colour. If you click before a picture has finished downloading, the gun keeps its
-- current look and swaps the moment it is ready.
local SkinKit = { img = {}, loading = {}, waiting = {}, onReady = nil }

-- downloads a skin picture into memory once, so showing it later is instant
function SkinKit.load(key)
	if SkinKit.img[key] ~= nil or SkinKit.loading[key] then return end
	SkinKit.loading[key] = true
	task.spawn(function()
		local content = resolveSkin(key)
		local ei = false
		if content then
			local ok, res = pcall(function()
				return AssetService:CreateEditableImageAsync(Content.fromUri(content))
			end)
			if ok and res then
				ei = res
				table.insert(KEEP, res)
			end
		end
		SkinKit.img[key] = ei -- false = couldn't be held in memory, falls back to the normal picture link
		SkinKit.loading[key] = nil
		if SkinKit.onReady then pcall(SkinKit.onReady, key) end
	end)
end

-- puts the picture into a SurfaceAppearance, returns what it used (or nil)
function SkinKit.fill(sa, key)
	local src = SkinKit.img[key]
	local content = resolveSkin(key)
	if src then
		if not pcall(function() sa.ColorMapContent = Content.fromObject(src) end) then return nil end
		pcall(function() sa.Color = Color3.new(1, 1, 1) end)
		return src
	elseif content then
		if not pcall(function() sa.ColorMap = content end) then return nil end
		pcall(function() sa.Color = Color3.new(1, 1, 1) end)
		return content
	end
	return nil
end

-- makes (but does not show) the skin's appearance for one gun part
function SkinKit.make(mp, key)
	if SkinKit.img[key] == nil then return nil end -- still downloading
	local cache = saCache[mp]
	if not cache then
		cache = {}
		saCache[mp] = cache
	end
	local name = "skin_" .. key
	local sa = cache[name]
	if sa and imgOf[sa] ~= (SkinKit.img[key] or resolveSkin(key)) then
		pcall(function() sa:Destroy() end)
		cache[name] = nil
		sa = nil
	end
	if not sa then
		sa = Instance.new("SurfaceAppearance")
		sa.Name = "VSSurface"
		local token = SkinKit.fill(sa, key)
		if not token then
			pcall(function() sa:Destroy() end)
			return nil
		end
		ours[sa] = true
		cache[name] = sa
		imgOf[sa] = token
	end
	return sa, cache
end

-- shows the skin (swap only, nothing loads here)
function SkinKit.apply(mp, key)
	local sa, cache = SkinKit.make(mp, key)
	if not sa then return false end
	sa.Parent = mp -- show the new one first, then hide the others, so there is never a gap
	for _, o in pairs(cache) do
		if o ~= sa and o.Parent then o.Parent = nil end
	end
	surfaces[mp] = sa
	applied[mp] = imgOf[sa]
	return true
end

-- gets every downloaded skin ready on every part of a gun (unparented, so nothing changes on screen yet)
function SkinKit.prebuild(tool)
	for _, d in ipairs(tool:GetDescendants()) do
		if d:IsA("MeshPart") then
			local ok, tex = pcall(function() return d.TextureID end)
			if ok and type(tex) == "string" and tex ~= "" then
				for key in pairs(SKIN_TEXTURES) do
					if SkinKit.img[key] ~= nil then pcall(SkinKit.make, d, key) end
				end
			end
		end
	end
end

local tintMesh
local jobs = {}
local sourceFailed = {} -- texture id -> { at, why }: textures the game wouldn't let us read (don't retry every click)
local working = false

local function runJobs()
	if working then return end
	working = true
	task.spawn(function()
		while #jobs > 0 do
			-- a style the player is waiting on always goes first
			local pick = 1
			for i, j in ipairs(jobs) do
				if next(j.entry.waiters) then pick = i break end
			end
			local job = table.remove(jobs, pick)
			local entry = job.entry
			local function budget()
				return next(entry.waiters) and BUDGET_WAITING or BUDGET_BACKGROUND
			end
			local src, why = sources[job.tex], nil
			if not src then
				local f = sourceFailed[job.tex]
				if f and os.clock() - f.at < 30 then
					why = f.why
				else
					src, why = loadSource(job.tex, budget)
					if src then
						sources[job.tex] = src
					else
						if not f then
							warn("[Voidscope Recolor] " .. tostring(why))
						end
						sourceFailed[job.tex] = { at = os.clock(), why = why }
					end
				end
			end
			local image
			if src then image, why = paintSource(src, TEX_STYLES[job.style], budget) end
			if image then
				entry.state = "done"
				entry.image = image
			else
				entry.state = "failed"
				entry.at = os.clock()
				entry.why = tostring(why)
			end
			local waiting = entry.waiters
			entry.waiters = {}
			for w in pairs(waiting) do
				if selected and selected.mode == "texture" and typeof(w) == "Instance" and w.Parent then
					pcall(tintMesh, w, colorFor(w))
				end
			end
		end
		working = false
	end)
end

local function ensureTexture(style, tex)
	if not TEX_STYLES[style] then return nil end
	local key = style .. "|" .. tex
	local entry = pinkCache[key]
	if entry and entry.state == "failed" and os.clock() - (entry.at or 0) > 30 then
		entry = nil
	end
	if entry then return entry end
	entry = { state = "working", waiters = {} }
	pinkCache[key] = entry
	table.insert(jobs, { style = style, tex = tex, entry = entry })
	runJobs()
	return entry
end

function tintMesh(mp, color)
	if isChrome() then
		chromeMesh(mp, color)
		if not wantsSheen() then removeSheen(mp) end
		return
	end
	removeSheen(mp)
	unchromeMesh(mp)
	purgeStray(mp)

	-- a skin with its picture filled in: the picture goes straight onto the gun
	local skin = skinOf(selected)
	if skin then
		local okTex, tex = pcall(function() return mp.TextureID end)
		if not okTex or type(tex) ~= "string" or tex == "" then return end
		local key = selected.skin
		if SkinKit.img[key] == nil then
			-- still downloading: keep what is showing (never a flat colour) and swap the moment it's ready
			SkinKit.load(key)
			SkinKit.waiting[key] = SkinKit.waiting[key] or {}
			SkinKit.waiting[key][mp] = true
			setNote("Loading the " .. selected.name .. " picture...")
			return
		end
		if SkinKit.apply(mp, key) then
			removeOverlay(mp)
			setNote("")
		else
			setNote("Couldn't load the " .. selected.name .. " picture, check SKIN_TEXTURES.")
		end
		return
	end

	if selected ~= nil and selected.mode == "texture" then
		local okTex, tex = pcall(function() return mp.TextureID end)
		if not okTex or type(tex) ~= "string" or tex == "" then return end
		local style = selected.texStyle or "rainbow"
		if selected.reflectance then -- backup look: a little real metal shine on top of the painted texture
			set(mp, "Material", Enum.Material.Metal)
			set(mp, "Reflectance", selected.reflectance)
			chromed[mp] = true
		end
		local entry = ensureTexture(style, tex)
		if entry and entry.state == "done" then
			if applyEdited(mp, entry.image, style) then
				removeOverlay(mp)
				setNote("")
				return
			end
			-- the image went bad (destroyed?): throw it away and build it again
			pinkCache[style .. "|" .. tex] = nil
			entry = ensureTexture(style, tex)
		end
		removeOverlay(mp)
		if entry and entry.state == "working" then
			-- NO flat colour: keep whatever texture is showing now and swap the moment this one is ready
			entry.waiters[mp] = true
			if not applied[mp] then hideSurfaces(mp) end
			setNote("Building the " .. style .. " texture...")
		elseif entry and entry.state == "failed" then
			-- the game won't let us edit its texture: tint with the skin's colour instead, so something always shows
			applied[mp] = nil
			local c = colorFor(mp)
			local result = setSurfaceTint(mp, c)
			if result == "fail" then setOverlay(mp, c, OVERLAY_TRANSPARENCY) end
			setNote(selected.name .. ": texture edit blocked, using a colour tint. Fill in SKIN_TEXTURES for the full look.")
		end
		return
	end

	applied[mp] = nil
	local result = setSurfaceTint(mp, color)
	if result == "notex" then return end
	if result == "fail" then
		setOverlay(mp, color, OVERLAY_TRANSPARENCY)
		setNote("Texture tint isn't supported here, using a colour overlay.")
	else
		removeOverlay(mp)
	end
end

-- builds the built-in backup looks for the gun in the background, so picking a scope is instant.
-- Skins whose picture is filled in don't need this, so they are skipped.
local function prebuildTextures(tool)
	for _, d in ipairs(tool:GetDescendants()) do
		if d:IsA("MeshPart") then
			local ok, tex = pcall(function() return d.TextureID end)
			if ok and type(tex) == "string" and tex ~= "" then
				for _, style in ipairs(PREBUILD_STYLES) do
					local skinKey = SKIN_OF_STYLE[style]
					if not (skinKey and resolveSkin(skinKey)) then
						ensureTexture(style, tex)
					end
				end
			end
		end
	end
end

local function watchTexture(mp)
	if texWatched[mp] then return end
	texWatched[mp] = true
	connect(mp:GetPropertyChangedSignal("TextureID"), function()
		if selected then tintMesh(mp, colorFor(mp)) end
	end)
end

-- TRAIL
local function withAxis(vec, axis, value)
	return Vector3.new(axis == "X" and value or vec.X, axis == "Y" and value or vec.Y, axis == "Z" and value or vec.Z)
end

local trailRefs = {} -- tool / group key -> the gun part the trail is attached to
local function removeTrail(tool)
	trailRefs[tool] = nil
	local made = trails[tool]
	if made then
		for _, o in pairs(made) do
			pcall(function() o:Destroy() end)
		end
		trails[tool] = nil
	end
end

local function trailColorSeq()
	if selected == nil then return ColorSequence.new(Color3.new(1, 1, 1)) end
	if selected.mode == "rainbow" or selected.rainbowFx then return RAINBOW_SEQUENCE end
	if selected.mode == "pearl" then return ColorSequence.new(Color3.fromRGB(235, 240, 255)) end
	if selected.effectSeq then return selected.effectSeq end
	return ColorSequence.new(selected.color)
end

local function trailLook(trail)
	trail.Color = trailColorSeq()
	local black = selected ~= nil and colorsClose(selected.color, Color3.new(0, 0, 0))
	trail.LightEmission = black and 0 or 1
	pcall(function() trail.Brightness = 4 end)
end

local MUZZLE_WORDS = { "muzzle", "barrel", "tip", "flash", "firepoint", "fireattach", "nozzle", "shoot" }
local function findMuzzle(parts)
	for _, word in ipairs(MUZZLE_WORDS) do
		for _, p in ipairs(parts) do
			for _, a in ipairs(p:GetChildren()) do
				if a:IsA("Attachment") and a.Name ~= "VSTrail" and a.Name ~= "VSSheen"
					and string.find(string.lower(a.Name), word, 1, true) then
					return p, a.Position
				end
			end
		end
	end
	for _, p in ipairs(parts) do
		for _, a in ipairs(p:GetChildren()) do
			if a:IsA("Attachment") and a.Name ~= "VSTrail" and a.Name ~= "VSSheen" then
				for _, c in ipairs(a:GetChildren()) do
					if c:IsA("ParticleEmitter") or c:IsA("Light") then
						return p, a.Position
					end
				end
			end
		end
	end
	return nil
end

local function handPosition()
	local char = LocalPlayer.Character
	local hand = char and (char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm"))
	return hand and hand.Position or nil
end

local function handleGrip(parts)
	local handle, biggest
	for _, p in ipairs(parts) do
		if p.Name == "Handle" then handle = p end
		if not biggest or p.Size.Magnitude > biggest.Size.Magnitude then biggest = p end
	end
	if handle and handle ~= biggest then return handle.Position end
	return nil
end

-- the tip = the middle of the face of the gun that points furthest the way you are aiming
local function aimTip(allParts)
	local parts = {}
	for _, p in ipairs(allParts) do
		if p.Transparency < 1 then table.insert(parts, p) end
	end
	if #parts == 0 then parts = allParts end
	if #parts == 0 then return nil end
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local cam = Workspace.CurrentCamera
	local dir = (root and root.CFrame.LookVector) or (cam and cam.CFrame.LookVector) or Vector3.new(0, 0, -1)
	if TRAIL_END == "back" then dir = -dir end
	if TRAIL_FLIP then dir = -dir end
	local faces, best, lo = {}, -math.huge, math.huge
	for _, p in ipairs(parts) do
		for _, axis in ipairs({ "X", "Y", "Z" }) do
			for sign = -1, 1, 2 do
				local localPos = withAxis(Vector3.zero, axis, sign * p.Size[axis] / 2)
				local score = p.CFrame:PointToWorldSpace(localPos):Dot(dir)
				table.insert(faces, { part = p, pos = localPos, score = score })
				if score > best then best = score end
				if score < lo then lo = score end
			end
		end
	end
	-- among the faces right at the front, take the one on the biggest part (the barrel, not a little sight)
	local pick
	local window = (TRAIL_END == "back") and math.max((best - lo) * 0.015, 0.04) or math.max((best - lo) * 0.06, 0.15)
	for _, f in ipairs(faces) do
		if f.score >= best - window then
			if not pick or f.part.Size.Magnitude > pick.part.Size.Magnitude then pick = f end
		end
	end
	if not pick then return nil end
	local up = pick.part.CFrame:VectorToObjectSpace(Vector3.new(0, 1, 0))
	local side = up.Magnitude > 0.01 and up.Unit * (TRAIL_WIDTH / 2) or Vector3.new(TRAIL_WIDTH / 2, 0, 0)
	return pick.part, pick.pos, side, (TRAIL_END == "back") and "very back of the gun" or "front tip of the gun"
end

local function findTip(allParts, gripPos, useAim)
	local parts = {}
	for _, p in ipairs(allParts) do
		if p.Transparency < 1 then table.insert(parts, p) end
	end
	if #parts == 0 then parts = allParts end
	if #parts == 0 then return nil end

	local markerPart, markerPos = findMuzzle(allParts)
	if markerPart then
		return markerPart, markerPos, Vector3.new(TRAIL_WIDTH / 2, 0, 0), "the gun's muzzle point"
	end

	if useAim then
		local ap, atip, aside, ahow = aimTip(allParts)
		if ap then return ap, atip, aside, ahow end
	end

	if gripPos then
		local bestPart, bestDist = nil, -1
		for _, p in ipairs(parts) do
			local h = p.Size / 2
			for sx = -1, 1, 2 do
				for sy = -1, 1, 2 do
					for sz = -1, 1, 2 do
						local world = p.CFrame:PointToWorldSpace(Vector3.new(h.X * sx, h.Y * sy, h.Z * sz))
						local d = (world - gripPos).Magnitude
						if d > bestDist then
							bestDist = d
							bestPart = p
						end
					end
				end
			end
		end
		if bestPart then
			local p = bestPart
			local names = { "X", "Y", "Z" }
			table.sort(names, function(a, b) return p.Size[a] > p.Size[b] end)
			local axis, sideAxis = names[1], names[2]
			local dir = p.CFrame:VectorToWorldSpace(withAxis(Vector3.zero, axis, 1))
			local half = p.Size[axis] / 2
			local sign = ((p.Position + dir * half - gripPos).Magnitude >= (p.Position - dir * half - gripPos).Magnitude) and 1 or -1
			if TRAIL_FLIP then sign = -sign end
			return p, withAxis(Vector3.zero, axis, sign * half), withAxis(Vector3.zero, sideAxis, TRAIL_WIDTH / 2), "end furthest from your hand"
		end
	end

	local ref = parts[1]
	for _, p in ipairs(parts) do
		if p.Size.Magnitude > ref.Size.Magnitude then ref = p end
	end
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, p in ipairs(parts) do
		local h = p.Size / 2
		for sx = -1, 1, 2 do
			for sy = -1, 1, 2 do
				for sz = -1, 1, 2 do
					local world = p.CFrame:PointToWorldSpace(Vector3.new(h.X * sx, h.Y * sy, h.Z * sz))
					local v = ref.CFrame:PointToObjectSpace(world)
					lo = Vector3.new(math.min(lo.X, v.X), math.min(lo.Y, v.Y), math.min(lo.Z, v.Z))
					hi = Vector3.new(math.max(hi.X, v.X), math.max(hi.Y, v.Y), math.max(hi.Z, v.Z))
				end
			end
		end
	end
	local ext = hi - lo
	local names = { "X", "Y", "Z" }
	table.sort(names, function(a, b) return ext[a] > ext[b] end)
	local axis, sideAxis = names[1], names[2]
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local useHi = true
	if root then
		local dir = ref.CFrame:VectorToWorldSpace(withAxis(Vector3.zero, axis, 1))
		useHi = dir:Dot(root.CFrame.LookVector) >= 0
	end
	if TRAIL_FLIP then useHi = not useHi end
	local endVal = useHi and hi[axis] or lo[axis]
	local len = ext[axis]
	local sumV, n = Vector3.zero, 0
	for _, p in ipairs(parts) do
		local h = p.Size / 2
		local far = useHi and -math.huge or math.huge
		for sx = -1, 1, 2 do
			for sy = -1, 1, 2 do
				for sz = -1, 1, 2 do
					local world = p.CFrame:PointToWorldSpace(Vector3.new(h.X * sx, h.Y * sy, h.Z * sz))
					local v = ref.CFrame:PointToObjectSpace(world)[axis]
					far = useHi and math.max(far, v) or math.min(far, v)
				end
			end
		end
		if math.abs(far - endVal) <= len * 0.12 then
			sumV = sumV + ref.CFrame:PointToObjectSpace(p.Position)
			n += 1
		end
	end
	local center = (lo + hi) / 2
	if n > 0 then center = sumV / n end
	local tip = withAxis(center, axis, endVal)
	local side = withAxis(Vector3.zero, sideAxis, TRAIL_WIDTH / 2)
	return ref, tip, side, "far end of the longest side (guess)"
end

local learnedTip = setmetatable({}, { __mode = "k" }) -- tool -> { part, pos }
local function learnTip(beam)
	local hand = handPosition()
	local bestWorld, bestDist
	for _, a in ipairs({ beam.Attachment0, beam.Attachment1 }) do
		if a and a.Parent and a.Parent:IsA("BasePart") then
			local w = a.WorldPosition
			local dist = hand and (w - hand).Magnitude or 0
			if not bestDist or dist < bestDist then
				bestWorld, bestDist = w, dist
			end
		end
	end
	if not bestWorld or bestDist > 12 then return false end
	for tool in pairs(hooked) do
		if tool.Parent and tool.Parent == LocalPlayer.Character then
			local nearest, nearestD
			for _, p in ipairs(partsUnder(tool)) do
				local d = (p.Position - bestWorld).Magnitude - p.Size.Magnitude / 2
				if not nearestD or d < nearestD then nearest, nearestD = p, d end
			end
			if nearest and nearestD < 6 then
				learnedTip[tool] = { part = nearest, pos = nearest.CFrame:PointToObjectSpace(bestWorld) }
				removeTrail(tool)
				return true
			end
		end
	end
	return false
end

local function buildTrail(tool, allParts, gripPos)
	removeTrail(tool)
	local ref, tip, side, how
	local isTool = typeof(tool) == "Instance"
	local learned = learnedTip[tool]
	local useLearned = false
	if TRAIL_END ~= "back" and learned and learned.part and learned.part.Parent then
		useLearned = true
		-- only trust where the shot left the gun if that is really out at the front, not the middle
		local ap, atip = aimTip(allParts)
		if ap and isTool then
			local a = ap.CFrame:PointToWorldSpace(atip)
			local l = learned.part.CFrame:PointToWorldSpace(learned.pos)
			local biggest = 1
			for _, q in ipairs(allParts) do biggest = math.max(biggest, q.Size.Magnitude) end
			useLearned = (a - l).Magnitude <= math.max(biggest * 0.3, 1)
		end
	end
	if useLearned then
		ref, tip, side, how = learned.part, learned.pos, Vector3.new(TRAIL_WIDTH / 2, 0, 0), "where your shot leaves the gun"
	else
		ref, tip, side, how = findTip(allParts, gripPos, true)
	end
	if not ref then return end
	print("[Voidscope Recolor] trail tip = " .. how .. " (on part '" .. ref.Name .. "')")
	-- moves the whole trail DOWN (same spot along the gun, just lower)
	local upLocal = ref.CFrame:VectorToObjectSpace(Vector3.new(0, 1, 0))
	local drop = upLocal.Magnitude > 0.01 and (upLocal.Unit * -TRAIL_DROP) or Vector3.zero
	local a0 = Instance.new("Attachment")
	a0.Name = "VSTrail"
	a0.Position = tip + side + drop
	a0.Parent = ref
	local a1 = Instance.new("Attachment")
	a1.Name = "VSTrail"
	a1.Position = tip - side + drop
	a1.Parent = ref
	local trail = Instance.new("Trail")
	trail.Name = "VSTrail"
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = TRAIL_LIFETIME
	trail.MinLength = 0.02
	trail.FaceCamera = true
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	trail.Parent = ref
	trailLook(trail)
	trails[tool] = { trail = trail, a0 = a0, a1 = a1 }
	trailRefs[tool] = ref
end

local function glassWanted()
	return glassOverlay or (selected ~= nil and (selected.mode == "glass" or selected.forceGlass == true))
end

local function glassify(inst)
	set(inst, "Transparency", glassT())
	set(inst, "Material", Enum.Material.Glass)
	glassed[inst] = true
end

local function applyGlass(inst)
	if not glassGuarded[inst] then
		glassGuarded[inst] = true
		connect(inst:GetPropertyChangedSignal("Transparency"), function()
			if not unglassing and glassWanted() and inst.Transparency < glassT() - 0.01 then
				glassify(inst)
			end
		end)
	end
	if inst.Transparency < glassT() - 0.01 then
		glassify(inst)
	elseif glassed[inst] and inst.Material ~= Enum.Material.Glass then
		set(inst, "Material", Enum.Material.Glass)
	end
end

local function unglassAll()
	unglassing = true
	for inst in pairs(glassed) do
		local saved = originals[inst]
		if saved then
			pcall(function()
				if saved.Transparency ~= nil and inst.Transparency < 0.95 then
					inst.Transparency = saved.Transparency
				end
				if saved.Material ~= nil then inst.Material = saved.Material end
			end)
			saved.Transparency = nil
			saved.Material = nil
		end
		glassed[inst] = nil
	end
	unglassing = false
end

local function restoreAll()
	unglassAll()
	for tool in pairs(trails) do removeTrail(tool) end
	for part in pairs(sheens) do removeSheen(part) end
	for mp in pairs(chromed) do chromed[mp] = nil end
	for inst, saved in pairs(originals) do
		for prop, v in pairs(saved) do
			pcall(function() inst[prop] = v end)
		end
	end
	for k in pairs(originals) do
		originals[k] = nil
	end
	for mp in pairs(overlays) do removeOverlay(mp) end
	for mp in pairs(applied) do applied[mp] = nil end
	for mp, cache in pairs(saCache) do
		for _, o in pairs(cache) do
			pcall(function() o:Destroy() end)
		end
		saCache[mp] = nil
	end
	for mp, sa in pairs(surfaces) do
		pcall(function() sa:Destroy() end)
		surfaces[mp] = nil
	end
end

local function paint(inst, color, isShot)
	if inst:IsA("MeshPart") and not isShot then
		-- texture styles / skins paint the whole look themselves, so a textured part must not add a colour tint on top.
		-- Parts with no texture have nothing to paint them, so they get the plain colour.
		local hasTex = false
		pcall(function() hasTex = inst.TextureID ~= "" end)
		local c = (hasTex and ((selected and selected.mode == "texture") or skinOf(selected))) and Color3.new(1, 1, 1) or color
		set(inst, "Color", c)
		watchTexture(inst)
		tintMesh(inst, color)
		if glassWanted() then applyGlass(inst) end
		return true
	elseif inst:IsA("BasePart") then
		set(inst, "Color", color)
		if glassWanted() and not isShot then applyGlass(inst) end
		if isShot then
			if inst:IsA("MeshPart") then set(inst, "TextureID", "") end
			set(inst, "MaterialVariant", "")
			if colorsClose(color, Color3.new(0, 0, 0)) then
				set(inst, "Material", Enum.Material.SmoothPlastic)
			else
				set(inst, "Material", Enum.Material.Neon)
			end
		end
		return true
	elseif isEffect(inst) then
		if inst.Name == "VSTrail" then return false end
		if selected and (selected.mode == "rainbow" or selected.rainbowFx) then
			set(inst, "Color", RAINBOW_SEQUENCE)
		elseif selected and selected.effectSeq then
			set(inst, "Color", selected.effectSeq)
		else
			set(inst, "Color", ColorSequence.new(color))
		end
		return true
	elseif inst:IsA("SpecialMesh") then
		if isShot then set(inst, "TextureId", "") end
		set(inst, "VertexColor", Vector3.new(color.R, color.G, color.B))
		return true
	elseif inst:IsA("SurfaceAppearance") then
		if inst.Name == "VSSurface" then return false end
		if isShot or isChrome() then set(inst, "ColorMap", "") end
		set(inst, "Color", color)
		return true
	elseif inst:IsA("Decal") or inst:IsA("Texture") then
		set(inst, "Color3", color)
		return true
	elseif inst:IsA("Light") then
		if inst.Name == "VSSheen" then return false end
		set(inst, "Color", color)
		return true
	elseif inst:IsA("Fire") then
		set(inst, "Color", color)
		set(inst, "SecondaryColor", color)
		return true
	elseif inst:IsA("Sparkles") then
		set(inst, "SparkleColor", color)
		return true
	elseif inst:IsA("Highlight") then
		if inst.Name == "VSOverlay" then return false end
		set(inst, "FillColor", color)
		set(inst, "OutlineColor", color)
		return true
	end
	return false
end

local function guardEffect(inst)
	if not isEffect(inst) or guarded[inst] then return end
	if inst.Name == "VSTrail" then return end
	guarded[inst] = true
	connect(inst:GetPropertyChangedSignal("Color"), function()
		if not selected then return end
		local fine
		if selected.mode == "rainbow" or selected.rainbowFx then
			fine = #inst.Color.Keypoints == #RAINBOW_SEQUENCE.Keypoints
		elseif selected.effectSeq then
			fine = #inst.Color.Keypoints == #selected.effectSeq.Keypoints
		else
			fine = seqIsColor(inst.Color, colorFor(inst))
		end
		if not fine then
			paint(inst, colorFor(inst), false)
		end
	end)
end

local function paintGun(tool)
	if not selected then return 0 end
	local ref = mapRainbow(partsUnder(tool))
	local effects = 0
	for _, d in ipairs(tool:GetDescendants()) do
		if paint(d, colorFor(d), false) and isEffect(d) then
			effects += 1
		end
		guardEffect(d)
	end
	if ref and wantsSheen() then addSheen(ref) end
	return effects
end

local function gunAssetIds()
	local ids = {}
	for tool in pairs(hooked) do
		for _, d in ipairs(tool:GetDescendants()) do
			if d:IsA("MeshPart") then
				local okt, tex = pcall(function() return d.TextureID end)
				if okt and type(tex) == "string" and tex ~= "" then ids[tex] = true end
				local okm, mesh = pcall(function() return d.MeshId end)
				if okm and type(mesh) == "string" and mesh ~= "" then ids[mesh] = true end
			end
		end
	end
	return ids
end

local function hipTarget(char)
	local ref = char:FindFirstChild("DisplayRefGun")
	if not (ref and ref:IsA("ObjectValue")) then return nil end
	local t = ref.Value
	if not t then return nil end
	if t == char or char:IsDescendantOf(t) then return nil end
	if t:IsA("Humanoid") or t:FindFirstChildOfClass("Humanoid") then return nil end
	return t
end

local function watchTarget(target)
	if watchedTargets[target] then return end
	watchedTargets[target] = true
	connect(target.DescendantAdded, function(d)
		task.defer(function()
			if selected and d.Parent then
				paint(d, colorFor(d), false)
			end
		end)
	end)
end

local function paintHip()
	local char = LocalPlayer.Character
	if not (selected and char) then return 0 end
	local done, count = {}, 0
	local function paintOne(d)
		if done[d] then return end
		done[d] = true
		if paint(d, colorFor(d), false) and d:IsA("BasePart") then
			count += 1
		end
	end
	local target = hipTarget(char)
	if target then
		watchTarget(target)
		local targetRef = mapRainbow(partsUnder(target))
		paintOne(target)
		for _, d in ipairs(target:GetDescendants()) do
			paintOne(d)
		end
		if targetRef and wantsSheen() then addSheen(targetRef) end
	end
	local ids = gunAssetIds()
	local matched = {}
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("MeshPart") and not done[d] and not d:FindFirstAncestorOfClass("Tool") then
			local okt, tex = pcall(function() return d.TextureID end)
			local okm, mesh = pcall(function() return d.MeshId end)
			if (okt and tex ~= "" and ids[tex]) or (okm and mesh ~= "" and ids[mesh]) then
				table.insert(matched, d)
			end
		end
	end
	local matchedRef = mapRainbow(matched)
	for _, d in ipairs(matched) do
		paintOne(d)
	end
	if matchedRef and wantsSheen() then addSheen(matchedRef) end
	return count
end

local function hipGroups()
	local groups = {}
	local char = LocalPlayer.Character
	if not char then return groups end
	local target = hipTarget(char)
	if target then groups["HIPTARGET"] = partsUnder(target) end
	local ids = gunAssetIds()
	local matched = {}
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("MeshPart") and not d:FindFirstAncestorOfClass("Tool") and not (target and d:IsDescendantOf(target)) then
			local okt, tex = pcall(function() return d.TextureID end)
			local okm, mesh = pcall(function() return d.MeshId end)
			if (okt and tex ~= "" and ids[tex]) or (okm and mesh ~= "" and ids[mesh]) then
				table.insert(matched, d)
			end
		end
	end
	if #matched > 0 then groups["HIPMATCH"] = matched end
	return groups
end

-- a trail only counts as working if it still sits on a live part of the CURRENT gun
local function trailAlive(key, parts)
	local made = trails[key]
	if not (made and made.trail and made.trail.Parent and made.a0 and made.a0.Parent and made.a1 and made.a1.Parent) then
		return false
	end
	if not made.trail:IsDescendantOf(Workspace) then return false end
	local ref = trailRefs[key]
	if not (ref and ref.Parent) then return false end
	if typeof(key) == "Instance" then return ref:IsDescendantOf(key) end
	return table.find(parts, ref) ~= nil
end

local function ensureTrail(key, getParts, gripFn)
	local parts = (typeof(key) ~= "Instance") and getParts() or nil
	if trailAlive(key, parts) then
		local trail = trails[key].trail
		if not trail.Enabled then trail.Enabled = true end
		trail.Lifetime = TRAIL_LIFETIME
		trailLook(trail)
		return
	end
	removeTrail(key) -- throw the dead / stale one away and build a fresh one on the new gun
	parts = parts or getParts()
	local ok, err = pcall(function()
		buildTrail(key, parts, gripFn and gripFn(parts) or nil)
	end)
	if not ok then warn("[Voidscope Recolor] trail failed: " .. tostring(err)) end
end

local function refreshTrails()
	if not (trailOn and selected) then
		for key in pairs(trails) do removeTrail(key) end
		return
	end
	for tool in pairs(hooked) do
		if tool.Parent and tool.Parent == LocalPlayer.Character then
			ensureTrail(tool, function() return partsUnder(tool) end, handPosition)
		else
			removeTrail(tool)
		end
	end
	local groups = hipGroups()
	for key, parts in pairs(groups) do
		ensureTrail(key, function() return parts end, handleGrip)
	end
	for key in pairs(trails) do
		if type(key) == "string" and not groups[key] then removeTrail(key) end
	end
end

local lastTrailCheck = 0
connect(RunService.Heartbeat, function()
	if not (trailOn and selected) then return end
	local now = os.clock()
	if now - lastTrailCheck < 0.4 then return end
	lastTrailCheck = now
	local ok, err = pcall(refreshTrails) -- an error can never switch the trail off for good
	if not ok then warn("[Voidscope Recolor] trail refresh failed: " .. tostring(err)) end
end)

local function refreshHip()
	if not selected then return end
	local n = paintHip()
	if n > 0 then
		setHipStatus("Hip gun: recoloured (" .. n .. " part(s))")
	else
		setHipStatus("Hip gun: not seen yet (put the gun away)")
	end
end

local function queueHipRefresh()
	if hipQueued then return end
	hipQueued = true
	task.defer(function()
		hipQueued = false
		refreshHip()
	end)
end

local function hookRef(ref)
	if guarded[ref] then return end
	guarded[ref] = true
	connect(ref:GetPropertyChangedSignal("Value"), queueHipRefresh)
end

local function watchCharacter(char)
	if not char then return end
	connect(char.DescendantAdded, function(d)
		if d.Name == "DisplayRefGun" and d:IsA("ObjectValue") then
			hookRef(d)
			queueHipRefresh()
		elseif selected and d:IsA("MeshPart") then
			queueHipRefresh()
		end
	end)
	local ref = char:FindFirstChild("DisplayRefGun")
	if ref and ref:IsA("ObjectValue") then hookRef(ref) end
end

-- GUN DETECTION: a Tool counts as the gun if its name is "gun" or contains any word below.
-- If the menu says "Gun not found", add the exact name of your gun tool here (it lists the tools it can see).
local GUN_NAMES = { "gun", "voidscope" }
local function isGun(inst)
	if not inst:IsA("Tool") then return false end
	local n = string.lower(inst.Name)
	if n == "gun" then return true end
	for _, word in ipairs(GUN_NAMES) do
		if string.find(n, string.lower(word), 1, true) then return true end
	end
	return false
end

local function toolNames()
	local names = {}
	local function grab(c)
		if not c then return end
		for _, t in ipairs(c:GetChildren()) do
			if t:IsA("Tool") then table.insert(names, t.Name) end
		end
	end
	grab(LocalPlayer.Character)
	grab(LocalPlayer:FindFirstChildOfClass("Backpack"))
	return #names > 0 and table.concat(names, ", ") or "none"
end

local function openShotWindow()
	local now = os.clock()
	if now > shotUntil then shotCount = 0 end
	shotUntil = now + SHOT_WINDOW
	task.delay(SHOT_WINDOW + 0.2, function()
		if selected and os.clock() >= shotUntil then
			setNote("Last shot: " .. shotCount .. " extra effect(s) recoloured")
		end
	end)
end

local function watchSound(inst)
	if not inst:IsA("Sound") or guarded[inst] then return end
	local n = string.lower(inst.Name)
	if string.find(n, "shot", 1, true) or string.find(n, "shoot", 1, true)
		or string.find(n, "fire", 1, true) or string.find(n, "alt", 1, true) then
		guarded[inst] = true
		connect(inst.Played, openShotWindow)
	end
end

local function hookGun(tool)
	if hooked[tool] then return end
	hooked[tool] = true
	print("[Voidscope Recolor] found gun: " .. tool:GetFullName())
	task.delay(PREBUILD_DELAY, prebuildTextures, tool) -- builds the backup looks quietly in the background
	task.spawn(SkinKit.prebuild, tool)                 -- makes every downloaded skin ready on every gun part right now (instant switching)
	local effects = paintGun(tool)
	if selected then
		setGunStatus("Gun: found, " .. effects .. " beam part(s)")
		refreshHip()
	else
		setGunStatus("Gun: found (" .. tool.Name .. ")")
	end
	for _, d in ipairs(tool:GetDescendants()) do
		watchSound(d)
	end
	connect(tool.DescendantAdded, function(d)
		guardEffect(d)
		watchSound(d)
		task.defer(function()
			if selected and d.Parent then
				paint(d, colorFor(d), false)
			end
		end)
	end)
	connect(tool.Activated, openShotWindow)
	connect(tool.Equipped, function()
		task.delay(0.3, function()
			if selected then paintGun(tool) end
			if trailOn and selected then refreshTrails() end
		end)
	end)
	connect(tool.Unequipped, function()
		removeTrail(tool)
		task.delay(0.3, function()
			if selected then
				refreshHip()
				refreshTrails()
			end
		end)
	end)
	if trailOn and selected and tool.Parent == LocalPlayer.Character then
		task.delay(0.3, refreshTrails)
	end
end

local function scan(container)
	if not container then return end
	for _, child in ipairs(container:GetChildren()) do
		if isGun(child) then hookGun(child) end
	end
	connect(container.ChildAdded, function(child)
		if isGun(child) then hookGun(child) end
	end)
end

scan(LocalPlayer.Character)
scan(LocalPlayer:FindFirstChildOfClass("Backpack"))
connect(LocalPlayer.CharacterAdded, scan)
watchCharacter(LocalPlayer.Character)
connect(LocalPlayer.CharacterAdded, watchCharacter)
-- new round / respawn: forget the old trails and rebuild them on the new gun a few times while it loads in
connect(LocalPlayer.CharacterAdded, function()
	for key in pairs(trails) do removeTrail(key) end
	for k in pairs(learnedTip) do learnedTip[k] = nil end
	for _, wait_ in ipairs({ 0.5, 1.5, 3, 6 }) do
		task.delay(wait_, function()
			if trailOn and selected then pcall(refreshTrails) end
		end)
	end
end)
connect(LocalPlayer.ChildAdded, function(c)
	if c:IsA("Backpack") then scan(c) end
end)

-- after a round ends / you respawn the game hands you a brand new gun: pick it up again within a second
local lastRehook = 0
connect(RunService.Heartbeat, function()
	local now = os.clock()
	if now - lastRehook < 1 then return end
	lastRehook = now
	for _, c in ipairs({ LocalPlayer.Character, LocalPlayer:FindFirstChildOfClass("Backpack") }) do
		if c then
			for _, child in ipairs(c:GetChildren()) do
				if isGun(child) and not hooked[child] then hookGun(child) end
			end
		end
	end
end)

connect(UserInputService.InputBegan, function(input, processed)
	if processed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		local char = LocalPlayer.Character
		if char then
			for _, child in ipairs(char:GetChildren()) do
				if isGun(child) then
					openShotWindow()
					break
				end
			end
		end
	end
end)

local function characterOf(inst)
	local m = inst:FindFirstAncestorOfClass("Model")
	while m do
		if m:FindFirstChildOfClass("Humanoid") then return m end
		m = m:FindFirstAncestorOfClass("Model")
	end
	return nil
end

local function partOf(inst)
	if inst:IsA("BasePart") then return inst end
	local p = inst.Parent
	if p and p:IsA("Attachment") then p = p.Parent end
	if p and p:IsA("BasePart") then return p end
	return nil
end

local function nearYou(d)
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return true end
	local points = {}
	local part = partOf(d)
	if part then table.insert(points, part.Position) end
	if d:IsA("Beam") then
		local a0, a1 = d.Attachment0, d.Attachment1
		if a0 then table.insert(points, a0.WorldPosition) end
		if a1 then table.insert(points, a1.WorldPosition) end
	end
	if #points == 0 then return true end
	for _, p in ipairs(points) do
		if (p - root.Position).Magnitude <= SHOT_RADIUS then return true end
	end
	return false
end

connect(Workspace.DescendantAdded, function(d)
	if not selected then return end
	if os.clock() > shotUntil then return end
	local char = characterOf(d)
	if char then
		if char ~= LocalPlayer.Character then return end
		if not (isEffect(d) or d:IsA("Light")) then return end
	end
	task.defer(function()
		if not d.Parent or not selected then return end
		if not nearYou(d) then return end
		if d:IsA("Beam") then
			local function learn()
				if learnTip(d) and trailOn then refreshTrails() end
			end
			learn()
			task.delay(0.05, learn)
		end
		if paint(d, colorFor(d), true) then
			guardEffect(d)
			shotCount += 1
		end
	end)
end)

---------------------------------------------------------------------
-- HEX PARSER (used by the colour picker)
---------------------------------------------------------------------
local function parseHex(s)
	s = string.gsub(s or "", "[#%s]", "")
	s = string.gsub(s, "^0[xX]", "")
	if #s == 3 then
		s = string.sub(s, 1, 1) .. string.sub(s, 1, 1) .. string.sub(s, 2, 2) .. string.sub(s, 2, 2)
			.. string.sub(s, 3, 3) .. string.sub(s, 3, 3)
	end
	if #s ~= 6 or string.find(s, "%X") then return nil end
	local n = tonumber(s, 16)
	if not n then return nil end
	return Color3.fromRGB(math.floor(n / 65536) % 256, math.floor(n / 256) % 256, n % 256)
end

local function setOutline(bg, on)
	local stroke = bg:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = on and BUTTON_SELECTED or BUTTON_OUTLINE
		stroke.Thickness = on and 2.5 or 1
		stroke.Transparency = on and 0 or 0.45
	end
end

local function updateStatus()
	if glassToggleBtn then
		glassToggleBtn.Text = glassOverlay and "SEE-THROUGH: ON" or "SEE-THROUGH: OFF"
	end
	if glassToggleBg then
		glassToggleBg.BackgroundColor3 = glassOverlay and Color3.fromRGB(0, 105, 190) or Color3.fromRGB(78, 80, 92)
	end
	if trailToggleBtn then
		trailToggleBtn.Text = trailOn and "TRAIL: ON" or "TRAIL: OFF"
	end
	if trailToggleBg then
		trailToggleBg.BackgroundColor3 = trailOn and Color3.fromRGB(0, 105, 190) or Color3.fromRGB(78, 80, 92)
	end
	if statusLabel then
		statusLabel.Text = selected and ("Selected: " .. selected.name) or "Selected: Default"
	end
	for name, bg in pairs(buttons) do
		setOutline(bg, selected ~= nil and selected.name == name)
	end
end

local function applyColor(entry)
	selected = entry
	if not glassWanted() then unglassAll() end
	for part in pairs(sheens) do removeSheen(part) end
	local found, effects = 0, 0
	for tool in pairs(hooked) do
		if tool.Parent then
			found += 1
			effects += paintGun(tool)
		end
	end
	if found == 0 then
		setGunStatus("Gun not found. Tools seen: " .. toolNames() .. " (add the right name to GUN_NAMES)")
	else
		setGunStatus("Gun: found, " .. effects .. " beam part(s)")
		if not (selected and selected.mode == "texture") then setNote("") end
	end
	refreshHip()
	refreshTrails()
	updateStatus()
end

local function resetColor()
	selected = nil
	glassOverlay = false
	trailOn = false
	restoreAll()
	setNote("")
	setHipStatus("Hip gun: pick a colour first")
	updateStatus()
end

local function label(frame, order, text, size, color, height)
	local l = Instance.new("TextLabel")
	l.LayoutOrder = order
	l.Size = UDim2.new(1, 0, 0, height)
	l.BackgroundTransparency = 1
	l.Font = BUBBLY_FONT
	l.TextSize = size
	l.TextColor3 = color
	l.TextWrapped = true
	l.Text = text
	l.Parent = frame
	return l
end

local B64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function b64decode(data)
	local lookup = {}
	for i = 1, 64 do
		lookup[string.byte(B64_CHARS, i)] = i - 1
	end
	data = string.gsub(data, "[^%w%+/=]", "")
	local chunks = {}
	for i = 1, #data, 4 do
		local c1, c2, c3, c4 = string.byte(data, i, i + 3)
		local v3 = (c3 and c3 ~= 61) and lookup[c3] or nil
		local v4 = (c4 and c4 ~= 61) and lookup[c4] or nil
		local n = lookup[c1] * 262144 + lookup[c2] * 4096 + (v3 or 0) * 64 + (v4 or 0)
		local b1 = math.floor(n / 65536)
		local b2 = math.floor(n / 256) % 256
		local b3 = n % 256
		if v4 then
			table.insert(chunks, string.char(b1, b2, b3))
		elseif v3 then
			table.insert(chunks, string.char(b1, b2))
		else
			table.insert(chunks, string.char(b1))
		end
	end
	return table.concat(chunks)
end

local function loadIconImage()
	if MINI_ICON_ASSET ~= "" then return MINI_ICON_ASSET end
	local hasB64 = string.gsub(ICON_PNG_B64, "%s", "") ~= ""
	if not hasB64 and ICON_URL == "" then return nil end
	local toAsset = getcustomasset or getsynasset
	if not (writefile and toAsset) then return nil end
	local ok, asset = pcall(function()
		local name = "VestaIcon2.png"
		if hasB64 then
			writefile(name, b64decode(ICON_PNG_B64))
		else
			writefile(name, game:HttpGet(ICON_URL))
		end
		return toAsset(name)
	end)
	if ok and type(asset) == "string" and asset ~= "" then
		return asset
	end
	return nil
end

local function buildGui()
	gui = Instance.new("ScreenGui")
	gui.Name = "VoidscopeRecolor"
	gui.ResetOnSpawn = false
	local ok = pcall(function()
		gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
	end)
	if not ok or not gui.Parent then
		gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end

	local WIDTH = 290   -- width of the page area
	local TABW = 0      -- no side tab column

	local function photoText(b, size)
		b.Font = BUBBLY_FONT
		b.TextSize = size or 15
		b.TextColor3 = Color3.new(1, 1, 1)
		b.TextStrokeColor3 = Color3.new(0, 0, 0)
		b.TextStrokeTransparency = 0.3
	end

	local METAL_FRAME = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(12, 12, 15)),
		ColorSequenceKeypoint.new(0.1, Color3.fromRGB(2, 2, 4)),
		ColorSequenceKeypoint.new(0.24, Color3.fromRGB(2, 2, 3)),
		ColorSequenceKeypoint.new(0.31, Color3.fromRGB(34, 36, 44)),
		ColorSequenceKeypoint.new(0.37, Color3.fromRGB(6, 6, 9)),
		ColorSequenceKeypoint.new(0.55, Color3.fromRGB(1, 1, 2)),
		ColorSequenceKeypoint.new(0.67, Color3.fromRGB(26, 27, 34)),
		ColorSequenceKeypoint.new(0.73, Color3.fromRGB(4, 4, 6)),
		ColorSequenceKeypoint.new(0.88, Color3.fromRGB(2, 2, 3)),
		ColorSequenceKeypoint.new(0.95, Color3.fromRGB(20, 21, 27)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(4, 4, 6)),
	})
	local METAL_BUTTON = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(175, 175, 182)),
		ColorSequenceKeypoint.new(0.48, Color3.fromRGB(120, 120, 128)),
		ColorSequenceKeypoint.new(0.52, Color3.fromRGB(75, 75, 84)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(135, 135, 144)),
	})

	-- where the mouse / finger is, in the same space as AbsolutePosition
	local function pointerPos(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			return Vector2.new(input.Position.X, input.Position.Y)
		end
		local m = UserInputService:GetMouseLocation()
		local inset = GuiService:GetGuiInset()
		return Vector2.new(m.X - inset.X, m.Y - inset.Y)
	end

	local function makeGlassButton(parent, order, text, fillColor, fillGradient, onClick, transparency)
		local holder = Instance.new("Frame")
		holder.LayoutOrder = order
		holder.BackgroundTransparency = 1
		holder.Parent = parent

		local bg = Instance.new("Frame")
		bg.Name = "Glass"
		bg.Size = UDim2.new(1, 0, 1, 0)
		bg.BackgroundColor3 = fillGradient and Color3.new(1, 1, 1) or fillColor
		bg.BackgroundTransparency = transparency or 0
		bg.BorderSizePixel = 0
		bg.ZIndex = 1
		bg.Parent = holder
		Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 9)
		local g = Instance.new("UIGradient")
		if fillGradient then
			g.Color = fillGradient
		else
			g.Color = METAL_BUTTON
			g.Rotation = 90
		end
		g.Parent = bg
		local stroke = Instance.new("UIStroke")
		stroke.Color = BUTTON_OUTLINE
		stroke.Thickness = 1
		stroke.Transparency = 0.45
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = bg

		local shine = Instance.new("Frame")
		shine.Name = "Shine"
		shine.Size = UDim2.new(1, -8, 0.45, 0)
		shine.Position = UDim2.new(0, 4, 0, 2)
		shine.BackgroundColor3 = Color3.new(1, 1, 1)
		shine.BorderSizePixel = 0
		shine.ZIndex = 2
		shine.Parent = holder
		Instance.new("UICorner", shine).CornerRadius = UDim.new(0, 7)
		local shineGradient = Instance.new("UIGradient")
		shineGradient.Rotation = 90
		shineGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.6),
			NumberSequenceKeypoint.new(1, 1),
		})
		shineGradient.Parent = shine

		local tb = Instance.new("TextButton")
		tb.Size = UDim2.new(1, 0, 1, 0)
		tb.BackgroundTransparency = 1
		tb.BorderSizePixel = 0
		tb.AutoButtonColor = false
		tb.ZIndex = 3
		photoText(tb, 13)
		tb.TextScaled = true
		local limit = Instance.new("UITextSizeConstraint")
		limit.MaxTextSize = 14
		limit.MinTextSize = 7
		limit.Parent = tb
		tb.Text = text
		tb.Parent = holder
		tb.MouseButton1Click:Connect(onClick)
		return bg, tb, holder
	end

	local frame = Instance.new("Frame")
	frame.Name = "Main"
	frame.Size = UDim2.new(0, WIDTH + TABW, 0, 400)
	frame.Position = UDim2.new(0, 20, 0.04, 0)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BackgroundTransparency = 0
	frame.BorderSizePixel = 0
	frame.Active = true
	pcall(function() frame.Draggable = true end)
	frame.Parent = gui
	local guiScale = Instance.new("UIScale")
	guiScale.Scale = GUI_SCALE
	guiScale.Parent = frame
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)
	local frameStroke = Instance.new("UIStroke")
	frameStroke.Color = MENU_OUTLINE
	frameStroke.Thickness = 1.5
	frameStroke.Transparency = 0.5
	frameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	frameStroke.Parent = frame
	local glassSheen = Instance.new("UIGradient")
	glassSheen.Rotation = 70
	glassSheen.Color = METAL_FRAME
	glassSheen.Parent = frame
	local gloss = Instance.new("Frame")
	gloss.Name = "Gloss"
	gloss.Size = UDim2.new(1, -6, 0.3, 0)
	gloss.Position = UDim2.new(0, 3, 0, 3)
	gloss.BackgroundColor3 = Color3.new(1, 1, 1)
	gloss.BorderSizePixel = 0
	gloss.ZIndex = 1
	gloss.Parent = frame
	Instance.new("UICorner", gloss).CornerRadius = UDim.new(0, 14)
	local glossGradient = Instance.new("UIGradient")
	glossGradient.Rotation = 90
	glossGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.93),
		NumberSequenceKeypoint.new(0.6, 0.98),
		NumberSequenceKeypoint.new(1, 1),
	})
	glossGradient.Parent = gloss

	-- LEFT SIDE TABS
	local sidebar = Instance.new("Frame")
	sidebar.Name = "Tabs"
	sidebar.Position = UDim2.new(0, 8, 0, 10)
	sidebar.Size = UDim2.new(0, TABW - 14, 1, -20)
	sidebar.BackgroundColor3 = Color3.new(0, 0, 0)
	sidebar.BackgroundTransparency = 0.3
	sidebar.BorderSizePixel = 0
	sidebar.ZIndex = 2
	sidebar.Parent = frame
	sidebar.Visible = false
	Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 12)
	local sideStroke = Instance.new("UIStroke")
	sideStroke.Color = BUTTON_OUTLINE
	sideStroke.Thickness = 1
	sideStroke.Transparency = 0.5
	sideStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	sideStroke.Parent = sidebar
	local sidePad = Instance.new("UIPadding", sidebar)
	sidePad.PaddingTop = UDim.new(0, 6)
	sidePad.PaddingBottom = UDim.new(0, 6)
	sidePad.PaddingLeft = UDim.new(0, 5)
	sidePad.PaddingRight = UDim.new(0, 5)
	local sideList = Instance.new("UIListLayout", sidebar)
	sideList.Padding = UDim.new(0, 6)
	sideList.SortOrder = Enum.SortOrder.LayoutOrder

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Position = UDim2.new(0, TABW, 0, 0)
	content.Size = UDim2.new(0, WIDTH, 0, 0)
	content.AutomaticSize = Enum.AutomaticSize.Y
	content.BackgroundTransparency = 1
	content.ZIndex = 2
	content.Parent = frame
	local pad = Instance.new("UIPadding", content)
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	local list = Instance.new("UIListLayout", content)
	list.Padding = UDim.new(0, 6)
	list.SortOrder = Enum.SortOrder.LayoutOrder

	local function syncHeight()
		frame.Size = UDim2.new(0, WIDTH + TABW, 0, math.max(content.AbsoluteSize.Y / GUI_SCALE, 200))
	end
	connect(content:GetPropertyChangedSignal("AbsoluteSize"), syncHeight)
	task.defer(syncHeight)

	local order = 0
	local function nextOrder()
		order += 1
		return order
	end

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.LayoutOrder = nextOrder()
	header.Size = UDim2.new(1, 0, 0, 30)
	header.BackgroundTransparency = 1
	header.Parent = content

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -70, 1, 0)
	title.BackgroundTransparency = 1
	title.Font = BUBBLY_FONT
	title.Text = "VESTA RECOLOR"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextStrokeColor3 = Color3.new(0, 0, 0)
	title.TextStrokeTransparency = 0.3
	title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header
	local titleLimit = Instance.new("UITextSizeConstraint")
	titleLimit.MaxTextSize = 19
	titleLimit.Parent = title

	local function headerButton(text, xOffset, bg)
		local b = Instance.new("TextButton")
		b.AnchorPoint = Vector2.new(1, 0.5)
		b.Position = UDim2.new(1, xOffset, 0.5, 0)
		b.Size = UDim2.new(0, 28, 0, 28)
		b.BackgroundColor3 = bg
		b.BackgroundTransparency = 0.3
		b.BorderSizePixel = 0
		photoText(b, 18)
		b.Text = text
		b.Parent = header
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
		local s = Instance.new("UIStroke")
		s.Color = BUTTON_OUTLINE
		s.Transparency = 0.5
		s.Thickness = 1
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		s.Parent = b
		return b
	end
	local minBtn = headerButton("-", -34, Color3.fromRGB(38, 40, 54))
	local closeBtn = headerButton("X", 0, Color3.fromRGB(125, 30, 30))

	-- PAGES (one per side tab, only one is visible at a time)
	local pages = {}
	local function newPage(name)
		local page = Instance.new("Frame")
		page.Name = name
		page.LayoutOrder = nextOrder()
		page.Size = UDim2.new(1, 0, 0, 0)
		page.AutomaticSize = Enum.AutomaticSize.Y
		page.BackgroundTransparency = 1
		page.Visible = false
		page.Parent = content
		local pl = Instance.new("UIListLayout", page)
		pl.Padding = UDim.new(0, 6)
		pl.SortOrder = Enum.SortOrder.LayoutOrder
		local n = 0
		pages[name] = page
		return page, function()
			n += 1
			return n
		end
	end

	local function featureRow(page, nextFn)
		local row = Instance.new("Frame")
		row.LayoutOrder = nextFn()
		row.Size = UDim2.new(1, 0, 0, 30)
		row.BackgroundTransparency = 1
		row.Parent = page
		local rl = Instance.new("UIListLayout")
		rl.FillDirection = Enum.FillDirection.Horizontal
		rl.Padding = UDim.new(0, 6)
		rl.SortOrder = Enum.SortOrder.LayoutOrder
		rl.Parent = row
		return row
	end

	local function sectionLabel(page, nextFn, text)
		local l = label(page, nextFn(), text, 14, Color3.new(1, 1, 1), 16)
		l.Font = BUBBLY_FONT
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextStrokeColor3 = Color3.new(0, 0, 0)
		l.TextStrokeTransparency = 0.3
		return l
	end

	-- scrolling list of colours; suffix = " SCOPE", store = table that remembers each button
	local function colorScroll(page, nextFn, suffix, onPick, store, list_)
		local scroll = Instance.new("ScrollingFrame")
		scroll.Name = "Colours"
		scroll.LayoutOrder = nextFn()
		scroll.Size = UDim2.new(1, 0, 0, 175)
		scroll.BackgroundColor3 = Color3.new(0, 0, 0)
		scroll.BackgroundTransparency = 0.3
		scroll.BorderSizePixel = 0
		scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroll.ScrollingDirection = Enum.ScrollingDirection.Y
		scroll.ScrollBarThickness = 4
		scroll.ScrollBarImageColor3 = Color3.fromRGB(150, 154, 170)
		scroll.Parent = page
		Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 10)
		local scrollStroke = Instance.new("UIStroke")
		scrollStroke.Color = BUTTON_OUTLINE
		scrollStroke.Thickness = 1
		scrollStroke.Transparency = 0.5
		scrollStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		scrollStroke.Parent = scroll
		local scrollPad = Instance.new("UIPadding", scroll)
		scrollPad.PaddingTop = UDim.new(0, 6)
		scrollPad.PaddingBottom = UDim.new(0, 6)
		scrollPad.PaddingLeft = UDim.new(0, 6)
		scrollPad.PaddingRight = UDim.new(0, 10)
		local scrollList = Instance.new("UIListLayout", scroll)
		scrollList.Padding = UDim.new(0, 6)
		scrollList.SortOrder = Enum.SortOrder.LayoutOrder

		for i, entry in ipairs(list_) do
			local shown = colorsClose(entry.color, Color3.new(0, 0, 0)) and Color3.fromRGB(40, 40, 46) or entry.color
			local grad = entry.btnGradient or (entry.gradient and RAINBOW_SEQUENCE) or nil
			local bg, _, holder = makeGlassButton(scroll, i, string.upper(entry.name) .. suffix, shown, grad,
				function() onPick(entry) end)
			holder.Size = UDim2.new(1, 0, 0, 34)
			store[entry.name] = bg
		end
		return scroll
	end

	-- COLOUR PICKER: a colour box with a dot you drag around (saturation / brightness), a hue slider,
	-- and a hex box. onApply(color) is called while dragging and when you let go / press Apply.
	local function buildPicker(page, nextFn, onApply)
		sectionLabel(page, nextFn, "COLOUR PICKER")
		local h, s, v = 0, 1, 1
		local dragging = nil
		local lastApply = 0
		local settingText = false

		local sv = Instance.new("TextButton")
		sv.LayoutOrder = nextFn()
		sv.Size = UDim2.new(1, 0, 0, 110)
		sv.AutoButtonColor = false
		sv.Text = ""
		sv.BorderSizePixel = 0
		sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		sv.ClipsDescendants = true
		sv.Parent = page
		Instance.new("UICorner", sv).CornerRadius = UDim.new(0, 8)
		local svStroke = Instance.new("UIStroke")
		svStroke.Color = BUTTON_OUTLINE
		svStroke.Thickness = 1
		svStroke.Transparency = 0.3
		svStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		svStroke.Parent = sv

		local whiteLayer = Instance.new("Frame")
		whiteLayer.Size = UDim2.new(1, 0, 1, 0)
		whiteLayer.BackgroundColor3 = Color3.new(1, 1, 1)
		whiteLayer.BorderSizePixel = 0
		whiteLayer.ZIndex = 2
		whiteLayer.Parent = sv
		local wg = Instance.new("UIGradient")
		wg.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		wg.Parent = whiteLayer

		local blackLayer = Instance.new("Frame")
		blackLayer.Size = UDim2.new(1, 0, 1, 0)
		blackLayer.BackgroundColor3 = Color3.new(0, 0, 0)
		blackLayer.BorderSizePixel = 0
		blackLayer.ZIndex = 3
		blackLayer.Parent = sv
		local bg2 = Instance.new("UIGradient")
		bg2.Rotation = 90
		bg2.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		})
		bg2.Parent = blackLayer

		local dot = Instance.new("Frame")
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.Size = UDim2.new(0, 16, 0, 16)
		dot.BackgroundColor3 = Color3.new(1, 0, 0)
		dot.BorderSizePixel = 0
		dot.ZIndex = 5
		dot.Parent = sv
		Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
		local dotStroke = Instance.new("UIStroke")
		dotStroke.Color = Color3.new(1, 1, 1)
		dotStroke.Thickness = 2.5
		dotStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		dotStroke.Parent = dot

		local hue = Instance.new("TextButton")
		hue.LayoutOrder = nextFn()
		hue.Size = UDim2.new(1, 0, 0, 16)
		hue.AutoButtonColor = false
		hue.Text = ""
		hue.BorderSizePixel = 0
		hue.BackgroundColor3 = Color3.new(1, 1, 1)
		hue.Parent = page
		Instance.new("UICorner", hue).CornerRadius = UDim.new(0, 8)
		local hueKeys = {}
		for i = 0, 6 do
			table.insert(hueKeys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6 >= 1 and 0 or i / 6, 1, 1)))
		end
		local hg = Instance.new("UIGradient")
		hg.Color = ColorSequence.new(hueKeys)
		hg.Parent = hue
		local marker = Instance.new("Frame")
		marker.AnchorPoint = Vector2.new(0.5, 0.5)
		marker.Size = UDim2.new(0, 8, 1, 6)
		marker.BackgroundColor3 = Color3.new(1, 1, 1)
		marker.BorderSizePixel = 0
		marker.ZIndex = 3
		marker.Parent = hue
		Instance.new("UICorner", marker).CornerRadius = UDim.new(0, 4)
		local markerStroke = Instance.new("UIStroke")
		markerStroke.Color = Color3.new(0, 0, 0)
		markerStroke.Thickness = 1.5
		markerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		markerStroke.Parent = marker

		local hexRow = Instance.new("Frame")
		hexRow.LayoutOrder = nextFn()
		hexRow.Size = UDim2.new(1, 0, 0, 30)
		hexRow.BackgroundTransparency = 1
		hexRow.Parent = page
		local hexList = Instance.new("UIListLayout")
		hexList.FillDirection = Enum.FillDirection.Horizontal
		hexList.Padding = UDim.new(0, 6)
		hexList.SortOrder = Enum.SortOrder.LayoutOrder
		hexList.Parent = hexRow

		local swatch = Instance.new("Frame")
		swatch.LayoutOrder = 1
		swatch.Size = UDim2.new(0, 30, 1, 0)
		swatch.BackgroundColor3 = Color3.new(1, 0, 0)
		swatch.BorderSizePixel = 0
		swatch.Parent = hexRow
		Instance.new("UICorner", swatch).CornerRadius = UDim.new(0, 8)
		local swatchStroke = Instance.new("UIStroke")
		swatchStroke.Color = BUTTON_OUTLINE
		swatchStroke.Thickness = 1
		swatchStroke.Transparency = 0.3
		swatchStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		swatchStroke.Parent = swatch

		local hexBox = Instance.new("TextBox")
		hexBox.LayoutOrder = 2
		hexBox.Size = UDim2.new(1, -112, 1, 0)
		hexBox.BackgroundColor3 = Color3.fromRGB(20, 21, 28)
		hexBox.BackgroundTransparency = 0.1
		hexBox.BorderSizePixel = 0
		hexBox.ClearTextOnFocus = false
		hexBox.PlaceholderText = "#FF8800"
		hexBox.PlaceholderColor3 = Color3.fromRGB(130, 132, 148)
		hexBox.Text = "#FF0000"
		hexBox.Font = BUBBLY_FONT
		hexBox.TextSize = 14
		hexBox.TextColor3 = Color3.new(1, 1, 1)
		hexBox.TextXAlignment = Enum.TextXAlignment.Left
		hexBox.Parent = hexRow
		Instance.new("UICorner", hexBox).CornerRadius = UDim.new(0, 8)
		local hexPad = Instance.new("UIPadding", hexBox)
		hexPad.PaddingLeft = UDim.new(0, 8)
		local hexStroke = Instance.new("UIStroke")
		hexStroke.Color = BUTTON_OUTLINE
		hexStroke.Thickness = 1
		hexStroke.Transparency = 0.45
		hexStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		hexStroke.Parent = hexBox

		local function current()
			return Color3.fromHSV(h, s, v)
		end

		local function refresh(skipHex)
			local c = current()
			sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			dot.Position = UDim2.new(s, 0, 1 - v, 0)
			dot.BackgroundColor3 = c
			marker.Position = UDim2.new(h, 0, 0.5, 0)
			swatch.BackgroundColor3 = c
			if not skipHex then
				settingText = true
				hexBox.Text = string.format("#%02X%02X%02X",
					math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
				settingText = false
			end
		end

		local function commit(final)
			local now = os.clock()
			if final or now - lastApply > 0.15 then
				lastApply = now
				onApply(current())
			end
		end

		local function move(input)
			local p = pointerPos(input)
			if dragging == "sv" then
				s = math.clamp((p.X - sv.AbsolutePosition.X) / math.max(sv.AbsoluteSize.X, 1), 0, 1)
				v = 1 - math.clamp((p.Y - sv.AbsolutePosition.Y) / math.max(sv.AbsoluteSize.Y, 1), 0, 1)
			elseif dragging == "hue" then
				h = math.clamp((p.X - hue.AbsolutePosition.X) / math.max(hue.AbsoluteSize.X, 1), 0, 0.999)
			else
				return
			end
			refresh()
			commit(false)
		end

		local function isPress(input)
			return input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
		end
		local function startDrag(kind, input)
			dragging = kind
			pcall(function() frame.Draggable = false end) -- so the menu doesn't slide around while you pick
			move(input)
		end
		sv.InputBegan:Connect(function(input)
			if isPress(input) then startDrag("sv", input) end
		end)
		hue.InputBegan:Connect(function(input)
			if isPress(input) then startDrag("hue", input) end
		end)
		connect(UserInputService.InputChanged, function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch) then
				move(input)
			end
		end)
		connect(UserInputService.InputEnded, function(input)
			if dragging and isPress(input) then
				dragging = nil
				pcall(function() frame.Draggable = true end)
				commit(true)
			end
		end)

		local function applyHex()
			local c = parseHex(hexBox.Text)
			if not c then
				setNote("Invalid hex, use something like #FF8800")
				return
			end
			setNote("")
			h, s, v = Color3.toHSV(c)
			if h >= 1 then h = 0.999 end
			refresh(false)
			commit(true)
		end
		hexBox:GetPropertyChangedSignal("Text"):Connect(function()
			if settingText then return end
			local c = parseHex(hexBox.Text)
			if c then
				h, s, v = Color3.toHSV(c)
				if h >= 1 then h = 0.999 end
				refresh(true)
			end
		end)
		hexBox.FocusLost:Connect(function(enterPressed)
			if enterPressed then applyHex() end
		end)
		do
			local _, _, holder = makeGlassButton(hexRow, 3, "APPLY", Color3.fromRGB(0, 105, 190), nil, applyHex)
			holder.Size = UDim2.new(0, 70, 1, 0)
		end
		refresh(false)
	end

	-- PAGE 1: SCOPES
	local scopesPage, scopesNext = newPage("scopes")

	local row1 = featureRow(scopesPage, scopesNext)
	glassToggleBg, glassToggleBtn = (function()
		local bg, tb, holder = makeGlassButton(row1, 1, "SEE-THROUGH: OFF", Color3.fromRGB(78, 80, 92), nil, function()
			glassOverlay = not glassOverlay
			if selected then
				applyColor(selected)
			else
				updateStatus()
			end
		end)
		holder.Size = UDim2.new(0.5, -3, 1, 0)
		return bg, tb
	end)()
	trailToggleBg, trailToggleBtn = (function()
		local bg, tb, holder = makeGlassButton(row1, 2, "TRAIL: OFF", Color3.fromRGB(78, 80, 92), nil, function()
			trailOn = not trailOn
			if trailOn and not selected then
				setNote("Pick a scope first, the trail follows it.")
			elseif trailOn then
				setNote("")
			end
			refreshTrails()
			updateStatus()
		end)
		holder.Size = UDim2.new(0.5, -3, 1, 0)
		return bg, tb
	end)()

	local row2 = featureRow(scopesPage, scopesNext)
	do
		local bg, _, holder = makeGlassButton(row2, 1, string.upper(GLASS.name), Color3.fromRGB(100, 140, 170), nil,
			function() applyColor(GLASS) end, 0.15)
		holder.Size = UDim2.new(0.5, -3, 1, 0)
		buttons[GLASS.name] = bg
		local bg2, _, holder2 = makeGlassButton(row2, 2, string.upper(RAINBOW.name), Color3.new(1, 1, 1), RAINBOW_SEQUENCE,
			function() applyColor(RAINBOW) end)
		holder2.Size = UDim2.new(0.5, -3, 1, 0)
		buttons[RAINBOW.name] = bg2
	end

	local row3 = featureRow(scopesPage, scopesNext)
	do
		local _, _, holder = makeGlassButton(row3, 1, "RESET TO DEFAULT", Color3.fromRGB(84, 84, 100), nil, resetColor)
		holder.Size = UDim2.new(1, 0, 1, 0)
	end

	sectionLabel(scopesPage, scopesNext, "SCOPES")
	colorScroll(scopesPage, scopesNext, " SCOPE", applyColor, buttons, COLORS)

	buildPicker(scopesPage, scopesNext, function(c)
		applyColor({ name = "Custom", color = c })
	end)

	-- shared status lines + note + footer + credit (below the page)
	gunLabel = label(content, nextOrder(), "Gun: looking...", 11, Color3.fromRGB(190, 192, 208), 30)
	gunLabel.TextXAlignment = Enum.TextXAlignment.Left
	gunLabel.TextYAlignment = Enum.TextYAlignment.Top
	gunLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	gunLabel.TextStrokeTransparency = 0.5

	hipLabel = label(content, nextOrder(), "Hip gun: pick a colour first", 11, Color3.fromRGB(190, 192, 208), 14)
	hipLabel.TextXAlignment = Enum.TextXAlignment.Left
	hipLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	hipLabel.TextStrokeTransparency = 0.5

	noteLabel = label(content, nextOrder(), "", 11, Color3.fromRGB(150, 150, 170), 30)
	noteLabel.TextXAlignment = Enum.TextXAlignment.Left
	noteLabel.TextYAlignment = Enum.TextYAlignment.Top
	noteLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	noteLabel.TextStrokeTransparency = 0.5

	local footer = Instance.new("Frame")
	footer.LayoutOrder = nextOrder()
	footer.Size = UDim2.new(1, 0, 0, 18)
	footer.BackgroundTransparency = 1
	footer.Parent = content
	local hint = Instance.new("TextLabel")
	hint.Size = UDim2.new(0.6, 0, 1, 0)
	hint.BackgroundTransparency = 1
	hint.Font = BUBBLY_FONT
	hint.TextSize = 11
	hint.TextColor3 = Color3.fromRGB(150, 152, 168)
	hint.TextStrokeColor3 = Color3.new(0, 0, 0)
	hint.TextStrokeTransparency = 0.5
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.Text = "RightShift = hide / show"
	hint.Parent = footer
	local handle = Instance.new("TextLabel")
	handle.Size = UDim2.new(0.4, 0, 1, 0)
	handle.Position = UDim2.new(0.6, 0, 0, 0)
	handle.BackgroundTransparency = 1
	handle.Font = BUBBLY_FONT
	handle.TextSize = 15
	handle.TextColor3 = Color3.new(1, 1, 1)
	handle.TextStrokeColor3 = Color3.new(0, 0, 0)
	handle.TextStrokeTransparency = 0.3
	handle.TextXAlignment = Enum.TextXAlignment.Right
	handle.Text = ""
	handle.Parent = footer

	local credit = Instance.new("TextLabel")
	credit.LayoutOrder = nextOrder()
	credit.Size = UDim2.new(1, 0, 0, 26)
	credit.BackgroundTransparency = 1
	credit.Font = BUBBLY_FONT
	credit.TextSize = 17
	credit.TextColor3 = Color3.new(1, 1, 1)
	credit.TextStrokeColor3 = Color3.new(0, 0, 0)
	credit.TextStrokeTransparency = 0.3
	credit.Text = "made by: FearVesta"
	credit.Parent = content

	-- SIDE TAB BUTTONS
	local tabBgs = {}
	local function showTab(name)
		for key, page in pairs(pages) do
			page.Visible = (key == name)
		end
		for key, bg in pairs(tabBgs) do
			setOutline(bg, key == name)
		end
		setNote("")
	end
	local tabDefs = {
		{ "scopes", "SCOPES" },
	}
	for i, def in ipairs(tabDefs) do
		local key = def[1]
		local bg, tb, holder = makeGlassButton(sidebar, i, def[2], Color3.fromRGB(84, 84, 100), nil, function()
			showTab(key)
		end)
		holder.Size = UDim2.new(1, 0, 0, 44)
		tb.TextWrapped = true
		tabBgs[key] = bg
	end
	showTab("scopes")

	local confirm = Instance.new("Frame")
	confirm.Name = "ConfirmClose"
	confirm.Size = UDim2.new(1, 0, 1, 0)
	confirm.BackgroundColor3 = Color3.fromRGB(2, 2, 5)
	confirm.BackgroundTransparency = 0.3
	confirm.BorderSizePixel = 0
	confirm.Active = true
	confirm.Visible = false
	confirm.ZIndex = 20
	confirm.Parent = frame
	Instance.new("UICorner", confirm).CornerRadius = UDim.new(0, 16)

	local confirmText = Instance.new("TextLabel")
	confirmText.AnchorPoint = Vector2.new(0.5, 0.5)
	confirmText.Position = UDim2.new(0.5, 0, 0.35, 0)
	confirmText.Size = UDim2.new(1, -24, 0, 50)
	confirmText.BackgroundTransparency = 1
	confirmText.Font = BUBBLY_FONT
	confirmText.TextSize = 20
	confirmText.TextWrapped = true
	confirmText.TextColor3 = Color3.new(1, 1, 1)
	confirmText.TextStrokeColor3 = Color3.new(0, 0, 0)
	confirmText.TextStrokeTransparency = 0.3
	confirmText.Text = "ARE YOU SURE?"
	confirmText.ZIndex = 21
	confirmText.Parent = confirm

	local function confirmButton(text, xScale, bg)
		local b = Instance.new("TextButton")
		b.AnchorPoint = Vector2.new(0.5, 0.5)
		b.Position = UDim2.new(xScale, 0, 0.7, 0)
		b.Size = UDim2.new(0.3, 0, 0, 34)
		b.BackgroundColor3 = bg
		b.BackgroundTransparency = 0.25
		b.BorderSizePixel = 0
		photoText(b, 15)
		b.Text = text
		b.ZIndex = 21
		b.Parent = confirm
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 9)
		local s = Instance.new("UIStroke")
		s.Color = BUTTON_OUTLINE
		s.Transparency = 0.45
		s.Thickness = 1
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		s.Parent = b
		return b
	end
	local yesBtn = confirmButton("YES", 0.3, Color3.fromRGB(125, 30, 30))
	local noBtn = confirmButton("NO", 0.7, Color3.fromRGB(38, 40, 54))

	-- the YES / NO cover must not stop the menu from moving, so it drags the menu itself
	local confirmDrag = nil
	local function isPressInput(input)
		return input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
	end
	confirm.InputBegan:Connect(function(input)
		if isPressInput(input) then
			confirmDrag = { start = pointerPos(input), pos = frame.Position }
		end
	end)
	connect(UserInputService.InputChanged, function(input)
		if confirmDrag and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local d = pointerPos(input) - confirmDrag.start
			local p0 = confirmDrag.pos
			frame.Position = UDim2.new(p0.X.Scale, p0.X.Offset + d.X, p0.Y.Scale, p0.Y.Offset + d.Y)
		end
	end)
	connect(UserInputService.InputEnded, function(input)
		if confirmDrag and isPressInput(input) then confirmDrag = nil end
	end)

	local minimised = false
	local imageId = loadIconImage()
	local icon
	if imageId then
		icon = Instance.new("ImageButton")
		icon.Image = imageId
		icon.ScaleType = Enum.ScaleType.Stretch
		icon.BackgroundColor3 = Color3.new(0, 0, 0)
		icon.AutoButtonColor = false
	else
		icon = Instance.new("TextButton")
		icon.AutoButtonColor = false
		icon.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		icon.Font = BUBBLY_FONT
		icon.Text = "vesta"
		icon.TextSize = 22
		icon.TextColor3 = Color3.fromRGB(215, 218, 228)
		icon.TextStrokeColor3 = Color3.fromRGB(90, 94, 110)
		icon.TextStrokeTransparency = 0.4
	end
	icon.Name = "MiniIcon"
	icon.Size = UDim2.new(0, ICON_SIZE, 0, math.floor(ICON_SIZE * ICON_ASPECT))
	icon.Position = frame.Position
	icon.BorderSizePixel = 0
	icon.Active = true
	icon.Visible = false
	pcall(function() icon.Draggable = true end)
	icon.Parent = gui
	Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 12)
	local iconStroke = Instance.new("UIStroke")
	iconStroke.Color = MENU_OUTLINE
	iconStroke.Thickness = 1
	iconStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	iconStroke.Parent = icon

	minBtn.MouseButton1Click:Connect(function()
		minimised = true
		confirm.Visible = false
		icon.Position = frame.Position
		frame.Visible = false
		icon.Visible = true
	end)

	local pressedAt
	icon.MouseButton1Down:Connect(function()
		pressedAt = icon.AbsolutePosition
	end)
	icon.MouseButton1Click:Connect(function()
		if pressedAt and (icon.AbsolutePosition - pressedAt).Magnitude > 6 then return end
		minimised = false
		frame.Position = icon.Position
		icon.Visible = false
		frame.Visible = true
	end)

	closeBtn.MouseButton1Click:Connect(function()
		confirm.Visible = true
	end)
	noBtn.MouseButton1Click:Connect(function()
		confirm.Visible = false
	end)
	yesBtn.MouseButton1Click:Connect(function()
		if env.VoidscopeRecolorCleanup then
			pcall(env.VoidscopeRecolorCleanup)
		elseif gui then
			gui:Destroy()
		end
	end)

	connect(UserInputService.InputBegan, function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.RightShift then
			local target = minimised and icon or frame
			target.Visible = not target.Visible
		end
	end)
end

local built, buildErr = pcall(buildGui)
if not built then
	warn("[Voidscope Recolor] the menu failed to build: " .. tostring(buildErr))
end

if next(hooked) then
	setGunStatus("Gun: found")
else
	setGunStatus("Gun: not found yet (equip it)")
	task.delay(2, function()
		if not next(hooked) then
			setGunStatus("Gun not found. Tools seen: " .. toolNames() .. " (add the right name to GUN_NAMES)")
		end
	end)
end

-- INSTANT SWITCHING: at start, every skin picture is downloaded into memory at the same time and made ready on
-- every gun part, so clicking a skin only swaps it in. A click made before a download finishes keeps the current
-- look (no flat colour) and swaps the moment that picture is ready.
task.spawn(function()
	SkinKit.onReady = function(key)
		for tool in pairs(hooked) do
			if tool.Parent then SkinKit.prebuild(tool) end
		end
		local w = SkinKit.waiting[key]
		SkinKit.waiting[key] = nil
		if w and selected and selected.skin == key then
			for mp in pairs(w) do
				if typeof(mp) == "Instance" and mp.Parent then pcall(tintMesh, mp, colorFor(mp)) end
			end
			setNote("")
		end
	end
	-- every skin downloads at the same time
	for key in pairs(SKIN_TEXTURES) do SkinKit.load(key) end
	local waited = 0
	while waited < 30 do
		local pending = false
		for key in pairs(SKIN_TEXTURES) do
			if SkinKit.img[key] == nil then pending = true end
		end
		if not pending then break end
		task.wait(0.1)
		waited += 0.1
	end
	for key in pairs(SKIN_TEXTURES) do
		if SkinKit.img[key] == false then
			warn("[Voidscope Recolor] the '" .. key .. "' picture couldn't be loaded. Save it as '" .. key .. ".png' in your executor's workspace folder.")
		end
	end
	-- show each skin for a moment on a tiny hidden copy of a gun part so the graphics card has them ready
	local src
	for tool in pairs(hooked) do
		if tool.Parent then
			for _, d in ipairs(tool:GetDescendants()) do
				local okt, tex = pcall(function() return d:IsA("MeshPart") and d.TextureID or "" end)
				if okt and tex ~= "" and (not src or d.Size.Magnitude > src.Size.Magnitude) then src = d end
			end
		end
	end
	if not src then return end
	pcall(function()
		local cam = Workspace.CurrentCamera
		local dummy = src:Clone()
		for _, c in ipairs(dummy:GetChildren()) do c:Destroy() end
		dummy.Anchored = true
		dummy.CanCollide = false
		dummy.CanQuery = false
		dummy.CanTouch = false
		dummy.Size = src.Size * 0.15
		dummy.Parent = cam
		for key in pairs(SKIN_TEXTURES) do
			if cam then dummy.CFrame = cam.CFrame * CFrame.new(0, 0, -3) end
			local sa = Instance.new("SurfaceAppearance")
			if SkinKit.fill(sa, key) then
				sa.Parent = dummy
				task.wait(0.1)
			end
			sa:Destroy()
		end
		dummy:Destroy()
	end)
end)

local pre = env.VoidscopeColor
if type(pre) == "string" then
	if string.lower(pre) == "chroma" then
		applyColor(RAINBOW)
	elseif string.lower(pre) == "glass" then
		applyColor(GLASS)
	else
		for _, entry in ipairs(COLORS) do
			if string.lower(entry.name) == string.lower(pre) then
				applyColor(entry)
				break
			end
		end
	end
end

-- closing the script ONLY removes the menu and stops the live watching. Nothing is reset, so every colour,
-- texture, glass and see-through effect you applied stays on the gun.
env.VoidscopeRecolorCleanup = function()
	for _, c in ipairs(conns) do
		pcall(function() c:Disconnect() end)
	end
	if gui then gui:Destroy() end
	env.VoidscopeRecolorCleanup = nil
end

print("[Voidscope Recolor] loaded")
env.VestaLoadDone = true -- tells the loading screen it can fade out
