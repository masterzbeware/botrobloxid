-- AutoCook_Solara.lua
-- HARD PATH | NO MODULE | SOLARA SAFE

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- =========================
-- CONFIG
-- =========================
_G.AutoCookEnabled = false
_G.AutoCookDelay = 0.6

-- =========================
-- PATH
-- =========================
local Plot = workspace.Plots:WaitForChild("Plot_Umbralis_4")
local House = Plot:WaitForChild("House")
local Counters = House:WaitForChild("Counters")

local Fridge = Counters:WaitForChild("FlexFreeze Fridge")
local PlaceArea =
    Counters:WaitForChild("Basic Counter")
        :WaitForChild("ObjectModel")
        :WaitForChild("PlaceArea")

print("[AutoCook] Loaded (Hard Path, Solara Safe)")

-- =========================
-- UTILS
-- =========================
local function teleportTo(part)
    local char = LocalPlayer.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    hrp.CFrame = part.CFrame * CFrame.new(0, 0, 2)
end

local function interact(part)
    teleportTo(part)
    task.wait(0.3)

    -- ProximityPrompt
    for _, v in ipairs(part:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            fireproximityprompt(v)
            return
        end
    end

    -- ClickDetector fallback
    for _, v in ipairs(part:GetDescendants()) do
        if v:IsA("ClickDetector") then
            fireclickdetector(v)
            return
        end
    end
end

-- =========================
-- MAIN LOOP
-- =========================
task.spawn(function()
    while true do
        if _G.AutoCookEnabled then
            -- Ambil bahan
            interact(Fridge)
            task.wait(1)

            -- Mix / place
            interact(PlaceArea)
            task.wait(_G.AutoCookDelay)
        end
        task.wait(1)
    end
end)