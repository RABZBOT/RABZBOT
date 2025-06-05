-- ===============================================
-- MEMUAT RAYFIELD & MEMBUAT JENDELA UTAMA
-- ===============================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "HXEL",
    LoadingTitle = "HXEL Menyala",
    LoadingSubtitle = "Delta Executor"
})

-- ===============================================
-- TAB "Stats"
-- ===============================================
local StatsTab = Window:CreateTab("Stats", nil)
StatsTab:CreateSection("Data Statistik")

-- 1) Label Koordinat
local coordLabel = StatsTab:CreateLabel("Koordinat: Memuat...")

-- 2) Label Money
local moneyLabel = StatsTab:CreateLabel("Money: Memuat...")

-- 3) Label Touch Player
local touchLabel = StatsTab:CreateLabel("Touch Player: Belum ada")

-- Update koordinat setiap frame
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

-- Update money via leaderstats Changed
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
            if ls and ls:FindFirstChild("Money") then
                bindMoneyStat(ls.Money)
            end
        end
    end)
end

-- Deteksi "Touch Player" pada HumanoidRootPart
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

-- ===============================================
-- TAB "test1"  (Infinite Jump & Auto-Farm)
-- ===============================================
local Test1Tab = Window:CreateTab("test1", nil)
Test1Tab:CreateSection("Farm & Infinite Jump")

local farmEnabled     = false
local customJumpPower = 50

-- Toggle: Enable Infinite Jump
Test1Tab:CreateToggle({
    Name     = "Enable Infinite Jump",
    CurrentValue = false,
    Callback = function(value)
        farmEnabled = value
        local player = game:GetService("Players").LocalPlayer
        if not farmEnabled and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.JumpPower = 50
            end
        end
    end
})

-- Slider: Atur JumpPower (0-200)
local jumpPowerSlider = Test1Tab:CreateSlider({
    Name         = "Jump Height",
    Range        = {0, 200},
    Increment    = 1,
    Suffix       = "",
    CurrentValue = 50,
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

-- Button: Reset JumpPower ke 50
Test1Tab:CreateButton({
    Name     = "Reset Jump Power",
    Callback = function()
        customJumpPower = 50
        jumpPowerSlider:Set(50)
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

-- Infinite Jump terus-menerus (Heartbeat)
do
    local RunService = game:GetService("RunService")
    local Players    = game:GetService("Players")
    local player     = Players.LocalPlayer

    RunService.Heartbeat:Connect(function()
        if not farmEnabled then return end
        if player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.JumpPower = customJumpPower
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
end

-- Auto-Farm (hancurkan objek bernama "Coin" saat disentuh)
do
    local Players = game:GetService("Players")
    local player  = Players.LocalPlayer

    local function onTouched(hit)
        if not farmEnabled then return end
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

-- ===============================================
-- TAB "test2"  (Teleport Ketinggian)
-- ===============================================
local Test2Tab = Window:CreateTab("test2", nil)
Test2Tab:CreateSection("Teleport Ketinggian")

-- Teleport +1000Y
Test2Tab:CreateButton({
    Name = "Teleport +1000Y",
    Callback = function()
        local player = game:GetService("Players").LocalPlayer
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local root = player.Character.HumanoidRootPart
            local pos  = root.Position
            root.CFrame = CFrame.new(pos.X, pos.Y + 1000, pos.Z)
        end
    end
})

-- Teleport +5000Y
Test2Tab:CreateButton({
    Name = "Teleport +5000Y",
    Callback = function()
        local player = game:GetService("Players").LocalPlayer
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local root = player.Character.HumanoidRootPart
            local pos  = root.Position
            root.CFrame = CFrame.new(pos.X, pos.Y + 5000, pos.Z)
        end
    end
})

-- Teleport +10000Y
Test2Tab:CreateButton({
    Name = "Teleport +10000Y",
    Callback = function()
        local player = game:GetService("Players").LocalPlayer
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local root = player.Character.HumanoidRootPart
            local pos  = root.Position
            root.CFrame = CFrame.new(pos.X, pos.Y + 10000, pos.Z)
        end
    end
})

-- Teleport +1000Z
Test2Tab:CreateButton({
    Name = "Teleport +1000Z",
    Callback = function()
        local player = game:GetService("Players").LocalPlayer
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local root = player.Character.HumanoidRootPart
            local pos  = root.Position
            root.CFrame = CFrame.new(pos.X, pos.Y, pos.Z + 1000)
        end
    end
})

-- ===============================================
-- TAB "NoClip"
-- ===============================================
local NoClipTab = Window:CreateTab("NoClip", nil)
NoClipTab:CreateSection("NoClip Controls")

local noclipEnabled = false

-- Toggle: Enable / Disable NoClip
NoClipTab:CreateToggle({
    Name     = "Enable NoClip",
    CurrentValue = false,
    Callback = function(value)
        noclipEnabled = value
        if not noclipEnabled then
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

-- Setiap frame, matikan CanCollide semua part karakter jika noclipEnabled == true
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

-- ===============================================
-- TAB "Auto"  (Auto-Aim Lengkap dengan Fitur LOS)
-- ===============================================
local AutoTab = Window:CreateTab("Auto", nil)
AutoTab:CreateSection("Auto Lock / Aim")

local lockEnabled        = false
local maxDistance        = 50      -- Jarak maksimal default (50 studs)
local targetPartOption   = "Head"  -- Pilihan default: "Head" atau "Body"
local checkLOS           = true    -- Pengecekan Line of Sight default: true
local originalCamType    = nil     -- Simpan CameraType sebelum Auto Aim

-- Parameter tambahan:
local smoothSpeed        = 0.15   -- (0 < smoothSpeed < 1)
local predictionFactor   = 0.1    -- Prediksi posisi target (velocity * predictionFactor)
local snapAngleThreshold = 0.01   -- Batas sudut (radian) untuk "snap" langsung

-- 1) Toggle: Enable / Disable Auto Aim
AutoTab:CreateToggle({
    Name     = "Enable Auto Aim",
    CurrentValue = false,
    Callback = function(value)
        lockEnabled = value
        local camera = workspace.CurrentCamera
        if lockEnabled then
            originalCamType = camera.CameraType
            camera.CameraType = Enum.CameraType.Scriptable
        else
            camera.CameraType = originalCamType or Enum.CameraType.Custom
        end
    end
})

-- 2) Toggle: Line of Sight Check
AutoTab:CreateToggle({
    Name     = "Line of Sight Check",
    CurrentValue = checkLOS,
    Callback = function(value)
        checkLOS = value
    end
})

-- 3) Textbox: Max Distance (stud)
local maxDistanceBox = AutoTab:CreateInput({
    Name = "Max Distance",
    PlaceholderText = tostring(maxDistance),
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        local num = tonumber(text)
        if num and num >= 0 then
            maxDistance = num
            maxDistanceBox:Set(tostring(num))
        else
            maxDistanceBox:Set(tostring(maxDistance))
        end
    end,
})

-- 4) Dropdown: Pilih "Head" atau "Body"
AutoTab:CreateDropdown({
    Name = "Target Part",
    Options = {"Head", "Body"},
    CurrentOption = targetPartOption,
    Callback = function(option)
        targetPartOption = option
    end
})

-- 5) Slider: Smooth Speed (0.00 - 1.00)
AutoTab:CreateSlider({
    Name = "Smooth Speed",
    Range = {0, 1},
    Increment = 0.01,
    Suffix = "",
    CurrentValue = smoothSpeed,
    Callback = function(value)
        smoothSpeed = value
    end
})

-- 6) Slider: Prediction Factor (0.00 - 1.00)
AutoTab:CreateSlider({
    Name = "Prediction Factor",
    Range = {0, 1},
    Increment = 0.01,
    Suffix = "",
    CurrentValue = predictionFactor,
    Callback = function(value)
        predictionFactor = value
    end
})

-- 7) Slider: Snap Angle Threshold (0.001 - 0.1 rad)
AutoTab:CreateSlider({
    Name = "Snap Angle Threshold",
    Range = {0.001, 0.1},
    Increment = 0.001,
    Suffix = "",
    CurrentValue = snapAngleThreshold,
    Callback = function(value)
        snapAngleThreshold = value
    end
})

-- Fungsi bantu: periksa apakah pemain "otherPlayer" valid untuk di-aim
local function canBeTargeted(localPlayer, otherPlayer)
    if not otherPlayer.Character then return false end
    
    -- Cek jika di dalam satu team
    if localPlayer.Team and otherPlayer.Team and localPlayer.Team == otherPlayer.Team then
        return false
    end
    
    -- Cek ForceField
    local otherChar = otherPlayer.Character
    if otherChar:FindFirstChild("ForceField") then return false end
    
    -- Cek Humanoid & Health > 0
    local humanoid = otherChar:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    return true
end

-- Fungsi bantu: cek line-of-sight (LOS) antara kamera lokal dan targetPart
local function hasLineOfSight(localPlayer, targetPart)
    if not targetPart then return false end
    local camera    = workspace.CurrentCamera
    local origin    = camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = { localPlayer.Character }
    rayParams.IgnoreWater = true
    
    local rayResult = workspace:Raycast(origin, direction.Unit * direction.Magnitude, rayParams)
    if rayResult then
        -- Cek apakah yang terkena raycast adalah target atau bagian dari target
        local hitPart = rayResult.Instance
        while hitPart do
            if hitPart == targetPart or hitPart:IsDescendantOf(targetPart.Parent) then
                return true
            end
            hitPart = hitPart.Parent
        end
        return false
    end
    return true
end

-- Fungsi: cari pemain terdekat dalam maxDistance, dengan pengecekan canBeTargeted + LOS
local function findNearestTarget()
    local Players     = game:GetService("Players")
    local localPlayer = Players.LocalPlayer
    
    if not localPlayer.Character then return nil, nil end
    local root = localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil, nil end
    
    local rootPos       = root.Position
    local nearestDist   = maxDistance
    local nearestPlayer = nil
    local nearestPart   = nil

    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= localPlayer and other.Character then
            local otherRoot = other.Character:FindFirstChild("HumanoidRootPart")
            if otherRoot and canBeTargeted(localPlayer, other) then
                local targetPart = nil
                if targetPartOption == "Head" then
                    targetPart = other.Character:FindFirstChild("Head")
                else
                    targetPart = otherRoot
                end

                if targetPart then
                    local otherPos = otherRoot.Position
                    local dist     = (rootPos - otherPos).Magnitude
                    
                    -- Cek jarak dan line of sight (jika diaktifkan)
                    local losCheck = true
                    if checkLOS then
                        losCheck = hasLineOfSight(localPlayer, targetPart)
                    end
                    
                    if dist <= nearestDist and losCheck then
                        nearestDist   = dist
                        nearestPlayer = other
                        nearestPart   = targetPart
                    end
                end
            end
        end
    end

    return nearestPlayer, nearestPart
end

-- RenderStepped: jalankan Auto-Aim jika lockEnabled == true
game:GetService("RunService").RenderStepped:Connect(function()
    if not lockEnabled then return end
    
    local camera      = workspace.CurrentCamera
    local localPlayer = game:GetService("Players").LocalPlayer
    
    -- Pastikan karakter ada sebelum melanjutkan
    if not localPlayer.Character then return end
    
    local targetPlayer, targetPart = findNearestTarget()

    if targetPlayer and targetPart then
        local camPos = camera.CFrame.Position

        -- Prediksi posisi target: posisi sekarang + velocity * predictionFactor
        local predictedPos
        if targetPart:IsA("BasePart") then
            local velocity   = targetPart.Velocity or Vector3.new(0,0,0)
            predictedPos     = targetPart.Position + velocity * predictionFactor
        else
            predictedPos     = targetPart.Position
        end

        -- Buat "desiredCFrame" agar kamera mengarah ke prediksi
        local desiredCFrame = CFrame.new(camPos, predictedPos)

        -- Interpolasi (lerp) dengan smoothSpeed
        local newCFrame = camera.CFrame:Lerp(desiredCFrame, smoothSpeed)
        camera.CFrame = newCFrame

        -- Hitung sudut antara arah kamera sekarang dan arah ke target
        local currentLook = newCFrame.LookVector
        local desiredDir  = (predictedPos - camPos).Unit
        local dotValue    = currentLook:Dot(desiredDir)
        local angle       = math.acos(math.clamp(dotValue, -1, 1))

        -- Jika sudut < snapAngleThreshold, langsung snap agar sangat akurat
        if angle < snapAngleThreshold then
            camera.CFrame = desiredCFrame
        end
    end
end)

-- ===============================================
-- LOADER SELESAI
-- ===============================================
Rayfield:LoadConfiguration() -- Memuat konfigurasi terakhir jika ada
Rayfield:Notify("HXEL Loaded!", "Script berhasil dijalankan", 4483362458)
