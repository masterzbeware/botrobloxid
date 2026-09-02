
-- Commands/Follow.lua
-- Admin-only follow system
-- Bot formation: FRONT -> BACK
-- Bot berjalan mengikuti Admin
-- Saat sampai posisi, bot berhenti dan menghadap sama dengan Admin
-- Supports: !follow / !follow <username|displayname>

return {
    Execute = function()

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TextChatService = game:GetService("TextChatService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            return
        end

        ----------------------------------------------------------------
        -- LOAD ADMIN MODULE
        ----------------------------------------------------------------

        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        ----------------------------------------------------------------
        -- LOAD DISTANCE MODULE
        ----------------------------------------------------------------

        local Distance = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
        ))()

        ----------------------------------------------------------------
        -- VARIABLES
        ----------------------------------------------------------------

        local humanoid
        local myHRP

        local following = false
        local targetPlayer
        local followConnection

        ----------------------------------------------------------------
        -- DISTANCE CONFIG
        ----------------------------------------------------------------

        local adminFollowDistance = 3
        local defaultBotFollowDistance = 2

        ----------------------------------------------------------------
        -- FORMATION CONFIG
        ----------------------------------------------------------------

        -- Mulai bergerak jika jarak lebih dari ini
        local moveThreshold = 2

        -- Di bawah jarak ini bot dianggap sudah sampai
        local stopThreshold = 1.5

        ----------------------------------------------------------------
        -- BOT ORDER
        -- FRONT -> BACK
        ----------------------------------------------------------------

        local botOrder = {

            "11611503633", -- Bot 1
            "11611534165", -- Bot 2
            "11611567975", -- Bot 3
            "11611562042", -- Bot 4
            "11611591921", -- Bot 5
            "11122806815", -- Bot 6
            "11122806817", -- Bot 7
            "11122687468", -- Bot 8
            "11122854402", -- Bot 9

        }

        ----------------------------------------------------------------
        -- UPDATE CHARACTER
        ----------------------------------------------------------------

        local function updateCharacter()

            local char =
                LocalPlayer.Character
                or LocalPlayer.CharacterAdded:Wait()

            humanoid = char:WaitForChild("Humanoid")
            myHRP = char:WaitForChild("HumanoidRootPart")

            -- Default kembali aktif setelah respawn
            humanoid.AutoRotate = true

        end

        updateCharacter()

        ----------------------------------------------------------------
        -- CHARACTER RESPAWN
        ----------------------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(function()

            -- Hentikan connection lama
            if followConnection then

                followConnection:Disconnect()
                followConnection = nil

            end

            updateCharacter()

            -- Kalau sebelumnya sedang follow,
            -- follow akan dijalankan kembali
            if targetPlayer and following then

                task.wait(1)

                if targetPlayer then
                    startFollow(targetPlayer)
                end

            end

        end)

        ----------------------------------------------------------------
        -- SEND CHAT
        ----------------------------------------------------------------

        local function sendChat(msg)

            local ok = false

            ------------------------------------------------------------
            -- TEXT CHAT
            ------------------------------------------------------------

            if TextChatService
                and TextChatService.TextChannels then

                local ch =
                    TextChatService.TextChannels:FindFirstChild("RBXGeneral")

                if ch then

                    pcall(function()
                        ch:SendAsync(msg)
                    end)

                    ok = true

                end

            end

            ------------------------------------------------------------
            -- LEGACY CHAT FALLBACK
            ------------------------------------------------------------

            if not ok then

                pcall(function()

                    ReplicatedStorage
                        .DefaultChatSystemChatEvents
                        .SayMessageRequest
                        :FireServer(msg, "All")

                end)

            end

        end

        ----------------------------------------------------------------
        -- STOP FOLLOW
        ----------------------------------------------------------------

        local function stopFollow()

            following = false
            targetPlayer = nil

            if followConnection then

                followConnection:Disconnect()
                followConnection = nil

            end

            ------------------------------------------------------------
            -- KEMBALIKAN AUTOROTATE
            ------------------------------------------------------------

            if humanoid then
                humanoid.AutoRotate = true
            end

        end

        ----------------------------------------------------------------
        -- FIND PLAYER BY NAME / DISPLAY NAME
        ----------------------------------------------------------------

        local function findPlayerByName(name)

            name = name:lower()

            for _, player in ipairs(Players:GetPlayers()) do

                if player.Name:lower() == name
                    or player.DisplayName:lower() == name then

                    return player

                end

            end

            return nil

        end

        ----------------------------------------------------------------
        -- START FOLLOW
        ----------------------------------------------------------------

        local function startFollow(player)

            if not player then
                return
            end

            ------------------------------------------------------------
            -- STOP FOLLOW LAMA
            ------------------------------------------------------------

            if followConnection then

                followConnection:Disconnect()
                followConnection = nil

            end

            ------------------------------------------------------------
            -- SET TARGET
            ------------------------------------------------------------

            following = true
            targetPlayer = player

            sendChat("Yes, Sir!")

            ------------------------------------------------------------
            -- CEK BOT INDEX
            ------------------------------------------------------------

            local myIndex =
                table.find(
                    botOrder,
                    tostring(LocalPlayer.UserId)
                )

            ------------------------------------------------------------
            -- Kalau bukan Bot yang terdaftar
            ------------------------------------------------------------

            if not myIndex then

                following = false
                targetPlayer = nil

                return

            end

            ------------------------------------------------------------
            -- FOLLOW LOOP
            ------------------------------------------------------------

            followConnection =
                RunService.Heartbeat:Connect(function()

                    --------------------------------------------------------
                    -- VALIDASI
                    --------------------------------------------------------

                    if not following then
                        return
                    end

                    if not humanoid or not myHRP then
                        return
                    end

                    if not targetPlayer then
                        return
                    end

                    --------------------------------------------------------
                    -- TARGET CHARACTER
                    --------------------------------------------------------

                    local targetCharacter =
                        targetPlayer.Character

                    if not targetCharacter then
                        return
                    end

                    --------------------------------------------------------
                    -- TARGET HRP
                    --------------------------------------------------------

                    local hrp =
                        targetCharacter:FindFirstChild(
                            "HumanoidRootPart"
                        )

                    if not hrp then
                        return
                    end

                    --------------------------------------------------------
                    -- HITUNG DISTANCE
                    --------------------------------------------------------

                    local distance =
                        defaultBotFollowDistance

                    --------------------------------------------------------
                    -- JIKA TARGET ADALAH ADMIN
                    --------------------------------------------------------

                    if Admin:IsAdmin(targetPlayer) then

                        distance =
                            adminFollowDistance

                    end

                    --------------------------------------------------------
                    -- SPECIAL PAIR DISTANCE
                    --------------------------------------------------------

                    local special =
                        Distance:GetDistance(
                            tostring(LocalPlayer.UserId),
                            tostring(targetPlayer.UserId)
                        )

                    if special then
                        distance = special
                    end

                    --------------------------------------------------------
                    -- FORMATION POSITION
                    --
                    -- Bot 1 = distance x 1
                    -- Bot 2 = distance x 2
                    -- Bot 3 = distance x 3
                    -- dst.
                    --------------------------------------------------------

                    local offset =
                        hrp.CFrame.LookVector
                        * -(distance * myIndex)

                    local targetPosition =
                        hrp.Position + offset

                    --------------------------------------------------------
                    -- DISTANCE BOT KE FORMATION POSITION
                    --------------------------------------------------------

                    local distanceToTarget =
                        (
                            myHRP.Position
                            - targetPosition
                        ).Magnitude

                    --------------------------------------------------------
                    -- BOT MASIH JAUH
                    --------------------------------------------------------

                    if distanceToTarget > moveThreshold then

                        ----------------------------------------------------
                        -- BIARKAN HUMANOID BERJALAN
                        ----------------------------------------------------

                        humanoid.AutoRotate = true

                        humanoid:MoveTo(targetPosition)

                    --------------------------------------------------------
                    -- BOT SUDAH SAMPAI
                    --------------------------------------------------------

                    elseif distanceToTarget <= stopThreshold then

                        ----------------------------------------------------
                        -- HENTIKAN BOT
                        ----------------------------------------------------

                        humanoid:MoveTo(myHRP.Position)

                        ----------------------------------------------------
                        -- MATIKAN AUTOROTATE
                        ----------------------------------------------------

                        humanoid.AutoRotate = false

                        ----------------------------------------------------
                        -- AMBIL ROTASI ADMIN
                        ----------------------------------------------------

                        local adminRotation =
                            hrp.CFrame - hrp.Position

                        ----------------------------------------------------
                        -- PERTAHANKAN POSISI BOT
                        -- GUNAKAN ROTASI ADMIN
                        ----------------------------------------------------

                        myHRP.CFrame =
                            CFrame.new(myHRP.Position)
                            * adminRotation

                    end

                end)

        end

        ----------------------------------------------------------------
        -- COMMAND HANDLER
        ----------------------------------------------------------------

        local function handleCommand(msg, sender)

            ------------------------------------------------------------
            -- HANYA ADMIN
            ------------------------------------------------------------

            if not Admin:IsAdmin(sender) then
                return
            end

            local lower =
                msg:lower()

            ------------------------------------------------------------
            -- !FOLLOW
            ------------------------------------------------------------

            if lower == "!follow" then

                startFollow(sender)

                return

            end

            ------------------------------------------------------------
            -- !FOLLOW <NAME>
            ------------------------------------------------------------

            local targetName =
                lower:match("^!follow%s+(.+)$")

            if targetName then

                local target =
                    findPlayerByName(targetName)

                if target then

                    startFollow(target)

                end

                return

            end

            ------------------------------------------------------------
            -- !STOP
            ------------------------------------------------------------

            if lower == "!stop"
                or lower == "!unfollow" then

                stopFollow()

                return

            end

        end

        ----------------------------------------------------------------
        -- TEXT CHAT SERVICE
        ----------------------------------------------------------------

        if TextChatService
            and TextChatService.TextChannels then

            local ch =
                TextChatService.TextChannels:FindFirstChild(
                    "RBXGeneral"
                )

            if ch then

                ch.OnIncomingMessage =
                    function(message)

                        local uid =
                            message.TextSource
                            and message.TextSource.UserId

                        local sender =
                            uid
                            and Players:GetPlayerByUserId(uid)

                        if sender then

                            handleCommand(
                                message.Text,
                                sender
                            )

                        end

                    end

            end

        end

        ----------------------------------------------------------------
        -- FALLBACK CHAT
        ----------------------------------------------------------------

        for _, player in ipairs(Players:GetPlayers()) do

            player.Chatted:Connect(function(msg)

                handleCommand(
                    msg,
                    player
                )

            end)

        end

        ----------------------------------------------------------------
        -- PLAYER ADDED
        ----------------------------------------------------------------

        Players.PlayerAdded:Connect(function(player)

            player.Chatted:Connect(function(msg)

                handleCommand(
                    msg,
                    player
                )

            end)

        end)

    end
}
