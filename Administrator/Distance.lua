-- Administrator/Distance.lua
-- Daftar Bot dan jarak antar pasangan

local DistanceModule = {}

-- ✅ Daftar Bot
DistanceModule.Bots = {
    ["10190578237"] = "Bot 1",
    ["10190587148"] = "Bot 2",
    ["10190589698"] = "Bot 3",
    ["10190597760"] = "Bot 4",
    ["10190628492"] = "Bot 5",
    ["10190661182"] = "Bot 6",
}

-- ✅ Pasangan Bot dan jaraknya
DistanceModule.Pairs = {
    {["BotA"] = "10190578237", ["BotB"] = "10190587148", ["Distance"] = 3},
    {["BotA"] = "10190589698", ["BotB"] = "10190597760", ["Distance"] = 3},
    {["BotA"] = "10190628492", ["BotB"] = "10190661182", ["Distance"] = 3},
}

-- ✅ Fungsi untuk mengambil jarak pasangan
function DistanceModule:GetDistance(userIdA, userIdB)
    for _, pair in ipairs(self.Pairs) do
        if (pair.BotA == userIdA and pair.BotB == userIdB) or (pair.BotA == userIdB and pair.BotB == userIdA) then
            return pair.Distance
        end
    end
    return nil -- jika bukan pasangan, tidak ada jarak spesial
end

-- ✅ Fungsi untuk mengecek apakah userId adalah Bot
function DistanceModule:IsBot(userId)
    return self.Bots[tostring(userId)] ~= nil
end

return DistanceModule
