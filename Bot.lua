local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Kyro Hub",
    SubTitle = "",
    TabWidth = 160,
    Size = UDim2.fromOffset(500, 350),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "MAIN" }),
    AutoFishing = Window:AddTab({ Title = "AUTO FISHING" })
}

Tabs.AutoFishing:AddParagraph({
    Title = "Auto Fishing",
    Content = "Auto casting"
})

-- VARIABEL
local AutoFishingEnabled = false
local autoFishingLoop = nil

-- 🔥 SPEED CONTROL (NEW)
local FishingSpeed = 1 -- default normal (1x)

-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local CastRequest = ReplicatedStorage.Packages.Knit.Services.Fish.RF.CastRequest
local MinigameResolved = ReplicatedStorage.Packages.Knit.Services.Fish.RF.MinigameResolved
local CastVisuals = ReplicatedStorage.Packages.Knit.Services.Fish.RE.CastVisuals

-- UTIL
local function randomFloat(min, max)
    return min + (math.random() * (max - min))
end

local function getGoodPower()
    return randomFloat(0.85, 0.95)
end

local function doCast()
    local power = getGoodPower()
    CastRequest:InvokeServer(power)
end

-- CAST VISUAL HANDLER
CastVisuals.OnClientEvent:Connect(function(player, pos, fish, weight, data)
    if player == LocalPlayer and AutoFishingEnabled then

        local minigameDelay = (4.5 + randomFloat(0, 0.5)) / FishingSpeed
        task.wait(minigameDelay)

        local reactionTime = randomFloat(0.2, 0.6) / FishingSpeed
        task.wait(reactionTime)

        MinigameResolved:InvokeServer(true)
    end
end)

-- LOOP
local function StartAutoFishing()
    if autoFishingLoop then
        task.cancel(autoFishingLoop)
    end

    autoFishingLoop = task.spawn(function()
        while AutoFishingEnabled do
            doCast()

            local baseDelay = randomFloat(8, 15)
            task.wait(baseDelay / FishingSpeed)
        end
    end)
end

-- TOGGLE
Tabs.AutoFishing:AddToggle("AutoFishingToggle", {
    Title = "Auto Fishing",
    Default = false
}):OnChanged(function(Value)
    AutoFishingEnabled = Value

    if AutoFishingEnabled then
        StartAutoFishing()

        Fluent:Notify({
            Title = "Auto Fishing",
            Content = "Fishing dimulai!",
            Duration = 3
        })
    else
        if autoFishingLoop then
            task.cancel(autoFishingLoop)
            autoFishingLoop = nil
        end

        Fluent:Notify({
            Title = "Auto Fishing",
            Content = "Fishing dihentikan",
            Duration = 2
        })
    end
end)

-- 🔥 SPEED SLIDER (NEW - DI BAWAH TOGGLE)
Tabs.AutoFishing:AddSlider("FishingSpeedSlider", {
    Title = "Fishing Speed",
    Description = "Semakin kecil = semakin cepat",
    Default = 1,
    Min = 0.2,
    Max = 3,
    Rounding = 1
}):OnChanged(function(Value)
    FishingSpeed = Value
end)

-- MAINTAIN LOOP
task.spawn(function()
    while task.wait(2) do
        if AutoFishingEnabled and not autoFishingLoop then
            StartAutoFishing()
        end
    end
end)

Window:SelectTab(1)

Fluent:Notify({
    Title = "L-01 Auto Fishing",
    Content = "Ready!",
    Duration = 5
})