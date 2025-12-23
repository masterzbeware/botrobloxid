-- Administrator/Distance.lua
-- Daftar Bot dan jarak antar pasangan

local DistanceModule = {}

-- ✅ Daftar Bot
DistanceModule.Bots = {
    ["10191476366"] = "Bot 1",
    ["10191480511"] = "Bot 2",
    ["10191462654"] = "Bot 3",
    ["10190853828"] = "Bot 4",
    ["10191023081"] = "Bot 5",
    ["10191070611"] = "Bot 6",
    ["10191489151"] = "Bot 7", -- Bot7 baru
}

-- ✅ Pasangan Bot dan jaraknya (pastikan UserId sesuai daftar Bots)
DistanceModule.Pairs = {
    {["BotA"] = "10191476366", ["BotB"] = "10191480511", ["Distance"] = 3}, -- Bot1-Bot2
    {["BotA"] = "10191462654", ["BotB"] = "10190853828", ["Distance"] = 3}, -- Bot3-Bot4
    {["BotA"] = "10191023081", ["BotB"] = "10191070611", ["Distance"] = 3}, -- Bot5-Bot6
    -- Bot7 tidak punya pasangan, pakai jarak default
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
