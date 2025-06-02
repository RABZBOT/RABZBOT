--[[
  fit/unljmp.lua
  Modular Unlimited Jump (Auto-Jump) untuk HXEL v2.2
  – Menambahkan kemampuan auto-jump terus-menerus
  – Kecepatan (jumps per detik) dapat di-set melalui module.SetSpeed()
  – Otomatis reconnect saat karakter respawn

  Cara pakai di main script:
    local unljmp = loadstring(game:HttpGet(
      "https://raw.githubusercontent.com/RABZBOT/RABZBOT/main/fit/unljmp.lua",
      true
    ))()
    -- (1) Set kecepatan auto-jump (opsional, default: 5 jumps per detik)
    unljmp.SetSpeed(8)
    -- (2) Aktifkan auto-jump
    unljmp.Enable()
    -- (3) Matikan auto-jump
    unljmp.Disable()
    -- (4) Saat script di-unload, panggil Destroy()
    unljmp.Destroy()
--]]

local module = {}

-- Services
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

-- References karakter (akan di-update otomatis saat respawn)
local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid  = character:WaitForChild("Humanoid")

-- Internal flag dan koneksi
local _enabled       = false
local _heartbeatConn = nil
local _respawnConn   = nil

-- Kecepatan auto-jump (jumps per detik)
-- Default: 5 jumps per detik (interval 0.2 detik)
local jumpSpeed    = 5
local jumpInterval = 1 / jumpSpeed

-- Accumulator untuk menghitung waktu antara jump
local timeAccumulator = 0

--------------------------------------------------------------------------------
-- Fungsi internal: update referensi humanoid saat karakter respawn
--------------------------------------------------------------------------------
local function onCharacterAdded(char)
    character = char
    humanoid  = character:WaitForChild("Humanoid")

    -- Jika fitur sedang aktif, restart loop Heartbeat
    if _enabled then
        -- Disconnect loop lama jika ada
        if _heartbeatConn then
            _heartbeatConn:Disconnect()
            _heartbeatConn = nil
        end
        -- Reset accumulator
        timeAccumulator = 0
        -- Buat koneksi baru
        _heartbeatConn = RunService.Heartbeat:Connect(function(dt)
            if not _enabled or not humanoid or not humanoid.Parent then
                return
            end
            timeAccumulator = timeAccumulator + dt
            if timeAccumulator >= jumpInterval then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                timeAccumulator = timeAccumulator - jumpInterval
            end
        end)
    end
end

-- Pasang listener respawn pertama kali
_respawnConn = player.CharacterAdded:Connect(onCharacterAdded)

--------------------------------------------------------------------------------
-- Publik: SetSpeed(n)
-- Mengubah kecepatan auto-jump dalam "jumps per detik".
-- Contoh: SetSpeed(10) → interval 0.1 detik
-- Jika nilai <= 0 atau non-number, fungsi akan diabaikan.
--------------------------------------------------------------------------------
function module.SetSpeed(n)
    if type(n) ~= "number" or n <= 0 then
        warn("[unljmp] SetSpeed(): nilai harus > 0 (number). Ditemukan:", n)
        return
    end
    jumpSpeed    = n
    jumpInterval = 1 / jumpSpeed
end

--------------------------------------------------------------------------------
-- Publik: Enable()
-- Mengaktifkan auto-jump. Jika sudah aktif, panggilan berikutnya diabaikan.
--------------------------------------------------------------------------------
function module.Enable()
    if _enabled then return end

    -- Pastikan humanoid valid
    if not humanoid or not humanoid.Parent then
        character = player.Character or player.CharacterAdded:Wait()
        humanoid  = character:WaitForChild("Humanoid")
    end

    -- Reset accumulator saat Enable
    timeAccumulator = 0

    -- Buat koneksi Heartbeat loop
    _heartbeatConn = RunService.Heartbeat:Connect(function(dt)
        if not _enabled or not humanoid or not humanoid.Parent then
            return
        end
        timeAccumulator = timeAccumulator + dt
        if timeAccumulator >= jumpInterval then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            timeAccumulator = timeAccumulator - jumpInterval
        end
    end)

    _enabled = true
end

--------------------------------------------------------------------------------
-- Publik: Disable()
-- Mematikan auto-jump. Jika belum aktif, panggilan diabaikan.
--------------------------------------------------------------------------------
function module.Disable()
    if not _enabled then return end
    if _heartbeatConn then
        _heartbeatConn:Disconnect()
        _heartbeatConn = nil
    end
    _enabled = false
end

--------------------------------------------------------------------------------
-- Publik: Destroy()
-- Membersihkan semua koneksi (Heartbeat & Respawn listener) sebelum modul di-unload.
--------------------------------------------------------------------------------
function module.Destroy()
    module.Disable()
    if _respawnConn then
        _respawnConn:Disconnect()
        _respawnConn = nil
    end
end

return module
