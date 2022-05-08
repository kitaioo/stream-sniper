local user_id = "3515195953"
local game_id = "3976767347"

local http_service = game:GetService("HttpService")

local image_request = syn.request({
    Url = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=".. user_id .. "&size=150x150&format=Png&isCircular=false"
})

local image_url = http_service:JSONDecode(image_request.Body).data[1].imageUrl

local servers, cursor = {}
local function get_servers()
    while true do
        local data = syn.request({
            Url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Desc&limit=100%s", game_id, cursor and "&cursor=" .. cursor or "")
        })
        data = http_service:JSONDecode(data.Body)
        for _, server in pairs(data.data) do
            servers[#servers + 1] = {
                server_id = server.id,
                player_tokens = server.playerTokens
            }
        end
        if not data.nextPageCursor then
            break
        end
        cursor = data.nextPageCursor
    end
    return servers
end

rconsoleprint("gathering servers...\n")
local servers = get_servers()
rconsoleprint("found " .. #servers .. " servers\n")
for _, server in pairs(servers) do
    local server_data = {}
    for i = 1, #server.player_tokens do
        table.insert(server_data, {
            token = server.player_tokens[i],
            type = "AvatarHeadshot",
            size = "150x150"
        })
    end
    local post_request = syn.request({
        Url = "https://thumbnails.roblox.com/v1/batch",
        Method = "POST",
        Body = http_service:JSONEncode(server_data),
        Headers = {
            ["Content-Type"] = "application/json"
        }
    })
    rconsoleprint("searching server " .. server.server_id .. "\n")
    for _, v in next, http_service:JSONDecode(post_request.Body).data do
        if v.imageUrl == image_url then
            game:GetService("TeleportService"):TeleportToPlaceInstance(game_id, server.server_id)
        end
    end
end
