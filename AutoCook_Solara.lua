-- AutoCook_Solara.lua (NO UI, SOLARA SAFE)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local FoodService = require(ReplicatedStorage.Modules.FoodService)
local Items = require(ReplicatedStorage.Modules.ItemService)

_G.AutoCookEnabled = false
_G.AutoCookItem = "Lovely Bacon and Eggs"
_G.AutoCookDelay = 0.6

print("[AutoCook] Loaded (Solara Safe)")

local function findStation(stationType)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local item = Items:GetItemFromObject(obj)
            if item and item:IsType(stationType) then
                return obj
            end
        end
    end
end

local function interact(station)
    local char = LocalPlayer.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    hrp.CFrame = station:GetPivot() * CFrame.new(0, 0, 3)
    task.wait(0.4)

    local remote = ReplicatedStorage:FindFirstChild("CookingRemote")
    if remote then
        pcall(function()
            remote:FireServer({ Object = station })
        end)
    end
end

task.spawn(function()
    while true do
        if _G.AutoCookEnabled then
            local item = Items:GetItem(_G.AutoCookItem)
            if item and item.CookRecipe then
                for _, step in ipairs(item.CookRecipe) do
                    if not _G.AutoCookEnabled then break end

                    local action = type(step) == "table" and step[1] or step
                    local data = FoodService.CookActions[action]
                    if not data then continue end

                    local stationType = data.Type or (data.Types and data.Types[1])
                    local station = stationType and findStation(stationType)

                    if station then
                        interact(station)
                        task.wait(data.Duration or 3)
                    end

                    task.wait(_G.AutoCookDelay)
                end
            end
        end
        task.wait(1)
    end
end)