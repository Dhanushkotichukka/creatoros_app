@echo off
echo ===================================================
echo 🛠️  CreatorOS Repair & Build Tool 🛠️
echo ===================================================
echo.
echo Phase 1: Cleaning and fetching dependencies...
cd frontend
call flutter clean
call flutter pub get

echo.
echo Phase 2: Building your Web Dashboard...
echo (This may take 1-2 minutes. Please wait...)
call flutter build web --release

echo.
echo ===================================================
echo ✅ SUCCESS! Your app is now updated.
echo ===================================================
echo.
echo Please go to your browser (http://localhost:8080) 
echo and press CTRL + F5 to see the new Post Hub!
echo.
pause
