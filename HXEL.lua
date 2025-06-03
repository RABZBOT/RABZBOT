-- Lengkapi dan perbaiki kode Rayfield: Infinite Jump otomatis di tab “test1”

-- Memuat library Rayfield dan membuat jendela utama
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "HXEL",
    LoadingTitle = "HXEL Menyala",
    LoadingSubtitle = "Delta Executor"
})

-- ─── TAB "Stats" ────────────────────────────────────────────────────────────
local StatsTab = Window:CreateTab("Stats", nil)
StatsTab:CreateSection("Data Statistik")

-- Buat tiga label: Koordinat, Money, dan Touch Player
local coordLabel = StatsTab:CreateLabel("Koordinat: Memuat...")
local moneyLabel = StatsTab:CreateLabel("Money: Memuat...")
local touchLabel = StatsTab:CreateLabel("Touch Player: Belum ada")

-- 1) Pembaruan real‐time Koordinat (setiap frame)
do
    local RunService = game:GetService("RunService")
    local Players    = game:GetService("Players")
    local player     = Players.LocalPlayer

    RunService.RenderStepped:Connect(function()
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local pos = char.HumanoidRootPart.Position
            local x, y, z = math.floor(pos.X), math.floor(pos.Y), math.floor(pos.Z)
            coordLabel:Set(string.format("Koordinat: %d, %d, %d", x, y, z))
        else
            coordLabel:Set("Koordinat: (Tidak tersedia)")
        end
    end)
end

-- 2) Pembaruan Money via event Changed
do
    local Players = game:GetService("Players")
    local player  = Players.LocalPlayer

    local function bindMoneyStat(stat)
        moneyLabel:Set("Money: " .. tostring(stat.Value))
        stat.Changed:Connect(function(newVal)
            moneyLabel:Set("Money: " .. tostring(newVal))
        end)
    end

    if player:FindFirstChild("leaderstats") then
        local ls = player.leaderstats
        if ls:FindFirstChild("Money") then
            bindMoneyStat(ls.Money)
        end
    end
    player.ChildAdded:Connect(function(child)
        if child.Name == "leaderstats" then
            wait(0.1)
            local ls = player.leaderstats
            if ls:FindFirstChild("Money") then
                bindMoneyStat(ls.Money)
            end
        end
    end)
end

-- 3) Deteksi “Touch Player” pada HumanoidRootPart
do
    local Players = game:GetService("Players")
    local player  = Players.LocalPlayer

    local function connectTouch(rootPart)
        touchLabel:Set("Touch Player: Belum ada")
        rootPart.Touched:Connect(function(hit)
            local otherChar = hit.Parent
            if otherChar and otherChar ~= player.Character then
                local otherPlayer = Players:GetPlayerFromCharacter(otherChar)
                if otherPlayer then
                    touchLabel:Set("Touch Player: " .. otherPlayer.Name)
                end
            end
        end)
    end

    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        connectTouch(player.Character.HumanoidRootPart)
    end
    player.CharacterAdded:Connect(function(char)
        char:WaitForChild("HumanoidRootPart")
        connectTouch(char.HumanoidRootPart)
    end)
end

-- ─── TAB "test1" ───────────────────────────────────────────────────────────
local Test1Tab = Window:CreateTab("test1", nil)
Test1Tab:CreateSection("Farm & Infinite Jump")

-- Variabel untuk Infinite Jump otomatis
local farmEnabled     = false
local customJumpPower = 50

-- Toggle untuk mengaktifkan Infinite Jump otomatis
local farmToggle = Test1Tab:CreateToggle({
    Name     = "Enable Infinite Jump",
    Flag     = "EnableFarm",
    Value    = false,
    Callback = function(value)
        farmEnabled = value
        local player = game:GetService("Players").LocalPlayer
        if not farmEnabled and player.Character then
            -- Kembalikan JumpPower ke default saat dinonaktifkan
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.JumpPower = 50
            end
        end
    end
})

-- Slider untuk mengatur tinggi lompatan (JumpPower)
local jumpPowerSlider = Test1Tab:CreateSlider({
    Name         = "Jump Height",
    SliderText   = "Power",
    Range        = {0, 200},
    Increment    = 1,
    Suffix       = "",
    CurrentValue = 50,
    Flag         = "JumpPower",
    Callback     = function(value)
        customJumpPower = value
        if farmEnabled then
            local player = game:GetService("Players").LocalPlayer
            if player.Character then
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.JumpPower = customJumpPower
                end
            end
        end
    end
})

-- Tombol “Reset Jump Power” untuk mengembalikan ke default (50)
Test1Tab:CreateButton({
    Name     = "Reset Jump Power",
    Callback = function()
        customJumpPower = 50
        jumpPowerSlider:Update(50)
        if farmEnabled then
            local player = game:GetService("Players").LocalPlayer
            if player.Character then
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.JumpPower = customJumpPower
                end
            end
        end
    end
})

-- Logika Infinite Jump otomatis (RunService.Heartbeat)
do
    local RunService = game:GetService("RunService")
    local Players    = game:GetService("Players")
    local player     = Players.LocalPlayer

    RunService.Heartbeat:Connect(function()
        if not farmEnabled then return end

        if player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                -- Terapkan custom JumpPower
                humanoid.JumpPower = customJumpPower
                -- Paksa Humanoid lompat terus‐menerus meski di udara
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
end

-- Contoh logika auto‐farm (opsional): menghancurkan objek “Coin” bila disentuh
do
    local Players = game:GetService("Players")
    local player  = Players.LocalPlayer

    local function onTouched(hit)
        if not farmEnabled then return end
        -- Jika bagian yang disentuh bernama “Coin” atau berada dalam Model yang bernama “Coin”
        if hit.Name == "Coin" or (hit.Parent and hit.Parent.Name == "Coin") then
            if hit.Parent:IsA("Model") then
                hit.Parent:Destroy()
            elseif hit:IsA("BasePart") then
                hit:Destroy()
            end
        end
    end

    local function connectFarm(rootPart)
        rootPart.Touched:Connect(onTouched)
    end

    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        connectFarm(player.Character.HumanoidRootPart)
    end
    player.CharacterAdded:Connect(function(char)
        char:WaitForChild("HumanoidRootPart")
        connectFarm(char.HumanoidRootPart)
    end)
end

-- Tambahkan di bagian pembuatan TAB “test2” agar berisi fitur teleport ketinggian
-- Asumsi: Anda sudah memuat Rayfield dan membuat Window sebelumnya

-- ─── TAB "test2" ───────────────────────────────────────────────────────────
local Test2Tab = Window:CreateTab("test2", nil)
Test2Tab:CreateSection("Teleport Ketinggian")

-- Tombol Teleport +1000Y
Test2Tab:CreateButton({
    Name = "Teleport +1000Y",
    Callback = function()
        local player = game:GetService("Players").LocalPlayer
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local root = player.Character.HumanoidRootPart
            local pos = root.Position
            root.CFrame = CFrame.new(pos.X, pos.Y + 1000, pos.Z)
        end
    end
})

-- Tombol Teleport +5000Y
Test2Tab:CreateButton({
    Name = "Teleport +5000Y",
    Callback = function()
        local player = game:GetService("Players").LocalPlayer
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local root = player.Character.HumanoidRootPart
            local pos = root.Position
            root.CFrame = CFrame.new(pos.X, pos.Y + 5000, pos.Z)
        end
    end
})

-- Tombol Teleport +10000Y
Test2Tab:CreateButton({
    Name = "Teleport +10000Y",
    Callback = function()
        local player = game:GetService("Players").LocalPlayer
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local root = player.Character.HumanoidRootPart
            local pos = root.Position
            root.CFrame = CFrame.new(pos.X, pos.Y + 10000, pos.Z)
        end
    end
})

-- Tombol Teleport +1000Z
Test2Tab:CreateButton({
    Name = "Teleport +1000Z",
    Callback = function()
        local player = game:GetService("Players").LocalPlayer
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local root = player.Character.HumanoidRootPart
            local pos = root.Position
            root.CFrame = CFrame.new(pos.X, pos.Y, pos.Z + 1000)
        end
    end
})

-- Tambahkan di bawah pembuatan tab “test2” untuk membuat tab “NoClip”

-- ─── TAB "NoClip" ────────────────────────────────────────────────────────────
local NoClipTab = Window:CreateTab("NoClip", nil)
NoClipTab:CreateSection("NoClip Controls")

-- State untuk NoClip
local noclipEnabled = false

-- Toggle untuk mengaktifkan atau menonaktifkan NoClip
NoClipTab:CreateToggle({
    Name     = "Enable NoClip",
    Flag     = "NoClipToggle",
    Value    = false,
    Callback = function(value)
        noclipEnabled = value
        if not noclipEnabled then
            -- Saat dinonaktifkan, kembalikan CanCollide ke true untuk semua bagian karakter
            local player = game:GetService("Players").LocalPlayer
            if player.Character then
                for _, part in ipairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end
    end
})

-- Loop NoClip: setiap frame, jika diaktifkan, matikan CanCollide semua bagian karakter
do
    local RunService = game:GetService("RunService")
    local Players    = game:GetService("Players")
    local player     = Players.LocalPlayer

    RunService.Stepped:Connect(function()
        if not noclipEnabled then return end
        if player.Character then
            for _, part in ipairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end

-- ─── TAB "Auto" (Perbaikan Auto‐Aim ke Kepala + LOS Check) ─────────────────
local AutoTab = Window:CreateTab("Auto", nil)
AutoTab:CreateSection("Auto Lock / Aim")

-- State untuk Auto Lock / Aim
local lockEnabled      = false
local lockRadius       = 50
local targetPartOption = "Head"  -- Pilihan: "Head" atau "Body"
local originalCamType  = nil     -- Akan menyimpan CameraType sebelum auto‐aim

-- Toggle untuk mengaktifkan atau mematikan Auto Lock/Aim
AutoTab:CreateToggle({
    Name     = "Enable Auto Aim",
    Flag     = "AutoAimToggle",
    Value    = false,
    Callback = function(value)
        lockEnabled = value

        local camera = workspace.CurrentCamera
        if lockEnabled then
            -- Simpan CameraType saat ini, lalu set jadi Scriptable
            originalCamType = camera.CameraType
            camera.CameraType = Enum.CameraType.Scriptable
        else
            -- Kembalikan CameraType ke semula
            camera.CameraType = originalCamType or Enum.CameraType.Custom
        end
    end
})

-- Slider untuk mengatur radius Auto Aim (dalam stud)
AutoTab:CreateSlider({
    Name         = "Aim Radius",
    SliderText   = "Studs",
    Range        = {0, 500},
    Increment    = 5,
    Suffix       = " studs",
    CurrentValue = lockRadius,
    Flag         = "AimRadius",
    Callback     = function(value)
        lockRadius = value
    end
})

-- Dropdown untuk memilih Part target: "Head" atau "Body"
AutoTab:CreateDropdown({
    Name     = "Target Part",
    Flag     = "TargetPartOption",
    Options  = {"Head", "Body"},
    Current  = targetPartOption,
    Multi    = false,
    Callback = function(option)
        targetPartOption = option
    end
})

-- Fungsi bantu: periksa apakah pemain dapat di‐aim
-- Kriteria:
-- 1) Bukan teman (friend) atau satu Team
-- 2) Tidak memiliki ForceField (immune)
-- 3) Memiliki Humanoid dan Health > 0
local function canBeTargeted(localPlayer, otherPlayer)
    if not otherPlayer.Character then
        return false
    end

    -- 1) Cek friend / team
    if localPlayer:IsFriendsWith(otherPlayer.UserId) then
        return false
    end
    if localPlayer.Team and otherPlayer.Team and localPlayer.Team == otherPlayer.Team then
        return false
    end

    local otherChar = otherPlayer.Character

    -- 2) Cek ForceField
    if otherChar:FindFirstChild("ForceField") then
        return false
    end

    -- 3) Cek Humanoid dan Health > 0
    local humanoid = otherChar:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return false
    end

    return true
end

-- Fungsi tambahan: periksa line‐of‐sight (LOS) antara kamera lokal dengan targetPart
-- Mengembalikan true jika ray menuju targetPart tidak terhalang objek lain
local function hasLineOfSight(localPlayer, targetPart)
    if not targetPart then
        return false
    end

    local camera = workspace.CurrentCamera
    local origin = camera.CFrame.Position
    local direction = (targetPart.Position - origin)

    -- Siapkan RaycastParams untuk mengabaikan karakter pemain sendiri
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = { localPlayer.Character }
    rayParams.IgnoreWater = true

    local rayResult = workspace:Raycast(origin, direction, rayParams)
    if rayResult and rayResult.Instance then
        -- Jika objek pertama yang kena adalah bagian dari karakter target, maka LOS ada
        if rayResult.Instance:IsDescendantOf(targetPart.Parent) then
            return true
        else
            return false
        end
    end

    -- Jika rayResult nil (tidak menabrak apa‐apa) maka LOS dianggap terhalang
    return false
end

-- Fungsi menemukan pemain terdekat dalam radius, dengan pengecekan canBeTargeted() + LOS
local function findNearestTarget()
    local Players     = game:GetService("Players")
    local localPlayer = Players.LocalPlayer
    if not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return nil
    end

    local rootPos       = localPlayer.Character.HumanoidRootPart.Position
    local nearestDist   = lockRadius
    local nearestPlayer = nil

    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= localPlayer and other.Character and other.Character:FindFirstChild("HumanoidRootPart") then
            if canBeTargeted(localPlayer, other) then
                -- Tentukan targetPart (Head atau Body)
                local targetPart = nil
                if targetPartOption == "Head" then
                    targetPart = other.Character:FindFirstChild("Head")
                else
                    -- Gunakan HumanoidRootPart sebagai "Body"
                    targetPart = other.Character:FindFirstChild("HumanoidRootPart")
                end

                if targetPart then
                    -- Cek jarak
                    local otherPos = other.Character.HumanoidRootPart.Position
                    local dist = (rootPos - otherPos).Magnitude
                    if dist <= nearestDist then
                        -- Cek line‐of‐sight
                        if hasLineOfSight(localPlayer, targetPart) then
                            nearestDist   = dist
                            nearestPlayer = other
                        end
                    end
                end
            end
        end
    end

    return nearestPlayer
end

-- Loop RenderStepped untuk auto‐aim saat aktif
game:GetService("RunService").RenderStepped:Connect(function()
    if not lockEnabled then
        return
    end

    local camera      = workspace.CurrentCamera
    local localPlayer = game:GetService("Players").LocalPlayer
    local targetPlayer = findNearestTarget()

    if targetPlayer and targetPlayer.Character then
        -- Ambil part target yang sudah dipilih (Head/Body)
        local partToAim = nil
        if targetPartOption == "Head" then
            partToAim = targetPlayer.Character:FindFirstChild("Head")
        else
            partToAim = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        end

        if partToAim then
            -- Gerakkan kamera ke arah targetPart (lock pada posisi target)
            camera.CFrame = CFrame.new(camera.CFrame.Position, partToAim.Position)
        end
    end
end)

-- ─── TAB "Player" ───────────────────────────────────────────────────────────
local PlayerTab = Window:CreateTab("Player", nil)
PlayerTab:CreateSection("Player Settings")

-- Status invincible (Max HP)
local invincibleEnabled = false

-- Fungsi untuk mengunci HP ke nilai maksimum
local function applyInvincibility(humanoid)
    if not humanoid or humanoid.Health <= 0 then return end
    -- Simpan nilai MaxHealth
    local maxH = humanoid.MaxHealth

    -- Set Health selalu ke MaxHealth setiap frame
    local connection
    connection = game:GetService("RunService").RenderStepped:Connect(function()
        if invincibleEnabled and humanoid.Health < maxH then
            humanoid.Health = maxH
        end
        if not invincibleEnabled and connection then
            connection:Disconnect()
        end
    end)
end

-- Callback ketika karakter respawn / loaded
local function onCharacterAdded(char)
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        -- Pastikan Health di‐set ulang ke MaxHealth segera
        if invincibleEnabled then
            humanoid.Health = humanoid.MaxHealth
        end
        applyInvincibility(humanoid)
    end
end

-- Bind ketika pemain pertama kali join (jika sudah ada character)
local player = game:GetService("Players").LocalPlayer
if player.Character then
    onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

-- Toggle untuk mengaktifkan/mematikan Max HP
PlayerTab:CreateToggle({
    Name     = "Enable Max HP (Invincible)",
    Flag     = "MaxHPToggle",
    Value    = false,
    Callback = function(value)
        invincibleEnabled = value

        -- Jika diaktifkan, set Humanoid.Health ke Max sekarang juga
        local char = player.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                if invincibleEnabled then
                    humanoid.Health = humanoid.MaxHealth
                    -- Pastikan juga MaxHealth ditinggikan jika perlu (opsional)
                    -- humanoid.MaxHealth = math.huge
                end
                -- Mulai loop applyInvincibility di applyInvincibility()
                applyInvincibility(humanoid)
            end
        end

        -- Tampilkan notifikasi kecil
        if invincibleEnabled then
            PlayerTab:CreateNotification({
                Title   = "Max HP Aktif",
                Content = "Player sekarang tidak akan kehilangan HP.",
                Duration= 3
            })
        else
            PlayerTab:CreateNotification({
                Title   = "Max HP Dimatikan",
                Content = "Player kembali bisa menerima damage.",
                Duration= 3
            })
        end
    end
})
