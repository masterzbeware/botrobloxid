return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local CombatTab = tab or Tabs.Combat

        if not CombatTab then
            warn("[NoSpread] Tab Combat tidak ditemukan!")
            return
        end

        local Group = CombatTab:AddLeftGroupbox("No Spread (M4A1)")

        vars.NoSpread = vars.NoSpread or false

        local ReplicatedFirst = game:GetService("ReplicatedFirst")
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        local camera = workspace.CurrentCamera

        local BulletService = ReplicatedFirst:WaitForChild("Actor"):WaitForChild("BulletServiceMultithread")
        local Send = BulletService:WaitForChild("Send")

        Group:AddToggle("ToggleNoSpread", {
            Text = "No Spread",
            Default = vars.NoSpread,
            Callback = function(v)
                vars.NoSpread = v
            end
        })

        local oldFire
        oldFire = hookfunction(Send.Fire, function(self, ...)
            local args = {...}
            if vars.NoSpread and args[3] and type(args[3]) == "table" then
                local data = args[3]
                data.OriginCFrame = CFrame.new(camera.CFrame.Position, camera.CFrame.Position + camera.CFrame.LookVector)
                data.Spread = 0
                data.Range = 9999
                args[3] = data
            end
            return oldFire(self, unpack(args))
        end)

        print("✅ [NoSpread] Aktif - M4A1 tanpa spread siap digunakan.")
    end
}
