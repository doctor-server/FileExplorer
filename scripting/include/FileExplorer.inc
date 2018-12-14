/*
**
*/
#if defined _FileExplorer_included
 #endinput
#endif
#define _FileExplorer_included

public SharedPlugin __pl_FileExplorer = 
{
	name = "FileExplorer",
	file = "FileExplorer-Core.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
 
#if !defined REQUIRE_PLUGIN
public void __pl_FileExplorer_SetNTVOptional()
{
	MarkNativeAsOptional("FE_OpenMenu");
	MarkNativeAsOptional("FE_GetDirectoryPath");
	MarkNativeAsOptional("FE_WhitelistFileExtension");
}
#endif

/**
 * Open the file explorer menu
 *
 * @param client		Client index.
 * @param path			The DirectoryPath.
 * @noreturn 			
 */
native void FE_OpenMenu(int client, char[] path);

/**
 * Get the client's DirectoryPath
 *
 * @param client		Client index.
 * @param path			Return DirectoryPath.
 * @param maxlength		Maximum length of output string buffer.
 * @noreturn 			
 */
native void FE_GetDirectoryPath(int client, char[] path, int maxlength);

/**
 * Whitelist the File Extension in order to let client is able to press items on the menu
 *
 * @param extension		A string. (i.e. ".smx\0",  ".mp3\0")
 * @noreturn				
 *
 * Example: WhitelistFileExtension(".smx\0");
 */
native void FE_WhitelistFileExtension(char[] extension);

/**
 * Called when a client has selected a file.
 *
 * @param client		The client index.
 * @param strFilePath	The file path.
 * @noreturn
 **/
forward void FE_OnFileSelected(int client, char[] strFilePath);

stock char[] GetDirectoryName(char[] strpath)
{
	char temp[PLATFORM_MAX_PATH];
	Format(temp, PLATFORM_MAX_PATH, "%s", strpath);
	
	int pos = FindCharInString(temp, '/', true);	
	for (int i = pos; temp[i] != '\0'; i++)
	{
		temp[i] = '\0';
	}
	return temp;
}