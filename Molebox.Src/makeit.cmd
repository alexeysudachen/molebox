@echo off 
set MAKEIT_NAME=molebox
set MAKEIT_DIR=%~dp0

cmd /c %~dp0..\xternal\makeit_proc.cmd %*
