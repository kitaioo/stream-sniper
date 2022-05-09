local user_id = "3485422903"
local game_id = tostring(game.PlaceId)

local start_tick = tick()
local http_service = game:GetService("HttpService")

local image_request = syn.request({
    Url = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=".. user_id .. "&size=150x150&format=Png&isCircular=false"
})

local image_url = http_service:JSONDecode(image_request.Body).data[1].imageUrl

local servers, cursor = {}

local index = 0
while true do
    local data = syn.request({
        Url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Desc&limit=100%s", game_id, cursor and "&cursor=" .. cursor or "")
    })
    data = http_service:JSONDecode(data.Body)
    index = index + 1
    for _, server in pairs(data.data) do
        for i = 1, #server.playerTokens do
            table.insert(servers, {
                token = server.playerTokens[i],
                type = "AvatarHeadshot",
                size = "150x150",
                requestId = server.id
            })
        end
    end
    task.spawn(function()
        local post_data = {}
        for i = 1, 100 do
            local server_i = table.remove(servers)
            table.insert(post_data, server_i)
        end
        local post_request = syn.request({
            Url = "https://thumbnails.roblox.com/v1/batch",
            Method = "POST",
            Body = http_service:JSONEncode(post_data),
            Headers = {
                ["Content-Type"] = "application/json"
            }
        })
        local post_data = http_service:JSONDecode(post_request.Body).data
        if not post_data then
            return
        end
        rconsoleprint("searching server " .. post_data[index].requestId .. "\n")
        for _, v in next, post_data do
            if v.imageUrl == image_url then
                warn("found server " .. v.requestId .. " in " .. math.floor(tick() - start_tick) .. " seconds\n")
                game:GetService("TeleportService"):TeleportToPlaceInstance(game_id, v.requestId)
            end
        end
    end)
    if not data.nextPageCursor then
        break
    end
    cursor = data.nextPageCursor
end
