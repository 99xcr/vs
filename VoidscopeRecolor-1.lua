print("[Voidscope Recolor] loading...")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
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

-- EDITABLE IMAGE SPEED SETTINGS
local MAX_TEX = 512              -- sharper; built once in the background so it doesn't hurt switching (384 = lighter)
local BUDGET_BACKGROUND = 0.006  -- seconds of each frame used while quietly pre-building textures
local BUDGET_WAITING = 0.03      -- if you click a style that isn't ready, it gets most of the frame
local PREBUILD_DELAY = 0         -- start building every style the moment the gun is found
local MARBLE_SCALE = 1.6         -- Diamond / Ruby pattern size: higher = smaller, busier marbling, lower = bigger swirls

-- button shine for the special scopes (gold bands / icy diamond facets / ruby)
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

local COLORS = {
	{ name = "Red",        color = Color3.fromRGB(255, 0, 0) },
	{ name = "Green",      color = Color3.fromRGB(0, 255, 0) },
	{ name = "Black",      color = Color3.fromRGB(0, 0, 0) },
	{ name = "Orange",     color = Color3.fromRGB(255, 128, 0) },
	{ name = "Yellow",     color = Color3.fromRGB(255, 255, 0) },
	{ name = "Blue",       color = Color3.fromRGB(0, 100, 255) },
	{ name = "Purple",     color = Color3.fromRGB(160, 32, 240) },
	{ name = "Cyan",       color = Color3.fromRGB(0, 255, 255) },
	-- PINK: pastel pink body with the gun's detail painted white (editable image texture)
	{ name = "Pink",       color = Color3.fromRGB(255, 190, 215), mode = "texture", texStyle = "pink" },
	{ name = "Rainbow",    color = Color3.fromRGB(255, 60, 200), mode = "texture", texStyle = "rainbow", gradient = true, rainbowFx = true },
	-- GOLD: polished shiny metal, marbled bands of light and deep gold, warm glints
	{ name = "Gold",       color = Color3.fromRGB(255, 200, 40), mode = "texture", texStyle = "gold", reflectance = 0.45,
		btnGradient = GOLD_SEQ, effectSeq = GOLD_SEQ },
	-- DIAMOND: icy crystal, mirror shine, white sparkle
	{ name = "Diamond",    color = Color3.fromRGB(185, 242, 255), mode = "texture", texStyle = "diamond", reflectance = 0.2,
		btnGradient = DIAMOND_SEQ, effectSeq = DIAMOND_SEQ },
	-- RUBY: deep red gemstone with marbled swirls and bright glints
	{ name = "Ruby",       color = Color3.fromRGB(190, 15, 40), mode = "texture", texStyle = "ruby", reflectance = 0.12,
		btnGradient = RUBY_SEQ, effectSeq = RUBY_SEQ },
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
33lmdnZebB+92G6is9EotsaS3s02bZOBQ2fgl9hep2OttVhri6Rnk5vCuzaxxUa/GNB0rR2wJNYWtkjsTehtNbH/Szq3oNNJ+kQ9
W1hru9Ymdu5/uiXWJv8HYa//2EhibtOYWNuxtkgW56Y2E74FDn1EOAUbcPsPf9CdACcCwIeQcrmwRs8bhoEUgAKigfMGYUgaDawD
WwGk6UZIyGZ0smhMZmzSdQZeICC0abpJWEJZ9hMoNoJxU/D7gxvoN5tkidVpuQbQTEn7LGJoGCidTdYhQUoqIB1kssU2EKOEgpj2
g6dOfPdUZoqt16Ql4DolOA5EUJZ22a7i4zspfnpTUmW6oSlcBpcG9lBbz8+dMaQQl33fZdK+UqkDYYnjRCsRRKSl/xuTxG51ohBS
KPYm3XP556w1GfgOUMY+FAUsDwaciEIaWwLGYWvBNha87GsQbkhw1Agl5RHZGojlNNqmbazBBxxK0t65JW3jWncv+1IgHFCUA/Gc
jZwjAHFeINUyuBHxxnuLkKRs950d/MmH2tdtas0CznDRhmKm9Is2Di7FuRKgvbl32iUaak5QCcP26sAwMTajk8wt0xRhKee7HTJh
DgZeCyimzUf2z49d2D+lQRzj3MPdZnuiNwtoxfUj0Z7fe0kFd2TfScUxepWzpr8TDx/f5QvlICzJxSs/9rN2/oWjQd3ntfklq6//
y+wDfyoAjfPNhaHdztcTACG1fff54xcjz//10P48W3rC/9mSBLB6dXddNVSLCuQn2DetDYVWKto7f6pp487vvPzE5Ycl2HbS+ZZ/
4ScLu7UBMmz5FxdWBLl5pGNN9eTJR5uBkmC6He47Jh2oQG/i3GkAnWvqhVc7a8A8Me2cBbQ1V563218Jp/ozI3/2+ytIyfALWPPV
t45X5xYVomYyQ5wlI2np/ln6W9fS60bdvu66h+784Cfz3RSOPfRmun19fX0dQy979On3f5pv70t1Vz4xr8Tt0lHKu+uy73X/i/X1
X5t1sV6pNe+0fKiCz42x70rw08ZY5Z12FinWjqHrrUCjbazXbtyfaC/o86lAmAZIpZQStdTYoP8VaWtX90XPRa20QrHgd16VQtau
Dv0w/EB3nUZ2x/lDS589arXBWlMN/rpmpDcyZtDIeIc3NIMQSmDtjlXv8SVAUZ40Zf6fs3V8Bze8rbx8BFEvWFg7baKWUnv3POMF
KcaalU/L+sEFlJBDWmfamIk3n1neLZQyodZrl8bvnq1lcdxuzx6Q6rp0Ia5QLodvL9/xivLCC8EDXx1yAr3qPPXH9drcRw7C4o58
1PU+/YbS5Z1fmdVW24k3wuqzQe3dqGWkCaq71+6tGVG76Btn3KuG6WoFxy+P/uCaUHL8nz71PdFpIoNtpyBvflyDuSECWh9cVdbx
jufBRx9v/2H0lTaqmrv3leapqPf1ucQoaO7Ak+NOOuxXAGehrFSVsh+02kNzB60JJmeEXauupIgr8yqoUm9SPRPCnPjnh8NCZELt
fOuJQBLdU/nzZSmUFB/+tlC7YcihAjBxRez/d6HGfjg270jtOEOvSvvaF6ex+Y2lz/jv1FeXn9TZWYPXsKfMuDVC7ZRGQjj75o/3
xyityhmv0T+bKgAce6b+0wPywHceSO+1VrlLuTS9vxQSLZqtJafxy/UzRz/bnJrvdvc8fXEEpMAUQO++r42dNIAGpayBPmHcuFyr
lb7Zc8/f1KXOH33XyT3P8T0LqB2/Mg/1xGsrB0eb3anOe9/+1AsfMkLurFngX5+7cXzyM8oaGyeO7J9GFcCh+U66L1f2sV3SJtuM
EqJh7t2XGMDbeenzlV2PN/Xrqtn4/Ii2azMvzimBMbD4iSgbPdi6lnvU5ZrCDjJMfeTRb/jnD1M/EMf60NLBzA10dmY3VmBn9hwh
DD26eqXLhPaKd34gJFboIhr7UdUErORokY39m7yxMWW/dNIV2/gFWKu187v/cOT7nlf9RfObQO/lux+JJjqTjwFcPLvTyForHRLy
hjDuRPuSacg4/nsJZ9/2MJXCLZ0KpPjDJkx3ADrT26cbkVKquNg7aXML8sUvFZMnDIDnrOTko7mU5OXUiXx0VbWC84fnNMwt3qH+
w4rUx+n/efYezWuR0To1Ry+NCCOVeyPSSZbF3alX77/wd6fmzrXjJLnyDYld8h1pzVAw9fpTbrPl3fVSprVZPONjjPAjKuCnvkMq
q29Us1i7f/TckGur+2eefnYKNNqujf3ymf3TEjSlK8miMJdad7i2+pAKFAf+9pS2pqgoiymRg0WJ/bVAfzxeSfjo8426//bYGXv9
8AxowBnuVU8rK6TSlS/JctHkVG0cawhvayjMg51E4zwOuoLrUwEfGoQfnlYzhRG/P38/NGbOPBmn0oiGp4Lh05XD//hFT6Ks0MTT
d29b39mJUV4r2TMsslIYlDcyLtG7Fva6gy8FcNh1LTe79ppHXLYVd72ABqlUI5AHVp3JhgIEMltcGrmnd+YkRjVHxt9dfuXJeF7j
NccVGm3cresczYb/ZW1vmx1dgL3jV3VXaxASbM24PlZbrbvtkzO7fqXqpa+tkLXacnH7904nIAJlszhKd0K6mSH7j/9sPPnYWg2o
7AqvPjidS6TWXVvdI5w2oNG4j2WfdMOxS996ieyib1uzE7FCKZt1ycQ2wK8AqQ+pfzm5Nmnbx6olcG92/P0/SawBIasvHvr5pNYG
hWiUU7c90mR031tfS4R8Pdw+/v6PZoxGE2TT4W+7xI3K5kXQfVSlYlIKC3Awn5/SBpRQ1UnZapv+iWL5xJffgvtMfM4ouW28+tj0
XxmMBJvFI7WVaB+icEj9/lXtvWQmrAfC84FiOmFw2/2D6GMvD2QRo588/zAU7tkExOhwo50lG9elhc/lSk4gbH/KQLHwnkEEdZ/U
Ly+Hm+K2xzdXjmIhBChcgEI45abphFBBExCWTcZuR4Ka2ODZuCGGW20mgNRPKXW/UzoDk1271lC73QHhAHPC1HI5bl3SYScKgcIt
00bfmDKMveoDRNLfyqyPrkxxFP7mPkwBcqSQODDvO2UIKQLHKYGC2MdxXL8EytDfLB76OkQEKVL4PrBVSdm57lxvrmP/XyS3Vl1J
P6Dbtb3OLbWeTazt9orfjLylPN2q3ZKby8fOTSH/DbseQ+Or0ehDAAAAAElFTkSuQmCC
]=]

local env = (getgenv and getgenv()) or _G
if env.VoidscopeRecolorCleanup then
	pcall(env.VoidscopeRecolorCleanup)
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
local saCache = setmetatable({}, { __mode = "k" })   -- meshPart -> { tint = SA, rainbow = SA, gold = SA, ... } (one per style, swapped by re-parenting)
local imgOf = setmetatable({}, { __mode = "k" })     -- SurfaceAppearance -> the edited image it was built from
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
local TEX_STYLES = {
	rainbow = function(stats)
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
	end,
}

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
-- PINK: dark parts of the gun = pastel pink, the gun's detail / bright parts fade up to pure white
local PINK_R, PINK_G, PINK_B = buildRamp({
	{ 244, 160, 196 }, { 255, 184, 212 }, { 255, 208, 228 }, { 255, 235, 244 }, { 255, 255, 255 },
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

local PREBUILD_STYLES = { "rainbow", "gold", "diamond", "ruby", "pink" }

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

-- smooth value noise (tileable), used to make the Diamond / Ruby marbling
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
		-- marble fields, worked out once per texture and shared by Diamond / Ruby
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

local tintMesh
local jobs = {}
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
				src, why = loadSource(job.tex, budget)
				if src then sources[job.tex] = src end
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
				warn("[Voidscope Recolor] " .. job.style .. " texture edit failed: " .. tostring(why))
			end
			local waiting = entry.waiters
			entry.waiters = {}
			if next(waiting) then
				setNote(image and "" or ("Texture edit failed: " .. tostring(why)))
			end
			for w in pairs(waiting) do
				if selected and selected.mode == "texture" and w.Parent then
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
	if entry and entry.state == "failed" and os.clock() - (entry.at or 0) > 2 then
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

	if selected ~= nil and selected.mode == "texture" then
		local okTex, tex = pcall(function() return mp.TextureID end)
		if not okTex or type(tex) ~= "string" or tex == "" then return end
		local style = selected.texStyle or "rainbow"
		if selected.reflectance then -- gold / diamond / ruby: a little real metal shine on top of the painted texture
			set(mp, "Material", Enum.Material.Metal)
			set(mp, "Reflectance", selected.reflectance)
			chromed[mp] = true
		end
		local entry = ensureTexture(style, tex)
		if entry and entry.state == "done" then
			if applyEdited(mp, entry.image, style) then
				removeOverlay(mp)
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
			removeSurface(mp)
			setNote("Texture edit failed: " .. tostring(entry.why))
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

-- builds every texture style for the gun in the background, so picking a scope is instant
local function prebuildTextures(tool)
	for _, d in ipairs(tool:GetDescendants()) do
		if d:IsA("MeshPart") then
			local ok, tex = pcall(function() return d.TextureID end)
			if ok and type(tex) == "string" and tex ~= "" then
				for _, style in ipairs(PREBUILD_STYLES) do
					ensureTexture(style, tex)
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

local function findTip(allParts, gripPos)
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
	local learned = learnedTip[tool]
	if learned and learned.part and learned.part.Parent then
		ref, tip, side, how = learned.part, learned.pos, Vector3.new(TRAIL_WIDTH / 2, 0, 0), "where your shot leaves the gun"
	else
		ref, tip, side, how = findTip(allParts, gripPos)
	end
	if not ref then return end
	print("[Voidscope Recolor] trail tip = " .. how .. " (on part '" .. ref.Name .. "')")
	local a0 = Instance.new("Attachment")
	a0.Name = "VSTrail"
	a0.Position = tip + side
	a0.Parent = ref
	local a1 = Instance.new("Attachment")
	a1.Name = "VSTrail"
	a1.Position = tip - side
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
		-- texture styles paint the whole look themselves, so the part itself must not add a colour tint on top
		local c = (selected and selected.mode == "texture") and Color3.new(1, 1, 1) or color
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
	if made and made.trail and made.trail.Parent then
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
	if now - lastTrailCheck < 1.5 then return end
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

local function isGun(inst)
	if not inst:IsA("Tool") then return false end
	local n = string.lower(inst.Name)
	return n == "gun" or string.find(n, "voidscope", 1, true) ~= nil
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
	task.delay(PREBUILD_DELAY, prebuildTextures, tool) -- builds all texture styles quietly in the background
	local effects = paintGun(tool)
	if selected then
		setGunStatus("Gun: found, " .. effects .. " beam part(s)")
		refreshHip()
	else
		setGunStatus("Gun: found")
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
		local stroke = bg:FindFirstChildOfClass("UIStroke")
		if stroke then
			local on = (selected ~= nil and selected.name == name)
			stroke.Color = on and BUTTON_SELECTED or BUTTON_OUTLINE
			stroke.Thickness = on and 2.5 or 1
			stroke.Transparency = on and 0 or 0.45
		end
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
		setGunStatus("Gun: not found yet (equip it)")
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

-- ============================================================
-- SHADERS: glossy lighting look (client side only)
-- bloom glow + sharp environment reflections + colour grading + optional shiny surfaces
-- ============================================================
local Lighting = game:GetService("Lighting")
local shaderOn = false
local shaderPreset = "Glossy"
local glossLevel = 3           -- 1..5, higher = glossier
local shinySurfaces = true     -- adds a shine (Reflectance) to map parts, can cost some FPS on huge maps
local shaderFx = {}
local lightingSaved = nil
local reflSaved = setmetatable({}, { __mode = "k" })
local shinyRun = 0
local shinyConn = nil
local shaderUIRefresh = nil
local lastShaderCheck = 0

local SHADER_ORDER = { "Glossy", "Warm", "Cool", "Neon" }
local SHADER_PRESETS = {
	Glossy = { tint = Color3.fromRGB(255, 252, 255), sat = 0.22, contrast = 0.16, bright = 0.01, threshold = 0.8,
		ambient = Color3.fromRGB(78, 82, 100), outdoor = Color3.fromRGB(120, 126, 150),
		top = Color3.fromRGB(255, 246, 235), bottom = Color3.fromRGB(130, 160, 215) },
	Warm = { tint = Color3.fromRGB(255, 238, 215), sat = 0.25, contrast = 0.14, bright = 0.02, threshold = 0.8,
		ambient = Color3.fromRGB(105, 85, 75), outdoor = Color3.fromRGB(150, 120, 100),
		top = Color3.fromRGB(255, 214, 160), bottom = Color3.fromRGB(190, 120, 90) },
	Cool = { tint = Color3.fromRGB(225, 240, 255), sat = 0.18, contrast = 0.16, bright = 0.0, threshold = 0.78,
		ambient = Color3.fromRGB(60, 78, 110), outdoor = Color3.fromRGB(95, 125, 170),
		top = Color3.fromRGB(205, 230, 255), bottom = Color3.fromRGB(90, 130, 220) },
	Neon = { tint = Color3.fromRGB(245, 225, 255), sat = 0.4, contrast = 0.2, bright = 0.0, threshold = 0.7,
		ambient = Color3.fromRGB(70, 50, 105), outdoor = Color3.fromRGB(110, 80, 160),
		top = Color3.fromRGB(255, 160, 235), bottom = Color3.fromRGB(70, 200, 255) },
}

local function setLighting(prop, value)
	pcall(function() Lighting[prop] = value end)
end

local function setProps(obj, props)
	for k, v in pairs(props) do
		pcall(function() obj[k] = v end)
	end
end

local function saveLighting()
	if lightingSaved then return end
	lightingSaved = {}
	local names = { "Brightness", "ExposureCompensation", "EnvironmentSpecularScale", "EnvironmentDiffuseScale",
		"Ambient", "OutdoorAmbient", "ColorShift_Top", "ColorShift_Bottom", "ShadowSoftness" }
	for _, name in ipairs(names) do
		local ok, v = pcall(function() return Lighting[name] end)
		if ok then lightingSaved[name] = v end
	end
end

local function getFx(class, name)
	local fx = shaderFx[name]
	if not fx or fx.Parent ~= Lighting then
		if fx then pcall(function() fx:Destroy() end) end
		fx = Instance.new(class)
		fx.Name = "VS_" .. name
		fx.Parent = Lighting
		shaderFx[name] = fx
	end
	return fx
end

-- shiny surfaces
local function shinyTarget(part)
	if part:IsA("Terrain") then return false end
	if part.Transparency >= 0.95 then return false end
	if part:FindFirstAncestorOfClass("Tool") then return false end
	if part:FindFirstChild("VSSurface") or part:FindFirstChildOfClass("SurfaceAppearance") then return false end
	if characterOf(part) then return false end
	return true
end

local function shinyOne(part)
	if not part.Parent then return end
	local okT, target = pcall(shinyTarget, part)
	if not (okT and target) then return end
	local want = math.clamp(glossLevel * 0.06, 0.06, 0.3)
	if reflSaved[part] == nil then reflSaved[part] = part.Reflectance end
	pcall(function() part.Reflectance = math.max(reflSaved[part], want) end)
end

local function stopShiny()
	shinyRun += 1
	if shinyConn then
		shinyConn:Disconnect()
		shinyConn = nil
	end
	for part, original in pairs(reflSaved) do
		pcall(function() part.Reflectance = original end)
		reflSaved[part] = nil
	end
end

local function startShiny()
	shinyRun += 1
	local run = shinyRun
	if shinyConn then
		shinyConn:Disconnect()
		shinyConn = nil
	end
	shinyConn = Workspace.DescendantAdded:Connect(function(d)
		if shinyRun == run and d:IsA("BasePart") then
			task.defer(shinyOne, d)
		end
	end)
	task.spawn(function()
		local n = 0
		for _, d in ipairs(Workspace:GetDescendants()) do
			if shinyRun ~= run then return end
			if d:IsA("BasePart") then
				shinyOne(d)
				n += 1
				if n % 300 == 0 then task.wait() end
			end
		end
	end)
end

local function removeShader()
	for name, fx in pairs(shaderFx) do
		pcall(function() fx:Destroy() end)
		shaderFx[name] = nil
	end
	stopShiny()
	if lightingSaved then
		for prop, v in pairs(lightingSaved) do
			setLighting(prop, v)
		end
		lightingSaved = nil
	end
end

local function applyLook()
	saveLighting()
	local p = SHADER_PRESETS[shaderPreset] or SHADER_PRESETS.Glossy
	local lvl = glossLevel
	local k = lvl / 3
	local base = lightingSaved or {}

	-- sharp, strong reflections of the sky on everything
	setLighting("EnvironmentSpecularScale", math.clamp(0.4 + lvl * 0.15, 0, 1))
	setLighting("EnvironmentDiffuseScale", 0.55)
	setLighting("ExposureCompensation", (base.ExposureCompensation or 0) + 0.12 * k)
	setLighting("Ambient", p.ambient)
	setLighting("OutdoorAmbient", p.outdoor)
	setLighting("ColorShift_Top", p.top)
	setLighting("ColorShift_Bottom", p.bottom)
	setLighting("ShadowSoftness", 0.15)

	-- rich, punchy colours
	setProps(getFx("ColorCorrectionEffect", "Color"), {
		Contrast = p.contrast * k, Saturation = p.sat * k, Brightness = p.bright, TintColor = p.tint,
	})
	-- the glossy glow on bright spots
	setProps(getFx("BloomEffect", "Bloom"), {
		Intensity = 0.3 + 0.3 * lvl, Size = 22 + 5 * lvl, Threshold = p.threshold,
	})
	-- light shafts from the sun / bright lights
	setProps(getFx("SunRaysEffect", "Rays"), {
		Intensity = 0.06 + 0.03 * lvl, Spread = 0.75,
	})
end

local function applyShader()
	if not shaderOn then
		removeShader()
	else
		applyLook()
		if shinySurfaces then startShiny() else stopShiny() end
	end
	if shaderUIRefresh then shaderUIRefresh() end
end

-- keeps the effects alive if the game removes / resets them
connect(RunService.Heartbeat, function()
	if not shaderOn then return end
	local now = os.clock()
	if now - lastShaderCheck < 2 then return end
	lastShaderCheck = now
	applyLook()
end)

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

	local WIDTH = 290

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
	frame.Size = UDim2.new(0, WIDTH, 0, 400)
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

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, 0, 0, 0)
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
		frame.Size = UDim2.new(0, WIDTH, 0, math.max(content.AbsoluteSize.Y, 40))
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

	local function featureRow()
		local row = Instance.new("Frame")
		row.LayoutOrder = nextOrder()
		row.Size = UDim2.new(1, 0, 0, 30)
		row.BackgroundTransparency = 1
		row.Parent = content
		local rl = Instance.new("UIListLayout")
		rl.FillDirection = Enum.FillDirection.Horizontal
		rl.Padding = UDim.new(0, 6)
		rl.SortOrder = Enum.SortOrder.LayoutOrder
		rl.Parent = row
		return row
	end
	local row1 = featureRow()
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

	local row2 = featureRow()
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

	local row3 = featureRow()
	do
		local _, _, holder = makeGlassButton(row3, 1, "RESET TO DEFAULT", Color3.fromRGB(84, 84, 100), nil, resetColor)
		holder.Size = UDim2.new(1, 0, 1, 0)
	end

	local scopesLabel = label(content, nextOrder(), "SCOPES", 14, Color3.new(1, 1, 1), 16)
	scopesLabel.Font = BUBBLY_FONT
	scopesLabel.TextXAlignment = Enum.TextXAlignment.Left
	scopesLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	scopesLabel.TextStrokeTransparency = 0.3

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Scopes"
	scroll.LayoutOrder = nextOrder()
	scroll.Size = UDim2.new(1, 0, 0, 175)
	scroll.BackgroundColor3 = Color3.new(0, 0, 0)
	scroll.BackgroundTransparency = 0.3
	scroll.BorderSizePixel = 0
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = Color3.fromRGB(150, 154, 170)
	scroll.Parent = content
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

	for i, entry in ipairs(COLORS) do
		local shown = colorsClose(entry.color, Color3.new(0, 0, 0)) and Color3.fromRGB(40, 40, 46) or entry.color
		local grad = entry.btnGradient or (entry.gradient and RAINBOW_SEQUENCE) or nil
		local bg, _, holder = makeGlassButton(scroll, i, string.upper(entry.name) .. "SCOPE", shown, grad,
			function() applyColor(entry) end)
		holder.Size = UDim2.new(1, 0, 0, 34)
		buttons[entry.name] = bg
	end

	noteLabel = label(content, nextOrder(), "", 11, Color3.fromRGB(150, 150, 170), 14)
	noteLabel.TextXAlignment = Enum.TextXAlignment.Left
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

	-- ===== SIDE TABS + SHADERS PANEL =====
	local scopeItems = {}
	for _, c in ipairs(content:GetChildren()) do
		if c:IsA("GuiObject") and c ~= header then
			table.insert(scopeItems, c)
		end
	end

	local shadersPanel = Instance.new("Frame")
	shadersPanel.Name = "ShadersPanel"
	shadersPanel.LayoutOrder = 50
	shadersPanel.Size = UDim2.new(1, 0, 0, 0)
	shadersPanel.AutomaticSize = Enum.AutomaticSize.Y
	shadersPanel.BackgroundTransparency = 1
	shadersPanel.Visible = false
	shadersPanel.Parent = content
	local panelList = Instance.new("UIListLayout")
	panelList.Padding = UDim.new(0, 6)
	panelList.SortOrder = Enum.SortOrder.LayoutOrder
	panelList.Parent = shadersPanel

	local function panelRow(rowOrder)
		local row = Instance.new("Frame")
		row.LayoutOrder = rowOrder
		row.Size = UDim2.new(1, 0, 0, 30)
		row.BackgroundTransparency = 1
		row.Parent = shadersPanel
		local rl = Instance.new("UIListLayout")
		rl.FillDirection = Enum.FillDirection.Horizontal
		rl.Padding = UDim.new(0, 6)
		rl.SortOrder = Enum.SortOrder.LayoutOrder
		rl.Parent = row
		return row
	end

	local function panelLabel(rowOrder, text)
		local l = label(shadersPanel, rowOrder, text, 14, Color3.new(1, 1, 1), 16)
		l.Font = BUBBLY_FONT
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextStrokeColor3 = Color3.new(0, 0, 0)
		l.TextStrokeTransparency = 0.3
		return l
	end

	panelLabel(1, "SHADERS")

	local shToggleBg, shToggleBtn
	do
		local row = panelRow(2)
		local bg, tb, holder = makeGlassButton(row, 1, "SHADERS: OFF", Color3.fromRGB(78, 80, 92), nil, function()
			shaderOn = not shaderOn
			applyShader()
		end)
		holder.Size = UDim2.new(1, 0, 1, 0)
		shToggleBg, shToggleBtn = bg, tb
	end

	panelLabel(3, "STYLE")
	local presetColors = {
		Glossy = Color3.fromRGB(100, 140, 170),
		Warm = Color3.fromRGB(190, 120, 80),
		Cool = Color3.fromRGB(70, 110, 200),
		Neon = Color3.fromRGB(150, 60, 200),
	}
	local presetBgs = {}
	for r = 0, 1 do
		local row = panelRow(4 + r)
		for c = 1, 2 do
			local name = SHADER_ORDER[r * 2 + c]
			local bg, _, holder = makeGlassButton(row, c, string.upper(name), presetColors[name], nil, function()
				shaderPreset = name
				shaderOn = true
				applyShader()
			end)
			holder.Size = UDim2.new(0.5, -3, 1, 0)
			presetBgs[name] = bg
		end
	end

	panelLabel(6, "GLOSS LEVEL")
	local glossValue
	do
		local row = panelRow(7)
		local _, _, minusHolder = makeGlassButton(row, 1, "-", Color3.fromRGB(84, 84, 100), nil, function()
			glossLevel = math.max(1, glossLevel - 1)
			if shaderOn then applyShader() elseif shaderUIRefresh then shaderUIRefresh() end
		end)
		minusHolder.Size = UDim2.new(0.25, -4, 1, 0)
		glossValue = Instance.new("TextLabel")
		glossValue.LayoutOrder = 2
		glossValue.Size = UDim2.new(0.5, -4, 1, 0)
		glossValue.BackgroundTransparency = 1
		photoText(glossValue, 16)
		glossValue.Text = glossLevel .. " / 5"
		glossValue.Parent = row
		local _, _, plusHolder = makeGlassButton(row, 3, "+", Color3.fromRGB(84, 84, 100), nil, function()
			glossLevel = math.min(5, glossLevel + 1)
			if shaderOn then applyShader() elseif shaderUIRefresh then shaderUIRefresh() end
		end)
		plusHolder.Size = UDim2.new(0.25, -4, 1, 0)
	end

	local shinyBg, shinyBtn
	do
		local row = panelRow(8)
		local bg, tb, holder = makeGlassButton(row, 1, "SHINY SURFACES: ON", Color3.fromRGB(78, 80, 92), nil, function()
			shinySurfaces = not shinySurfaces
			if shaderOn then applyShader() elseif shaderUIRefresh then shaderUIRefresh() end
		end)
		holder.Size = UDim2.new(1, 0, 1, 0)
		shinyBg, shinyBtn = bg, tb
	end

	local shNote = label(shadersPanel, 9, "Glossy = bloom glow + sharp reflections + shiny surfaces. Turn SHINY SURFACES off if it lags.", 11, Color3.fromRGB(150, 150, 170), 30)
	shNote.TextXAlignment = Enum.TextXAlignment.Left
	shNote.TextStrokeColor3 = Color3.new(0, 0, 0)
	shNote.TextStrokeTransparency = 0.5

	do
		local row = panelRow(10)
		local _, _, holder = makeGlassButton(row, 1, "TURN OFF SHADERS", Color3.fromRGB(84, 84, 100), nil, function()
			shaderOn = false
			applyShader()
		end)
		holder.Size = UDim2.new(1, 0, 1, 0)
	end

	shaderUIRefresh = function()
		shToggleBtn.Text = shaderOn and "SHADERS: ON" or "SHADERS: OFF"
		shToggleBg.BackgroundColor3 = shaderOn and Color3.fromRGB(0, 105, 190) or Color3.fromRGB(78, 80, 92)
		for name, bg in pairs(presetBgs) do
			local stroke = bg:FindFirstChildOfClass("UIStroke")
			if stroke then
				local on = shaderOn and shaderPreset == name
				stroke.Color = on and BUTTON_SELECTED or BUTTON_OUTLINE
				stroke.Thickness = on and 2.5 or 1
				stroke.Transparency = on and 0 or 0.45
			end
		end
		glossValue.Text = glossLevel .. " / 5"
		shinyBtn.Text = shinySurfaces and "SHINY SURFACES: ON" or "SHINY SURFACES: OFF"
		shinyBg.BackgroundColor3 = shinySurfaces and Color3.fromRGB(0, 105, 190) or Color3.fromRGB(78, 80, 92)
	end
	shaderUIRefresh()

	-- side tabs (stuck to the right edge of the menu, they move with it)
	local tabBgs = {}
	local function setTab(name)
		for _, item in ipairs(scopeItems) do
			item.Visible = (name == "scopes")
		end
		shadersPanel.Visible = (name == "shaders")
		for tabName, bg in pairs(tabBgs) do
			local stroke = bg:FindFirstChildOfClass("UIStroke")
			if stroke then
				local on = (tabName == name)
				stroke.Color = on and BUTTON_SELECTED or BUTTON_OUTLINE
				stroke.Thickness = on and 2.5 or 1
				stroke.Transparency = on and 0 or 0.45
			end
		end
	end
	local function makeTab(name, text, y)
		local bg, _, holder = makeGlassButton(frame, 0, text, Color3.fromRGB(84, 84, 100), nil, function()
			setTab(name)
		end)
		holder.Size = UDim2.new(0, 78, 0, 34)
		holder.Position = UDim2.new(1, 4, 0, y)
		tabBgs[name] = bg
	end
	makeTab("scopes", "SCOPES", 52)
	makeTab("shaders", "SHADERS", 92)
	setTab("scopes")

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
end

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

env.VoidscopeRecolorCleanup = function()
	for _, c in ipairs(conns) do
		pcall(function() c:Disconnect() end)
	end
	pcall(removeShader)
	restoreAll()
	if gui then gui:Destroy() end
	env.VoidscopeRecolorCleanup = nil
end

print("[Voidscope Recolor] loaded")
