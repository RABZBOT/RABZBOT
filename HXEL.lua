-- HXEL Script by [Nama Anda]
-- Versi 2.0 (2025-06-02)
-- Fitur: Unlimited Jump (modular), Speed Hack dengan nilai kustom, Noclip, Anti-AFK, Clean Unload

--==========================================================--
--=== 1. DEFINISI KONFIGURASI & VARIABEL POKOK ================--
--==========================================================--

-- Services
local Players       = game:GetService("Players")
local UserInput     = game:GetService("UserInputService")
local RunService    = game:GetService("RunService")
local CoreGui       = game:GetService("CoreGui")
local VirtualUser   = game:GetService("VirtualUser")

-- Player & Character (akan di‐set pada CharacterAdded)
local player        = Players.LocalPlayer
local character     = player.Character or player.CharacterAdded:Wait()
local humanoid      = character:WaitForChild("Humanoid")

-- Nilai Default
local DEFAULT_SPEED = 100    -- Default nilai Speed Hack (stud/s)
local AFK_INTERVAL  = 60     -- Interval detik untuk mengirim input anti-AFK

-- Warna & Styling
local COLOR_BG       = Color3.fromRGB(30, 30, 40)
local COLOR_FRAME    = Color3.fromRGB(25, 25, 35)
local COLOR_BUTTON   = Color3.fromRGB(60, 60, 80)
local COLOR_TEXT_ON  = Color3.fromRGB(0, 255, 0)
local COLOR_TEXT_OFF = Color3.fromRGB(255, 255, 255)
local FONT_LABEL     = Enum.Font.GothamBold
local FONT_BUTTON    = Enum.Font.Gotham

-- Status Flags
local isUnlimitedJumpEnabled = false
local isSpeedHackEnabled     = false
local isNoclipEnabled        = false
local isAntiAFKEnabled       = false

-- Simpan koneksi agar bisa di‐disconnect ketika dimatikan
local speedOriginal      = nil
local noclipConnection   = nil
local afkConnection      = nil

-- Module Unlimited Jump (akan di‐load via loadstring)
local unljmpModule = nil

--==========================================================--
--=== 2. FUNGSI-PUNGSI PENDUKUNG (UTILITIES) ================--
--==========================================================--

-- Fungsi untuk membuat StatusLabel (ON/OFF)
local function createStatusLabel(parentFrame, anchorPos)
    local lbl = Instance.new("TextLabel")
    lbl.Size            = UDim2.new(0.3, 0, 0, 20)
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

-- Fungsi untuk membuat Button
local function createButton(parentFrame, name, anchorY, text, callback)
    local btn = Instance.new("TextButton")
    btn.Name               = name
    btn.Size               = UDim2.new(0.8, 0, 0, 40)
    btn.Position           = UDim2.new(0.1, 0, anchorY, 0)
    btn.BackgroundColor3   = COLOR_BUTTON
    btn.Text               = text
    btn.TextColor3         = COLOR_TEXT_OFF
    btn.Font               = FONT_BUTTON
    btn.TextScaled         = true
    btn.AutomaticSize      = Enum.AutomaticSize.None
    btn.Parent             = parentFrame

    -- Ketika Button diklik, jalankan callback
    btn.MouseButton1Click:Connect(function()
        callback(btn)
    end)

    return btn
end

-- Fungsi untuk mengupdate posisi Humanoid & references ketika respawn (umum untuk Speed & Noclip)
local function onCharacterAdded(char)
    character = char
    humanoid  = character:WaitForChild("Humanoid")
    -- Jika Speed Hack sedang aktif, pulihkan speed ke nilai kustom
    if isSpeedHackEnabled and tonumber(txtSpeedInput.Text) then
        humanoid.WalkSpeed = tonumber(txtSpeedInput.Text)
    elseif not isSpeedHackEnabled then
        humanoid.WalkSpeed = speedOriginal or humanoid.WalkSpeed
    end

    -- Jika Noclip sedang aktif, langsung set CanCollide = false untuk semua part baru
    if isNoclipEnabled then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end

-- Tambahkan listener agar saat respawn, references ter‐update
player.CharacterAdded:Connect(onCharacterAdded)

--==========================================================--
--=== 3. IMPLENTASI FUNGSI-FUNGSI UTAMA =======================--
--==========================================================--

----- 3.1 Unlimited Jump (Modular via loadstring) -----
local function toggleUnlimitedJump()
    isUnlimitedJumpEnabled = not isUnlimitedJumpEnabled
    if isUnlimitedJumpEnabled then
        -- Jika belum ada module, load via loadstring
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
                return
            end
        end
        -- Panggil Enable pada modul
        unljmpModule.Enable()
        lblJumpStatus.Text = "Unlimited Jump: ON"
        lblJumpStatus.TextColor3 = COLOR_TEXT_ON
    else
        -- Disable & clear module jika perlu
        if unljmpModule then
            unljmpModule.Disable()
        end
        lblJumpStatus.Text = "Unlimited Jump: OFF"
        lblJumpStatus.TextColor3 = COLOR_TEXT_OFF
    end
end

----- 3.2 Speed Hack -----
-- Kita tambahkan sebuah TextBox untuk memasukkan nilai speed kustom
local function toggleSpeedHack()
    isSpeedHackEnabled = not isSpeedHackEnabled
    if isSpeedHackEnabled then
        -- Simpan original speed untuk restore nanti
        speedOriginal = humanoid.WalkSpeed
        -- Ambil nilai dari txtSpeedInput, jika tidak valid gunakan DEFAULT_SPEED
        local inputSpeed = tonumber(txtSpeedInput.Text)
        local newSpeed = (inputSpeed and inputSpeed > 0) and inputSpeed or DEFAULT_SPEED
        humanoid.WalkSpeed = newSpeed
        lblSpeedStatus.Text = "Speed Hack: ON (" .. tostring(newSpeed) .. ")"
        lblSpeedStatus.TextColor3 = COLOR_TEXT_ON
    else
        humanoid.WalkSpeed = speedOriginal or humanoid.WalkSpeed
        lblSpeedStatus.Text = "Speed Hack: OFF"
        lblSpeedStatus.TextColor3 = COLOR_TEXT_OFF
    end
end

----- 3.3 Noclip -----
local function updateNoclipParts()
    if character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end

local function toggleNoclip()
    isNoclipEnabled = not isNoclipEnabled
    lblNoclipStatus.Text = "Noclip: " .. (isNoclipEnabled and "ON" or "OFF")
    lblNoclipStatus.TextColor3 = isNoclipEnabled and COLOR_TEXT_ON or COLOR_TEXT_OFF

    if isNoclipEnabled then
        -- Pertama‐tama set untuk semua part yang ada sekarang
        updateNoclipParts()
        -- Sambung ke Stepped agar setiap frame part baru juga di‐disable collidenya
        noclipConnection = RunService.Stepped:Connect(updateNoclipParts)
    else
        -- Kembalikan CanCollide = true untuk part (opsional)
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
        -- Disconnect loop
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
    end
end

----- 3.4 Anti-AFK (VirtualUser) -----
local function toggleAntiAFK()
    isAntiAFKEnabled = not isAntiAFKEnabled
    lblAntiAFKStatus.Text = "Anti-AFK: " .. (isAntiAFKEnabled and "ON" or "OFF")
    lblAntiAFKStatus.TextColor3 = isAntiAFKEnabled and COLOR_TEXT_ON or COLOR_TEXT_OFF

    if isAntiAFKEnabled then
        local timeAccumulator = 0
        afkConnection = RunService.Heartbeat:Connect(function(dt)
            timeAccumulator = timeAccumulator + dt
            if timeAccumulator >= AFK_INTERVAL then
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(0, 0))
                timeAccumulator = 0
            end
        end)
    else
        if afkConnection then
            afkConnection:Disconnect()
            afkConnection = nil
        end
    end
end

----- 3.5 Clean Unload (Destroy GUI + Disconnect Semuanya) -----
local function unloadScript()
    -- Matikan semua fitur jika sedang aktif
    if isUnlimitedJumpEnabled and unljmpModule then
        unljmpModule.Disable()
    end
    if isSpeedHackEnabled then toggleSpeedHack() end
    if isNoclipEnabled then toggleNoclip() end
    if isAntiAFKEnabled then toggleAntiAFK() end

    -- Jika modul Unlimited Jump sudah di‐load, panggil Destroy
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
--=== 4. PEMBUATAN & PENATAAN GUI UTAMA ======================--
--==========================================================--

-- Hancurkan GUI lama jika ada
if CoreGui:FindFirstChild("HXEL_Main") then
    CoreGui.HXEL_Main:Destroy()
end

-- Buat ScreenGui
local HXEL = Instance.new("ScreenGui")
HXEL.Name   = "HXEL_Main"
HXEL.Parent = CoreGui

-- Buat MainFrame
local MainFrame = Instance.new("Frame")
MainFrame.Name            = "MainFrame"
MainFrame.Size            = UDim2.new(0, 320, 0, 300)
MainFrame.Position        = UDim2.new(0.5, -160, 0.5, -150)
MainFrame.BackgroundColor3= COLOR_BG
MainFrame.BorderSizePixel = 0
MainFrame.Active          = true
MainFrame.Selectable      = true
MainFrame.Parent          = HXEL

-- Title Bar (Judul + Tombol Close)
local TitleBar = Instance.new("Frame")
TitleBar.Name             = "TitleBar"
TitleBar.Size             = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = COLOR_FRAME
TitleBar.BorderSizePixel  = 0
TitleBar.Parent           = MainFrame

-- Judul
local lblTitle = Instance.new("TextLabel")
lblTitle.Size             = UDim2.new(1, -40, 1, 0)
lblTitle.Position         = UDim2.new(0, 10, 0, 0)
lblTitle.BackgroundTransparency = 1
lblTitle.Text             = "HXEL - HYPER EXPLOIT v2.0"
lblTitle.TextColor3       = Color3.fromRGB(0, 255, 200)
lblTitle.Font             = FONT_LABEL
lblTitle.TextScaled       = true
lblTitle.Parent           = TitleBar

-- Tombol Close di TitleBar
local btnClose = Instance.new("TextButton")
btnClose.Name             = "CloseButton"
btnClose.Size             = UDim2.new(0, 30, 0, 30)
btnClose.Position         = UDim2.new(1, -35, 0, 5)
btnClose.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
btnClose.Text             = "X"
btnClose.TextColor3       = Color3.fromRGB(255, 255, 255)
btnClose.Font             = FONT_BUTTON
btnClose.TextScaled       = true
btnClose.Parent           = TitleBar
btnClose.MouseButton1Click:Connect(unloadScript)

-- Draggable Behavior
do
    local dragging       = false
    local dragStart      = nil
    local startPos       = nil

    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
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
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            if dragging then
                local delta = input.Position - dragStart
                MainFrame.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end
    end)
end

-- Container untuk tombol‐tombol dan status
local ContentFrame = Instance.new("Frame")
ContentFrame.Name            = "ContentFrame"
ContentFrame.Size            = UDim2.new(1, 0, 1, -40)
ContentFrame.Position        = UDim2.new(0, 0, 0, 40)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent          = MainFrame

-- Layout vertical
local uiLayout = Instance.new("UIListLayout")
uiLayout.Parent       = ContentFrame
uiLayout.FillDirection= Enum.FillDirection.Vertical
uiLayout.SortOrder    = Enum.SortOrder.LayoutOrder
uiLayout.Padding      = UDim.new(0, 8)

-- Spacer (wrapper atas)
local Spacer = Instance.new("Frame")
Spacer.Size             = UDim2.new(1, 0, 0, 10)
Spacer.BackgroundTransparency = 1
Spacer.LayoutOrder      = 1
Spacer.Parent           = ContentFrame

-- Baris 1: Unlimited Jump
local rowJump = Instance.new("Frame")
rowJump.Size             = UDim2.new(1, 0, 0, 40)
rowJump.BackgroundTransparency = 1
rowJump.LayoutOrder      = 2
rowJump.Parent           = ContentFrame

local btnJump = createButton(rowJump, "BtnUnlimitedJump", 0, "Toggle Unlimited Jump", function() toggleUnlimitedJump() end)
btnJump.Size              = UDim2.new(0.6, 0, 1, 0)
btnJump.Position          = UDim2.new(0, 10, 0, 0)
lblJumpStatus             = createStatusLabel(rowJump, UDim2.new(0.7, 0, 0, 10))

-- Baris 2: Speed Hack + Input Speed Kustom
local rowSpeed = Instance.new("Frame")
rowSpeed.Size            = UDim2.new(1, 0, 0, 40)
rowSpeed.BackgroundTransparency = 1
rowSpeed.LayoutOrder     = 3
rowSpeed.Parent          = ContentFrame

local btnSpeed = createButton(rowSpeed, "BtnSpeedHack", 0, "Toggle Speed Hack", function() toggleSpeedHack() end)
btnSpeed.Size             = UDim2.new(0.5, 0, 1, 0)
btnSpeed.Position         = UDim2.new(0, 10, 0, 0)

-- TextBox untuk memasukkan nilai speed
local txtSpeedInput = Instance.new("TextBox")
txtSpeedInput.Size            = UDim2.new(0.25, 0, 1, 0)
txtSpeedInput.Position        = UDim2.new(0.55, 0, 0, 0)
txtSpeedInput.BackgroundColor3= COLOR_BUTTON
txtSpeedInput.Text            = tostring(DEFAULT_SPEED)
txtSpeedInput.PlaceholderText = "Speed"
txtSpeedInput.TextColor3      = COLOR_TEXT_OFF
txtSpeedInput.Font            = FONT_BUTTON
txtSpeedInput.TextScaled      = true
txtSpeedInput.Parent          = rowSpeed

lblSpeedStatus = createStatusLabel(rowSpeed, UDim2.new(0.82, 0, 0, 10))

-- Baris 3: Noclip
local rowNoclip = Instance.new("Frame")
rowNoclip.Size           = UDim2.new(1, 0, 0, 40)
rowNoclip.BackgroundTransparency = 1
rowNoclip.LayoutOrder    = 4
rowNoclip.Parent         = ContentFrame

local btnNoclip = createButton(rowNoclip, "BtnNoclip", 0, "Toggle Noclip", function() toggleNoclip() end)
btnNoclip.Size            = UDim2.new(0.6, 0, 1, 0)
btnNoclip.Position        = UDim2.new(0, 10, 0, 0)

lblNoclipStatus = createStatusLabel(rowNoclip, UDim2.new(0.7, 0, 0, 10))

-- Baris 4: Anti-AFK
local rowAntiAFK = Instance.new("Frame")
rowAntiAFK.Size          = UDim2.new(1, 0, 0, 40)
rowAntiAFK.BackgroundTransparency = 1
rowAntiAFK.LayoutOrder   = 5
rowAntiAFK.Parent        = ContentFrame

local btnAntiAFK = createButton(rowAntiAFK, "BtnAntiAFK", 0, "Toggle Anti-AFK", function() toggleAntiAFK() end)
btnAntiAFK.Size           = UDim2.new(0.6, 0, 1, 0)
btnAntiAFK.Position       = UDim2.new(0, 10, 0, 0)

lblAntiAFKStatus = createStatusLabel(rowAntiAFK, UDim2.new(0.7, 0, 0, 10))

-- Spacer Bawah
local SpacerBottom = Instance.new("Frame")
SpacerBottom.Size       = UDim2.new(1, 0, 1, -242)
SpacerBottom.BackgroundTransparency = 1
SpacerBottom.LayoutOrder = 6
SpacerBottom.Parent     = ContentFrame

--==========================================================--
--=== 5. PESAN LOG =============-----------------------------­
print("HXEL v2.0 Script Loaded Successfully!")
