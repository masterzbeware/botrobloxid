-- Administrator/Distance.lua
-- Daftar bot dan pasangan bot untuk sistem formasi/jarak.

local DistanceModule = {}

--------------------------------------------------
-- DAFTAR BOT
--------------------------------------------------

DistanceModule.Bots = {

    ["11611503633"] = "Bot 1",
    ["11611591921"] = "Bot 2",
    ["11611597741"] = "Bot 3",
    ["11672407300"] = "Bot 4",
    ["11672403154"] = "Bot 5",
    ["11672413029"] = "Bot 6",
    ["11672983578"] = "Bot 7",
    ["11122806815"] = "Bot 8",
    ["11122806817"] = "Bot 9",
    ["11122687468"] = "Bot 10",
    ["11122854402"] = "Bot 11",
    ["11001607521"] = "Bot 12",




}

--------------------------------------------------
-- URUTAN BOT
--------------------------------------------------
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
--------------------------------------------------

DistanceModule.Pairs = {

{
    ["BotA"] = "11611503633",
    ["BotB"] = "11611591921",
    ["Distance"] = 2
}, -- Bot 1 - Bot 2

{
    ["BotA"] = "11611597741",
    ["BotB"] = "11672407300",
    ["Distance"] = 2
}, -- Bot 3 - Bot 4

{
    ["BotA"] = "11672403154",
    ["BotB"] = "11672413029",
    ["Distance"] = 2
}, -- Bot 5 - Bot 6

{
    ["BotA"] = "11672983578",
    ["BotB"] = "11122806815",
    ["Distance"] = 2
}, -- Bot 7 - Bot 8

{
    ["BotA"] = "11122806817",
    ["BotB"] = "11122687468",
    ["Distance"] = 2
}, -- Bot 9 - Bot 10

{
    ["BotA"] = "11122854402",
    ["BotB"] = "11001607521",
    ["Distance"] = 2
}, -- Bot 11 - Bot 12

}

--------------------------------------------------
-- MENGAMBIL JARAK ANTAR PASANGAN BOT
--------------------------------------------------

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

--------------------------------------------------
-- CEK APAKAH USER ID ADALAH BOT
--------------------------------------------------

function DistanceModule:IsBot(userId)

    return self.Bots[tostring(userId)] ~= nil

end

--------------------------------------------------
-- MENGAMBIL NAMA BOT
--------------------------------------------------

function DistanceModule:GetBotName(userId)

    return self.Bots[tostring(userId)]

end

--------------------------------------------------
-- MENGAMBIL SEMUA BOT
--------------------------------------------------

function DistanceModule:GetBots()

    return self.Bots

end

--------------------------------------------------
-- RETURN MODULE
--------------------------------------------------

return DistanceModule
