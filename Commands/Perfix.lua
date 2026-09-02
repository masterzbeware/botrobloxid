-- Perfix.lua
-- Core / Prefix Loader (tanpa Tab)

return {
  Execute = function()
      _G.BotVars = _G.BotVars or {}
      local vars = _G.BotVars

      -- Ambil MainWindow dari loader utama
      if not vars.MainWindow then
          warn("[Perfix] MainWindow not found")
          return
      end

      -- Prefix command (kalau nanti mau dipakai)
      vars.Prefix = vars.Prefix or "!"

      -- Status bot
      vars.BotReady = true

      print("[Perfix] Loaded successfully")
  end
}
