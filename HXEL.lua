-- Memuat library Rayfield dan membuat jendela utama
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "HXEL", 
    LoadingTitle = "HXEL Menyala", 
    LoadingSubtitle = "Delta Executor"
})

-- Membuat tab "Stats"
local StatsTab = Window:CreateTab("Stats", nil)
StatsTab:CreateSection("Data Statistik")

-- Ganti CreateParagraph dengan dua CreateLabel untuk koordinat dan money
local coordLabel = StatsTab:CreateLabel({
    Name  = "Koordinat: ",
    Value = "Memuat..."
})
local moneyLabel = StatsTab:CreateLabel({
    Name  = "Money: ",
    Value = "Memuat..."
})

-- Loop untuk mengupdate koordinat dan money setiap detik
spawn(function()
    local Players   = game:GetService("Players")
    local player    = Players.LocalPlayer

    while true do
        -- Update Koordinat
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local pos = char.HumanoidRootPart.Position
            -- Bulatkan ke integer agar tampilannya lebih rapi
            local x, y, z = math.floor(pos.X), math.floor(pos.Y), math.floor(pos.Z)
            coordLabel:Set("Koordinat: " .. x .. ", " .. y .. ", " .. z)
        else
            coordLabel:Set("Koordinat: (Tidak tersedia)")
        end

        -- Update Money (mencari leaderstat bernama "Money")
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            local cashStat = leaderstats:FindFirstChild("Money")
            if cashStat then
                moneyLabel:Set("Money: " .. cashStat.Value)
            else
                moneyLabel:Set("Money: (Leaderstat 'Money' tidak ditemukan)")
            end
        else
            moneyLabel:Set("Money: (Leaderstats tidak tersedia)")
        end

        wait(1)
    end
end)

-- Membuat tab "test1"
local Test1Tab = Window:CreateTab("test1", nil)
Test1Tab:CreateSection("Pengaturan Test 1")
Test1Tab:CreateParagraph({
    Title   = "Info Test1", 
    Content = "Konten test1 di sini."
})

-- Membuat tab "test2"
local Test2Tab = Window:CreateTab("test2", nil)
Test2Tab:CreateSection("Pengaturan Test 2")
Test2Tab:CreateParagraph({
    Title   = "Info Test2", 
    Content = "Konten test2 di sini."
})
