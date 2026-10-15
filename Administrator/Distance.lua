-- Administrator/Distance.lua
-- Daftar bot dan pasangan bot untuk sistem formasi/jarak.

local DistanceModule = {}

--------------------------------------------------
-- DAFTAR BOT
--------------------------------------------------

DistanceModule.Bots = {

		["11801693968"] = "Bot 1",
		["11801692411"] = "Bot 2",
		["11801726433"] = "Bot 3",
		["11801750996"] = "Bot 4",
        ["11802903376"] = "Bot 5",
        ["11802903446"] = "Bot 6",
        ["11802916689"] = "Bot 7",
        ["11810691407"] = "Bot 8",
        ["11810683044"] = "Bot 9",

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


--------------------------------------------------
-- DAFTAR BOT
--------------------------------------------------

DistanceModule.Bots = {
    ["11801693968"] = "Bot 1",
    ["11801692411"] = "Bot 2",

    ["11801726433"] = "Bot 3",
    ["11801750996"] = "Bot 4",

    ["11802903376"] = "Bot 5",
    ["11802903446"] = "Bot 6",

    ["11802916689"] = "Bot 7",
    ["11810691407"] = "Bot 8",

    ["11810683044"] = "Bot 9",
}

--------------------------------------------------
-- PASANGAN BOT
--------------------------------------------------
-- Bot 1 - Bot 2
-- Bot 3 - Bot 4
-- Bot 5 - Bot 6
-- Bot 7 - Bot 8
-- Bot 9 tidak memiliki pasangan
-- Jarak antar pasangan = 2
--------------------------------------------------

DistanceModule.Pairs = {
    {
        ["BotA"] = "11801693968",
        ["BotB"] = "11801692411",
        ["Distance"] = 2
    }, -- Bot 1 - Bot 2

    {
        ["BotA"] = "11801726433",
        ["BotB"] = "11801750996",
        ["Distance"] = 2
    }, -- Bot 3 - Bot 4

    {
        ["BotA"] = "11802903376",
        ["BotB"] = "11802903446",
        ["Distance"] = 2
    }, -- Bot 5 - Bot 6

    {
        ["BotA"] = "11802916689",
        ["BotB"] = "11810691407",
        ["Distance"] = 2
    }, -- Bot 7 - Bot 8
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
