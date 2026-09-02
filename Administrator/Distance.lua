-- Administrator/Distance.lua
-- Daftar Bot dan jarak antar pasangan

local DistanceModule = {}

-- ✅ Daftar Bot
DistanceModule.Bots = {
    ["11611503633"] = "Bot 1",
    ["11611534165"] = "Bot 2",
    ["11611567975"] = "Bot 3",
    ["11611562042"] = "Bot 4",
    ["11611591921"] = "Bot 5",
    ["11122806815"] = "Bot 6",
    ["11122806817"] = "Bot 7",
    ["11122687468"] = "Bot 8",
    ["11122854402"] = "Bot 9",
}

-- ✅ Pasangan Bot dan jaraknya (pastikan UserId sesuai daftar Bots)
DistanceModule.Pairs = {
    {["BotA"] = "11611503633", ["BotB"] = "11611534165", ["Distance"] = 3}, -- Bot1-Bot2
    {["BotA"] = "11611567975", ["BotB"] = "11611567975", ["Distance"] = 3}, -- Bot3-Bot4
    {["BotA"] = "11611562042", ["BotB"] = "11611591921", ["Distance"] = 3}, -- Bot5-Bot6
    {["BotA"] = "11122806815", ["BotB"] = "11122806817", ["Distance"] = 3}, -- Bot7-Bot8
    {["BotA"] = "11122687468", ["BotB"] = "111228544020", ["Distance"] = 3}, -- Bot9-Bot10
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
