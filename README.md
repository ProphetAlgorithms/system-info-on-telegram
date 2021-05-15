# system-info-on-telegram

Script that collects some information about the system and sends it to a bot of the telegram platform.

**Warning: do not use the same user to start the script and the validator (tendermint) if you enable the validator section!.
The validator section is disabled by default, activate it if you want.**

The first thing to do is contact @BotFather and create your bot, then take its token and use it in the 
following link: [https://api.telegram.org/bot<BOT_TOKEN>/getUpdates](https://api.telegram.org/bot<BOT_TOKEN>/getUpdates) if the link does not return anything
write a message in the chat and try to visit the link again. The page will show you information about the
bot's chats find your chat id and use it, along with the bot token, in the script fields. You can use this 
script in conjunction with crontab so that you have the information constantly:
```bash
crontab -u <user> -e
0,30 * * * *   /path/to/script/system-info-on-telegram.sh
<save the file>
```
You can add your own rule, that in example starts the script every half hour.

I use two different users to run the script and the validator in addition have a (compiled) copy of the 
executables in the home folder of the user who starts the script to not grant shared permissions.
In the script there are sections enclosed by <> that need to be replaced with your data, before starting.
