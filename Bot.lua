-- Bot.lua
-- MasterZ HUB
-- Loader command dengan logging error yang jelas.
-- Mendukung subfolder seperti Commands/Dance/BrazilDance.lua

--------------------------------------------------
-- REPOSITORY
--------------------------------------------------

local repoBase =
    "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Commands/"

local obsidianRepo =
    "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

--------------------------------------------------
-- LOAD OBSIDIAN
--------------------------------------------------

local libraryOk, Library = pcall(function()
    local source = game:HttpGet(
        obsidianRepo .. "Library.lua"
    )

    local loader, compileError = loadstring(source)

    if not loader then
        error(compileError or "Gagal compile Obsidian Library")
    end

    return loader()
end)

if not libraryOk or not Library then
    error(
        "[Bot.lua] Gagal load Obsidian Library: "
        .. tostring(Library)
    )
end

--------------------------------------------------
-- GLOBAL VARIABLES
--------------------------------------------------

_G.BotVars = {
    Players = game:GetService("Players"),
    TextChatService = game:GetService("TextChatService"),
    RunService = game:GetService("RunService"),
    LocalPlayer = game:GetService("Players").LocalPlayer,

    CommandTarget = nil,
    ActiveMode = nil,
    ModeControllers = {},
    AdditionalAdmins = {},
    Modules = {},
    Tabs = {},
}

--------------------------------------------------
-- CREATE WINDOW
--------------------------------------------------

local windowOk, Window = pcall(function()
    return Library:CreateWindow({
        Title = "MasterZ HUB",
        Footer = "1.0.0",
        Icon = 0,
    })
end)

if not windowOk or not Window then
    error(
        "[Bot.lua] Gagal membuat Window: "
        .. tostring(Window)
    )
end

_G.BotVars.Library = Library
_G.BotVars.MainWindow = Window

--------------------------------------------------
-- COMMAND FILES
--------------------------------------------------

local commandFiles = {
    "Perfix.lua",
    "Main.lua",
    "Agree.lua",
    "Arrow.lua",
    "Backline.lua",

    -- BrazilDance sekarang berada di subfolder Dance
    "Dance/BrazilDance.lua",
    "Dance/KangoraDance.lua",
    "Dance/PakodiDance.lua",
    "Dance/PargoyDance.lua",
    "Dance/ScubaDance.lua",
    "Dance/KetlinDance.lua",
    "Dance/TripoutDance.lua",
    "Dance/HulaDance.lua",
    "Dance/TomatoDance.lua",
    "Dance/TrackmakerDance.lua",
    "Dance/MyDawgDance.lua",

    "Circle.lua",
    "Collision.lua",
    "Follow.lua",
    "Fourline.lua",
    "Frontline.lua",
    "Glowstick.lua",
    "Message.lua",
    "Rest.lua",
    "Salute.lua",
    "Sit.lua",
    "Square.lua",
    "Sync.lua",
    "Worship.lua",
    "LineFormation.lua",
    "Stagger.lua",
    "Centerline.lua",
}

--------------------------------------------------
-- LOAD COMMAND MODULES
--------------------------------------------------

for _, fileName in ipairs(commandFiles) do
    local url = repoBase .. fileName

    print("[Bot.lua] Mengambil:", url)

    --------------------------------------------------
    -- DOWNLOAD SOURCE
    --------------------------------------------------

    local httpOk, source = pcall(function()
        return game:HttpGet(url)
    end)

    if not httpOk then
        warn(
            "[Bot.lua] HTTP GAGAL:",
            fileName,
            tostring(source)
        )
        continue
    end

    if type(source) ~= "string" or source == "" then
        warn(
            "[Bot.lua] Source kosong:",
            fileName
        )
        continue
    end

    --------------------------------------------------
    -- COMPILE SOURCE
    --------------------------------------------------

    local loader, compileError = loadstring(source)

    if not loader then
        warn(
            "[Bot.lua] SYNTAX ERROR:",
            fileName,
            tostring(compileError)
        )
        continue
    end

    --------------------------------------------------
    -- EXECUTE MODULE CHUNK
    --------------------------------------------------

    local moduleOk, moduleTable = pcall(loader)

    if not moduleOk then
        warn(
            "[Bot.lua] MODULE ERROR:",
            fileName,
            tostring(moduleTable)
        )
        continue
    end

    if type(moduleTable) ~= "table" then
        warn(
            "[Bot.lua] Return module bukan table:",
            fileName
        )
        continue
    end

    --------------------------------------------------
    -- REGISTER MODULE
    --------------------------------------------------

    -- Ambil nama file saja, bukan nama folder.
    -- Dance/BrazilDance.lua -> brazildance
    local key = fileName:match("([^/]+)%.lua$")

    if not key then
        warn(
            "[Bot.lua] Nama module tidak valid:",
            fileName
        )
        continue
    end

    key = key:lower()

    _G.BotVars.Modules[key] = moduleTable

    print("[Bot.lua] Loaded:", key)
end

--------------------------------------------------
-- EXECUTION FUNCTION
--------------------------------------------------

local function jalankan(name)
    name = name:lower()

    local module = _G.BotVars.Modules[name]

    if not module then
        warn(
            "[Bot.lua] Module tidak ditemukan:",
            name
        )
        return false
    end

    if type(module.Execute) ~= "function" then
        warn(
            "[Bot.lua] Module tidak memiliki Execute():",
            name
        )
        return false
    end

    local executeOk, executeError = pcall(function()
        module.Execute()
    end)

    if not executeOk then
        warn(
            "[Bot.lua] EXECUTE ERROR:",
            name,
            tostring(executeError)
        )
        return false
    end

    print("[Bot.lua] Executed:", name)
    return true
end

--------------------------------------------------
-- EXECUTION ORDER
--------------------------------------------------

local executionOrder = {
    "perfix",
    "main",
    "agree",
    "arrow",
    "backline",
    "brazildance",
    "circle",
    "follow",
    "fourline",
    "frontline",
    "glowstick",
    "kangoradance",
    "message",
    "pakodidance",
    "pargoydance",
    "rest",
    "salute",
    "sit",
    "square",
    "sync",
    "worship",
    "lineformation",
    "stagger",
    "centerline",
    "scubadance",
    "ketlindance",
    "tripoutdance",
    "huladance",
    "tomatodance",
    "trackmakerdance",
    "mydawgdance",
}

for _, name in ipairs(executionOrder) do
    jalankan(name)
end

--------------------------------------------------
-- FINISHED
--------------------------------------------------

print("[Bot.lua] Proses pemuatan command selesai.")