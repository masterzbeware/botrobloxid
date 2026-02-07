-- AutoCook_Solara.lua (NO UI, SOLARA SAFE)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- JANGAN reset _G kalau sudah diset dari executor
_G.AutoCookEnabled = _G.AutoCookEnabled or false
_G.AutoCookItem = _G.AutoCookItem or "Lovely Bacon and Eggs"
_G.AutoCookDelay = _G.AutoCookDelay or 0.6

print("[AutoCook] Loaded (Solara Safe)")

-- =========================
-- SAFE REQUIRE
-- =========================
local FoodService
local Items

do
    local ok1, mod1 = pcall(function()
        return require(ReplicatedStorage.Modules.FoodService)
    end)
    local ok2, mod2 = pcall(function()
        return require(ReplicatedStorage.Modules.ItemService)
    end)

    if not ok1 or not ok2 then
        warn("[AutoCook] Module load failed")
        return
    end

    FoodService = mod1
    Items = mod2
end

-- =========================
-- CACHE STATION (LEBIH AMAN)
-- =========================
local StationCache = {}

local function buildStationCache()
    table.clear(StationCache)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local ok, item = pcall(function()
                return Items:GetItemFromObject(obj)
            end)
            if ok and item and item.Type then
                StationCache[item.Type] = obj
            end
        end
    end
end

buildStationCache()

-- =========================
-- INTERACT
-- =========================
local function interact(station)
    local char = LocalPlayer.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    hrp.CFrame = station:GetPivot() * CFrame.new(0, 0, 3)
    task.wait(0.4)

    local remote = ReplicatedStorage:FindFirstChild("CookingRemote", true)
    if remote then
        pcall(function()
            remote:FireServer({ Object = station })
        end)
    end
end

-- =========================
-- MAIN LOOP
-- =========================
task.spawn(function()
    while task.wait(1) do
        if not _G.AutoCookEnabled then
            continue
        end

        local item = Items:GetItem(_G.AutoCookItem)
        if not item or not item.CookRecipe then
            continue
        end

        for _, step in ipairs(item.CookRecipe) do
            if not _G.AutoCookEnabled then break end

            local action = type(step) == "table" and step[1] or step
            local data = FoodService.CookActions[action]
            if not data then continue end

            local stationType = data.Type or (data.Types and data.Types[1])
            local station = stationType and StationCache[stationType]

            if station then
                interact(station)
                task.wait(data.Duration or 3)
            end

            task.wait(_G.AutoCookDelay)
        end
    end
end)