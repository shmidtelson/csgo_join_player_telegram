#include <sourcemod>
#include <system2>

#define PLUGIN_AUTHOR "Romua1d"
#define PLUGIN_VERSION "1.02"

#pragma newdecls required
#pragma semicolon 1

Handle Hostname;
Handle g_hEnabled;
Handle g_telegram_token;
Handle g_telegram_chat_id ;
 
public Plugin myinfo = 
{
    name = "Notify about player connect",
    author = PLUGIN_AUTHOR,
    description = "Notify into telegram if player connect",
    version = PLUGIN_VERSION,
    url = "github.com/romua1d"
};

public void OnPluginStart()
{
    g_hEnabled = CreateConVar("sm_telegram_notify_enabled", "0", "Включение/Выключение плагина.");
    g_telegram_token = CreateConVar("sm_telegram_notify_telegram_token", "", "Токен бота телеграма.");
    g_telegram_chat_id = CreateConVar("sm_telegram_notify_chat_id", "", "Ид чата, куда отправлять.");
    AutoExecConfig();
    // Меняем cvar через консоль
    RegAdminCmd("sm_telegram_notify_toggle", Command_ChangePluginState, ADMFLAG_ROOT);

    Hostname = FindConVar("hostname");
}

// Реверсируем квар
public Action Command_ChangePluginState(int client, int args)
{
    int oldcvar = GetConVarInt(g_hEnabled);
    SetConVarInt(g_hEnabled, !oldcvar);
    char sMessage[128];
    Format(sMessage, sizeof(sMessage), "sm_telegram_notify_enabled = %d", !oldcvar);
    ReplyToCommand(client, sMessage);
}

// Заглушаем ответ
public void HttpResponseCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {

}

public void Telegram_Send_Message(const char[] sMessage)
{
    char sURL[256];
    char sToken[128];
    char sChatID[128];
    char error_sending[128] = "%s is empty, sending not working";
    GetConVarString(g_telegram_token, sToken, sizeof(sToken));
    GetConVarString(g_telegram_chat_id, sChatID, sizeof(sChatID));

    if(StrEqual(sToken, "")) LogError(error_sending, "sm_telegram_notify_telegram_token");
    if(StrEqual(sChatID, "")) LogError(error_sending, "sm_telegram_notify_chat_id");

    Format(sURL, sizeof(sURL), "https://api.telegram.org/bot%s/sendMessage?chat_id=%s&text=%s", sToken, sChatID, sMessage);
    System2HTTPRequest httpRequest = new System2HTTPRequest(HttpResponseCallback, sURL);
    httpRequest.GET();

    delete httpRequest;
}

public void OnClientPutInServer(int client)
{
    int cvar = GetConVarInt(g_hEnabled);
    if(cvar){
        char name[32];
        char authid[64];
        char host_name[128];

        Hostname = FindConVar("hostname");
        GetConVarString(Hostname, host_name, sizeof(host_name));

        GetClientName(client, name, sizeof(name));
        GetClientAuthId(client, AuthId_Steam2, authid, sizeof(authid));

        if(!StrEqual(authid, "BOT")){
            char sMessage[128];
            Format(sMessage, sizeof(sMessage), "На сервер (%s) зашел: %s [%s]", host_name, name, authid);
            Telegram_Send_Message(sMessage);
        }
    }
}
