-- AutoCook_Solara_Minimal.lua (SUPER SOLARA SAFE)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

_G.AutoCookEnabled = _G.AutoCookEnabled or false
_G.AutoCookDelay = _G.AutoCookDelay or 4

print("[AutoCook] Minimal loaded")

local function getStove()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v.Name:lower():find("stove") then
            return v
        end
    end
end

local function interact(stove)
    local char = LocalPlayer.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    hrp.CFrame = stove:GetPivot() * CFrame.new(0,0,3)
    task.wait(0.3)

    local remote = ReplicatedStorage:FindFirstChild("CookingRemote", true)
    if remote then
        pcall(function()
            remote:FireServer({ Object = stove })
        end)
    end
end

task.spawn(function()
    while task.wait(_G.AutoCookDelay) do
        if not _G.AutoCookEnabled then continue end

        local stove = getStove()
        if stove then
            interact(stove)
        end
    end
end)