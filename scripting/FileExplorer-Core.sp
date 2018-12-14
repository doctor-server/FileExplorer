#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <FileExplorer>

#define DEBUG

#define PLUGIN_AUTHOR "Battlefield Duck"
#define PLUGIN_VERSION "1.0"

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Sourcemod File Explorer",
	author = PLUGIN_AUTHOR,
	description = "Access file system in Game",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/battlefieldduck/"
};

#define MAX_FOLDER PLATFORM_MAX_PATH
#define MAX_FILE PLATFORM_MAX_PATH
#define MAX_FILENAME 50

#define MAX_SUPPORT_FILEEXTENSION 300
#define MAX_FILEEXTENSION 10

char g_strDirectoryPath[MAXPLAYERS + 1][PLATFORM_MAX_PATH];
char g_strWhilelistFile[MAX_SUPPORT_FILEEXTENSION][MAX_FILEEXTENSION];

Handle sFW_OnFileSelected;

public void OnPluginStart()	
{
	CreateConVar("sm_fileexplorer_version", PLUGIN_VERSION, "Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	RegAdminCmd("sm_file", Command_FileExplorer, ADMFLAG_ROOT, "sm_file");
	RegAdminCmd("sm_fileexplorer", Command_FileExplorer, ADMFLAG_ROOT, "sm_file");
	RegAdminCmd("sm_filereset", Command_FilePathReset, ADMFLAG_ROOT, "sm_file");
	
	for (int i = 1; i <= MaxClients; i++)
	{ 
		if (IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("FE_OpenMenu", Native_OpenMenu);
	CreateNative("FE_GetDirectoryPath", Native_GetDirectoryPath);
	CreateNative("FE_WhitelistFileExtension", Native_WhitelistFileExtension);
	
	sFW_OnFileSelected = CreateGlobalForward("FE_OnFileSelected", ET_Event, Param_Cell, Param_String);
	
	RegPluginLibrary("FileExplorer");
	
	return APLRes_Success;
}

public void OnClientPutInServer(int client)
{
	Format(g_strDirectoryPath[client], PLATFORM_MAX_PATH, "/");
}

public Action Command_FilePathReset(int client, int args)
{
	Format(g_strDirectoryPath[client], PLATFORM_MAX_PATH, "/");
}

public Action Command_FileExplorer(int client, int args)
{
	char menuinfo[PLATFORM_MAX_PATH];
	Menu menu = new Menu(Handler_FileExplorer);

	//Make sure the path is exists
	if (StrEqual(g_strDirectoryPath[client], "/") || !DirExists(g_strDirectoryPath[client]))
	{
		Format(g_strDirectoryPath[client], PLATFORM_MAX_PATH, "/");
	}
	
	Format(menuinfo, sizeof(menuinfo), "File Explorer\n \n%s", g_strDirectoryPath[client]);
	menu.SetTitle(menuinfo);
	
	//Set up BACK path
	char strTemp[PLATFORM_MAX_PATH];
	int pos = FindCharInString(g_strDirectoryPath[client], '/', true);
	for (int i = 0; i < pos; i++)
	{
		strTemp[i] = g_strDirectoryPath[client][i];
	}

	//Display Back Button
	DirectoryListing hDL;
	if (StrEqual(g_strDirectoryPath[client], "/"))
	{
		menu.AddItem(strTemp, "/..", ITEMDRAW_DISABLED);
		hDL = OpenDirectory(".");
	}
	else
	{
		menu.AddItem(strTemp, "/..");
		hDL = OpenDirectory(g_strDirectoryPath[client]);
	}
	
	//Get folders and files name
	char strFoldernames[MAX_FOLDER][MAX_FILENAME], strFilenames[MAX_FILE][MAX_FILENAME];
	int FolderCount = 0, FileCount = 0;
	FileType Filetype;
	while (hDL.GetNext(strTemp, PLATFORM_MAX_PATH, Filetype))
	{
		Format(menuinfo, sizeof(menuinfo), "%s/%s", g_strDirectoryPath[client], strTemp);
		if (Filetype == FileType_Directory)
		{
			Format(strFoldernames[FolderCount], MAX_FOLDER, "/%s", strTemp);
			FolderCount++;
		}
		else if (Filetype == FileType_File)
		{
			Format(strFilenames[FileCount], MAX_FILE, "%s", strTemp);
			FileCount++;
		}
	}
	delete hDL;

	//Sort the folders and files name
	SortStrings(strFoldernames, FolderCount);
	SortStrings(strFilenames, FileCount);
	
	//Display the folders and files name
	for (int i = 0; i < FolderCount; i++)
	{
		if (StrEqual(strFoldernames[i], "/."))
			continue;
		
		if (StrEqual(strFoldernames[i], "/.."))
			continue;
		
		Format(menuinfo, sizeof(menuinfo), "%s%s", g_strDirectoryPath[client], strFoldernames[i]);
		menu.AddItem(menuinfo, strFoldernames[i]);
	}
	for (int j = 0; j < FileCount; j++)
	{
		Format(menuinfo, sizeof(menuinfo), "%s/%s", g_strDirectoryPath[client], strFilenames[j]);
		if (IsFileOnWhileList(strFilenames[j]))
		{
			menu.AddItem(menuinfo, strFilenames[j]);
			continue;
		}	

		menu.AddItem(menuinfo, strFilenames[j], ITEMDRAW_DISABLED);
	}

	menu.ExitBackButton = false;
	menu.ExitButton = true;
	menu.Display(client, -1);
}

public int Handler_FileExplorer(Menu menu, MenuAction action, int client, int selection)
{
	if (action == MenuAction_Select)
	{
		char strPath[PLATFORM_MAX_PATH];
		menu.GetItem(selection, strPath, sizeof(strPath));
	
		if (DirExists(strPath))
		{
			Format(g_strDirectoryPath[client], PLATFORM_MAX_PATH, strPath);
			Command_FileExplorer(client, -1);
		}
		else if (FileExists(strPath))
		{
			Call_StartForward(sFW_OnFileSelected);
			Call_PushCell(client);
			Call_PushString(strPath);
			Call_Finish();
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (selection == MenuCancel_ExitBack)
		{
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public int Native_OpenMenu(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	char strpath[PLATFORM_MAX_PATH];
	GetNativeString(2, strpath, PLATFORM_MAX_PATH);
	
	g_strDirectoryPath[client] = strpath;
	if (g_strDirectoryPath[client][1] != '/')
	{
		Format(g_strDirectoryPath[client], PLATFORM_MAX_PATH, "/%s", g_strDirectoryPath[client]);
	}
	Command_FileExplorer(client, -1);
}

public int Native_GetDirectoryPath(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int size = GetNativeCell(3);
	
	SetNativeString(2, g_strDirectoryPath[client], size, false);
}

public int Native_WhitelistFileExtension(Handle plugin, int numParams)
{
	char extension[10];
	GetNativeString(1, extension, sizeof(extension));

	int i;
	for (i = 0; g_strWhilelistFile[i][0] != '\0'; i++)
	{
		if (StrEqual(g_strWhilelistFile[i], extension))
		{
			return;
		}
	}
	//i++;
	g_strWhilelistFile[i] = extension;
}

bool IsFileOnWhileList(char[] strFilename)
{
	for (int i = 0; g_strWhilelistFile[i][0] != '\0'; i++)
	{
		if (StrContains(strFilename, g_strWhilelistFile[i]) != -1)
		{
			return true;
		}
	}
	return false;
}