return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[Sync] LocalPlayer tidak ditemukan.")
            return
        end


        ----------------------------------------------------------------
        -- GLOBAL SYSTEM
        ----------------------------------------------------------------

        _G.BotVars = _G.BotVars or {}


        ----------------------------------------------------------------
        -- PREVENT DUPLICATE EXECUTE
        ----------------------------------------------------------------

        if _G.BotVars.SyncLoaded then
            warn("[Sync] Sync.lua sudah aktif.")
            return
        end

        _G.BotVars.SyncLoaded = true


        ----------------------------------------------------------------
        -- ADMIN MODULE
        ----------------------------------------------------------------

        local Admin

        local successAdmin, resultAdmin = pcall(function()
            return loadstring(game:HttpGet(
                "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
            ))()
        end)

        if not successAdmin then
            warn("[Sync] Gagal load Admin.lua:", resultAdmin)
            _G.BotVars.SyncLoaded = false
            return
        end

        Admin = resultAdmin


        ----------------------------------------------------------------
        -- REQUEST SYNC REMOTE
        ----------------------------------------------------------------

        local EventsFolder = ReplicatedStorage:WaitForChild("Events", 10)

        if not EventsFolder then
            warn("[Sync] Folder ReplicatedStorage.Events tidak ditemukan.")
            _G.BotVars.SyncLoaded = false
            return
        end

        local RequestSync = EventsFolder:WaitForChild("RequestSync", 10)

        if not RequestSync then
            warn("[Sync] RemoteEvent RequestSync tidak ditemukan.")
            _G.BotVars.SyncLoaded = false
            return
        end


        ----------------------------------------------------------------
        -- FIND PLAYER
        ----------------------------------------------------------------

        local function findPlayer(name)
            if not name or name == "" then
                return nil
            end

            name = tostring(name)

            ------------------------------------------------------------
            -- EXACT USERNAME
            ------------------------------------------------------------

            for _, player in ipairs(Players:GetPlayers()) do
                if string.lower(player.Name) == string.lower(name) then
                    return player
                end
            end


            ------------------------------------------------------------
            -- EXACT DISPLAY NAME
            ------------------------------------------------------------

            for _, player in ipairs(Players:GetPlayers()) do
                if string.lower(player.DisplayName) == string.lower(name) then
                    return player
                end
            end


            ------------------------------------------------------------
            -- USERNAME PREFIX
            ------------------------------------------------------------

            for _, player in ipairs(Players:GetPlayers()) do
                if string.sub(
                    string.lower(player.Name),
                    1,
                    #name
                ) == string.lower(name) then

                    return player
                end
            end


            ------------------------------------------------------------
            -- DISPLAY NAME PREFIX
            ------------------------------------------------------------

            for _, player in ipairs(Players:GetPlayers()) do
                if string.sub(
                    string.lower(player.DisplayName),
                    1,
                    #name
                ) == string.lower(name) then

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
                warn("[Sync] Target tidak ditemukan.")
                return false
            end

            if not target:IsDescendantOf(Players) then
                warn("[Sync] Target sudah tidak berada di Players:", target.Name)
                return false
            end

            local success, err = pcall(function()

                -- Mengikuti format RemoteEvent yang terbukti berhasil:
                local args = {
                    Players:WaitForChild(target.Name)
                }

                RequestSync:FireServer(unpack(args))

            end)

            if not success then
                warn("[Sync] RequestSync gagal:", err)
                return false
            end

            print("[Sync] Berhasil request sync ke:", target.Name)

            return true
        end


        ----------------------------------------------------------------
        -- HANDLE COMMAND
        ----------------------------------------------------------------

        local function handleCommand(sender, message)

            if not sender or not message then
                return
            end


            ------------------------------------------------------------
            -- ADMIN CHECK
            ------------------------------------------------------------

            if not Admin:IsAdmin(sender) then
                return
            end


            ------------------------------------------------------------
            -- CLEAN MESSAGE
            ------------------------------------------------------------

            message = tostring(message)

            if message == "" then
                return
            end


            ------------------------------------------------------------
            -- SPLIT COMMAND
            ------------------------------------------------------------

            local command, targetName = message:match("^(%S+)%s*(.*)$")

            if not command then
                return
            end

            command = string.lower(command)

            if targetName then
                targetName = targetName:gsub("^%s+", "")
                targetName = targetName:gsub("%s+$", "")
            end


            ------------------------------------------------------------
            -- !SYNC
            ------------------------------------------------------------

            if command == "!sync" then

                --------------------------------------------------------
                -- !sync
                -- Sync ke player yang mengirim command
                --------------------------------------------------------

                if not targetName or targetName == "" then

                    requestSync(sender)

                    return
                end


                --------------------------------------------------------
                -- !sync username/displayname
                --------------------------------------------------------

                local target = findPlayer(targetName)

                if not target then
                    warn(
                        "[Sync] Player tidak ditemukan:",
                        targetName
                    )

                    return
                end

                requestSync(target)

                return
            end
        end


        ----------------------------------------------------------------
        -- CHAT CONNECTION
        ----------------------------------------------------------------

        local connections = {}

        _G.BotVars.SyncConnections = connections


        ------------------------------------------------------------
        -- EXISTING PLAYERS
        ------------------------------------------------------------

        for _, player in ipairs(Players:GetPlayers()) do

            connections[player] = player.Chatted:Connect(function(message)

                handleCommand(player, message)

            end)

        end


        ------------------------------------------------------------
        -- NEW PLAYERS
        ------------------------------------------------------------

        connections.PlayerAdded = Players.PlayerAdded:Connect(function(player)

            if connections[player] then
                connections[player]:Disconnect()
                connections[player] = nil
            end

            connections[player] = player.Chatted:Connect(function(message)

                handleCommand(player, message)

            end)

        end)


        ------------------------------------------------------------
        -- PLAYER REMOVING
        ------------------------------------------------------------

        connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)

            if connections[player] then
                connections[player]:Disconnect()
                connections[player] = nil
            end

        end)


        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print("[Sync] Loaded successfully.")
        print("[Sync] !sync")
        print("[Sync] !sync username/displayname")

    end
}