return {
    Execute = function()

        --------------------------------------------------
        -- SERVICES
        --------------------------------------------------

        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer
        local PlaceId = game.PlaceId

        if not LocalPlayer then
            warn("[Sync] LocalPlayer tidak ditemukan.")
            return
        end


        --------------------------------------------------
        -- GLOBAL SYSTEM
        --------------------------------------------------

        _G.BotVars = _G.BotVars or {}


        --------------------------------------------------
        -- PREVENT DUPLICATE EXECUTE
        --------------------------------------------------

        if _G.BotVars.SyncLoaded then
            warn("[Sync] Sync.lua sudah aktif.")
            return
        end

        _G.BotVars.SyncLoaded = true


        --------------------------------------------------
        -- PLACE CONFIGURATION
        --------------------------------------------------

        local PLACE_CIDRO = 79312497897212
        local PLACE_TANPANAMA = 119031818630096


        --------------------------------------------------
        -- DETECT PLACE
        --------------------------------------------------

        local CurrentPlaceName

        if PlaceId == PLACE_CIDRO then

            CurrentPlaceName = "Cidro Janji"

        elseif PlaceId == PLACE_TANPANAMA then

            CurrentPlaceName = "TANPANAMA"

        else

            warn(
                "[Sync] Place tidak didukung.",
                "PlaceId:",
                PlaceId
            )

            _G.BotVars.SyncLoaded = false
            return
        end


        print(
            "[Sync] Place terdeteksi:",
            CurrentPlaceName,
            "(" .. tostring(PlaceId) .. ")"
        )


        --------------------------------------------------
        -- ADMIN MODULE
        --------------------------------------------------

        local Admin

        local successAdmin, resultAdmin = pcall(function()

            local url =
                "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"

            return loadstring(game:HttpGet(url))()

        end)

        if not successAdmin then

            warn(
                "[Sync] Gagal load Admin.lua:",
                resultAdmin
            )

            _G.BotVars.SyncLoaded = false
            return
        end

        Admin = resultAdmin

        if not Admin then

            warn("[Sync] Admin.lua tidak menghasilkan module.")

            _G.BotVars.SyncLoaded = false
            return
        end


        --------------------------------------------------
        -- SYNC REMOTE
        --------------------------------------------------

        local SyncRemote


        --------------------------------------------------
        -- CIDRO JANJI
        --------------------------------------------------

        if PlaceId == PLACE_CIDRO then

            local EventsFolder =
                ReplicatedStorage:WaitForChild(
                    "Events",
                    10
                )

            if not EventsFolder then

                warn(
                    "[Sync] Events tidak ditemukan."
                )

                _G.BotVars.SyncLoaded = false
                return
            end


            SyncRemote =
                EventsFolder:WaitForChild(
                    "RequestSync",
                    10
                )

            if not SyncRemote then

                warn(
                    "[Sync] RequestSync tidak ditemukan."
                )

                _G.BotVars.SyncLoaded = false
                return
            end


            print(
                "[Sync] Remote:",
                "Events.RequestSync"
            )


        --------------------------------------------------
        -- TANPANAMA
        --------------------------------------------------

        elseif PlaceId == PLACE_TANPANAMA then

            local EventsFolder =
                ReplicatedStorage:WaitForChild(
                    "Events",
                    10
                )

            if not EventsFolder then

                warn(
                    "[Sync] Events tidak ditemukan."
                )

                _G.BotVars.SyncLoaded = false
                return
            end


            local DanceFolder =
                EventsFolder:WaitForChild(
                    "Dance",
                    10
                )

            if not DanceFolder then

                warn(
                    "[Sync] Events.Dance tidak ditemukan."
                )

                _G.BotVars.SyncLoaded = false
                return
            end


            SyncRemote =
                DanceFolder:WaitForChild(
                    "startSync",
                    10
                )

            if not SyncRemote then

                warn(
                    "[Sync] startSync tidak ditemukan."
                )

                _G.BotVars.SyncLoaded = false
                return
            end


            print(
                "[Sync] Remote:",
                "Events.Dance.startSync"
            )

        end


        --------------------------------------------------
        -- CHECK REMOTE
        --------------------------------------------------

        if not SyncRemote then

            warn(
                "[Sync] Sync remote tidak tersedia."
            )

            _G.BotVars.SyncLoaded = false
            return
        end


        if not SyncRemote:IsA("RemoteEvent") then

            warn(
                "[Sync] Object sync bukan RemoteEvent:",
                SyncRemote.ClassName
            )

            _G.BotVars.SyncLoaded = false
            return
        end


        --------------------------------------------------
        -- FIND PLAYER
        --------------------------------------------------

        local function findPlayer(name)

            if not name or name == "" then
                return nil
            end

            name = tostring(name)

            local lowerName =
                string.lower(name)


            --------------------------------------------------
            -- EXACT USERNAME
            --------------------------------------------------

            for _, player in ipairs(
                Players:GetPlayers()
            ) do

                if string.lower(player.Name)
                    == lowerName then

                    return player
                end
            end


            --------------------------------------------------
            -- EXACT DISPLAY NAME
            --------------------------------------------------

            for _, player in ipairs(
                Players:GetPlayers()
            ) do

                if string.lower(player.DisplayName)
                    == lowerName then

                    return player
                end
            end


            --------------------------------------------------
            -- USERNAME PREFIX
            --------------------------------------------------

            for _, player in ipairs(
                Players:GetPlayers()
            ) do

                if string.sub(
                    string.lower(player.Name),
                    1,
                    #name
                ) == lowerName then

                    return player
                end
            end


            --------------------------------------------------
            -- DISPLAY NAME PREFIX
            --------------------------------------------------

            for _, player in ipairs(
                Players:GetPlayers()
            ) do

                if string.sub(
                    string.lower(player.DisplayName),
                    1,
                    #name
                ) == lowerName then

                    return player
                end
            end


            return nil
        end


        --------------------------------------------------
        -- REQUEST SYNC
        --------------------------------------------------

        local function requestSync(target)

            if not target then

                warn(
                    "[Sync] Target tidak ditemukan."
                )

                return false
            end


            if not target:IsDescendantOf(Players) then

                warn(
                    "[Sync] Target sudah tidak berada di Players:",
                    target.Name
                )

                return false
            end


            local success, err =
                pcall(function()


                    --------------------------------------------------
                    -- CIDRO JANJI
                    --------------------------------------------------

                    if PlaceId == PLACE_CIDRO then

                        SyncRemote:FireServer(
                            target
                        )


                    --------------------------------------------------
                    -- TANPANAMA
                    --------------------------------------------------

                    elseif PlaceId == PLACE_TANPANAMA then

                        SyncRemote:FireServer(
                            target,
                            true
                        )

                    end

                end)


            if not success then

                warn(
                    "[Sync] Request sync gagal:",
                    err
                )

                return false
            end


            print(
                "[Sync] Sync berhasil.",
                "Place:",
                CurrentPlaceName,
                "Target:",
                target.Name
            )

            return true
        end


        --------------------------------------------------
        -- HANDLE COMMAND
        --------------------------------------------------

        local function handleCommand(
            sender,
            message
        )

            if not sender or not message then
                return
            end


            --------------------------------------------------
            -- ADMIN CHECK
            --------------------------------------------------

            if not Admin:IsAdmin(sender) then
                return
            end


            --------------------------------------------------
            -- CLEAN MESSAGE
            --------------------------------------------------

            message = tostring(message)

            if message == "" then
                return
            end


            --------------------------------------------------
            -- SPLIT COMMAND
            --------------------------------------------------

            local command, targetName =
                message:match(
                    "^(%S+)%s*(.*)$"
                )

            if not command then
                return
            end


            command =
                string.lower(command)


            --------------------------------------------------
            -- CLEAN TARGET
            --------------------------------------------------

            if targetName then

                targetName =
                    targetName:gsub(
                        "^%s+",
                        ""
                    )

                targetName =
                    targetName:gsub(
                        "%s+$",
                        ""
                    )

            end


            --------------------------------------------------
            -- !SYNC
            --------------------------------------------------

            if command == "!sync" then


                --------------------------------------------------
                -- !sync
                -- Sync ke sender
                --------------------------------------------------

                if not targetName
                    or targetName == "" then

                    requestSync(sender)

                    return
                end


                --------------------------------------------------
                -- !sync username
                --------------------------------------------------

                local target =
                    findPlayer(targetName)


                if not target then

                    warn(
                        "[Sync] Player tidak ditemukan:",
                        targetName
                    )

                    return
                end


                --------------------------------------------------
                -- EXECUTE
                --------------------------------------------------

                requestSync(target)

                return
            end
        end


        --------------------------------------------------
        -- CHAT CONNECTIONS
        --------------------------------------------------

        local connections = {}

        _G.BotVars.SyncConnections =
            connections


        --------------------------------------------------
        -- EXISTING PLAYERS
        --------------------------------------------------

        for _, player in ipairs(
            Players:GetPlayers()
        ) do

            connections[player] =
                player.Chatted:Connect(
                    function(message)

                        handleCommand(
                            player,
                            message
                        )

                    end
                )

        end


        --------------------------------------------------
        -- NEW PLAYERS
        --------------------------------------------------

        connections.PlayerAdded =
            Players.PlayerAdded:Connect(
                function(player)

                    if connections[player] then

                        connections[player]:Disconnect()

                        connections[player] = nil
                    end


                    connections[player] =
                        player.Chatted:Connect(
                            function(message)

                                handleCommand(
                                    player,
                                    message
                                )

                            end
                        )

                end
            )


        --------------------------------------------------
        -- PLAYER REMOVING
        --------------------------------------------------

        connections.PlayerRemoving =
            Players.PlayerRemoving:Connect(
                function(player)

                    if connections[player] then

                        connections[player]:Disconnect()

                        connections[player] = nil
                    end

                end
            )


        --------------------------------------------------
        -- GLOBAL INFO
        --------------------------------------------------

        _G.BotVars.SyncPlace =
            CurrentPlaceName

        _G.BotVars.SyncPlaceId =
            PlaceId

        _G.BotVars.SyncRemote =
            SyncRemote


        --------------------------------------------------
        -- READY
        --------------------------------------------------

        print("----------------------------------------")
        print("[Sync] Loaded successfully.")
        print("[Sync] Place:", CurrentPlaceName)
        print("[Sync] PlaceId:", PlaceId)
        print("[Sync] Remote:", SyncRemote:GetFullName())
        print("[Sync] Command: !sync")
        print("[Sync] Command: !sync username/displayname")
        print("----------------------------------------")

    end
}