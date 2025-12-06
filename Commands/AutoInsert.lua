return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      local MainTab = tab or Tabs.Main

      if not MainTab then
          warn("[Auto Insert] Tab tidak ditemukan!")
          return
      end

      -- UI GROUP
      local Group = MainTab:AddLeftGroupbox("Auto Insert Items")

      -- DEFAULT VARS
      vars.AutoInsert = vars.AutoInsert or false
      vars.InsertDelay = vars.InsertDelay or 1 -- default 1 detik
      vars.InsertTarget = vars.InsertTarget or "Small Food Trough" -- default target
      _G.BotVars = vars -- pastikan disimpan global

      -- TOGGLE
      Group:AddToggle("ToggleAutoInsert", {
          Text = "Auto Insert",
          Default = vars.AutoInsert,
          Callback = function(v)
              vars.AutoInsert = v
          end
      })

      -- DROPDOWN PILIH BLOCK
      -- Obsidian kadang butuh delay, kita gunakan spawn
      spawn(function()
          task.wait(0.1)
          Group:AddDropdown("DropdownInsertTarget", {
              Text = "Pilih Block",
              Default = vars.InsertTarget,
              Options = {"Small Food Trough", "Butter Churn", "Small Water Trough", "Compost Bin"},
              Callback = function(v)
                  vars.InsertTarget = v
                  print("[Auto Insert] Target diubah ke:", v)
              end
          })
      end)

      -- SLIDER DELAY
      Group:AddSlider("SliderInsertDelay", {
          Text = "Delay Insert",
          Default = vars.InsertDelay,
          Min = 0.5,
          Max = 2,
          Rounding = 1,
          Compact = false,
          Callback = function(v)
              vars.InsertDelay = v
          end
      })

      -- SERVICES
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")
      local Blocks = ReplicatedStorage:WaitForChild("Relay"):WaitForChild("Blocks")
      local InsertItem = Blocks:WaitForChild("InsertItem")

      -- LOOP SYSTEM
      coroutine.wrap(function()
          while true do
              if not vars.AutoInsert then
                  task.wait(0.1)
              else
                  for _, block in ipairs(LoadedBlocks:GetChildren()) do
                      if block.Name == vars.InsertTarget then
                          local voxel = block:GetAttribute("VoxelPosition")
                          if voxel then
                              local success, err = pcall(function()
                                  InsertItem:InvokeServer(vector.create(voxel.X, voxel.Y, voxel.Z))
                              end)
                              if success then
                                  print("Berhasil insert ke:", block.Name)
                              else
                                  warn("Gagal insert ke:", block.Name, err)
                              end
                          end
                      end
                  end
                  task.wait(vars.InsertDelay)
              end
          end
      end)()

      print("[Auto Insert] Sistem aktif. Target:", vars.InsertTarget)
  end
}
