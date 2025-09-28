return function(args, ctx)
    local targetName = args[1]
    if not targetName then
        ctx.Library:Notify("Usage: !sync {username/displayname}", 3)
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
        local params = { target }
        ctx.ReplicatedStorage:WaitForChild("Events"):WaitForChild("RequestSync"):FireServer(unpack(params))
        ctx.Library:Notify("Synced with " .. target.DisplayName, 3)
    else
        ctx.Library:Notify("Player not found: " .. targetName, 3)
    end
end
