-- NoRecoil.lua
-- Menghilangkan efek recoil kamera pemain
-- Bisa dipasang bareng Headshot.lua

return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      _G.BotVars = vars
      local Tabs = vars.Tabs or {}
      local RunService = game:GetService("RunService")
      local Camera = workspace.CurrentCamera

      tab = tab or (Tabs.Combat or Tabs.Main)
      if not tab then
          warn("[NoRecoil] Tab Combat tidak ditemukan.")
          return
      end

      vars.NoRecoil = vars.NoRecoil or false

      local Group = tab:AddLeftGroupbox("No Recoil")
      Group:AddToggle("NoRecoil", {
          Text = "Aktifkan No Recoil",
          Default = vars.NoRecoil,
          Callback = function(Value)
              vars.NoRecoil = Value
              print(Value and "[NoRecoil] Efek recoil dinonaktifkan ✅" or "[NoRecoil] Dinonaktifkan ❌")
          end
      })

      -- Simpan posisi kamera stabil
      local stableCF = nil

      RunService.RenderStepped:Connect(function()
          if not vars.NoRecoil then
              stableCF = Camera.CFrame
              return
          end

          -- Jaga agar kamera tidak goyah
          if stableCF then
              Camera.CFrame = Camera.CFrame:Lerp(stableCF, 0.25)
          else
              stableCF = Camera.CFrame
          end
      end)

      print("✅ [NoRecoil] Sistem siap, toggle tersedia di tab Combat.")
  end
}
