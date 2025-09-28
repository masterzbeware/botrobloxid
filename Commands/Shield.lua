return {
    execute = function(args, ctx)
        local targetName = args[1]
        if not targetName then
            ctx.Library:Notify("Usage: !shield {username/displayname}", 3)
            return
        end

        local target = nil
        for _, plr in ipairs(ctx.Players:GetPlayers()) do
            if plr.Name:lower():find(targetName:lower()) or plr.DisplayName:lower():find(targetName:lower()) then
                target = plr
                break
            end
        end

        if target then
            ctx.State.currentFormasiTarget = target
            ctx.State.shieldActive = true
            ctx.State.rowActive = false
            ctx.State.followAllowed = false
            ctx.Library:Notify("Shield formation active for " .. target.DisplayName, 3)
        else
            ctx.Library:Notify("Player not found: " .. targetName, 3)
        end
    end,

    run = function(State, localPlayer, targetHRP, moveToPosition, botMapping)
        if not State.shieldActive then return end

        local botName = botMapping[tostring(localPlayer.UserId)]
        if not botName then return end

        local index = tonumber(string.match(botName, "%d+")) or 0
        local offsetX = (index - 2) * State.shieldSpacing
        local shieldPos = targetHRP.CFrame * CFrame.new(offsetX, 0, -State.shieldDistance)

        moveToPosition(shieldPos.Position, targetHRP.Position)
    end,
}
