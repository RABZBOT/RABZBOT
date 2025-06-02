-- Memuat layanan Roblox
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- Muat library Rayfield dari URL
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()

-- Buat jendela utama HXEL
local Window = Rayfield:CreateWindow({
    Name = "HXEL",
    LoadingTitle = "HXEL Memuat...",
    LoadingSubtitle = "HXEL GUI",
    ConfigurationSaving = {
        Enabled = true,
        FileName = "HXEL_Config"
    },
    Discord = {
        Enabled = false
    },
    KeySystem = false
})

-- Tab: Stats
local StatsTab = Window:CreateTab("Stats", 4483362458)
StatsTab:CreateSection("Informasi Pemain")

-- Label untuk koordinat pemain
local posLabel = StatsTab:CreateLabel("Koordinat: (0, 0, 0)", 4483362458, Color3.fromRGB(255,255,255), false)

-- Tombol minimize untuk menyembunyikan GUI
StatsTab:CreateButton({
    Name = "-",
    Callback = function()
        Rayfield:SetVisibility(false)  -- Sembunyikan GUI utama:contentReference[oaicite:6]{index=6}
        screenGui.Enabled = true       -- Tampilkan tombol HXEL
    end
})

-- Perbarui koordinat secara real-time
RunService.RenderStepped:Connect(function()
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local pos = player.Character.HumanoidRootPart.Position
        posLabel:Set(string.format("Koordinat: (%.1f, %.1f, %.1f)", pos.X, pos.Y, pos.Z))
    end
end)

-- Tab: test1 (placeholder)
local Test1Tab = Window:CreateTab("test1", 4483362458)
Test1Tab:CreateSection("Placeholder")
Test1Tab:CreateButton({
    Name = "Load script test1",
    Callback = function()
        loadstring(game:HttpGet("https://example.com/script_test1.lua", true))()
    end
})

-- Tab: test2 (placeholder)
local Test2Tab = Window:CreateTab("test2", 4483362458)
Test2Tab:CreateSection("Placeholder")
Test2Tab:CreateButton({
    Name = "Load script test2",
    Callback = function()
        loadstring(game:HttpGet("https://example.com/script_test2.lua", true))()
    end
})

-- Buat tombol HXEL (maximize) sebagai pop-up ketika GUI diminimize
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HXEL_ButtonGui"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.Enabled = false

local hxelButton = Instance.new("TextButton")
hxelButton.Size = UDim2.new(0, 100, 0, 100)
hxelButton.Position = UDim2.new(0, 10, 0, 10)
hxelButton.Text = "HXEL"
hxelButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
hxelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
hxelButton.TextScaled = true
hxelButton.Parent = screenGui

-- Ubah tombol menjadi bentuk lingkaran
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 50)
corner.Parent = hxelButton

-- Klik untuk menampilkan kembali GUI
hxelButton.MouseButton1Click:Connect(function()
    Rayfield:SetVisibility(true)
    screenGui.Enabled = false
end)
