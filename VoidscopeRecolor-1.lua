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
local MENU_OUTLINE = Color3.fromRGB(80, 60, 130)
local BUTTON_OUTLINE = Color3.fromRGB(70, 70, 70)     -- thin outline so the Black button shows on the black menu
local BUTTON_SELECTED = Color3.fromRGB(0, 170, 255)
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
local ICON_SIZE = 52
local ICON_PNG_B64 = [=[
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
local unglassing = false
local chromed = setmetatable({}, { __mode = "k" })       -- meshes currently showing the chrome look
local flatSpread = setmetatable({}, { __mode = "k" })    -- parts of a gun that is a single piece (no end-to-end spread to colour)
local sheens = setmetatable({}, { __mode = "k" })        -- gun part -> the two glow lights we added to it (only if GLASS_SHEEN is on)
local lastSpin = 0
local hipQueued = false
local gui, gunLabel, hipLabel, statusLabel, noteLabel, glassToggleBtn
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
			for w in pairs(waiting) do
				if selected and selected.mode == "texture" and w.Parent then
					pcall(tintMesh, w, colorFor(w))
				end
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
			entry.waiters[mp] = true
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
		if selected then tintMesh(mp, colorFor(mp)) end
	end)
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
		connect(inst:GetPropertyChangedSignal("Transparency"), function()
			if not unglassing and glassWanted() and inst.Transparency < GLASS_TRANSPARENCY - 0.01 then
				glassify(inst)
			end
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
	for mp, sa in pairs(surfaces) do
		pcall(function() sa:Destroy() end)
		surfaces[mp] = nil
	end
end
local function paint(inst, color, isShot)
	if inst:IsA("MeshPart") and not isShot then
		set(inst, "Color", color)
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
	guarded[inst] = true
	connect(inst:GetPropertyChangedSignal("Color"), function()
		if not selected then return end
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
end
local function paintGun(tool)
	if not selected then return 0 end
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
	task.delay(5, prebuildTextures, tool) -- builds the rainbow texture quietly in the background (after load) so picking Rainbow is quick
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
	if #points == 0 then return true end -- can't tell where it is, so don't skip it
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
		if paint(d, colorFor(d), true) then
			guardEffect(d)
			shotCount += 1
		end
	end)
end)
local function updateStatus()
	if glassToggleBtn then
		glassToggleBtn.Text = glassOverlay and "See-through: ON" or "See-through: OFF"
		glassToggleBtn.BackgroundColor3 = glassOverlay and Color3.fromRGB(40, 100, 150) or Color3.fromRGB(35, 35, 50)
	end
	if statusLabel then
		statusLabel.Text = selected and ("Selected: " .. selected.name) or "Selected: Default"
	end
	for name, btn in pairs(buttons) do
		local stroke = btn:FindFirstChildOfClass("UIStroke")
		if stroke then
			local on = (selected ~= nil and selected.name == name)
			stroke.Color = on and BUTTON_SELECTED or BUTTON_OUTLINE
			stroke.Thickness = on and 2 or 1
		end
	end
end
local function applyColor(entry)
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
	updateStatus()
end
local function resetColor()
	selected = nil
	glassOverlay = false
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
	if string.gsub(ICON_PNG_B64, "%s", "") == "" then return nil end
	local toAsset = getcustomasset or getsynasset
	if not (writefile and toAsset) then return nil end
	local ok, asset = pcall(function()
		local name = "VoidscopeOrb.png"
		writefile(name, b64decode(ICON_PNG_B64))
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

	local WIDTH = 280

	-- the look from the photo: bold white capitals with a soft dark outline
	local function photoText(b, size)
		b.Font = BUBBLY_FONT
		b.TextSize = size or 15
		b.TextColor3 = Color3.new(1, 1, 1)
		b.TextStrokeColor3 = Color3.new(0, 0, 0)
		b.TextStrokeTransparency = 0.45
	end

	local frame = Instance.new("Frame")
	frame.Name = "Main"
	frame.Size = UDim2.new(0, WIDTH, 0, 320) -- the height follows the content, see syncHeight below
	frame.Position = UDim2.new(0, 20, 0.3, 0)
	frame.BackgroundColor3 = Color3.new(1, 1, 1) -- the gradient below does the colouring
	frame.BorderSizePixel = 0
	frame.Active = true
	pcall(function() frame.Draggable = true end)
	frame.Parent = gui
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)
	local frameStroke = Instance.new("UIStroke")
	frameStroke.Color = MENU_OUTLINE
	frameStroke.Thickness = 1.5
	frameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	frameStroke.Parent = frame

	-- black galaxy background
	local galaxyOk, galaxyErr = pcall(function()
		local sky = Instance.new("UIGradient")
		sky.Rotation = 60
		sky.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0, 0, 0)),
			ColorSequenceKeypoint.new(0.35, Color3.fromRGB(22, 5, 44)),
			ColorSequenceKeypoint.new(0.70, Color3.fromRGB(6, 12, 44)),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0)),
		})
		sky.Parent = frame

		local stars = Instance.new("Frame")
		stars.Name = "Stars"
		stars.Size = UDim2.new(1, 0, 1, 0)
		stars.BackgroundTransparency = 1
		stars.ClipsDescendants = true
		stars.ZIndex = 1
		stars.Parent = frame
		Instance.new("UICorner", stars).CornerRadius = UDim.new(0, 14)

		local rng = Random.new(1234)
		for i = 1, 60 do
			local size = 1
			local roll = rng:NextNumber()
			if roll < 0.15 then
				size = 3
			elseif roll < 0.5 then
				size = 2
			end
			local star = Instance.new("Frame")
			star.Size = UDim2.new(0, size, 0, size)
			star.Position = UDim2.new(rng:NextNumber(0.03, 0.97), 0, rng:NextNumber(0.02, 0.98), 0)
			star.BorderSizePixel = 0
			if i % 5 == 0 then
				star.BackgroundColor3 = Color3.fromRGB(190, 170, 255)
			elseif i % 7 == 0 then
				star.BackgroundColor3 = Color3.fromRGB(170, 215, 255)
			else
				star.BackgroundColor3 = Color3.new(1, 1, 1)
			end
			star.BackgroundTransparency = rng:NextNumber(0.05, 0.65)
			star.ZIndex = 1
			star.Parent = stars
			if size > 1 then
				Instance.new("UICorner", star).CornerRadius = UDim.new(1, 0)
			end
		end
	end)
	if not galaxyOk then
		warn("[Voidscope Recolor] galaxy background skipped: " .. tostring(galaxyErr))
		frame.BackgroundColor3 = Color3.fromRGB(4, 2, 12)
	end

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
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	local list = Instance.new("UIListLayout", content)
	list.Padding = UDim.new(0, 5)
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
	title.TextStrokeTransparency = 0.45
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
		b.BorderSizePixel = 0
		photoText(b, 18)
		b.Text = text
		b.Parent = header
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
		return b
	end
	local minBtn = headerButton("-", -34, Color3.fromRGB(40, 40, 60))
	local closeBtn = headerButton("X", 0, Color3.fromRGB(170, 40, 40))

	-- colour buttons (one per line, scrolls)
	local grid = Instance.new("ScrollingFrame") -- one colour per line, scrolls like the photo
	grid.Name = "Colours"
	grid.LayoutOrder = nextOrder()
	grid.Size = UDim2.new(1, 0, 0, 250)
	grid.BackgroundTransparency = 1
	grid.BorderSizePixel = 0
	grid.CanvasSize = UDim2.new(0, 0, 0, 0)
	grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
	grid.ScrollingDirection = Enum.ScrollingDirection.Y
	grid.ScrollBarThickness = 4
	grid.ScrollBarImageColor3 = Color3.fromRGB(200, 190, 255)
	grid.Parent = content
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(1, -10, 0, 30)
	gridLayout.CellPadding = UDim2.new(0, 0, 0, 6)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = grid

	for i, entry in ipairs(COLORS) do
		local btn = Instance.new("TextButton")
		btn.LayoutOrder = i
		btn.BackgroundColor3 = entry.color
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = true
		photoText(btn, 14)
		btn.Text = string.upper(entry.name)
		if entry.gradient then
			local holder = Instance.new("Frame")
			holder.LayoutOrder = i
			holder.BackgroundTransparency = 1
			holder.Parent = grid
			local fill = Instance.new("Frame")
			fill.Size = UDim2.new(1, 0, 1, 0)
			fill.BackgroundColor3 = Color3.new(1, 1, 1)
			fill.BorderSizePixel = 0
			fill.ZIndex = 1
			fill.Parent = holder
			Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 8)
			local fillGradient = Instance.new("UIGradient")
			fillGradient.Color = RAINBOW_SEQUENCE
			fillGradient.Parent = fill
			btn.LayoutOrder = 1
			btn.Size = UDim2.new(1, 0, 1, 0)
			btn.BackgroundTransparency = 1
			btn.ZIndex = 2
			btn.Parent = holder
		else
			btn.Parent = grid
		end
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
		local stroke = Instance.new("UIStroke")
		stroke.Color = BUTTON_OUTLINE
		stroke.Thickness = 1
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = btn
		btn.MouseButton1Click:Connect(function()
			applyColor(entry)
		end)
		buttons[entry.name] = btn
	end

	-- Chroma (full-width rainbow bar)
	local specialRow = Instance.new("Frame")
	specialRow.Name = "SpecialRow"
	specialRow.LayoutOrder = nextOrder()
	specialRow.Size = UDim2.new(1, 0, 0, 30)
	specialRow.BackgroundTransparency = 1
	specialRow.Parent = content
	local specialLayout = Instance.new("UIListLayout")
	specialLayout.FillDirection = Enum.FillDirection.Horizontal
	specialLayout.Padding = UDim.new(0, 6)
	specialLayout.SortOrder = Enum.SortOrder.LayoutOrder
	specialLayout.Parent = specialRow

	local rainbowHolder = Instance.new("Frame")
	rainbowHolder.Name = "RainbowHolder"
	rainbowHolder.LayoutOrder = 1
	rainbowHolder.Size = UDim2.new(1, 0, 1, 0)
	rainbowHolder.BackgroundTransparency = 1
	rainbowHolder.Parent = specialRow

	local rainbowFill = Instance.new("Frame")
	rainbowFill.Size = UDim2.new(1, 0, 1, 0)
	rainbowFill.BackgroundColor3 = Color3.new(1, 1, 1)
	rainbowFill.BorderSizePixel = 0
	rainbowFill.ZIndex = 1
	rainbowFill.Parent = rainbowHolder
	Instance.new("UICorner", rainbowFill).CornerRadius = UDim.new(0, 8)
	local rainbowGradient = Instance.new("UIGradient")
	rainbowGradient.Color = RAINBOW_SEQUENCE
	rainbowGradient.Parent = rainbowFill

	local rainbowBtn = Instance.new("TextButton")
	rainbowBtn.Size = UDim2.new(1, 0, 1, 0)
	rainbowBtn.BackgroundTransparency = 1
	rainbowBtn.BorderSizePixel = 0
	photoText(rainbowBtn, 15)
	rainbowBtn.Text = string.upper(RAINBOW.name)
	rainbowBtn.ZIndex = 2
	rainbowBtn.Parent = rainbowHolder
	Instance.new("UICorner", rainbowBtn).CornerRadius = UDim.new(0, 8)
	local rainbowStroke = Instance.new("UIStroke")
	rainbowStroke.Color = BUTTON_OUTLINE
	rainbowStroke.Thickness = 1
	rainbowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	rainbowStroke.Parent = rainbowBtn
	rainbowBtn.MouseButton1Click:Connect(function()
		applyColor(RAINBOW)
	end)
	buttons[RAINBOW.name] = rainbowBtn

	-- Glass: frosted light-blue like the buttons in the photo
	local glassBtn = Instance.new("TextButton")
	glassBtn.LayoutOrder = #COLORS + 1
	glassBtn.BackgroundColor3 = Color3.fromRGB(170, 220, 255)
	glassBtn.BackgroundTransparency = 0.45
	glassBtn.BorderSizePixel = 0
	photoText(glassBtn, 14)
	glassBtn.Text = string.upper(GLASS.name)
	glassBtn.Parent = grid
	Instance.new("UICorner", glassBtn).CornerRadius = UDim.new(0, 8)
	local glassStroke = Instance.new("UIStroke")
	glassStroke.Color = BUTTON_OUTLINE
	glassStroke.Thickness = 1
	glassStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	glassStroke.Parent = glassBtn
	glassBtn.MouseButton1Click:Connect(function()
		applyColor(GLASS)
	end)
	buttons[GLASS.name] = glassBtn

	glassToggleBtn = Instance.new("TextButton")
	glassToggleBtn.LayoutOrder = nextOrder()
	glassToggleBtn.Size = UDim2.new(1, 0, 0, 30)
	glassToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
	glassToggleBtn.BorderSizePixel = 0
	photoText(glassToggleBtn, 14)
	glassToggleBtn.Text = "See-through: OFF"
	glassToggleBtn.Parent = content
	Instance.new("UICorner", glassToggleBtn).CornerRadius = UDim.new(0, 8)
	glassToggleBtn.MouseButton1Click:Connect(function()
		glassOverlay = not glassOverlay
		if selected then
			applyColor(selected) -- repaints with / without the see-through look
		else
			updateStatus()
		end
	end)

	local reset = Instance.new("TextButton")
	reset.LayoutOrder = nextOrder()
	reset.Size = UDim2.new(1, 0, 0, 30)
	reset.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
	reset.BorderSizePixel = 0
	photoText(reset, 14)
	reset.Text = "RESET TO DEFAULT"
	reset.Parent = content
	Instance.new("UICorner", reset).CornerRadius = UDim.new(0, 8)
	reset.MouseButton1Click:Connect(resetColor)

	noteLabel = label(content, nextOrder(), "", 11, Color3.fromRGB(200, 190, 255), 28)
	noteLabel.TextXAlignment = Enum.TextXAlignment.Left
	label(content, nextOrder(), "RightShift = hide / show", 11, Color3.fromRGB(130, 130, 150), 14)

	-- footer
	local handle = label(content, nextOrder(), "insp:kudo", 15, Color3.new(1, 1, 1), 22)
	handle.Font = BUBBLY_FONT
	handle.TextWrapped = false
	handle.TextStrokeColor3 = Color3.new(0, 0, 0)
	handle.TextStrokeTransparency = 0.45

	-- "Are you sure?" popup for the close button
	local confirm = Instance.new("Frame")
	confirm.Name = "ConfirmClose"
	confirm.Size = UDim2.new(1, 0, 1, 0)
	confirm.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	confirm.BackgroundTransparency = 0.15
	confirm.BorderSizePixel = 0
	confirm.Active = true -- stops clicks going through to the buttons underneath
	confirm.Visible = false
	confirm.ZIndex = 20
	confirm.Parent = frame
	Instance.new("UICorner", confirm).CornerRadius = UDim.new(0, 14)

	local confirmText = Instance.new("TextLabel")
	confirmText.AnchorPoint = Vector2.new(0.5, 0.5)
	confirmText.Position = UDim2.new(0.5, 0, 0.38, 0)
	confirmText.Size = UDim2.new(1, -24, 0, 50)
	confirmText.BackgroundTransparency = 1
	confirmText.Font = BUBBLY_FONT
	confirmText.TextSize = 18
	confirmText.TextWrapped = true
	confirmText.TextColor3 = Color3.new(1, 1, 1)
	confirmText.TextStrokeColor3 = Color3.new(0, 0, 0)
	confirmText.TextStrokeTransparency = 0.45
	confirmText.Text = "ARE YOU SURE?"
	confirmText.ZIndex = 21
	confirmText.Parent = confirm

	local function confirmButton(text, xScale, bg)
		local b = Instance.new("TextButton")
		b.AnchorPoint = Vector2.new(0.5, 0.5)
		b.Position = UDim2.new(xScale, 0, 0.7, 0)
		b.Size = UDim2.new(0.4, 0, 0, 32)
		b.BackgroundColor3 = bg
		b.BorderSizePixel = 0
		photoText(b, 15)
		b.Text = text
		b.ZIndex = 21
		b.Parent = confirm
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
		return b
	end
	local yesBtn = confirmButton("YES", 0.28, Color3.fromRGB(170, 40, 40))
	local noBtn = confirmButton("NO", 0.72, Color3.fromRGB(45, 45, 70))

	-- minimise
	local minimised = false
	local imageId = loadIconImage()
	local icon
	if imageId then
		icon = Instance.new("ImageButton")
		icon.Image = imageId
		icon.ScaleType = Enum.ScaleType.Fit
		icon.BackgroundColor3 = Color3.new(0, 0, 0)
		icon.AutoButtonColor = false
	else
		-- drawn-in-code version of the orb picture: black square, white sphere, white ring
		icon = Instance.new("TextButton")
		icon.Text = ""
		icon.AutoButtonColor = false
		icon.BackgroundColor3 = Color3.fromRGB(8, 8, 10)

		local planet = Instance.new("Frame")
		planet.AnchorPoint = Vector2.new(0.5, 0.5)
		planet.Position = UDim2.new(0.5, 0, 0.5, 0)
		planet.Size = UDim2.new(0, 28, 0, 28)
		planet.BorderSizePixel = 0
		planet.BackgroundColor3 = Color3.new(1, 1, 1)
		planet.Parent = icon
		Instance.new("UICorner", planet).CornerRadius = UDim.new(1, 0)
		local planetGradient = Instance.new("UIGradient")
		planetGradient.Rotation = 45
		planetGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.55, Color3.fromRGB(40, 40, 46)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(235, 235, 240)),
		})
		planetGradient.Parent = planet

		local ring = Instance.new("Frame")
		ring.AnchorPoint = Vector2.new(0.5, 0.5)
		ring.Position = UDim2.new(0.5, 0, 0.5, 0)
		ring.Size = UDim2.new(0, 46, 0, 14)
		ring.Rotation = -20
		ring.BackgroundTransparency = 1
		ring.BorderSizePixel = 0
		ring.Parent = icon
		Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
		local ringStroke = Instance.new("UIStroke")
		ringStroke.Color = Color3.new(1, 1, 1)
		ringStroke.Thickness = 3
		ringStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		ringStroke.Parent = ring

		-- tiny stars on the black sphere area and around it
		local specks = { { 0.15, 0.2 }, { 0.82, 0.18 }, { 0.2, 0.8 }, { 0.85, 0.78 }, { 0.5, 0.08 }, { 0.45, 0.5 }, { 0.58, 0.42 } }
		for _, p in ipairs(specks) do
			local dot = Instance.new("Frame")
			dot.Size = UDim2.new(0, 2, 0, 2)
			dot.Position = UDim2.new(p[1], 0, p[2], 0)
			dot.BorderSizePixel = 0
			dot.BackgroundColor3 = Color3.new(1, 1, 1)
			dot.ZIndex = 3
			dot.Parent = icon
		end
	end
	icon.Name = "MiniIcon"
	icon.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
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
