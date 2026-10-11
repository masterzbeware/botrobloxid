-- Glowstick.lua
-- MasterZ HUB
-- Glowstick command untuk TANPANAMA dan Cidro-Janji
-- Commands:
-- !glowstick
-- !glowstick red
-- !glowstick orange
-- !glowstick yellow
-- !glowstick green
-- !glowstick blue
-- !glowstick pink
-- !glowstick black
-- !glowstick white
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
        -- CONFIG
        --------------------------------------------------

        local PlaceId = game.PlaceId
        local ToolName

        if PlaceId == 119031818630096 then
            -- TANPANAMA
            ToolName = "GlowStick"
        elseif PlaceId == 79312497897212 then
            -- Cidro-Janji
            ToolName = "Glowstick"
        else
            ToolName = "Glowstick"
        end

        print("[Glowstick] PlaceId:", PlaceId, "Tool:", ToolName)

        --------------------------------------------------
        -- LOAD ADMIN MODULE
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

        if adminOk then
            Admin = adminResult
        else
            warn("[Glowstick] Gagal memuat Admin.lua:", adminResult)
            return
        end

        --------------------------------------------------
        -- STATE
        --------------------------------------------------

        local vars = _G.BotVars or {}
        vars.GlowstickState = vars.GlowstickState or {}

        local state = vars.GlowstickState
        state.Active = false

        -- Hindari koneksi command ganda jika Execute dipanggil ulang.
        if state.Connections then
            for _, connection in ipairs(state.Connections) do
                pcall(function()
                    connection:Disconnect()
                end)
            end
        end

        state.Connections = {}
        vars.GlowstickState = state

        --------------------------------------------------
        -- COLORS
        --------------------------------------------------

        local GlowstickColors = {
            red = Color3.new(1, 0, 0),
            orange = Color3.new(1, 0.47058823704719543, 0),
            yellow = Color3.new(1, 0.94117647409439087, 0),
            green = Color3.new(0.31372550129890442, 1, 0),
            blue = Color3.new(0, 0.31372550129890442, 1),
            pink = Color3.new(1, 0.62745100259780884, 0.86274510622024536),
            black = Color3.new(0.039215687662363052, 0.039215687662363052, 0.039215687662363052),
            white = Color3.new(0.94117647409439087, 0.94117647409439087, 0.94117647409439087),
        }

        --------------------------------------------------
        -- FIND TOOL
        --------------------------------------------------

        local function findGlowstick()
            local character = LocalPlayer.Character
            local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")

            -- Jika sudah equipped, jangan equip ulang.
            if character then
                for _, child in ipairs(character:GetChildren()) do
                    if child:IsA("Tool") then
                        local name = child.Name:lower()

                        if name == "glowstick" then
                            return child
                        end
                    end
                end
            end

            -- Cari berdasarkan nama tanpa membedakan kapital.
            if backpack then
                for _, child in ipairs(backpack:GetChildren()) do
                    if child:IsA("Tool") then
                        local name = child.Name:lower()

                        if name == ToolName:lower()
                            or name == "glowstick" then
                            return child
                        end
                    end
                end
            end

            return nil
        end

        --------------------------------------------------
        -- EQUIP TOOL
        --------------------------------------------------

        local function equipGlowstick()
            local character = LocalPlayer.Character

            if not character then
                warn("[Glowstick] Character belum tersedia.")
                return false
            end

            local humanoid = character:FindFirstChildOfClass("Humanoid")

            if not humanoid then
                warn("[Glowstick] Humanoid tidak ditemukan.")
                return false
            end

            local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")

            local tool = findGlowstick()

            if not tool then
                warn(
                    "[Glowstick] Tool tidak ditemukan!",
                    "Nama yang dicari:", ToolName,
                    "| Backpack:", backpack ~= nil,
                    "| PlaceId:", PlaceId
                )
                return false
            end

            -- Sudah berada di Character berarti sudah equipped.
            if tool.Parent == character then
                print("[Glowstick] Tool sudah equipped:", tool.Name)
                return true
            end

            if tool.Parent ~= backpack then
                warn(
                    "[Glowstick] Tool ditemukan tetapi bukan di Backpack:",
                    tool:GetFullName()
                )
                return false
            end

            local equipOk, equipError = pcall(function()
                humanoid:EquipTool(tool)
            end)

            if not equipOk then
                warn("[Glowstick] EquipTool gagal:", equipError)
                return false
            end

            -- Beri waktu singkat untuk perpindahan Tool.
            task.wait(0.25)

            if tool.Parent == character then
                print("[Glowstick] Berhasil equipped:", tool.Name)
                return true
            end

            warn(
                "[Glowstick] Equip belum berhasil.",
                "Tool:", tool.Name,
                "| Parent:", tool.Parent and tool.Parent:GetFullName() or "nil"
            )

            return false
        end

        --------------------------------------------------
        -- SET COLOR
        --------------------------------------------------

        local function setGlowstickColor(colorName)
            local color = GlowstickColors[colorName]

            if not color then
                warn("[Glowstick] Warna tidak dikenal:", colorName)
                return
            end

            local remotes = ReplicatedStorage:FindFirstChild("GlowstickRemotes")

            if not remotes then
                warn("[Glowstick] GlowstickRemotes tidak ditemukan.")
                return
            end

            local setColor = remotes:FindFirstChild("SetColor")

            if not setColor or not setColor:IsA("RemoteEvent") then
                warn("[Glowstick] RemoteEvent SetColor tidak ditemukan.")
                return
            end

            local ok, err = pcall(function()
                setColor:FireServer(color)
            end)

            if ok then
                print("[Glowstick] Permintaan warna dikirim:", colorName)
            else
                warn("[Glowstick] Gagal mengirim warna:", err)
            end
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

            local humanoid = character:FindFirstChildOfClass("Humanoid")

            if humanoid then
                pcall(function()
                    humanoid:UnequipTools()
                end)
            end

            print("[Glowstick] Glowstick dihentikan.")
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
        -- HANDLE COMMAND
        --------------------------------------------------

        local function handleCommand(message, sender)
            if not message or not sender then
                return
            end

            if not isAdmin(sender) then
                return
            end

            local lower = message:lower():match("^%s*(.-)%s*$")

            if lower == "!stop" then
                stopGlowstick()
                return
            end

            if lower == "!glowstick" then
                state.Active = true

                task.spawn(function()
                    -- Coba beberapa kali jika Tool baru diberikan.
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
                        "[Glowstick] Gagal equip setelah 10 percobaan.",
                        "Pastikan Tool tersedia di Backpack."
                    )
                end)

                return
            end

            local colorName = lower:match("^!glowstick%s+(%a+)%s*$")

            if colorName then
                if not GlowstickColors[colorName] then
                    warn("[Glowstick] Warna tidak tersedia:", colorName)
                    return
                end

                state.Active = true

                task.spawn(function()
                    local equipped = false

                    for attempt = 1, 10 do
                        if not state.Active then
                            return
                        end

                        if equipGlowstick() then
                            equipped = true
                            break
                        end

                        if attempt < 10 then
                            task.wait(0.5)
                        end
                    end

                    if equipped and state.Active then
                        setGlowstickColor(colorName)
                    else
                        warn("[Glowstick] Warna tidak dikirim karena equip gagal.")
                    end
                end)
            end
        end

        --------------------------------------------------
        -- CHAT CONNECTIONS
        --------------------------------------------------

        local function addConnection(connection)
            table.insert(state.Connections, connection)
        end

        -- Chat modern: RBXGeneral.
        local channels = TextChatService:FindFirstChild("TextChannels")
        local general = channels and channels:FindFirstChild("RBXGeneral")

        if general then
            addConnection(general.MessageReceived:Connect(function(message)
                local source = message.TextSource

                if not source then
                    return
                end

                local sender = Players:GetPlayerByUserId(source.UserId)

                if sender then
                    handleCommand(message.Text, sender)
                end
            end))
        else
            warn("[Glowstick] RBXGeneral belum tersedia; menggunakan fallback chat.")
        end

        -- Fallback chat klasik.
        local function connectPlayer(player)
            addConnection(player.Chatted:Connect(function(message)
                handleCommand(message, player)
            end))
        end

        for _, player in ipairs(Players:GetPlayers()) do
            connectPlayer(player)
        end

        addConnection(Players.PlayerAdded:Connect(connectPlayer))

        --------------------------------------------------
        -- RESPAWN
        --------------------------------------------------

        addConnection(LocalPlayer.CharacterAdded:Connect(function()
            task.wait(1)

            if state.Active then
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
            end
        end))

        --------------------------------------------------
        -- DONE
        --------------------------------------------------

        print("[Glowstick] Command system berhasil dimuat.")
        print("[Glowstick] Gunakan !glowstick untuk equip dan !stop untuk unequip.")
    end
}
