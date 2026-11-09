
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
local TRAIL_WIDTH = 0.12     -- how thick the trail is (studs), smaller = thinner
local TRAIL_END = "back"     -- "back" = comes off the very back of the gun, "front" = off the tip
local TRAIL_FLIP = false     -- if the trail comes off the wrong end of the gun, set this to true
local TRAIL_DROP = 1.2       -- how far to move the trail DOWN from where it is now (studs). Bigger = lower, 0 = old position

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
	ruby    = "94500665581850",
	white   = "109366061167898",
	rainbow = "79921047565141",
	colourscope = "116830015801415",
	beast   = "78396157128775",
	kitty   = "125707015473446",
	galaxy  = "105612826347881",
	red     = "107521248572145",
	orange  = "81186357661641",
	yellow  = "99924122176025",
	green   = "76639960602606",
	blue    = "95581576115992",
	purple  = "136303338873406",
	pink    = "75102863575405",
	cyan    = "128247760025980",
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
	{ name = "Red",        color = Color3.fromRGB(255, 0, 0), skin = "red" },
	{ name = "Green",      color = Color3.fromRGB(0, 255, 0), skin = "green" },
	{ name = "Black",      color = Color3.fromRGB(0, 0, 0) },
	{ name = "Orange",     color = Color3.fromRGB(255, 128, 0), skin = "orange" },
	{ name = "Yellow",     color = Color3.fromRGB(255, 255, 0), skin = "yellow" },
	{ name = "Blue",       color = Color3.fromRGB(0, 100, 255), skin = "blue" },
	{ name = "Purple",     color = Color3.fromRGB(160, 32, 240), skin = "purple" },
	{ name = "Cyan",       color = Color3.fromRGB(0, 255, 255), skin = "cyan" },
	{ name = "Pink",       color = Color3.fromRGB(255, 190, 215), mode = "texture", texStyle = "pink", skin = "pink" },
	{ name = "White",      color = Color3.fromRGB(238, 238, 244), mode = "texture", texStyle = "white", skin = "white" },
	{ name = "Rainbow",    color = Color3.fromRGB(255, 60, 200), mode = "texture", texStyle = "rainbow", skin = "rainbow", gradient = true, rainbowFx = true },
	{ name = "Colourscope", color = Color3.fromRGB(255, 90, 210), mode = "texture", texStyle = "rainbow", skin = "colourscope", gradient = true, rainbowFx = true },
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
local ICON_ASPECT = 0.326      -- height / width of the logo picture
local ICON_URL = ""
local ICON_PNG_B64 = [=[
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
hTIo4UoIhPV6vUQiufbaa4uKir7++us//OEPkBCCigiHJ9xf+HPhFIwj3IfD0NLSkpKSYjabu7u709LSKisrR44cef78eZCb9+zZ
k5iYmJqaihCOIkNWrgxxO72cTicMfHBwsFQqHT9+fGxsbFtbW0xMTEtLi0ajMZvNISEho0aNOnz4MPwAe2MikcjpdI4ZMyY8PNxs
Nsvl8sLCwueee+6vf/3rrFmzMjIy9u7d+/zzz/f09DQ3NxcXF0PIymQyAUSkc0LeDGZOJpM1Nzdv3749LCxsypQp+/fvDw0NbW5u
pgzFx8dn5cqVc+fO1Wg0QqGwpqamrq6OchNwc9ra2sBGmT17dlRU1NatW7u6ukAEVygUISEh0CQhZQPev09bo62Mp46rlUgkOp3O
4/F8++23UVFRPB6vpqYGT52tfZIPb2trMxqN9fX1IPuUl5cfOnQINjE0NDQsLKyqqurYsWMA8pRKpa+vLyQuaWQogla4PkJ/cLUi
kSgkJOT06dONjY1arXbZsmXY02ijQ25CO55o0Eg8gcKyYCpb2mcFg2DsLBaLyWQymUxWq9XHx2fJkiXvv//+TTfddObMGa1W29bW
ZrPZxGJxT0/Phg0bqqurP//8856eHqPRWF5enpubW19f/9e//jUnJ8doNHIgHranoeffX7jIKVOm+Pr6vvXWWyDlJiYmhoaGEhMa
GAVbuIQ+jtVqtVgsLS0tTU1NnZ2dUVFRTzzxRHp6+pIlSxYuXFhXV9fQ0EBzx2gF8PSnT59+5513vvzyy/n5+dHR0WFhYQEBAVhS
Dr/BezYOq/VD9osN7nC1aP6yWq07d+48e/YsCOKkpIw8hnqDWMKU3W7HTQUHB4tEop9//nnu3LnwDTg+ELfvU1mYE0AI+jQ33t+y
3YN1dXWRkZEw1SEhIS0tLRaLJTQ0tL6+PiAgQK/Xnz17NiEhAc3lHMlLKmrAm7FeyNfXt7S0FHIt69ate+aZZxITEw8ePAh1yNra
2oyMjLNnz4KHThcDpUi1Wj1r1iyj0RgYGLh3794lS5aUlpaWl5fv37//hx9+WLp0qVQqbWlpKS0tra+vR0UZvoVCfXIpZF9CQkJe
e+21tra2u+++G3Xo8PDwmpoaEIK7u7vHjh27YsUKdBva7fb6+npw23DSUK9xOBzNzc3XXnvthAkTXn/9dZFIlJCQUF1djbCorq4O
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
GtRZKPkvLS2Fto7JZEKSyPKDCTEh4hxbeYmIiFAoFHV1dWg4aG5u9u5R6k8ghuV500AI+hZ/lFV6MpvNra2tSAmBWZBYAsxWeXk5
zZDJyMjIy8vbtWsXTt22bdvWr1+PSg3hzQRWUvWQZtglJCRUVFSghWLGjBmojaKjBfVQVsWR5cpyZgq1tbWdOnWKJJ9hVthpC95E
hHPnzkF8jlW2YTG+gTuoOERktguP3glpCnBTP/nkE6RaFoult7cX0kuEIsEboSLhcDhIUQBZS0dHB1w7gnrOrJ7BTsUY5EAVwA02
m62iokKtVkOsQyqVNjQ0JCcnnz59Oj4+PigoaMOGDZ9++mlzc7NIJGJDaJKAYrc1jhaKL8XFxci058yZs2XLlry8vM7OTpT3kNEk
JCSgCauzs3Pp0qUKhaKrq6uystLlck2ZMuXmm29+9dVXzWYzeHc2mw2toRztCHYeDjs4JTU1taKiYtu2bTfddFNMTMzf/vY3nU5X
Xl5OG8vtdi9dulQkEtXX18+bNw9wCTujEWfGbrfHxcU5nc6KigpwI0+fPg1OkL+/f2FhodVqxb4nz8nJnDkPj8xTc3NzU1MTukAg
NgTRGYlEQg13qJFDfYLYOkSMAHTqdDqFQiE0roABdXZ21tTUaLVaBE3AR1h2MmF5ON56vX7MmDGADOLi4sAMKCwszMnJQWrM0gjZ
EI+UW9jUg9MxdEGOPtAiMohstYSKPoAqsM1wzW1tbfAodLTYGjyhJDRvR61WnzlzBp0fCxYsOHToEMqOzc3NDQ0NVCVgAxDOZD52
gCraKhGx9qlYymlhxXZl5+INAJhwmH7ea8L+Flym2+1G7chqtUIwE/sEdRIyynjuEFFCSZRIGKDgdXV1wbvjE7yn+PV38YKLHWLJ
aibo9XroQHd0dMhkMpQnwsLCzp8/P2XKlH379u3bt2/mzJlGoxGtJVRDYasPlH7j2aNgnJeXB9b1Pffcc8sttwQEBACfRnPWnDlz
vvrqK4/HM2HChNmzZ7e0tPj5+e3fv/+pp5565ZVXAE/u3r3797//PQxTcXFxS0sLBgHROaQMmeQLMPNIo9E899xzYWFh11xzze7d
u10ul0KhQA6IbaFSqebPn//DDz9cf/31UCmDSaUmGlCEent7R44cefz4cfziV1991dLSYjQaBQJBXV0d4TskA8J2n3IMEMvmwmRu
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
AAAAAElFTkSuQmCC
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
local SKIN_OF_STYLE = { gold = "gold", diamond = "diamond", ruby = "ruby", beast = "beast", pink = "pink", white = "white", rainbow = "rainbow" }

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
		-- light version: no big editable images in memory, the picture is just preloaded so it is ready to swap in
		local content = resolveSkin(key)
		local result = false
		if content then
			result = content
			pcall(function()
				local probe = Instance.new("SurfaceAppearance")
				probe.ColorMap = content
				ContentProvider:PreloadAsync({ probe })
				probe:Destroy()
			end)
		end
		SkinKit.img[key] = result
		SkinKit.loading[key] = nil
		if SkinKit.onReady then pcall(SkinKit.onReady, key) end
	end)
end

-- puts the picture into a SurfaceAppearance, returns what it used (or nil)
function SkinKit.fill(sa, key)
	local content = SkinKit.img[key] or resolveSkin(key)
	if content then
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
function SkinKit.prebuild(tool, onlyKey)
	for _, d in ipairs(tool:GetDescendants()) do
		if d:IsA("MeshPart") then
			local ok, tex = pcall(function() return d.TextureID end)
			if ok and type(tex) == "string" and tex ~= "" then
				for key in pairs(SKIN_TEXTURES) do
					if (not onlyKey or key == onlyKey) and SkinKit.img[key] ~= nil then pcall(SkinKit.make, d, key) end
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
	if now - lastTrailCheck < 1.5 then return end
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
	if not (writefile and toAsset) then
		warn("[Voidscope Recolor] this executor can't show the minimised logo (needs writefile + getcustomasset). Put an image id in MINI_ICON_ASSET instead.")
		return nil
	end
	local ok, asset = pcall(function()
		local name = "VestaIcon3.png"
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
	warn("[Voidscope Recolor] couldn't load the minimised logo (" .. tostring(asset) .. "). Put an image id in MINI_ICON_ASSET instead.")
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
			if tool.Parent then SkinKit.prebuild(tool, key) end
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
