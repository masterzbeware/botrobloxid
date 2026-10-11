-- Circle.lua
-- MasterZ HUB
-- Dynamic circle formation
-- Menghitung ulang formasi berdasarkan bot yang masih online.
-- Jika 10 bot menjadi 8 bot, lingkaran tetap terbentuk penuh.

return {
    Execute = function()

        --------------------------------------------------
        -- SERVICES
        --------------------------------------------------

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TextChatService = game:GetService("TextChatService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[Circle] LocalPlayer tidak ditemukan.")
            return
        end

        --------------------------------------------------
        -- GLOBAL MODE SYSTEM
        --------------------------------------------------

        _G.BotVars = _G.BotVars or {}

        local vars = _G.BotVars

        vars.ModeControllers = vars.ModeControllers or {}

        --------------------------------------------------
        -- LOAD ADMIN
        --------------------------------------------------

        local Admin

        local adminOk, adminResult = pcall(function()
            local source = game:HttpGet(
                "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
            )

            local loader, compileError = loadstring(source)

            if not loader then
                error(compileError)
            end

            return loader()
        end)

        if not adminOk or not adminResult then
            warn("[Circle] Gagal memuat Admin.lua:", adminResult)
            return
        end

        Admin = adminResult

        --------------------------------------------------
        -- LOAD DISTANCE
        --------------------------------------------------

        local Distance

        local distanceOk, distanceResult = pcall(function()
            local source = game:HttpGet(
                "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
            )

            local loader, compileError = loadstring(source)

            if not loader then
                error(compileError)
            end

            return loader()
        end)

        if not distanceOk or not distanceResult then
            warn(
                "[Circle] Gagal memuat Distance.lua:",
                distanceResult
            )
            return
        end

        Distance = distanceResult

        --------------------------------------------------
        -- VARIABLES
        --------------------------------------------------

        local humanoid
        local myHRP

        local circling = false
        local targetPlayer = nil
        local circleConnection = nil

        --------------------------------------------------
        -- FORMATION DISTANCE
        --------------------------------------------------

        local adminCircleDistance = 6
        local defaultBotCircleDistance = 6

        --------------------------------------------------
        -- BOT ORDER
        --------------------------------------------------
        -- Urutan prioritas bot.
        -- Bot yang disconnect otomatis dilewati.
        -- Urutan relatif bot yang tersisa tetap konsisten.

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
        }

        --------------------------------------------------
        -- DYNAMIC ACTIVE BOT LIST
        --------------------------------------------------
        -- Hanya bot yang masih berada di server yang dihitung.
        --
        -- Contoh:
        -- 10 bot online = 10 posisi lingkaran
        --  9 bot online =  9 posisi lingkaran
        --  8 bot online =  8 posisi lingkaran
        --
        -- Karakter yang sedang respawn tetap diperhitungkan
        -- selama Player masih berada di server.

        local function getActiveBotOrder()
            local activeBots = {}

            for _, userId in ipairs(botOrder) do
                local numericUserId = tonumber(userId)

                if numericUserId then
                    local player =
                        Players:GetPlayerByUserId(numericUserId)

                    if player then
                        table.insert(
                            activeBots,
                            tostring(player.UserId)
                        )
                    end
                end
            end

            return activeBots
        end

        --------------------------------------------------
        -- UPDATE CHARACTER
        --------------------------------------------------

        local function updateCharacter()
            local character =
                LocalPlayer.Character
                or LocalPlayer.CharacterAdded:Wait()

            humanoid =
                character:WaitForChild("Humanoid")

            myHRP =
                character:WaitForChild("HumanoidRootPart")

            humanoid.AutoRotate = true
        end

        updateCharacter()

        --------------------------------------------------
        -- SEND CHAT
        --------------------------------------------------

        local function sendChat(message)
            local success = false

            if TextChatService
                and TextChatService.TextChannels then

                local channel =
                    TextChatService.TextChannels:FindFirstChild(
                        "RBXGeneral"
                    )

                if channel then
                    local ok = pcall(function()
                        channel:SendAsync(message)
                    end)

                    success = ok
                end
            end

            if not success then
                pcall(function()
                    local chatEvents =
                        ReplicatedStorage:FindFirstChild(
                            "DefaultChatSystemChatEvents"
                        )

                    local sayMessageRequest =
                        chatEvents
                        and chatEvents:FindFirstChild(
                            "SayMessageRequest"
                        )

                    if sayMessageRequest then
                        sayMessageRequest:FireServer(
                            message,
                            "All"
                        )
                    end
                end)
            end
        end

        --------------------------------------------------
        -- STOP CIRCLE
        --------------------------------------------------

        local function stopCircle()
            circling = false
            targetPlayer = nil

            if circleConnection then
                circleConnection:Disconnect()
                circleConnection = nil
            end

            if humanoid then
                humanoid.AutoRotate = true
            end
        end

        --------------------------------------------------
        -- REGISTER CONTROLLER
        --------------------------------------------------

        vars.ModeControllers.circle = stopCircle

        --------------------------------------------------
        -- STOP OTHER MODES
        --------------------------------------------------

        local function stopOtherModes()
            for name, stopFunction in pairs(
                vars.ModeControllers
            ) do
                if name ~= "circle"
                    and type(stopFunction) == "function" then

                    pcall(stopFunction)
                end
            end
        end

        --------------------------------------------------
        -- FIND PLAYER
        --------------------------------------------------

        local function findPlayerByName(name)
            if not name or name == "" then
                return nil
            end

            name = name:lower()

            -- Exact username / display name
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Name:lower() == name
                    or player.DisplayName:lower() == name then

                    return player
                end
            end

            -- Username prefix
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Name:lower():sub(1, #name) == name then
                    return player
                end
            end

            -- Display name prefix
            for _, player in ipairs(Players:GetPlayers()) do
                if player.DisplayName:lower():sub(1, #name) == name then
                    return player
                end
            end

            return nil
        end

        --------------------------------------------------
        -- START CIRCLE
        --------------------------------------------------

        local function startCircle(player)
            if not player then
                return
            end

            --------------------------------------------------
            -- VALIDATE TARGET
            --------------------------------------------------

            if not player:IsDescendantOf(Players) then
                warn("[Circle] Target tidak berada di server.")
                return
            end

            --------------------------------------------------
            -- STOP OTHER MODES
            --------------------------------------------------

            stopOtherModes()

            --------------------------------------------------
            -- SET ACTIVE MODE
            --------------------------------------------------

            vars.ActiveMode = "circle"

            --------------------------------------------------
            -- STOP OLD CONNECTION
            --------------------------------------------------

            if circleConnection then
                circleConnection:Disconnect()
                circleConnection = nil
            end

            --------------------------------------------------
            -- SET TARGET
            --------------------------------------------------

            circling = true
            targetPlayer = player
            vars.CommandTarget = player

            --------------------------------------------------
            -- DISPLAY ACTIVE BOT COUNT
            --------------------------------------------------

            local activeBots = getActiveBotOrder()

            print(
                "[Circle] Target:",
                player.Name
            )

            print(
                "[Circle] Bot online:",
                #activeBots,
                "dari",
                #botOrder
            )

            if #activeBots == 0 then
                warn("[Circle] Tidak ada bot yang terdaftar dan online.")
                stopCircle()
                return
            end

            --------------------------------------------------
            -- VALIDATE LOCAL BOT
            --------------------------------------------------

            local myIndex =
                table.find(
                    activeBots,
                    tostring(LocalPlayer.UserId)
                )

            if not myIndex then
                warn(
                    "[Circle] Bot ini tidak terdaftar dalam daftar bot aktif:",
                    LocalPlayer.Name
                )

                stopCircle()
                return
            end

            --------------------------------------------------
            -- CHAT CONFIRMATION
            --------------------------------------------------

            sendChat("Yes, Sir!")

            --------------------------------------------------
            -- CIRCLE LOOP
            --------------------------------------------------

            circleConnection =
                RunService.Heartbeat:Connect(function()

                    --------------------------------------------------
                    -- VALIDATE MODE
                    --------------------------------------------------

                    if vars.ActiveMode ~= "circle" then
                        stopCircle()
                        return
                    end

                    if not circling then
                        return
                    end

                    if not humanoid
                        or not myHRP
                        or not myHRP.Parent then

                        return
                    end

                    if not targetPlayer
                        or not targetPlayer:IsDescendantOf(Players) then

                        return
                    end

                    --------------------------------------------------
                    -- TARGET CHARACTER
                    --------------------------------------------------

                    local targetCharacter =
                        targetPlayer.Character

                    if not targetCharacter then
                        return
                    end

                    local targetHRP =
                        targetCharacter:FindFirstChild(
                            "HumanoidRootPart"
                        )

                    if not targetHRP then
                        return
                    end

                    --------------------------------------------------
                    -- RECALCULATE ACTIVE BOTS
                    --------------------------------------------------
                    -- Penting:
                    -- Hitung ulang setiap update sehingga ketika bot
                    -- disconnect, posisi bot yang tersisa bergeser
                    -- menjadi lingkaran baru tanpa celah.
                    --------------------------------------------------

                    local currentActiveBots =
                        getActiveBotOrder()

                    local totalBots =
                        #currentActiveBots

                    if totalBots == 0 then
                        return
                    end

                    local currentIndex =
                        table.find(
                            currentActiveBots,
                            tostring(LocalPlayer.UserId)
                        )

                    if not currentIndex then
                        -- Bot tidak lagi terdeteksi dalam daftar aktif.
                        return
                    end

                    --------------------------------------------------
                    -- CIRCLE RADIUS
                    --------------------------------------------------

                    local radius =
                        defaultBotCircleDistance

                    local targetIsAdmin = false

                    pcall(function()
                        targetIsAdmin =
                            Admin:IsAdmin(targetPlayer)
                    end)

                    if targetIsAdmin then
                        radius = adminCircleDistance
                    end

                    local specialDistance =
                        Distance:GetDistance(
                            tostring(LocalPlayer.UserId),
                            tostring(targetPlayer.UserId)
                        )

                    if specialDistance then
                        radius = specialDistance
                    end

                    --------------------------------------------------
                    -- RECALCULATE ANGLE
                    --------------------------------------------------
                    -- Angle menggunakan jumlah bot AKTIF, bukan
                    -- jumlah bot yang terdaftar di botOrder.
                    --
                    -- 8 bot  = 360 / 8 = 45 derajat
                    -- 9 bot  = 360 / 9 = 40 derajat
                    -- 10 bot = 360 / 10 = 36 derajat
                    --------------------------------------------------

                    local angle =
                        ((currentIndex - 1) / totalBots)
                        * math.pi * 2

                    local forward =
                        targetHRP.CFrame.LookVector

                    local right =
                        targetHRP.CFrame.RightVector

                    local offset =
                        (forward * math.cos(angle))
                        +
                        (right * math.sin(angle))

                    local targetPosition =
                        targetHRP.Position
                        +
                        (offset * radius)

                    --------------------------------------------------
                    -- DISTANCE TO POSITION
                    --------------------------------------------------

                    local distanceToTarget =
                        (
                            myHRP.Position
                            -
                            targetPosition
                        ).Magnitude

                    --------------------------------------------------
                    -- MOVE BOT
                    --------------------------------------------------

                    if distanceToTarget > 1.5 then
                        humanoid.AutoRotate = true

                        humanoid:MoveTo(
                            targetPosition
                        )

                        return
                    end

                    --------------------------------------------------
                    -- FACE CENTER
                    --------------------------------------------------

                    humanoid.AutoRotate = false

                    local lookPosition =
                        Vector3.new(
                            targetHRP.Position.X,
                            myHRP.Position.Y,
                            targetHRP.Position.Z
                        )

                    if (lookPosition - myHRP.Position).Magnitude > 0.01 then
                        myHRP.CFrame =
                            CFrame.lookAt(
                                myHRP.Position,
                                lookPosition
                            )
                    end
                end)
        end

        --------------------------------------------------
        -- HANDLE COMMAND
        --------------------------------------------------

        local function handleCommand(message, sender)
            if not message or not sender then
                return
            end

            --------------------------------------------------
            -- ADMIN CHECK
            --------------------------------------------------

            local isAdmin = false

            pcall(function()
                isAdmin = Admin:IsAdmin(sender)
            end)

            local lower =
                message:lower()
                :gsub("^%s+", "")
                :gsub("%s+$", "")

            local commandTarget =
                vars.CommandTarget

            --------------------------------------------------
            -- !STOP / !UNCIRCLE
            --------------------------------------------------

            if lower == "!stop"
                or lower == "!uncircle" then

                if not isAdmin then
                    return
                end

                vars.ActiveMode = nil
                vars.CommandTarget = nil

                for _, stopFunction in pairs(
                    vars.ModeControllers
                ) do
                    if type(stopFunction) == "function" then
                        pcall(stopFunction)
                    end
                end

                print("[Circle] Semua mode dihentikan oleh admin.")
                return
            end

            --------------------------------------------------
            -- !CIRCLE
            --------------------------------------------------

            if lower == "!circle" then
                if not isAdmin and sender ~= commandTarget then
                    return
                end

                startCircle(sender)
                return
            end

            --------------------------------------------------
            -- !CIRCLE PLAYER
            -- Only an admin can select a new target.
            --------------------------------------------------

            local targetName =
                lower:match("^!circle%s+(.+)$")

            if targetName then
                if not isAdmin then
                    return
                end

                local target =
                    findPlayerByName(targetName)

                if not target then
                    warn(
                        "[Circle] Player tidak ditemukan:",
                        targetName
                    )

                    return
                end

                startCircle(target)
                return
            end
        end

        --------------------------------------------------
        -- CHAT CONNECTION
        --------------------------------------------------
        -- Gunakan chat modern jika tersedia.
        -- Fallback Chatted hanya dipakai jika RBXGeneral tidak ada,
        -- agar satu command tidak memulai formasi dua kali.

        local channel

        if TextChatService
            and TextChatService.TextChannels then

            channel =
                TextChatService.TextChannels:FindFirstChild(
                    "RBXGeneral"
                )
        end

        if channel then
            channel.MessageReceived:Connect(function(message)
                local textSource = message.TextSource

                if not textSource then
                    return
                end

                local sender =
                    Players:GetPlayerByUserId(
                        textSource.UserId
                    )

                if sender then
                    handleCommand(
                        message.Text,
                        sender
                    )
                end
            end)

        else
            --------------------------------------------------
            -- LEGACY CHAT FALLBACK
            --------------------------------------------------

            local function connectPlayer(player)
                player.Chatted:Connect(function(message)
                    handleCommand(
                        message,
                        player
                    )
                end)
            end

            for _, player in ipairs(Players:GetPlayers()) do
                connectPlayer(player)
            end

            Players.PlayerAdded:Connect(connectPlayer)
        end

        --------------------------------------------------
        -- CHARACTER RESPAWN
        --------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(function()
            task.wait(1)

            updateCharacter()

            if vars.ActiveMode == "circle"
                and targetPlayer then

                startCircle(targetPlayer)
            end
        end)

        --------------------------------------------------
        -- DONE
        --------------------------------------------------

        print("[Circle] Dynamic Circle system loaded.")
        print("[Circle] Bot online akan dihitung ulang otomatis.")
        print("[Circle] Ketik !circle untuk membentuk ulang lingkaran.")
    end
}