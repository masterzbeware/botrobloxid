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
-- ReplicatedStorage.Remotes.ColorPicker.ColorChanged
-- firesignal(ColorChanged.OnClientEvent, LocalPlayer, color)
--
-- Commands:
-- !glowstick
-- !glowstick blue
-- !glowstick purple
-- !glowstick magenta
-- !glowstick pink
-- !glowstick red
-- !glowstick orange
-- !glowstick yellow
-- !glowstick lime
-- !glowstick green
-- !glowstick white
-- !glowstick black
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

        local PlaceId = game.PlaceId

        local PLACE_TANPANAMA = 119031818630096
        local PLACE_CIDRO = 79312497897212
        local PLACE_THE_BUNKER = 133943904733338

        local IsTanpanama = PlaceId == PLACE_TANPANAMA
        local IsCidro = PlaceId == PLACE_CIDRO
        local IsTheBunker = PlaceId == PLACE_THE_BUNKER

        local ToolName

        if IsTanpanama then
            ToolName = "GlowStick"
        else
            ToolName = "Glowstick"
        end

        local GameName

        if IsTanpanama then
            GameName = "TANPANAMA"
        elseif IsCidro then
            GameName = "Cidro-Janji"
        elseif IsTheBunker then
            GameName = "THE BUNKER"
        else
            GameName = "Other"
        end

        print(
            "[Glowstick] PlaceId:", PlaceId,
            "| Game:", GameName,
            "| Tool:", ToolName
        )

        --------------------------------------------------
        -- LOAD ADMIN MODULE
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
            warn(
                "[Glowstick] Gagal memuat Admin.lua:",
                Admin
            )
            return
        end

        --------------------------------------------------
        -- GLOBAL STATE / CLEANUP
        --------------------------------------------------

        _G.BotVars = _G.BotVars or {}

        local vars = _G.BotVars

        if vars.GlowstickState
            and vars.GlowstickState.Connections then

            for _, connection in ipairs(
                vars.GlowstickState.Connections
            ) do
                pcall(function()
                    connection:Disconnect()
                end)
            end
        end

        local state = {
            Active = false,
            Connections = {},
        }

        vars.GlowstickState = state

        local function addConnection(connection)
            table.insert(state.Connections, connection)
        end

        --------------------------------------------------
        -- COLOR CONFIG
        --------------------------------------------------
        -- Warna merah THE BUNKER memakai nilai Color3
        -- dari contoh Cobalt yang kamu berikan.
        --
        -- Warna pada game lain tetap seperti sebelumnya.
        --------------------------------------------------

        local redColor

        if IsTheBunker then
            redColor = Color3.new(
                1,
                0.19607843458652496,
                0.19607843458652496
            )
        else
            redColor = Color3.new(
                1,
                0,
                0
            )
        end

        local GlowstickColors = {

            blue = Color3.new(
                0,
                0.35294118523597717,
                1
            ),

            purple = Color3.new(
                0.58823531866073608,
                0,
                1
            ),

            magenta = Color3.new(
                1,
                0,
                1
            ),

            pink = Color3.new(
                1,
                0.11764705926179886,
                0.47058823704779886
            ),

            red = redColor,

            orange = Color3.new(
                1,
                0.43137255311012268,
                0
            ),

            yellow = Color3.new(
                1,
                0.84313726425170898,
                0
            ),

            lime = Color3.new(
                0.66666668653488159,
                1,
                0
            ),

            green = Color3.new(
                0,
                0.82352942228317261,
                0.31372550129890442
            ),

            white = Color3.new(
                1,
                1,
                1
            ),

            black = Color3.new(
                0.039215687662363052,
                0.039215687662363052,
                0.039215687662363052
            ),
        }

        --------------------------------------------------
        -- FIND GLOWSTICK
        -- Character atau Backpack
        --------------------------------------------------

        local function findGlowstick()

            local character = LocalPlayer.Character

            local backpack =
                LocalPlayer:FindFirstChildOfClass("Backpack")

            --------------------------------------------------
            -- CHECK CHARACTER FIRST
            --------------------------------------------------

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

            --------------------------------------------------
            -- CHECK BACKPACK
            --------------------------------------------------

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
                warn("[Glowstick] Character belum tersedia.")
                return false
            end

            local humanoid =
                character:FindFirstChildOfClass("Humanoid")

            if not humanoid then
                warn("[Glowstick] Humanoid tidak ditemukan.")
                return false
            end

            local tool = findGlowstick()

            if not tool then
                warn(
                    "[Glowstick] Tool tidak ditemukan:",
                    ToolName
                )
                return false
            end

            --------------------------------------------------
            -- ALREADY EQUIPPED
            --------------------------------------------------

            if tool.Parent == character then

                print(
                    "[Glowstick] Sudah equipped:",
                    tool.Name
                )

                return true
            end

            --------------------------------------------------
            -- VALIDATE BACKPACK
            --------------------------------------------------

            local backpack =
                LocalPlayer:FindFirstChildOfClass("Backpack")

            if tool.Parent ~= backpack then

                warn(
                    "[Glowstick] Tool bukan di Backpack:",
                    tool:GetFullName()
                )

                return false
            end

            --------------------------------------------------
            -- EQUIP
            --------------------------------------------------

            local ok, err = pcall(function()
                humanoid:EquipTool(tool)
            end)

            if not ok then

                warn(
                    "[Glowstick] EquipTool error:",
                    err
                )

                return false
            end

            task.wait(0.25)

            if tool.Parent == character then

                print(
                    "[Glowstick] Berhasil equipped:",
                    tool.Name
                )

                return true
            end

            warn(
                "[Glowstick] Equip belum terkonfirmasi:",
                tool.Name
            )

            return false
        end

        --------------------------------------------------
        -- FIND COLOR EVENT
        --------------------------------------------------

        local function getColorEvent()

            --------------------------------------------------
            -- TANPANAMA
            -- Character/Backpack.GlowStick.SetColor
            --------------------------------------------------

            if IsTanpanama then

                local tool = findGlowstick()

                if not tool then

                    warn(
                        "[Glowstick] GlowStick tidak ditemukan."
                    )

                    return nil
                end

                local remote =
                    tool:FindFirstChild("SetColor", true)

                if remote
                    and remote:IsA("RemoteEvent") then

                    return remote
                end

                warn(
                    "[Glowstick] SetColor tidak ditemukan di Tool."
                )

                return nil
            end

            --------------------------------------------------
            -- THE BUNKER
            -- ReplicatedStorage.Remotes.ColorPicker.ColorChanged
            --------------------------------------------------

            if IsTheBunker then

                local remotes =
                    ReplicatedStorage:FindFirstChild("Remotes")

                if not remotes then

                    warn(
                        "[Glowstick] Folder Remotes tidak ditemukan."
                    )

                    return nil
                end

                local colorPicker =
                    remotes:FindFirstChild("ColorPicker")

                if not colorPicker then

                    warn(
                        "[Glowstick] Remotes.ColorPicker tidak ditemukan."
                    )

                    return nil
                end

                local colorChanged =
                    colorPicker:FindFirstChild("ColorChanged")

                if not colorChanged
                    or not colorChanged:IsA("RemoteEvent") then

                    warn(
                        "[Glowstick] ColorChanged bukan RemoteEvent "
                        .. "atau tidak ditemukan."
                    )

                    return nil
                end

                return colorChanged
            end

            --------------------------------------------------
            -- CIDRO-JANJI / OTHER PLACES
            -- ReplicatedStorage.GlowstickRemotes.SetColor
            --------------------------------------------------

            local remotes =
                ReplicatedStorage:FindFirstChild(
                    "GlowstickRemotes"
                )

            if not remotes then

                warn(
                    "[Glowstick] GlowstickRemotes tidak ditemukan."
                )

                return nil
            end

            local remote =
                remotes:FindFirstChild("SetColor")

            if not remote
                or not remote:IsA("RemoteEvent") then

                warn(
                    "[Glowstick] SetColor RemoteEvent tidak ditemukan."
                )

                return nil
            end

            return remote
        end

        --------------------------------------------------
        -- CHANGE GLOWSTICK COLOR
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

            local remote = getColorEvent()

            if not remote then
                return false
            end

            --------------------------------------------------
            -- THE BUNKER
            --------------------------------------------------
            -- Mengikuti kode Cobalt:
            --
            -- firesignal(
            --     ColorChanged.OnClientEvent,
            --     LocalPlayer,
            --     color
            -- )
            --
            -- firesignal adalah fungsi khusus executor.
            --------------------------------------------------

            if IsTheBunker then

                if type(firesignal) ~= "function" then

                    warn(
                        "[Glowstick] Executor tidak menyediakan "
                        .. "fungsi firesignal."
                    )

                    return false
                end

                local ok, err = pcall(function()

                    firesignal(
                        remote.OnClientEvent,
                        LocalPlayer,
                        color
                    )

                end)

                if not ok then

                    warn(
                        "[Glowstick] Gagal memicu ColorChanged:",
                        err
                    )

                    return false
                end

                print(
                    "[Glowstick] ColorChanged dipicu:",
                    colorName,
                    "| Game: THE BUNKER"
                )

                return true
            end

            --------------------------------------------------
            -- TANPANAMA / CIDRO-JANJI
            --------------------------------------------------

            local ok, err = pcall(function()
                remote:FireServer(color)
            end)

            if not ok then

                warn(
                    "[Glowstick] Gagal mengirim warna:",
                    colorName,
                    err
                )

                return false
            end

            print(
                "[Glowstick] Warna dikirim:",
                colorName,
                "| Game:",
                GameName
            )

            return true
        end

        --------------------------------------------------
        -- STOP / UNEQUIP
        --------------------------------------------------

        local function stopGlowstick()

            state.Active = false

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

            print("[Glowstick] Dihentikan.")
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
            -- !GLOWSTICK
            --------------------------------------------------

            if lower == "!glowstick" then

                state.Active = true

                task.spawn(function()

                    for attempt = 1, 10 do

                        if not state.Active then
                            return
                        end

                        if equipGlowstick() then
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

            state.Active = true

            task.spawn(function()

                for attempt = 1, 10 do

                    if not state.Active then
                        return
                    end

                    local tool = findGlowstick()

                    if tool then

                        -- Tetap mencoba equip.
                        -- Pengiriman warna mengikuti game masing-masing.

                        equipGlowstick()

                        if state.Active then
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

            --------------------------------------------------
            -- LEGACY CHAT FALLBACK
            --------------------------------------------------

            local function connectPlayer(player)

                addConnection(
                    player.Chatted:Connect(function(message)

                        handleCommand(
                            message,
                            player
                        )

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
                            return
                        end

                        task.wait(0.5)

                    end

                end)

            end)
        )

        --------------------------------------------------
        -- DONE
        --------------------------------------------------

        print("[Glowstick] Command system loaded.")
        print("[Glowstick] Game:", GameName)
        print("[Glowstick] Gunakan !glowstick untuk equip.")
        print("[Glowstick] Gunakan !glowstick red untuk mengganti warna.")
        print("[Glowstick] Gunakan !stop untuk unequip.")

    end
}