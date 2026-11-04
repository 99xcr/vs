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

-- button shine for the two special scopes (gold bands / icy diamond facets)
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

local COLORS = {
	{ name = "Red",        color = Color3.fromRGB(255, 0, 0) },
	{ name = "Green",      color = Color3.fromRGB(0, 255, 0) },
	{ name = "Black",      color = Color3.fromRGB(0, 0, 0) },
	{ name = "Orange",     color = Color3.fromRGB(255, 128, 0) },
	{ name = "Yellow",     color = Color3.fromRGB(255, 255, 0) },
	{ name = "Blue",       color = Color3.fromRGB(0, 100, 255) },
	{ name = "Purple",     color = Color3.fromRGB(160, 32, 240) },
	{ name = "Cyan",       color = Color3.fromRGB(0, 255, 255) },
	-- PINK: editable image texture, pastel pink body with white texture / detail
	{ name = "Pink",       color = Color3.fromRGB(255, 188, 214), mode = "texture", texStyle = "pink", meshColor = Color3.new(1, 1, 1) },
	{ name = "Rainbow",    color = Color3.fromRGB(255, 60, 200), mode = "texture", texStyle = "rainbow", gradient = true, rainbowFx = true },
	-- GOLD: polished shiny metal, bands of light and deep gold along the gun, warm glints
	{ name = "Gold",       color = Color3.fromRGB(255, 200, 40), mode = "metal", reflectance = 0.7,
		sheenA = Color3.fromRGB(255, 225, 100), sheenB = Color3.fromRGB(255, 150, 30), btnGradient = GOLD_SEQ },
	-- DIAMOND: icy see-through crystal, mirror shine, pink + teal sparkle
	{ name = "Diamond",    color = Color3.fromRGB(185, 242, 255), mode = "diamond", forceGlass = true, glassT = 0.3, reflectance = 0.6,
		sheenA = Color3.fromRGB(150, 240, 255), sheenB = Color3.fromRGB(255, 170, 235), btnGradient = DIAMOND_SEQ },
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
4ScLu7UBMmz5FxdWBLl5pGNN9eTJR5uBkmC6He47Jh2oQG/i3GkAnWvqhVc7a8A8Me2cBbQ1V563218Jp/ozI3/2+
