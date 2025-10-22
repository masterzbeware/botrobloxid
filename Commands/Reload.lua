return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local VisualTab = tab or Tabs.Visual

        if not VisualTab then
            warn("[ESP] Tab Visual tidak ditemukan!")
            return
        end

        -- Buat group sendiri
        local Group = VisualTab:AddLeftGroupbox("ESP Control")

        -- Variabel toggle default
        vars.ShowSkeleton = vars.ShowSkeleton or false
        vars.ShowTracer   = vars.ShowTracer or false
        vars.ShowDistance = vars.ShowDistance or false

        -- Toggle Skeleton
        Group:AddToggle("ToggleSkeletonESP", {
            Text = "Tampilkan Skeleton",
            Default = vars.ShowSkeleton,
            Callback = function(v)
                vars.ShowSkeleton = v
            end
        })

        -- Toggle Tracer
        Group:AddToggle("ToggleTracerESP", {
            Text = "Tampilkan Tracer",
            Default = vars.ShowTracer,
            Callback = function(v)
                vars.ShowTracer = v
            end
        })

        -- Toggle Distance
        Group:AddToggle("ToggleDistanceESP", {
            Text = "Tampilkan Distance",
            Default = vars.ShowDistance,
            Callback = function(v)
                vars.ShowDistance = v
            end
        })

        print("✅ [ESP] Toggle siap di VisualTab")
    end
}
