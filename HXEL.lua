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

-- ─── TAB "Auto" (Ditingkatkan Lagi) ────────────────────────────────────────
local AutoTab = Window:CreateTab("Auto", nil)
AutoTab:CreateSection("Auto Lock")

-- State untuk Auto Lock
local lockEnabled = false
local lockRadius  = 50

-- Toggle untuk mengaktifkan atau mematikan Auto Lock
AutoTab:CreateToggle({
    Name     = "Enable Auto Lock",
    Flag     = "AutoLockToggle",
    Value    = false,
    Callback = function(value)
        lockEnabled = value
    end
})

-- Slider untuk mengatur radius Auto Lock (dalam stud)
AutoTab:CreateSlider({
    Name         = "Lock Radius",
    SliderText   = "Studs",
    Range        = {0, 500},
    Increment    = 5,
    Suffix       = " studs",
    CurrentValue = 50,
    Flag         = "LockRadius",
    Callback     = function(value)
        lockRadius = value
    end
})

-- Fungsi bantu untuk memeriksa apakah target bisa di-lock:
-- 1) Bukan teman (friend)
-- 2) Tidak memiliki ForceField (immune)
-- 3) Memiliki Humanoid dan Health > 0 (tidak mati atau nol darah)
local function canBeTargeted(localPlayer, otherPlayer)
    -- Pastikan karakter ada
    local otherChar = otherPlayer.Character
    if not otherChar then return false end

    -- 1) Cek friend
    if localPlayer:IsFriendsWith(otherPlayer.UserId) then
        return false
    end

    -- 2) Cek ForceField
    if otherChar:FindFirstChild("ForceField") then
        return false
    end

    -- 3) Cek Humanoid dan Health
    local humanoid = otherChar:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return false
    end

    return true
end

-- Fungsi untuk menemukan pemain terdekat (selain diri sendiri) dalam radius,
-- dengan pengecekan canBeTargeted()
local function findNearestTarget()
    local Players     = game:GetService("Players")
    local localPlayer = Players.LocalPlayer
    if not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return nil
    end

    local rootPos = localPlayer.Character.HumanoidRootPart.Position
    local nearestDist = lockRadius
    local nearestPlayer = nil

    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= localPlayer and other.Character and other.Character:FindFirstChild("HumanoidRootPart") then
            if canBeTargeted(localPlayer, other) then
                local otherPos = other.Character.HumanoidRootPart.Position
                local dist = (rootPos - otherPos).Magnitude
                if dist <= nearestDist then
                    nearestDist = dist
                    nearestPlayer = other
                end
            end
        end
    end

    return nearestPlayer
end

-- Loop RenderStepped untuk mengunci kamera ke target saat Auto Lock aktif
do
    local RunService = game:GetService("RunService")
    local Players    = game:GetService("Players")
    local player     = Players.LocalPlayer
    local camera     = workspace.CurrentCamera

    RunService.RenderStepped:Connect(function()
        if not lockEnabled then
            return
        end

        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and camera then
            local target = findNearestTarget()
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                local targetHum = target.Character:FindFirstChildOfClass("Humanoid")
                if targetHum and targetHum.Health > 0 then
                    local targetPos = target.Character.HumanoidRootPart.Position
                    local camPos    = camera.CFrame.Position
                    camera.CFrame   = CFrame.new(camPos, targetPos)
                end
            end
        end
    end)
end
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and camera then
            local target = findNearestTarget()
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                local targetPos = target.Character.HumanoidRootPart.Position
                -- Tetap di posisi kamera saat ini, tetapi arahkan ke target
                local camPos = camera.CFrame.Position
                camera.CFrame = CFrame.new(camPos, targetPos)
            end
        end
    end)
end
