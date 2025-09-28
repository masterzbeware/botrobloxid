return function(args, ctx)
    ctx.State.followAllowed, ctx.State.shieldActive, ctx.State.rowActive, ctx.State.currentFormasiTarget = false, false, false, nil
    ctx.Library:Notify("Bot stopped", 3)
end
