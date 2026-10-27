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

local COLORS = {
	{ name = "Red",        color = Color3.fromRGB(255, 0, 0) },
	{ name = "Green",      color = Color3.fromRGB(0, 255, 0) },
	{ name = "Black",      color = Color3.fromRGB(0, 0, 0) },
	{ name = "Orange",     color = Color3.fromRGB(255, 128, 0) },
	{ name = "Yellow",     color = Color3.fromRGB(255, 255, 0) },
	{ name = "Blue",       color = Color3.fromRGB(0, 100, 255) },
	{ name = "Purple",     color = Color3.fromRGB(160, 32, 240) },
	{ name = "Cyan",       color = Color3.fromRGB(0, 255, 255) },
	-- flat pastel pink: a plain colour tint, so the gun keeps its own texture detail
	{ name = "Pink",       color = Color3.fromRGB(255, 190, 215) },
	{ name = "Rainbow",    color = Color3.fromRGB(255, 60, 200), mode = "texture", texStyle = "rainbow", gradient = true, rainbowFx = true },
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
local surfaces = setmetatable({}, { __mode = "k" })  -- meshPart -> SurfaceAppearance we added (the tint)
local overlays = setmetatable({}, { __mode = "k" })  -- meshPart -> Highlight we added (colour wash)
local watchedTargets = setmetatable({}, { __mode = "k" })
local rainbowT = setmetatable({}, { __mode = "k" })       -- part -> 0..1, where it sits along the gun (rainbow / pearl)
local glassed = setmetatable({}, { __mode = "k" })       -- parts currently showing our glass look
local glassGuarded = setmetatable({}, { __mode = "k" })  -- parts we already watch for the game making them solid again
local glassOverlay = false  -- the "See-through" switch: keep the glass look on any colour
local trailOn = false       -- the "Trail" switch: coloured trail off the tip of the gun
local trails = setmetatable({}, { __mode = "k" })        -- tool -> { trail, a0, a1 } (the trail we added)
local unglassing = false
local chromed = setmetatable({}, { __mode = "k" })       -- meshes currently showing the chrome look
local flatSpread = setmetatable({}, { __mode = "k" })    -- parts of a gun that is a single piece (no end-to-end spread to colour)
local sheens = setmetatable({}, { __mode = "k" })        -- gun part -> the two glow lights we added to it (only if GLASS_SHEEN is on)
local lastSpin = 0
local hipQueued = false
local gui, gunLabel, hipLabel, statusLabel, noteLabel
local glassToggleBtn, glassToggleBg, trailToggleBtn, trailToggleBg
local buttons = {}

-- ===== EXTRAS: knives / bombs, custom colour, finishes, shot fx =====
local VS = {}
-- Which tools get recoloured. Tool names are matched with spaces / symbols removed and lower-cased, so
-- "Gold Bomb", "GoldBomb" and "gold_bomb" are the same thing. The first entry that matches wins.
-- If one of your items is not found, the console prints the exact tool name: add a word for it in `match`.
--   trail      = this item may get the coloured trail
--   shotWindow = seconds after you use it during which new effects near you count as "its shot"
VS.ITEMS = {
	{ kind = "prankbomb", label = "PRANK BOMB", match = { "prank" },                  trail = false, shotWindow = 4 },
	{ kind = "goldbomb",  label = "GOLD BOMB",  match = { "goldbomb", "goldenbomb" }, trail = false, shotWindow = 4 },
	{ kind = "knife",     label = "KNIFE",      match = { "knife", "dagger" },        trail = true,  shotWindow = 1.5 },
	{ kind = "gun",       label = "GUN",        match = { "voidscope" }, exact = { "gun" }, trail = true, shotWindow = SHOT_WINDOW },
}
VS.ORDER = { "gun", "knife", "goldbomb", "prankbomb" } -- order of the menu switches
VS.BYKIND = {}
for _, def in ipairs(VS.ITEMS) do VS.BYKIND[def.kind] = def end
VS.itemOn = { gun = true, knife = true, goldbomb = true, prankbomb = true } -- the per-item switches
VS.itemFound = {}   -- kind -> true once a tool of that kind has been seen
VS.warned = {}      -- tool names we already told you about
VS.shotKind = "gun" -- which item the current shot window belongs to
VS.shotFxOn = true  -- the "Shot FX" switch
-- Finishes (cycle with the FINISH button). Add your own: { name = "X", material = Enum.Material.Y, reflectance = 0.2 }
VS.FINISHES = {
	{ name = "DEFAULT" },
	{ name = "METAL", material = Enum.Material.Metal,         reflectance = 0.35 },
	{ name = "MATTE", material = Enum.Material.Plastic,       reflectance = 0 },
	{ name = "SATIN", material = Enum.Material.SmoothPlastic, reflectance = 0.12 },
}
VS.finishIdx = 1
VS.finished = setmetatable({}, { __mode = "k" }) -- parts currently showing a finish
-- Custom colour picker state
VS.custom = { h = 0.58, s = 0.9, v = 1 }
VS.override = {}  -- kind -> colour chosen on that item's own page (nil = it follows the ALL page)
VS.tab = "all"    -- which page of the menu is open: "all" or an item kind
VS.curKind = nil  -- the item being painted right now
VS.hipKind = setmetatable({}, { __mode = "k" }) -- copies on your hip / back -> the item they belong to
VS.ui = { allOnly = {}, itemOnly = {}, advanced = {} }
VS.moreOpen = false -- the MORE OPTIONS section
VS.tabBtn, VS.tabTb = {}, {}
VS.ON, VS.OFF = Color3.fromRGB(0, 105, 190), Color3.fromRGB(78, 80, 92)
VS.GREEN, VS.RED = Color3.fromRGB(45, 165, 80), Color3.fromRGB(175, 55, 55)
VS.toggleBtn = {}


function VS.parseColor(text)
	text = string.gsub(text or "", "%s", "")
	local hex = string.match(text, "^#?(%x%x%x%x%x%x)$")
	if not hex then
		local short = string.match(text, "^#?(%x%x%x)$")
		if short then
			hex = string.sub(short, 1, 1) .. string.sub(short, 1, 1) .. string.sub(short, 2, 2)
				.. string.sub(short, 2, 2) .. string.sub(short, 3, 3) .. string.sub(short, 3, 3)
		end
	end
	if hex then
		return Color3.fromRGB(tonumber(string.sub(hex, 1, 2), 16), tonumber(string.sub(hex, 3, 4), 16), tonumber(string.sub(hex, 5, 6), 16))
	end
	local r, g, b = string.match(text, "^(%d+)[,;](%d+)[,;](%d+)$")
	if r then
		return Color3.fromRGB(math.clamp(tonumber(r), 0, 255), math.clamp(tonumber(g), 0, 255), math.clamp(tonumber(b), 0, 255))
	end
	return nil
end

-- what kind of item a tool is ("gun" / "knife" / "goldbomb" / "prankbomb"), or nil
function VS.kindOfTool(inst)
	if not inst:IsA("Tool") then return nil end
	local n = string.lower((string.gsub(inst.Name, "[^%w]", "")))
	for _, def in ipairs(VS.ITEMS) do
		for _, word in ipairs(def.match) do
			if string.find(n, word, 1, true) then return def.kind end
		end
		if def.exact then
			for _, e in ipairs(def.exact) do
				if n == e then return def.kind end
			end
		end
	end
	return nil
end
-- which hooked item (if any) an instance belongs to
function VS.kindOfInst(inst)
	local hk = VS.hipKind[inst]
	if hk then return hk end
	local p = inst
	while p do
		local k = hooked[p]
		if k then return k end
		p = p.Parent
	end
	return nil
end
-- false only when the instance belongs to an item whose switch is OFF
function VS.kindEnabled(inst)
	local k = VS.kindOfInst(inst)
	return k == nil or VS.itemOn[k] == true
end
function VS.soundWord(n)
	for _, w in ipairs({ "throw", "toss", "swing", "slash", "stab", "boom", "explo", "fuse", "whoosh" }) do
		if string.find(n, w, 1, true) then return true end
	end
	return false
end
-- the colour an item uses: its own (if you picked one on its page) or the ALL one
function VS.sel(kind)
	return VS.override[kind] or selected
end
function VS.anyActive()
	return selected ~= nil or next(VS.override) ~= nil
end
function VS.anyRainbow()
	if selected and selected.mode == "rainbow" then return true end
	for _, o in pairs(VS.override) do
		if o.mode == "rainbow" then return true end
	end
	return false
end
function VS.currentEntry()
	if VS.tab == "all" then return selected end
	return VS.override[VS.tab]
end
-- runs fn with `selected` swapped to that item's own colour (if it has one), then puts it back
function VS.run(kind, fn, ...)
	local prevSel, prevKind = selected, VS.curKind
	local own = VS.override[kind]
	if own then selected = own end
	VS.curKind = kind
	local ok, a, b = pcall(fn, ...)
	selected = prevSel
	VS.curKind = prevKind
	if not ok then
		warn("[Voidscope Recolor] " .. tostring(a))
		return nil
	end
	return a, b
end
function VS.finishWanted()
	local f = VS.FINISHES[VS.finishIdx]
	return f ~= nil and f.material ~= nil
end

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
local function partsUnder(root)
	local list = {}
	if root:IsA("BasePart") then table.insert(list, root) end
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then table.insert(list, d) end
	end
	return list
end
local function mapRainbow(parts)
	if not (selected and (selected.mode == "rainbow" or selected.mode == "pearl"
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
	end
	return selected and selected.color or Color3.new(1, 1, 1)
end
connect(RunService.Heartbeat, function()
	if RAINBOW_SPIN == 0 or not VS.anyRainbow() then return end
	local now = os.clock()
	if now - lastSpin < 0.08 then return end
	lastSpin = now
	for mp in pairs(rainbowT) do
		local sa = surfaces[mp]
		if sa and sa.Parent then
			local kind = VS.kindOfInst(mp) or "gun"
			local own = VS.sel(kind)
			if own and own.mode == "rainbow" then
				VS.run(kind, function() sa.Color = colorFor(mp) end)
			end
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
local function setSurfaceTint(mp, color, flat)
	local tex
	pcall(function() tex = mp.TextureID end)
	if type(tex) ~= "string" or tex == "" then
		return "notex"
	end
	local sa = surfaces[mp]
	if not sa or not sa.Parent then
		local existing = mp:FindFirstChild("VSSurface")
		if existing and existing:IsA("SurfaceAppearance") then
			sa = existing
			surfaces[mp] = sa
		else
			sa = Instance.new("SurfaceAppearance")
			sa.Name = "VSSurface"
			if not pcall(function() sa.ColorMap = tex end) then
				sa:Destroy()
				return "fail"
			end
			sa.Parent = mp
			surfaces[mp] = sa
		end
	end
	pcall(function()
		local want = flat and "" or tex
		if sa.ColorMap ~= want then sa.ColorMap = want end
	end)
	if not pcall(function() sa.Color = color end) then
		pcall(function() sa:Destroy() end)
		surfaces[mp] = nil
		return "fail"
	end
	return "ok"
end
local function removeSurface(mp)
	applied[mp] = nil
	local sa = surfaces[mp]
	if sa then
		pcall(function() sa:Destroy() end)
		surfaces[mp] = nil
	end
	local existing = mp:FindFirstChild("VSSurface")
	if existing then pcall(function() existing:Destroy() end) end
end
local function chromeMesh(mp, color)
	removeOverlay(mp)
	removeSurface(mp)
	set(mp, "TextureID", "")
	set(mp, "Material", glassed[mp] and Enum.Material.Glass or Enum.Material.Metal)
	set(mp, "Reflectance", CHROME_REFLECTANCE)
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
	local specs = { { SHEEN_PINK, offset }, { SHEEN_TEAL, -offset } }
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
		table.insert(made, att) -- removing the attachment removes its light too
	end
	sheens[part] = made
end
local function wantsSheen()
	return selected ~= nil and selected.mode == "pearl" and selected.sheen ~= false
end
local AssetService = game:GetService("AssetService")
local pinkCache = {}                     -- "style|texture id" -> { state, image, waiters }

-- Rainbow texture settings (colours follow your gun reference, darker)
local RB_BRIGHTNESS = 0.58      -- 1 = full colour, lower = darker colours
local RB_X_WEIGHT = 0.75        -- how much the gradient runs left-to-right across the texture...
local RB_Y_WEIGHT = 0.25        -- ...and top-to-bottom
local RB_REVERSE = false        -- true flips the order of the colours
local RB_BODY_TINT = 0.65       -- how strongly the dark parts of the gun lean magenta (0 = off)
local RB_BODY_COLOR = { 190, 25, 160 }
local RB_STOPS = {              -- purple > blue > cyan > green > yellow > orange > red > magenta > purple
	{ 120, 40, 230 }, { 30, 80, 245 }, { 0, 190, 225 }, { 50, 190, 60 }, { 225, 195, 20 },
	{ 235, 110, 10 }, { 215, 35, 35 }, { 200, 30, 170 }, { 120, 40, 230 },
}

-- the whole colour gradient is worked out once (256 steps) so painting a texture stays fast
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
-- (brightness 0-1, position u/v 0-1 across the texture, edge strength 0-1) into r, g, b (0-255)
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
			-- the dark parts of the gun lean magenta, like the body in your reference
			local d = (0.35 - rel) / 0.35
			if d > 0 then
				d = d * RB_BODY_TINT
				r, g, b = r + (bc1 - r) * d, g + (bc2 - g) * d, b + (bc3 - b) * d
			end
			-- keep the gun's own shading, darkened
			local shade = (0.45 + 0.55 * rel) * RB_BRIGHTNESS
			r, g, b = r * shade, g * shade, b * shade
			-- the very brightest pixels (rings, sharp facets) go pale like the silver parts
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
-- styles listed here also get an edge map worked out (the value is how far, in pixels, an edge reaches)
local TEX_EDGE_WIDTH = {}

local MAX_TEX = 512 -- bigger textures are shrunk to this before editing: much faster, looks the same on a gun

local function percentileOf(hist, total, p)
	if total == 0 then return p end
	local target, run = p * total, 0
	for k = 0, 255 do
		run += hist[k]
		if run >= target then return k / 255 end
	end
	return 1
end

-- Step 1 (once per texture, shared by every style): load it, shrink it, work out every pixel's brightness
local sources = {} -- texture id -> { w, h, buf, lum, hist, seen }

local function makeBreather(budgetFn)
	local mark = os.clock()
	return function()
		-- called once per row: hands the frame back to the game when we've used our share
		if os.clock() - mark > budgetFn() then
			task.wait()
			mark = os.clock()
		end
	end
end

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
		if step > 1 then -- shrink big textures (one pixel in every `step`)
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
				if readu8(buf, o + 3) > 10 then -- ignore see-through pixels
					hist[l] += 1
					seen += 1
				end
			end
			breathe()
		end
		src = { w = w, h = h, buf = buf, lum = lumBuf, hist = hist, seen = seen }
	end)
	pcall(function() ei:Destroy() end) -- the pixels are in our own buffer now
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
			gq = function() return 0 end,
		}
		local out = buffer.create(w * h * 4)
		buffer.copy(out, 0, src.buf, 0, w * h * 4) -- keeps the see-through (alpha) values
		local lumBuf = src.lum
		local pixel = makePixel(stats)
		for y = 0, h - 1 do
			local row = y * w
			local v = y / h
			for x = 0, w - 1 do
				local i = row + x
				local o = i * 4
				local nr, ng, nb = pixel(readu8(lumBuf, i) / 255, x / w, v, 0)
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

local function applyEdited(mp, image)
	local sa = surfaces[mp]
	if sa and sa.Parent and applied[mp] == image then return true end -- already showing it, nothing to do
	if not (sa and sa.Parent) then
		applied[mp] = nil
		if setSurfaceTint(mp, Color3.new(1, 1, 1), true) ~= "ok" then return false end
		sa = surfaces[mp]
	end
	local ok = pcall(function()
		sa.ColorMapContent = Content.fromObject(image)
		sa.Color = Color3.new(1, 1, 1)
	end)
	if ok then applied[mp] = image end
	return ok
end
local tintMesh
local jobs = {}
local working = false
local function runJobs()
	if working then return end
	working = true
	task.spawn(function()
		while #jobs > 0 do
			-- a style the player is waiting on goes first
			local pick = 1
			for i, j in ipairs(jobs) do
				if next(j.entry.waiters) then pick = i break end
			end
			local job = table.remove(jobs, pick)
			local entry = job.entry
			local function budget()
				return next(entry.waiters) and 0.005 or 0.0015 -- smaller slices of each frame = no stutter
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
				warn("[Voidscope Recolor] texture edit failed: " .. tostring(why))
			end
			local waiting = entry.waiters
			entry.waiters = {}
			if next(waiting) then
				setNote(image and "" or ("Texture edit failed: " .. tostring(why)))
			end
			for w, wk in pairs(waiting) do
				VS.run(type(wk) == "string" and wk or "gun", function()
					if selected and selected.mode == "texture" and w.Parent and VS.kindEnabled(w) then
						pcall(tintMesh, w, colorFor(w))
					end
				end)
			end
		end
		working = false
	end)
end
-- finds the built texture for this style + texture id, or queues it to be built
local function ensureTexture(style, tex)
	if not TEX_STYLES[style] then return nil end
	local key = style .. "|" .. tex
	local entry = pinkCache[key]
	if entry and entry.state == "failed" and os.clock() - (entry.at or 0) > 2 then
		entry = nil -- a failed build gets another try after a couple of seconds
	end
	if entry then return entry end
	entry = { state = "working", waiters = {} }
	pinkCache[key] = entry
	table.insert(jobs, { style = style, tex = tex, entry = entry })
	runJobs()
	return entry
end
function tintMesh(mp, color)
	if selected ~= nil and selected.mode == "pearl" then
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
		local entry = ensureTexture(style, tex)
		if entry and entry.state == "done" and applyEdited(mp, entry.image) then
			removeOverlay(mp)
			return
		end
		local result = setSurfaceTint(mp, color, true) -- flat colour until the texture is ready
		if result == "fail" then
			setOverlay(mp, color, OVERLAY_TRANSPARENCY)
		else
			removeOverlay(mp)
		end
		if entry and entry.state == "working" then
			entry.waiters[mp] = VS.curKind or "gun"
			setNote("Building the " .. style .. " texture...")
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
local function prebuildTextures(tool)
	for _, d in ipairs(tool:GetDescendants()) do
		if d:IsA("MeshPart") then
			local ok, tex = pcall(function() return d.TextureID end)
			if ok and type(tex) == "string" and tex ~= "" then
				ensureTexture("rainbow", tex)
			end
		end
	end
end
local function watchTexture(mp)
	if texWatched[mp] then return end
	texWatched[mp] = true
	connect(mp:GetPropertyChangedSignal("TextureID"), function()
		VS.run(VS.kindOfInst(mp) or "gun", function()
			if selected and VS.kindEnabled(mp) then tintMesh(mp, colorFor(mp)) end
		end)
	end)
end

-- TRAIL: a coloured ribbon that streams off the tip of the gun while you move it
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
	return ColorSequence.new(selected.color)
end
local function trailLook(trail)
	trail.Color = trailColorSeq()
	-- glowing (additive) trails can't show black, so a black trail is drawn solid instead
	local black = selected ~= nil and colorsClose(selected.color, Color3.new(0, 0, 0))
	trail.LightEmission = black and 0 or 1
	pcall(function() trail.Brightness = 4 end) -- extra glow so it pops (ignored if unsupported)
end
-- works out where the tip of the gun is: the far end of its longest side, the end that points away from you
-- 1) if the gun has its own muzzle marker (an Attachment called Muzzle / Barrel / Tip / Flash...), use exactly that
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
	-- 1b) an attachment that holds a muzzle flash / light / emitter is almost always the muzzle
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
-- where your hand is (the gun's grip), so the tip can be "the end furthest from the hand"
local function handPosition()
	local char = LocalPlayer.Character
	local hand = char and (char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm"))
	return hand and hand.Position or nil
end
-- for the hip gun: the Handle part is the grip, as long as it isn't the whole gun body
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
	if #parts == 0 then parts = allParts end -- gun hidden by the game? still put the trail on it
	if #parts == 0 then return nil end
	local markerPart, markerPos = findMuzzle(allParts)
	if markerPart then
		return markerPart, markerPos, Vector3.new(TRAIL_WIDTH / 2, 0, 0), "the gun's muzzle point"
	end
	-- 2) otherwise: find the part that reaches furthest from the grip, and put the trail on the CENTRE of its far end
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
	-- 3) last resort: the far end of the gun's longest side
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
	-- the tip sits on the barrel: average the position of the parts that reach the far end,
	-- instead of the middle of the whole gun (which would be down by the grip)
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
-- LEARNED TIP: the first time you fire, the game's own shot starts at the muzzle. We remember exactly where
-- that was on the gun, so the trail sits on the real muzzle from then on.
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
	for tool, kind in pairs(hooked) do
		if kind == "gun" and tool.Parent and tool.Parent == LocalPlayer.Character then
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
	set(inst, "Transparency", GLASS_TRANSPARENCY)
	set(inst, "Material", Enum.Material.Glass)
	glassed[inst] = true
end
local function applyGlass(inst)
	if not glassGuarded[inst] then
		glassGuarded[inst] = true
		local gk = VS.kindOfInst(inst) or VS.curKind or "gun"
		connect(inst:GetPropertyChangedSignal("Transparency"), function()
			VS.run(VS.kindOfInst(inst) or gk, function()
				if not unglassing and glassWanted() and VS.kindEnabled(inst) and inst.Transparency < GLASS_TRANSPARENCY - 0.01 then
					glassify(inst)
				end
			end)
		end)
	end
	if inst.Transparency < GLASS_TRANSPARENCY - 0.01 then
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
	for inst in pairs(VS.finished) do VS.finished[inst] = nil end
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
	for mp, sa in pairs(surfaces) do
		pcall(function() sa:Destroy() end)
		surfaces[mp] = nil
	end
end
-- FINISH: Metal / Matte / Satin material on top of the colour (skipped while the glass / chrome look is on)
function VS.applyFinish(inst)
	local f = VS.FINISHES[VS.finishIdx]
	if not (f and f.material) then return end
	if not inst:IsA("BasePart") then return end
	if glassWanted() or chromed[inst] or glassed[inst] then return end
	set(inst, "Material", f.material)
	set(inst, "Reflectance", f.reflectance or 0)
	VS.finished[inst] = true
end
function VS.unfinishAll()
	for inst in pairs(VS.finished) do
		if not (glassed[inst] or chromed[inst]) then
			local saved = originals[inst]
			if saved then
				pcall(function()
					if saved.Material ~= nil then inst.Material = saved.Material end
					if saved.Reflectance ~= nil then inst.Reflectance = saved.Reflectance end
				end)
				saved.Material = nil
				saved.Reflectance = nil
			end
		end
		VS.finished[inst] = nil
	end
end
-- puts everything under `root` (an item, or its display copy) back to how the game made it
function VS.restoreUnder(root)
	if not root then return end
	local function inside(inst)
		return inst == root or inst:IsDescendantOf(root)
	end
	unglassing = true
	local glassList = {}
	for inst in pairs(glassed) do
		if inside(inst) then table.insert(glassList, inst) end
	end
	for _, inst in ipairs(glassList) do
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
	local origList = {}
	for inst in pairs(originals) do
		if inside(inst) then table.insert(origList, inst) end
	end
	for _, inst in ipairs(origList) do
		local saved = originals[inst]
		if saved then
			for prop, v in pairs(saved) do
				pcall(function() inst[prop] = v end)
			end
		end
		originals[inst] = nil
		chromed[inst] = nil
		VS.finished[inst] = nil
	end
	local surfList, overList, sheenList = {}, {}, {}
	for mp in pairs(surfaces) do
		if inside(mp) then table.insert(surfList, mp) end
	end
	for mp in pairs(overlays) do
		if inside(mp) then table.insert(overList, mp) end
	end
	for part in pairs(sheens) do
		if inside(part) then table.insert(sheenList, part) end
	end
	for _, mp in ipairs(surfList) do removeSurface(mp) end
	for _, mp in ipairs(overList) do removeOverlay(mp) end
	for _, part in ipairs(sheenList) do removeSheen(part) end
end
local function paint(inst, color, isShot)
	if inst:IsA("MeshPart") and not isShot then
		set(inst, "Color", color)
		watchTexture(inst)
		tintMesh(inst, color)
		if glassWanted() then applyGlass(inst) end
		VS.applyFinish(inst)
		return true
	elseif inst:IsA("BasePart") then
		set(inst, "Color", color)
		if glassWanted() and not isShot then applyGlass(inst) end
		if not isShot then VS.applyFinish(inst) end
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
		if inst.Name == "VSTrail" then return false end -- our own trail is coloured by trailLook
		if selected and (selected.mode == "rainbow" or selected.rainbowFx) then
			set(inst, "Color", RAINBOW_SEQUENCE)
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
		if isShot or (selected and selected.mode == "pearl") then set(inst, "ColorMap", "") end
		set(inst, "Color", color)
		return true
	elseif inst:IsA("Decal") or inst:IsA("Texture") then
		set(inst, "Color3", color)
		return true
	elseif inst:IsA("Light") then -- PointLight / SpotLight / SurfaceLight
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
	local gk = VS.kindOfInst(inst) or VS.shotKind
	connect(inst:GetPropertyChangedSignal("Color"), function()
		VS.run(VS.kindOfInst(inst) or gk, function()
		if not selected then return end
		if not VS.kindEnabled(inst) then return end
		local fine
		if selected.mode == "rainbow" or selected.rainbowFx then
			fine = #inst.Color.Keypoints == #RAINBOW_SEQUENCE.Keypoints
		else
			fine = seqIsColor(inst.Color, colorFor(inst))
		end
		if not fine then
			paint(inst, colorFor(inst), false)
		end
		end)
	end)
end
local function paintGunRaw(tool)
	local kind = hooked[tool] or "gun"
	if not VS.itemOn[kind] then return 0 end
	if not selected then
		if VS.finishWanted() then -- a finish works on its own, before any colour is picked
			for _, d in ipairs(tool:GetDescendants()) do
				if d:IsA("BasePart") then VS.applyFinish(d) end
			end
		end
		return 0
	end
	local ref = mapRainbow(partsUnder(tool)) -- does nothing unless Rainbow / Glass is picked
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
local function paintGun(tool)
	return VS.run(hooked[tool] or "gun", paintGunRaw, tool) or 0
end
local function gunAssetIds(kind)
	kind = kind or "gun"
	local ids = {}
	for tool in pairs(hooked) do
		for _, d in ipairs(tool:GetDescendants()) do
			if hooked[tool] == kind and d:IsA("MeshPart") then
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
			VS.run("gun", function()
				if selected and VS.itemOn.gun and d.Parent then
					VS.hipKind[d] = "gun"
					paint(d, colorFor(d), false)
				end
			end)
		end)
	end)
end
local function paintHip()
	local char = LocalPlayer.Character
	if not (VS.anyActive() and char) then return 0 end
	local done, count = {}, 0
	local function paintOne(d, kind)
		if done[d] then return end
		done[d] = true
		VS.hipKind[d] = kind
		if paint(d, colorFor(d), false) and d:IsA("BasePart") then
			count += 1
		end
	end
	local function ownedBy(d, ids)
		local okt, tex = pcall(function() return d.TextureID end)
		local okm, mesh = pcall(function() return d.MeshId end)
		return (okt and tex ~= "" and ids[tex]) or (okm and mesh ~= "" and ids[mesh])
	end
	-- the gun on your hip / back
	VS.run("gun", function()
		if not (selected and VS.itemOn.gun) then return end
		local target = hipTarget(char)
		if target then
			watchTarget(target)
			local targetRef = mapRainbow(partsUnder(target))
			paintOne(target, "gun")
			for _, d in ipairs(target:GetDescendants()) do
				paintOne(d, "gun")
			end
			if targetRef and wantsSheen() then addSheen(targetRef) end
		end
		local ids = gunAssetIds("gun")
		local matched = {}
		for _, d in ipairs(char:GetDescendants()) do
			if d:IsA("MeshPart") and not done[d] and not d:FindFirstAncestorOfClass("Tool") and ownedBy(d, ids) then
				table.insert(matched, d)
			end
		end
		local matchedRef = mapRainbow(matched)
		for _, d in ipairs(matched) do paintOne(d, "gun") end
		if matchedRef and wantsSheen() then addSheen(matchedRef) end
	end)
	-- knives / bombs: a copy of the item on your hip or back (any part of you that uses the item's mesh)
	for _, kind in ipairs(VS.ORDER) do
		if kind ~= "gun" and VS.itemOn[kind] then
			VS.run(kind, function()
				if not selected then return end
				local kindIds = gunAssetIds(kind)
				if not next(kindIds) then return end
				local list = {}
				for _, d in ipairs(char:GetDescendants()) do
					if d:IsA("MeshPart") and not done[d] and not d:FindFirstAncestorOfClass("Tool") and ownedBy(d, kindIds) then
						table.insert(list, d)
					end
				end
				mapRainbow(list)
				for _, d in ipairs(list) do paintOne(d, kind) end
			end)
		end
	end
	return count
end
-- the gun on your hip / back (the game's display copy, or any part of you that uses the gun's mesh)
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
-- trails go on the gun in your hand AND the one on your hip
local function refreshTrails()
	if not trailOn then
		for key in pairs(trails) do removeTrail(key) end
		return
	end
	for tool, kind in pairs(hooked) do
		local def = VS.BYKIND[kind]
		if tool.Parent and tool.Parent == LocalPlayer.Character and VS.itemOn[kind] and def and def.trail and VS.sel(kind) then
			VS.run(kind, ensureTrail, tool, function() return partsUnder(tool) end, handPosition)
		else
			removeTrail(tool)
		end
	end
	if VS.itemOn.gun and VS.sel("gun") then
		for key, parts in pairs(hipGroups()) do
			VS.run("gun", ensureTrail, key, function() return parts end, handleGrip)
		end
	else
		for key in pairs(trails) do
			if type(key) == "string" then removeTrail(key) end
		end
	end
end
local lastTrailCheck = 0
connect(RunService.Heartbeat, function()
	if not trailOn then return end
	local now = os.clock()
	if now - lastTrailCheck < 1.5 then return end
	lastTrailCheck = now
	refreshTrails() -- keeps trails alive if the game swaps / re-creates the gun
end)
local function refreshHip()
	if not VS.anyActive() then return end
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
		elseif VS.anyActive() and d:IsA("MeshPart") then
			queueHipRefresh()
		end
	end)
	local ref = char:FindFirstChild("DisplayRefGun")
	if ref and ref:IsA("ObjectValue") then hookRef(ref) end
end
local function isGun(inst) -- now returns the item kind ("gun" / "knife" / "goldbomb" / "prankbomb") or nil
	return VS.kindOfTool(inst)
end
local function openShotWindow(kind)
	if type(kind) ~= "string" or not VS.BYKIND[kind] then kind = "gun" end
	local now = os.clock()
	if now > shotUntil then shotCount = 0 end
	local window = VS.BYKIND[kind].shotWindow or SHOT_WINDOW
	VS.shotKind = kind
	shotUntil = now + window
	task.delay(window + 0.2, function()
		if selected and os.clock() >= shotUntil then
			setNote("Last shot: " .. shotCount .. " extra effect(s) recoloured")
		end
	end)
end
local function watchSound(inst, kind)
	if not inst:IsA("Sound") or guarded[inst] then return end
	local n = string.lower(inst.Name)
	if string.find(n, "shot", 1, true) or string.find(n, "shoot", 1, true)
		or string.find(n, "fire", 1, true) or string.find(n, "alt", 1, true) or VS.soundWord(n) then
		guarded[inst] = true
		connect(inst.Played, function() openShotWindow(kind) end)
	end
end
local function hookGun(tool, kind)
	if hooked[tool] then return end
	kind = kind or "gun"
	hooked[tool] = kind
	VS.itemFound[kind] = true
	print("[Voidscope Recolor] found " .. kind .. ": " .. tool:GetFullName())
	if kind == "gun" then
		task.delay(5, prebuildTextures, tool) -- builds the rainbow texture quietly in the background (after load) so picking Rainbow is quick
	end
	local effects = paintGun(tool)
	if VS.anyActive() then
		setGunStatus("Gun: found, " .. effects .. " beam part(s)")
		refreshHip()
	else
		setGunStatus("Gun: found")
	end
	for _, d in ipairs(tool:GetDescendants()) do
		watchSound(d, kind)
	end
	connect(tool.DescendantAdded, function(d)
		guardEffect(d)
		watchSound(d, kind)
		task.defer(function()
			VS.run(kind, function()
				if selected and VS.itemOn[kind] and d.Parent then
					paint(d, colorFor(d), false)
				end
			end)
		end)
	end)
	connect(tool.Activated, function() openShotWindow(kind) end)
	-- the trail is only on while the gun is in your hands
	connect(tool.Equipped, function()
		task.delay(0.3, function() -- give the game a moment to attach the gun to your hand
			if trailOn then refreshTrails() end
		end)
	end)
	connect(tool.Unequipped, function()
		removeTrail(tool)
	end)
	if trailOn and tool.Parent == LocalPlayer.Character then
		task.delay(0.3, refreshTrails)
	end
	if VS.refreshUi then VS.refreshUi() end
end
local function consider(child)
	local kind = isGun(child)
	if kind then
		hookGun(child, kind)
	elseif child:IsA("Tool") and not VS.warned[child.Name] then
		VS.warned[child.Name] = true
		print("[Voidscope Recolor] tool not recognised (add a word for it in VS.ITEMS if it should be recoloured): " .. child.Name)
	end
end
local function scan(container)
	if not container then return end
	for _, child in ipairs(container:GetChildren()) do
		consider(child)
	end
	connect(container.ChildAdded, function(child)
		consider(child)
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
				local kind = isGun(child)
				if kind then
					openShotWindow(kind)
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
	if #points == 0 then return true end -- can't tell where it is, so don't skip it
	for _, p in ipairs(points) do
		if (p - root.Position).Magnitude <= SHOT_RADIUS then return true end
	end
	return false
end
connect(Workspace.DescendantAdded, function(d)
	if not VS.sel(VS.shotKind) then return end
	if not VS.shotFxOn then return end -- the SHOT FX switch
	if os.clock() > shotUntil then return end
	if not VS.itemOn[VS.shotKind] then return end
	local char = characterOf(d)
	if char then
		if char ~= LocalPlayer.Character then return end
		if not (isEffect(d) or d:IsA("Light")) then return end
	end
	local shotKind = VS.shotKind
	task.defer(function()
		VS.run(shotKind, function()
		if not d.Parent or not selected then return end
		if not nearYou(d) then return end
		if d:IsA("Beam") then
			-- learn where the shot leaves the gun (tried straight away and again a moment later)
			local function learn()
				if learnTip(d) and trailOn then refreshTrails() end
			end
			learn()
			task.delay(0.05, learn)
		end
		-- knife / bomb projectiles keep their texture (tinted); gun shots become solid glowing colour as before
		if paint(d, colorFor(d), not (shotKind ~= "gun" and d:IsA("MeshPart"))) then
			guardEffect(d)
			shotCount += 1
		end
		end)
	end)
end)
local function updateStatus()
	if VS.refreshUi then VS.refreshUi() end
	local cur = VS.currentEntry() -- the colour of whichever page is open
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
		statusLabel.Text = cur and ("Selected: " .. cur.name) or "Selected: Default"
	end
	for name, bg in pairs(buttons) do
		local stroke = bg:FindFirstChildOfClass("UIStroke")
		if stroke then
			local on = (cur ~= nil and cur.name == name)
			stroke.Color = on and BUTTON_SELECTED or BUTTON_OUTLINE
			stroke.Thickness = on and 2.5 or 1
			stroke.Transparency = on and 0 or 0.45
		end
	end
end
local function applyColor(entry)
	if VS.tab ~= "all" then -- an item's own page: colour just that item
		VS.applyItemColor(VS.tab, entry)
		return
	end
	for k in pairs(VS.override) do VS.override[k] = nil end -- the ALL page colours everything
	selected = entry -- set first, so nothing puts the glass look back while we undo it
	if not glassWanted() then unglassAll() end -- leaving Glass: bring the solid gun back
	if not wantsSheen() then -- no glow lights for this colour: take away any left over
		for part in pairs(sheens) do removeSheen(part) end
	end
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
	refreshHip() -- the gun on your hip / back too
	refreshTrails() -- the trail switches to the new colour
	updateStatus()
end
local function resetColor()
	for k in pairs(VS.override) do VS.override[k] = nil end
	selected = nil
	glassOverlay = false
	trailOn = false
	VS.finishIdx = 1
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

-- switching one item on / off puts that item back exactly as the game made it
function VS.restoreKind(kind)
	for tool, k in pairs(hooked) do
		if k == kind then
			removeTrail(tool)
			VS.restoreUnder(tool)
		end
	end
	local char = LocalPlayer.Character
	if not char then return end
	if kind == "gun" then
		for key in pairs(trails) do
			if type(key) == "string" then removeTrail(key) end
		end
		local target = hipTarget(char)
		if target then VS.restoreUnder(target) end
	end
	local ids = gunAssetIds(kind)
	if next(ids) then
		for _, d in ipairs(char:GetDescendants()) do
			if d:IsA("MeshPart") and not d:FindFirstAncestorOfClass("Tool") then
				local okt, tex = pcall(function() return d.TextureID end)
				local okm, mesh = pcall(function() return d.MeshId end)
				if (okt and tex ~= "" and ids[tex]) or (okm and mesh ~= "" and ids[mesh]) then
					VS.restoreUnder(d)
				end
			end
		end
	end
end
function VS.toggleItem(kind)
	VS.itemOn[kind] = not VS.itemOn[kind]
	if VS.itemOn[kind] then
		if VS.anyActive() or VS.finishWanted() then
			for tool, k in pairs(hooked) do
				if k == kind and tool.Parent then paintGun(tool) end
			end
			refreshHip()
			refreshTrails()
		end
	else
		VS.restoreKind(kind)
	end
	updateStatus()
end
function VS.cycleFinish()
	VS.finishIdx = VS.finishIdx % #VS.FINISHES + 1
	VS.unfinishAll()
	if VS.anyActive() or VS.finishWanted() then
		for tool, kind in pairs(hooked) do
			if tool.Parent and VS.itemOn[kind] then paintGun(tool) end
		end
		refreshHip()
	end
	updateStatus()
end
-- colour one item only (from its own page)
function VS.applyItemColor(kind, entry)
	VS.restoreKind(kind) -- start from the game's own look
	VS.override[kind] = entry
	for tool, k in pairs(hooked) do
		if k == kind and tool.Parent then paintGun(tool) end
	end
	refreshHip()
	refreshTrails()
	updateStatus()
end
-- put one item back to following the ALL page
function VS.resetItem(kind)
	VS.override[kind] = nil
	VS.restoreKind(kind)
	if selected or VS.finishWanted() then
		for tool, k in pairs(hooked) do
			if k == kind and tool.Parent then paintGun(tool) end
		end
		refreshHip()
		refreshTrails()
	end
	setNote("")
	updateStatus()
end
-- switch the menu page: "all" or an item kind
function VS.setTab(tab)
	VS.tab = tab
	local isAll = (tab == "all")
	for _, f in ipairs(VS.ui.allOnly) do f.Visible = isAll end
	for _, f in ipairs(VS.ui.itemOnly) do f.Visible = not isAll end
	if VS.ui.title then
		VS.ui.title.Text = isAll and "ALL ITEMS  -  one colour for everything"
			or (VS.BYKIND[tab].label .. "  -  its own colour (RESET ITEM = follow ALL)")
	end
	setNote("")
	updateStatus()
end
function VS.newRow(ctx, height, order)
	local row = Instance.new("Frame")
	row.LayoutOrder = order or ctx.nextOrder()
	row.Size = UDim2.new(1, 0, 0, height)
	row.BackgroundTransparency = 1
	row.Parent = ctx.content
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = row
	return row
end

-- custom colour picker (hex / r,g,b box + hue / saturation / brightness sliders) - lives under MORE OPTIONS
function VS.buildPicker(ctx)
	local glassButton, photoText = ctx.glassButton, ctx.photoText
	local c = VS.custom
	local function curColor() return Color3.fromHSV(c.h, c.s, c.v) end
	local function hexOf(col)
		return string.format("#%02X%02X%02X", math.floor(col.R * 255 + 0.5), math.floor(col.G * 255 + 0.5), math.floor(col.B * 255 + 0.5))
	end
	local function styleBox(inst)
		Instance.new("UICorner", inst).CornerRadius = UDim.new(0, 8)
		local st = Instance.new("UIStroke")
		st.Color = BUTTON_OUTLINE
		st.Transparency = 0.45
		st.Thickness = 1
		st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		st.Parent = inst
	end

	-- swatch | hex box | APPLY
	local rowA = VS.newRow(ctx, 28)
	table.insert(VS.ui.advanced, rowA)
	local swatch = Instance.new("Frame")
	swatch.LayoutOrder = 1
	swatch.Size = UDim2.new(0, 28, 1, 0)
	swatch.BorderSizePixel = 0
	swatch.Parent = rowA
	styleBox(swatch)
	local hexBox = Instance.new("TextBox")
	hexBox.LayoutOrder = 2
	hexBox.Size = UDim2.new(1, -114, 1, 0)
	hexBox.BackgroundColor3 = Color3.fromRGB(22, 23, 30)
	hexBox.BackgroundTransparency = 0.15
	hexBox.BorderSizePixel = 0
	hexBox.ClearTextOnFocus = false
	hexBox.Font = BUBBLY_FONT
	hexBox.TextSize = 14
	hexBox.TextColor3 = Color3.new(1, 1, 1)
	hexBox.PlaceholderText = "own colour: #RRGGBB or 255,128,0"
	hexBox.PlaceholderColor3 = Color3.fromRGB(130, 132, 150)
	hexBox.Text = ""
	hexBox.Parent = rowA
	styleBox(hexBox)

	local hueS, satS, valS
	local function refreshSwatch()
		local col = curColor()
		swatch.BackgroundColor3 = col
		hexBox.Text = hexOf(col)
	end
	local function refreshSliders()
		hueS.set(c.h)
		satS.set(c.s)
		valS.set(c.v)
		satS.grad.Color = ColorSequence.new(Color3.fromHSV(c.h, 0, c.v), Color3.fromHSV(c.h, 1, c.v))
		valS.grad.Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.fromHSV(c.h, c.s, 1))
	end
	local function setCustom(col)
		c.h, c.s, c.v = col:ToHSV()
		refreshSwatch()
		refreshSliders()
	end
	local function applyCustom()
		applyColor({ name = "Custom", color = curColor() })
	end
	local applyBg, _, applyHolder = glassButton(rowA, 3, "APPLY", Color3.fromRGB(0, 105, 190), nil, applyCustom)
	applyHolder.Size = UDim2.new(0, 74, 1, 0)
	buttons["Custom"] = applyBg
	hexBox.FocusLost:Connect(function(enterPressed)
		local col = VS.parseColor(hexBox.Text)
		if col then
			setCustom(col)
			if enterPressed then applyCustom() end
		else
			refreshSwatch()
			setNote("Colour not understood. Use #RRGGBB or 255,128,0")
		end
	end)

	-- hue / saturation / brightness sliders
	local rowB = VS.newRow(ctx, 22)
	table.insert(VS.ui.advanced, rowB)
	local function makeSlider(order, text, onChange)
		local bar = Instance.new("Frame")
		bar.LayoutOrder = order
		bar.Size = UDim2.new(1 / 3, -4, 1, 0)
		bar.BackgroundColor3 = Color3.new(1, 1, 1)
		bar.BorderSizePixel = 0
		bar.Parent = rowB
		styleBox(bar)
		local grad = Instance.new("UIGradient")
		grad.Parent = bar
		local hit = Instance.new("TextButton")
		hit.Size = UDim2.new(1, 0, 1, 0)
		hit.BackgroundTransparency = 1
		hit.BorderSizePixel = 0
		hit.AutoButtonColor = false
		hit.ZIndex = 2
		hit.Text = text
		hit.TextXAlignment = Enum.TextXAlignment.Left
		photoText(hit, 11)
		Instance.new("UIPadding", hit).PaddingLeft = UDim.new(0, 8)
		hit.Parent = bar
		local knob = Instance.new("Frame")
		knob.AnchorPoint = Vector2.new(0.5, 0.5)
		knob.Size = UDim2.new(0, 6, 1, 4)
		knob.Position = UDim2.new(0, 0, 0.5, 0)
		knob.BackgroundColor3 = Color3.new(1, 1, 1)
		knob.BorderSizePixel = 0
		knob.ZIndex = 3
		knob.Parent = bar
		Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 3)
		local ks = Instance.new("UIStroke")
		ks.Color = Color3.new(0, 0, 0)
		ks.Thickness = 1
		ks.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		ks.Parent = knob
		local dragging = false
		local function fromInput(input)
			local w = bar.AbsoluteSize.X
			if w <= 0 then return end
			onChange(math.clamp((input.Position.X - bar.AbsolutePosition.X) / w, 0, 1))
		end
		hit.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				fromInput(input)
			end
		end)
		connect(UserInputService.InputChanged, function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				fromInput(input)
			end
		end)
		connect(UserInputService.InputEnded, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		return {
			grad = grad,
			set = function(rel) knob.Position = UDim2.new(rel, 0, 0.5, 0) end,
		}
	end
	local function changed()
		refreshSwatch()
		refreshSliders()
	end
	hueS = makeSlider(1, "HUE", function(rel) c.h = rel changed() end)
	satS = makeSlider(2, "SAT", function(rel) c.s = rel changed() end)
	valS = makeSlider(3, "BRIGHT", function(rel) c.v = rel changed() end)
	local hueKeys = {}
	for i = 0, 6 do
		table.insert(hueKeys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)))
	end
	hueS.grad.Color = ColorSequence.new(hueKeys)
	refreshSwatch()
	refreshSliders()
end

-- left column: one big ON/OFF switch per item. right pane: everything else.
function VS.buildBody(ctx)
	local glassButton = ctx.glassButton
	local body = Instance.new("Frame")
	body.Name = "Body"
	body.LayoutOrder = ctx.nextOrder()
	body.Size = UDim2.new(1, 0, 0, 0)
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.BackgroundTransparency = 1
	body.Parent = ctx.content
	local bodyLayout = Instance.new("UIListLayout")
	bodyLayout.FillDirection = Enum.FillDirection.Horizontal
	bodyLayout.Padding = UDim.new(0, 8)
	bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
	bodyLayout.Parent = body

	local side = Instance.new("Frame")
	side.Name = "Switches"
	side.LayoutOrder = 1
	side.Size = UDim2.new(0, 112, 0, 0)
	side.AutomaticSize = Enum.AutomaticSize.Y
	side.BackgroundTransparency = 1
	side.Parent = body
	local sideLayout = Instance.new("UIListLayout")
	sideLayout.Padding = UDim.new(0, 6)
	sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sideLayout.Parent = side
	local sideTitle = label(side, 0, "Turn on / off:", 13, Color3.new(1, 1, 1), 18)
	sideTitle.Font = BUBBLY_FONT
	sideTitle.TextXAlignment = Enum.TextXAlignment.Left
	for i, kind in ipairs(VS.ORDER) do
		local bg, tb, holder = glassButton(side, i, VS.BYKIND[kind].label .. "\nON", VS.GREEN, nil, function()
			VS.toggleItem(kind)
		end)
		holder.Size = UDim2.new(1, 0, 0, 42)
		VS.toggleBtn[kind] = { bg = bg, tb = tb }
	end

	local main = Instance.new("Frame")
	main.Name = "Main"
	main.LayoutOrder = 2
	main.Size = UDim2.new(1, -120, 0, 0)
	main.AutomaticSize = Enum.AutomaticSize.Y
	main.BackgroundTransparency = 1
	main.Parent = body
	local mainLayout = Instance.new("UIListLayout")
	mainLayout.Padding = UDim.new(0, 6)
	mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
	mainLayout.Parent = main
	local title = label(main, 0, "Pick a colour!", 14, Color3.new(1, 1, 1), 18)
	title.Font = BUBBLY_FONT
	title.TextXAlignment = Enum.TextXAlignment.Left
	ctx.content = main -- everything built after this goes in the right-hand pane
end

-- MORE OPTIONS (own colour, finish, shot fx) hidden until you press the button
function VS.buildOptions(ctx, controls)
	local glassButton = ctx.glassButton
	local ON, OFF = VS.ON, VS.OFF
	local moreRow = VS.newRow(ctx, 28)
	local moreTb
	local function showMore()
		for _, f in ipairs(VS.ui.advanced) do f.Visible = VS.moreOpen end
		moreTb.Text = VS.moreOpen and "FEWER OPTIONS" or "MORE OPTIONS"
	end
	local _, tb, moreHolder = glassButton(moreRow, 1, "MORE OPTIONS", OFF, nil, function()
		VS.moreOpen = not VS.moreOpen
		showMore()
	end)
	moreTb = tb
	moreHolder.Size = UDim2.new(1, 0, 1, 0)

	VS.buildPicker(ctx) -- own colour (added to VS.ui.advanced)

	local row2 = VS.newRow(ctx, 28)
	local finishBg, finishTb, finishHolder = glassButton(row2, 1, "FINISH: DEFAULT", OFF, nil, function()
		VS.cycleFinish()
	end)
	finishHolder.Size = UDim2.new(0.5, -3, 1, 0)
	local shotBg, shotTb, shotHolder = glassButton(row2, 2, "SHOT FX: ON", ON, nil, function()
		VS.shotFxOn = not VS.shotFxOn
		updateStatus()
	end)
	shotHolder.Size = UDim2.new(0.5, -3, 1, 0)
	local foundLabel = label(ctx.content, ctx.nextOrder(), "", 11, Color3.fromRGB(150, 150, 170), 14)
	foundLabel.TextXAlignment = Enum.TextXAlignment.Left
	foundLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	foundLabel.TextStrokeTransparency = 0.5
	table.insert(VS.ui.advanced, row2)
	table.insert(VS.ui.advanced, foundLabel)

	function VS.refreshUi()
		for kind, b in pairs(VS.toggleBtn) do
			local on = VS.itemOn[kind]
			b.tb.Text = VS.BYKIND[kind].label .. "\n" .. (on and "ON" or "OFF")
			b.bg.BackgroundColor3 = on and VS.GREEN or VS.RED
		end
		finishTb.Text = "FINISH: " .. VS.FINISHES[VS.finishIdx].name
		finishBg.BackgroundColor3 = VS.finishIdx > 1 and ON or OFF
		shotTb.Text = VS.shotFxOn and "SHOT FX: ON" or "SHOT FX: OFF"
		shotBg.BackgroundColor3 = VS.shotFxOn and ON or OFF
		local got, missing = {}, {}
		for _, kind in ipairs(VS.ORDER) do
			table.insert(VS.itemFound[kind] and got or missing, VS.BYKIND[kind].label)
		end
		local text = "Found: " .. (#got > 0 and table.concat(got, ", ") or "none yet")
		if #missing > 0 then
			text = text .. "   |   Not seen yet: " .. table.concat(missing, ", ")
		end
		foundLabel.Text = text
	end
	VS.refreshUi()
	showMore()
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

	local WIDTH = 570 -- wide and short: side bar on the left, options on the right

	-- bold white capitals with a soft dark outline (stays readable on the clear glass)
	local function photoText(b, size)
		b.Font = BUBBLY_FONT
		b.TextSize = size or 15
		b.TextColor3 = Color3.new(1, 1, 1)
		b.TextStrokeColor3 = Color3.new(0, 0, 0)
		b.TextStrokeTransparency = 0.3
	end

	-- shiny metal: bright and dark bands like polished chrome
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

	-- one metallic button: a tinted see-through slab, a glossy highlight on the top half and a white rim.
	-- (the text button sits on top so the shine never washes out the label)
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
			g.Color = fillGradient          -- rainbow buttons keep their rainbow
		else
			g.Color = METAL_BUTTON          -- everything else gets the chrome shading over its colour
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
		tb.TextScaled = true -- long labels shrink to fit the smaller buttons
		local limit = Instance.new("UITextSizeConstraint")
		limit.MaxTextSize = 13
		limit.MinTextSize = 7
		limit.Parent = tb
		tb.Text = text
		tb.Parent = holder
		tb.MouseButton1Click:Connect(onClick)
		return bg, tb, holder
	end

	local frame = Instance.new("Frame")
	frame.Name = "Main"
	frame.Size = UDim2.new(0, WIDTH, 0, 180) -- the height follows the content, see syncHeight below
	frame.Position = UDim2.new(0, 20, 0.3, 0)
	frame.BackgroundColor3 = Color3.new(1, 1, 1) -- the metal gradient below does the colouring
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
	-- a soft diagonal sheen across the glass (brighter at the corners, clearest in the middle)
	local glassSheen = Instance.new("UIGradient")
	glassSheen.Rotation = 20
	glassSheen.Color = METAL_FRAME
	glassSheen.Parent = frame
	-- glossy reflection across the top half, like light on polished black chrome
	local gloss = Instance.new("Frame")
	gloss.Name = "Gloss"
	gloss.Size = UDim2.new(1, -6, 0.5, 0)
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

	-- header: title + minimise + close
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

	-- side bar + right-hand pane (everything below goes in the pane)
	local ctx = { content = content, nextOrder = nextOrder, glassButton = makeGlassButton, photoText = photoText }
	VS.buildBody(ctx)

	-- colour buttons: six per row, two rows (10 colours + Glass + Chroma)
	local grid = Instance.new("Frame")
	grid.Name = "Colours"
	grid.LayoutOrder = nextOrder()
	grid.Size = UDim2.new(1, 0, 0, 62)
	grid.BackgroundTransparency = 1
	grid.Parent = ctx.content
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(1 / 6, -5, 0, 28)
	gridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = grid

	for i, entry in ipairs(COLORS) do
		-- a pure black button would swallow the chrome shading, so it's drawn as dark gunmetal
		local shown = colorsClose(entry.color, Color3.new(0, 0, 0)) and Color3.fromRGB(40, 40, 46) or entry.color
		local bg = makeGlassButton(grid, i, string.upper(entry.name), shown,
			entry.gradient and RAINBOW_SEQUENCE or nil, function() applyColor(entry) end)
		buttons[entry.name] = bg
	end
	-- Glass: frosted light-blue
	buttons[GLASS.name] = (makeGlassButton(grid, #COLORS + 1, string.upper(GLASS.name),
		Color3.fromRGB(100, 140, 170), nil, function() applyColor(GLASS) end, 0.15))
	-- Chroma: the live rainbow
	buttons[RAINBOW.name] = (makeGlassButton(grid, #COLORS + 2, string.upper(RAINBOW.name),
		Color3.new(1, 1, 1), RAINBOW_SEQUENCE, function() applyColor(RAINBOW) end))

	-- custom colour picker + saved colours

	-- controls row: See-through / Trail / Reset
	local controls = Instance.new("Frame")
	controls.Name = "Controls"
	controls.LayoutOrder = nextOrder()
	controls.Size = UDim2.new(1, 0, 0, 28)
	controls.BackgroundTransparency = 1
	controls.Parent = ctx.content
	local controlsLayout = Instance.new("UIListLayout")
	controlsLayout.FillDirection = Enum.FillDirection.Horizontal
	controlsLayout.Padding = UDim.new(0, 6)
	controlsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	controlsLayout.Parent = controls

	local function controlButton(order2, text, fill, onClick)
		local bg, tb, holder = makeGlassButton(controls, order2, text, fill, nil, onClick)
		holder.Size = UDim2.new(1 / 3, -4, 1, 0)
		return bg, tb
	end
	glassToggleBg, glassToggleBtn = controlButton(1, "SEE-THROUGH: OFF", Color3.fromRGB(78, 80, 92), function()
		glassOverlay = not glassOverlay
		if selected then
			applyColor(selected) -- repaints with / without the see-through look
		else
			updateStatus()
		end
	end)
	trailToggleBg, trailToggleBtn = controlButton(2, "TRAIL: OFF", Color3.fromRGB(78, 80, 92), function()
		trailOn = not trailOn
		if trailOn and not selected then
			setNote("Pick a colour first, the trail follows it.")
		elseif trailOn then
			setNote("")
		end
		refreshTrails()
		updateStatus()
	end)
	controlButton(3, "RESET TO DEFAULT", Color3.fromRGB(84, 84, 100), resetColor)

	-- per-item switches, finish, shot fx
	VS.buildOptions(ctx, controls)

	noteLabel = label(ctx.content, nextOrder(), "", 11, Color3.fromRGB(150, 150, 170), 14)
	noteLabel.TextXAlignment = Enum.TextXAlignment.Left
	noteLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	noteLabel.TextStrokeTransparency = 0.5

	-- footer: hint on the left, handle on the right
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
	handle.Text = "insp:kudo"
	handle.Parent = footer

	-- "Are you sure?" popup for the close button
	local confirm = Instance.new("Frame")
	confirm.Name = "ConfirmClose"
	confirm.Size = UDim2.new(1, 0, 1, 0)
	confirm.BackgroundColor3 = Color3.fromRGB(2, 2, 5)
	confirm.BackgroundTransparency = 0.3
	confirm.BorderSizePixel = 0
	confirm.Active = true -- stops clicks going through to the buttons underneath
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
		b.Size = UDim2.new(0.25, 0, 0, 34)
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
	local yesBtn = confirmButton("YES", 0.35, Color3.fromRGB(125, 30, 30))
	local noBtn = confirmButton("NO", 0.65, Color3.fromRGB(38, 40, 54))

	-- minimise
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
		icon.Position = frame.Position -- the icon appears where the menu was
		frame.Visible = false
		icon.Visible = true
	end)

	local pressedAt
	icon.MouseButton1Down:Connect(function()
		pressedAt = icon.AbsolutePosition
	end)
	icon.MouseButton1Click:Connect(function()
		if pressedAt and (icon.AbsolutePosition - pressedAt).Magnitude > 6 then return end -- it was a drag, not a tap
		minimised = false
		frame.Position = icon.Position -- the menu opens where the icon is
		icon.Visible = false
		frame.Visible = true
	end)

	-- close: X asks first, YES closes for real, NO goes back
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
			local target = minimised and icon or frame -- hides / shows whichever one is out right now
			target.Visible = not target.Visible
		end
	end)
end

local built, buildErr = pcall(buildGui)
if not built then
	warn("[Voidscope Recolor] the menu failed to build: " .. tostring(buildErr))
end
if next(hooked) then
	setGunStatus("Gun: found") -- it was already in your hands before the menu existed
end
if VS.refreshUi then VS.refreshUi() end
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
	restoreAll()
	if gui then gui:Destroy() end
	env.VoidscopeRecolorCleanup = nil
end
print("[Voidscope Recolor] loaded")
