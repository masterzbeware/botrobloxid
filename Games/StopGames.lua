-- StopGames.lua
-- Commands: !ongames / !offgames
-- Mengaktifkan atau menonaktifkan ToggleGames tanpa notifikasi chat

return {
  Execute = function(msg, client)
      local vars = _G.BotVars or {}
      local command = msg:lower()

      if command == "!ongames" then
          vars.ToggleGameActive = true
      elseif command == "!offgames" then
          vars.ToggleGameActive = false
      else
          return -- command tidak dikenal
      end

      -- Debug/log di console
      print("[COMMAND] ToggleGames set to:", vars.ToggleGameActive, "by client:", client and client.Name or "Unknown")
  end
}
