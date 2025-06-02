-- Lengkapi dan perbaiki kode Stats di Rayfield agar koordinat langsung ter‐update
-- tanpa jeda 1 detik, serta Money dan Touch Player tetap berfungsi.

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
-- Note: Untuk Rayfield v2, CreateLabel() menerima satu string: "<Nama>: <Value>"
local coordLabel = StatsTab:CreateLabel("Koordinat: Memuat...")
local moneyLabel = StatsTab:CreateLabel("Money: Memuat...")
local touchLabel = StatsTab:CreateLabel("Touch Player: Belum ada")

-- 1) Pembaruan real‐time Koordinat (setiap frame)
do
    local RunService = game:GetService("RunService")
    local Players    = game:GetService("Players")
    local player     = Players.LocalPlayer

    -- Setiap frame, cek Character dan update label
    RunService.RenderStepped:Connect(function()
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local pos = char.HumanoidRootPart.Position
            -- Bulatkan untuk tampilan yang lebih rapi
            local x, y, z = math.floor(pos.X), math.floor(pos.Y), math.floor(pos.Z)
            coordLabel:Set(string.format("Koordinat: %d, %d, %d", x, y, z))
        else
            coordLabel:Set("Koordinat: (Tidak tersedia)")
        end
    end)
end

-- 2) Pembaruan Money via event Changed (menanggapi perubahan secara instan)
do
    local Players = game:GetService("Players")
    local player  = Players.LocalPlayer

    local function bindMoneyStat(stat)
        -- Jika 'Money' sudah ditemukan, langsung tampilkan dan sambungkan Changed
        moneyLabel:Set("Money: " .. tostring(stat.Value))
        stat.Changed:Connect(function(newVal)
            moneyLabel:Set("Money: " .. tostring(newVal))
        end)
    end

    -- Jika sudah ada leaderstats saat script dijalankan
    if player:FindFirstChild("leaderstats") then
        local ls = player.leaderstats
        if ls:FindFirstChild("Money") then
            bindMoneyStat(ls.Money)
        end
    end

    -- Ketika leaderstats muncul (respawn atau baru spawn)
    player.ChildAdded:Connect(function(child)
        if child.Name == "leaderstats" then
            wait(0.1)  -- biarkan nilai ter‐initialize
            local ls = player.leaderstats
            if ls:FindFirstChild("Money") then
                bindMoneyStat(ls.Money)
            end
        end
    end)
end

-- 3) Deteksi “Touch Player” real‐time pada HumanoidRootPart
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

    -- Bila Character sudah ada sejak awal
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        connectTouch(player.Character.HumanoidRootPart)
    end

    -- Saat respawn, sambungkan kembali
    player.CharacterAdded:Connect(function(char)
        char:WaitForChild("HumanoidRootPart")
        connectTouch(char.HumanoidRootPart)
    end)
end

-- ─── TAB "test1" ───────────────────────────────────────────────────────────
local Test1Tab = Window:CreateTab("test1", nil)
Test1Tab:CreateSection("Pengaturan Test 1")
Test1Tab:CreateParagraph({
    Title   = "Info Test1",
    Content = "Konten test1 di sini."
})

-- ─── TAB "test2" ───────────────────────────────────────────────────────────
local Test2Tab = Window:CreateTab("test2", nil)
Test2Tab:CreateSection("Pengaturan Test 2")
Test2Tab:CreateParagraph({
    Title   = "Info Test2",
    Content = "Konten test2 di sini."
})
