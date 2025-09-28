local M = {}

function M.execute(args, ctx)
    ctx.State.rowActive = not ctx.State.rowActive
    ctx.State.followAllowed = false
    ctx.State.shieldActive = false
    ctx.Library:Notify("Row " .. (ctx.State.rowActive and "ON" or "OFF"), 3)
end

function M.run(State, localPlayer, targetHRP, moveToPosition, botMapping)
    local botIds = {}
    for id in pairs(botMapping) do table.insert(botIds, tonumber(id)) end
    table.sort(botIds)

    local index = 1
    for i, id in ipairs(botIds) do if id == localPlayer.UserId then index = i break end end

    local targetPos
    if index == 1 then
        targetPos = targetHRP.Position - targetHRP.CFrame.LookVector * State.jarakIkut - targetHRP.CFrame.RightVector * State.sideSpacing
    elseif index == 2 then
        targetPos = targetHRP.Position - targetHRP.CFrame.LookVector * State.jarakIkut + targetHRP.CFrame.RightVector * State.sideSpacing
    elseif index == 3 then
        targetPos = targetHRP.Position - targetHRP.CFrame.LookVector * (State.jarakIkut + State.rowSpacing) - targetHRP.CFrame.RightVector * State.sideSpacing
    elseif index == 4 then
        targetPos = targetHRP.Position - targetHRP.CFrame.LookVector * (State.jarakIkut + State.rowSpacing) + targetHRP.CFrame.RightVector * State.sideSpacing
    end

    if targetPos then moveToPosition(targetPos, targetHRP.Position) end
end

return M
