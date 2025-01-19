if not lib.checkDependency('stevo_lib', '1.7.3') then error('stevo_lib 1.7.3 required for stevo_reports') end
lib.locale()
local config = require('config')
local stevo_lib = exports['stevo_lib']:import()

local function gotoUser(data)
    local user = data.user
    local coords = lib.callback.await('stevo_reports:requestCoords', false, user.source)

    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z)

    lib.notify({
        title = locale("notify.teleportedTo", user.name),
        icon = 'wand-magic-sparkles',
        type = 'info'
    })

    TriggerServerEvent('stevo_reports:teleportAction', user.source, true)
end 

local function bringUser(data)
    local user = data.user
    local coords = lib.callback.await('stevo_reports:requestCoords', false, user.source)

    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z)

    lib.notify({
        title = locale("notify.brought", user.name),
        icon = 'wand-magic-sparkles',
        type = 'info'
    })

    TriggerServerEvent('stevo_reports:teleportAction', user.source, false)
end

RegisterNetEvent('stevo_reports:startReporting', function()
    if GetInvokingResource() then return end

    local inputs = {
        {type = 'number', label = locale('input.playerIdTitle'), icon = 'user', description = locale('input.playerIdDesc'), required = false, min = 1},
        {type = 'textarea', label = locale('input.reasonTitle'), description = locale('input.reasonDesc'), required = true, min = 4},
        {type = 'checkbox', label = locale('input.checkbox'), required = true}
    } 

    local input = lib.inputDialog(locale("input.title"), inputs)

    TriggerServerEvent('stevo_reports:generateReport', input)
end)


RegisterNetEvent('stevo_reports:openReportsMenu', function(reports)
    if GetInvokingResource() then return end


    local formattedReports = {}

    for i=1, #reports do 
        local report = reports[i]
        local option = {

            title = locale('menu.reportOptionTitle', i),
            description =  not report.beingResolved and locale('menu.reportOptionDesc', report.reporter.name, report.reporter.charName) or locale('menu.reportOptionDescResolving', #report.respondingAdmins),
            icon = not report.beingResolved and 'triangle-exclamation' or 'circle-check',
            onSelect = function()
                lib.showContext('stevo_reports_report_'..i)
            end  
        }


        lib.registerContext({
            id = 'stevo_reports_reporter',
            menu = 'stevo_reports_report_'..i,
            title = locale('menu.reporterActions'),
            options = {
                {
                    title = locale("menu.gotoPlayer"),
                    icon = 'arrow-up',
                    arrow = true,
                    args = {user = report.reporter},
                    onSelect = gotoUser
                },
                {
                    title = locale("menu.bringPlayer"),
                    icon = 'arrow-down',
                    arrow = true,
                    args = {user = report.reporter},
                    onSelect = bringUser
                },
            }
        })

        if report.reported then 
            lib.registerContext({
                id = 'stevo_reports_reported',
                menu = 'stevo_reports_report_'..i,
                title = locale('menu.reportedActions'),
                options = {
                    {
                        title = report.reported and locale("menu.gotoPlayer") or locale("menu.noPlayer"),
                        icon = 'arrow-up',
                        arrow = true,
                        disabled = not report.reported,
                        args = {user = report.reported},
                        onSelect = gotoUser
                    },
                    {
                        title = report.reported and locale("menu.bringPlayer") or locale("menu.noPlayer"),
                        icon = 'arrow-down',
                        arrow = true,
                        disabled = not report.reported,
                        args = {user = report.reported},
                        onSelect = bringUser
                    },
                }
            })
        end

    
        lib.registerContext({
            id = 'stevo_reports_report_'..i,
            menu = 'stevo_reports_menu',
            title = locale('menu.reportOptionTitle', i),
            options = {
                
                {
                    title = locale("menu.report"),
                    description = report.report,
                    icon = 'message'
                },
                {
                    title = locale("menu.reportingPlayer"),
                    description = ('%s [%s]'):format(report.reporter.charName, report.reporter.name),
                    icon = 'user',
                    iconColor = '#CAF1DE',
                    arrow = true,
                    onSelect = function()
                        lib.showContext('stevo_reports_reporter')
                    end
                },
                {
                    title = report.reported and locale("menu.reportedPlayer") or locale("menu.noReported"),
                    icon = 'user-slash',
                    iconColor = '#F7D8BA',
                    description = report.reported and ('%s [%s]'):format(report.reported.charName, report.reported.name) or false,
                    disabled = not report.reported,
                    arrow = report.reported,
                    onSelect = function()
                        lib.showContext('stevo_reports_reported')
                    end
                },
                {
                    title = locale("menu.deleteReport"),
                    icon = 'trash',
                    iconColor = '#ff0000',
                    onSelect = function()
                        local alert = lib.alertDialog({
                            header = locale('alert.deleteTitle'),
                            content = locale('alert.deleteContent'),
                            centered = true,
                            cancel = true
                        })
                    

                        if alert == 'confirm' then 
                            local input = lib.inputDialog(locale('input.deleteTitle'), {
                                {type = 'input', label = locale('input.deleteReasonTitle'), description = locale('input.deleteReasonDesc'), required = true, min = 1},
                            }, {allowCancel = false})
                            TriggerServerEvent('stevo_reports:deleteReport', i, input[1])
                        else                  
                            lib.showContext('stevo_reports_report_'..i)
                        end
                    end
                },
            }
        })
    

        table.insert(formattedReports, option)
        
    end

    local deleteAllReports = {

        title = locale('menu.deleteAllReports'),
        icon = 'trash',
        iconColor = '#ff0000',
        onSelect = function()
            local alert = lib.alertDialog({
                header = locale('alert.deleteAllTitle'),
                content = locale('alert.deleteAllContent'),
                centered = true,
                cancel = true
            })
        

            if alert == 'confirm' then 
                TriggerServerEvent('stevo_reports:deleteReport', 'all')
            end
        end  
    }


    table.insert(formattedReports, deleteAllReports)

    lib.registerContext({
        id = 'stevo_reports_menu',
        title = locale('menu.title', #reports),
        options = formattedReports
    })

    lib.showContext('stevo_reports_menu')
end)
