--[[
Copyright c 2015, Selindrile
All rights reserved.
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Request nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL Selindrile BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
]]

require('luau')
packets = require('packets')

_addon.name = 'Request'
_addon.author = 'Selindrile'
_addon.commands = {'request','rq'}
_addon.version = 1.1
_addon.language = 'english'

defaults = T{}
defaults.mode = 'whitelist'
defaults.whitelist = S{}
defaults.blacklist = S{}
defaults.nicknames = S{}
defaults.forbidden = S{'Lua','U','Reload','Terminate','Quit','Treasury','Unload', 'Unloadall','S','Say','Exec','Load','L','Linkshell','Sh','Shout','Minimize'}
defaults.PartyLock = true
defaults.ExactLock = true
defaults.TradeLock = true
defaults.RequestLock = false

-- Aliases to access correct modes based on supplied arguments.
aliases = T{
    wl		     = 'whitelist',
    wlist        = 'whitelist',
    white        = 'whitelist',
    whitelist    = 'whitelist',
    b	         = 'blacklist',
	bl	         = 'blacklist',
    blist        = 'blacklist',
    black        = 'blacklist',
    blacklist    = 'blacklist',
    nick         = 'nicknames',
    nickname	 = 'nicknames',
    nicknames    = 'nicknames',
    partylock	 = 'partylock',
    partyl       = 'partylock',
    plock        = 'partylock',
    pl           = 'partylock',
    requestlock  = 'requestlock',
    requestl     = 'requestlock',
    rlock        = 'requestlock',
    rl           = 'requestlock',
    exactlock    = 'exactlock',
    exact        = 'exactlock',
    exactl       = 'exactlock',
    elock        = 'exactlock',
    xlock        = 'exactlock',
	el	         = 'exactlock',
    xl           = 'exactlock',
	tradelock	 = 'tradelock',
	tl			 = 'tradelock',
	tradel		 = 'tradelock',
	trade		 = 'tradelock',
	tlock		 = 'tradelock',
    forbidden    = 'forbidden',
    forbid       = 'forbidden',
}

-- Aliases to access the add and item_to_remove routines.
addstrs = S{'a', 'add', '+'}
rmstrs = S{'r', 'rm', 'remove', 'delete', 'del', '-'}

-- Aliases for partylock and requestlock and exactlock modes.
on = S{'on', 'yes', 'true'}
off = S{'off', 'no', 'false'}

modes = S{'whitelist', 'blacklist'}

-- Load settings from file
settings = config.load(defaults)

-- Check for permission.
windower.register_event('chat message', function(message, player, mode, is_gm)

        if settings.mode == 'blacklist' then
            if settings.blacklist:contains(player) then
                return
            else
                request(message, player)
            end
        elseif settings.mode == 'whitelist' then
            if settings.whitelist:contains(player) then
                request(message, player)
            end
        end

end)

-- Attempts to send a request, Quick Debug Line: windower.send_command('input /echo '..nick..' '..request..' '..target..'')
function request(message, player)

	local nick
	local request
	local target

	nick, request = string.match(message:lower(), '^%s*(%a+)%s+([:/%-%a*%d*]+)')
	target = string.match(message:lower(), '^%s*%a+%s+[:/%-%a*%d*]+%s+(%a+)')
	
	if nick == nil then nick = ' ' end
	if request == nil then request = ' ' end
	if target == nil then target = ' ' end

	local status = res.statuses[windower.ffxi.get_player().status].english
	
	-- Check to see if valid player is issuing a command with your nick, and check it against the list of forbidden commands.
	if settings.nicknames:contains(nick:ucfirst()) and not settings.forbidden:contains(request:ucfirst()) then
		--Party commands to check.
		if not settings.PartyLock and request == "pass" and (target == "lead" or target == "leader") then
			windower.chat.input('/pcmd leader '..player..'')
			
		elseif not settings.PartyLock and request == "pass" and (target == "alli" or target == "ally" or target == "alliance") then
			windower.chat.input('/acmd leader '..player..'')
	
		elseif not settings.PartyLock and (request == "disband" or request == "drop" or request =="leave") and target == "party" then
			windower.chat.input('/pcmd leave')
			
		elseif not settings.PartyLock and (request == "disband" or request == "drop" or request =="leave") and target == "alliance" then
			windower.chat.input('/acmd leave')
			
		elseif not settings.PartyLock and (((request == "accept" or request == "take") and target == "invite") or request == "join") then
			windower.chat.input('/join')
		
		elseif not settings.PartyLock and request == "invite" then
			if target == "me" or target == " " then windower.chat.input('/pcmd add '..player..'')
			else windower.chat.input('/pcmd add '..target..'')
			end
			
		elseif not settings.PartyLock and request == "alliance" then
			if target == "me" or target == " " then windower.chat.input('/pcmd add '..player..'')
			else windower.chat.input('/acmd add '..target..'')
			end
			
		elseif not settings.PartyLock and request == "kick" then
			windower.chat.input('/pcmd kick '..target..'')

		elseif request == "exact" and not settings.ExactLock then
			exactcommand = string.match(message, '%a+ exact (.*)')
			windower.send_command(''..exactcommand..'')
			
		elseif request == "trade" and not settings.TradeLock then
			if target == "me" or target == nil then
				local tradename = player and windower.ffxi.get_mob_by_name(player)
				if status == 'Idle' and tradename and math.sqrt(tradename.distance) <= 6 and not tradename.is_npc and tradename.id ~= windower.ffxi.get_player().id then
					windower.send_command('keyboard_blockinput 1;setkey escape;wait .2;setkey escape up;wait .4;setkey escape;wait .2;setkey escape up;wait .4;setkey escape;wait .2;setkey escape up;wait .4;input /target '..player..';wait .2;setkey enter;wait .2;setkey enter up;wait .4;setkey up;wait .2;setkey up up;wait .2;setkey up;wait .2;setkey up up;setkey enter;wait .2;setkey enter up;wait .2;keyboard_blockinput 0')
				end
			elseif target then
				local tradename = target and windower.ffxi.get_mob_by_name(target)
				if status == 'Idle' and tradename and math.sqrt(tradename.distance) <= 6 and not tradename.is_npc and tradename.id ~= windower.ffxi.get_player().id then
					windower.send_command('keyboard_blockinput 1;setkey escape;wait .2;setkey escape up;wait .4;setkey escape;wait .2;setkey escape up;wait .4;setkey escape;wait .2;setkey escape up;wait .4;input /target '..target..';wait .2;setkey enter;wait .2;setkey enter up;wait .4;setkey up;wait .2;setkey up up;wait .2;setkey up;wait .2;setkey up up;setkey enter;wait .2;setkey enter up;wait .2;keyboard_blockinput 0')
				end
			else
			end

		
		--Anything else, mostly send on to shortcuts and user aliases, could potentially send short addon commands.
		elseif not settings.RequestLock then
			if request == "stop" and (target == "attack" or target == "attacking") then windower.send_command('attackoff')
			elseif ((request == "accept" or request == "take") and target == "raise") then
				windower.send_command('keyboard_blockinput 1;setkey enter down; wait 0.2;setkey enter up;keyboard_blockinput 0')
			elseif request == "strip" or (request == "get" and target == "naked") then
				windower.send_command('gs c naked')
			elseif request == "stand" or (request == "get" and target == "up") then
				if status == 'Dead' or status == 'Engaged dead' then
					windower.send_command('keyboard_blockinput 1;setkey enter down; wait 0.2;setkey enter up;keyboard_blockinput 0')
				elseif status == 'Sitting' then
					windower.chat.input('/sit')
				elseif status == 'Resting' then
					windower.chat.input('/heal')
				end
			elseif request == "stop" or (request == "stay" and target == "here") then windower.send_command('keyboard_blockinput 1;setkey s down; wait 0.3;setkey s up;keyboard_blockinput 0')
			elseif target == "bt" or target == "this" then windower.send_command(''..request..' <bt>')
			elseif target == "it" or target == "t" then windower.send_command(''..request..' <t>')
			elseif target == "us" or target == "yourself" then windower.send_command(''..request..' <me>')
			elseif target == "me" or target == "now" or target == "please" or target == nil then windower.send_command(''..request..' '..player..'')
			elseif request == "gtfo" then
				local inventory = windower.ffxi.get_items("inventory")
				
				windower.add_to_chat(123,''..inventory[1][1]..'')
				
				if inventory['Farewell Fly'] then
					windower.chat.input('/item "Farewell Fly" <me>')
				elseif inventory['Misanthropy'] then
					windower.add_to_chat(123,'Found my Scythe!')
				else
					windower.add_to_chat(123,'No GTFO Items Found')
				end
				
			elseif request == "cancel" then
				windower.send_command('cancel '..target..'')
			else windower.send_command(''..request..' '..target..'')
			end
		end
	end
end


-- Adds names/items to a given list type.
function add_item(mode, ...)
    local names = S{...}
    local doubles = names * settings[mode]
    if not doubles:empty() then
        if aliases[mode] == 'nicknames' then
            notice('User':plural(doubles)..' '..doubles:format()..' already on nickname list.')
        elseif aliases[mode] == 'forbidden' then
			notice('Command':plural(doubles)..' '..doubles:format()..' already on forbidden list.')
		else
            notice('User':plural(doubles)..' '..doubles:format()..' already on '..aliases[mode]..'.')
        end
    end
    local new = names - settings[mode]
    if not new:empty() then
        settings[mode] = settings[mode] + new
        log('Added '..new:format()..' to the '..aliases[mode]..'.')
    end
end

-- Removes names/items from a given list type.
function remove_item(mode, ...)
    local names = S{...}
    local dummy = names - settings[mode]
    if not dummy:empty() then
        if aliases[mode] == 'nicknames' then
            notice('User':plural(dummy)..' '..dummy:format()..' not found on nickname list.')
        elseif aliases[mode] == 'forbidden' then
			notice('Command':plural(dummy)..' '..dummy:format()..' not found on forbidden list.')
		else
            notice('User':plural(dummy)..' '..dummy:format()..' not found on '..aliases[mode]..'.')
        end
    end
    local item_to_remove = names * settings[mode]
    if not item_to_remove:empty() then
        settings[mode] = settings[mode] - item_to_remove
        log('Removed '..item_to_remove:format()..' from the '..aliases[mode]..'.')
    end
end

windower.register_event('incoming chunk', function(id, original, modified, injected, blocked)
    if id == 0x021 then
        local packet = packets.parse('incoming',original)
        trader_name = windower.ffxi.get_mob_by_id(packet['Player']).name
        if settings.whitelist:contains(trader_name) and not settings.TradeLock then
            windower.packets.inject_outgoing(0x33,string.char(0x33,0x06,0,0,0,0,0,0,0,0,0,0))
        end
    elseif id == 0x022 then
        local packet = packets.parse('incoming',original)
            if packet['Type'] == 2 then
            trader_name = windower.ffxi.get_mob_by_id(packet['Player']).name
            if trade_count and settings.whitelist:contains(trader_name) and not settings.TradeLock then
                windower.packets.inject_outgoing(0x33,string.char(0x33,0x06,0,0,0x02,0,0,0, (trade_count%256), math.floor(trade_count/256),0,0))
            end
        else
            trade_count = 0
        end
    elseif id == 0x023 then
        trade_count = original:byte(9)+original:byte(10)*256
    end
end)

windower.register_event('addon command', function(command, ...)
    command = command and command:lower() or 'status'
    local args = L{...}
    -- Changes whitelist/blacklist mode
    if command == 'mode' then
        local mode = args[1] or 'status'
        if aliases:keyset():contains(mode) then
            settings.mode = aliases[mode]
            log('Mode switched to '..settings.mode..'.')
        elseif mode == 'status' then
            log('Currently in '..settings.mode..' mode.')
        else
            error('Invalid mode:', args[1])
            return
        end
    
	-- Turns Party Lock on or off
    elseif command == 'partylock' then
        status = args[1] or 'status'
        status = string.lower(status)
        if on:contains(status) then
            settings.PartyLock = true
            log('Party Lock turned on.')
        elseif off:contains(status) then
            settings.PartyLock = false
            log('Party Lock turned off.')
        elseif status == 'status' then
            log('Party Lock currently '..display(settings.PartyLock)..'.')
        else
            error('Invalid status:', args[1])
            return
        end

	-- Turns Request Lock on or off
    elseif aliases[command] == 'requestlock' then
        status = args[1] or 'status'
        status = string.lower(status)
        if on:contains(status) then
            settings.RequestLock = true
            log('Request Lock turned on.')
        elseif off:contains(status) then
            settings.RequestLock = false
            log('Request Lock turned off.')
        elseif status == 'status' then
            log('Request Lock currently '..display(settings.RequestLock)..'.')
        else
            error('Invalid status:', args[1])
            return
        end	
		
	-- Turns Trade Lock on or off
    elseif aliases[command] == 'tradelock' then
        status = args[1] or 'status'
        status = string.lower(status)
        if on:contains(status) then
            settings.TradeLock = true
            log('Trade Lock turned on.')
        elseif off:contains(status) then
            settings.TradeLock = false
            log('Trade Lock turned off.')
        elseif status == 'status' then
            log('Trade Lock currently '..display(settings.TradeLock)..'.')
        else
            error('Invalid status:', args[1])
            return
        end	
		
	-- Turns Exact Lock on or off
    elseif aliases[command] == 'exactlock' then
        status = args[1] or 'status'
        status = string.lower(status)
        if on:contains(status) then
            settings.ExactLock = true
            log('Exact Lock turned on.')
        elseif off:contains(status) then
            settings.ExactLock = false
            log('Exact Lock turned off.')
        elseif status == 'status' then
            log('Exact Lock currently '..display(settings.ExactLock)..'.')
        else
            error('Invalid status:', args[1])
            return
        end	
		
    elseif aliases:keyset():contains(command) then
		mode = aliases[command]
		names = args:slice(2):map(string.ucfirst..string.lower)
		if args:empty() then
			log(mode:ucfirst()..':', settings[mode]:format('csv'))
		else
			if addstrs:contains(args[1]) then
				add_item(mode, names:unpack())
			elseif rmstrs:contains(args[1]) then
				remove_item(mode, names:unpack())
			else
				notice('Invalid operator specified. Specify add or remove.')
			end
		end
        
    -- Print current settings status
    elseif command == 'status' then
	log('~~~~~~~ Request Settings ~~~~~~~')
    log('Mode:', settings.mode:ucfirst())
    log('Whitelist:', settings.whitelist:empty() and '(empty)' or settings.whitelist:format('csv'))
    log('Blacklist:', settings.blacklist:empty() and '(empty)' or settings.blacklist:format('csv'))
	log('Nicknames:', settings.nicknames:empty() and '(empty)' or settings.nicknames:format('csv'))
	log('Forbidden Commands:', settings.forbidden:empty() and '(empty)' or settings.forbidden:format('csv'))
	log('Party Lock:', display(settings.PartyLock))
	log('Request Lock:', display(settings.RequestLock))
	log('Exact Lock:', display(settings.ExactLock))
	log('Trade Lock:', display(settings.TradeLock))
    
    -- Ignores (and prints a warning) if unknown command is passed.
    else
        warning('Unkown command \''..command..'\', ignored.')

    end

    config.save(settings)
end)

display = function(setting)
    if class(setting) == 'Set' then
        return setting:empty() and '(empty)' or setting:format('csv')
    elseif class(setting) == 'boolean' then
        return setting and 'On' or 'Off'
    end

    return tostring(setting)
end