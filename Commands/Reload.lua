return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local VisualTab = tab or Tabs.Combat

        if not VisualTab then
            warn("[COMBAT] Tab Visual tidak ditemukan!")
            return
        end

        -- Buat group sendiri
        local Group = VisualTab:AddLeftGroupbox("Auto Reload")

        -- Variabel toggle default
        vars.ShowSkeleton = vars.ShowSkeleton or false
        vars.ShowTracer   = vars.ShowTracer or false
        vars.ShowDistance = vars.ShowDistance or false

        -- Toggle Skeleton
        Group:AddToggle("ToggleSkeletonESP", {
            Text = "Auto Reload",
            Default = vars.ShowSkeleton,
            Callback = function(v)
                vars.ShowSkeleton = v
            end
        })

        print("[COMBAT] Toggle siap di CombatTab")
    end
}
