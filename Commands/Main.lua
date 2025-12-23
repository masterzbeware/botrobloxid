return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local MainTab = tab or Tabs.Main

        if not MainTab then
            warn("[ServerInfo] Tab tidak ditemukan!")
            return
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
                local playerCount = Players.NumPlayers
                local uptime = workspace:GetServerTimeNow()
                ServerInfoLabel:SetText(
                    "Player di Server : " .. playerCount ..
                    "\nServer Aktif : " .. formatTime(uptime)
                )
                task.wait(1)
            end
        end)

        print("[ServerInfo] Loaded ✔")
    end
}
