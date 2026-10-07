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
        return
    end

    ----------------------------------------------------------------
    -- LOAD ADMIN
    ----------------------------------------------------------------

    local Admin = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
    ))()

    ----------------------------------------------------------------
    -- VARIABLES
    ----------------------------------------------------------------

    local glowstickActive = false

    ----------------------------------------------------------------
    -- GLOWSTICK COLORS
    ----------------------------------------------------------------

    local GlowstickColors = {

        ------------------------------------------------------------
        -- RED
        ------------------------------------------------------------

        red =
            Color3.new(
                1,
                0,
                0
            ),

        ------------------------------------------------------------
        -- ORANGE
        ------------------------------------------------------------

        orange =
            Color3.new(
                1,
                0.47058823704719543,
                0
            ),

        ------------------------------------------------------------
        -- YELLOW
        ------------------------------------------------------------

        yellow =
            Color3.new(
                1,
                0.94117647409439087,
                0
            ),

        ------------------------------------------------------------
        -- GREEN
        ------------------------------------------------------------

        green =
            Color3.new(
                0.31372550129890442,
                1,
                0
            ),

        ------------------------------------------------------------
        -- BLUE
        ------------------------------------------------------------

        blue =
            Color3.new(
                0,
                0.31372550129890442,
                1
            ),

        ------------------------------------------------------------
        -- PINK
        ------------------------------------------------------------

        pink =
            Color3.new(
                1,
                0.62745100259780884,
                0.86274510622024536
            ),

        ------------------------------------------------------------
        -- BLACK
        ------------------------------------------------------------

        black =
            Color3.new(
                0.039215687662363052,
                0.039215687662363052,
                0.039215687662363052
            ),

        ------------------------------------------------------------
        -- WHITE
        ------------------------------------------------------------

        white =
            Color3.new(
                0.94117647409439087,
                0.94117647409439087,
                0.94117647409439087
            ),

    }

    ----------------------------------------------------------------
    -- EQUIP GLOWSTICK
    ----------------------------------------------------------------

    local function equipGlowstick()

        local character =
            LocalPlayer.Character

        if not character then
            return
        end

        local humanoid =
            character:FindFirstChildOfClass("Humanoid")

        if not humanoid then
            return
        end

        ------------------------------------------------------------
        -- BACKPACK
        ------------------------------------------------------------

        local backpack =
            LocalPlayer:FindFirstChild("Backpack")

        if not backpack then
            return
        end

        ------------------------------------------------------------
        -- FIND GLOWSTICK
        ------------------------------------------------------------

        local glowstick =
            backpack:FindFirstChild("Glowstick")

        if not glowstick then

            warn(
                "[Glowstick] Tool Glowstick tidak ditemukan di Backpack."
            )

            return

        end

        ------------------------------------------------------------
        -- EQUIP
        ------------------------------------------------------------

        pcall(function()

            humanoid:EquipTool(
                glowstick
            )

        end)

    end

    ----------------------------------------------------------------
    -- SET GLOWSTICK COLOR
    ----------------------------------------------------------------

    local function setGlowstickColor(
        colorName
    )

        local color =
            GlowstickColors[colorName]

        ------------------------------------------------------------
        -- INVALID COLOR
        ------------------------------------------------------------

        if not color then

            warn(
                "[Glowstick] Warna tidak dikenal:",
                colorName
            )

            return

        end

        ------------------------------------------------------------
        -- GLOWSTICK REMOTES
        ------------------------------------------------------------

        local glowstickRemotes =
            ReplicatedStorage:FindFirstChild(
                "GlowstickRemotes"
            )

        if not glowstickRemotes then

            warn(
                "[Glowstick] GlowstickRemotes tidak ditemukan."
            )

            return

        end

        ------------------------------------------------------------
        -- SET COLOR REMOTE
        ------------------------------------------------------------

        local setColor =
            glowstickRemotes:FindFirstChild(
                "SetColor"
            )

        if not setColor then

            warn(
                "[Glowstick] SetColor tidak ditemukan."
            )

            return

        end

        ------------------------------------------------------------
        -- FIRE SERVER
        ------------------------------------------------------------

        pcall(function()

            setColor:FireServer(
                color
            )

        end)

    end

    ----------------------------------------------------------------
    -- UNEQUIP GLOWSTICK
    ----------------------------------------------------------------

    local function unequipGlowstick()

        glowstickActive = false

        local character =
            LocalPlayer.Character

        if not character then
            return
        end

        local humanoid =
            character:FindFirstChildOfClass("Humanoid")

        if not humanoid then
            return
        end

        ------------------------------------------------------------
        -- CHECK EQUIPPED GLOWSTICK
        ------------------------------------------------------------

        local equippedTool =
            character:FindFirstChild(
                "Glowstick"
            )

        if equippedTool then

            pcall(function()

                humanoid:UnequipTools()

            end)

        end

    end

    ----------------------------------------------------------------
    -- HANDLE COMMAND
    ----------------------------------------------------------------

    local function handleCommand(
        message,
        sender
    )

        if not message
            or not sender then

            return

        end

        ----------------------------------------------------------------
        -- ADMIN CHECK
        ----------------------------------------------------------------

        local isAdmin = false

        pcall(function()

            isAdmin =
                Admin:IsAdmin(
                    sender
                )

        end)

        if not isAdmin then
            return
        end

        ----------------------------------------------------------------
        -- NORMALIZE MESSAGE
        ----------------------------------------------------------------

        local lower =
            message
            :lower()
            :gsub("^%s+", "")
            :gsub("%s+$", "")

        ----------------------------------------------------------------
        -- !STOP
        ----------------------------------------------------------------

        if lower == "!stop" then

            unequipGlowstick()

            return

        end

        ----------------------------------------------------------------
        -- !GLOWSTICK
        ----------------------------------------------------------------

        if lower == "!glowstick" then

            glowstickActive = true

            equipGlowstick()

            return

        end

        ----------------------------------------------------------------
        -- !GLOWSTICK COLOR
        ----------------------------------------------------------------

        local glowstickColor =
            lower:match(
                "^!glowstick%s+(.+)$"
            )

        if glowstickColor then

            glowstickColor =
                glowstickColor
                :gsub("^%s+", "")
                :gsub("%s+$", "")

            --------------------------------------------------------
            -- VALIDATE COLOR
            --------------------------------------------------------

            if not GlowstickColors[
                glowstickColor
            ] then

                warn(
                    "[Glowstick] Warna tidak tersedia:",
                    glowstickColor
                )

                return

            end

            --------------------------------------------------------
            -- ACTIVATE
            --------------------------------------------------------

            glowstickActive = true

            --------------------------------------------------------
            -- EQUIP
            --------------------------------------------------------

            equipGlowstick()

            --------------------------------------------------------
            -- SET COLOR
            --------------------------------------------------------

            setGlowstickColor(
                glowstickColor
            )

            return

        end

    end

    ----------------------------------------------------------------
    -- TEXT CHAT
    ----------------------------------------------------------------

    if TextChatService
        and TextChatService.TextChannels then

        local channel =
            TextChatService.TextChannels:FindFirstChild(
                "RBXGeneral"
            )

        if channel then

            channel.MessageReceived:Connect(
                function(message)

                    local userId =
                        message.TextSource
                        and message.TextSource.UserId

                    local sender =
                        userId
                        and Players:GetPlayerByUserId(
                            userId
                        )

                    if sender then

                        handleCommand(
                            message.Text,
                            sender
                        )

                    end

                end
            )

        end

    end

    ----------------------------------------------------------------
    -- FALLBACK CHAT
    ----------------------------------------------------------------

    for _, player in ipairs(
        Players:GetPlayers()
    ) do

        player.Chatted:Connect(
            function(message)

                handleCommand(
                    message,
                    player
                )

            end
        )

    end

    ----------------------------------------------------------------
    -- PLAYER ADDED
    ----------------------------------------------------------------

    Players.PlayerAdded:Connect(
        function(player)

            player.Chatted:Connect(
                function(message)

                    handleCommand(
                        message,
                        player
                    )

                end
            )

        end
    )

    ----------------------------------------------------------------
    -- CHARACTER RESPAWN
    ----------------------------------------------------------------

    LocalPlayer.CharacterAdded:Connect(
        function()

            task.wait(1)

            if glowstickActive then

                equipGlowstick()

            end

        end
    )

    ----------------------------------------------------------------
    -- DONE
    ----------------------------------------------------------------

    print(
        "[Glowstick] Glowstick command system loaded."
    )

end

}
