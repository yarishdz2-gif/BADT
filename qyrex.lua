local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local CONFIG = {
	Version = "Qyrex AntiCheat SERVER 7.0",
	WarningLifetime = 5,
	MaxWarnings = 3,

	SampleRate = 0.10,
	PropertyScanRate = 0.25,
	PhysicsScanRate = 0.50,

	SpawnGrace = 5,

	MaxWalkSpeed = 20,
	MaxJumpPower = 55,
	MaxJumpHeight = 8.5,
	MaxHealth = 150,
	MaxHipHeight = 6,

	MaxVelocity = 105,
	MaxHorizontalVelocity = 48,
	MaxAngularVelocity = 90,

	MaxTeleportDistance = 65,

	FlyTime = 2.35,
	HoverTime = 1.20,
	NoclipTime = 0.90,

	JumpWindow = 1.35,
	MaxJumpsInWindow = 6,

	WarningCooldown = 1.35,
	SameDetectionCooldown = 2.50,

	HoneypotKick = true,
	WatchdogRemoteCount = 10,

	Debug = false,
}

local COLORS = {
	Background = Color3.fromRGB(5, 8, 14),
	Panel = Color3.fromRGB(9, 14, 24),
	Panel2 = Color3.fromRGB(13, 20, 33),
	Cyan = Color3.fromRGB(67, 214, 255),
	Cyan2 = Color3.fromRGB(91, 144, 255),
	Green = Color3.fromRGB(65, 240, 165),
	Yellow = Color3.fromRGB(255, 190, 70),
	Red = Color3.fromRGB(255, 78, 98),
	White = Color3.fromRGB(240, 248, 255),
	Muted = Color3.fromRGB(130, 158, 190),
}

local WHITELIST = {
}

local states = {}
local lastGlobalScan = 0

local protectedFolder =
	ReplicatedStorage:FindFirstChild("_QYREX_SECURITY_CORE")

if protectedFolder then
	protectedFolder:Destroy()
end

protectedFolder = Instance.new("Folder")
protectedFolder.Name = "_QYREX_SECURITY_CORE"
protectedFolder.Parent = ReplicatedStorage

local reportRemote = Instance.new("RemoteEvent")
reportRemote.Name = "_Report"
reportRemote.Parent = protectedFolder

local honeypots = {}

local function makeRandomName(prefix)
	return prefix ..
		string.gsub(
			HttpService:GenerateGUID(false),
			"-",
			""
		):sub(1, 20)
end

for i = 1, CONFIG.WatchdogRemoteCount do
	local remote = Instance.new("RemoteEvent")

	remote.Name = makeRandomName("_QX_")
	remote:SetAttribute("QyrexHoneypot", true)
	remote.Parent = protectedFolder

	table.insert(
		honeypots,
		remote
	)
end

local invokeTrap = Instance.new("RemoteFunction")
invokeTrap.Name = makeRandomName("_RF_")
invokeTrap:SetAttribute("QyrexHoneypot", true)
invokeTrap.Parent = protectedFolder

local openings = {
	"Qyrex Security Core detected an abnormal gameplay state.",
	"A protected character validation has been triggered.",
	"The server detected an irregular movement signature.",
	"A server-side integrity check failed.",
	"An abnormal character property was detected.",
	"Protected gameplay limits were exceeded.",
	"The movement validator detected an unexpected state.",
	"Qyrex identified suspicious character behavior.",
	"The server observed a persistent gameplay anomaly.",
	"A physics integrity check returned an abnormal result.",
	"The character controller entered a protected invalid state.",
	"An anti-cheat threshold was crossed by the current session.",
	"The server detected behavior outside the configured limits.",
	"A protected movement sample was classified as abnormal.",
	"The security core identified a suspicious state transition.",
	"An integrity monitor detected an unexpected character value.",
	"Qyrex recorded an abnormal movement event.",
	"The server-side protection layer raised an alert.",
	"A protected physics rule has been triggered.",
	"The current character state does not match the expected model.",
	"A movement integrity check detected an anomaly.",
	"A server validation rule has been activated.",
	"An unexpected character configuration was detected.",
	"The session produced a protected security event.",
	"Qyrex detected abnormal gameplay behavior.",
	"An integrity threshold was exceeded repeatedly.",
	"The server recorded a non-standard character state.",
	"A protected gameplay property entered an invalid range.",
	"The security monitor detected inconsistent movement data.",
	"A protected server check reported an anomaly.",
	"The player state crossed a protected safety threshold.",
	"Qyrex Security Core detected a suspicious gameplay pattern.",
}

local details = {
	"The server compared several recent samples before confirming the event.",
	"The event remained outside the allowed tolerance long enough to be confirmed.",
	"A short frame spike was filtered before this warning was generated.",
	"The anomaly persisted across multiple server validation cycles.",
	"The server-side validator compared movement and character state together.",
	"The current value exceeded the configured gameplay envelope.",
	"The server detected a difference between expected and observed behavior.",
	"The event crossed a threshold reserved for abnormal gameplay.",
	"Multiple samples contributed to the current security classification.",
	"Recent character data did not match the configured movement model.",
	"The protection layer ignored transient values and monitored the next samples.",
	"The anomaly remained consistent after anti-false-positive filtering.",
	"The detected state was outside the normal gameplay range.",
	"Server validation produced a result inconsistent with ordinary movement.",
	"The current character state produced a protected integrity violation.",
	"The security monitor confirmed the event over more than one sample.",
	"The current physics signature differs from normal player movement.",
	"Qyrex compared velocity, position and humanoid state before reporting it.",
	"The event was confirmed by server-side observation.",
	"Protected values were outside their expected range.",
	"The server observed a persistent mismatch in character behavior.",
	"Recent movement samples showed an abnormal pattern.",
	"The security core classified this event after repeated validation.",
	"A protected character property exceeded its configured tolerance.",
}

local actions = {
	"Please return to normal gameplay.",
	"Continue normally and this notice will close automatically.",
	"Repeated confirmed violations can result in removal from the server.",
	"Your session remains under active server monitoring.",
	"Avoid repeating the detected behavior.",
	"The security monitor will continue checking the session.",
	"This notice is informational and will close automatically.",
	"The server has recorded this incident for the current session.",
}

local warningVariantCount =
	#openings *
	#details *
	#actions

local function getWarningVariant()
	local index =
		math.random(
			1,
			warningVariantCount
		)

	local value = index - 1

	local a =
		(value % #openings) + 1

	value =
		math.floor(
			value / #openings
		)

	local b =
		(value % #details) + 1

	value =
		math.floor(
			value / #details
		)

	local c =
		(value % #actions) + 1

	return
		openings[a]
		.. " "
		.. details[b]
		.. " "
		.. actions[c]
end

local function isWhitelisted(player)
	return WHITELIST[player.UserId] == true
end

local function getBypass(player, character, humanoid)
	if isWhitelisted(player) then
		return true
	end

	if player:GetAttribute("QyrexAC_Bypass") == true then
		return true
	end

	if character
		and character:GetAttribute("QyrexAC_Bypass") == true then
		return true
	end

	if humanoid
		and humanoid:GetAttribute("QyrexAC_Bypass") == true then
		return true
	end

	return false
end

local function getGraceUntil(player, character)
	local grace =
		workspace:GetServerTimeNow()
		+ CONFIG.SpawnGrace

	local playerGrace =
		player:GetAttribute("QyrexAC_GraceUntil")

	if typeof(playerGrace) == "number" then
		grace =
			math.max(
				grace,
				playerGrace
			)
	end

	if character then
		local characterGrace =
			character:GetAttribute(
				"QyrexAC_GraceUntil"
			)

		if typeof(characterGrace) == "number" then
			grace =
				math.max(
					grace,
					characterGrace
				)
		end
	end

	return grace
end

local function createState(player)
	local state = {
		player = player,

		warnings = 0,
		score = 0,

		trust = 100,

		lastWarning = 0,
		lastDetection = {},

		lastPosition = nil,
		lastSafePosition = nil,

		flyTime = 0,
		hoverTime = 0,
		noclipTime = 0,

		jumpTimes = {},

		lastHealth = nil,
		lastMaxHealth = nil,
		lastHipHeight = nil,

		propertyTimer = 0,
		physicsTimer = 0,

		graceUntil =
			workspace:GetServerTimeNow()
			+ CONFIG.SpawnGrace,

		character = nil,
		humanoid = nil,
		root = nil,

		ui = nil,
		uiSerial = 0,

		connections = {},
	}

	states[player] = state

	return state
end

local function getState(player)
	return states[player]
end

local function cleanupState(state)
	for _, connection in ipairs(state.connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end

	table.clear(state.connections)

	if state.ui and state.ui.Parent then
		state.ui:Destroy()
	end

	state.ui = nil
end

local function createLabel(
	parent,
	text,
	textSize,
	position,
	size,
	color,
	font
)
	local label = Instance.new("TextLabel")

	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextSize = textSize
	label.Font = font
	label.Position = position
	label.Size = size
	label.TextXAlignment =
		Enum.TextXAlignment.Left
	label.TextYAlignment =
		Enum.TextYAlignment.Center

	label.Parent = parent

	return label
end

local function createCorner(parent, radius)
	local corner =
		Instance.new("UICorner")

	corner.CornerRadius =
		UDim.new(0, radius)

	corner.Parent = parent

	return corner
end

local function createWarningUI(
	player,
	detection,
	code,
	extra
)
	local state =
		states[player]

	if not state then
		return
	end

	state.uiSerial += 1

	local serial =
		state.uiSerial

	if state.ui
		and state.ui.Parent then

		state.ui:Destroy()
	end

	local playerGui =
		player:FindFirstChildOfClass(
			"PlayerGui"
		)

	if not playerGui then
		playerGui =
			player:WaitForChild(
				"PlayerGui",
				5
			)
	end

	if not playerGui then
		return
	end

	local gui =
		Instance.new("ScreenGui")

	gui.Name =
		"QyrexAntiCheatWarning"

	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 100000
	gui.ZIndexBehavior =
		Enum.ZIndexBehavior.Global

	gui.Parent = playerGui

	state.ui = gui

	local overlay =
		Instance.new("Frame")

	overlay.Size =
		UDim2.fromScale(1, 1)

	overlay.BackgroundColor3 =
		Color3.fromRGB(2, 4, 8)

	overlay.BackgroundTransparency =
		0.45

	overlay.BorderSizePixel = 0

	overlay.Parent = gui

	local panel =
		Instance.new("Frame")

	panel.Name =
		"SecurityWarning"

	panel.AnchorPoint =
		Vector2.new(0.5, 0.5)

	panel.Position =
		UDim2.fromScale(
			0.5,
			0.5
		)

	panel.Size =
		UDim2.fromOffset(
			0,
			0
		)

	panel.BackgroundColor3 =
		COLORS.Background

	panel.BorderSizePixel = 0
	panel.ClipsDescendants = true

	panel.Parent = gui

	createCorner(
		panel,
		26
	)

	local stroke =
		Instance.new("UIStroke")

	stroke.Color =
		COLORS.Cyan

	stroke.Thickness = 1.5
	stroke.Transparency = 0.16
	stroke.Parent = panel

	local gradient =
		Instance.new("UIGradient")

	gradient.Rotation = 120

	gradient.Color =
		ColorSequence.new({
			ColorSequenceKeypoint.new(
				0,
				Color3.fromRGB(
					12,
					24,
					40
				)
			),

			ColorSequenceKeypoint.new(
				0.5,
				Color3.fromRGB(
					5,
					9,
					16
				)
			),

			ColorSequenceKeypoint.new(
				1,
				Color3.fromRGB(
					18,
					8,
					27
				)
			),
		})

	gradient.Parent = panel

	local top =
		Instance.new("Frame")

	top.Size =
		UDim2.new(
			1,
			0,
			0,
			78
		)

	top.BackgroundColor3 =
		COLORs and COLORS.Panel or COLORS.Panel

	top.BackgroundTransparency =
		0.04

	top.BorderSizePixel = 0
	top.Parent = panel

	createCorner(
		top,
		26
	)

	local iconBox =
		Instance.new("Frame")

	iconBox.Size =
		UDim2.fromOffset(
			48,
			48
		)

	iconBox.Position =
		UDim2.fromOffset(
			18,
			15
		)

	iconBox.BackgroundColor3 =
		COLORS.Cyan

	iconBox.BackgroundTransparency =
		0.80

	iconBox.BorderSizePixel = 0

	iconBox.Parent = top

	createCorner(
		iconBox,
		14
	)

	local iconStroke =
		Instance.new("UIStroke")

	iconStroke.Color =
		COLORS.Cyan

	iconStroke.Transparency =
		0.18

	iconStroke.Parent =
		iconBox

	local icon =
		createLabel(
			iconBox,
			"!",
			29,
			UDim2.fromScale(
				0,
				0
			),
			UDim2.fromScale(
				1,
				1
			),
			COLORS.Yellow,
			Enum.Font.GothamBlack
		)

	icon.TextXAlignment =
		Enum.TextXAlignment.Center

	local title =
		createLabel(
			top,
			"QYREX SECURITY CORE",
			22,
			UDim2.fromOffset(
				80,
				10
			),
			UDim2.new(
				1,
				-235,
				0,
				30
			),
			COLORS.White,
			Enum.Font.GothamBold
		)

	local subtitle =
		createLabel(
			top,
			CONFIG.Version,
			10,
			UDim2.fromOffset(
				81,
				40
			),
			UDim2.new(
				1,
				-250,
				0,
				18
			),
			COLORS.Muted,
			Enum.Font.Code
		)

	local status =
		Instance.new("Frame")

	status.Size =
		UDim2.fromOffset(
			122,
			34
		)

	status.Position =
		UDim2.new(
			1,
			-142,
			0,
			21
		)

	status.BackgroundColor3 =
		COLORS.Red

	status.BackgroundTransparency =
		0.84

	status.BorderSizePixel = 0
	status.Parent = top

	createCorner(
		status,
		99
	)

	local statusText =
		createLabel(
			status,
			"SECURITY ALERT",
			10,
			UDim2.fromScale(
				0,
				0
			),
			UDim2.fromScale(
				1,
				1
			),
			Color3.fromRGB(
				255,
				125,
				145
			),
			Enum.Font.GothamBold
		)

	statusText.TextXAlignment =
		Enum.TextXAlignment.Center

	local warningBadge =
		Instance.new("Frame")

	warningBadge.Size =
		UDim2.fromOffset(
			155,
			32
		)

	warningBadge.Position =
		UDim2.fromOffset(
			28,
			98
		)

	warningBadge.BackgroundColor3 =
		COLORS.Yellow

	warningBadge.BackgroundTransparency =
		0.86

	warningBadge.BorderSizePixel = 0

	warningBadge.Parent = panel

	createCorner(
		warningBadge,
		99
	)

	local warningText =
		createLabel(
			warningBadge,
			string.format(
				"WARNING %d / %d",
				state.warnings,
				CONFIG.MaxWarnings
			),
			11,
			UDim2.fromScale(
				0,
				0
			),
			UDim2.fromScale(
				1,
				1
			),
			COLORS.Yellow,
			Enum.Font.GothamBold
		)

	warningText.TextXAlignment =
		Enum.TextXAlignment.Center

	local detectionText =
		createLabel(
			panel,
			detection,
			29,
			UDim2.fromOffset(
				28,
				144
			),
			UDim2.new(
				1,
				-56,
				0,
				40
			),
			COLORS.White,
			Enum.Font.GothamBlack
		)

	local subDetection =
		createLabel(
			panel,
			"SERVER-SIDE INTEGRITY EVENT",
			10,
			UDim2.fromOffset(
				29,
				182
			),
			UDim2.new(
				1,
				-58,
				0,
				18
			),
			COLORS.Cyan,
			Enum.Font.Code
		)

	local reasonBox =
		Instance.new("Frame")

	reasonBox.Size =
		UDim2.new(
			1,
			-56,
			0,
			88
		)

	reasonBox.Position =
		UDim2.fromOffset(
			28,
			210
		)

	reasonBox.BackgroundColor3 =
		COLORS.Panel

	reasonBox.BackgroundTransparency =
		0.08

	reasonBox.BorderSizePixel = 0
	reasonBox.Parent = panel

	createCorner(
		reasonBox,
		16
	)

	local reasonStroke =
		Instance.new("UIStroke")

	reasonStroke.Color =
		COLORS.Cyan2

	reasonStroke.Transparency =
		0.72

	reasonStroke.Parent =
		reasonBox

	local incident =
		createLabel(
			reasonBox,
			"INCIDENT ANALYSIS",
			9,
			UDim2.fromOffset(
				15,
				7
			),
			UDim2.new(
				1,
				-30,
				0,
				18
			),
			COLORS.Muted,
			Enum.Font.GothamBold
		)

	local variant =
		createLabel(
			reasonBox,
			getWarningVariant(),
			12,
			UDim2.fromOffset(
				15,
				27
			),
			UDim2.new(
				1,
				-30,
				0,
				52
			),
			COLORS.White,
			Enum.Font.GothamMedium
		)

	variant.TextWrapped = true
	variant.TextYAlignment =
		Enum.TextYAlignment.Top

	local cardWidth = 195
	local gap = 14
	local x1 = 28
	local x2 = x1 + cardWidth + gap
	local x3 = x2 + cardWidth + gap

	local function makeCard(
		x,
		name,
		value,
		color
	)
		local card =
			Instance.new("Frame")

		card.Size =
			UDim2.fromOffset(
				cardWidth,
				72
			)

		card.Position =
			UDim2.fromOffset(
				x,
				315
			)

		card.BackgroundColor3 =
			COLORS.Panel2

		card.BackgroundTransparency =
			0.10

		card.BorderSizePixel = 0

		card.Parent = panel

		createCorner(
			card,
			15
		)

		local cardStroke =
			Instance.new("UIStroke")

		cardStroke.Color =
			color

		cardStroke.Transparency =
			0.72

		cardStroke.Parent =
			card

		createLabel(
			card,
			name,
			9,
			UDim2.fromOffset(
				13,
				7
			),
			UDim2.new(
				1,
				-26,
				0,
				16
			),
			COLORS.Muted,
			Enum.Font.GothamBold
		)

		local valueLabel =
			createLabel(
				card,
				value,
				18,
				UDim2.fromOffset(
					13,
					29
				),
				UDim2.new(
					1,
					-26,
					0,
					28
				),
				COLORS.White,
				Enum.Font.GothamBold
			)

		valueLabel.Name =
			"Value"

		return card
	end

	local severity =
		state.warnings >= 3
		and "CRITICAL"
		or state.warnings == 2
		and "HIGH"
		or "MEDIUM"

	makeCard(
		x1,
		"SEVERITY",
		severity,
		COLORS.Red
	)

	makeCard(
		x2,
		"TRUST",
		tostring(
			math.max(
				0,
				math.floor(
					state.trust
				)
			)
		) .. "%",
		COLORS.Green
	)

	local timeCard =
		makeCard(
			x3,
			"AUTO CLOSE",
			"5.0s",
			COLORS.Cyan
		)

	local timeValue =
		timeCard:FindFirstChild(
			"Value"
		)

	local codeBox =
		Instance.new("Frame")

	codeBox.Size =
		UDim2.new(
			1,
			-56,
			0,
			55
		)

	codeBox.Position =
		UDim2.fromOffset(
			28,
			402
		)

	codeBox.BackgroundColor3 =
		Color3.fromRGB(
			4,
			7,
			13
		)

	codeBox.BackgroundTransparency =
		0.05

	codeBox.BorderSizePixel = 0
	codeBox.Parent = panel

	createCorner(
		codeBox,
		14
	)

	local codeStroke =
		Instance.new("UIStroke")

	codeStroke.Color =
		COLORS.Cyan

	codeStroke.Transparency =
		0.60

	codeStroke.Parent =
		codeBox

	createLabel(
		codeBox,
		"EVENT CODE",
		9,
		UDim2.fromOffset(
			13,
			5
		),
		UDim2.new(
			0,
			90,
			0,
			16
		),
		COLORS.Muted,
		Enum.Font.GothamBold
	)

	local codeValue =
		createLabel(
			codeBox,
			code,
			12,
			UDim2.fromOffset(
				102,
				2
			),
			UDim2.new(
				1,
				-115,
				1,
				-4
			),
			Color3.fromRGB(
				80,
				245,
				225
			),
			Enum.Font.Code
		)

	codeValue.TextXAlignment =
		Enum.TextXAlignment.Right

	local progressBackground =
		Instance.new("Frame")

	progressBackground.Size =
		UDim2.new(
			1,
			-56,
			0,
			5
		)

	progressBackground.Position =
		UDim2.fromOffset(
			28,
			472
		)

	progressBackground.BackgroundColor3 =
		Color3.fromRGB(
			24,
			32,
			46
		)

	progressBackground.BorderSizePixel = 0
	progressBackground.Parent = panel

	createCorner(
		progressBackground,
		99
	)

	local progress =
		Instance.new("Frame")

	progress.Size =
		UDim2.fromScale(
			1,
			1
		)

	progress.BackgroundColor3 =
		COLORS.Cyan

	progress.BorderSizePixel = 0
	progress.Parent =
		progressBackground

	createCorner(
		progress,
		99
	)

	createLabel(
		panel,
		tostring(extra or "Protected server rule"),
		9,
		UDim2.fromOffset(
			28,
			480
		),
		UDim2.new(
			1,
			-56,
			0,
			18
		),
		COLORS.Muted,
		Enum.Font.Code
	)

	TweenService:Create(
		panel,
		TweenInfo.new(
			0.42,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out
		),
		{
			Size =
				UDim2.fromOffset(
					700,
					510
				),
		}
	):Play()

	local endTime =
		os.clock()
		+ CONFIG.WarningLifetime

	task.spawn(function()
		while
			gui.Parent
			and state.uiSerial == serial
		do
			local remaining =
				math.max(
					0,
					endTime - os.clock()
				)

			local ratio =
				math.clamp(
					remaining
						/ CONFIG.WarningLifetime,
					0,
					1
				)

			progress.Size =
				UDim2.new(
					ratio,
					0,
					1,
					0
				)

			if timeValue then
				timeValue.Text =
					string.format(
						"%.1fs",
						remaining
					)
			end

			if remaining <= 0 then
				break
			end

			task.wait(
				0.04
			)
		end

		if gui.Parent
			and state.uiSerial == serial then

			TweenService:Create(
				panel,
				TweenInfo.new(
					0.27,
					Enum.EasingStyle.Quad,
					Enum.EasingDirection.In
				),
				{
					Size =
						UDim2.fromOffset(
							0,
							0
						),
				}
			):Play()

			TweenService:Create(
				overlay,
				TweenInfo.new(
					0.20
				),
				{
					BackgroundTransparency = 1,
				}
			):Play()

			task.wait(
				0.30
			)

			if gui.Parent then
				gui:Destroy()
			end

			if state.ui == gui then
				state.ui = nil
			end
		end
	end)

	task.spawn(function()
		while
			gui.Parent
			and state.uiSerial == serial
		do
			TweenService:Create(
				stroke,
				TweenInfo.new(
					0.6,
					Enum.EasingStyle.Sine,
					Enum.EasingDirection.InOut
				),
				{
					Transparency = 0.04,
				}
			):Play()

			task.wait(
				0.6
			)

			TweenService:Create(
				stroke,
				TweenInfo.new(
					0.6,
					Enum.EasingStyle.Sine,
					Enum.EasingDirection.InOut
				),
				{
					Transparency = 0.28,
				}
			):Play()

			task.wait(
				0.6
			)
		end
	end)
end

local function makeCode(detection)
	return "QX-"
		.. detection
		.. "-"
		.. string.gsub(
			HttpService:GenerateGUID(false),
			"-",
			""
		):sub(1, 16)
end

local function kick(player, detection, code)
	if not player.Parent then
		return
	end

	player:Kick(
		table.concat(
			{
				"QYREX SECURITY CORE",
				"",
				"SERVER ENFORCEMENT",
				"Detection: " .. detection,
				"Code: " .. code,
				"Warnings: " ..
					tostring(
						states[player]
						and states[player].warnings
						or 0
					),
			},
			"\n"
		)
	)
end

local function registerViolation(
	player,
	detection,
	weight,
	extra
)
	local state =
		states[player]

	if not state then
		return
	end

	if getBypass(
		player,
		state.character,
		state.humanoid
	) then
		return
	end

	local now =
		os.clock()

	if
		now - state.lastWarning
		< CONFIG.WarningCooldown
	then
		return
	end

	local previous =
		state.lastDetection[detection]

	if previous
		and now - previous
		< CONFIG.SameDetectionCooldown
	then
		return
	end

	state.lastWarning = now
	state.lastDetection[detection] = now

	state.warnings += 1

	state.score += weight

	state.trust =
		math.max(
			0,
			state.trust
				- math.max(
					5,
					weight * 0.65
				)
		)

	local code =
		makeCode(
			detection
		)

	if CONFIG.Debug then
		warn(
			"[QyrexAC]",
			player.Name,
			detection,
			extra or ""
		)
	end

	createWarningUI(
		player,
		detection,
		code,
		extra
	)

	if state.warnings
		> CONFIG.MaxWarnings then

		task.delay(
			0.35,
			function()
				if player.Parent then
					kick(
						player,
						detection,
						code
					)
				end
			end
		)
	end
end

local function getAllowedWalkSpeed(
	player,
	character,
	humanoid
)
	local value =
		humanoid:GetAttribute(
			"QyrexAC_AllowedWalkSpeed"
		)

	if typeof(value) == "number" then
		return value
	end

	value =
		character:GetAttribute(
			"QyrexAC_AllowedWalkSpeed"
		)

	if typeof(value) == "number" then
		return value
	end

	value =
		player:GetAttribute(
			"QyrexAC_AllowedWalkSpeed"
		)

	if typeof(value) == "number" then
		return value
	end

	return CONFIG.MaxWalkSpeed
end

local function getAllowedJumpPower(
	player,
	character,
	humanoid
)
	local value =
		humanoid:GetAttribute(
			"QyrexAC_AllowedJumpPower"
		)

	if typeof(value) == "number" then
		return value
	end

	value =
		character:GetAttribute(
			"QyrexAC_AllowedJumpPower"
		)

	if typeof(value) == "number" then
		return value
	end

	value =
		player:GetAttribute(
			"QyrexAC_AllowedJumpPower"
		)

	if typeof(value) == "number" then
		return value
	end

	return CONFIG.MaxJumpPower
end

local function getAllowedJumpHeight(
	player,
	character,
	humanoid
)
	local value =
		humanoid:GetAttribute(
			"QyrexAC_AllowedJumpHeight"
		)

	if typeof(value) == "number" then
		return value
	end

	value =
		character:GetAttribute(
			"QyrexAC_AllowedJumpHeight"
		)

	if typeof(value) == "number" then
		return value
	end

	value =
		player:GetAttribute(
			"QyrexAC_AllowedJumpHeight"
		)

	if typeof(value) == "number" then
		return value
	end

	return CONFIG.MaxJumpHeight
end

local function getAllowedMaxHealth(
	player,
	character,
	humanoid
)
	local value =
		humanoid:GetAttribute(
			"QyrexAC_AllowedMaxHealth"
		)

	if typeof(value) == "number" then
		return value
	end

	value =
		character:GetAttribute(
			"QyrexAC_AllowedMaxHealth"
		)

	if typeof(value) == "number" then
		return value
	end

	value =
		player:GetAttribute(
			"QyrexAC_AllowedMaxHealth"
		)

	if typeof(value) == "number" then
		return value
	end

	return CONFIG.MaxHealth
end

local function checkHumanoidProperties(
	player,
	state
)
	local character =
		state.character

	local humanoid =
		state.humanoid

	if not character
		or not humanoid
		or humanoid.Health <= 0
	then
		return
	end

	if getBypass(
		player,
		character,
		humanoid
	) then
		return
	end

	if
		humanoid.WalkSpeed
		> getAllowedWalkSpeed(
			player,
			character,
			humanoid
		) + 2.5
	then
		registerViolation(
			player,
			"SPEED",
			30,
			string.format(
				"WalkSpeed %.1f",
				humanoid.WalkSpeed
			)
		)
	end

	if humanoid.UseJumpPower then
		if
			humanoid.JumpPower
			> getAllowedJumpPower(
				player,
				character,
				humanoid
			) + 8
		then
			registerViolation(
				player,
				"JUMPPOWER",
				30,
				string.format(
					"JumpPower %.1f",
					humanoid.JumpPower
				)
			)
		end
	else
		if
			humanoid.JumpHeight
			> getAllowedJumpHeight(
				player,
				character,
				humanoid
			) + 1.25
		then
			registerViolation(
				player,
				"JUMPHEIGHT",
				30,
				string.format(
					"JumpHeight %.1f",
					humanoid.JumpHeight
				)
			)
		end
	end

	if
		humanoid.MaxHealth
		> getAllowedMaxHealth(
			player,
			character,
			humanoid
		) + 25
	then
		registerViolation(
			player,
			"GODMODE",
			40,
			string.format(
				"MaxHealth %.1f",
				humanoid.MaxHealth
			)
		)
	end

	if
		state.lastMaxHealth
		and humanoid.MaxHealth
			> state.lastMaxHealth + 30
	then
		registerViolation(
			player,
			"GODMODE_CHANGE",
			45,
			"MaxHealth changed unexpectedly"
		)
	end

	if
		state.lastHealth
		and humanoid.Health
			> state.lastHealth + 45
		and humanoid:GetAttribute(
			"QyrexAC_LegitHeal"
		) ~= true
	then
		registerViolation(
			player,
			"HEALTH",
			30,
			string.format(
				"Health %.1f -> %.1f",
				state.lastHealth,
				humanoid.Health
			)
		)
	end

	if
		humanoid.HipHeight
		> CONFIG.MaxHipHeight
		and humanoid:GetAttribute(
			"QyrexAC_AllowHipHeight"
		) ~= true
	then
		registerViolation(
			player,
			"HIPHEIGHT",
			25,
			string.format(
				"HipHeight %.1f",
				humanoid.HipHeight
			)
		)
	end

	if humanoid.AutoRotate == false
		and humanoid:GetAttribute(
			"QyrexAC_AllowAutoRotateOff"
		) ~= true
		and humanoid.Sit == false
	then
		registerViolation(
			player,
			"AUTOROTATE",
			15,
			"Unexpected AutoRotate state"
		)
	end

	state.lastHealth =
		humanoid.Health

	state.lastMaxHealth =
		humanoid.MaxHealth

	state.lastHipHeight =
		humanoid.HipHeight
end

local function checkMovement(
	player,
	state,
	dt
)
	local root =
		state.root

	local humanoid =
		state.humanoid

	if not root
		or not humanoid
		or humanoid.Health <= 0
	then
		return
	end

	if getBypass(
		player,
		state.character,
		humanoid
	) then
		return
	end

	if workspace:GetServerTimeNow()
		< state.graceUntil
	then
		state.lastPosition =
			root.Position

		return
	end

	if not state.lastPosition then
		state.lastPosition =
			root.Position

		state.lastSafePosition =
			root.Position

		return
	end

	local position =
		root.Position

	local velocity =
		root.AssemblyLinearVelocity

	local distance =
		(position - state.lastPosition).Magnitude

	local allowedSpeed =
		getAllowedWalkSpeed(
			player,
			state.character,
			humanoid
		)

	local expectedMovement =
		math.max(
			6,
			(allowedSpeed + 24) * dt
		)

	if
		distance
		> math.max(
			CONFIG.MaxTeleportDistance,
			expectedMovement * 5
		)
	then
		registerViolation(
			player,
			"TELEPORT",
			50,
			string.format(
				"Moved %.1f studs",
				distance
			)
		)
	end

	local horizontal =
		Vector3.new(
			velocity.X,
			0,
			velocity.Z
		).Magnitude

	local total =
		velocity.Magnitude

	if
		horizontal
		> CONFIG.MaxHorizontalVelocity
	then
		registerViolation(
			player,
			"ABNORMAL_SPEED",
			35,
			string.format(
				"Horizontal velocity %.1f",
				horizontal
			)
		)
	end

	if total > CONFIG.MaxVelocity then
		registerViolation(
			player,
			"VELOCITY",
			45,
			string.format(
				"Velocity %.1f",
				total
			)
		)
	end

	if
		distance > 25
		and humanoid.FloorMaterial
			== Enum.Material.Air
		and total > 30
	then
		registerViolation(
			player,
			"AIR_MOVEMENT",
			30,
			string.format(
				"Air displacement %.1f",
				distance
			)
		)
	end

	state.lastPosition =
		position
end

local function checkAir(
	player,
	state,
	dt
)
	local root =
		state.root

	local humanoid =
		state.humanoid

	local character =
		state.character

	if not root
		or not humanoid
		or not character
		or humanoid.Health <= 0
	then
		return
	end

	if getBypass(
		player,
		character,
		humanoid
	) then
		return
	end

	if workspace:GetServerTimeNow()
		< state.graceUntil
	then
		state.flyTime = 0
		state.hoverTime = 0
		return
	end

	local params =
		RaycastParams.new()

	params.FilterType =
		Enum.RaycastFilterType.Exclude

	params.FilterDescendantsInstances =
		{
			character
		}

	params.IgnoreWater =
		false

	local ground =
		workspace:Raycast(
			root.Position
				+ Vector3.new(
					0,
					1,
					0
				),
			Vector3.new(
				0,
				-7,
				0
			),
			params
		)

	local currentState =
		humanoid:GetState()

	local legitimateAir =
		currentState
			== Enum.HumanoidStateType.Jumping
		or currentState
			== Enum.HumanoidStateType.Freefall
		or currentState
			== Enum.HumanoidStateType.Flying

	if not ground
		and legitimateAir
	then
		local velocity =
			root.AssemblyLinearVelocity

		if math.abs(velocity.Y) < 5 then
			state.hoverTime += dt
		else
			state.hoverTime =
				math.max(
					0,
					state.hoverTime
						- dt
				)
		end

		state.flyTime += dt
	else
		state.flyTime =
			math.max(
				0,
				state.flyTime
					- dt * 2
			)

		state.hoverTime =
			math.max(
				0,
				state.hoverTime
					- dt * 2
			)
	end

	if
		state.hoverTime
		>= CONFIG.HoverTime
	then
		registerViolation(
			player,
			"HOVER",
			45,
			string.format(
				"Hover %.2fs",
				state.hoverTime
			)
		)

		state.hoverTime = 0
	end

	if
		state.flyTime
		>= CONFIG.FlyTime
		and root.AssemblyLinearVelocity.Y > -4
	then
		registerViolation(
			player,
			"FLY",
			50,
			string.format(
				"Air %.2fs",
				state.flyTime
			)
		)

		state.flyTime = 0
	end
end

local function checkNoclip(
	player,
	state,
	dt
)
	local root =
		state.root

	local humanoid =
		state.humanoid

	local character =
		state.character

	if not root
		or not humanoid
		or not character
		or humanoid.Health <= 0
	then
		return
	end

	if getBypass(
		player,
		character,
		humanoid
	) then
		return
	end

	if workspace:GetServerTimeNow()
		< state.graceUntil
	then
		state.noclipTime = 0
		return
	end

	local overlap =
		OverlapParams.new()

	overlap.FilterType =
		Enum.RaycastFilterType.Exclude

	overlap.FilterDescendantsInstances =
		{
			character
		}

	overlap.MaxParts = 30

	local parts =
		workspace:GetPartBoundsInBox(
			root.CFrame,
			Vector3.new(
				2.4,
				3.4,
				1.8
			),
			overlap
		)

	local solidParts = 0

	for _, part in ipairs(parts) do
		if
			part:IsA("BasePart")
			and part.CanCollide
			and part.CanQuery
			and part.Transparency < 1
			and not part:IsDescendantOf(
				character
			)
		then
			solidParts += 1
		end
	end

	local speed =
		root.AssemblyLinearVelocity.Magnitude

	if
		solidParts > 0
		and speed > 8
		and humanoid.FloorMaterial
			== Enum.Material.Air
	then
		state.noclipTime += dt
	else
		state.noclipTime =
			math.max(
				0,
				state.noclipTime
					- dt * 2
			)
	end

	if
		state.noclipTime
		>= CONFIG.NoclipTime
	then
		registerViolation(
			player,
			"NOCLIP",
			55,
			string.format(
				"Solid overlaps %d",
				solidParts
			)
		)

		state.noclipTime = 0
	end
end

local function checkPhysics(
	player,
	state
)
	local character =
		state.character

	local root =
		state.root

	local humanoid =
		state.humanoid

	if not character
		or not root
		or not humanoid
		or humanoid.Health <= 0
	then
		return
	end

	if getBypass(
		player,
		character,
		humanoid
	) then
		return
	end

	local angular =
		root.AssemblyAngularVelocity.Magnitude

	if
		angular
		> CONFIG.MaxAngularVelocity
	then
		registerViolation(
			player,
			"ANGULAR",
			40,
			string.format(
				"Angular %.1f",
				angular
			)
		)
	end

	for _, object in ipairs(
		character:GetDescendants()
	) do
		if
			object:GetAttribute(
				"QyrexAC_LegitPhysics"
			) ~= true
		then
			if object:IsA(
				"BodyVelocity"
			) then
				if
					object.Velocity.Magnitude
					> 45
				then
					registerViolation(
						player,
						"BODYVELOCITY",
						50,
						object.Name
					)

					break
				end

			elseif object:IsA(
				"BodyPosition"
			) then
				registerViolation(
					player,
					"BODYPOSITION",
					45,
					object.Name
				)

				break

			elseif object:IsA(
				"BodyGyro"
			) then
				registerViolation(
					player,
					"BODYGYRO",
					45,
					object.Name
				)

				break

			elseif object:IsA(
				"BodyAngularVelocity"
			) then
				registerViolation(
					player,
					"BODYANGULAR",
					45,
					object.Name
				)

				break

			elseif object:IsA(
				"VectorForce"
			) then
				if
					object.Force.Magnitude
					> 18000
				then
					registerViolation(
						player,
						"VECTORFORCE",
						50,
						object.Name
					)

					break
				end

			elseif object:IsA(
				"LinearVelocity"
			) then
				if
					object.VectorVelocity.Magnitude
					> 50
				then
					registerViolation(
						player,
						"LINEARVELOCITY",
						50,
						object.Name
					)

					break
				end

			elseif object:IsA(
				"AngularVelocity"
			) then
				if
					object.AngularVelocity.Magnitude
					> 50
				then
					registerViolation(
						player,
						"ANGULARVELOCITY",
						50,
						object.Name
					)

					break
				end

			elseif object:IsA(
				"AlignPosition"
			) then
				if
					object.MaxForce > 50000
				then
					registerViolation(
						player,
						"ALIGNPOSITION",
						45,
						object.Name
					)

					break
				end

			elseif object:IsA(
				"AlignOrientation"
			) then
				if
					object.MaxTorque > 50000
				then
					registerViolation(
						player,
						"ALIGNORIENTATION",
						45,
						object.Name
					)

					break
				end
			end
		end
	end
end

local function checkStates(
	player,
	state
)
	local humanoid =
		state.humanoid

	local root =
		state.root

	local character =
		state.character

	if not humanoid
		or not root
		or not character
		or humanoid.Health <= 0
	then
		return
	end

	if getBypass(
		player,
		character,
		humanoid
	) then
		return
	end

	local stateType =
		humanoid:GetState()

	local velocity =
		root.AssemblyLinearVelocity.Magnitude

	if
		stateType
			== Enum.HumanoidStateType.Physics
		and velocity > 30
		and humanoid:GetAttribute(
			"QyrexAC_AllowPhysicsState"
		) ~= true
	then
		registerViolation(
			player,
			"PHYSICS_STATE",
			35,
			"Physics + velocity"
		)
	end

	if
		stateType
			== Enum.HumanoidStateType.PlatformStanding
		and velocity > 35
		and humanoid:GetAttribute(
			"QyrexAC_AllowPlatformStanding"
		) ~= true
	then
		registerViolation(
			player,
			"PLATFORM_STANDING",
			35,
			"PlatformStanding + velocity"
		)
	end

	if
		stateType
			== Enum.HumanoidStateType.Flying
		and humanoid:GetAttribute(
			"QyrexAC_AllowFlying"
		) ~= true
	then
		registerViolation(
			player,
			"FLYING_STATE",
			40,
			"Humanoid Flying state"
		)
	end
end

local function registerJump(
	player,
	state
)
	local humanoid =
		state.humanoid

	if not humanoid
		or humanoid.Health <= 0
	then
		return
	end

	local character =
		state.character

	if getBypass(
		player,
		character,
		humanoid
	) then
		return
	end

	local now =
		os.clock()

	table.insert(
		state.jumpTimes,
		now
	)

	while
		state.jumpTimes[1]
		and now - state.jumpTimes[1]
			> CONFIG.JumpWindow
	do
		table.remove(
			state.jumpTimes,
			1
		)
	end

	if
		#state.jumpTimes
		> CONFIG.MaxJumpsInWindow
	then
		registerViolation(
			player,
			"INFJUMP",
			45,
			string.format(
				"%d jumps / %.2fs",
				#state.jumpTimes,
				CONFIG.JumpWindow
			)
		)

		table.clear(
			state.jumpTimes
		)
	end
end

local function attachCharacter(
	player,
	character
)
	local state =
		states[player]

	if not state then
		return
	end

	state.character =
		character

	state.humanoid =
		character:FindFirstChildOfClass(
			"Humanoid"
		)

	state.root =
		character:FindFirstChild(
			"HumanoidRootPart"
		)

	if not state.humanoid then
		state.humanoid =
			character:WaitForChild(
				"Humanoid",
				8
			)
	end

	if not state.root then
		state.root =
			character:WaitForChild(
				"HumanoidRootPart",
				8
			)
	end

	state.lastPosition = nil
	state.lastSafePosition = nil

	state.flyTime = 0
	state.hoverTime = 0
	state.noclipTime = 0

	table.clear(
		state.jumpTimes
	)

	state.lastHealth = nil
	state.lastMaxHealth = nil
	state.lastHipHeight = nil

	state.graceUntil =
		getGraceUntil(
			player,
			character
		)

	if not state.humanoid
		or not state.root
	then
		return
	end

	table.insert(
		state.connections,
		state.humanoid.Jumping:Connect(
			function(active)
				if active then
					registerJump(
						player,
						state
					)
				end
			end
		)
	)

	table.insert(
		state.connections,
		state.humanoid.Died:Connect(
			function()
				state.graceUntil =
					workspace:GetServerTimeNow()
					+ 2

				state.lastPosition = nil
			end
		)
	)

	table.insert(
		state.connections,
		state.humanoid:GetPropertyChangedSignal(
			"WalkSpeed"
		):Connect(
			function()
				if not state.humanoid then
					return
				end

				if
					state.humanoid.WalkSpeed
					> getAllowedWalkSpeed(
						player,
						character,
						state.humanoid
					) + 2.5
				then
					registerViolation(
						player,
						"SPEED_PROPERTY",
						35,
						string.format(
							"WalkSpeed %.1f",
							state.humanoid.WalkSpeed
						)
					)
				end
			end
		)
	)

	table.insert(
		state.connections,
		state.humanoid:GetPropertyChangedSignal(
			"JumpPower"
		):Connect(
			function()
				if not state.humanoid then
					return
				end

				if
					state.humanoid.UseJumpPower
					and state.humanoid.JumpPower
						> getAllowedJumpPower(
							player,
							character,
							state.humanoid
						) + 8
				then
					registerViolation(
						player,
						"JUMP_PROPERTY",
						35,
						string.format(
							"JumpPower %.1f",
							state.humanoid.JumpPower
						)
					)
				end
			end
		)
	)

	table.insert(
		state.connections,
		state.humanoid:GetPropertyChangedSignal(
			"JumpHeight"
		):Connect(
			function()
				if not state.humanoid then
					return
				end

				if
					not state.humanoid.UseJumpPower
					and state.humanoid.JumpHeight
						> getAllowedJumpHeight(
							player,
							character,
							state.humanoid
						) + 1.25
				then
					registerViolation(
						player,
						"JUMPHEIGHT_PROPERTY",
						35,
						string.format(
							"JumpHeight %.1f",
							state.humanoid.JumpHeight
						)
					)
				end
			end
		)
	)

	table.insert(
		state.connections,
		state.humanoid:GetPropertyChangedSignal(
			"MaxHealth"
		):Connect(
			function()
				if not state.humanoid then
					return
				end

				if
					state.humanoid.MaxHealth
						> getAllowedMaxHealth(
							player,
							character,
							state.humanoid
						) + 25
				then
					registerViolation(
						player,
						"GODMODE_PROPERTY",
						45,
						string.format(
							"MaxHealth %.1f",
							state.humanoid.MaxHealth
						)
					)
				end
			end
		)
	)
end

for _, honeypot in ipairs(honeypots) do
	honeypot.OnServerEvent:Connect(
		function(player)
			if CONFIG.HoneypotKick then
				kick(
					player,
					"HONEYPOT_REMOTE",
					"QX-HONEYPOT"
				)
			end
		end
	)
end

invokeTrap.OnServerInvoke =
	function(player)
		if CONFIG.HoneypotKick then
			kick(
				player,
				"HONEYPOT_FUNCTION",
				"QX-HONEYPOT-FUNCTION"
			)
		end

		return false
	end

reportRemote.OnServerEvent:Connect(
	function(player, payload)
		if CONFIG.Debug
			and typeof(payload) == "table"
		then
			print(
				"[QyrexAC]",
				player.Name,
				tostring(
					payload.detection
					or "UNKNOWN"
				)
			)
		end
	end
)

Players.PlayerAdded:Connect(
	function(player)
		local state =
			createState(player)

		player.CharacterAdded:Connect(
			function(character)
				for _, connection
					in ipairs(state.connections)
				do
					pcall(function()
						connection:Disconnect()
					end)
				end

				table.clear(
					state.connections
				)

				attachCharacter(
					player,
					character
				)
			end
		)

		if player.Character then
			task.defer(
				attachCharacter,
				player,
				player.Character
			)
		end
	end
)

Players.PlayerRemoving:Connect(
	function(player)
		local state =
			states[player]

		if state then
			cleanupState(
				state
			)
		end

		states[player] = nil
	end
)

local function processPlayer(
	player,
	state,
	dt
)
	if not state.character
		or not state.humanoid
		or not state.root
	then
		return
	end

	if state.humanoid.Health <= 0 then
		return
	end

	state.propertyTimer += dt
	state.physicsTimer += dt

	checkMovement(
		player,
		state,
		dt
	)

	checkAir(
		player,
		state,
		dt
	)

	checkNoclip(
		player,
		state,
		dt
	)

	checkStates(
		player,
		state
	)

	if
		state.propertyTimer
		>= CONFIG.PropertyScanRate
	then
		state.propertyTimer = 0

		checkHumanoidProperties(
			player,
			state
		)
	end

	if
		state.physicsTimer
		>= CONFIG.PhysicsScanRate
	then
		state.physicsTimer = 0

		checkPhysics(
			player,
			state
		)
	end
end

RunService.Heartbeat:Connect(
	function(dt)
		local step =
			math.min(
				dt,
				0.25
			)

		for _, player in ipairs(
			Players:GetPlayers()
		) do
			local state =
				states[player]

			if state then
				processPlayer(
					player,
					state,
					step
				)
			end
		end
	end
)

_G.QyrexAntiCheat = {
	GrantGrace = function(
		player,
		seconds
	)
		local state =
			states[player]

		if not state then
			return
		end

		state.graceUntil =
			math.max(
				state.graceUntil,
				workspace:GetServerTimeNow()
					+ math.max(
						0,
						seconds or 0
					)
			)
	end,

	ClearWarnings = function(
		player
	)
		local state =
			states[player]

		if not state then
			return
		end

		state.warnings = 0
		state.score = 0
		state.trust = 100
		state.lastWarning = 0

		table.clear(
			state.lastDetection
		)

		state.uiSerial += 1

		if
			state.ui
			and state.ui.Parent
		then
			state.ui:Destroy()
		end

		state.ui = nil
	end,

	GetStatus = function(
		player
	)
		local state =
			states[player]

		if not state then
			return nil
		end

		return {
			warnings =
				state.warnings,

			score =
				state.score,

			trust =
				state.trust,

			version =
				CONFIG.Version,

			warningVariants =
				warningVariantCount,
		}
	end,
}

print(
	string.format(
		"[Qyrex AntiCheat] %s | SERVER ONLY | %d warning variants | UI 5s",
		CONFIG.Version,
		warningVariantCount
	)
)
