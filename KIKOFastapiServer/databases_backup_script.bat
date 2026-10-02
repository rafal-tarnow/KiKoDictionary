@echo off
setlocal enabledelayedexpansion

:: ================= USTAWIENIA =================
:: %~dp0 oznacza folder, w którym znajduje się ten plik .bat
:: Zakładamy, że skrypt leży w głównym folderze KIKOFastapiServer
set LIVE_DIR=%~dp0databases
set TEMP_BACKUP_DIR=%~dp0backups_temp

:: Ścieżki do narzędzi (te zostawiamy absolutne, bo to programy systemowe)
set SQLITE_EXE=C:\rclone\sqlite3.exe
set RCLONE_EXE=C:\rclone\rclone.exe

:: Nazwa folderu na Dysku Google
set GDRIVE_FOLDER=KiKo_Backupy
:: ==============================================

:: 1. Tworzenie znacznika czasu (Format: YYYY-MM-DD_HH-MM)
set TIMESTAMP=%date:~-4,4%-%date:~-7,2%-%date:~-10,2%_%time:~0,2%-%time:~3,2%
set TIMESTAMP=%TIMESTAMP: =0%

echo Rozpoczynam backup KiKo [%TIMESTAMP%]...

:: 2. Utworzenie folderu tymczasowego, jeśli nie istnieje
if not exist "%TEMP_BACKUP_DIR%" mkdir "%TEMP_BACKUP_DIR%"

:: 3. Bezpieczny zrzut (snapshot) przy użyciu sqlite3
echo Kopiowanie bazy captcha...
"%SQLITE_EXE%" "%LIVE_DIR%\captcha.db" ".backup '%TEMP_BACKUP_DIR%\captcha.db'"

echo Kopiowanie bazy users...
"%SQLITE_EXE%" "%LIVE_DIR%\users.db" ".backup '%TEMP_BACKUP_DIR%\users.db'"

echo Kopiowanie bazy sentences...
"%SQLITE_EXE%" "%LIVE_DIR%\sentences.db" ".backup '%TEMP_BACKUP_DIR%\sentences.db'"

echo Kopiowanie bazy todo...
"%SQLITE_EXE%" "%LIVE_DIR%\todo.db" ".backup '%TEMP_BACKUP_DIR%\todo.db'"

:: 4. Wysyłanie do chmury przez Rclone
echo Wysylanie na Dysk Google...
"%RCLONE_EXE%" copy "%TEMP_BACKUP_DIR%" "GoogleDrive:%GDRIVE_FOLDER%/%TIMESTAMP%"

:: 5. Czyszczenie plików tymczasowych z laptopa
echo Czyszczenie plikow tymczasowych...
del /q "%TEMP_BACKUP_DIR%\*.*"

echo Backup zakonczony sukcesem!