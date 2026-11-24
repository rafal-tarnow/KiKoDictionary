#!/usr/bin/env bash
# =============================================================================
#  Backup baz SQLite KiKo -> Google Drive (Linux, odpowiednik databases_backup_script.bat)
#
#  1. Bezpieczny snapshot kazdej bazy przez `sqlite3 .backup` (dziala przy pracujacych kontenerach)
#  2. Kontrola spojnosci kopii (PRAGMA integrity_check)
#  3. Wysylka przez rclone do  <remote>:<folder>/<YYYY-MM-DD_HH-MM>/
#  4. Sprzatanie plikow tymczasowych (zawsze, takze po bledzie)
#
#  Kod wyjscia: 0 = wszystko OK, 1 = co najmniej jedna baza / wysylka sie nie udala
#  (cron i monitoring widza blad - w przeciwienstwie do wersji .bat).
#
#  Wymagania:  sudo apt install sqlite3 rclone   +   jednorazowo: rclone config
#  Cron (codziennie 20:00):
#    0 20 * * * /sciezka/KIKOFastapiServer/databases_backup_script.sh >> /var/log/kiko-backup.log 2>&1
#
#  Wszystkie ustawienia mozna nadpisac zmiennymi srodowiskowymi, np.:
#    GDRIVE_REMOTE=MojDrive KEEP_DAYS=30 ./databases_backup_script.sh
# =============================================================================
set -Eeuo pipefail

# ================= USTAWIENIA =================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LIVE_DIR="${LIVE_DIR:-$SCRIPT_DIR/databases}"
TEMP_BACKUP_DIR="${TEMP_BACKUP_DIR:-$SCRIPT_DIR/backups_temp}"

SQLITE_BIN="${SQLITE_BIN:-sqlite3}"
RCLONE_BIN="${RCLONE_BIN:-rclone}"

# Nazwa remote'a z `rclone config` i folder na Dysku Google (jak w wersji .bat)
GDRIVE_REMOTE="${GDRIVE_REMOTE:-GoogleDrive}"
GDRIVE_FOLDER="${GDRIVE_FOLDER:-KiKo_Backupy}"

# Usuwanie backupow starszych niz N dni z Dysku Google (0 = nie usuwaj niczego)
KEEP_DAYS="${KEEP_DAYS:-0}"

# Bazy do backupu (nazwy plikow w LIVE_DIR)
DATABASES=(captcha.db users.db sentences.db todos.db projects.db)
# ==============================================

TIMESTAMP="$(date +%Y-%m-%d_%H-%M)"
DESTINATION="${GDRIVE_REMOTE}:${GDRIVE_FOLDER}/${TIMESTAMP}"
LOCK_FILE="${TEMP_BACKUP_DIR}/.backup.lock"

log() { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }
fail() { log "BLAD: $*"; }

require() {
    if ! command -v "$1" >/dev/null 2>&1; then
        fail "nie znaleziono programu '$1' (zainstaluj: sudo apt install $2)"
        exit 1
    fi
}

cleanup() {
    # Usuwamy tylko kopie baz - katalog i plik blokady zostaja
    find "$TEMP_BACKUP_DIR" -maxdepth 1 -type f -name '*.db' -delete 2>/dev/null || true
}

main() {
    require "$SQLITE_BIN" sqlite3
    require "$RCLONE_BIN" rclone

    mkdir -p "$TEMP_BACKUP_DIR"

    # Blokada: drugi rownolegly backup (np. reczny + cron) konczy sie od razu
    exec 9>"$LOCK_FILE"
    if ! flock -n 9; then
        fail "inny backup juz trwa (blokada: $LOCK_FILE)"
        exit 1
    fi
    trap cleanup EXIT
    cleanup  # resztki po ewentualnym przerwanym poprzednim backupie

    log "Rozpoczynam backup KiKo [$TIMESTAMP] -> $DESTINATION"

    local errors=0 copied=0
    for db in "${DATABASES[@]}"; do
        local source="$LIVE_DIR/$db"
        local target="$TEMP_BACKUP_DIR/$db"

        if [[ ! -s "$source" ]]; then
            fail "brak bazy lub pusty plik: $source"
            errors=$((errors + 1))
            continue
        fi

        log "Kopiowanie bazy $db..."
        if ! "$SQLITE_BIN" "$source" ".backup '$target'"; then
            fail "sqlite3 .backup nie powiodl sie dla $db"
            errors=$((errors + 1))
            continue
        fi

        local integrity
        integrity="$("$SQLITE_BIN" "$target" 'PRAGMA integrity_check;' 2>&1 || true)"
        if [[ "$integrity" != "ok" ]]; then
            fail "kopia $db nie przeszla integrity_check: $integrity"
            rm -f "$target"
            errors=$((errors + 1))
            continue
        fi

        copied=$((copied + 1))
    done

    if (( copied == 0 )); then
        fail "nie skopiowano zadnej bazy - pomijam wysylke"
        exit 1
    fi

    log "Wysylanie $copied baz na Dysk Google..."
    if ! "$RCLONE_BIN" copy "$TEMP_BACKUP_DIR" "$DESTINATION" --include '*.db'; then
        fail "rclone copy nie powiodl sie"
        exit 1
    fi

    if (( KEEP_DAYS > 0 )); then
        log "Usuwanie backupow starszych niz $KEEP_DAYS dni..."
        if ! "$RCLONE_BIN" delete "${GDRIVE_REMOTE}:${GDRIVE_FOLDER}" --min-age "${KEEP_DAYS}d" ||
           ! "$RCLONE_BIN" rmdirs "${GDRIVE_REMOTE}:${GDRIVE_FOLDER}" --leave-root; then
            fail "nie udalo sie usunac starych backupow (nowy backup jest juz wyslany)"
            errors=$((errors + 1))
        fi
    fi

    if (( errors > 0 )); then
        fail "backup zakonczony z bledami: $errors (wyslane bazy: $copied)"
        exit 1
    fi
    log "Backup zakonczony sukcesem! (wyslane bazy: $copied)"
}

main "$@"
