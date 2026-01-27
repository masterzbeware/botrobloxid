-- AutoChop.lua
return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      local MainTab = tab or Tabs.Main

      if not MainTab then
          warn("[Auto Chop] Tab tidak ditemukan!")
          return
      end

      -- =========================
      -- UI GROUP
      -- =========================
      local Group = MainTab:AddLeftGroupbox("Auto Chop")

      -- =========================
      -- DEFAULT VARS
      -- =========================
      vars.AutoChop  = vars.AutoChop or false
      vars.ChopDelay = vars.ChopDelay or 0.3
      _G.BotVars = vars

      -- =========================
      -- TOGGLE
      -- =========================
      Group:AddToggle("ToggleAutoChop", {
          Text = "Auto Chop",
          Default = vars.AutoChop,
          Callback = function(v)
              vars.AutoChop = v
              print("[Auto Chop] Toggle:", v and "ON" or "OFF")
          end
      })

      -- =========================
      -- SLIDER DELAY
      -- =========================
      Group:AddSlider("SliderChopDelay", {
          Text = "Delay Chop",
          Default = vars.ChopDelay,
          Min = 0.3,
          Max = 4,
          Rounding = 1,
          Callback = function(v)
              vars.ChopDelay = v
          end
      })

      -- =========================
      -- SERVICES
      -- =========================
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")
      local ChopTree = ReplicatedStorage
          :WaitForChild("Relay")
          :WaitForChild("Blocks")
          :WaitForChild("ChopTree")

      -- =========================
      -- AUTO CHOP LOOP
      -- =========================
      coroutine.wrap(function()
          while true do
              if vars.AutoChop then
                  local blocks = LoadedBlocks:GetChildren()
                  for i, block in ipairs(blocks) do
                      -- asumsi tree = MeshPart + ada VoxelPosition
                      if block:IsA("MeshPart") then
                          local voxel = block:GetAttribute("VoxelPosition")
                          if voxel then
                              task.spawn(function()
                                  local success, err = pcall(function()
                                      ChopTree:InvokeServer(
                                          vector.create(voxel.X, voxel.Y, voxel.Z)
                                      )
                                  end)
                                  if not success then
                                      warn("[Auto Chop] Gagal chop:", err)
                                  end
                              end)
                              task.wait(0.1) -- delay antar tree
                          end
                      end
                  end
                  task.wait(vars.ChopDelay) -- delay antar batch
              else
                  task.wait(1)
              end
          end
      end)()

      print("[Auto Chop] Sistem aktif.")
  end
}
