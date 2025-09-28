return {
    Execute = function(msg, client)
        local Vars = _G.BotVars
        Vars.FollowAllowed = false
        Vars.ShieldActive = false
        Vars.RowActive = false
        Vars.CurrentFormasiTarget = nil
        game.StarterGui:SetCore("SendNotification", {
            Title = "Command",
            Text = "Stop command executed!"
        })
    end
}
