-- HXEL Script by [Nama Anda]
-- Versi 2.1 (2025-06-02)
-- Fitur: Unlimited Jump (Auto-Jump) dgn kecepatan kustom, GUI dengan minimize/maximize, rounded corners, border stroke, animasi Tween.

--==========================================================--
--=== 1. DEFINISI KONFIGURASI & VARIABEL POKOK ================--
--==========================================================--

local Players      = game:GetService("Players")
local CoreGui      = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local player       = Players.LocalPlayer
local character    = player.Character or player.CharacterAdded:Wait()
local humanoid     = character:WaitForChild("Humanoid")

-- Color / Styling
local COLOR_BG        = Color3.fromRGB(25, 25, 35)
local COLOR_FRAME     = Color3.fromRGB(40, 40, 50)
local COLOR_TITLE     = Color3.fromRGB(0, 200, 180)
local COLOR_BUTTON    = Color3.fromRGB(60, 60, 80)
local COLOR_BUTTON_H  = Color3.fromRGB(80, 80, 100)
local COLOR_TEXT_ON   = Color3.fromRGB(0, 255, 0)
local COLOR_TEXT_OFF  = Color3.fromRGB(200, 200, 200)
local BORDER_COLOR    = Color3.fromRGB(60, 60, 80)

local FONT_LABEL      = Enum.Font.GothamBold
local FONT_BUTTON     = Enum.Font.Gotham

-- Status Flag
local isUnlimitedJumpEnabled = false
local isMinimized            = false

-- Module Unlimited Jump (dimuat via loadstring)
local unljmpModule = nil

-- GUI References (akan diinisialisasi di bagian 4)
local MainGui, MainFrame, TitleBar
local btnClose, btnMinimize, lblTitle
local ContentFrame
local lblSpeedText, txtJumpSpeed
local lblJumpStatus, btnJump

-- Animasi tween untuk minimize/maximize
local tweenInfoShort = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Ukuran‐ukuran awal (sebagai referensi saat restore)
local ORIGINAL_SIZE = UDim2.new(0, 300, 0, 180)
local MINIMIZED_SIZE = UDim2.new(0, 300, 0, 30)

--==========================================================--
--=== 2. FUNGSI PENDUKUNG ====================================--
--==========================================================--

-- Helper: Membuat rounded corner pada sebuah instance
local function applyRoundedCorners(inst, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = inst
end

-- Helper: Membuat border stroke pada sebuah instance
local function applyBorderStroke(inst, thickness, color)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = thickness or 1
    stroke.Color = color or BORDER_COLOR
    stroke.Parent = inst
end

-- Fungsi untuk membuat StatusLabel (ON/OFF)
local function createStatusLabel(parentFrame, anchorPos)
    local lbl = Instance.new("TextLabel")
    lbl.Size             = UDim2.new(0.4, 0, 0, 20)
    lbl.Position         = anchorPos
    lbl.BackgroundColor3 = COLOR_FRAME
    lbl.BorderSizePixel  = 0
    lbl.Text             = "OFF"
    lbl.TextScaled       = true
    lbl.TextColor3       = COLOR_TEXT_OFF
    lbl.Font             = FONT_LABEL
    lbl.Parent           = parentFrame
    applyRoundedCorners(lbl, 4)
    applyBorderStroke(lbl, 1, BORDER_COLOR)
    return lbl
end

-- Fungsi untuk membuat Button dengan hover effect
local function createButton(parentFrame, name, anchorY, text, callback)
    local btn = Instance.new("TextButton")
    btn.Name             = name
    btn.Size             = UDim2.new(0.8, 0, 0, 32)
    btn.Position         = UDim2.new(0.1, 0, anchorY, 0)
    btn.BackgroundColor3 = COLOR_BUTTON
    btn.Text             = text
    btn.TextColor3       = COLOR_TEXT_OFF
    btn.Font             = FONT_BUTTON
    btn.TextScaled       = true
    btn.BorderSizePixel  = 0
    btn.Parent           = parentFrame

    applyRoundedCorners(btn, 4)
    applyBorderStroke(btn, 1, BORDER_COLOR)

    -- Hover effect: ganti warna saat kursor di atas
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

-- Tween helper: resize MainFrame ke ukuran target
local function tweenMainFrameSize(targetSize)
    if MainFrame then
        TweenService:Create(MainFrame, tweenInfoShort, {Size = targetSize}):Play()
    end
end

--==========================================================--
--=== 3. IMPLEMENTASI FUNGSI UTAMA ==========================--
--==========================================================--

-- Toggle Minimize / Maximize
local function toggleMinimize()
    if isMinimized then
        -- Maximize kembali
        tweenMainFrameSize(ORIGINAL_SIZE)
        -- Tampilkan konten (fade in sederhana)
        ContentFrame.Visible = true
        isMinimized = false
        btnMinimize.Text = "–"
    else
        -- Minimize (hanya TitleBar)
        tweenMainFrameSize(MINIMIZED_SIZE)
        -- Setelah animasi selesai, sembunyikan konten agar tidak interaksi
        delay(0.2, function()
            if MainFrame.Size == MINIMIZED_SIZE then
                ContentFrame.Visible = false
            end
        end)
        isMinimized = true
        btnMinimize.Text = "+"
    end
end

-- Toggle Unlimited Jump (sama seperti sebelumnya, tapi update status label)
local function toggleUnlimitedJump()
    isUnlimitedJumpEnabled = not isUnlimitedJumpEnabled

    if isUnlimitedJumpEnabled then
        -- Lazy‐load modul sekali saja
        if not unljmpModule then
            local success, result = pcall(function()
                return loadstring(game:HttpGet(
                    "https://raw.githubusercontent.com/RABZBOT/RABZBOT/main/fit/unljmp.lua",
                    true
                ))()
            end)

            if success and type(result) == "table" then
                unljmpModule = result
            else
                warn("Gagal load modul Unlimited Jump:", result)
                isUnlimitedJumpEnabled = false
                lblJumpStatus.Text = "OFF"
                lblJumpStatus.TextColor3 = COLOR_TEXT_OFF
                return
            end
        end

        -- Set speed dari TextBox jika valid
        local inputSpeed = tonumber(txtJumpSpeed.Text)
        if inputSpeed and inputSpeed > 0 then
            unljmpModule.SetSpeed(inputSpeed)
        end

        unljmpModule.Enable()
        lblJumpStatus.Text = "ON"
        lblJumpStatus.TextColor3 = COLOR_TEXT_ON
    else
        if unljmpModule then
            unljmpModule.Disable()
        end
        lblJumpStatus.Text = "OFF"
        lblJumpStatus.TextColor3 = COLOR_TEXT_OFF
    end
end

-- Unload Script (Close)
local function unloadScript()
    -- Matikan Unlimited Jump jika aktif
    if isUnlimitedJumpEnabled and unljmpModule then
        unljmpModule.Disable()
    end

    -- Panggil Destroy pada modul jika sudah load
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

--==========================================================--
--=== 4. MEMBANGUN & MENATA GUI UTAMA =======================--
--==========================================================--

-- Hapus GUI lama bila ada
if CoreGui:FindFirstChild("HXEL_Main") then
    CoreGui.HXEL_Main:Destroy()
end

-- Buat ScreenGui
MainGui = Instance.new("ScreenGui")
MainGui.Name   = "HXEL_Main"
MainGui.Parent = CoreGui

-- Buat MainFrame (rounded, border stroke)
MainFrame = Instance.new("Frame")
MainFrame.Name             = "MainFrame"
MainFrame.Size             = ORIGINAL_SIZE
MainFrame.Position         = UDim2.new(0.5, -150, 0.5, -90)
MainFrame.BackgroundColor3 = COLOR_BG
MainFrame.BorderSizePixel  = 0
MainFrame.Active           = true
MainFrame.Selectable       = true
MainFrame.Parent           = MainGui

applyRoundedCorners(MainFrame, 12)
applyBorderStroke(MainFrame, 2, BORDER_COLOR)

-- Title Bar (rounded atas, warna kontras, border stroke)
TitleBar = Instance.new("Frame")
TitleBar.Name             = "TitleBar"
TitleBar.Size             = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = COLOR_TITLE
TitleBar.BorderSizePixel  = 0
TitleBar.Parent           = MainFrame

applyRoundedCorners(TitleBar, 12)
applyBorderStroke(TitleBar, 1, BORDER_COLOR)

-- Judul (dalam TitleBar)
lblTitle = Instance.new("TextLabel")
lblTitle.Size               = UDim2.new(1, -70, 1, 0)
lblTitle.Position           = UDim2.new(0, 10, 0, 0)
lblTitle.BackgroundTransparency = 1
lblTitle.Text               = "HXEL - Unlimited Jump"
lblTitle.TextColor3         = Color3.fromRGB(255, 255, 255)
lblTitle.Font               = FONT_LABEL
lblTitle.TextScaled         = true
lblTitle.Parent             = TitleBar

-- Tombol Minimize (“–” / “+”)
btnMinimize = Instance.new("TextButton")
btnMinimize.Name             = "MinimizeButton"
btnMinimize.Size             = UDim2.new(0, 25, 0, 25)
btnMinimize.Position         = UDim2.new(1, -60, 0, 2)
btnMinimize.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
btnMinimize.Text             = "–"
btnMinimize.TextColor3       = Color3.fromRGB(255, 255, 255)
btnMinimize.Font             = FONT_BUTTON
btnMinimize.TextScaled       = true
btnMinimize.BorderSizePixel  = 0
btnMinimize.Parent           = TitleBar

applyRoundedCorners(btnMinimize, 4)
applyBorderStroke(btnMinimize, 1, BORDER_COLOR)

btnMinimize.MouseButton1Click:Connect(toggleMinimize)

-- Tombol Close (“X”)
btnClose = Instance.new("TextButton")
btnClose.Name               = "CloseButton"
btnClose.Size               = UDim2.new(0, 25, 0, 25)
btnClose.Position           = UDim2.new(1, -30, 0, 2)
btnClose.BackgroundColor3   = Color3.fromRGB(200, 50, 50)
btnClose.Text               = "X"
btnClose.TextColor3         = Color3.fromRGB(255, 255, 255)
btnClose.Font               = FONT_BUTTON
btnClose.TextScaled         = true
btnClose.BorderSizePixel    = 0
btnClose.Parent             = TitleBar

applyRoundedCorners(btnClose, 4)
applyBorderStroke(btnClose, 1, BORDER_COLOR)

btnClose.MouseButton1Click:Connect(unloadScript)

-- Dragging Behavior untuk TitleBar
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

-- Container untuk konten (speed, status, tombol)
ContentFrame = Instance.new("Frame")
ContentFrame.Name                = "ContentFrame"
ContentFrame.Size                = UDim2.new(1, 0, 1, -30)
ContentFrame.Position            = UDim2.new(0, 0, 0, 30)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent              = MainFrame

-- Label & TextBox untuk Jump Speed
lblSpeedText = Instance.new("TextLabel")
lblSpeedText.Size               = UDim2.new(0.6, 0, 0, 20)
lblSpeedText.Position           = UDim2.new(0.05, 0, 0.1, 0)
lblSpeedText.BackgroundTransparency = 1
lblSpeedText.Text               = "Jump Speed (jumps/detik):"
lblSpeedText.TextColor3         = COLOR_TEXT_OFF
lblSpeedText.Font               = FONT_BUTTON
lblSpeedText.TextScaled         = true
lblSpeedText.TextXAlignment     = Enum.TextXAlignment.Left
lblSpeedText.Parent             = ContentFrame

txtJumpSpeed = Instance.new("TextBox")
txtJumpSpeed.Size               = UDim2.new(0.25, 0, 0, 20)
txtJumpSpeed.Position           = UDim2.new(0.65, 0, 0.1, 0)
txtJumpSpeed.BackgroundColor3   = COLOR_BUTTON
txtJumpSpeed.Text               = "5"
txtJumpSpeed.PlaceholderText    = "5"
txtJumpSpeed.TextColor3         = COLOR_TEXT_OFF
txtJumpSpeed.Font               = FONT_BUTTON
txtJumpSpeed.TextScaled         = true
txtJumpSpeed.ClearTextOnFocus   = false
txtJumpSpeed.BorderSizePixel    = 0
txtJumpSpeed.Parent             = ContentFrame

applyRoundedCorners(txtJumpSpeed, 4)
applyBorderStroke(txtJumpSpeed, 1, BORDER_COLOR)

-- Status Label (ON/OFF) untuk Unlimited Jump
lblJumpStatus = createStatusLabel(ContentFrame, UDim2.new(0.65, 0, 0.4, 0))
lblJumpStatus.Text = "OFF"
lblJumpStatus.TextColor3 = COLOR_TEXT_OFF

-- Tombol Toggle Unlimited Jump
btnJump = createButton(ContentFrame, "BtnUnlimitedJump", 0.6, "Toggle Unlimited Jump", function()
    toggleUnlimitedJump()
end)

--==========================================================--
--=== 5. LOG KONFIRMASI ===============------------------------
--==========================================================--
print("HXEL Unlimited Jump v2.1 Loaded.") 
