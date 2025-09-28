return {
    Execute = function(msg, client)
        local Vars = _G.BotVars
        Vars.RowActive = not Vars.RowActive
        Vars.FollowAllowed = false
        Vars.ShieldActive = false
        game.StarterGui:SetCore("SendNotification", {
            Title = "Command",
            Text = Vars.BotIdentity .. " Row " .. (Vars.RowActive and "Activated" or "Deactivated")
        })
    end
}
