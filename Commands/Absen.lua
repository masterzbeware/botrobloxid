-- Absen.lua
-- Menampilkan UI + Toggle + Eksekusi Absen Command

return {
    Execute = function(msg, client)
        local vars = _G.BotVars
        local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
        local Window = Library:CreateWindow({
            Title = "MasterZ Bot Control",
            Footer = "Absen Panel",
            Icon = 0,
            ShowCustomCursor = true,
        })

        local Tabs = {
            Control = Window:AddTab("Control", "settings"),
        }

        local Group = Tabs.Control:AddLeftGroupbox("Absen Control")

        -- ✅ Enable toggle utama
        Group:AddToggle("EnableBotSystem", {
            Text = "Aktifkan Bot System",
            Default = vars.ToggleAktif,
            Callback = function(Value)
                vars.ToggleAktif = Value
                print("[Absen] ToggleAktif:", Value)
            end
        })

        -- ⚙️ Input pengaturan jarak & spacing
        Group:AddInput("JarakIkut", {
            Default = tostring(vars.JarakIkut),
            Text = "Follow Distance",
            Callback = function(v) vars.JarakIkut = tonumber(v) or vars.JarakIkut end
        })

        Group:AddInput("FollowSpacing", {
            Default = tostring(vars.FollowSpacing),
            Text = "Follow Spacing",
            Callback = function(v) vars.FollowSpacing = tonumber(v) or vars.FollowSpacing end
        })

        Group:AddInput("ShieldDistance", {
            Default = tostring(vars.ShieldDistance),
            Text = "Shield Distance",
            Callback = function(v) vars.ShieldDistance = tonumber(v) or vars.ShieldDistance end
        })

        Group:AddInput("RowSpacing", {
            Default = tostring(vars.RowSpacing),
            Text = "Row Spacing",
            Callback = function(v) vars.RowSpacing = tonumber(v) or vars.RowSpacing end
        })

        Group:AddInput("SideSpacing", {
            Default = tostring(vars.SideSpacing),
            Text = "Side Spacing",
            Callback = function(v) vars.SideSpacing = tonumber(v) or vars.SideSpacing end
        })

        Group:AddButton("Mulai Absen", function()
            print("[Absen] Perintah !absen dijalankan")
            if vars.CommandFiles and vars.CommandFiles["absen"] and vars.CommandFiles["absen"].Execute then
                vars.CommandFiles["absen"].Execute("!absen", client)
            else
                warn("Command Absen tidak ditemukan!")
            end
        end)

        print("✅ Absen UI aktif — semua toggle & input dipindah dari Bot.lua")
    end
}
