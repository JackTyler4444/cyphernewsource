@echo Deploying to: 
@echo   InstantLocalLounge-web
@echo   InstantLocalLounge-android
@echo   InstantLocalLounge-desktop
@echo off
cd..
cd..
cd bin-output
xcopy PokerCardGame InstantLocalLounge-web\PokerCardGame /E /Y
xcopy PokerCardGame InstantLocalLounge-android\PokerCardGame /E /Y
xcopy PokerCardGame InstantLocalLounge-desktop\PokerCardGame /E /Y
@echo Done.