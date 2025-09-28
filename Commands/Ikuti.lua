return {
    execute = function(args, ctx)
        local targetName = args[1]
        if not targetName then
            ctx.Library:Notify("Usage: !ikuti {username/displayname}", 3)
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
            ctx.State.followAllowed = true
            ctx.State.shieldActive = false
            ctx.State.rowActive = false
            ctx.Library:Notify("Following " .. target.DisplayName, 3)
        else
            ctx.Library:Notify("Player not found: " .. targetName, 3)
        end
    end,

    run = function(State, localPlayer, targetHRP, moveToPosition, botMapping)
        if not State.followAllowed then return end

        local botName = botMapping[tostring(localPlayer.UserId)]
        if not botName then return end

        local spacing = State.followSpacing
        local offsetZ = -State.jarakIkut - (tonumber(string.match(botName, "%d+")) or 0) * spacing
        local followPos = targetHRP.CFrame * CFrame.new(0, 0, offsetZ)

        moveToPosition(followPos.Position, targetHRP.Position)
    end,
}
