-- Script untuk tab Stats - fit/stat.lua

-- Pastikan library GUI sudah tersedia
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- Cek apakah Rayfield tersedia
if not Rayfield then
    warn("Rayfield GUI tidak ditemukan. Pastikan Anda memuat HXEL.lua terlebih dahulu.")
    return
end

-- Buat Tab baru untuk Stats jika belum ada
local StatsTab = Window and Window:CreateTab("Stats", 4483362458) or Rayfield:CreateWindow({Name = "HXEL"}):CreateTab("Stats", 4483362458)
StatsTab:CreateSection("Statistik Pemain")

-- Label koordinat
local coordLabel = StatsTab:CreateLabel("Koordinat: Memuat...")

-- Update koordinat secara real-time
RunService.RenderStepped:Connect(function()
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local pos = player.Character.HumanoidRootPart.Position
        coordLabel:Set(string.format("Koordinat: (%.1f, %.1f, %.1f)", pos.X, pos.Y, pos.Z))
    end
end)
