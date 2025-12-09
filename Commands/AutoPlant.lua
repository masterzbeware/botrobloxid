-- AutoPlanter.lua
return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      local MainTab = tab or Tabs.Main

      if not MainTab then
          warn("[Auto Planter] Tab tidak ditemukan!")
          return
      end

      -- =========================
      -- UI GROUP
      -- =========================
      local Group = MainTab:AddLeftGroupbox("Auto Planter Cart")

      -- =========================
      -- DEFAULT VARS
      -- =========================
      vars.AutoPlanter   = vars.AutoPlanter or false
      vars.PlanterDelay  = vars.PlanterDelay or 0.3
      _G.BotVars = vars

      -- =========================
      -- TOGGLE
      -- =========================
      Group:AddToggle("ToggleAutoPlanter", {
          Text = "Auto Planter",
          Default = vars.AutoPlanter,
          Callback = function(v)
              vars.AutoPlanter = v
              print("[Auto Planter] Toggle:", v and "ON" or "OFF")
          end
      })

      -- =========================
      -- SERVICES
      -- =========================
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")
      local UsePlanterCart = ReplicatedStorage:WaitForChild("Relay")
          :WaitForChild("Blocks")
          :WaitForChild("UsePlanterCart")

      -- =========================
      -- CEK FARMLAND TERISI
      -- =========================
      local function isOccupied(voxel)
          for _, block in ipairs(LoadedBlocks:GetChildren()) do
              local v2 = block:GetAttribute("VoxelPosition")
              if v2 and v2.X == voxel.X and v2.Y == voxel.Y and v2.Z == voxel.Z then
                  return true
              end
          end
          return false
      end

      -- =========================
      -- AUTO PLANT LOOP
      -- =========================
      coroutine.wrap(function()
          while true do
              if vars.AutoPlanter then
                  for _, block in ipairs(LoadedBlocks:GetChildren()) do
                      if block.Name == "Farmland" then
                          local voxel = block:GetAttribute("VoxelPosition")
                          if voxel then
                              local above = Vector3.new(voxel.X, voxel.Y + 1, voxel.Z)

                              if not isOccupied(above) then
                                  -- Spawn thread ringan untuk tiap voxel
                                  task.spawn(function()
                                      pcall(function()
                                          UsePlanterCart:InvokeServer(above)
                                      end)
                                  end)
                                  -- delay mini antar voxel untuk kurangi lag
                                  task.wait(0.05)
                              end
                          end
                      end
                  end
                  task.wait(vars.PlanterDelay)
              else
                  task.wait(0.05)
              end
          end
      end)()

      print("[Auto Planter] Sistem aktif.")
  end
}
