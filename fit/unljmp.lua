-- fit/unljmp.lua
-- Modular Unlimited Jump (Auto-Jump) untuk HXEL v2.2
-- Fungsionalitas:
--   • Enable()   → Mulai auto-jump sesuai kecepatan (jumps per detik)
--   • Disable()  → Hentikan auto-jump
--   • SetSpeed(n)→ Ubah kecepatan (jumps per detik), n > 0
--   • Destroy()  → Bersihkan koneksi sebelum modul di-unload

local module = {}

-- Services
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Referensi karakter & humanoid akan di-update saat respawn
local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid  = character:WaitForChild("Humanoid")

-- Internal state
local _enabled       = false
local _heartbeatConn = nil
local _respawnConn   = nil

-- Kecepatan auto-jump (jumps per detik), default 5
local jumpSpeed    = 5
local jumpInterval = 1 / jumpSpeed

-- Akumulator waktu untuk Heartbeat loop
local timeAccumulator = 0

-- Fungsi internal: update referensi humanoid saat respawn
local function onCharacterAdded(char)
    character = char
    humanoid  = character:WaitForChild("Humanoid")

    if _enabled then
        -- Reset akumulator dan sambung ulang Heartbeat
        if _heartbeatConn then
            _heartbeatConn:Disconnect()
            _heartbeatConn = nil
        end
        timeAccumulator = 0
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

-- Pasang listener respawn
_respawnConn = player.CharacterAdded:Connect(onCharacterAdded)

-- Publik: SetSpeed(n)
-- n harus number > 0
function module.SetSpeed(n)
    if type(n) ~= "number" or n <= 0 then
        warn("[unljmp] SetSpeed(): nilai harus > 0")
        return
    end
    jumpSpeed    = n
    jumpInterval = 1 / jumpSpeed
end

-- Publik: Enable()
function module.Enable()
    if _enabled then
        return
    end

    -- Pastikan humanoid valid
    if not humanoid or not humanoid.Parent then
        character = player.Character or player.CharacterAdded:Wait()
        humanoid  = character:WaitForChild("Humanoid")
    end

    timeAccumulator = 0
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

-- Publik: Disable()
function module.Disable()
    if not _enabled then
        return
    end
    if _heartbeatConn then
        _heartbeatConn:Disconnect()
        _heartbeatConn = nil
    end
    _enabled = false
end

-- Publik: Destroy()
-- Bersihkan semua koneksi
function module.Destroy()
    module.Disable()
    if _respawnConn then
        _respawnConn:Disconnect()
        _respawnConn = nil
    end
end

return module
