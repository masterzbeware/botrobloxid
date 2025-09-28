local M = {}

function M.execute(args, ctx)
    ctx.State.followAllowed = false
    ctx.State.shieldActive = false
    ctx.State.rowActive = false
    ctx.State.currentFormasiTarget = nil
    ctx.Library:Notify("Bot stopped", 3)
end

return M
