-- Administrator/Distance.lua

local DistanceModule = {}

-- =========================================================
-- DAFTAR BOT
-- =========================================================

DistanceModule.Bots = {

    ["11611503633"] = "Bot 1",
    ["11611534165"] = "Bot 2",
    ["11611567975"] = "Bot 3",
    ["11611562042"] = "Bot 4",
    ["11611591921"] = "Bot 5",
    ["11611597741"] = "Bot 6",
    ["11122806815"] = "Bot 7",
    ["11122806817"] = "Bot 8",
    ["11122687468"] = "Bot 9",
    ["11122854402"] = "Bot 10",
    ["11001607521"] = "Bot 11",
    ["11001608049"] = "Bot 12",

}

-- =========================================================
-- PASANGAN BOT DAN JARAK
-- =========================================================
--
-- Bot 1  - Bot 2
-- Bot 3  - Bot 4
-- Bot 5  - Bot 6
-- Bot 7  - Bot 8
-- Bot 9  - Bot 10
-- Bot 11 - Bot 12
--
-- Jarak antar pasangan = 3
--
-- =========================================================

DistanceModule.Pairs = {

    {
        ["BotA"] = "11611503633",
        ["BotB"] = "11611534165",
        ["Distance"] = 3
    }, -- Bot 1 - Bot 2

    {
        ["BotA"] = "11611567975",
        ["BotB"] = "11611562042",
        ["Distance"] = 3
    }, -- Bot 3 - Bot 4

    {
        ["BotA"] = "11611591921",
        ["BotB"] = "11611597741",
        ["Distance"] = 3
    }, -- Bot 5 - Bot 6

    {
        ["BotA"] = "11122806815",
        ["BotB"] = "11122806817",
        ["Distance"] = 3
    }, -- Bot 7 - Bot 8

    {
        ["BotA"] = "11122687468",
        ["BotB"] = "11122854402",
        ["Distance"] = 3
    }, -- Bot 9 - Bot 10

    {
        ["BotA"] = "11001607521",
        ["BotB"] = "11001608049",
        ["Distance"] = 3
    }, -- Bot 11 - Bot 12

}

-- =========================================================
-- MENGAMBIL JARAK ANTAR PASANGAN BOT
-- =========================================================

function DistanceModule:GetDistance(userIdA, userIdB)

    userIdA = tostring(userIdA)
    userIdB = tostring(userIdB)

    for _, pair in ipairs(self.Pairs) do

        if (
            pair.BotA == userIdA
            and pair.BotB == userIdB
        )
        or (
            pair.BotA == userIdB
            and pair.BotB == userIdA
        ) then

            return pair.Distance

        end

    end

    return nil

end

-- =========================================================
-- CEK APAKAH USER ID ADALAH BOT
-- =========================================================

function DistanceModule:IsBot(userId)

    return self.Bots[tostring(userId)] ~= nil

end

-- =========================================================
-- MENGAMBIL NAMA BOT
-- =========================================================

function DistanceModule:GetBotName(userId)

    return self.Bots[tostring(userId)]

end

-- =========================================================
-- MENGAMBIL SEMUA BOT
-- =========================================================

function DistanceModule:GetBots()

    return self.Bots

end

-- =========================================================
-- RETURN MODULE
-- =========================================================

return DistanceModule