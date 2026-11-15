-- VESTA GEARS MENU
-- Real Roblox gears (loaded with GetObjects) + a menu to give / remove each one.
-- Method is the same as the Crossbow of the Sea script: load the real model, delete its original
-- scripts, and run our own logic on it. If an ID is blank or fails to load, a built-in model is used,
-- so every gear still works.
-- Menu: drag the title bar, "-" minimises, "X" closes the menu (gears stay), RightShift hides/shows.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- ===== GEAR LIST (IDs can also be changed live in the menu) =====
-- id = 0 -> built-in model. rot = optional CFrame.Angles to turn a carpet model that loads sideways.
local GEARS = {
	{ name = "Rainbow Carpet",     kind = "carpet",  id = 225921000,  speed = 90,  color = "rainbow", trail = "rainbow" },
	{ name = "Gold Carpet",        kind = "carpet",  id = 1016183873, speed = 70,  color = Color3.fromRGB(255, 200, 40),
		trail = ColorSequence.new(Color3.fromRGB(255, 200, 40), Color3.fromRGB(255, 240, 150)) },
	{ name = "Black Magic Carpet", kind = "carpet",  id = 402305186,          speed = 110, color = Color3.fromRGB(15, 15, 18),
		trail = ColorSequence.new(Color3.fromRGB(0, 0, 0), Color3.fromRGB(30, 30, 30)), trailEmission = 0 },
	{ name = "Blow Dryer",         kind = "dryer",   id = 11719016 },
	{ name = "Sea Bow",            kind = "seabow",  id = 236438668 },
	{ name = "Gravity Coil",       kind = "gravity", id = 16688968 },
	{ name = "Speed Coil",         kind = "speed",   id = 99119158 },
	{ name = "Rocket Launcher",    kind = "rocket",  id = 32356064 },
}

local SHOT_SOUND_ID = "rbxassetid://99204505"
local HIT_SOUND_ID = "rbxassetid://58274204"
local DRYER_SOUND_ID = "rbxassetid://11717967" -- looping blow dryer motor/air sound

-- ===== helpers =====
local function getChar()
	return player.Character or player.CharacterAdded:Wait()
end

local function getHandle(tool)
	return tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart", true)
end

local function rainbowSequence()
	local keys = {}
	for i = 0, 6 do
		keys[#keys + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 7, 1, 1))
	end
	return ColorSequence.new(keys)
end

local function tintInstance(root, color)
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("MeshPart") or d:IsA("Part") or d:IsA("UnionOperation") then
			d.Color = color
		elseif d:IsA("SpecialMesh") then
			d.VertexColor = Vector3.new(color.R, color.G, color.B)
		end
	end
end

local function addSound(parent, name, id, volume)
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = id
	s.Volume = volume or 0.5
	s.Parent = parent
	return s
end

local function fallbackTool(cfg)
	local tool = Instance.new("Tool")
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	local h = Instance.new("Part")
	h.Name = "Handle"
	h.CanCollide = false
	h.Material = Enum.Material.SmoothPlastic
	if cfg.kind == "carpet" then
		h.Size = Vector3.new(4, 0.3, 6)
		h.Color = (typeof(cfg.color) == "Color3") and cfg.color or Color3.new(1, 0, 0)
	elseif cfg.kind == "dryer" then
		h.Size = Vector3.new(0.8, 0.8, 1.8)
		h.Color = Color3.fromRGB(220, 60, 120)
	elseif cfg.kind == "rocket" then
		h.Size = Vector3.new(1, 1, 4)
		h.Color = Color3.fromRGB(70, 90, 70)
	else
		h.Size = Vector3.new(1, 1, 1)
	end
	h.Parent = tool
	return tool
end

-- returns tool, reason (reason is nil when the real model was loaded)
local function loadTool(cfg)
	local tool, reason
	if cfg.id and cfg.id ~= 0 then
		local ok, objs = pcall(function()
			return game:GetObjects("rbxassetid://" .. cfg.id)
		end)
		if ok and objs and objs[1] then
			if objs[1]:IsA("Tool") then
				tool = objs[1]
			else
				tool = objs[1]:FindFirstChildWhichIsA("Tool", true)
			end
			if not tool then reason = "asset has no Tool inside" end
		else
			reason = "GetObjects failed"
		end
	else
		reason = "no ID set"
	end
	if not tool then tool = fallbackTool(cfg) end
	tool.Name = cfg.name
	for _, d in ipairs(tool:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") then d:Destroy() end
	end
	if not getHandle(tool) then
		local h = Instance.new("Part")
		h.Name = "Handle"
		h.Size = Vector3.new(1, 1, 1)
		h.CanCollide = false
		h.Parent = tool
	end
	tool:SetAttribute("Fallback", reason ~= nil)
	return tool, reason
end

-- ===== CARPETS (held in your hand; WASD / thumbstick flies toward the camera, Space = up, Ctrl = down) =====
local controls
pcall(function()
	controls = require(player.PlayerScripts:WaitForChild("PlayerModule", 3)):GetControls()
end)

local function getMove()
	if controls then
		local ok, v = pcall(function() return controls:GetMoveVector() end)
		if ok and v then return v end
	end
	local x = (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0)
	local z = (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0)
	return Vector3.new(x, 0, z)
end

local function setupCarpet(tool, cfg)
	-- the carpet stays in your hand the whole time; flying is done by moving your character
	local handle = getHandle(tool)
	local bv, bg, loop, trail, a0, a1

	local function stop()
		if loop then loop:Disconnect() loop = nil end
		if bv then bv:Destroy() bv = nil end
		if bg then bg:Destroy() bg = nil end
		if trail then trail:Destroy() trail = nil end
		if a0 then a0:Destroy() a0 = nil end
		if a1 then a1:Destroy() a1 = nil end
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum.PlatformStand = false end
	end

	local function start()
		stop()
		local char = getChar()
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not (hrp and hum and handle) then return end

		-- trail on the carpet in your hand
		local half = handle.Size * 0.45
		a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(-half.X, 0, 0)
		a0.Parent = handle
		a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(half.X, 0, 0)
		a1.Parent = handle
		trail = Instance.new("Trail")
		trail.Attachment0 = a0
		trail.Attachment1 = a1
		trail.Lifetime = 1.2
		trail.LightEmission = cfg.trailEmission or 0.6
		trail.Transparency = NumberSequence.new(0.1, 1)
		if cfg.trail == "rainbow" then
			trail.Color = rainbowSequence()
		elseif cfg.trail then
			trail.Color = cfg.trail
		end
		trail.Parent = handle

		hum.PlatformStand = true
		bv = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
		bv.Velocity = Vector3.zero
		bv.Parent = hrp
		bg = Instance.new("BodyGyro")
		bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
		bg.P = 9000
		bg.D = 600
		bg.CFrame = hrp.CFrame
		bg.Parent = hrp

		local fallback = tool:GetAttribute("Fallback")
		local hue = 0
		loop = RunService.Heartbeat:Connect(function(dt)
			if not hrp.Parent then return stop() end
			local cam = workspace.CurrentCamera.CFrame
			local mv = getMove()
			local dir = cam.RightVector * mv.X + cam.LookVector * -mv.Z
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis end
			bv.Velocity = (dir.Magnitude > 0.05) and (dir.Unit * cfg.speed) or Vector3.zero
			local flat = Vector3.new(cam.LookVector.X, 0, cam.LookVector.Z)
			if flat.Magnitude > 0.01 then
				bg.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + flat)
			end
			-- real models keep their own look; the built-in carpet gets the colour effect
			if fallback then
				if cfg.color == "rainbow" then
					hue = (hue + dt * 0.4) % 1
					tintInstance(tool, Color3.fromHSV(hue, 1, 1))
				elseif typeof(cfg.color) == "Color3" then
					tintInstance(tool, cfg.color)
				end
			end
		end)
	end

	tool.Equipped:Connect(start)
	tool.Unequipped:Connect(stop)
	tool.Destroying:Connect(stop)
end

-- ===== COILS =====
local function setupGravity(tool)
	local force, loop
	local function stop()
		if loop then loop:Disconnect() loop = nil end
		if force then force:Destroy() force = nil end
	end
	tool.Equipped:Connect(function()
		stop()
		local hrp = getChar():FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		force = Instance.new("BodyForce")
		force.Parent = hrp
		loop = RunService.Heartbeat:Connect(function()
			if not hrp.Parent then return stop() end
			force.Force = Vector3.new(0, hrp.AssemblyMass * workspace.Gravity * 0.75, 0)
		end)
	end)
	tool.Unequipped:Connect(stop)
	tool.Destroying:Connect(stop)
end

local function setupSpeed(tool)
	local old
	local function restore()
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum and old then hum.WalkSpeed = old end
		old = nil
	end
	tool.Equipped:Connect(function()
		local hum = getChar():FindFirstChildOfClass("Humanoid")
		if hum then
			old = old or hum.WalkSpeed
			hum.WalkSpeed = 40
		end
	end)
	tool.Unequipped:Connect(restore)
	tool.Destroying:Connect(restore)
end

-- ===== BLOW DRYER (hold click: loud air blast toward your mouse, pushes parts, light recoil on you) =====
local function setupDryer(tool)
	local handle = getHandle(tool)
	local holding = false
	local loopConn

	local wind = addSound(handle, "Blow", DRYER_SOUND_ID, 0.7)
	wind.Looped = true

	-- the attachment is turned toward your mouse every frame, so the air always leaves the nozzle toward where you aim
	local att = Instance.new("Attachment")
	att.Name = "WindOrigin"
	att.Parent = handle

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Wind"
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(0.5, 0.9)
	emitter.Speed = NumberRange.new(55, 70)
	emitter.SpreadAngle = Vector2.new(10, 10)
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 2.5) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 225, 240))
	emitter.LightEmission = 0.3
	emitter.EmitDirection = Enum.NormalId.Front
	emitter.Parent = att

	local RANGE, PUSH, RECOIL = 32, 90, 45

	local function stopBlowing()
		holding = false
		emitter.Rate = 0
		wind:Stop()
		if loopConn then loopConn:Disconnect() loopConn = nil end
	end

	local function startBlowing()
		if holding then return end
		local char = getChar()
		local hrp = char:FindFirstChild("HumanoidRootPart")
		holding = true
		emitter.Rate = 150
		wind:Play()

		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { char }

		local acc = 0
		loopConn = RunService.Heartbeat:Connect(function(dt)
			if not (holding and tool.Parent == char and handle.Parent) then return stopBlowing() end
			local origin = handle.Position
			local aim = mouse.Hit.Position - origin
			if aim.Magnitude < 0.1 then return end
			local look = aim.Unit
			att.WorldCFrame = CFrame.lookAt(origin, origin + look)

			-- recoil: the blast gently pushes you the other way
			if hrp and hrp.Parent then
				hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity - look * RECOIL * dt
			end

			-- push loose parts and other players in the cone (only parts your client owns will really move)
			acc += dt
			if acc >= 0.1 then
				acc = 0
				for _, p in ipairs(workspace:GetPartBoundsInRadius(origin + look * (RANGE / 2), RANGE / 2, params)) do
					if not p.Anchored then
						local to = p.Position - origin
						if to.Magnitude > 0.1 and to.Unit:Dot(look) > 0.7 then
							p.AssemblyLinearVelocity = p.AssemblyLinearVelocity + look * PUSH * 0.3
						end
					end
				end
			end
		end)
	end

	tool.Activated:Connect(startBlowing)
	tool.Deactivated:Connect(stopBlowing)
	tool.Unequipped:Connect(stopBlowing)
	tool.Destroying:Connect(stopBlowing)
end

-- ===== ROCKET LAUNCHER =====
local function setupRocket(tool)
	local handle = getHandle(tool)
	local ready = true
	addSound(handle, "Shot", SHOT_SOUND_ID, 0.6)

	tool.Activated:Connect(function()
		if not ready then return end
		ready = false
		local char = getChar()
		handle.Shot.Pitch = math.random(90, 110) / 100
		handle.Shot:Play()

		local rocket = Instance.new("Part")
		rocket.Name = "Rocket"
		rocket.Size = Vector3.new(0.6, 0.6, 3)
		rocket.Color = Color3.fromRGB(200, 60, 40)
		rocket.Material = Enum.Material.Metal
		rocket.CanCollide = false
		rocket.CFrame = CFrame.new(handle.Position, mouse.Hit.Position)
		rocket.Parent = workspace
		local bf = Instance.new("BodyForce")
		bf.Force = Vector3.new(0, rocket:GetMass() * workspace.Gravity, 0)
		bf.Parent = rocket
		rocket.AssemblyLinearVelocity = rocket.CFrame.LookVector * 140
		local fire = Instance.new("Fire")
		fire.Size = 5
		fire.Parent = rocket
		addSound(rocket, "Hit", HIT_SOUND_ID, 1)

		local conn
		conn = rocket.Touched:Connect(function(part)
			if part:IsDescendantOf(char) or part:IsDescendantOf(tool) then return end
			conn:Disconnect()
			local pos = rocket.Position
			local ex = Instance.new("Explosion")
			ex.Position = pos
			ex.BlastRadius = 12
			ex.BlastPressure = 0
			ex.DestroyJointRadiusPercent = 0
			ex.Parent = workspace
			rocket.Hit:Play()
			-- rocket jump
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local d = hrp.Position - pos
				if d.Magnitude < 14 and d.Magnitude > 0.01 then
					hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + d.Unit * (90 * (1 - d.Magnitude / 14) + 20)
				end
			end
			rocket.Transparency = 1
			rocket.Anchored = true
			fire.Enabled = false
		end)
		Debris:AddItem(rocket, 6)
		task.delay(1.5, function() ready = true end)
	end)
end

-- ===== SEA BOW (same behaviour as the Crossbow of the Sea script) =====
local function createWaterExplosion(point)
	local scale = 8 + (4 * math.random(1, 3))
	local terrain = workspace.Terrain
	terrain:FillBall(point, scale, Enum.Material.Water)
	task.delay(7, function()
		terrain:FillBall(point, scale, Enum.Material.Air)
	end)
end

local function createArrow()
	local arrow = Instance.new("Part")
	arrow.Name = "SeaArrow"
	arrow.Size = Vector3.new(0.2, 0.2, 2.5)
	arrow.Transparency = 0.25
	arrow.Reflectance = 0.5
	arrow.CanCollide = false
	arrow.Material = Enum.Material.SmoothPlastic
	arrow.BrickColor = BrickColor.new("Cyan")
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshId = "rbxassetid://235107348"
	mesh.TextureId = "rbxassetid://235107780"
	mesh.Parent = arrow
	addSound(arrow, "Hit", HIT_SOUND_ID, 1)
	return arrow
end

local function setupSeaBow(tool)
	local handle = getHandle(tool)
	addSound(handle, "Shot", SHOT_SOUND_ID, 0.5)
	local ready = true

	tool.Activated:Connect(function()
		if not ready then return end
		ready = false
		local char = getChar()
		handle.Shot.Pitch = math.random(90, 110) / 100
		handle.Shot:Play()

		local arrow = createArrow()
		arrow.CFrame = CFrame.new(handle.Position, mouse.Hit.Position)
		arrow.Velocity = arrow.CFrame.LookVector * 120
		arrow.Parent = workspace

		local conn
		conn = arrow.Touched:Connect(function(part)
			if part:IsDescendantOf(char) then return end
			createWaterExplosion(arrow.Position)
			arrow.Hit:Play()
			arrow.Anchored = true
			arrow.Transparency = 1
			conn:Disconnect()
		end)
		Debris:AddItem(arrow, 8)
		task.delay(1.2, function() ready = true end)
	end)
end

-- smoother jump out of water while the Sea Bow is equipped
do
	local JUMP_POWER, BOOST_FRAMES = 78, 8
	UserInputService.JumpRequest:Connect(function()
		local char = player.Character
		if not (char and char:FindFirstChild("Sea Bow")) then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		local root = char:FindFirstChild("HumanoidRootPart")
		if not (hum and root) then return end
		local st = hum:GetState()
		if st ~= Enum.HumanoidStateType.Swimming and st ~= Enum.HumanoidStateType.GettingUp then return end
		hum:ChangeState(Enum.HumanoidStateType.Jumping)
		local v = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity = Vector3.new(v.X, JUMP_POWER, v.Z)
		task.spawn(function()
			for _ = 1, BOOST_FRAMES do
				if not root.Parent then break end
				if root.AssemblyLinearVelocity.Y < JUMP_POWER * 0.7 then
					local cur = root.AssemblyLinearVelocity
					root.AssemblyLinearVelocity = Vector3.new(cur.X, math.max(cur.Y, JUMP_POWER * 0.85), cur.Z)
				end
				RunService.Heartbeat:Wait()
			end
		end)
	end)
end

-- ===== give / remove =====
local SETUP = {
	carpet = setupCarpet, dryer = setupDryer, seabow = setupSeaBow,
	gravity = setupGravity, speed = setupSpeed, rocket = setupRocket,
}

local active = {} -- name -> tool
local wanted = {} -- name -> true (given again after respawn)

local function removeGear(cfg)
	wanted[cfg.name] = nil
	local t = active[cfg.name]
	if t then pcall(function() t:Destroy() end) end
	active[cfg.name] = nil
end

-- returns ok, message
local function giveGear(cfg)
	removeGear(cfg)
	local backpack = player:WaitForChild("Backpack")
	local result, reason
	local ok, err = pcall(function()
		local tool, why = loadTool(cfg)
		SETUP[cfg.kind](tool, cfg)
		tool.Parent = backpack
		active[cfg.name] = tool
		reason = why
	end)
	if not ok then
		return false, cfg.name .. " failed: " .. tostring(err)
	end
	wanted[cfg.name] = true
	if reason then
		return true, cfg.name .. ": built-in model (" .. reason .. ")"
	end
	return true, cfg.name .. ": real Roblox gear loaded"
end

-- ===== MENU =====
local rows = {}
local statusLabel

local function status(msg)
	if statusLabel then statusLabel.Text = msg end
end

local function buildGui()
	local genv = (getgenv and getgenv()) or _G
	if genv.VestaGearsGui then pcall(function() genv.VestaGearsGui:Destroy() end) end

	local gui = Instance.new("ScreenGui")
	gui.Name = "VestaGears"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 999
	local okParent = pcall(function()
		gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
	end)
	if not okParent or not gui.Parent then
		gui.Parent = player:WaitForChild("PlayerGui")
	end
	genv.VestaGearsGui = gui

	local function mk(class, props, parent)
		local o = Instance.new(class)
		for k, v in pairs(props) do o[k] = v end
		o.Parent = parent
		return o
	end
	local function round(o, r)
		mk("UICorner", { CornerRadius = UDim.new(0, r or 8) }, o)
	end

	local BG = Color3.fromRGB(14, 14, 20)
	local PANEL = Color3.fromRGB(26, 26, 38)
	local ACCENT = Color3.fromRGB(120, 90, 230)
	local OFF = Color3.fromRGB(46, 46, 64)

	local frame = mk("Frame", {
		Name = "Main", Size = UDim2.new(0, 340, 0, 372), Position = UDim2.new(0.5, -170, 0.5, -186),
		BackgroundColor3 = BG, BorderSizePixel = 0, Active = true,
	}, gui)
	round(frame, 12)
	mk("UIStroke", { Color = ACCENT, Thickness = 1.5, Transparency = 0.3 }, frame)

	-- title bar (drag handle)
	local bar = mk("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = PANEL, BorderSizePixel = 0 }, frame)
	round(bar, 12)
	mk("TextLabel", {
		Size = UDim2.new(1, -80, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold, Text = "VESTA GEARS", TextSize = 15, TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, bar)
	local minBtn = mk("TextButton", {
		Size = UDim2.new(0, 28, 0, 24), Position = UDim2.new(1, -66, 0, 5), BackgroundColor3 = OFF,
		Font = Enum.Font.GothamBold, Text = "-", TextSize = 16, TextColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
	}, bar)
	round(minBtn, 6)
	local closeBtn = mk("TextButton", {
		Size = UDim2.new(0, 28, 0, 24), Position = UDim2.new(1, -34, 0, 5), BackgroundColor3 = Color3.fromRGB(125, 30, 30),
		Font = Enum.Font.GothamBold, Text = "X", TextSize = 14, TextColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
	}, bar)
	round(closeBtn, 6)

	local dragging, dragStart, startPos
	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	local body = mk("Frame", { Size = UDim2.new(1, 0, 1, -34), Position = UDim2.new(0, 0, 0, 34), BackgroundTransparency = 1 }, frame)

	local list = mk("ScrollingFrame", {
		Size = UDim2.new(1, -16, 1, -92), Position = UDim2.new(0, 8, 0, 8), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, body)
	mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, list)

	for i, cfg in ipairs(GEARS) do
		local row = mk("Frame", { Size = UDim2.new(1, -6, 0, 34), BackgroundColor3 = PANEL, BorderSizePixel = 0, LayoutOrder = i }, list)
		round(row, 8)
		mk("TextLabel", {
			Size = UDim2.new(0.38, 0, 1, 0), Position = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium, Text = cfg.name, TextSize = 12, TextColor3 = Color3.new(1, 1, 1),
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
		}, row)
		local box = mk("TextBox", {
			Size = UDim2.new(0.32, 0, 0, 24), Position = UDim2.new(0.4, 0, 0, 5), BackgroundColor3 = BG,
			Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Color3.new(1, 1, 1),
			PlaceholderText = "ID (blank = built-in)", PlaceholderColor3 = Color3.fromRGB(120, 120, 140),
			Text = (cfg.id ~= 0) and tostring(cfg.id) or "", ClearTextOnFocus = false, BorderSizePixel = 0,
		}, row)
		round(box, 6)
		local btn = mk("TextButton", {
			Size = UDim2.new(0.24, 0, 0, 24), Position = UDim2.new(0.74, 0, 0, 5), BackgroundColor3 = OFF,
			Font = Enum.Font.GothamBold, Text = "GIVE", TextSize = 11, TextColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
		}, row)
		round(btn, 6)

		local function setOn(on)
			btn.Text = on and "REMOVE" or "GIVE"
			btn.BackgroundColor3 = on and ACCENT or OFF
		end
		rows[cfg.name] = { setOn = setOn, box = box, cfg = cfg }

		btn.MouseButton1Click:Connect(function()
			local t = active[cfg.name]
			if t and t.Parent then
				removeGear(cfg)
				setOn(false)
				status(cfg.name .. " removed")
			else
				cfg.id = tonumber(string.match(box.Text, "%d+")) or 0
				local _, msg = giveGear(cfg)
				setOn(active[cfg.name] ~= nil)
				status(msg)
			end
		end)
	end

	local function footerButton(text, x, color)
		local b = mk("TextButton", {
			Size = UDim2.new(0.5, -12, 0, 28), Position = UDim2.new(x, x == 0 and 8 or 4, 1, -76), BackgroundColor3 = color,
			Font = Enum.Font.GothamBold, Text = text, TextSize = 12, TextColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
		}, body)
		round(b, 8)
		return b
	end
	local giveAllBtn = footerButton("GIVE ALL", 0, ACCENT)
	local removeAllBtn = footerButton("REMOVE ALL", 0.5, Color3.fromRGB(125, 30, 30))

	statusLabel = mk("TextLabel", {
		Size = UDim2.new(1, -16, 0, 32), Position = UDim2.new(0, 8, 1, -40), BackgroundTransparency = 1,
		Font = Enum.Font.Gotham, Text = "Pick a gear, then equip it from your hotbar.", TextSize = 11,
		TextColor3 = Color3.fromRGB(190, 190, 210), TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
	}, body)

	giveAllBtn.MouseButton1Click:Connect(function()
		local real, built = 0, 0
		for _, cfg in ipairs(GEARS) do
			local r = rows[cfg.name]
			cfg.id = tonumber(string.match(r.box.Text, "%d+")) or 0
			local ok, msg = giveGear(cfg)
			r.setOn(active[cfg.name] ~= nil)
			if ok then
				if string.find(msg, "built%-in") then built += 1 else real += 1 end
			end
		end
		status(("All given: %d real gears, %d built-in."):format(real, built))
	end)
	removeAllBtn.MouseButton1Click:Connect(function()
		for _, cfg in ipairs(GEARS) do
			removeGear(cfg)
			rows[cfg.name].setOn(false)
		end
		status("All gears removed")
	end)

	local collapsed = false
	minBtn.MouseButton1Click:Connect(function()
		collapsed = not collapsed
		body.Visible = not collapsed
		frame.Size = collapsed and UDim2.new(0, 340, 0, 34) or UDim2.new(0, 340, 0, 372)
	end)
	closeBtn.MouseButton1Click:Connect(function()
		gui:Destroy()
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.RightShift and gui.Parent then
			frame.Visible = not frame.Visible
		end
	end)
end

buildGui()

-- give the chosen gears again after every respawn
player.CharacterAdded:Connect(function()
	task.wait(1)
	for _, cfg in ipairs(GEARS) do
		if wanted[cfg.name] then
			giveGear(cfg)
			if rows[cfg.name] then rows[cfg.name].setOn(active[cfg.name] ~= nil) end
		end
	end
end)

print("Vesta Gears menu ready")
