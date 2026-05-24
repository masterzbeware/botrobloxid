-- Administrator/Distance.lua
-- Daftar Bot dan jarak antar pasangan

local DistanceModule = {}

-- ✅ Daftar Bot
DistanceModule.Bots = {
    ["11001607521"] = "Bot 1",
    ["11001608049"] = "Bot 2",
    ["11001625681"] = "Bot 3",
    ["11001647769"] = "Bot 4",
}

-- ✅ Pasangan Bot dan jaraknya (pastikan UserId sesuai daftar Bots)
DistanceModule.Pairs = {
    {["BotA"] = "10191476366", ["BotB"] = "10191480511", ["Distance"] = 3}, -- Bot1-Bot2
    {["BotA"] = "10191462654", ["BotB"] = "10190853828", ["Distance"] = 3}, -- Bot3-Bot4
    {["BotA"] = "10191023081", ["BotB"] = "10191070611", ["Distance"] = 3}, -- Bot5-Bot6
    {["BotA"] = "10191489151", ["BotB"] = "10191571531", ["Distance"] = 3}, -- Bot7-Bot8
    {["BotA"] = "10192469244", ["BotB"] = "10192474291", ["Distance"] = 3}, -- Bot9-Bot10
    {["BotA"] = "10196485340", ["BotB"] = "10196526503", ["Distance"] = 3}, -- Bot11-Bot12
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
