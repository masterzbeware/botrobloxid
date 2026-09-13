--============================================================
-- BOT.LUA
-- MASTERZ HUB - CENTRAL LOADER
--============================================================

local repoBase =
    "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Commands/"

local obsidianRepo =
    "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

--============================================================
-- LOAD OBSIDIAN
--============================================================

local success, Library = pcall(function()
    return loadstring(
        game:HttpGet(
            obsidianRepo .. "Library.lua"
        )
    )()
end)

if not success or not Library then
    error("[Bot.lua] Gagal load Obsidian Library")
end

--============================================================
-- GLOBAL VARIABLES
--============================================================

_G.BotVars = {
    Players = game:GetService("Players"),
    TextChatService = game:GetService("TextChatService"),
    RunService = game:GetService("RunService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),

    LocalPlayer = game:GetService("Players").LocalPlayer,

    Modules = {},
    ModeControllers = {},
    ActiveMode = nil,
}

local vars = _G.BotVars

--============================================================
-- CREATE WINDOW
--============================================================

local Window = Library:CreateWindow({
    Title = "MasterZ HUB",
    Footer = "1.0.5",
    Icon = 0
})

vars.Library = Library
vars.MainWindow = Window

--============================================================
-- COMMAND FILES
--============================================================

local commandFiles = {

    "Perfix.lua",
    "Main.lua",

    "Follow.lua",

    "Pushup.lua",
    "Triangle.lua",
    "Triangle2.lua",
    "Sync.lua",
    "Twoline.lua",
    "Wedgetv.lua",

    "Frontline.lua",
    "Frontline2.lua",

    "FrontlineLeft.lua",
    "FrontlineRight.lua",

    "Salute.lua",
    "Circle.lua",
    "Backline.lua",

    "Rest.lua",
    "Square.lua",
    "Vanguard.lua",
    "SpearHead.lua",

    "ThreeColumn.lua",
    "FourColumn.lua",
}

--============================================================
-- LOAD MODULE
--============================================================

for _, fileName in ipairs(commandFiles) do

    local ok, response = pcall(function()

        return game:HttpGet(
            repoBase .. fileName
        )

    end)

    if not ok then

        warn(
            "[Bot.lua] Gagal HttpGet:",
            fileName,
            response
        )

        continue

    end

    if not response then

        warn(
            "[Bot.lua] Response kosong:",
            fileName
        )

        continue

    end

    ------------------------------------------------------------
    -- COMPILE
    ------------------------------------------------------------

    local loader, loadError =
        loadstring(response)

    if not loader then

        warn(
            "[Bot.lua] Gagal compile:",
            fileName,
            loadError
        )

        continue

    end

    ------------------------------------------------------------
    -- EXECUTE MODULE
    ------------------------------------------------------------

    local moduleSuccess, moduleTable =
        pcall(loader)

    if not moduleSuccess then

        warn(
            "[Bot.lua] Gagal execute:",
            fileName,
            moduleTable
        )

        continue

    end

    ------------------------------------------------------------
    -- VALIDATE MODULE
    ------------------------------------------------------------

    if type(moduleTable) ~= "table" then

        warn(
            "[Bot.lua] Module bukan table:",
            fileName
        )

        continue

    end

    ------------------------------------------------------------
    -- SAVE MODULE
    ------------------------------------------------------------

    local key =
        fileName
            :gsub("%.lua$", "")
            :lower()

    vars.Modules[key] = moduleTable

    print(
        "[Bot.lua] Loaded:",
        key
    )

end

--============================================================
-- WAIT
--============================================================

task.wait(0.5)

--============================================================
-- EXECUTE MODULE
--============================================================

local function jalankan(name)

    local module =
        vars.Modules[name]

    if not module then

        warn(
            "[Bot.lua] Module tidak ditemukan:",
            name
        )

        return

    end

    if type(module.Execute) ~= "function" then

        warn(
            "[Bot.lua] Execute tidak ditemukan:",
            name
        )

        return

    end

    local success, errorMessage =
        pcall(function()

            module.Execute()

        end)

    if not success then

        warn(
            "[Bot.lua] Error Execute:",
            name,
            errorMessage
        )

        return

    end

    print(
        "[Bot.lua] Executed:",
        name
    )

end

--============================================================
-- EXECUTION ORDER
--============================================================

jalankan("perfix")
jalankan("main")

jalankan("follow")

jalankan("pushup")
jalankan("sync")
jalankan("twoline")
jalankan("wedgetv")

jalankan("triangle")
jalankan("triangle2")

jalankan("frontline")
jalankan("frontline2")

jalankan("frontlineleft")
jalankan("frontlineright")

jalankan("salute")

jalankan("circle")
jalankan("backline")

jalankan("square")
jalankan("rest")

jalankan("vanguard")
jalankan("spearhead")

jalankan("threecolumn")
jalankan("fourcolumn")

--============================================================
-- CENTRAL CHAT DEBUG
--============================================================

local TextChatService =
    vars.TextChatService

local Players =
    vars.Players

------------------------------------------------------------
-- TEXT CHAT
------------------------------------------------------------

if TextChatService then

    TextChatService.MessageReceived:Connect(
        function(message)

            local textSource =
                message.TextSource

            if not textSource then
                return
            end

            local sender =
                Players:GetPlayerByUserId(
                    textSource.UserId
                )

            if not sender then
                return
            end

            print(
                "[Bot.lua] CHAT:",
                sender.Name,
                message.Text
            )

        end
    )

end

------------------------------------------------------------
-- OLD CHAT FALLBACK
------------------------------------------------------------

for _, player in ipairs(
    Players:GetPlayers()
) do

    player.Chatted:Connect(
        function(message)

            print(
                "[Bot.lua] CHAT OLD:",
                player.Name,
                message
            )

        end
    )

end

Players.PlayerAdded:Connect(
    function(player)

        player.Chatted:Connect(
            function(message)

                print(
                    "[Bot.lua] CHAT OLD:",
                    player.Name,
                    message
                )

            end
        )

    end
)

--============================================================
-- FINISHED
--============================================================

print("======================================")
print("✅ MasterZ HUB loaded")
print("✅ All modules loaded")
print("✅ All modules executed")
print("✅ Central chat listener active")
print("======================================")