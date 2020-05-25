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
_addon.version = 2.0
_addon.language = 'english'

player_name = windower.ffxi.get_player().name
defaults = T{}
defaults.mode = 'whitelist'
defaults.whitelist = S{}
defaults.blacklist = S{}
defaults.nicknames = S{}
defaults.forbidden = S{'Lua','U','Reload','Terminate','Quit','Treasury','Unload', 'Unloadall','S','Say','Exec','Load','L','Linkshell','Sh','Shout','Minimize'}
defaults.PartyLock = true
defaults.MotionLock = false
defaults.ExactLock = true
defaults.TradeLock = true
defaults.RequestLock = false
allow_target = true
allow_engage = true

motion_map = {[15]='Cure',[17]='Attack',[23]='Target',[27]='Silence',[28]='Sleep',[30]='Stun',[31]='Haste'}

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

		if is_gm then
			windower.send_command('lua unload request;hb off;lua reload gearswap')
        elseif settings.mode == 'blacklist' then
            if settings.blacklist:contains(player) then
				return
            else
                request(message, player, mode)
            end
        elseif settings.mode == 'whitelist' then
            if settings.whitelist:contains(player) then
                request(message, player, mode)
            end
        end

end)

windower.register_event('emote', function(emote_id, sender_id, target_id, motion)
	if motion and not settings.MotionLock and motion_map[emote_id] then
		local player = windower.ffxi.get_player()
		if sender_id ~= player.id then
			local sender = windower.ffxi.get_mob_by_id(sender_id)
			if settings.mode == 'blacklist' then
				if settings.blacklist:contains(sender.name) then
					return
				else
					if target_id == 0 then target_id = sender_id end
					request_motion(emote_id,target_id,player.id,player.index)
				end
			elseif settings.mode == 'whitelist' then
				if settings.whitelist:contains(sender.name) then
					if target_id == 0 then target_id = sender_id end
					request_motion(emote_id,target_id,player.id,player.index)
				end
			end
		end
	end
end)

-- Motion triggers
function request_motion(emote_id,target_id,player_id,player_index)
	if emote_id == 23 and allow_target then
		packets.inject(packets.new('incoming', 0x058, {
			['Player'] = player_id,
			['Target'] = target_id,
			['Player Index'] = player_index,
		}))
	elseif emote_id == 17 and allow_engage then
		local target = windower.ffxi.get_mob_by_id(target_id)
		if target and target.valid_target and target.spawn_type == 16 and sqrt(target.distance) <= 30 then
			packets.inject(packets.new('outgoing', 0x1a, {
				['Target'] = target.id,
				['Target Index'] = target.index,
				['Category']     = 0x02,
			}))
		end
	else
		windower.send_command(''..motion_map[emote_id]..' '..target_id..'')
	end
end

-- Attempts to send a request, Quick Debug Line: windower.send_command('input /echo '..nick..' '..request..' '..target..'')
function request(message, sender, mode)
	message = message:lower()
	message = T(message:split(' '))
	
	if mode == 3 and not settings.nicknames:contains(message[1]:ucfirst()) then
		table.insert(message,0,player_name)
	end
	
	local nick = tostring(table.remove(message, 1):ucfirst())
	if #message == 0 then return end
	local target = (table.remove(message, #message)):lower()
	local request = message
	if target == nil then return end
	if request[1] == nil then
		request[1] = target
		target = ''		
	end

	-- Check to see if valid sender is issuing a command with your nick, and check it against the list of forbidden commands.	
	if (nick == player_name or settings.nicknames:contains(nick)) and not settings.forbidden:contains(request[1]:ucfirst()) then

		if request == "exact" and not settings.ExactLock then
			exactcommand = string.match(message, '%a+ exact (.*)')
			windower.send_command(''..exactcommand..'')
			return
		end

		if target == nil then
			target = ''
		elseif target == 'me' then
			target = sender
		end
		
		--[[Test Code Block
		if sender then windower.add_to_chat(7,'sender: '..sender..'') end
		if nick then windower.add_to_chat(7,'nick: '..nick..'') end
		if target then windower.add_to_chat(7,'target: '..target..'') end	
		if request[1] then windower.add_to_chat(7,'request[1]: '..request[1]..'') end
		if request[2] then windower.add_to_chat(7,'request[2]: '..request[1]..'') end
		]]
		
		--Party commands to check.
		if not settings.PartyLock then
			if request[1] == "pass" then
				if request[2] == nil then
					if target == 'lead' or target == "leader" then
						windower.chat.input('/pcmd leader '..sender..'')
					elseif target == "alli" or target == "ally" or target == "alliance" then
						windower.chat.input('/acmd leader '..sender..'')
					end
				elseif request[2] == 'lead' or request[2] == 'leader' then
					windower.chat.input('/pcmd leader '..target..'')
				elseif request[2] == "alli" or request[2] == "ally" or request[2] == "alliance" then
					windower.chat.input('/acmd leader '..target..'')
				else
					if request[2] == 'me' then request[2] = sender end
					if target == 'lead' or target == "leader" then
						windower.chat.input('/pcmd leader '..request[2]..'')
					elseif target == "alli" or target == "ally" or target == "alliance" then
						windower.chat.input('/acmd leader '..request[2]..'')
					end
				end
			elseif request[1] == "disband" or request[1] == "drop" or request[1] =="leave" then
				if request[2] == nil then
					if target == "party" then
						windower.chat.input('/pcmd leave')
					elseif target == "alliance" then
						windower.chat.input('/acmd leave')
					end
				elseif request[2] == "party" then
					windower.chat.input('/pcmd leave')
				elseif request[2] == "alliance" then
					windower.chat.input('/acmd leave')
				end
			elseif request[1] == "accept" or request[1] == "take" then
				if target == 'invite' or target == 'party' or target == 'alliance' then
					windower.chat.input('/join')
				elseif request[2] and (request[2] == 'invite' or request[2] == 'party' or request[2] == 'alliance') then
					windower.chat.input('/join')
				end
			elseif request[1] == "join" then
				if target == 'party' or target == 'alliance' or (request[2] and (request[2] == 'party' or request[2] == 'alliance')) then
					windower.chat.input('/join')
				end
			elseif request[1] == "invite" or request[1] == "alliance" then
				if request[2] == nil then
					if target == '' then
						windower.chat.input('/pcmd add '..sender..'')
					else
						windower.chat.input('/pcmd add '..target..'')
					end
				elseif request[2] == 'me' then
					windower.chat.input('/pcmd add '..sender..'')
				else
					windower.chat.input('/pcmd add '..request[2]..'')
				end
			elseif request[1] == "kick" then
				if request[2] == nil then
					windower.chat.input('/pcmd kick '..target..'')
				elseif request[2] == 'me' then
					windower.chat.input('/pcmd kick '..sender..'')
				else
					windower.chat.input('/pcmd kick '..request[2]..'')
				end
			end
		end
		
		--Anything else, mostly send on to shortcuts and user aliases, could potentially send short addon commands.
		if not settings.RequestLock then
			local status = res.statuses[windower.ffxi.get_player().status].english
			
			if request[1] == 'tele' or request[1] == 'teleport' or request[1] == 'telly' then
				if request[2] then
					windower.send_command('teleport-'..request[2]..'')
				else
					windower.send_command('teleport-'..target..'')
				end
			elseif request[1] == 'recall' then
				if request[2] then
					windower.send_command('recall-'..request[2]..'')
				else
					windower.send_command('recall-'..target..'')
				end
			elseif request[1] == "disengage" or request[1] == "unengage" then
				windower.send_command('attackoff')
			elseif request[1] == "stop" then
				if not request[2] then
					if target == "attack" or target == "attacking" then 
						windower.send_command('attackoff')
					elseif target == "moving" or target == '' then
						windower.send_command('attackoff')
						windower.ffxi.run(false)
						windower.ffxi.follow()
					end
				elseif request[2] == "attack" or request[2] == "attacking" then 
					windower.send_command('attackoff')
				elseif request[2] == "moving" or request[2] == '' then
					windower.send_command('attackoff')
					windower.ffxi.run(false)
					windower.ffxi.follow()
				end
			elseif request[1] == "stay" then
				if not request[2] then
					if target == "here" or '' then
						windower.ffxi.run(false)
						windower.ffxi.follow()
					end
				elseif request[2] == "here" then
					windower.ffxi.run(false)
					windower.ffxi.follow()
				end	
			elseif request[1] == "accept" or request[1] == "take" then
				if target == 'raise' or target == 'arise' or (request[2] and (request[2] == 'raise' or request[2] == 'arise')) then
					if status == 'Dead' or status == 'Engaged dead' then
						windower.send_command('keyboard_blockinput 1;setkey enter down; wait 0.2;setkey enter up;keyboard_blockinput 0')
					end
				end
			elseif request[1] == "strip" then
				windower.send_command('gs c naked')
			elseif request[1] == "get" and (target == "naked" or (request[2] and request[2] == "naked")) then
				windower.send_command('gs c naked')
			elseif request[1] == "stand" or (request[1] == "get" and (target == "up" or (request[2] and request[2] == "up"))) then
				if status == 'Dead' or status == 'Engaged dead' then
					windower.send_command('keyboard_blockinput 1;setkey enter down; wait 0.2;setkey enter up;keyboard_blockinput 0')
				elseif status == 'Sitting' then
					windower.chat.input('/sit')
				elseif status == 'Resting' then
					windower.chat.input('/heal')
				end
			else
				
				if request[2] then
					request = table.concat(request,'',1,2)
				else
					request = table.concat(request,'')
				end
				
				if target == sender or target == 'it' then
					windower.send_command(''..request..' '..target..'')
				elseif target == "bt" or target == "this" then
					windower.send_command(''..request..' <bt>')
				elseif target == "us" or target == "yourself" then
					windower.send_command(''..request..' <me>')				
				elseif target == "now" or target == "please" or target == '' then
					windower.send_command(''..request..' '..sender..'')
				elseif request == "gtfo" then
					windower.chat.input('/item "Farewell Fly" <me>')
				elseif request == "cancel" then
					windower.send_command('cancel '..target..'')
				elseif target ~= '' then
					target = get_closest_mob_id_by_name(target)
					windower.send_command(''..request..' '..target..'')
				else
					windower.send_command(''..request..'')
				end
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
	if not settings.TradeLock then
		if id == 0x021 then
			local packet = packets.parse('incoming',original)
			trader_name = windower.ffxi.get_mob_by_id(packet['Player']).name
			if settings.whitelist:contains(trader_name) then
				windower.packets.inject_outgoing(0x33,string.char(0x33,0x06,0,0,0,0,0,0,0,0,0,0))
			end
		elseif id == 0x022 then
			local packet = packets.parse('incoming',original)
				if packet['Type'] == 2 then
				trader_name = windower.ffxi.get_mob_by_id(packet['Player']).name
				if trade_count and settings.whitelist:contains(trader_name) then
					windower.packets.inject_outgoing(0x33,string.char(0x33,0x06,0,0,0x02,0,0,0, (trade_count%256), math.floor(trade_count/256),0,0))
				end
			else
				trade_count = 0
			end
		elseif id == 0x023 then
			trade_count = original:byte(9)+original:byte(10)*256
		end
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
            log('Party Lock currently: '..display(settings.PartyLock)..'')
        else
            error('Invalid status:', args[1])
            return
        end
		
	elseif command == 'target' then
		if allow_target then
			allow_target = false
			log('Targetting turned off.')
		else
			allow_target = true
			log('Targetting turned on.')
		end
	
	elseif command == 'engage' then
		if allow_engage then
			allow_engage = false
			log('Engaging turned off.')
		else
			allow_engage = true
			log('Engaging turned on.')
		end
		
	-- Turns Motion Lock on or off
    elseif command == 'motionlock' then
        status = args[1] or 'status'
        status = string.lower(status)
        if on:contains(status) then
            settings.MotionLock = true
            log('Motion Lock turned on.')
        elseif off:contains(status) then
            settings.MotionLock = false
            log('Motion Lock turned off.')
        elseif status == 'status' then
            log('Motion Lock currently: '..display(settings.MotionLock)..'')
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
            log('Request Lock currently: '..display(settings.RequestLock)..'')
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
            log('Trade Lock currently: '..display(settings.TradeLock)..'')
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
            log('Exact Lock currently: '..display(settings.ExactLock)..'')
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

function get_closest_mob_id_by_name(name)
	local name = get_fuzzy_name(name)
	local mobs = windower.ffxi.get_mob_array()
	local fuzzy_list = T{}
	local best_match = T{}

	for i, mob in pairs(mobs) do
		if mob.valid_target then
			local fuzzy_mob_name = get_fuzzy_name(mob.name)
			if (name:length() >= 3 and fuzzy_mob_name:contains(name)) or fuzzy_mob_name == name then
				fuzzy_list[mob.id] = mob
				fuzzy_list[mob.id].score = fuzzy_mob_name:length() - name:length()
			end
		end
	end
	
	for i, mob in pairs(fuzzy_list) do
		if (not best_match.score or mob.score < best_match.score) or (mob.score == best_match.score and (mob.distance < best_match.distance)) then
			best_match = mob
		end
	end

	return best_match.id or name
end

function get_fuzzy_name(name)
	return name:lower():gsub("%s", ""):gsub("%p", "")
end