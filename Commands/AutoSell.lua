-- Shop.lua (Auto Sell Items)
return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}

      -- 🔹 Buat / ambil Tab Shop
      local ShopTab = Tabs.Shop or tab
      if not ShopTab then
          warn("[Shop] Tab tidak ditemukan!")
          return
      end

      local Group = ShopTab:AddLeftGroupbox("Shop")

      vars.AutoSell = vars.AutoSell or false
      _G.BotVars = vars

      -- Toggle Auto Sell
      Group:AddToggle("ToggleAutoSell", {
          Text = "Auto Sell Items",
          Default = vars.AutoSell,
          Callback = function(v)
              vars.AutoSell = v
              print("[Shop] Auto Sell:", v and "ON" or "OFF")
          end
      })

      -- Remote
      local SellItems = game:GetService("ReplicatedStorage")
          :WaitForChild("Relay")
          :WaitForChild("Inventory")
          :WaitForChild("SellItems")

      -- Loop
      coroutine.wrap(function()
          while true do
              if vars.AutoSell then
                  local ok, err = pcall(function()
                      SellItems:InvokeServer()
                  end)

                  if not ok then
                      warn("[Shop] Gagal SellItems:", err)
                  end

                  task.wait(1) -- delay (bisa diubah kalau mau)
              else
                  task.wait(1)
              end
          end
      end)()

      print("[Shop] Sistem aktif.")
  end
}
