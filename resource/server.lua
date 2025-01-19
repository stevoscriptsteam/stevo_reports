if not lib.checkDependency('stevo_lib', '1.7.3') then error('stevo_lib 1.7.3 required for stevo_reports') end
lib.locale()
local config = require('config')
local stevo_lib = exports['stevo_lib']:import()
local reports = {}
local logWebhook = 'WEBHOOK HERE'

local function sendWebhook(title, message)

    local embed = {
        {
            ["title"] = title,
            ["description"] = message,
            ["type"] = "rich",
            ["color"] = 0x02dddd,
            ["thumbnail"] = { ['url'] = "https://i.postimg.cc/F15fCBm2/RACOON.png" },
            ["footer"] = {
                ["text"] = 'Stevo Scripts - https://discord.gg/stevoscripts',
            },
        }
    }

    PerformHttpRequest(logWebhook, function(err, text, headers) end, 'POST', json.encode({username = "Stevo Reports", embeds = embed}), { ['Content-Type'] = 'application/json' })
end

lib.callback.register('stevo_reports:requestCoords', function(source, targetSource)
    if not IsPlayerAceAllowed(source, config.perms.reportsCommand) then return end

    local ped = GetPlayerPed(targetSource)
    local coords = GetEntityCoords(ped)

    return ped and coords or false
end)

RegisterNetEvent('stevo_reports:teleportAction', function(target, isGoto)
    if not IsPlayerAceAllowed(source, config.perms.reportsCommand) then return end

    local adminName = GetPlayerName(source)
    local targetName = GetPlayerName(target)
    local message

    if isGoto then 
        lib.notify(target, {
            title = locale("notify.adminTeleportedTo"),
            icon = 'wand-magic-sparkles',
            type = 'info'
        })
        message = ('**%s** Teleported to **%s**'):format(adminName, targetName)
    else 
        lib.notify(target, {
            title = locale("notify.adminBrought"),
            icon = 'wand-magic-sparkles',
            type = 'info'
        })
        message = ('**%s** Brought **%s**'):format(adminName, targetName)
    end

    local title = 'Admin Teleported'
    sendWebhook(title, message)
end)

RegisterNetEvent('stevo_reports:deleteReport', function(report, reason)
    if not IsPlayerAceAllowed(source, config.perms.deleteAllReports) then return end

    if report == 'all' then 
        lib.notify(source, {
            title = locale("notify.deletedReports", report),
            type = 'error'
        })

        local adminName = GetPlayerName(source)
        local title = 'All Reports Deleted'
        local message = ('**%s** Deleted **%s** Reports'):format(adminName, #reports)
        sendWebhook(title, message)

        
        reports = {}
    else

        lib.notify(source, {
            title = locale("notify.deletedReport", report),
            description = locale('notify.deletedReportDesc', reason),
            type = 'error'
        })

        local adminName = GetPlayerName(source)
        local title = 'Report Deleted'
        local message = ('**%s** Deleted Report **%s**\n**Reason:** %s'):format(adminName, report, reason)
        sendWebhook(title, message)

        
        reports[report] = nil
    end
end)

RegisterNetEvent('stevo_reports:generateReport', function(data)
    local reportId = #reports +1
    local report = {
        report = data[2],
        reporter = {
            source = source,
            name = GetPlayerName(source),
            charName = stevo_lib.GetName(source)
        },
        reported = data[1] and DoesPlayerExist(data[1]) and {
            source = data[1],
            name = GetPlayerName(data[1]),
            charName = stevo_lib.GetName(data[1])
        } or false,
        beingResolved = false,
        respondingAdmins = {}
    }
    reports[reportId] = report

    local title = 'Report Generated'
    local message = ('## %s generated a report\n \n**Report:** %s\n**Reported:** %s'):format(GetPlayerName(source), data[2],data[1] and GetPlayerName(data[1]) or 'No Reported Player')
    sendWebhook(title, message)

    
    local players = stevo_lib.GetPlayers()

    for i, player in pairs(players) do 
        local notifyWorthy = IsPlayerAceAllowed(player.source, config.perms.reportsCommand)

        if notifyWorthy then 
            lib.notify(player.source, {
                title = locale("notify.newReportTitle"),
                description = locale("notify.newReportDesc", report.reporter.name),
                type = 'error'
            })
        end
    end  
end)


lib.addCommand(locale('commands.reports'), {
    help = locale('commands.reportsHelp'),
    restricted = config.perms.reportsCommand
}, function(source, args, raw)

    local data = #reports > 0 and reports or false

    if not data then 
        lib.notify(source, {
            title = locale("notify.noReportsTitle"),
            description = locale("notify.noReportsDesc"),
            type = 'error'
        })
        return 
    end

    for i=1, #reports do 
        local report = reports[i]
        
        if not DoesPlayerExist(report.reporter.source) then 
            reports[i] = nil
        end
    end

    TriggerClientEvent('stevo_reports:openReportsMenu', source, data)
end)

lib.addCommand(locale('commands.report'), {
    help = locale('commands.reportHelp'),
    restricted = config.perms.reportsCommand
}, function(source, args, raw)

    if not config.multipleReports then

        for i=1, #reports do 
            local report = reports[i]
            
            if report.reporter.source == source then 
                lib.notify(source, {
                    title = locale("notify.maxReportsTitle"),
                    description = locale("notify.maxReportsDesc"),
                    type = 'error'
                })

                return
            end
        end
    end

    TriggerClientEvent('stevo_reports:startReporting', source)
end)