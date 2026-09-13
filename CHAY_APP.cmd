@echo off
cd /d "%~dp0"
if not exist node_modules (
  call npm install
  if errorlevel 1 exit /b 1
)
echo Mo trinh duyet tai http://localhost:3000
node server.mjs
pause
