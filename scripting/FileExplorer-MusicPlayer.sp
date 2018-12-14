#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <FileExplorer>
#include <soundlib>

#define DEBUG

#define PLUGIN_AUTHOR "Battlefield Duck"
#define PLUGIN_VERSION "1.0"

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Sourcemod File Explorer - Music Player",
	author = PLUGIN_AUTHOR,
	description = "Access sound files in Game",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/battlefieldduck/"
};

char g_strDirectoryPath[MAXPLAYERS + 1][PLATFORM_MAX_PATH];

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "FileExplorer"))
	{
		FE_WhitelistFileExtension(".mp3\0");
		FE_WhitelistFileExtension(".wav\0");
	}
}

public void FE_OnFileSelected(int client, char[] strFilePath)
{
	Format(g_strDirectoryPath[client], PLATFORM_MAX_PATH, "%s", strFilePath);
	Command_MusicPlayer(client, -1);
}

public Action Command_MusicPlayer(int client, int args)
{
	char menuinfo[PLATFORM_MAX_PATH];
	Menu menu = new Menu(Handler_MusicPlayer);

	char strSoundPath[PLATFORM_MAX_PATH];
	Format(strSoundPath, PLATFORM_MAX_PATH, "%s", g_strDirectoryPath[client]);
	ReplaceString(strSoundPath, PLATFORM_MAX_PATH, "//sound/", "");
	
	Handle soundfile = OpenSoundFile(strSoundPath);
	if (soundfile == INVALID_HANDLE)
	{
		Format(menuinfo, sizeof(menuinfo), "File Explorer - Music Player\n \n%s\n \n", g_strDirectoryPath[client]);
	}
	else
	{	
		Format(menuinfo, sizeof(menuinfo), "File Explorer - Music Player\n \n%s\n \nSound Length: %d\nBitrate: %dkbps\nSampling Rate: %dHz\n \n", 
		g_strDirectoryPath[client], GetSoundLength(soundfile), GetSoundBitRate(soundfile), GetSoundSamplingRate(soundfile));
	}
	menu.SetTitle(menuinfo);

	menu.AddItem("", "Play the music to all");
	menu.AddItem("", "Stop the music to all");
	
	menu.ExitBackButton = true;
	menu.ExitButton = false;
	
	menu.Display(client, -1);
}

public int Handler_MusicPlayer(Menu menu, MenuAction action, int client, int selection)
{
	if (action == MenuAction_Select)
	{
		//char strPath[PLATFORM_MAX_PATH];
		//menu.GetItem(selection, strPath, sizeof(strPath));
	
		char strSoundPath[PLATFORM_MAX_PATH]; 
		strSoundPath = g_strDirectoryPath[client];
		ReplaceString(strSoundPath, PLATFORM_MAX_PATH, "//sound/", "");
		PrecacheSound(strSoundPath, true);
		
		switch (selection)
		{	
			case (0): 
			{
				PrintCenterTextAll("Playing %s", strSoundPath);
				EmitSoundToAll(strSoundPath);
			}
			case (1): 
			{
				for (int i = 1; i <= MaxClients; i++)
				{ 
					if (IsClientInGame(i))
					{
						StopSound(i, SNDCHAN_AUTO, strSoundPath);
					}
				}
			}
		}
		
		Command_MusicPlayer(client, -1);
	}
	else if (action == MenuAction_Cancel)
	{
		if (selection == MenuCancel_ExitBack)
		{		
			FE_OpenMenu(client, GetDirectoryName(g_strDirectoryPath[client]));
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}
