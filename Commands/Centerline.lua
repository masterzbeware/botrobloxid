-- Centerline.lua
-- Formasi horizontal dengan Admin/Player berada di tengah.
--
-- Formasi:
-- B1 B2 B3 B4 B5  A  B6 B7 B8 B9 B10 B11 B12
--
-- Jarak:
-- Bot 5 ke A = 2 stud
-- A ke Bot 6 = 2 stud
-- Jarak antarbot pada sisi yang sama = 3 stud
--
-- Command:
-- !centerline
-- !centerline <player>
-- !stop
-- !uncenterline

return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TextChatService = game:GetService("TextChatService")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[Centerline] LocalPlayer tidak ditemukan.")
            return
        end

        ----------------------------------------------------------------
        -- CONFIGURATION
        ----------------------------------------------------------------

        local formationSpacing = 3
        local centerDistance = 2
        local arrivalTolerance = 1.5
        local moveUpdateInterval = 0.2

        ----------------------------------------------------------------
        -- BOT ORDER
        -- Slot bot selalu mengikuti UserId, bukan urutan bot aktif.
        ----------------------------------------------------------------

        local botOrder = {
            "11611503633", -- Bot 1
            "11611591921", -- Bot 2
            "11611597741", -- Bot 3
            "11672413029", -- Bot 4
            "11122806815", -- Bot 5
            "11122806817", -- Bot 6
            "11122687468", -- Bot 7
            "11122854402", -- Bot 8
            "11774472805", -- Bot 9
            "11774494628", -- Bot 10
            "11775829997", -- Bot 11
            "11775843339", -- Bot 12
        }

        ----------------------------------------------------------------
        -- ADMIN MODULE
        ----------------------------------------------------------------

        local Admin

        local success, result = pcall(function()
            return loadstring(game:HttpGet(
                "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
            ))()
        end)

        if success then
            Admin = result
        else
            warn("[Centerline] Gagal memuat Admin.lua:", result)
        end

        ----------------------------------------------------------------
        -- STATE
        ----------------------------------------------------------------

        local running = false
        local heartbeatConnection = nil
        local characterConnection = nil
        local textChatConnection = nil
        local playerChatConnections = {}

        local targetPlayer = nil
        local lastMoveUpdate = 0
        local restartToken = 0

        ----------------------------------------------------------------
        -- CHARACTER HELPERS
        ----------------------------------------------------------------

        local function getCharacter(player)
            if not player then
                return nil
            end

            return player.Character
        end

        local function getHumanoid(player)
            local character = getCharacter(player)

            if not character then
                return nil
            end

            return character:FindFirstChildOfClass("Humanoid")
        end

        local function getRootPart(player)
            local character = getCharacter(player)

            if not character then
                return nil
            end

            return character:FindFirstChild("HumanoidRootPart")
        end

        ----------------------------------------------------------------
        -- BOT SLOT
        ----------------------------------------------------------------

        local function getBotIndex()
            return table.find(botOrder, tostring(LocalPlayer.UserId))
        end

        ----------------------------------------------------------------
        -- ADMIN PERMISSION
        ----------------------------------------------------------------

        local function isAdmin(player)
            if not player then
                return false
            end

            -- Admin utama yang ditetapkan dalam Admin.lua.
            if Admin then
                local successMain, isMain = pcall(function()
                    return Admin:IsMainAdmin(player)
                end)

                if successMain and isMain then
                    return true
                end

                local successAdmin, allowed = pcall(function()
                    return Admin:IsAdmin(player)
                end)

                if successAdmin and allowed then
                    return true
                end

                -- Dukungan whitelist Admin.lua.
                if type(Admin.AllowedUsers) == "table" then
                    if Admin.AllowedUsers[player.UserId] then
                        return true
                    end

                    if Admin.AllowedUsers[tostring(player.UserId)] then
                        return true
                    end
                end
            end

            -- Dukungan admin tambahan dari sistem bot.
            local botVars = _G.BotVars

            if botVars and type(botVars.AdditionalAdmins) == "table" then
                local additionalAdmins = botVars.AdditionalAdmins

                if additionalAdmins[player.UserId]
                    or additionalAdmins[tostring(player.UserId)]
                    or additionalAdmins[player.Name]
                    or additionalAdmins[player.Name:lower()] then
                    return true
                end

                for key, value in pairs(additionalAdmins) do
                    if value == player.UserId
                        or tostring(value) == tostring(player.UserId)
                        or (type(value) == "string"
                            and value:lower() == player.Name:lower())
                        or (type(key) == "string"
                            and key:lower() == player.Name:lower()
                            and value) then
                        return true
                    end
                end
            end

            return false
        end

        ----------------------------------------------------------------
        -- PLAYER LOOKUP
        ----------------------------------------------------------------

        local function findPlayerByName(name)
            if not name or name == "" then
                return nil
            end

            local search = name:lower()

            -- Prioritaskan kecocokan nama lengkap.
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Name:lower() == search
                    or player.DisplayName:lower() == search then
                    return player
                end
            end

            -- Jika tidak ada kecocokan penuh, cari awalan nama.
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Name:lower():sub(1, #search) == search
                    or player.DisplayName:lower():sub(1, #search) == search then
                    return player
                end
            end

            return nil
        end

        ----------------------------------------------------------------
        -- CHAT HELPER
        ----------------------------------------------------------------

        local function sendChat(message)
            local successChat = pcall(function()
                local channels = TextChatService:FindFirstChild("TextChannels")

                if not channels then
                    return
                end

                local channel = channels:FindFirstChild("RBXGeneral")

                if channel then
                    channel:SendAsync(message)
                end
            end)

            if not successChat then
                warn("[Centerline] Pesan chat gagal dikirim.")
            end
        end

        ----------------------------------------------------------------
        -- STOP CENTERLINE
        ----------------------------------------------------------------

        local function stopCenterline()
            running = false
            restartToken += 1

            if heartbeatConnection then
                heartbeatConnection:Disconnect()
                heartbeatConnection = nil
            end

            targetPlayer = nil

            local humanoid = getHumanoid(LocalPlayer)

            if humanoid then
                humanoid:Move(Vector3.zero, false)
            end

            local botVars = _G.BotVars

            if botVars then
                if botVars.ModeControllers
                    and botVars.ModeControllers.centerline then
                    botVars.ModeControllers.centerline = nil
                end

                if botVars.ActiveMode == "centerline" then
                    botVars.ActiveMode = nil
                end
            end

            print("[Centerline] Mode dihentikan.")
        end

        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()
            local botVars = _G.BotVars

            if not botVars or type(botVars.ModeControllers) ~= "table" then
                return
            end

            for modeName, stopFunction in pairs(botVars.ModeControllers) do
                if modeName ~= "centerline" and type(stopFunction) == "function" then
                    local successStop, err = pcall(stopFunction)

                    if not successStop then
                        warn(
                            "[Centerline] Gagal menghentikan mode "
                                .. tostring(modeName) .. ": " .. tostring(err)
                        )
                    end
                end
            end
        end

        ----------------------------------------------------------------
        -- FORMATION OFFSET
        ----------------------------------------------------------------

        local function getHorizontalOffset(botIndex)
            if botIndex <= 5 then
                -- B5 = -2, B4 = -5, B3 = -8, B2 = -11, B1 = -14.
                return -centerDistance
                    - ((5 - botIndex) * formationSpacing)
            else
                -- B6 = +2, B7 = +5, B8 = +8, dan seterusnya.
                return centerDistance
                    + ((botIndex - 6) * formationSpacing)
            end
        end

        ----------------------------------------------------------------
        -- START CENTERLINE
        ----------------------------------------------------------------

        local function startCenterline(newTarget)
            if not newTarget then
                warn("[Centerline] Target tidak ditemukan.")
                return
            end

            local botIndex = getBotIndex()

            if not botIndex then
                warn(
                    "[Centerline] UserId bot tidak ada dalam botOrder: "
                        .. tostring(LocalPlayer.UserId)
                )
                return
            end

            if newTarget == LocalPlayer then
                warn("[Centerline] Bot tidak dapat menjadi target dirinya sendiri.")
                return
            end

            stopCenterline()
            stopOtherModes()

            targetPlayer = newTarget
            running = true
            lastMoveUpdate = 0

            local botVars = _G.BotVars

            if botVars then
                botVars.ModeControllers = botVars.ModeControllers or {}
                botVars.ModeControllers.centerline = stopCenterline
                botVars.ActiveMode = "centerline"
                botVars.CommandTarget = newTarget
            end

            local thisRestartToken = restartToken

            print(
                "[Centerline] Aktif | Bot "
                    .. tostring(botIndex)
                    .. " | Target: "
                    .. newTarget.Name
                    .. " | Offset: "
                    .. tostring(getHorizontalOffset(botIndex))
            )

            ----------------------------------------------------------------
            -- HEARTBEAT
            ----------------------------------------------------------------

            heartbeatConnection = RunService.Heartbeat:Connect(function()
                if not running or restartToken ~= thisRestartToken then
                    return
                end

                if not targetPlayer or not targetPlayer.Parent then
                    stopCenterline()
                    return
                end

                local currentBotIndex = getBotIndex()

                if not currentBotIndex then
                    stopCenterline()
                    return
                end

                local botCharacter = getCharacter(LocalPlayer)
                local botHumanoid = getHumanoid(LocalPlayer)
                local botRoot = getRootPart(LocalPlayer)

                local targetCharacter = getCharacter(targetPlayer)
                local targetHumanoid = getHumanoid(targetPlayer)
                local targetRoot = getRootPart(targetPlayer)

                if not botCharacter
                    or not botHumanoid
                    or not botRoot
                    or botHumanoid.Health <= 0 then
                    return
                end

                if not targetCharacter
                    or not targetHumanoid
                    or not targetRoot
                    or targetHumanoid.Health <= 0 then
                    return
                end

                local horizontalOffset = getHorizontalOffset(currentBotIndex)

                -- Posisi target mengikuti arah kanan/kiri target.
                -- Ketinggian bot disamakan dengan target.
                local targetPosition =
                    targetRoot.Position
                    + (targetRoot.CFrame.RightVector * horizontalOffset)

                targetPosition = Vector3.new(
                    targetPosition.X,
                    targetRoot.Position.Y,
                    targetPosition.Z
                )

                local currentTime = os.clock()

                if currentTime - lastMoveUpdate >= moveUpdateInterval then
                    lastMoveUpdate = currentTime

                    local distance = (botRoot.Position - targetPosition).Magnitude

                    if distance > arrivalTolerance then
                        botHumanoid:MoveTo(targetPosition)
                    else
                        botHumanoid:Move(Vector3.zero, false)
                    end
                end

                -- Arah hadap bot mengikuti arah hadap target.
                -- Posisi bot dipertahankan agar gerakan tidak tertimpa.
                local lookVector = targetRoot.CFrame.LookVector

                local flatLookVector = Vector3.new(
                    lookVector.X,
                    0,
                    lookVector.Z
                )

                if flatLookVector.Magnitude > 0.001 then
                    botRoot.CFrame = CFrame.lookAt(
                        botRoot.Position,
                        botRoot.Position + flatLookVector
                    )
                end
            end)
        end

        ----------------------------------------------------------------
        -- COMMAND HANDLER
        ----------------------------------------------------------------

        local function handleCommand(sender, message)
            if not sender or type(message) ~= "string" then
                return
            end

            local command, argument = message:match("^%s*(%S+)%s*(.-)%s*$")

            if not command then
                return
            end

            command = command:lower()

            if command ~= "!centerline"
                and command ~= "!stop"
                and command ~= "!uncenterline" then
                return
            end

            if not isAdmin(sender) then
                return
            end

            if command == "!stop" or command == "!uncenterline" then
                if running then
                    stopCenterline()
                    print("[Centerline] Dihentikan oleh " .. sender.Name)
                end

                return
            end

            -- !centerline <player> menggunakan player yang disebutkan.
            -- !centerline tanpa argumen menggunakan pengirim command.
            local selectedTarget

            if argument and argument ~= "" then
                selectedTarget = findPlayerByName(argument)

                if not selectedTarget then
                    warn("[Centerline] Player tidak ditemukan: " .. argument)
                    return
                end
            else
                selectedTarget = sender
            end

            startCenterline(selectedTarget)
        end

        ----------------------------------------------------------------
        -- CHAT CONNECTIONS
        ----------------------------------------------------------------

        local function connectPlayerChat(player)
            if playerChatConnections[player] then
                return
            end

            playerChatConnections[player] = player.Chatted:Connect(function(message)
                handleCommand(player, message)
            end)
        end

        for _, player in ipairs(Players:GetPlayers()) do
            connectPlayerChat(player)
        end

        Players.PlayerAdded:Connect(connectPlayerChat)

        Players.PlayerRemoving:Connect(function(player)
            local connection = playerChatConnections[player]

            if connection then
                connection:Disconnect()
                playerChatConnections[player] = nil
            end

            if targetPlayer == player then
                stopCenterline()
            end
        end)

        -- TextChatService: menangani pesan dari chat modern.
        textChatConnection = TextChatService.MessageReceived:Connect(function(textChatMessage)
            local textSource = textChatMessage.TextSource

            if not textSource then
                return
            end

            local sender = Players:GetPlayerByUserId(textSource.UserId)

            if sender then
                handleCommand(sender, textChatMessage.Text)
            end
        end)

        ----------------------------------------------------------------
        -- RESPAWN HANDLER
        ----------------------------------------------------------------

        characterConnection = LocalPlayer.CharacterAdded:Connect(function()
            if not running then
                return
            end

            local savedTarget = targetPlayer

            task.wait(1)

            if running and savedTarget and savedTarget.Parent then
                startCenterline(savedTarget)
            end
        end)

        ----------------------------------------------------------------
        -- REGISTER MODE CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars = _G.BotVars or {}
        _G.BotVars.ModeControllers = _G.BotVars.ModeControllers or {}
        _G.BotVars.ModeControllers.centerline = stopCenterline

        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print("[Centerline] Loaded successfully.")
        print("[Centerline] Jarak Bot 5/A dan A/Bot 6: 2 stud.")
        print("[Centerline] Jarak antarbot pada sisi yang sama: 3 stud.")

    end
}