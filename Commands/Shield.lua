local M = {}

return function(args, ctx)
    ctx.State.shieldActive = not ctx.State.shieldActive
    ctx.State.followAllowed = false
    ctx.State.rowActive = false
    ctx.Library:Notify("Shield " .. (ctx.State.shieldActive and "ON" or "OFF"), 3)
end

function M.run(State, localPlayer, targetHRP, moveToPosition, botMapping)
    local botIds = {}
    for id in pairs(botMapping) do table.insert(botIds, tonumber(id)) end
    table.sort(botIds)

    local index = 1
    for i, id in ipairs(botIds) do if id == localPlayer.UserId then index = i break end end

    local targetPos
    if index == 1 then
        targetPos = targetHRP.Position + targetHRP.CFrame.LookVector * State.shieldDistance
    elseif index == 2 then
        targetPos = targetHRP.Position - targetHRP.CFrame.RightVector * State.shieldDistance
    elseif index == 3 then
        targetPos = targetHRP.Position + targetHRP.CFrame.RightVector * State.shieldDistance
    elseif index == 4 then
        targetPos = targetHRP.Position - targetHRP.CFrame.LookVector * State.shieldDistance
    end

    if targetPos then moveToPosition(targetPos, targetHRP.Position + targetHRP.CFrame.LookVector * 50) end
end

return M
