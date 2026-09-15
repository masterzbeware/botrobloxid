return {
Execute = function()
    ----------------------------------------------------------------
    -- SERVICES
    ----------------------------------------------------------------

    local Players = game:GetService("Players")
    local PhysicsService = game:GetService("PhysicsService")

    ----------------------------------------------------------------
    -- LOCAL PLAYER
    ----------------------------------------------------------------

    local LocalPlayer = Players.LocalPlayer

    if not LocalPlayer then
        warn("[NoTouch] LocalPlayer tidak ditemukan.")
        return
    end

    ----------------------------------------------------------------
    -- CONFIG
    ----------------------------------------------------------------

    local BOT_GROUP = "Bots"
    local NO_TOUCH_GROUP = "NoBotTouch"

    local NO_TOUCH_ATTRIBUTE = "NoBotTouch"

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
                    "[NoTouch] Gagal membuat CollisionGroup:",
                    groupName,
                    err
                )

            end
        end
    end

    ensureCollisionGroup(BOT_GROUP)
    ensureCollisionGroup(NO_TOUCH_GROUP)

    ----------------------------------------------------------------
    -- SET COLLISION RULE
    ----------------------------------------------------------------

    pcall(function()

        PhysicsService:CollisionGroupSetCollidable(
            BOT_GROUP,
            NO_TOUCH_GROUP,
            false
        )

    end)

    ----------------------------------------------------------------
    -- SET PART COLLISION GROUP
    ----------------------------------------------------------------

    local function setCollisionGroup(
        instance,
        groupName
    )

        if not instance:IsA("BasePart") then
            return
        end

        pcall(function()

            instance.CollisionGroup =
                groupName

        end)
    end

    ----------------------------------------------------------------
    -- APPLY NO TOUCH
    ----------------------------------------------------------------

    local function applyNoTouch(instance)

        if not instance:IsA("BasePart") then
            return
        end

        if instance:GetAttribute(
            NO_TOUCH_ATTRIBUTE
        ) == true then

            setCollisionGroup(
                instance,
                NO_TOUCH_GROUP
            )

            print(
                "[NoTouch] Protected:",
                instance:GetFullName()
            )
        end
    end

    ----------------------------------------------------------------
    -- SCAN WORKSPACE
    ----------------------------------------------------------------

    local function scanWorkspace()

        for _, instance in ipairs(
            workspace:GetDescendants()
        ) do

            applyNoTouch(instance)

        end

    end

    ----------------------------------------------------------------
    -- CHARACTER
    ----------------------------------------------------------------

    local characterConnection = nil

    local function setupCharacter(
        character
    )

        if not character then
            return
        end

        ----------------------------------------------------------------
        -- SET ALL BODY PARTS TO BOT GROUP
        ----------------------------------------------------------------

        for _, instance in ipairs(
            character:GetDescendants()
        ) do

            if instance:IsA("BasePart") then

                setCollisionGroup(
                    instance,
                    BOT_GROUP
                )

            end

        end

        ----------------------------------------------------------------
        -- NEW CHARACTER PART
        ----------------------------------------------------------------

        if characterConnection then
            characterConnection:Disconnect()
            characterConnection = nil
        end

        characterConnection =
            character.DescendantAdded:Connect(
                function(instance)

                    if instance:IsA("BasePart") then

                        setCollisionGroup(
                            instance,
                            BOT_GROUP
                        )

                    end

                end
            )

        print(
            "[NoTouch] Bot collision aktif:",
            LocalPlayer.Name
        )
    end

    ----------------------------------------------------------------
    -- INITIAL CHARACTER
    ----------------------------------------------------------------

    if LocalPlayer.Character then

        setupCharacter(
            LocalPlayer.Character
        )

    end

    ----------------------------------------------------------------
    -- CHARACTER RESPAWN
    ----------------------------------------------------------------

    LocalPlayer.CharacterAdded:Connect(
        function(character)

            task.wait()

            setupCharacter(
                character
            )

        end
    )

    ----------------------------------------------------------------
    -- INITIAL SCAN
    ----------------------------------------------------------------

    scanWorkspace()

    ----------------------------------------------------------------
    -- NEW OBJECT MONITOR
    ----------------------------------------------------------------

    workspace.DescendantAdded:Connect(
        function(instance)

            if not instance:IsA("BasePart") then
                return
            end

            ----------------------------------------------------------------
            -- NO BOT TOUCH OBJECT
            ----------------------------------------------------------------

            if instance:GetAttribute(
                NO_TOUCH_ATTRIBUTE
            ) == true then

                setCollisionGroup(
                    instance,
                    NO_TOUCH_GROUP
                )

            end

        end
    )

    ----------------------------------------------------------------
    -- ATTRIBUTE CHANGED
    ----------------------------------------------------------------

    workspace.DescendantAdded:Connect(
        function(instance)

            if not instance:IsA("BasePart") then
                return
            end

            instance:GetAttributeChangedSignal(
                NO_TOUCH_ATTRIBUTE
            ):Connect(
                function()

                    if instance:GetAttribute(
                        NO_TOUCH_ATTRIBUTE
                    ) == true then

                        setCollisionGroup(
                            instance,
                            NO_TOUCH_GROUP
                        )

                    end

                end
            )

        end
    )

    ----------------------------------------------------------------
    -- CONNECT EXISTING ATTRIBUTES
    ----------------------------------------------------------------

    for _, instance in ipairs(
        workspace:GetDescendants()
    ) do

        if instance:IsA("BasePart") then

            instance:GetAttributeChangedSignal(
                NO_TOUCH_ATTRIBUTE
            ):Connect(
                function()

                    if instance:GetAttribute(
                        NO_TOUCH_ATTRIBUTE
                    ) == true then

                        setCollisionGroup(
                            instance,
                            NO_TOUCH_GROUP
                        )

                    end

                end
            )

        end

    end

    ----------------------------------------------------------------
    -- READY
    ----------------------------------------------------------------

    print(
        "[NoTouch] Loaded untuk:",
        LocalPlayer.Name
    )

end

}
