# Notatka dla agentów AI: tymczasowy dual boot serwera (Windows + Kubuntu)

**Stan na 2026-10-26. Rozwiązanie TYMCZASOWE**, do czasu zakupu mini PC / VPS.

Ten backend działa na jednym komputerze, który na zmianę uruchamia dwa systemy:

- **Windows 11**: Docker Desktop, katalog `C:\Users\Tom\Documents\GITHUB_MOJE\KiKoDictionary\KIKOFastapiServer`.
  Kontenery startują dopiero po zalogowaniu do Windows.
- **Kubuntu 26.04 live z Ventoy** (persistence): dysk `C:` (NTFS, UUID `6230D07430D05121`) jest montowany
  w `/mnt/windows` i Docker uruchamia **ten sam** `docker-compose.yml` z dysku `C:`.

Oba systemy używają **tych samych** baz SQLite (`databases/`, dane produkcyjne!) i tych samych plików `.env`.
Nigdy nie działają jednocześnie, więc tunel Cloudflare łączy się z tym, który akurat działa.

## Po zmianach kodu, uruchomienie / przebudowa na Kubuntu

Jeden skrypt robi wszystko (warunki, kopia baz, przebudowa, testy zdrowia, migracje, sprzątanie):

```bash
bash /mnt/windows/Users/Tom/Documents/GITHUB_MOJE/KiKoDictionary/KIKOFastapiServer/linux_update_server.sh
```

`--check` = tylko diagnoza, nic nie zmienia. Nagłówek skryptu zawiera pełny opis sytuacji i typowych
awarii (przeczytaj go przy problemach); logi: `~/kiko-update-logs/`, kopie baz: `~/kiko-db-safety-copies/`.

## Ważne przy pracy na Kubuntu

- `/etc/fstab` jest nadpisywany przy każdym starcie (casper). Montowanie robi jednostka
  `/etc/systemd/system/mnt-windows.mount`, a nie fstab.
- Docker ma blokadę `/etc/systemd/system/docker.service.d/wait-for-windows-disk.conf`: nie wystartuje bez
  zamontowanego `C:`. Nie usuwaj jej, bo bez niej kontenery (`restart: always`) utworzyłyby PUSTE bazy.
- Docker używa sterownika `vfs` (`/etc/docker/daemon.json`), bo overlay na overlay nie działa. Zajmuje dużo
  miejsca, więc po przebudowach sprzątaj: `docker image prune -f && docker builder prune -f`.
- Backup baz na Google Drive: `databases_backup_script.sh` z crona o 20:00 (log: `~/kiko-backup.log`).
  Na Windows to samo robi zadanie Harmonogramu „Kiko Dzienny Backup bazy danych” (`.bat`).
- Nie rób operacji git z Linuksa: na NTFS `git status` pokazuje fałszywe zmiany (uprawnienia plików).
  Git obsługuj z Windows.
- Nie zmieniaj końców linii plików `.env` (CRLF) i nie wypisuj ich zawartości (sekrety).
