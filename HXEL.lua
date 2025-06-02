-- HXEL Script by [Nama Anda]
-- Versi 2.2 (2025-06-02)
-- Fitur:
--   • GUI Modern dengan Tabs (Status, Teleport, Unlimited Jump)
--   • Integrasi Modular “Unlimited Jump” (via loadstring)
--   • Animasi Tween, Rounded Corners, Border Stroke, Drag TitleBar
--   • Debug Print pada tombol Unlimited Jump agar terlihat jika ditekan

--==========================================================--
--=== 1. DEFINISI KONFIGURASI & VARIABEL POKOK ================--
--==========================================================--

local Players      = game:GetService("Players")
local CoreGui      = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")

local player       = Players.LocalPlayer

-- Color / Styling
local COLOR_BG            = Color3.fromRGB(25, 25, 35)
local COLOR_FRAME         = Color3.fromRGB(40, 40, 50)
local COLOR_TITLE         = Color3.fromRGB(0, 200, 180)
local COLOR_TAB_INACTIVE  = Color3.fromRGB(50, 50, 60)
local COLOR_TAB_ACTIVE    = Color3.fromRGB(70, 70, 90)
local COLOR_BUTTON        = Color3.fromRGB(60, 60, 80)
local COLOR_BUTTON_H      = Color3.fromRGB(80, 80, 100)
local COLOR_TEXT_HEADER   = Color3.fromRGB(200, 200, 200)
local COLOR_TEXT_ON       = Color3.fromRGB(0, 255, 0)
local COLOR_TEXT_OFF      = Color3.fromRGB(200, 200, 200)
local COLOR_BORDER        = Color3.fromRGB(60, 60, 80)

local FONT_HEADER         = Enum.Font.GothamBold
local FONT_NORMAL         = Enum.Font.Gotham

-- Status Flags & Module References
local isMinimized            = false
local isUnlimitedJumpEnabled = false
local unljmpModule           = nil

-- GUI References (dideklarasikan di luar, akan di-assign saat build)
local MainFrame, TitleBar, TabBar, ContentArea
local btnClose, btnMinimize
local btnTabStatus, btnTabTeleport, btnTabJump
local StatusFrame, TeleportFrame, JumpFrame

-- Kontrol untuk update Status Tab
local statusAccumulator = 0

-- Jump UI dalam JumpFrame
local txtJumpSpeed, lblJumpStatus, btnJumpToggle

-- Teleport UI dalam TeleportFrame
local txtTeleportX, txtTeleportY, txtTeleportZ, btnTeleport

-- Ukuran GUI (normal vs minimized)
local ORIGINAL_SIZE   = UDim2.new(0, 360, 0, 240)
local MINIMIZED_SIZE  = UDim2.new(0, 360, 0, 30)

-- Tween Info
local tweenInfoShort = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

--==========================================================--
--=== 2. FUNGSI PENDUKUNG (UTILITIES) ========================--
--==========================================================--

-- Buat UICorner (rounded corner)
local function applyRounded(inst, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = inst
end

-- Buat UIStroke (border stroke)
local function applyStroke(inst, thickness, color)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = thickness or 1
    stroke.Color = color or COLOR_BORDER
    stroke.Parent = inst
end

-- Buat Button modern dengan hover effect
-- parent = Frame, name = string, size = UDim2, pos = UDim2, text = string, callback = function
local function createButton(parent, name, size, pos, text, callback)
    local btn = Instance.new("TextButton")
    btn.Name               = name
    btn.Size               = size
    btn.Position           = pos
    btn.BackgroundColor3   = COLOR_BUTTON
    btn.Text               = text
    btn.TextColor3         = COLOR_TEXT_HEADER
    btn.Font               = FONT_NORMAL
    btn.TextScaled         = true
    btn.BorderSizePixel    = 0
    btn.ZIndex             = 2         -- Pastikan tombol berada di atas frame
    btn.Parent             = parent

    applyRounded(btn, 4)
    applyStroke(btn, 1, COLOR_BORDER)

    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = COLOR_BUTTON_H
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = COLOR_BUTTON
    end)

    btn.MouseButton1Click:Connect(function()
        callback(btn)
    end)

    return btn
end

-- Tween resize MainFrame
local function tweenMainFrameSize(targetSize)
    TweenService:Create(MainFrame, tweenInfoShort, {Size = targetSize}):Play()
end

--==========================================================--
--=== 3. FUNGSI UTAMA =======================================--
--==========================================================--

-- Toggle minimize / maximize
local function toggleMinimize()
    if isMinimized then
        -- Maximize kembali
        tweenMainFrameSize(ORIGINAL_SIZE)
        ContentArea.Visible = true
        isMinimized = false
        btnMinimize.Text = "–"
    else
        -- Minimize
        tweenMainFrameSize(MINIMIZED_SIZE)
        delay(0.2, function()
            if MainFrame.Size == MINIMIZED_SIZE then
                ContentArea.Visible = false
            end
        end)
        isMinimized = true
        btnMinimize.Text = "+"
    end
end

-- Unload script dan cleanup
local function unloadScript()
    -- Disable Unlimited Jump jika aktif
    if isUnlimitedJumpEnabled and unljmpModule then
        unljmpModule.Disable()
    end
    -- Destroy modul jika sudah load
    if unljmpModule then
        unljmpModule.Destroy()
        unljmpModule = nil
    end
    -- Hapus GUI
    if CoreGui:FindFirstChild("HXEL_Main") then
        CoreGui.HXEL_Main:Destroy()
    end
    warn("HXEL Script Unloaded.")
end

-- Toggle Unlimited Jump (Jump Tab)
local function toggleUnlimitedJump()
    print("[ToggleUnlimitedJump] Button pressed")  -- Debug print
    isUnlimitedJumpEnabled = not isUnlimitedJumpEnabled

    if isUnlimitedJumpEnabled then
        -- Lazy-load modul (hanya sekali)
        if not unljmpModule then
            local ok, mod = pcall(function()
                return loadstring(game:HttpGet(
                    "https://raw.githubusercontent.com/RABZBOT/RABZBOT/main/fit/unljmp.lua",
                    true
                ))()
            end)
            if ok and type(mod) == "table" then
                print("[ToggleUnlimitedJump] Modul loaded successfully")  -- Debug print
                unljmpModule = mod
            else
                warn("Gagal load modul Unlimited Jump:", mod)
                isUnlimitedJumpEnabled = false
                lblJumpStatus.Text = "OFF"
                lblJumpStatus.TextColor3 = COLOR_TEXT_OFF
                return
            end
        end

        -- Ambil speed dari TextBox jika valid
        local speedVal = tonumber(txtJumpSpeed.Text)
        if speedVal and speedVal > 0 then
            unljmpModule.SetSpeed(speedVal)
            print("[ToggleUnlimitedJump] SetSpeed to", speedVal)  -- Debug print
        end

        unljmpModule.Enable()
        lblJumpStatus.Text = "ON"
        lblJumpStatus.TextColor3 = COLOR_TEXT_ON
    else
        if unljmpModule then
            unljmpModule.Disable()
            print("[ToggleUnlimitedJump] Modul disabled")  -- Debug print
        end
        lblJumpStatus.Text = "OFF"
        lblJumpStatus.TextColor3 = COLOR_TEXT_OFF
    end
end

-- Teleport player ke koordinat input (Teleport Tab)
local function teleportPlayer()
    local x = tonumber(txtTeleportX.Text)
    local y = tonumber(txtTeleportY.Text)
    local z = tonumber(txtTeleportZ.Text)
    if x and y and z then
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = CFrame.new(Vector3.new(x, y, z))
        end
    else
        warn("Teleport: Pastikan X, Y, Z adalah angka valid.")
    end
end

-- Update status (koordinat & money) setiap 0.5 detik (Status Tab)
local function updateStatus(dt)
    statusAccumulator = statusAccumulator + dt
    if statusAccumulator < 0.5 then return end
    statusAccumulator = statusAccumulator - 0.5

    -- Update koordinat
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local pos = char.HumanoidRootPart.Position
        StatusFrame.CoordinatesLabel.Text = string.format(
            "Coords: (%.1f, %.1f, %.1f)",
            pos.X, pos.Y, pos.Z
        )
    else
        StatusFrame.CoordinatesLabel.Text = "Coords: (n/a)"
    end

    -- Update money (jika ada leaderstats)
    local ls = player:FindFirstChild("leaderstats")
    if ls then
        local foundStat = false
        for _, stat in ipairs(ls:GetChildren()) do
            if stat:IsA("NumberValue") or stat:IsA("IntValue") then
                StatusFrame.MoneyLabel.Text = stat.Name .. ": " .. tostring(stat.Value)
                foundStat = true
                break
            end
        end
        if not foundStat then
            StatusFrame.MoneyLabel.Text = "Money: (n/a)"
        end
    else
        StatusFrame.MoneyLabel.Text = "Money: (n/a)"
    end
end

--==========================================================--
--=== 4. MEMBANGUN & MENATA GUI UTAMA =======================--
--==========================================================--

-- Hapus GUI lama bila ada
if CoreGui:FindFirstChild("HXEL_Main") then
    CoreGui.HXEL_Main:Destroy()
end

-- Buat ScreenGui
local MainGui = Instance.new("ScreenGui")
MainGui.Name   = "HXEL_Main"
MainGui.Parent = CoreGui

-- =========================================================
-- (A) Buat MainFrame
-- =========================================================
MainFrame = Instance.new("Frame")
MainFrame.Name             = "MainFrame"
MainFrame.Size             = ORIGINAL_SIZE
MainFrame.Position         = UDim2.new(0.5, -180, 0.5, -120)
MainFrame.BackgroundColor3 = COLOR_BG
MainFrame.BorderSizePixel  = 0
MainFrame.Active           = true
MainFrame.Selectable       = true
MainFrame.ZIndex           = 1
MainFrame.Parent           = MainGui

applyRounded(MainFrame, 12)
applyStroke(MainFrame, 2, COLOR_BORDER)

-- =========================================================
-- (B) Buat TitleBar di atas MainFrame
-- =========================================================
TitleBar = Instance.new("Frame")
TitleBar.Name             = "TitleBar"
TitleBar.Size             = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = COLOR_TITLE
TitleBar.BorderSizePixel  = 0
TitleBar.ZIndex           = 2
TitleBar.Parent           = MainFrame

applyRounded(TitleBar, 12)
applyStroke(TitleBar, 1, COLOR_BORDER)

-- Judul di TitleBar
local lblTitle = Instance.new("TextLabel")
lblTitle.Size               = UDim2.new(1, -90, 1, 0)
lblTitle.Position           = UDim2.new(0, 10, 0, 0)
lblTitle.BackgroundTransparency = 1
lblTitle.Text               = "HXEL - Multi Tab UI"
lblTitle.TextColor3         = Color3.fromRGB(255, 255, 255)
lblTitle.Font               = FONT_HEADER
lblTitle.TextScaled         = true
lblTitle.ZIndex             = 3
lblTitle.Parent             = TitleBar

-- Tombol Minimize ("–" / "+") di TitleBar
btnMinimize = Instance.new("TextButton")
btnMinimize.Name             = "MinimizeButton"
btnMinimize.Size             = UDim2.new(0, 25, 0, 25)
btnMinimize.Position         = UDim2.new(1, -60, 0, 2)
btnMinimize.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
btnMinimize.Text             = "–"
btnMinimize.TextColor3       = Color3.fromRGB(255, 255, 255)
btnMinimize.Font             = FONT_NORMAL
btnMinimize.TextScaled       = true
btnMinimize.BorderSizePixel  = 0
btnMinimize.ZIndex           = 3
btnMinimize.Parent           = TitleBar

applyRounded(btnMinimize, 4)
applyStroke(btnMinimize, 1, COLOR_BORDER)
btnMinimize.MouseButton1Click:Connect(toggleMinimize)

-- Tombol Close ("X") di TitleBar
btnClose = Instance.new("TextButton")
btnClose.Name               = "CloseButton"
btnClose.Size               = UDim2.new(0, 25, 0, 25)
btnClose.Position           = UDim2.new(1, -30, 0, 2)
btnClose.BackgroundColor3   = Color3.fromRGB(200, 50, 50)
btnClose.Text               = "X"
btnClose.TextColor3         = Color3.fromRGB(255, 255, 255)
btnClose.Font               = FONT_NORMAL
btnClose.TextScaled         = true
btnClose.BorderSizePixel    = 0
btnClose.ZIndex             = 3
btnClose.Parent             = TitleBar

applyRounded(btnClose, 4)
applyStroke(btnClose, 1, COLOR_BORDER)
btnClose.MouseButton1Click:Connect(unloadScript)

-- Drag behavior untuk TitleBar
do
    local dragging  = false
    local dragStart = nil
    local startPos  = nil

    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- =========================================================
-- (C) Buat TabBar di bawah TitleBar
-- =========================================================
TabBar = Instance.new("Frame")
TabBar.Name             = "TabBar"
TabBar.Size             = UDim2.new(1, 0, 0, 30)
TabBar.Position         = UDim2.new(0, 0, 0, 30)
TabBar.BackgroundColor3 = COLOR_FRAME
TabBar.BorderSizePixel  = 0
TabBar.ZIndex           = 2
TabBar.Parent           = MainFrame

applyStroke(TabBar, 1, COLOR_BORDER)

-- Tombol Tab: Status
btnTabStatus = Instance.new("TextButton")
btnTabStatus.Name             = "TabStatus"
btnTabStatus.Size             = UDim2.new(0, 120, 1, 0)
btnTabStatus.Position         = UDim2.new(0, 0, 0, 0)
btnTabStatus.BackgroundColor3 = COLOR_TAB_ACTIVE
btnTabStatus.Text             = "Status"
btnTabStatus.TextColor3       = COLOR_TEXT_HEADER
btnTabStatus.Font             = FONT_NORMAL
btnTabStatus.TextScaled       = true
btnTabStatus.BorderSizePixel  = 0
btnTabStatus.ZIndex           = 3
btnTabStatus.Parent           = TabBar

applyRounded(btnTabStatus, 4)
applyStroke(btnTabStatus, 1, COLOR_BORDER)

-- Tombol Tab: Teleport
btnTabTeleport = Instance.new("TextButton")
btnTabTeleport.Name             = "TabTeleport"
btnTabTeleport.Size             = UDim2.new(0, 120, 1, 0)
btnTabTeleport.Position         = UDim2.new(0, 120, 0, 0)
btnTabTeleport.BackgroundColor3 = COLOR_TAB_INACTIVE
btnTabTeleport.Text             = "Teleport"
btnTabTeleport.TextColor3       = COLOR_TEXT_HEADER
btnTabTeleport.Font             = FONT_NORMAL
btnTabTeleport.TextScaled       = true
btnTabTeleport.BorderSizePixel  = 0
btnTabTeleport.ZIndex           = 3
btnTabTeleport.Parent           = TabBar

applyRounded(btnTabTeleport, 4)
applyStroke(btnTabTeleport, 1, COLOR_BORDER)

-- Tombol Tab: Unlimited Jump
btnTabJump = Instance.new("TextButton")
btnTabJump.Name             = "TabJump"
btnTabJump.Size             = UDim2.new(0, 120, 1, 0)
btnTabJump.Position         = UDim2.new(0, 240, 0, 0)
btnTabJump.BackgroundColor3 = COLOR_TAB_INACTIVE
btnTabJump.Text             = "Unlimited Jump"
btnTabJump.TextColor3       = COLOR_TEXT_HEADER
btnTabJump.Font             = FONT_NORMAL
btnTabJump.TextScaled       = true
btnTabJump.BorderSizePixel  = 0
btnTabJump.ZIndex           = 3
btnTabJump.Parent           = TabBar

applyRounded(btnTabJump, 4)
applyStroke(btnTabJump, 1, COLOR_BORDER)

-- =========================================================
-- (D) Buat ContentArea di bawah TabBar
-- =========================================================
ContentArea = Instance.new("Frame")
ContentArea.Name                = "ContentArea"
ContentArea.Size                = UDim2.new(1, 0, 1, -60)
ContentArea.Position            = UDim2.new(0, 0, 0, 60)
ContentArea.BackgroundTransparency = 1
ContentArea.ZIndex              = 1
ContentArea.Parent              = MainFrame

--==========================================================--
--=== 4A. STATUS TAB =========================================
--==========================================================--

StatusFrame = Instance.new("Frame")
StatusFrame.Name                      = "StatusFrame"
StatusFrame.Size                      = UDim2.new(1, 0, 1, 0)
StatusFrame.Position                  = UDim2.new(0, 0, 0, 0)
StatusFrame.BackgroundTransparency    = 1
StatusFrame.ZIndex                    = 1
StatusFrame.Parent                    = ContentArea

-- Label Koordinat
local coordLbl = Instance.new("TextLabel")
coordLbl.Name                         = "CoordinatesLabel"
coordLbl.Size                         = UDim2.new(0.8, 0, 0, 24)
coordLbl.Position                     = UDim2.new(0.1, 0, 0.1, 0)
coordLbl.BackgroundTransparency       = 1
coordLbl.Text                         = "Coords: (n/a)"
coordLbl.TextColor3                   = COLOR_TEXT_HEADER
coordLbl.Font                         = FONT_HEADER
coordLbl.TextScaled                   = true
coordLbl.TextXAlignment               = Enum.TextXAlignment.Left
coordLbl.ZIndex                       = 2
coordLbl.Parent                       = StatusFrame

-- Label Money
local moneyLbl = Instance.new("TextLabel")
moneyLbl.Name                         = "MoneyLabel"
moneyLbl.Size                         = UDim2.new(0.8, 0, 0, 24)
moneyLbl.Position                     = UDim2.new(0.1, 0, 0.3, 0)
moneyLbl.BackgroundTransparency       = 1
moneyLbl.Text                         = "Money: (n/a)"
moneyLbl.TextColor3                   = COLOR_TEXT_HEADER
moneyLbl.Font                         = FONT_HEADER
moneyLbl.TextScaled                   = true
moneyLbl.TextXAlignment               = Enum.TextXAlignment.Left
moneyLbl.ZIndex                       = 2
moneyLbl.Parent                       = StatusFrame

-- Simpan reference
StatusFrame.CoordinatesLabel = coordLbl
StatusFrame.MoneyLabel       = moneyLbl

--==========================================================--
--=== 4B. TELEPORT TAB =======================================
--==========================================================--

TeleportFrame = Instance.new("Frame")
TeleportFrame.Name                  = "TeleportFrame"
TeleportFrame.Size                  = UDim2.new(1, 0, 1, 0)
TeleportFrame.Position              = UDim2.new(0, 0, 0, 0)
TeleportFrame.BackgroundTransparency = 1
TeleportFrame.Visible               = false
TeleportFrame.ZIndex                = 1
TeleportFrame.Parent                = ContentArea

-- Label & TextBox X
local lblX = Instance.new("TextLabel")
lblX.Size                           = UDim2.new(0.3, 0, 0, 24)
lblX.Position                       = UDim2.new(0.1, 0, 0.1, 0)
lblX.BackgroundTransparency         = 1
lblX.Text                           = "X:"
lblX.TextColor3                     = COLOR_TEXT_HEADER
lblX.Font                           = FONT_NORMAL
lblX.TextScaled                     = true
lblX.TextXAlignment                 = Enum.TextXAlignment.Left
lblX.ZIndex                         = 2
lblX.Parent                         = TeleportFrame

txtTeleportX = Instance.new("TextBox")
txtTeleportX.Size                   = UDim2.new(0.4, 0, 0, 24)
txtTeleportX.Position               = UDim2.new(0.4, 0, 0.1, 0)
txtTeleportX.BackgroundColor3       = COLOR_BUTTON
txtTeleportX.Text                   = "0"
txtTeleportX.PlaceholderText        = "0"
txtTeleportX.TextColor3             = COLOR_TEXT_HEADER
txtTeleportX.Font                   = FONT_NORMAL
txtTeleportX.TextScaled             = true
txtTeleportX.ClearTextOnFocus       = false
txtTeleportX.BorderSizePixel        = 0
txtTeleportX.ZIndex                 = 2
txtTeleportX.Parent                 = TeleportFrame

applyRounded(txtTeleportX, 4)
applyStroke(txtTeleportX, 1, COLOR_BORDER)

-- Label & TextBox Y
local lblY = Instance.new("TextLabel")
lblY.Size                           = UDim2.new(0.3, 0, 0, 24)
lblY.Position                       = UDim2.new(0.1, 0, 0.3, 0)
lblY.BackgroundTransparency         = 1
lblY.Text                           = "Y:"
lblY.TextColor3                     = COLOR_TEXT_HEADER
lblY.Font                           = FONT_NORMAL
lblY.TextScaled                     = true
lblY.TextXAlignment                 = Enum.TextXAlignment.Left
lblY.ZIndex                         = 2
lblY.Parent                         = TeleportFrame

txtTeleportY = Instance.new("TextBox")
txtTeleportY.Size                   = UDim2.new(0.4, 0, 0, 24)
txtTeleportY.Position               = UDim2.new(0.4, 0, 0.3, 0)
txtTeleportY.BackgroundColor3       = COLOR_BUTTON
txtTeleportY.Text                   = "0"
txtTeleportY.PlaceholderText        = "0"
txtTeleportY.TextColor3             = COLOR_TEXT_HEADER
txtTeleportY.Font                   = FONT_NORMAL
txtTeleportY.TextScaled             = true
txtTeleportY.ClearTextOnFocus       = false
txtTeleportY.BorderSizePixel        = 0
txtTeleportY.ZIndex                 = 2
txtTeleportY.Parent                 = TeleportFrame

applyRounded(txtTeleportY, 4)
applyStroke(txtTeleportY, 1, COLOR_BORDER)

-- Label & TextBox Z
local lblZ = Instance.new("TextLabel")
lblZ.Size                           = UDim2.new(0.3, 0, 0, 24)
lblZ.Position                       = UDim2.new(0.1, 0, 0.5, 0)
lblZ.BackgroundTransparency         = 1
lblZ.Text                           = "Z:"
lblZ.TextColor3                     = COLOR_TEXT_HEADER
lblZ.Font                           = FONT_NORMAL
lblZ.TextScaled                     = true
lblZ.TextXAlignment                 = Enum.TextXAlignment.Left
lblZ.ZIndex                         = 2
lblZ.Parent                         = TeleportFrame

txtTeleportZ = Instance.new("TextBox")
txtTeleportZ.Size                   = UDim2.new(0.4, 0, 0, 24)
txtTeleportZ.Position               = UDim2.new(0.4, 0, 0.5, 0)
txtTeleportZ.BackgroundColor3       = COLOR_BUTTON
txtTeleportZ.Text                   = "0"
txtTeleportZ.PlaceholderText        = "0"
txtTeleportZ.TextColor3             = COLOR_TEXT_HEADER
txtTeleportZ.Font                   = FONT_NORMAL
txtTeleportZ.TextScaled             = true
txtTeleportZ.ClearTextOnFocus       = false
txtTeleportZ.BorderSizePixel        = 0
txtTeleportZ.ZIndex                 = 2
txtTeleportZ.Parent                 = TeleportFrame

applyRounded(txtTeleportZ, 4)
applyStroke(txtTeleportZ, 1, COLOR_BORDER)

-- Tombol Teleport
btnTeleport = createButton(
    TeleportFrame,
    "BtnTeleport",
    UDim2.new(0.5, 0, 0, 32),
    UDim2.new(0.25, 0, 0.75, 0),
    "Teleport",
    teleportPlayer
)

--==========================================================--
--=== 4C. JUMP TAB ===========================================
--==========================================================--

JumpFrame = Instance.new("Frame")
JumpFrame.Name                   = "JumpFrame"
JumpFrame.Size                   = UDim2.new(1, 0, 1, 0)
JumpFrame.Position               = UDim2.new(0, 0, 0, 0)
JumpFrame.BackgroundTransparency = 1
JumpFrame.Visible                = false
JumpFrame.ZIndex                 = 1
JumpFrame.Parent                 = ContentArea

-- Label & TextBox untuk Jump Speed
local lblJS = Instance.new("TextLabel")
lblJS.Size               = UDim2.new(0.6, 0, 0, 24)
lblJS.Position           = UDim2.new(0.1, 0, 0.1, 0)
lblJS.BackgroundTransparency = 1
lblJS.Text               = "Jump Speed (jumps/detik):"
lblJS.TextColor3         = COLOR_TEXT_HEADER
lblJS.Font               = FONT_NORMAL
lblJS.TextScaled         = true
lblJS.TextXAlignment     = Enum.TextXAlignment.Left
lblJS.ZIndex             = 2
lblJS.Parent             = JumpFrame

txtJumpSpeed = Instance.new("TextBox")
txtJumpSpeed.Size            = UDim2.new(0.3, 0, 0, 24)
txtJumpSpeed.Position        = UDim2.new(0.6, 0, 0.1, 0)
txtJumpSpeed.BackgroundColor3= COLOR_BUTTON
txtJumpSpeed.Text            = "5"
txtJumpSpeed.PlaceholderText = "5"
txtJumpSpeed.TextColor3      = COLOR_TEXT_HEADER
txtJumpSpeed.Font            = FONT_NORMAL
txtJumpSpeed.TextScaled      = true
txtJumpSpeed.ClearTextOnFocus= false
txtJumpSpeed.BorderSizePixel = 0
txtJumpSpeed.ZIndex          = 2
txtJumpSpeed.Parent          = JumpFrame

applyRounded(txtJumpSpeed, 4)
applyStroke(txtJumpSpeed, 1, COLOR_BORDER)

-- Status Label ON/OFF
lblJumpStatus = Instance.new("TextLabel")
lblJumpStatus.Size               = UDim2.new(0.4, 0, 0, 24)
lblJumpStatus.Position           = UDim2.new(0.55, 0, 0.3, 0)
lblJumpStatus.BackgroundColor3   = COLOR_FRAME
lblJumpStatus.BorderSizePixel    = 0
lblJumpStatus.Text               = "OFF"
lblJumpStatus.TextColor3         = COLOR_TEXT_OFF
lblJumpStatus.Font               = FONT_HEADER
lblJumpStatus.TextScaled         = true
lblJumpStatus.ZIndex             = 2
lblJumpStatus.Parent             = JumpFrame

applyRounded(lblJumpStatus, 4)
applyStroke(lblJumpStatus, 1, COLOR_BORDER)

-- Tombol Toggle Unlimited Jump
btnJumpToggle = createButton(
    JumpFrame,
    "BtnJumpToggle",
    UDim2.new(0.5, 0, 0, 32),
    UDim2.new(0.25, 0, 0.6, 0),
    "Toggle Unlimited Jump",
    toggleUnlimitedJump
)

--==========================================================--
--=== 5. DEFINISIKAN switchTab & KONEKSI TAB BUTTONS ========
--==========================================================--

-- Pastikan switchTab didefinisikan hanya setelah semua frame & tombol tab selesai dibuat
local function switchTab(activeTab)
    -- Reset semua tab ke inactive
    btnTabStatus.BackgroundColor3   = COLOR_TAB_INACTIVE
    btnTabTeleport.BackgroundColor3 = COLOR_TAB_INACTIVE
    btnTabJump.BackgroundColor3     = COLOR_TAB_INACTIVE

    -- Hide semua frame
    StatusFrame.Visible   = false
    TeleportFrame.Visible = false
    JumpFrame.Visible     = false

    -- Aktifkan tab & frame yang dipilih
    if activeTab == "Status" then
        btnTabStatus.BackgroundColor3 = COLOR_TAB_ACTIVE
        StatusFrame.Visible = true
    elseif activeTab == "Teleport" then
        btnTabTeleport.BackgroundColor3 = COLOR_TAB_ACTIVE
        TeleportFrame.Visible = true
    elseif activeTab == "Jump" then
        btnTabJump.BackgroundColor3 = COLOR_TAB_ACTIVE
        JumpFrame.Visible = true
    end
end

-- Sambungkan klik tombol tab ke switchTab
btnTabStatus.MouseButton1Click:Connect(function()
    switchTab("Status")
end)
btnTabTeleport.MouseButton1Click:Connect(function()
    switchTab("Teleport")
end)
btnTabJump.MouseButton1Click:Connect(function()
    switchTab("Jump")
end)

--==========================================================--
--=== 6. KONEKSI & UPDATE LOOP ==============================--
--==========================================================--

-- Hubungkan updateStatus ke Heartbeat
RunService.Heartbeat:Connect(updateStatus)

-- Default aktifkan tab “Status”
switchTab("Status")

--==========================================================--
--=== 7. LOG KONFIRMASI =======================================
--==========================================================--

print("HXEL Multi-Tab UI v2.2 Loaded.") 
