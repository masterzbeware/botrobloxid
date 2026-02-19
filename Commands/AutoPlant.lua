-- AutoPlanter.lua (one-by-one, batch delay)
return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      local MainTab = tab or Tabs.Main

      if not MainTab then
          warn("[Auto Planter] Tab tidak ditemukan!")
          return
      end

      local Group = MainTab:AddLeftGroupbox("Auto Planter Cart")

      vars.AutoPlanter  = vars.AutoPlanter or false
      vars.PlanterDelay = vars.PlanterDelay or 0.5
      _G.BotVars = vars

      Group:AddToggle("ToggleAutoPlanter", {
          Text = "Auto Planter",
          Default = vars.AutoPlanter,
          Callback = function(v)
              vars.AutoPlanter = v
              print("[Auto Planter] Toggle:", v and "ON" or "OFF")
          end
      })

      Group:AddSlider("SliderPlanterDelay", {
          Text = "Delay Antar Batch",
          Default = vars.PlanterDelay,
          Min = 0.5,
          Max = 4,
          Rounding = 1,
          Callback = function(v)
              vars.PlanterDelay = v
          end
      })

      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")
      local UsePlanterCart = ReplicatedStorage:WaitForChild("Relay")
          :WaitForChild("Blocks")
          :WaitForChild("UsePlanterCart")

      local function isOccupied(voxel)
          for _, block in ipairs(LoadedBlocks:GetChildren()) do
              local v2 = block:GetAttribute("VoxelPosition")
              if v2 and v2.X == voxel.X and v2.Y == voxel.Y and v2.Z == voxel.Z then
                  return true
              end
          end
          return false
      end

      coroutine.wrap(function()
          while true do
              if vars.AutoPlanter then
                  local blocks = LoadedBlocks:GetChildren()
                  for i, block in ipairs(blocks) do
                      if block.Name == "Farmland" then
                          local voxel = block:GetAttribute("VoxelPosition")
                          if voxel then
                              local above = Vector3.new(voxel.X, voxel.Y + 1, voxel.Z)
                              if not isOccupied(above) then
                                  task.spawn(function()
                                      local success, err = pcall(function()
                                          UsePlanterCart:InvokeServer(above)
                                      end)
                                      if success then
                                          print("Planter Cart ke-", i, "berhasil")
                                      else
                                          warn("Gagal Planter Cart ke-", i, err)
                                      end
                                  end)
                                  task.wait(0.1) -- delay antar block
                              end
                          end
                      end
                  end
                  task.wait(vars.PlanterDelay) -- delay antar batch
              else
                  task.wait(1)
              end
          end
      end)()

      print("[Auto Planter] Sistem aktif.")
  end
}
