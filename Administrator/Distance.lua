-- Administrator/Distance.lua
-- Daftar Bot dan jarak antar pasangan

local DistanceModule = {}

-- ✅ Daftar Bot
DistanceModule.Bots = {
    ["11001607521"] = "Bot 1",
    ["11001608049"] = "Bot 2",
    ["11001625681"] = "Bot 3",
    ["11001647769"] = "Bot 4",
    ["11002716767"] = "Bot 5",
    ["11002763516"] = "Bot 6",
    ["11002833908"] = "Bot 7",
    ["11002919499"] = "Bot 8",
    ["11002918670"] = "Bot 9",
    ["11007692539"] = "Bot 10",
}

-- ✅ Pasangan Bot dan jaraknya (pastikan UserId sesuai daftar Bots)
DistanceModule.Pairs = {
    {["BotA"] = "11001607521", ["BotB"] = "11001608049", ["Distance"] = 3}, -- Bot1-Bot2
    {["BotA"] = "11001625681", ["BotB"] = "11001647769", ["Distance"] = 3}, -- Bot3-Bot4
    {["BotA"] = "11001647769", ["BotB"] = "11002716767", ["Distance"] = 3}, -- Bot4-Bot5
    {["BotA"] = "11002716767", ["BotB"] = "11002763516", ["Distance"] = 3}, -- Bot5-Bot6
    {["BotA"] = "11002763516", ["BotB"] = "11002833908", ["Distance"] = 3}, -- Bot6-Bot7
    {["BotA"] = "11002833908", ["BotB"] = "11002919499", ["Distance"] = 3}, -- Bot7-Bot8
    {["BotA"] = "11002919499", ["BotB"] = "11002918670", ["Distance"] = 3}, -- Bot8-Bot9
    {["BotA"] = "11002918670", ["BotB"] = "11007692539", ["Distance"] = 3}, -- Bot8-Bot9
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
