return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      local OvenTab = tab or Tabs.Oven

      if not OvenTab then
          warn("[Auto Oven] Tab Oven tidak ditemukan!")
          return
      end

      -- Ganti ke RightGroup
      local Group = OvenTab:AddRightGroupbox("Auto Oven")

      vars.AutoOven = vars.AutoOven or false

      Group:AddToggle("ToggleAutoOven", {
          Text = "Auto Oven",
          Default = vars.AutoOven,
          Callback = function(v)
              vars.AutoOven = v
          end
      })

      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local CraftItem = ReplicatedStorage:WaitForChild("Relay"):WaitForChild("Inventory"):WaitForChild("CraftItem")
      local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")

      -- Coroutine untuk loop auto oven
      coroutine.wrap(function()
          while true do
              if vars.AutoOven then
                  for _, block in ipairs(LoadedBlocks:GetChildren()) do
                      local voxel = block:GetAttribute("VoxelPosition")
                      if voxel then
                          pcall(function()
                              CraftItem:InvokeServer("Baker's Oven", "Chocolate Bar", Vector3.new(voxel.X, voxel.Y, voxel.Z))
                          end)
                      end
                  end
                  task.wait(0) -- super cepat tapi tetap yield
              else
                  task.wait(1)
              end
          end
      end)()

      print("Sistem Auto Oven aktif (mode super cepat) di RightGroup.")
  end
}
