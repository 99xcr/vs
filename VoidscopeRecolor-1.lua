print("[Voidscope Recolor] loading...")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local LocalPlayer = Players.LocalPlayer

local SHOT_WINDOW = 1.0          -- seconds after you fire during which new effects count as your shot
local SHOT_RADIUS = 30           -- studs from you within which a new effect counts as your shot
local OVERLAY_TRANSPARENCY = 0.6 -- only used if the texture tint isn't supported (colour wash)
local BUBBLY_FONT = Enum.Font.GothamBold   -- menu font (try Enum.Font.GothamBlack for even bolder)
local MENU_OUTLINE = Color3.fromRGB(70, 74, 88)
local BUTTON_OUTLINE = Color3.fromRGB(120, 125, 142)  -- glass rim around every button
local BUTTON_SELECTED = Color3.fromRGB(0, 150, 235)

-- TRAIL SETTINGS
local TRAIL_LIFETIME = 0.8   -- how long the trail lingers (seconds)
local TRAIL_WIDTH = 0.4      -- how thick the trail is at the tip (studs)
local TRAIL_FLIP = false     -- if the trail comes off the wrong end of the gun, set this to true

-- EDITABLE IMAGE SPEED SETTINGS (only used by the built-in backup textures, see SKIN_TEXTURES below)
local MAX_TEX = 512              -- sharper; built once in the background so it doesn't hurt switching (384 = lighter)
local BUDGET_BACKGROUND = 0.006  -- seconds of each frame used while quietly pre-building textures
local BUDGET_WAITING = 0.03      -- if you click a style that isn't ready, it gets most of the frame
local PREBUILD_DELAY = 0         -- start building every style the moment the gun is found
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
---------------------------------------------------------------------
local SKIN_TEXTURES = {
	gold    = "",
	pink    = "",
	diamond = "",
	black   = "",
	ruby    = "",
	beast   = "",
	white   = "",
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

-- "skin" = which picture from SKIN_TEXTURES the colour uses. mode / texStyle = the older built-in look, used as the
-- backup when that skin's picture isn't filled in above.
local COLORS = {
	{ name = "Red",        color = Color3.fromRGB(255, 0, 0) },
	{ name = "Green",      color = Color3.fromRGB(0, 255, 0) },
	{ name = "Black",      color = Color3.fromRGB(0, 0, 0), skin = "black" },
	{ name = "Orange",     color = Color3.fromRGB(255, 128, 0) },
	{ name = "Yellow",     color = Color3.fromRGB(255, 255, 0) },
	{ name = "Blue",       color = Color3.fromRGB(0, 100, 255) },
	{ name = "Purple",     color = Color3.fromRGB(160, 32, 240) },
	{ name = "Cyan",       color = Color3.fromRGB(0, 255, 255) },
	{ name = "Pink",       color = Color3.fromRGB(255, 190, 215), mode = "texture", texStyle = "pink", skin = "pink" },
	{ name = "White",      color = Color3.fromRGB(238, 238, 244), mode = "texture", texStyle = "white", skin = "white" },
	{ name = "Rainbow",    color = Color3.fromRGB(255, 60, 200), mode = "texture", texStyle = "rainbow", gradient = true, rainbowFx = true },
	{ name = "Gold",       color = Color3.fromRGB(255, 200, 40), mode = "texture", texStyle = "gold", skin = "gold", reflectance = 0.45,
		btnGradient = GOLD_SEQ, effectSeq = GOLD_SEQ },
	{ name = "Diamond",    color = Color3.fromRGB(185, 242, 255), mode = "texture", texStyle = "diamond", skin = "diamond", reflectance = 0.2,
		btnGradient = DIAMOND_SEQ, effectSeq = DIAMOND_SEQ },
	{ name = "Ruby",       color = Color3.fromRGB(190, 15, 40), mode = "texture", texStyle = "ruby", skin = "ruby", reflectance = 0.12,
		btnGradient = RUBY_SEQ, effectSeq = RUBY_SEQ },
	{ name = "Beast",      color = Color3.fromRGB(150, 60, 230), mode = "texture", texStyle = "beast", skin = "beast", reflectance = 0.12,
		btnGradient = BEAST_SEQ, effectSeq = BEAST_SEQ },
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
-- If both are empty, a black-and-white orb drawn in code (matching the picture) is used.
local MINI_ICON_ASSET = ""
local ICON_SIZE = 112
local ICON_URL = ""
local ICON_PNG_B64 = [=[
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
local function resolveSkin(key)
	if not key then return nil end
	local cached = skinCache[key]
	if cached ~= nil then return cached or nil end
	local result = false
	local raw = SKIN_TEXTURES[key]
	if type(raw) == "string" then
		raw = (string.gsub(raw, "^%s+", ""))
		raw = (string.gsub(raw, "%s+$", ""))
		local toAsset = getcustomasset or getsynasset
		if raw == "" then
			result = false
		elseif string.find(raw, "^%d+$") then
			result = "rbxassetid://" .. raw
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
local imgOf = setmetatable({}, { __mode = "k" })     -- SurfaceAppearance -> the edited image it was built from
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
local function purgeStray(mp)
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
	for _, o in pairs(cache)
