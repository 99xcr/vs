-- VESTA GEARS: Rainbow Carpet, Gold Carpet, Black Magic Carpet, Blow Dryer, Sea Bow,
-- Gravity Coil, Speed Coil, Rocket Launcher
-- Same method as the Crossbow of the Sea script: load the gear model with GetObjects,
-- delete its original scripts, then run our own logic on it.
-- If an asset ID is 0 (or fails to load) a simple built-in model is used, so every gear still works.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- ===== CONFIG: put the real asset IDs here (0 = use the built-in model) =====
local GEARS = {
	{ name = "Rainbow Carpet",     kind = "carpet",  id = 0, color = "rainbow", speed = 90 },
	{ name = "Gold Carpet",        kind = "carpet",  id = 0, color = Color3.fromRGB(255, 200, 40), speed = 70 },
	{ name = "Black Magic Carpet", kind = "carpet",  id = 0, color = Color3.fromRGB(15, 15, 18), speed = 110 },
	{ name = "Blow Dryer",         kind = "dryer",   id = 0 },
	{ name = "Sea Bow",            kind = "seabow",  id = 236438668 },
	{ name = "Gravity Coil",       kind = "gravity", id = 16688968 },
	{ name = "Speed Coil",         kind = "speed",   id = 99170 },
	{ name = "Rocket Launcher",    kind = "rocket",  id = 0 },
}

local SHOT_SOUND_ID = "rbxassetid://99204505"
local HIT_SOUND_ID = "rbxassetid://58274204"

-- ===== helpers =====
local function getChar()
	return player.Character or player.CharacterAdded:Wait()
end

local function getHandle(tool)
	return tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart", true)
end

local function tintInstance(root, color)
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("MeshPart") or d:IsA("Part") or d:IsA("UnionOperation") then
			d.Color = color
		elseif d:IsA("SpecialMesh") then
			d.VertexColor = Vector3.new(color.R, color.G, color.B)
		end
	end
	if root:IsA("BasePart") then root.Color = color end
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
		tool.GripPos = Vector3.new(0, 0, 0)
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

local function loadTool(cfg)
	local tool
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
		else
			warn(cfg.name .. ": GetObjects failed, using built-in model.")
		end
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
	return tool
end

local function addSound(parent, name, id, volume)
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = id
	s.Volume = volume or 0.5
	s.Parent = parent
	return s
end

-- ===== CARPETS (fly with WASD / thumbstick, Space = up, Ctrl = down) =====
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
	local handle = getHandle(tool)
	local carpet, bv, bg, loop, dead

	local function stop()
		if loop then loop:Disconnect() loop = nil end
		if bv then bv:Destroy() bv = nil end
		if bg then bg:Destroy() bg = nil end
		if carpet then carpet:Destroy() carpet = nil end
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then hum.PlatformStand = false end
		for _, p in ipairs(tool:GetDescendants()) do
			if p:IsA("BasePart") then p.LocalTransparencyModifier = 0 end
		end
	end

	local function start()
		stop()
		local char = getChar()
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not (hrp and hum and handle) then return end

		-- visible carpet under the feet, the held one is hidden
		carpet = handle:Clone()
		carpet.Name = "FlyingCarpet"
		carpet.Anchored = false
		carpet.CanCollide = false
		carpet.Massless = true
		carpet.CFrame = hrp.CFrame * CFrame.new(0, -2.9, 0)
		carpet.Parent = char
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hrp
		weld.Part1 = carpet
		weld.Parent = carpet
		for _, p in ipairs(tool:GetDescendants()) do
			if p:IsA("BasePart") then p.LocalTransparencyModifier = 1 end
		end

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

		local hue = 0
		loop = RunService.Heartbeat:Connect(function(dt)
			if not (hrp.Parent and carpet) then return stop() end
			local cam = workspace.CurrentCamera.CFrame
			local mv = getMove()
			local dir = cam.RightVector * mv.X + cam.LookVector * -mv.Z
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis end
			if dir.Magnitude > 0.05 then
				bv.Velocity = dir.Unit * cfg.speed
			else
				bv.Velocity = Vector3.zero
			end
			local flat = Vector3.new(cam.LookVector.X, 0, cam.LookVector.Z)
			if flat.Magnitude > 0.01 then
				bg.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + flat)
			end
			if cfg.color == "rainbow" then
				hue = (hue + dt * 0.4) % 1
				tintInstance(carpet, Color3.fromHSV(hue, 1, 1))
			elseif typeof(cfg.color) == "Color3" then
				tintInstance(carpet, cfg.color)
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
	tool.Equipped:Connect(function()
		local hum = getChar():FindFirstChildOfClass("Humanoid")
		if hum then
			old = old or hum.WalkSpeed
			hum.WalkSpeed = 40
		end
	end)
	tool.Unequipped:Connect(function()
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum and old then hum.WalkSpeed = old end
		old = nil
	end)
end

-- ===== BLOW DRYER (hold click: wind pushes things in front) =====
local function setupDryer(tool)
	local handle = getHandle(tool)
	local holding = false
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Wind"
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(0.5, 0.9)
	emitter.Speed = NumberRange.new(45, 60)
	emitter.SpreadAngle = Vector2.new(12, 12)
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 2) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 220, 235))
	emitter.EmitDirection = Enum.NormalId.Front
	emitter.Parent = handle

	local RANGE, PUSH = 28, 70
	tool.Activated:Connect(function()
		if holding then return end
		holding = true
		emitter.Rate = 120
		while holding and tool.Parent do
			local origin = handle.Position
			local look = (mouse.Hit.Position - origin).Unit
			for _, p in ipairs(workspace:GetPartBoundsInRadius(origin + look * (RANGE / 2), RANGE / 2)) do
				if not p.Anchored and not p:IsDescendantOf(tool.Parent) then
					local to = p.Position - origin
					if to.Magnitude > 0.1 and to.Unit:Dot(look) > 0.75 then
						p.AssemblyLinearVelocity = p.AssemblyLinearVelocity + look * PUSH * 0.2
					end
				end
			end
			task.wait(0.1)
		end
	end)
	tool.Deactivated:Connect(function()
		holding = false
		emitter.Rate = 0
	end)
	tool.Unequipped:Connect(function()
		holding = false
		emitter.Rate = 0
	end)
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

		local target = mouse.Hit.Position
		local rocket = Instance.new("Part")
		rocket.Name = "Rocket"
		rocket.Size = Vector3.new(0.6, 0.6, 3)
		rocket.Color = Color3.fromRGB(200, 60, 40)
		rocket.Material = Enum.Material.Metal
		rocket.CanCollide = false
		rocket.CFrame = CFrame.new(handle.Position, target)
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
			-- rocket jump: blast knocks you back if you are close
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local d = hrp.Position - pos
				if d.Magnitude < 14 then
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

-- smoother jump out of water (shared by all gears, connected once)
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

-- ===== give everything (and again after every respawn) =====
local SETUP = {
	carpet = setupCarpet, dryer = setupDryer, seabow = setupSeaBow,
	gravity = setupGravity, speed = setupSpeed, rocket = setupRocket,
}

local function giveAll()
	local backpack = player:WaitForChild("Backpack")
	for _, cfg in ipairs(GEARS) do
		local ok, err = pcall(function()
			local tool = loadTool(cfg)
			SETUP[cfg.kind](tool, cfg)
			tool.Parent = backpack
		end)
		if not ok then warn(cfg.name .. " failed: " .. tostring(err)) end
	end
end

giveAll()
player.CharacterAdded:Connect(function()
	task.wait(1)
	giveAll()
end)

print("Vesta Gears ready: Rainbow/Gold/Black carpets, Blow Dryer, Sea Bow, Gravity Coil, Speed Coil, Rocket Launcher")
