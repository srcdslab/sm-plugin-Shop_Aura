#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <shop>
#include <clientprefs>
#include <multicolors>

int g_iClientColor[MAXPLAYERS+1][4];
bool g_bHasAura[MAXPLAYERS+1];

KeyValues g_hKeyValues;
Handle g_hTimer[MAXPLAYERS+1];
int g_BeamSprite;
int g_HaloSprite;

ConVar g_convar_enabled;
ConVar g_convar_rainbow;
ConVar g_convar_aura_style;

Cookie g_hCookie;
bool g_bShouldSee[MAXPLAYERS + 1];
bool g_bRainbow[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "[Shop] Aura",
	description = "Grant player to buy aura",
	author = "R1KO",
	version = "1.3.3",
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	g_convar_enabled = CreateConVar("sm_shop_aura_enabled", "1", "plugin is enabled (1) or disabled (0)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_convar_rainbow = CreateConVar("sm_shop_aura_rainbow", "1", "enable rainbow aura (1) or disabled (0)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_convar_aura_style = CreateConVar("sm_shop_aura_style", "0", "aura style [Wide expanding (0) - Thin aura with wave effect (1)]", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCookie = new Cookie("shop_aura", "1 - enabled, 0 - disabled", CookieAccess_Private);

	if (Shop_IsStarted())
		Shop_Started();
}

public void OnMapStart() 
{
	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/glow08.vmt");

	char buffer[PLATFORM_MAX_PATH];
	if (g_hKeyValues != null) delete g_hKeyValues;
	
	g_hKeyValues = new KeyValues("Aura_Colors");
	
	Shop_GetCfgFile(buffer, sizeof(buffer), "aura_colors.txt");
	
	if (!g_hKeyValues.ImportFromFile(buffer)) SetFailState("Couldn't parse file %s", buffer);
}

public void OnPluginEnd()
{
	Shop_UnregisterMe();
}

public void Shop_Started()
{
	if (g_hKeyValues == null) OnMapStart();

	g_hKeyValues.Rewind();
	char sName[64], sDescription[64];
	
	g_hKeyValues.GetString("name", sName, sizeof(sName), "Aura");
	g_hKeyValues.GetString("description", sDescription, sizeof(sDescription));

	CategoryId category_id = Shop_RegisterCategory("aura", sName, sDescription);

	g_hKeyValues.Rewind();

	if (g_hKeyValues.GotoFirstSubKey())
	{
		do
		{
			if (g_hKeyValues.GetSectionName(sName, sizeof(sName)) && Shop_StartItem(category_id, sName))
			{
				g_hKeyValues.GetString("name", sDescription, sizeof(sDescription), sName);
				Shop_SetInfo(sDescription, "", g_hKeyValues.GetNum("price", -1), g_hKeyValues.GetNum("sellprice", -1), Item_Togglable, g_hKeyValues.GetNum("duration", 604800));
				Shop_SetCallbacks(_, OnEquipItem);
				Shop_EndItem();
			}
		} while (g_hKeyValues.GotoNextKey());
	}
	
	g_hKeyValues.Rewind();
	
	Shop_AddToFunctionsMenu(FuncToggleVisibilityDisplay, FuncToggleVisibility);
}

public void FuncToggleVisibilityDisplay(int client, char[] buffer, int maxlength)
{
	Format(buffer, maxlength, "Aura: %s", g_bShouldSee[client] ? "Visible" : "Hidden");
}

public bool FuncToggleVisibility(int client)
{
	g_bShouldSee[client] = !g_bShouldSee[client];
	CPrintToChat(client, "{green}[Shop] {default}Shop aura is %s{default}.", g_bShouldSee[client] ? "{blue}visible":"{red}hidden");
	return false;
}

public ShopAction OnEquipItem(int iClient, CategoryId category_id, const char[] category, ItemId item_id, const char[] sItem, bool isOn, bool elapsed)
{
	if (isOn || elapsed)
	{
		OnClientDisconnect(iClient);
		return Shop_UseOff;
	}
	
	Shop_ToggleClientCategoryOff(iClient, category_id);

	if (g_hKeyValues.JumpToKey(sItem, false))
	{
		g_bRainbow[iClient] = StrEqual(sItem, "rainbow", false);
		
		if (!g_bRainbow[iClient])
		{
			g_hKeyValues.GetColor("color", g_iClientColor[iClient][0], g_iClientColor[iClient][1], g_iClientColor[iClient][2], g_iClientColor[iClient][3]);
		}

		g_hKeyValues.Rewind();
		SetClientAura(iClient);
		g_bHasAura[iClient] = true;
		return Shop_UseOn;
	}
	
	PrintToChat(iClient, "Failed to use \"%s\"!.", sItem);
	return Shop_Raw;
}

public void OnClientCookiesCached(int iClient)
{
	char sBuffer[4];
	g_hCookie.Get(iClient, sBuffer, 4);
	g_bShouldSee[iClient] = view_as<bool>(StringToInt(sBuffer));
}

public void OnClientDisconnect(int iClient) 
{
	g_bHasAura[iClient] = false;
	g_bRainbow[iClient] = false;
	if (g_hTimer[iClient] != null)
	{
		delete g_hTimer[iClient];
	}
	
	SetCookieBool(iClient, g_hCookie, g_bShouldSee[iClient]);
	g_bShouldSee[iClient] = true;
}

stock void SetCookieBool(int iClient, Cookie hCookie, bool bValue)
{
	char sBuffer[4];
	if ( bValue ) {
		strcopy(sBuffer, 4, "1");
	}
	else {
		strcopy(sBuffer, 4, "0");
	}
	hCookie.Set(iClient, sBuffer);
}

public void OnClientPostAdminCheck(int iClient)
{
	g_bHasAura[iClient] = false;
}

public void Event_OnPlayerSpawn(Event hEvent, const char[] sName, bool bSilent)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if (iClient > 0 && g_bHasAura[iClient] && IsPlayerAlive(iClient))
		SetClientAura(iClient);
}

stock void SetClientAura(int iClient)
{
	if ( g_convar_enabled.BoolValue ) {
		if (g_hTimer[iClient] == null) g_hTimer[iClient] = CreateTimer(0.1, Timer_Beacon, iClient, TIMER_REPEAT);
	}
}

public Action Timer_Beacon(Handle hTimer, any iClient)
{
	if (IsClientInGame(iClient) && IsPlayerAlive(iClient) && g_bHasAura[iClient])
	{
		static float fVec[3];
		int iClients;
		int i;
		int[] iClientsArray = new int[MaxClients];
		GetClientAbsOrigin(iClient, fVec);

		int aura_style = g_convar_aura_style.IntValue;

		fVec[2] += (aura_style == 0) ? 10.0 : 7.5;

		if (g_convar_rainbow.BoolValue && g_bRainbow[iClient])
		{
			g_iClientColor[iClient][0] = GetRandomInt(1, 255);
			g_iClientColor[iClient][1] = GetRandomInt(1, 255);
			g_iClientColor[iClient][2] = GetRandomInt(1, 255);
			g_iClientColor[iClient][3] = 255;
		}

		if (aura_style == 0)
			TE_SetupBeamRingPoint(fVec, 50.0, 60.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.1, 10.0, 0.0, g_iClientColor[iClient], 10, 0);
		else
			TE_SetupBeamRingPoint(fVec, 50.0, 51.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.1, 10.0, 1.0, g_iClientColor[iClient], 10, 0);
		
		i = 1;
		iClients = 0;

		while(i <= MaxClients)
		{ 
			if (IsClientInGame(i) && IsFakeClient(i) == false && g_bShouldSee[i])
			{
				iClientsArray[iClients++] = i;
			}
			++i;
		}
		TE_Send(iClientsArray, iClients);
		return Plugin_Continue;
	}
	else
	{
		delete g_hTimer[iClient];
	}
	return Plugin_Stop;
}
