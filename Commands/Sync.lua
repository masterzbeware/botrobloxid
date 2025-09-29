return {
    Execute = function(msg, client)
        local Vars = _G.BotVars
        local targetName = msg:match("^!sync%s+(.+)")
        if targetName then
            local found = nil
            for _, plr in ipairs(Vars.Players:GetPlayers()) do
                if plr.DisplayName:lower() == targetName or plr.Name:lower() == targetName then
                    found = plr
                    break
                end
            end
            if found then
                local args = { found }
                game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("RequestSync"):FireServer(unpack(args))
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
