@echo off
setlocal EnableDelayedExpansion

for %%x in (%*) do (
  set y=%%x
  @REM Handle -V, does not handle combined single letter args, like -4V6
  IF "%%x" == "-V" GOTO :version
  @REM Handle vscode remote as special for plink only
  @REM IF "%%x" == "remote" GOTO :plink
  IF "!y:~0,13!" == "vscode.plink." GOTO :plink
)

REM use the built in ssh by default
GOTO :default_ssh

:version
echo OpenSSH
GOTO :eof

:plink
powershell -NoProfile -ExecutionPolicy Bypass %~dp0ssh.ps1 %*
GOTO :eof

:default_ssh
REM Load SSH agent
C:\PROGRA~1\git\usr\bin\bash.exe -c "if [ -e ~/.ssh/auto_agent ]; then source ~/.bashrc.d/auto_agent.bsh; export ""PATH=/usr/bin:${PATH}""; auto_agent; elif [ -f ~/.ssh/ssh-agent ]; then source ~/.ssh/ssh-agent > /dev/null; fi"

REM It appears that VSCode uses this ssh automagically? If I just say ssh.exe,
REM you'll end up using Window's ssh, which adds "DOMAIN\" in front of the user
REM name, among other... limitations
REM Convert to 8.3 naming, cause something in ssh.exe will create a child based
REM off of $0 and pass it off to "sh -c" without proper escaping, if you use
REM ProxyJump
for %%f in ("C:\Program Files\git\usr\bin\ssh.exe") do %%~sf %*
GOTO :eof