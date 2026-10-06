return {
Execute = function()
    ----------------------------------------------------------------
    -- SERVICES
    ----------------------------------------------------------------

    local Players = game:GetService("Players")
    local PhysicsService = game:GetService("PhysicsService")

    local LocalPlayer = Players.LocalPlayer

    if not LocalPlayer then
        warn("[AntiCollision] LocalPlayer tidak ditemukan.")
        return
    end

    ----------------------------------------------------------------
    -- CONFIG
    ----------------------------------------------------------------

    local BOT_GROUP = "BotAntiCollision"
    local PLAYER_GROUP = "PlayerCollision"

    ----------------------------------------------------------------
    -- CREATE COLLISION GROUP
    ----------------------------------------------------------------

    local function ensureCollisionGroup(groupName)

        local exists = false

        for _, groupInfo in ipairs(
            PhysicsService:GetRegisteredCollisionGroups()
        ) do

            if groupInfo.name == groupName then
                exists = true
                break
            end

        end

        if not exists then

            local success, err = pcall(function()

                PhysicsService:RegisterCollisionGroup(
                    groupName
                )

            end)

            if not success then

                warn(
                    "[AntiCollision] Gagal membuat CollisionGroup:",
                    groupName,
                    err
                )

            end

        end

    end

    ensureCollisionGroup(BOT_GROUP)
    ensureCollisionGroup(PLAYER_GROUP)

    ----------------------------------------------------------------
    -- COLLISION RULE
    --
    -- Bot tidak bertabrakan dengan Player.
    ----------------------------------------------------------------

    pcall(function()

        PhysicsService:CollisionGroupSetCollidable(
            BOT_GROUP,
            PLAYER_GROUP,
            false
        )

    end)

    ----------------------------------------------------------------
    -- SET BOT PARTS
    ----------------------------------------------------------------

    local function setupBotCharacter(character)

        if not character then
            return
        end

        for _, instance in ipairs(
            character:GetDescendants()
        ) do

            if instance:IsA("BasePart") then

                pcall(function()

                    instance.CollisionGroup =
                        BOT_GROUP

                end)

            end

        end

        ----------------------------------------------------------------
        -- HANDLE PART YANG MUNCUL KEMUDIAN
        ----------------------------------------------------------------

        character.DescendantAdded:Connect(
            function(instance)

                if instance:IsA("BasePart") then

                    pcall(function()

                        instance.CollisionGroup =
                            BOT_GROUP

                    end)

                end

            end
        )

        print(
            "[AntiCollision] Bot terlindungi:",
            LocalPlayer.Name
        )

    end

    ----------------------------------------------------------------
    -- SET PLAYER LAIN
    ----------------------------------------------------------------

    local function setupPlayerCharacter(
        player,
        character
    )

        if not character then
            return
        end

        -- Jangan ubah Bot sendiri
        if player == LocalPlayer then
            return
        end

        for _, instance in ipairs(
            character:GetDescendants()
        ) do

            if instance:IsA("BasePart") then

                pcall(function()

                    instance.CollisionGroup =
                        PLAYER_GROUP

                end)

            end

        end

        character.DescendantAdded:Connect(
            function(instance)

                if instance:IsA("BasePart") then

                    pcall(function()

                        instance.CollisionGroup =
                            PLAYER_GROUP

                    end)

                end

            end
        )

    end

    ----------------------------------------------------------------
    -- EXISTING PLAYERS
    ----------------------------------------------------------------

    local function setupPlayer(player)

        if player == LocalPlayer then
            return
        end

        if player.Character then

            setupPlayerCharacter(
                player,
                player.Character
            )

        end

        player.CharacterAdded:Connect(
            function(character)

                task.wait()

                setupPlayerCharacter(
                    player,
                    character
                )

            end
        )

    end

    for _, player in ipairs(
        Players:GetPlayers()
    ) do

        setupPlayer(player)

    end

    ----------------------------------------------------------------
    -- NEW PLAYER
    ----------------------------------------------------------------

    Players.PlayerAdded:Connect(
        function(player)

            setupPlayer(player)

        end
    )

    ----------------------------------------------------------------
    -- BOT CHARACTER
    ----------------------------------------------------------------

    if LocalPlayer.Character then

        setupBotCharacter(
            LocalPlayer.Character
        )

    end

    ----------------------------------------------------------------
    -- BOT RESPAWN
    ----------------------------------------------------------------

    LocalPlayer.CharacterAdded:Connect(
        function(character)

            task.wait()

            setupBotCharacter(
                character
            )

        end
    )

    ----------------------------------------------------------------
    -- READY
    ----------------------------------------------------------------

    print(
        "[AntiCollision] Loaded | Bot:",
        LocalPlayer.Name
    )

end

}
