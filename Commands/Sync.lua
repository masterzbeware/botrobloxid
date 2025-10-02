return {
    Execute = function(msg, client)
        local Vars = _G.BotVars
        Vars.SyncActive = true  -- flag untuk kontrol sync

        local targetName = msg:match("^!sync%s+(.+)")
        if targetName then
            local found = nil
            for _, plr in ipairs(Vars.Players:GetPlayers()) do
                if plr.DisplayName:lower() == targetName:lower() or plr.Name:lower() == targetName:lower() then
                    found = plr
                    break
                end
            end

            if found then
                -- hentikan sync sebelumnya kalau ada
                if Vars.SyncConnection then
                    task.cancel(Vars.SyncConnection)
                    Vars.SyncConnection = nil
                end

                -- loop sync baru
                Vars.SyncConnection = task.spawn(function()
                    while Vars.SyncActive do
                        local success, err = pcall(function()
                            game:GetService("ReplicatedStorage")
                                :WaitForChild("Events")
                                :WaitForChild("RequestSync")
                                :FireServer(found)
                        end)
                        if not success then
                            warn("Sync error:", err)
                        end
                        task.wait(0.5)
                    end
                end)

                game.StarterGui:SetCore("SendNotification", {
                    Title = "Command",
                    Text = Vars.BotIdentity .. " synced with " .. found.DisplayName
                })
            else
                game.StarterGui:SetCore("SendNotification", {
                    Title = "Command",
                    Text = "Player not found: " .. targetName
                })
            end
        end
    end
}
