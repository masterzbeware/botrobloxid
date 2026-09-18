return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")
        local TextChatService = game:GetService("TextChatService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[Sync] LocalPlayer tidak ditemukan.")
            return
        end

        ----------------------------------------------------------------
        -- GLOBAL
        ----------------------------------------------------------------

        _G.BotVars = _G.BotVars or {}

        ----------------------------------------------------------------
        -- LOAD ADMIN
        ----------------------------------------------------------------

        local Admin

        local adminSuccess, adminResult = pcall(function()
            return loadstring(game:HttpGet(
                "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
            ))()
        end)

        if adminSuccess and type(adminResult) == "table" then
            Admin = adminResult
        else
            warn("[Sync] Gagal load Admin.lua.")
            return
        end

        ----------------------------------------------------------------
        -- REQUEST SYNC REMOTE
        ----------------------------------------------------------------

        local Events = ReplicatedStorage:WaitForChild("Events")
        local RequestSync = Events:WaitForChild("RequestSync")

        ----------------------------------------------------------------
        -- FIND PLAYER
        ----------------------------------------------------------------

        local function findPlayer(name)

            if not name or name == "" then
                return nil
            end

            local search = name:lower()

            ------------------------------------------------------------
            -- EXACT USERNAME
            ------------------------------------------------------------

            for _, player in ipairs(Players:GetPlayers()) do
                if player.Name:lower() == search then
                    return player
                end
            end

            ------------------------------------------------------------
            -- EXACT DISPLAY NAME
            ------------------------------------------------------------

            for _, player in ipairs(Players:GetPlayers()) do
                if player.DisplayName:lower() == search then
                    return player
                end
            end

            ------------------------------------------------------------
            -- PREFIX USERNAME / DISPLAY NAME
            ------------------------------------------------------------

            for _, player in ipairs(Players:GetPlayers()) do

                if player.Name:lower():sub(1, #search) == search then
                    return player
                end

                if player.DisplayName:lower():sub(1, #search) == search then
                    return player
                end

            end

            return nil
        end

        ----------------------------------------------------------------
        -- REQUEST SYNC
        ----------------------------------------------------------------

        local function requestSync(target)

            if not target then
                return
            end

            local success, err = pcall(function()
                RequestSync:FireServer(target)
            end)

            if success then
                print(
                    "[Sync] RequestSync:",
                    target.Name,
                    "(" .. target.DisplayName .. ")"
                )
            else
                warn("[Sync] RequestSync gagal:", err)
            end

        end

        ----------------------------------------------------------------
        -- COMMAND HANDLER
        ----------------------------------------------------------------

        local function handleCommand(message, sender)

            if not message or not sender then
                return
            end

            ------------------------------------------------------------
            -- ADMIN CHECK
            ------------------------------------------------------------

            local isAdmin = false

            pcall(function()
                isAdmin = Admin:IsAdmin(sender)
            end)

            if not isAdmin then
                return
            end

            ------------------------------------------------------------
            -- CLEAN MESSAGE
            ------------------------------------------------------------

            local command =
                message
                :gsub("^%s+", "")
                :gsub("%s+$", "")

            local lower =
                command:lower()

            ------------------------------------------------------------
            -- !SYNC
            --
            -- Penting:
            -- Jangan mengubah ActiveMode / CommandTarget.
            -- Sync hanya mengirim RequestSync.
            ------------------------------------------------------------

            if lower == "!sync" then

                print(
                    "[Sync] Command diterima:",
                    sender.Name,
                    "->",
                    sender.Name
                )

                requestSync(sender)

                return
            end

            ------------------------------------------------------------
            -- !SYNC <USERNAME / DISPLAYNAME>
            ------------------------------------------------------------

            local targetName =
                command:match("^!sync%s+(.+)$")

            if targetName then

                local target =
                    findPlayer(targetName)

                if not target then
                    warn(
                        "[Sync] Player tidak ditemukan:",
                        targetName
                    )
                    return
                end

                print(
                    "[Sync] Command diterima:",
                    sender.Name,
                    "->",
                    target.Name
                )

                requestSync(target)

                return
            end

        end

        ----------------------------------------------------------------
        -- CHAT CONNECTION
        --
        -- Gunakan player.Chatted sebagai listener utama.
        -- Ini mencegah !sync diproses dua kali karena
        -- TextChatService.MessageReceived + Chatted.
        ----------------------------------------------------------------

        local function connectPlayer(player)

            if not player then
                return
            end

            player.Chatted:Connect(function(message)
                handleCommand(message, player)
            end)

        end

        ----------------------------------------------------------------
        -- CONNECT EXISTING PLAYERS
        ----------------------------------------------------------------

        for _, player in ipairs(Players:GetPlayers()) do
            connectPlayer(player)
        end

        ----------------------------------------------------------------
        -- CONNECT NEW PLAYERS
        ----------------------------------------------------------------

        Players.PlayerAdded:Connect(function(player)
            connectPlayer(player)
        end)

        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print("[Sync] Loaded successfully.")
        print("[Sync] !sync")
        print("[Sync] !sync <username/displayname>")

    end
}
