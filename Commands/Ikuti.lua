return {
    Execute = function(msg, client)
        local Vars = _G.BotVars
        Vars.FollowAllowed = true
        Vars.ShieldActive = false
        Vars.RowActive = false
        Vars.CurrentFormasiTarget = client
        game.StarterGui:SetCore("SendNotification", {
            Title = "Command",
            Text = Vars.BotIdentity .. " following VIP!"
        })
    end
}
