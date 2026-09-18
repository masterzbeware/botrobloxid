return {
    Execute = function()
        local vars = _G.BotVars

        if not vars then
            warn("[Main] _G.BotVars tidak ditemukan!")
            return
        end

        local Window = vars.MainWindow

        if not Window then
            warn("[Main] MainWindow tidak ditemukan!")
            return
        end

        vars.Tabs = vars.Tabs or {}

        --==================================================
        -- TAB HOME
        --==================================================

        if not vars.Tabs.Main then
            vars.Tabs.Main = Window:AddTab("Home")
        end

        local Tab = vars.Tabs.Main

        --==================================================
        -- SERVER GROUP
        --==================================================

        local ServerGroup =
            (Tab.AddLeftGroupbox and Tab:AddLeftGroupbox("Server"))
            or Tab:AddRightGroupbox("Server")

        --==================================================
        -- STATUS GROUP
        --==================================================

        local StatusGroup =
            (Tab.AddRightGroupbox and Tab:AddRightGroupbox("Status"))
            or Tab:AddLeftGroupbox("Status")

        --==================================================
        -- LIST COMMAND GROUP 1
        --==================================================

        local CommandGroup1 =
            (Tab.AddLeftGroupbox and Tab:AddLeftGroupbox("List Command 1"))
            or Tab:AddRightGroupbox("List Command 1")

        --==================================================
        -- LIST COMMAND GROUP 2
        --==================================================

        local CommandGroup2 =
            (Tab.AddRightGroupbox and Tab:AddRightGroupbox("List Command 2"))
            or Tab:AddLeftGroupbox("List Command 2")

        --==================================================
        -- SERVER INFO
        --==================================================

        local PlayersLabel = ServerGroup:AddLabel("Players\n0")
        local TimeLabel = ServerGroup:AddLabel("Server Time\n0h:00m:00s")

        --==================================================
        -- STATUS INFO
        --==================================================

        local StatusLabel = StatusGroup:AddLabel("Session\nOffline")

        --==================================================
        -- COMMAND LIST
        --==================================================

        local commands1 = {
            "!perfix",
            "!main",
            "!follow",
            "!frontline",
            "!circle",
            "!fourline",
            "!backline",
            "!rest",
            "!salute",
            "!sit",
            "!agree",
            "!pushup",
        }

        local commands2 = {
            "!message",
            "!collision",
            "!ateezdance",
            "!gabresdance",
            "!pakodidance",
            "!kangoradance",
            "!asmaradance",
            "!pargoydance",
            "!vacationdance",
            "!brazildance",
            "!ketlindance",
            "!harleydance",
            "!heeseungdance",
            "!worship",
        }

        for _, commandName in ipairs(commands1) do
            CommandGroup1:AddLabel(commandName)
        end

        for _, commandName in ipairs(commands2) do
            CommandGroup2:AddLabel(commandName)
        end

        --==================================================
        -- SERVER UPDATE
        --==================================================

        local Players = vars.Players
        local RunService = vars.RunService

        if Players then
            local function updatePlayers()
                local playerCount = #Players:GetPlayers()

                PlayersLabel:SetText(
                    "Players\n" .. tostring(playerCount)
                )
            end

            updatePlayers()

            Players.PlayerAdded:Connect(updatePlayers)
            Players.PlayerRemoving:Connect(updatePlayers)
        end

        --==================================================
        -- SERVER TIME UPDATE
        --==================================================

        if RunService then
            local startTime = os.clock()

            RunService.Heartbeat:Connect(function()
                local elapsed = math.floor(os.clock() - startTime)

                local hours = math.floor(elapsed / 3600)
                local minutes = math.floor((elapsed % 3600) / 60)
                local seconds = elapsed % 60

                TimeLabel:SetText(
                    string.format(
                        "Server Time\n%dh:%02dm:%02ds",
                        hours,
                        minutes,
                        seconds
                    )
                )
            end)
        end

        --==================================================
        -- SESSION STATUS
        --==================================================

        if vars.LocalPlayer then
            StatusLabel:SetText(
                "Session\nOnline\n" .. vars.LocalPlayer.Name
            )
        else
            StatusLabel:SetText("Session\nOffline")
        end

        print("[Main] Home tab berhasil dibuat.")
    end
}