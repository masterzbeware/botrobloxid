return function(args, ctx)
    ctx.State.followAllowed = true
    ctx.State.shieldActive = false
    ctx.State.rowActive = false
    ctx.State.currentFormasiTarget = ctx.Client
    ctx.Library:Notify("Following VIP", 3)
end

-- fungsi jalanin posisi
local M = {}
function M.run(State, localPlayer, targetHRP, moveToPosition, botMapping)
    local botIds = {}
    for id in pairs(botMapping) do table.insert(botIds, tonumber(id)) end
    table.sort(botIds)

    local index = 1
    for i, id in ipairs(botIds) do if id == localPlayer.UserId then index = i break end end

    local followPos = targetHRP.Position - targetHRP.CFrame.LookVector * (State.jarakIkut + (index - 1) * State.followSpacing)
    moveToPosition(followPos, targetHRP.Position)
end
return M
