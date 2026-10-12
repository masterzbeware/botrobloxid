-- Glowstick.lua
-- MasterZ HUB
--
-- TANPANAMA:
-- Tool GlowStick.SetColor:FireServer(color)
--
-- CIDRO-JANJI:
-- ReplicatedStorage.GlowstickRemotes.SetColor:FireServer(color)
--
-- THE BUNKER:
-- ReplicatedStorage.Remotes.ColorPicker.SetColor:FireServer(color, nil)
--
-- Commands:
-- !glowstick
-- !glowstick rainbow
-- !glowstick red
-- !glowstick blue
-- !stop

return {
    Execute = function()

        --------------------------------------------------
        -- SERVICES
        --------------------------------------------------

        local Players = game:GetService("Players")
        local TextChatService = game:GetService("TextChatService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[Glowstick] LocalPlayer tidak ditemukan.")
            return
        end

        --------------------------------------------------
        -- PLACE CONFIG
        --------------------------------------------------

        local PLACE_TANPANAMA = 119031818630096
        local PLACE_CIDRO = 79312497897212
        local PLACE_THE_BUNKER = 133943904733338

        local PlaceId = game.PlaceId

        local IsTanpanama = PlaceId == PLACE_TANPANAMA
        local IsCidro = PlaceId == PLACE_CIDRO
        local IsTheBunker = PlaceId == PLACE_THE_BUNKER

        local ToolName =
            IsTanpanama and "GlowStick" or "Glowstick"

        local GameName = "Other"

        if IsTanpanama then
            GameName = "TANPANAMA"
        elseif IsCidro then
            GameName = "Cidro-Janji"
        elseif IsTheBunker then
            GameName = "THE BUNKER"
        end

        -- Interval pergantian warna rainbow.
        local RAINBOW_INTERVAL = 1.2

        print(
            "[Glowstick] PlaceId:",
            PlaceId,
            "| Game:",
            GameName,
            "| Tool:",
            ToolName
        )

        --------------------------------------------------
        -- LOAD ADMIN
        --------------------------------------------------

        local adminOk, Admin = pcall(function()

            local source = game:HttpGet(
                "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
            )

            local loader, compileError = loadstring(source)

            if not loader then
                error(compileError)
            end

            return loader()

        end)

        if not adminOk or not Admin then
            warn("[Glowstick] Gagal memuat Admin.lua:", Admin)
            return
        end

        --------------------------------------------------
        -- GLOBAL STATE / CLEANUP OLD STATE
        --------------------------------------------------

        _G.BotVars = _G.BotVars or {}

        local vars = _G.BotVars
        local previousState = vars.GlowstickState

        if previousState then

            -- Menghentikan rainbow dari module sebelumnya.
            previousState.Active = false
            previousState.Rainbow = false

            previousState.RainbowRunId =
                (previousState.RainbowRunId or 0) + 1

            if previousState.Connections then
                for _, connection in ipairs(
                    previousState.Connections
                ) do
                    pcall(function()
                        connection:Disconnect()
                    end)
                end
            end

        end

        local state = {
            Active = false,
            Rainbow = false,
            RainbowRunId = 0,
            Connections = {},
        }

        vars.GlowstickState = state

        local function addConnection(connection)
            table.insert(state.Connections, connection)
        end

        --------------------------------------------------
        -- COLOR CONFIG
        --------------------------------------------------

        local GlowstickColors = {

            red = Color3.new(
                1, 0, 0
            ),

            orange = Color3.new(
                1, 0.43137255311012268, 0
            ),

            yellow = Color3.new(
                1, 0.84313726425170898, 0
            ),

            lime = Color3.new(
                0.66666668653488159, 1, 0
            ),

            green = Color3.new(
                0, 0.82352942228317261, 0.31372550129890442
            ),

            cyan = Color3.new(
                0, 0.78431373834609985, 1
            ),

            blue = Color3.new(
                0, 0.35294118523597717, 1
            ),

            purple = Color3.new(
                0.58823531866073608, 0, 1
            ),

            magenta = Color3.new(
                1, 0, 1
            ),

            pink = Color3.new(
                1, 0.11764705926179886, 0.47058823704779886
            ),

            black = Color3.new(
                0.039215687662363052,
                0.039215687662363052,
                0.039215687662363052
            ),

            white = Color3.new(
                1, 1, 1
            ),
        }

        --------------------------------------------------
        -- THE BUNKER COLOR PALETTE
        --------------------------------------------------

        if IsTheBunker then

            GlowstickColors.red =
                Color3.fromRGB(255, 50, 50)

            GlowstickColors.orange =
                Color3.fromRGB(255, 140, 0)

            GlowstickColors.yellow =
                Color3.fromRGB(255, 255, 0)

            GlowstickColors.lime =
                Color3.fromRGB(80, 255, 0)

            GlowstickColors.green =
                Color3.fromRGB(80, 255, 0)

            GlowstickColors.cyan =
                Color3.fromRGB(0, 200, 255)

            GlowstickColors.blue =
                Color3.fromRGB(0, 100, 255)

            GlowstickColors.purple =
                Color3.fromRGB(150, 0, 255)

            GlowstickColors.pink =
                Color3.fromRGB(255, 150, 200)

            GlowstickColors.black =
                Color3.fromRGB(30, 30, 30)

            GlowstickColors.white =
                Color3.fromRGB(255, 255, 255)

        end

        --------------------------------------------------
        -- RAINBOW PALETTE
        --------------------------------------------------
        -- THE BUNKER menggunakan palet ColorPickerHandler.
        -- TANPANAMA menggunakan palet Glowstick yang tersedia.
        -- CIDRO tidak mendukung command rainbow pada konfigurasi ini.

        local RainbowColors

        if IsTheBunker then

            RainbowColors = {
                "red",
                "orange",
                "yellow",
                "lime",
                "cyan",
                "blue",
                "purple",
                "pink",
                "black",
                "white",
            }

        else

            RainbowColors = {
                "red",
                "orange",
                "yellow",
                "lime",
                "green",
                "cyan",
                "blue",
                "purple",
                "magenta",
                "pink",
                "black",
                "white",
            }

        end

        local RandomGenerator = Random.new()

        --------------------------------------------------
        -- FIND GLOWSTICK
        --------------------------------------------------

        local function findGlowstick()

            local character = LocalPlayer.Character

            local backpack =
                LocalPlayer:FindFirstChildOfClass("Backpack")

            -- Cari Tool yang sudah equipped.
            if character then

                for _, child in ipairs(
                    character:GetChildren()
                ) do

                    if child:IsA("Tool")
                        and child.Name:lower() == "glowstick" then

                        return child
                    end

                end

            end

            -- Cari Tool di Backpack.
            if backpack then

                for _, child in ipairs(
                    backpack:GetChildren()
                ) do

                    if child:IsA("Tool")
                        and child.Name:lower() == "glowstick" then

                        return child
                    end

                end

            end

            return nil
        end

        --------------------------------------------------
        -- EQUIP GLOWSTICK
        --------------------------------------------------

        local function equipGlowstick()

            local character = LocalPlayer.Character

            if not character then
                return false
            end

            local humanoid =
                character:FindFirstChildOfClass("Humanoid")

            if not humanoid then
                return false
            end

            local tool = findGlowstick()

            if not tool then
                return false
            end

            if tool.Parent == character then
                return true
            end

            local backpack =
                LocalPlayer:FindFirstChildOfClass("Backpack")

            if tool.Parent ~= backpack then
                return false
            end

            local ok, err = pcall(function()
                humanoid:EquipTool(tool)
            end)

            if not ok then
                warn("[Glowstick] EquipTool gagal:", err)
                return false
            end

            task.wait(0.25)

            return tool.Parent == character
        end

        --------------------------------------------------
        -- GET COLOR REMOTE
        --------------------------------------------------

        local function getColorRemote()

            --------------------------------------------------
            -- TANPANAMA
            -- Character/Backpack.GlowStick.SetColor
            --------------------------------------------------

            if IsTanpanama then

                local tool = findGlowstick()

                if not tool then
                    warn("[Glowstick] GlowStick tidak ditemukan.")
                    return nil
                end

                local remote =
                    tool:FindFirstChild("SetColor", true)

                if remote
                    and remote:IsA("RemoteEvent") then

                    return remote
                end

                warn("[Glowstick] Tool.SetColor tidak ditemukan.")
                return nil
            end

            --------------------------------------------------
            -- THE BUNKER
            -- ReplicatedStorage.Remotes.ColorPicker.SetColor
            --------------------------------------------------

            if IsTheBunker then

                local remotes =
                    ReplicatedStorage:FindFirstChild("Remotes")

                local colorPicker =
                    remotes
                    and remotes:FindFirstChild("ColorPicker")

                local remote =
                    colorPicker
                    and colorPicker:FindFirstChild("SetColor")

                if not remote
                    or not remote:IsA("RemoteEvent") then

                    warn(
                        "[Glowstick] Remotes.ColorPicker.SetColor "
                        .. "tidak ditemukan."
                    )

                    return nil
                end

                return remote
            end

            --------------------------------------------------
            -- CIDRO-JANJI / OTHER PLACES
            --------------------------------------------------

            local remotes =
                ReplicatedStorage:FindFirstChild(
                    "GlowstickRemotes"
                )

            local remote =
                remotes
                and remotes:FindFirstChild("SetColor")

            if not remote
                or not remote:IsA("RemoteEvent") then

                warn(
                    "[Glowstick] GlowstickRemotes.SetColor "
                    .. "tidak ditemukan."
                )

                return nil
            end

            return remote
        end

        --------------------------------------------------
        -- SET GLOWSTICK COLOR
        --------------------------------------------------

        local function setGlowstickColor(colorName)

            local color =
                GlowstickColors[colorName]

            if not color then
                warn(
                    "[Glowstick] Warna tidak dikenal:",
                    colorName
                )
                return false
            end

            local remote = getColorRemote()

            if not remote then
                return false
            end

            local ok, err = pcall(function()

                if IsTheBunker then

                    -- THE BUNKER:
                    -- SetColor:FireServer(color, nil)
                    remote:FireServer(color, nil)

                else

                    -- TANPANAMA / CIDRO
                    remote:FireServer(color)

                end

            end)

            if not ok then
                warn(
                    "[Glowstick] Pengiriman warna gagal:",
                    colorName,
                    err
                )
                return false
            end

            print(
                "[Glowstick] Warna:",
                colorName,
                "| Game:",
                GameName
            )

            return true
        end

        --------------------------------------------------
        -- STOP RAINBOW
        --------------------------------------------------

        local function stopRainbow()

            state.Rainbow = false

            -- Membatalkan loop rainbow yang sedang berjalan.
            state.RainbowRunId =
                state.RainbowRunId + 1

        end

        --------------------------------------------------
        -- START RAINBOW
        --------------------------------------------------

        local function startRainbow()

            --------------------------------------------------
            -- PLACE VALIDATION
            --------------------------------------------------

            if not IsTanpanama and not IsTheBunker then

                warn(
                    "[Glowstick] Rainbow hanya tersedia "
                    .. "di TANPANAMA dan THE BUNKER."
                )

                return
            end

            --------------------------------------------------
            -- ACTIVATE RAINBOW
            --------------------------------------------------

            state.Active = true
            state.Rainbow = true

            state.RainbowRunId =
                state.RainbowRunId + 1

            local thisRunId =
                state.RainbowRunId

            print(
                "[Glowstick] Rainbow dimulai:",
                GameName
            )

            print(
                "[Glowstick] Interval warna:",
                RAINBOW_INTERVAL,
                "detik"
            )

            --------------------------------------------------
            -- RAINBOW LOOP
            --------------------------------------------------

            task.spawn(function()

                local lastColorName = nil

                --------------------------------------------------
                -- WAIT UNTIL TOOL IS AVAILABLE
                --------------------------------------------------

                local equipped = false

                for attempt = 1, 10 do

                    if not state.Active
                        or not state.Rainbow
                        or state.RainbowRunId ~= thisRunId then

                        return
                    end

                    local tool = findGlowstick()

                    if tool then

                        if tool.Parent == LocalPlayer.Character then
                            equipped = true
                        else
                            equipped = equipGlowstick()
                        end

                        if equipped then
                            break
                        end

                    end

                    task.wait(0.5)

                end

                if not equipped then

                    if state.RainbowRunId == thisRunId then
                        state.Rainbow = false
                    end

                    warn(
                        "[Glowstick] Rainbow gagal dimulai. "
                        .. "Tool Glowstick tidak ditemukan "
                        .. "atau gagal equipped."
                    )

                    return
                end

                --------------------------------------------------
                -- REPEATING RANDOM COLORS
                --------------------------------------------------

                while state.Active
                    and state.Rainbow
                    and state.RainbowRunId == thisRunId do

                    --------------------------------------------------
                    -- SELECT RANDOM COLOR
                    -- Hindari warna sama dua kali berturut-turut.
                    --------------------------------------------------

                    local choices = {}

                    for _, colorName in ipairs(
                        RainbowColors
                    ) do

                        if colorName ~= lastColorName then
                            table.insert(choices, colorName)
                        end

                    end

                    if #choices == 0 then
                        choices = RainbowColors
                    end

                    local index =
                        RandomGenerator:NextInteger(
                            1,
                            #choices
                        )

                    local nextColor =
                        choices[index]

                    --------------------------------------------------
                    -- CHECK TOOL / RE-EQUIP IF NECESSARY
                    --------------------------------------------------

                    local tool = findGlowstick()
                    local canChangeColor = false

                    if tool then

                        if tool.Parent == LocalPlayer.Character then
                            canChangeColor = true
                        else
                            canChangeColor = equipGlowstick()
                        end

                    end

                    --------------------------------------------------
                    -- APPLY RANDOM COLOR
                    --------------------------------------------------

                    if canChangeColor
                        and state.Active
                        and state.Rainbow
                        and state.RainbowRunId == thisRunId then

                        local success =
                            setGlowstickColor(nextColor)

                        if success then
                            lastColorName = nextColor
                        end

                    end

                    --------------------------------------------------
                    -- NEXT COLOR
                    --------------------------------------------------

                    task.wait(RAINBOW_INTERVAL)

                end

                print("[Glowstick] Rainbow loop selesai.")

            end)
        end

        --------------------------------------------------
        -- STOP / UNEQUIP
        --------------------------------------------------

        local function stopGlowstick()

            state.Active = false

            stopRainbow()

            local character = LocalPlayer.Character

            if not character then
                return
            end

            local humanoid =
                character:FindFirstChildOfClass("Humanoid")

            if humanoid then
                pcall(function()
                    humanoid:UnequipTools()
                end)
            end

            print("[Glowstick] Rainbow/Glowstick dihentikan.")

        end

        --------------------------------------------------
        -- ADMIN CHECK
        --------------------------------------------------

        local function isAdmin(sender)

            if not sender then
                return false
            end

            local ok, result = pcall(function()
                return Admin:IsAdmin(sender)
            end)

            return ok and result == true
        end

        --------------------------------------------------
        -- HANDLE CHAT COMMAND
        --------------------------------------------------

        local function handleCommand(message, sender)

            if not message or not sender then
                return
            end

            if not isAdmin(sender) then
                return
            end

            local lower =
                message:lower():match("^%s*(.-)%s*$")

            --------------------------------------------------
            -- !STOP
            --------------------------------------------------

            if lower == "!stop" then

                stopGlowstick()
                return
            end

            --------------------------------------------------
            -- !GLOWSTICK RAINBOW
            --------------------------------------------------

            if lower == "!glowstick rainbow" then

                startRainbow()
                return
            end

            --------------------------------------------------
            -- !GLOWSTICK
            -- Equip biasa dan hentikan rainbow sebelumnya.
            --------------------------------------------------

            if lower == "!glowstick" then

                stopRainbow()

                state.Active = true

                task.spawn(function()

                    for attempt = 1, 10 do

                        if not state.Active
                            or state.Rainbow then

                            return
                        end

                        if equipGlowstick() then

                            print(
                                "[Glowstick] Berhasil equipped:",
                                GameName
                            )

                            return
                        end

                        if attempt < 10 then
                            task.wait(0.5)
                        end

                    end

                    warn(
                        "[Glowstick] Gagal equip setelah "
                        .. "10 percobaan."
                    )

                end)

                return
            end

            --------------------------------------------------
            -- !GLOWSTICK COLOR
            --------------------------------------------------

            local colorName =
                lower:match("^!glowstick%s+(%a+)%s*$")

            if not colorName then
                return
            end

            if not GlowstickColors[colorName] then

                warn(
                    "[Glowstick] Warna tidak tersedia:",
                    colorName
                )

                return
            end

            --------------------------------------------------
            -- STOP RAINBOW BEFORE MANUAL COLOR
            --------------------------------------------------

            stopRainbow()

            state.Active = true

            task.spawn(function()

                for attempt = 1, 10 do

                    if not state.Active
                        or state.Rainbow then

                        return
                    end

                    local tool = findGlowstick()

                    if tool then

                        local equipped = false

                        if tool.Parent == LocalPlayer.Character then
                            equipped = true
                        else
                            equipped = equipGlowstick()
                        end

                        if equipped
                            and state.Active
                            and not state.Rainbow then

                            setGlowstickColor(colorName)

                        end

                        return
                    end

                    if attempt < 10 then
                        task.wait(0.5)
                    end

                end

                warn(
                    "[Glowstick] Tidak dapat mengubah warna: "
                    .. "Tool tidak ditemukan."
                )

            end)
        end

        --------------------------------------------------
        -- CHAT CONNECTIONS
        --------------------------------------------------

        local channels =
            TextChatService:FindFirstChild("TextChannels")

        local general =
            channels
            and channels:FindFirstChild("RBXGeneral")

        if general then

            addConnection(
                general.MessageReceived:Connect(function(message)

                    local source = message.TextSource

                    if not source then
                        return
                    end

                    local sender =
                        Players:GetPlayerByUserId(source.UserId)

                    if sender then
                        handleCommand(message.Text, sender)
                    end

                end)
            )

        else

            local function connectPlayer(player)

                addConnection(
                    player.Chatted:Connect(function(message)
                        handleCommand(message, player)
                    end)
                )

            end

            for _, player in ipairs(Players:GetPlayers()) do
                connectPlayer(player)
            end

            addConnection(
                Players.PlayerAdded:Connect(connectPlayer)
            )

        end

        --------------------------------------------------
        -- CHARACTER RESPAWN
        --------------------------------------------------

        addConnection(
            LocalPlayer.CharacterAdded:Connect(function()

                task.wait(1)

                if not state.Active then
                    return
                end

                task.spawn(function()

                    for attempt = 1, 10 do

                        if not state.Active then
                            return
                        end

                        if equipGlowstick() then
                            break
                        end

                        task.wait(0.5)

                    end

                    -- Rainbow loop akan mendeteksi Tool baru
                    -- dan melanjutkan penggantian warna.

                end)

            end)
        )

        --------------------------------------------------
        -- DONE
        --------------------------------------------------

        print("[Glowstick] Command system loaded.")
        print("[Glowstick] Game:", GameName)
        print("[Glowstick] !glowstick = Equip")
        print("[Glowstick] !glowstick rainbow = Random warna")
        print("[Glowstick] !glowstick red = Warna manual")
        print("[Glowstick] !stop = Hentikan dan unequip")

    end
}