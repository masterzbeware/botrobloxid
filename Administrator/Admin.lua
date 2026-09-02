-- Administrator/Admin.lua
-- Central admin whitelist (UserId based)

local Admin = {}

Admin.AllowedUsers = {
    [10190678566] = true, -- MAIN ADMIN
}

function Admin:IsAdmin(player)
    if not player then return false end
    return Admin.AllowedUsers[player.UserId] == true
end

return Admin
