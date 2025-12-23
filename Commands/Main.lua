return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        _G.BotVars = vars

        local Library = vars.Library
        local Window = vars.MainWindow

        if not Library or not Window then
            warn("[ServerInfo] Library / Window belum siap")
            return
        end

        vars.Tabs = vars.Tabs or {}

        local MainTab = tab
        if not MainTab then
            if not vars.Tabs.Main then
                vars.Tabs.Main = Window:AddTab("Main")
            end
            MainTab = vars.Tabs.Main
        end

        local Group = (MainTab.AddRightGroupbox and MainTab:AddRightGroupbox("Server Info"))
            or MainTab:AddLeftGroupbox("Server Info")

        local ServerInfoLabel = Group:AddLabel("Loading...")

        local Players = game:GetService("Players")

        local function formatTime(seconds)
            seconds = math.floor(seconds)
            local h = math.floor(seconds / 3600)
            local m = math.floor((seconds % 3600) / 60)
            local s = seconds % 60
            return string.format("%02d:%02d:%02d", h, m, s)
        end

        task.spawn(function()
            while true do
                ServerInfoLabel:SetText(
                    "Player di Server : " .. Players.NumPlayers ..
                    "\nServer Aktif : " .. formatTime(workspace:GetServerTimeNow())
                )
                task.wait(1)
            end
        end)

        print("[ServerInfo] Loaded ✔")
    end
}
