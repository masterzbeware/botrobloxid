return {
    Execute = function(msg, client)
        local Vars = _G.BotVars
        Vars.SyncActive = true  -- flag untuk kontrol

        local targetName = msg:match("^!sync%s+(.+)")
        if targetName then
            local found = nil
            for _, plr in ipairs(Vars.Players:GetPlayers()) do
                if plr.DisplayName:lower() == targetName:lower() or plr.Name:lower() == targetName:lower() then
                    found = plr
                    break
                end
            end
            if found then
                -- cek flag setiap saat sebelum sync
                spawn(function()
                    while Vars.SyncActive do
                        local args = { found }
                        game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("RequestSync"):FireServer(unpack(args))
                        wait(0.5) -- interval sync
                    end
                end)

                game.StarterGui:SetCore("SendNotification", {
                    Title = "Command",
                    Text = Vars.BotIdentity .. " synced with " .. found.DisplayName
                })
            else
                game.StarterGui:SetCore("SendNotification", {
                    Title = "Command",
                    Text = "Player not found: " .. targetName
                })
            end
        end
    end
}
