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

        local LeftGroup = (Tab.AddLeftGroupbox and Tab:AddLeftGroupbox("Server"))
            or Tab:AddRightGroupbox("Server")

        local RightGroup = (Tab.AddRightGroupbox and Tab:AddRightGroupbox("Status"))
            or Tab:AddLeftGroupbox("Status")

        local PlayersBox = LeftGroup:AddLabel(
            "Players\n\n0 / 0"
        )

        local TimeBox = LeftGroup:AddLabel(
            "Server Time\n\n00h:00m:00s"
        )

        local InfoBox = RightGroup:AddLabel(
            "Session\n\nConnected"
        )

        local Players = game:GetService("Players")

        local function formatTime(sec)
            sec = math.floor(sec)
            local h = math.floor(sec / 3600)
            local m = math.floor((sec % 3600) / 60)
            local s = sec % 60
            return string.format("%02dh:%02dm:%02ds", h, m, s)
        end

        task.spawn(function()
            while true do
                PlayersBox:SetText(
                    "Players\n\n" ..
                    Players.NumPlayers .. " / " .. Players.MaxPlayers
                )

                TimeBox:SetText(
                    "Server Time\n\n" ..
                    formatTime(workspace:GetServerTimeNow())
                )

                InfoBox:SetText(
                    "Session\n\nOnline"
                )

                task.wait(1)
            end
        end)
    end
}
