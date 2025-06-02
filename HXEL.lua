-- HXEL Script by [Nama Anda]
-- Versi 2.0 (2025-06-02)
-- Fitur: Unlimited Jump (Auto-Jump) dengan kecepatan kustom, Clean Unload

--==========================================================--
--=== 1. DEFINISI KONFIGURASI & VARIABEL POKOK ================--
--==========================================================--

local Players      = game:GetService("Players")
local CoreGui      = game:GetService("CoreGui")
local RunService   = game:GetService("RunService")

local player       = Players.LocalPlayer
local character    = player.Character or player.CharacterAdded:Wait()
local humanoid     = character:WaitForChild("Humanoid")

-- Color / Styling
local COLOR_BG       = Color3.fromRGB(30, 30, 40)
local COLOR_FRAME    = Color3.fromRGB(25, 25, 35)
local COLOR_BUTTON   = Color3.fromRGB(60, 60, 80)
local COLOR_TEXT_ON  = Color3.fromRGB(0, 255, 0)
local COLOR_TEXT_OFF = Color3.fromRGB(255, 255, 255)
local FONT_LABEL     = Enum.Font.GothamBold
local FONT_BUTTON    = Enum.Font.Gotham

-- Status Flag
local isUnlimitedJumpEnabled = false

-- Module Unlimited Jump (akan di-load via loadstring)
local unljmpModule = nil

-- GUI References (akan di-buat pada bagian GUI)
local lblJumpStatus   = nil
local txtJumpSpeed    = nil

--==========================================================--
--=== 2. FUNGSI PENDUKUNG ====================================--
--==========================================================--

local function createStatusLabel(parentFrame, anchorPos)
    local lbl = Instance.new("TextLabel")
    lbl.Size            = UDim2.new(0.4, 0, 0, 20)
    lbl.Position        = anchorPos
    lbl.BackgroundColor3= COLOR_FRAME
    lbl.BorderSizePixel = 0
    lbl.Text            = "OFF"
    lbl.TextScaled      = true
    lbl.TextColor3      = COLOR_TEXT_OFF
    lbl.Font            = FONT_LABEL
    lbl.Parent          = parentFrame
    return lbl
end

local function createButton(parentFrame, name, anchorY, text, callback)
    local btn = Instance.new("TextButton")
    btn.Name             = name
    btn.Size             = UDim2.new(0.8, 0, 0, 40)
    btn.Position         = UDim2.new(0.1, 0, anchorY, 0)
    btn.BackgroundColor3 = COLOR_BUTTON
    btn.Text             = text
    btn.TextColor3       = COLOR_TEXT_OFF
    btn.Font             = FONT_BUTTON
    btn.TextScaled       = true
    btn.AutomaticSize    = Enum.AutomaticSize.None
    btn.Parent           = parentFrame

    btn.MouseButton1Click:Connect(function()
        callback(btn)
    end)

    return btn
end

--==========================================================--
--=== 3. IMPLEMENTASI FUNGSI UTAMA ==========================--
--==========================================================--

local function toggleUnlimitedJump()
    isUnlimitedJumpEnabled = not isUnlimitedJumpEnabled

    if isUnlimitedJumpEnabled then
        -- Lazy-load modul hanya sekali
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

local function unloadScript()
    -- Matikan Unlimited Jump jika aktif
    if isUnlimitedJumpEnabled and unljmpModule then
        unljmpModule.Disable()
    end

    -- Panggil Destroy() modul jika sudah ter-load
    if unljmpModule then
        unljmpModule.Destroy()
        unljmpModule = nil
    end

    -- Hancurkan GUI
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
local HXEL = Instance.new("ScreenGui")
HXEL.Name   = "HXEL_Main"
HXEL.Parent = CoreGui

-- Buat MainFrame
local MainFrame = Instance.new("Frame")
MainFrame.Name             = "MainFrame"
MainFrame.Size             = UDim2.new(0, 300, 0, 180)
MainFrame.Position         = UDim2.new(0.5, -150, 0.5, -90)
MainFrame.BackgroundColor3 = COLOR_BG
MainFrame.BorderSizePixel  = 0
MainFrame.Active           = true
MainFrame.Selectable       = true
MainFrame.Parent           = HXEL

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Name             = "TitleBar"
TitleBar.Size             = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = COLOR_FRAME
TitleBar.BorderSizePixel  = 0
TitleBar.Parent           = MainFrame

-- Judul
local lblTitle = Instance.new("TextLabel")
lblTitle.Size               = UDim2.new(1, -35, 1, 0)
lblTitle.Position           = UDim2.new(0, 10, 0, 0)
lblTitle.BackgroundTransparency = 1
lblTitle.Text               = "HXEL - Unlimited Jump"
lblTitle.TextColor3         = Color3.fromRGB(0, 255, 200)
lblTitle.Font               = FONT_LABEL
lblTitle.TextScaled         = true
lblTitle.Parent             = TitleBar

-- Tombol Close
local btnClose = Instance.new("TextButton")
btnClose.Name               = "CloseButton"
btnClose.Size               = UDim2.new(0, 25, 0, 25)
btnClose.Position           = UDim2.new(1, -30, 0, 2)
btnClose.BackgroundColor3   = Color3.fromRGB(200, 50, 50)
btnClose.Text               = "X"
btnClose.TextColor3         = Color3.fromRGB(255, 255, 255)
btnClose.Font               = FONT_BUTTON
btnClose.TextScaled         = true
btnClose.Parent             = TitleBar
btnClose.MouseButton1Click:Connect(unloadScript)

-- Draggable Behavior (judul bisa drag)
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

-- Container Konten
local ContentFrame = Instance.new("Frame")
ContentFrame.Name                = "ContentFrame"
ContentFrame.Size                = UDim2.new(1, 0, 1, -30)
ContentFrame.Position            = UDim2.new(0, 0, 0, 30)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent              = MainFrame

-- Label & TextBox untuk Jump Speed
local lblSpeedText = Instance.new("TextLabel")
lblSpeedText.Size               = UDim2.new(0.5, 0, 0, 25)
lblSpeedText.Position           = UDim2.new(0.05, 0, 0.1, 0)
lblSpeedText.BackgroundTransparency = 1
lblSpeedText.Text               = "Jump Speed (jumps/detik):"
lblSpeedText.TextColor3         = COLOR_TEXT_OFF
lblSpeedText.Font               = FONT_BUTTON
lblSpeedText.TextScaled         = true
lblSpeedText.Parent             = ContentFrame

txtJumpSpeed = Instance.new("TextBox")
txtJumpSpeed.Size               = UDim2.new(0.3, 0, 0, 25)
txtJumpSpeed.Position           = UDim2.new(0.55, 0, 0.1, 0)
txtJumpSpeed.BackgroundColor3   = COLOR_BUTTON
txtJumpSpeed.Text               = "5"
txtJumpSpeed.PlaceholderText    = "5"
txtJumpSpeed.TextColor3         = COLOR_TEXT_OFF
txtJumpSpeed.Font               = FONT_BUTTON
txtJumpSpeed.TextScaled         = true
txtJumpSpeed.ClearTextOnFocus   = false
txtJumpSpeed.Parent             = ContentFrame

-- Status Label (ON/OFF)
lblJumpStatus = createStatusLabel(ContentFrame, UDim2.new(0.65, 0, 0.5, 0))
lblJumpStatus.Text = "OFF"
lblJumpStatus.TextColor3 = COLOR_TEXT_OFF

-- Tombol Toggle Unlimited Jump
local btnJump = createButton(ContentFrame, "BtnUnlimitedJump", 0.3, "Toggle Unlimited Jump", function()
    toggleUnlimitedJump()
end)

--==========================================================--
--=== 5. LOG KONFIRMASI ===============------------------------
--==========================================================--
print("HXEL Unlimited Jump Loaded.") 
