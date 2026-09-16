-- Administrator/Admin.lua
-- Central admin whitelist (UserId based)
-- Mendukung:
-- 1. Admin utama dari AllowedUsers
-- 2. Admin tambahan dari _G.BotVars.AdditionalAdmins

local Admin = {}

--------------------------------------------------
-- ADMIN UTAMA
--------------------------------------------------

Admin.AllowedUsers = {
    [11611493000] = true, -- MAIN ADMIN
}

--------------------------------------------------
-- CHECK MAIN ADMIN
--------------------------------------------------

function Admin:IsMainAdmin(player)
    if not player then
        return false
    end

    return Admin.AllowedUsers[player.UserId] == true
end

--------------------------------------------------
-- CHECK ADMIN
--------------------------------------------------

function Admin:IsAdmin(player)
    if not player then
        return false
    end

    --------------------------------------------------
    -- ADMIN UTAMA
    --------------------------------------------------

    if Admin.AllowedUsers[player.UserId] == true then
        return true
    end

    --------------------------------------------------
    -- ADMIN TAMBAHAN
    --------------------------------------------------

    _G.BotVars = _G.BotVars or {}

    _G.BotVars.AdditionalAdmins =
        _G.BotVars.AdditionalAdmins or {}

    return _G.BotVars.AdditionalAdmins[player.UserId] == true
end

--------------------------------------------------
-- RETURN
--------------------------------------------------

return Admin