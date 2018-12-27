Information:
* Author: Selindrile
* Thanks to: Booshack
* LUA coding and support: Montaeg
* Beta Testers: Hrothgar & Terezka
* Information and Borrowed code: Arcon

Version: 1.1
Automatically perform actions upon request.

Abbreviation: //rq, //request

Commands:
* <whitelist|blacklist> <add|remove> <player> - adds or removes a player from blacklist or whitelist.
* <nickname|nick> <add|remove> <word> - adds or removes a word from nickname list.
* mode <whitelist|blacklist> - changes to whitelist or blacklist, if no mode specified then it will print current mode.
* Partylock <on|off> - turns party lock on or off, if no status specified then it will print current status.
* Requestlock <on|off> - turns request lock on or off, if no status specified then it will print current status.
* Tradelock <on|off> - turns trade lock on or off, if no status specified then it will print current status.
* Exactlock <on|off> - turns exact command lock on or off, if no status specified then it will print current status.
* status - will print status of current options, including full whitelist, blacklist, and keyword list.

If you're looking for something to help with multiboxing, the official addon send is more logical as it will have less delay (no latency of going to the XI server and back.) and broader use cases, Request was primarily created to allow other players you designate to give your character commands.

Without the use of shortcuts, Request has little functionality outside of party management, I highly reccomend using it.
With creative use of aliases, you can have Request do almost anything you want and still be relatively safe.

I repeat, GO GET SHORTCUTS.

Usage:

Request only watches the first three letters of chatlogs (except in the case of exact, but this is dangerous), so commands should be formatted in three word sentances, Examples:

* sel mightyguard yourself
* montaeg magicfruit me
* hroth kick bob
* tere drop party
* arcon protectra5 us
* bill dia3 bt

Warning:

Also, be very careful with exact lock, if off it will allow anyone on your whitelist or anyone not on your blacklist in that mode to
input whatever they want as if they were at your console. I suggest only using it to command your own character from another PC, when you're the only person on that character's whitelist.
