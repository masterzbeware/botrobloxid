return {
    Execute = function()
        local vars = _G.BotVars or {}
        _G.BotVars = vars

        local Window = vars.MainWindow
        if not Window then return end

        vars.Tabs = vars.Tabs or {}
        if not vars.Tabs.Main then
            vars.Tabs.Main = Window:AddTab("Home")
        end

        local Tab = vars.Tabs.Main

        -- Groupbox kiri & kanan (mirip Ronix)
        local ServerGroup = (Tab.AddLeftGroupbox and Tab:AddLeftGroupbox("Server"))
            or Tab:AddRightGroupbox("Server")

        local StatusGroup = (Tab.AddRightGroupbox and Tab:AddRightGroupbox("Status"))
            or Tab:AddLeftGroupbox("Status")

        -- Label ala RonixHub
        local PlayersLabel = ServerGroup:AddLabel("Players\n0")
        local TimeLabel = ServerGroup:AddLabel("Server Time\n0h:00m:00s")
        local StatusLabel = StatusGroup:AddLabel("Session\nOffline")

        local Players = game:GetService("Players")
        local startTime = os.clock()

        -- Format waktu seperti RonixHub
        local function formatUptime(sec)
            sec = math.floor(sec)
            local h = math.floor(sec / 3600)
            local m = math.floor((sec % 3600) / 60)
            local s = sec % 60
            return string.format("%dh:%02dm:%02ds", h, m, s)
        end

        task.spawn(function()
            while true do
                -- Players
                PlayersLabel:SetText(
                    "Players\n" ..
                    Players.NumPlayers .. " / " .. Players.MaxPlayers
                )

                -- Server Time / Uptime
                TimeLabel:SetText(
                    "Server Time\n" ..
                    formatUptime(os.clock() - startTime)
                )

                -- Status
                StatusLabel:SetText(
                    "Session\nOnline"
                )

                task.wait(1)
            end
        end)
    end
}
