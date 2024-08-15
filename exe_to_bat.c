#include <stdio.h>
#include <string.h>
#include <Windows.h>

// Compile: cl /EHsc hello.c
// Program that runs "{exename}.exe.bat", for when calling bat files directly don't work

int main(int argc, char *argv[])
{
  char *script_path;
  char *args;
  char *args_string;
  int x;
  char exe_path[MAX_PATH];
  int args_len;
  int arg0_len=0;

  STARTUPINFO si;
  PROCESS_INFORMATION pi;

  GetModuleFileNameA(NULL, exe_path, MAX_PATH);
  script_path = (char *)malloc(sizeof(char) * (strlen(exe_path)+5));
  sprintf(script_path, "%s.bat", exe_path);

  args_string = GetCommandLineA();

  // Remove first argument
  x=0;
  for(arg0_len=0;
      arg0_len < strlen(args_string);
      arg0_len++)
  {
    if (args_string[arg0_len] == argv[0][x])
    {
      x++;
    }
    else if ((x >= strlen(argv[0])) && (args_string[arg0_len] == ' '))
    {
      // Capture the space, cause I'll be adding it anyways
      arg0_len++;
      break;
    }
  }

  args = (char*)malloc(strlen(args_string) - arg0_len + strlen(script_path) + 4);
  sprintf(args, "\"%s\" %s\0", script_path, args_string + arg0_len);

  // printf("%s\n", args_string);
  // printf("%s\n", args);

  // new_argv = (char**)malloc(sizeof(char*) * (argc+4));
  // new_argv[0] = script_path;
  // for(x=1; x<argc; x++)
  //   new_argv[x] = argv[x];
  // new_argv[x] = NULL;

  // printf("%s\n", GetCommandLineA());
  // printf("%s\n", argv[0]);

  ZeroMemory( &si, sizeof(si) );
  si.cb = sizeof(si);
  ZeroMemory( &pi, sizeof(pi) );

  if (! CreateProcess(NULL,   // No module name (use command line)
        args,           // Command + args
        NULL,           // Process handle not inheritable
        NULL,           // Thread handle not inheritable
        FALSE,          // Set handle inheritance to FALSE
        0,              // No creation flags
        NULL,           // Use parent's environment block
        NULL,           // Use parent's starting directory
        &si,            // Pointer to STARTUPINFO structure
        &pi )           // Pointer to PROCESS_INFORMATION structure
  )
  {
    printf("error\n");
    return 1;
  }

  // Wait until child process exits.
  WaitForSingleObject( pi.hProcess, INFINITE );

  // Close process and thread handles.
  CloseHandle( pi.hProcess );
  CloseHandle( pi.hThread );

  // new_argv = (char**)malloc(sizeof(char*) * (argc+4));
  // new_argv[0] = "cmd.exe";
  // new_argv[1] = "/Q";
  // new_argv[2] = "/C";
  // new_argv[3] = script_path;
  // for(x=1; x<argc; x++)
  //   new_argv[x+3] = argv[x];
  // new_argv[x+3] = NULL;

  // execvp("cmd.exe", new_argv);

  // for(x=0; x<argc+1; x++)
  //   if (new_argv[x] == NULL)
  //     printf("--NULL--\n");
  //   else
  //     printf("%s\n", new_argv[x]);

  free(args);
  free(script_path);
}
