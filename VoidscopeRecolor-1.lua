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
local BUBBLY_FONT = Enum.Font.GothamBold   -- menu font (try Enum.Font.GothamBlack for even bolder)
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
	-- the colour scopes
	red     = "74514059806540",
	green   = "87308630293771",
	orange  = "129129543552647",
	yellow  = "109406328791418",
	blue    = "133436489369053",
	purple  = "82454330103213",
	cyan    = "79146514446474",
	pink    = "103464770625429",
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
-- If both are empty, a black-and-white orb drawn in code (matching the picture) is used.
local MINI_ICON_ASSET = ""
local ICON_SIZE = 112
local ICON_URL = ""
local ICON_PNG_B64 = [=[
iVBORw0KGgoAAAANSUhEUgAAAKAAAAAvBAMAAACWB9wTAAAAMFBMVEXW2NmprK+JjI9wc3ZbXmBMT1E7PkErLjAhIyYUFhkJCgwD
AwQBAQEBAAAAAAEAAACYFXYNAAAJtElEQVR42n2Xb2wcx3nGf7N7MuREupvZU2IbCandO1IGCktcHmkHNhJbkZWgQmFIkWUnBlrU
CFK4QL+kcJIiH+rUcFIURdMaDVA0MRQnBdqg+mPLQVDDFkVSVp0AEY+3Et3AkXm7S8rph1rcmSXlhrVud/rhjqSi/nk+LGbmfd9n
33lmdnZnnn1nZnb2nm+7tltyrf1uzbZwN93suCG7zLEX5rGc9Zlgs9ieYwrtb7++ie3VBh2lKnL7XM3u6KQRn7RxBzTkYJ6c27Tp
6ZYpcjhgLffZx9a83FyBU/mObduTTtR3mH20CS1sFXefAFHNJqZEsXkpvcmjXkk2RIbkZSe5FJ9HNy5Q2iN+cOj/JL1CZ10FeU4A
bHUUoU0dwNjxWx8KbmVNHtDMXDgPj6Xu7K9dBuV8q1zIy7ucPsNnPNEnnvEXTlNE75kzFAlSxdvFZNVwZ7GqtNMDnfl/KjuzCJkX
lJvZA4jiuJQhdFTWcQKsYIuAwWNWmuLYAt5YQtZAJMd+Apc0BeTBngWzEuRmEYaWwNQMVY95+NSi/OM58FaRBt84JcR/M1RFkFjF
RpU3oNPCSGz7FBn1ZI9zEZuEpBTOrI3x9rpK8l0svgbtsrUhvfOMH9OSgGKrG6+Pld8mn4MSoJpjMAU2Q3WX4R8BW/gk8Ynsn7E
KIm7rPb5GBN3Z7e5JR6mKXOxsA2qxdFNNNmcoJ0KfmRTBqzHsAJGR8tSYmbslj1Q5Ajg0r8pO/0n9Cgqf7Mr0iJwyHxMHjNzzfC
7QVpPCHzpkV6YXMCnB9aGrWWYRK8VnzNxQPxOZpH+YE+Cp1Sn03E3+Qs1jA/xFKCvLrvuG/RT8Om13DKwv6AQ4u5txUPJrFC6bm
rDcmhHi1k4ACCgrSXiWTqbwIlPGKuJKsM7FUWHtWBvPzA7e29E4mQPMw3sC/Yu8qS7XmXyUAAQ6ooC4oTdhvP/Z6JiiQtZHc+NwE
Wt6fWXJw3tGeW33KpjIQdXqQ46K1iRvTCHlFzCHuEWRmwcwqh8M9uYWUzvlFKVNxf3Z/OHyF9kEODXiB/J6xTMV6fjZW6VVBZ7f2
N2uCs+J4pS9GL0cCvIJl5U6wsdTg50W5SG6xeIb7ZOcnYAJllEZ0v2RIIHCcg1a+f4XSdPv/XPkODwd27IJxH1WcJQ6Y3EIbVKNO
z5C+/5pZ0WsXkQyFgOLR2wmX2XsEPPPVLL3TGlgFfb3xTTLM4YPXTLn8xmuNbSF5FpWLfQnl9bz/Uy++q4vCxd+ntRUd5qTKzXj
CdFfE0K7bBnccAASXPAobwqOoNYAE8Zp5I1qaGWNTnbvK0lWrQVEfj3uI3L4cNfVX6WRqy/9B+Sfy+PJTjYpGZpw2cvycrhDSAy
dv2NXRNz9h1bPbsDSJoJRBY1jRhf9x7OwqZXL8+2X4Qgf9T6NCBuS8C2sOcgyANKvK9PpDWM4Hyw5F7oPRkH4bNwQ0WTO8PWeC0
ZiSMjXE5K2tDmmEmWU3AivO3dlIqlZjxO2kKEpEhbHoFSnh+Gu8FV97j8nOn7YHwLfNGWXoo6tg35ruYC9W9xnEdfVGJXXPpqqD
H8FW8uqLNFHHXxMNuFAzgI+wVXnJoYwdxVD6uvrJ3NJeAgGYcRfCZyjcNl+OpZn6Irgo8nSEP0qg7iGSKROCYfSWb4kwbSpu8Zh
XBMJ+Jpug7gkWAi9FlB6Y4nO3MC1elg8gBzC5g+Uf8vS+Aa+JsuA0Wj28F53+XvtDrIAd50fZGo3Sg3O+6a2gSiPA7OShCDiRZx
IvtBbHnZsAE8Z+1HFLQ6YP7ALEPMrKGPJQFvTnZBWgcv85n9bzY9xmS3MFeYT3tOWNcFnN8hbDlPjX/dRb7ZlGxxmsDdTRz+C5U
EWWJpTWT7Y/X/15SX/uFRK+I1Y2fi4W/W52wFRMX9jmmsHv2d+WSUX5kj0NKWa/YKVfV1hD32OrnI7gh/vh6FI79mRVh1iJzRA
MXz3oFW8XW2jcZP39dL2wn5p96yFqa7rBpq9yvf0dSgfdhU9yVD9+kqz2zEVWm6B0GKG2lKgB2OEmFX9GIvsuQL1tAiP4yrwwq
Wr25gAa1TQV0aFr3LGLSCmDKp+1TM5eZJCOxODD3IK++gv6l4y6npWWVZGwyv3Fhoa85eKHzO1h0H1u2a5GhAAAAAElFTkSuQmCC
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

local function removeTrail(tool)
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

local function ensureTrail(key, getParts, gripFn)
	local made = trails[key]
	if made and made.trail and made.trail.Parent and made.a0 and made.a0.Parent and made.a1 and made.a1.Parent then
		if not made.trail.Enabled then made.trail.Enabled = true end
		trailLook(made.trail)
		return
	end
	local parts = getParts()
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
	for key, parts in pairs(hipGroups()) do
		ensureTrail(key, function() return parts end, handleGrip)
	end
end

local lastTrailCheck = 0
connect(RunService.Heartbeat, function()
	if not (trailOn and selected) then return end
	local now = os.clock()
	if now - lastTrailCheck < 0.4 then return end
	lastTrailCheck = now
	refreshTrails()
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
	l.Font = Enum.Font.Gotham
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
		local name = "VestaIcon.png"
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
	frame.Position = UDim2.new(0, 20, 0.15, 0)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BackgroundTransparency = 0
	frame.BorderSizePixel = 0
	frame.Active = true
	pcall(function() frame.Draggable = true end)
	frame.Parent = gui
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
		frame.Size = UDim2.new(0, WIDTH + TABW, 0, math.max(content.AbsoluteSize.Y, 200))
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
	hint.Font = Enum.Font.Gotham
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
	icon.Size = UDim2.new(0, ICON_SIZE, 0, math.floor(ICON_SIZE * 0.295))
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
