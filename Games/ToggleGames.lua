-- ToggleGames.lua
-- Command: !ongames / !offgames
-- Mengatur status ToggleGames tanpa notifikasi chat

return {
  Execute = function(msg, client)
      local vars = _G.BotVars or {}
      msg = msg:lower()

      if msg:match("^!ongames") then
          vars.ToggleGameActive = true
          print("[COMMAND] ToggleGames set to TRUE by client:", client and client.Name or "Unknown")
      elseif msg:match("^!offgames") then
          vars.ToggleGameActive = false
          print("[COMMAND] ToggleGames set to FALSE by client:", client and client.Name or "Unknown")
      end
  end
}
