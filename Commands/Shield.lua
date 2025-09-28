return {
    Execute = function(msg, client)
        local Vars = _G.BotVars
        Vars.ShieldActive = not Vars.ShieldActive
        Vars.FollowAllowed = false
        Vars.RowActive = false
        game.StarterGui:SetCore("SendNotification", {
            Title = "Command",
            Text = "Shield " .. (Vars.ShieldActive and "Activated" or "Deactivated")
        })
    end
}
