--[[ 
    fit/unljmp.lua
    Modular Unlimited Jump untuk HXEL v2.0
    Di‐load via loadstring dari main script.
--]]

local module = {}

-- Services
local Players     = game:GetService("Players")
local UserInput   = game:GetService("UserInputService")
local RunService  = game:GetService("RunService")

-- References (akan di‐update otomatis saat respawn)
local player       = Players.LocalPlayer
local character    = player.Character or player.CharacterAdded:Wait()
local humanoid     = character:WaitForChild("Humanoid")

-- Flag internal
local _enabled        = false
local _connection     = nil
local _respawnListener = nil

-- Debounce supaya tidak men‐spam ChangeState
local DEBOUNCE_TIME = 0.1
local lastJumpTime  = 0

-- Function untuk update reference saat respawn
local function onCharacterAdded(char)
    character = char
    humanoid  = character:WaitForChild("Humanoid")
    -- Tidak langsung membuat koneksi di sini,
    -- tapi jika fitur _enabled sudah true, buat ulang listener:
    if _enabled then
        module.Enable()
    end
end

-- Inisialisasi listener respawn
_respawnListener = player.CharacterAdded:Connect(onCharacterAdded)

-- Fungsi utama untuk _listen_ JumpRequest
local function onJumpRequest()
    if not _enabled or not humanoid or not humanoid.Parent then
        return
    end
    local now = tick()
    if now - lastJumpTime >= DEBOUNCE_TIME then
        -- Ubah state ke Jumping
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        lastJumpTime = now
    end
end

-- Enable unlimited jump
function module.Enable()
    if _enabled then return end
    if not humanoid or not humanoid.Parent then
        -- Jika sudah dipanggil sebelum karakter muncul, tunggu karakter
        character = player.Character or player.CharacterAdded:Wait()
        humanoid  = character:WaitForChild("Humanoid")
    end
    _connection = UserInput.JumpRequest:Connect(onJumpRequest)
    _enabled = true
end

-- Disable unlimited jump
function module.Disable()
    if not _enabled then return end
    if _connection then
        _connection:Disconnect()
        _connection = nil
    end
    _enabled = false
end

-- Cleanup sebelum modul di‐destroy (jika perlu)
function module.Destroy()
    module.Disable()
    if _respawnListener then
        _respawnListener:Disconnect()
        _respawnListener = nil
    end
end

return module
