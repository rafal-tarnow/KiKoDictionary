#!/usr/bin/env bash
# =====================================================================================
#  KiKo / Maia - aktualizacja i diagnostyka backendu na KUBUNTU (dual boot z Windows)
# =====================================================================================
#
#  URUCHOMIENIE (na Kubuntu, w Konsole):
#
#    bash /mnt/windows/Users/Tom/Documents/GITHUB_MOJE/KiKoDictionary/KIKOFastapiServer/linux_update_server.sh
#
#    --check   tylko diagnoza, NIC nie zmienia (bez przebudowy, bez sprzątania)
#    --help    ten opis
#
#  "bash ..." jest potrzebne, bo na dysku NTFS (Windows) plik nie ma bitu wykonywalności.
#  Pełny log każdego uruchomienia: ~/kiko-update-logs/kiko-update-<data>.log
#
# -------------------------------------------------------------------------------------
#  KONTEKST DLA AGENTA AI (przeczytaj w całości, zanim cokolwiek zmienisz)
# -------------------------------------------------------------------------------------
#
#  Użytkownik (Tom) ma JEDEN komputer i uruchamia na zmianę:
#    - Windows 11 (dysk wewnętrzny, C:) - backend w Docker Desktop,
#    - Kubuntu 26.04 live z Ventoy (dysk USB, plik persistence ~100 GB, user "kubuntu").
#  Oba systemy NIGDY nie działają jednocześnie (dual boot), więc działa ten backend,
#  który jest akurat uruchomiony. Tunel Cloudflare (kontener cloudflared, token w .env)
#  sam łączy się z tym systemem, który działa - w panelu Cloudflare nic się nie zmienia.
#
#  WSPÓLNE PLIKI: Kubuntu montuje dysk Windows C: (NTFS, UUID 6230D07430D05121)
#  w /mnt/windows i uruchamia docker compose BEZPOŚREDNIO z repo na tym dysku:
#    /mnt/windows/Users/Tom/Documents/GITHUB_MOJE/KiKoDictionary/KIKOFastapiServer
#  Dlatego oba systemy mają te same: kod, pliki .env (sekrety) i bazy SQLite.
#  ALE każdy system ma WŁASNEGO Dockera z WŁASNYMI obrazami. Po zmianie kodu (zwykle
#  robionej na Windows) obrazy na Kubuntu są nieaktualne - ten skrypt je przebudowuje.
#
#  Konfiguracja Kubuntu (zrobiona wcześniej przez agenta, opis też w AGENTS.md):
#    - montowanie C: robi jednostka systemd /etc/systemd/system/mnt-windows.mount
#      (NIE /etc/fstab - w trybie live/casper fstab jest nadpisywany przy starcie),
#    - /etc/systemd/system/docker.service.d/wait-for-windows-disk.conf
#      (RequiresMountsFor=/mnt/windows): Docker NIE startuje bez zamontowanego C:.
#      NIE USUWAJ tego - bez tego kontenery (restart: always) wstałyby z PUSTYMI bazami
#      utworzonymi w złym miejscu i użytkownicy zobaczyliby pustą aplikację,
#    - Docker używa sterownika "vfs" (/etc/docker/daemon.json), bo overlay na overlay
#      (system live) nie działa. vfs zajmuje dużo miejsca -> skrypt na końcu sprząta.
#    - kontenery startują same przy starcie systemu (docker.service + restart: always).
#
#  SERWISY (docker-compose.yml w tym katalogu):
#    kontener            port  test zdrowia (oczekiwane HTTP 200)     baza (databases/)
#    maia-captcha        8001  /health/live                           captcha.db
#    maia-auth           8002  /health/live                           users.db
#    maia-sentences      8003  /health/live                           sentences.db
#    maia-todos          8004  /health                                todos.db
#    maia-projects       8005  /health/ready (sprawdza też bazę)      projects.db
#    cloudflared-tunnel   -    publicznie https://dev-auth.rafal-kruszyna.org/health/live
#  (databases/todo.db to pusty, nieużywany plik - ignoruj.)
#
#  MIGRACJE (Alembic):
#    - sentences i projects wykonują "alembic upgrade head" SAME przy starcie kontenera,
#    - auth NIE migruje sam (CMD = sam uvicorn) - skrypt tylko raportuje jego stan,
#    - bazy są wspólne z Windows, więc migracja wykonana na Windows jest już widoczna
#      tutaj (alembic wtedy nic nie robi). To normalne.
#
#  CO ROBI TEN SKRYPT (kolejno; każdy krok loguje wynik):
#    1. warunki: Linux, /mnt/windows zamontowany z zapisem, repo i 5 plików .env istnieją,
#       Docker działa, wolne miejsce w katalogu Dockera,
#    2. kopia bezpieczeństwa wszystkich baz (sqlite3 .backup + integrity_check)
#       do ~/kiko-db-safety-copies/<data>/ (trzymamy 5 ostatnich),
#    3. docker compose up -d --build --remove-orphans (przebudowa z aktualnego kodu),
#    4. czeka do 3 min, aż wszystkie serwisy odpowiedzą 200,
#    5. raport migracji Alembic (auth, sentences, projects) i liczby rekordów w bazach,
#    6. test publicznego dostępu przez Cloudflare (DNS przez 1.1.1.1),
#    7. sprzątanie: docker image prune + docker builder prune (tylko nieużywane rzeczy),
#    8. podsumowanie + kod wyjścia: 0 = wszystko OK, 1 = coś wymaga uwagi.
#
#  ZASADY DLA AGENTA AI:
#    - Bazy w databases/ to DANE PRODUKCYJNE prawdziwych użytkowników. Nie usuwaj, nie
#      nadpisuj, nie "naprawiaj" ich. Przywrócenie kopii z ~/kiko-db-safety-copies tylko
#      na wyraźne polecenie Toma.
#    - Nie wypisuj zawartości plików .env ani ~/.config/rclone/rclone.conf (sekrety).
#      Wolno sprawdzać, czy istnieją, i nazwy zmiennych: grep -oE '^[A-Z_]+' plik
#    - Nie zmieniaj kodu, Dockerfile, docker-compose.yml ani .env. Nie zmieniaj końców
#      linii plików .env (są CRLF - to celowe, Docker Compose je obsługuje).
#    - Nie rób operacji git z Linuksa (na NTFS git pokazuje fałszywe zmiany uprawnień).
#      Git obsługuje Tom z Windows.
#    - Nie rób "apt full-upgrade" (system live z Ventoy - aktualizacja jądra psuje start).
#    - Nie formatuj i nie "naprawiaj" (ntfsfix/chkdsk) dysku C: bez zgody Toma.
#
#  TYPOWE PROBLEMY I DIAGNOZA:
#    * "/mnt/windows nie jest zamontowany" albo "tylko do odczytu":
#        systemctl status mnt-windows.mount ; findmnt /mnt/windows ; journalctl -b -u mnt-windows.mount
#        Najczęstsza przyczyna: Windows został zahibernowany / zamknięty "na twardo" albo
#        włączone jest "Szybkie uruchamianie" -> NTFS jest "brudny" i Linux montuje go
#        tylko do odczytu. Rozwiązanie: uruchomić Windows i zamknąć go NORMALNIE
#        (Start -> Zamknij). Nie używać ntfsfix bez zgody Toma.
#    * Docker nie startuje: systemctl status docker ; journalctl -b -u docker | tail -50
#        (zwykle skutek braku /mnt/windows - patrz wyżej).
#    * Kontener się restartuje: docker compose logs --tail 80 <serwis>
#        "SECRET_KEY Field required" -> brak pliku <serwis>-microservice/.env (sekrety
#        muszą być takie same we wszystkich serwisach; NIE generuj nowych bez zgody Toma -
#        zmiana klucza wylogowuje wszystkich użytkowników).
#        "database is locked" / "disk I/O error" / "readonly database" -> problem z
#        dyskiem C: (pełny / tylko do odczytu) - patrz pierwszy punkt.
#    * Budowanie przerywa się / "no space left on device": df -h / ; docker system df
#        sprzątanie: docker system prune -f ; docker builder prune -af
#        (to usuwa tylko nieużywane obrazy i cache - bazy są poza Dockerem, bezpieczne).
#    * Lokalnie 200, publicznie nie działa: docker compose logs --tail 50 cloudflared
#        (szukaj "Registered tunnel connection"); routery potrafią cache'ować brak domeny -
#        sprawdź: curl --doh-url https://1.1.1.1/dns-query https://dev-auth.rafal-kruszyna.org/health/live
#    * Zegar: Windows trzyma czas w RTC lokalnie, Linux w UTC. Tokeny JWT mają czas
#        ważności, więc zegar musi być dobry: timedatectl (NTP synchronized: yes).
#
#  Po naprawie uruchom skrypt ponownie (albo z --check) i pokaż Tomowi podsumowanie.
# =====================================================================================

set -Eeuo pipefail

# ------------------------------ ustawienia -------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="${KIKO_SERVER_DIR:-$SCRIPT_DIR}"
WINDOWS_MOUNT="${KIKO_WINDOWS_MOUNT:-/mnt/windows}"
DB_DIR="$SERVER_DIR/databases"
SAFETY_DIR="${KIKO_SAFETY_DIR:-$HOME/kiko-db-safety-copies}"
LOG_DIR="${KIKO_LOG_DIR:-$HOME/kiko-update-logs}"
KEEP_SAFETY_COPIES=5
HEALTH_TIMEOUT_SECONDS=180
MIN_FREE_GB=4

DATABASES=(captcha users sentences todos projects)
ENV_FILES=(.env auth-microservice/.env sentences-microservice/.env todo-microservice/.env projects-microservice/.env)
# nazwa|port|ścieżka testu zdrowia
SERVICES=("captcha|8001|/health/live" "auth|8002|/health/live" "sentences|8003|/health/live" "todos|8004|/health" "projects|8005|/health/ready")
# kontener|czy migruje sam przy starcie
ALEMBIC_SERVICES=("maia-auth|nie" "maia-sentences|tak" "maia-projects|tak")
PUBLIC_CHECK_URL="https://dev-auth.rafal-kruszyna.org/health/live"

MODE="update"
TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"
PROBLEMS=()
WARNINGS=()

# ------------------------------ pomocnicze -------------------------------------------
if [[ -t 1 ]]; then C_OK=$'\e[32m'; C_ERR=$'\e[31m'; C_WARN=$'\e[33m'; C_HEAD=$'\e[1;36m'; C_END=$'\e[0m'
else C_OK=""; C_ERR=""; C_WARN=""; C_HEAD=""; C_END=""; fi

step()  { printf '\n%s==> %s%s\n' "$C_HEAD" "$*" "$C_END"; }
ok()    { printf '  %s[OK]%s %s\n' "$C_OK" "$C_END" "$*"; }
warn()  { printf '  %s[UWAGA]%s %s\n' "$C_WARN" "$C_END" "$*"; WARNINGS+=("$*"); }
fail()  { printf '  %s[BLAD]%s %s\n' "$C_ERR" "$C_END" "$*"; PROBLEMS+=("$*"); }
fatal() { fail "$*"; summary; exit 1; }

# Opis = cały komentarz z nagłówka pliku (do linii "set -Eeuo pipefail")
usage() { sed -n '2,/^set -Eeuo pipefail/p' "${BASH_SOURCE[0]}" | sed '$d' | sed 's/^# \{0,1\}//'; }

# docker bez sudo, jeśli użytkownik jest w grupie docker; inaczej przez sudo
DOCKER=(docker)
docker_cmd() { "${DOCKER[@]}" "$@"; }
compose() { docker_cmd compose --project-directory "$SERVER_DIR" -f "$SERVER_DIR/docker-compose.yml" "$@"; }

summary() {
    step "PODSUMOWANIE ($MODE)"
    if ((${#PROBLEMS[@]} == 0)); then
        ok "Wszystko działa. Backend na Kubuntu jest aktualny."
    else
        printf '  %sProblemy (%d):%s\n' "$C_ERR" "${#PROBLEMS[@]}" "$C_END"
        for p in "${PROBLEMS[@]}"; do printf '   - %s\n' "$p"; done
    fi
    if ((${#WARNINGS[@]} > 0)); then
        printf '  %sUwagi (%d):%s\n' "$C_WARN" "${#WARNINGS[@]}" "$C_END"
        for w in "${WARNINGS[@]}"; do printf '   - %s\n' "$w"; done
    fi
    printf '\n  Pełny log: %s\n' "$LOG_FILE"
    if ((${#PROBLEMS[@]} > 0)); then
        printf '  Coś nie działa? Pokaż agentowi AI ten plik skryptu (opis na górze) i log powyżej.\n'
    fi
}

# shellcheck disable=SC2329  # wywoływane przez: trap 'on_error ...' ERR
on_error() {
    local line=$1 code=$2
    fail "Nieoczekiwany błąd w linii $line (kod $code) - szczegóły w logu powyżej"
    summary
    exit 1
}

# ------------------------------ kroki -------------------------------------------------
check_preconditions() {
    step "1. Sprawdzanie warunków"

    [[ "$(uname -s)" == "Linux" ]] || fatal "To skrypt dla Linuksa (Kubuntu). Na Windows backend uruchamia Docker Desktop."
    ok "System: $(uname -sr)"

    if ! findmnt "$WINDOWS_MOUNT" >/dev/null 2>&1; then
        fatal "Dysk Windows nie jest zamontowany w $WINDOWS_MOUNT (sprawdź: systemctl status mnt-windows.mount)"
    fi
    local mount_opts
    mount_opts="$(findmnt -no OPTIONS "$WINDOWS_MOUNT")"
    if [[ ",$mount_opts," != *",rw,"* ]]; then
        fatal "Dysk Windows jest zamontowany TYLKO DO ODCZYTU ($mount_opts). Uruchom Windows i zamknij go normalnie (Start -> Zamknij)."
    fi
    ok "Dysk Windows zamontowany z zapisem: $WINDOWS_MOUNT"

    [[ -f "$SERVER_DIR/docker-compose.yml" ]] || fatal "Brak $SERVER_DIR/docker-compose.yml"
    ok "Repo: $SERVER_DIR"

    local probe="$DB_DIR/.kiko_write_test_$$"
    if touch "$probe" 2>/dev/null; then rm -f "$probe"; ok "Katalog baz jest zapisywalny"
    else fatal "Nie da się zapisać w $DB_DIR (dysk tylko do odczytu albo brak uprawnień)"; fi

    local missing=0
    for f in "${ENV_FILES[@]}"; do
        if [[ -s "$SERVER_DIR/$f" ]]; then :; else fail "Brak pliku z sekretami: $f"; missing=1; fi
    done
    ((missing == 0)) && ok "Wszystkie pliki .env są na miejscu (${#ENV_FILES[@]})"
    ((missing == 0)) || fatal "Bez plików .env serwisy nie wystartują (sekrety są tylko na dysku, nie w git)"

    for db in "${DATABASES[@]}"; do
        [[ -s "$DB_DIR/$db.db" ]] || fatal "Brak bazy lub pusty plik: databases/$db.db - STOP, nie uruchamiam kontenerów"
    done
    ok "Bazy danych na miejscu (${#DATABASES[@]})"

    if ! command -v docker >/dev/null 2>&1; then fatal "Docker nie jest zainstalowany"; fi
    if ! docker info >/dev/null 2>&1; then
        if sudo -n docker info >/dev/null 2>&1 || sudo docker info >/dev/null 2>&1; then
            DOCKER=(sudo docker)
            warn "Docker działa tylko przez sudo (użytkownik nie jest w grupie docker albo trzeba się przelogować)"
        else
            fatal "Docker nie działa (systemctl status docker ; journalctl -b -u docker | tail -50)"
        fi
    fi
    ok "Docker działa: $(docker_cmd version --format '{{.Server.Version}}' 2>/dev/null || echo '?') (sterownik: $(docker_cmd info --format '{{.Driver}}' 2>/dev/null || echo '?'))"

    local docker_root free_gb
    docker_root="$(docker_cmd info --format '{{.DockerRootDir}}' 2>/dev/null || echo /var/lib/docker)"
    free_gb="$(df -BG --output=avail "$docker_root" 2>/dev/null | tail -1 | tr -dc '0-9' || true)"
    if [[ -n "$free_gb" ]] && ((free_gb < MIN_FREE_GB)); then
        warn "Mało miejsca dla Dockera: ${free_gb} GB w $docker_root (zalecane >= ${MIN_FREE_GB} GB). Sprzątanie: docker system prune -f ; docker builder prune -af"
    else
        ok "Wolne miejsce dla Dockera: ${free_gb:-?} GB ($docker_root)"
    fi

    if timedatectl show -p NTPSynchronized --value 2>/dev/null | grep -qx yes; then ok "Zegar zsynchronizowany (NTP)"
    else warn "Zegar NIE jest zsynchronizowany (timedatectl) - tokeny logowania mogą być odrzucane"; fi
}

backup_databases() {
    step "2. Kopia bezpieczeństwa baz"
    if ! command -v sqlite3 >/dev/null 2>&1; then
        warn "Brak sqlite3 - pomijam kopię (instalacja: sudo apt install -y sqlite3)"
        return
    fi
    local target="$SAFETY_DIR/$TIMESTAMP"
    mkdir -p "$target"
    for db in "${DATABASES[@]}"; do
        if sqlite3 "$DB_DIR/$db.db" ".backup '$target/$db.db'" 2>/dev/null; then
            local integrity
            integrity="$(sqlite3 "$target/$db.db" 'PRAGMA integrity_check;' 2>&1 || true)"
            if [[ "$integrity" == "ok" ]]; then ok "$db.db -> kopia OK"
            else fail "$db.db: kopia nie przeszła integrity_check ($integrity)"; fi
        else
            fail "$db.db: nie udało się zrobić kopii (sqlite3 .backup)"
        fi
    done
    ok "Kopie: $target"
    # Zostawiamy tylko kilka ostatnich kopii
    find "$SAFETY_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort | head -n -"$KEEP_SAFETY_COPIES" |
        while read -r old; do rm -rf -- "${SAFETY_DIR:?}/$old"; done || true
}

rebuild_and_start() {
    step "3. Przebudowa i uruchomienie kontenerów (może potrwać kilka minut)"
    if compose up -d --build --remove-orphans; then ok "docker compose up --build zakończone"
    else fatal "docker compose up --build nie powiodło się (szczegóły wyżej; brak miejsca? brak internetu?)"; fi
}

wait_for_health() {
    step "4. Testy zdrowia serwisów (max ${HEALTH_TIMEOUT_SECONDS}s)"
    local deadline=$((SECONDS + HEALTH_TIMEOUT_SECONDS))
    for entry in "${SERVICES[@]}"; do
        IFS='|' read -r name port path <<<"$entry"
        local code="000"
        while ((SECONDS < deadline)); do
            code="$(curl -s -m 5 -o /dev/null -w '%{http_code}' "http://127.0.0.1:$port$path" || true)"
            [[ "$code" == "200" ]] && break
            sleep 3
        done
        if [[ "$code" == "200" ]]; then ok "$name (port $port$path) -> 200"
        else fail "$name (port $port$path) -> $code. Logi: docker compose logs --tail 80 $name"; fi
    done
    compose ps --format 'table {{.Name}}\t{{.Status}}' 2>/dev/null || compose ps
}

report_migrations_and_data() {
    step "5. Migracje bazy (Alembic) i dane"
    for entry in "${ALEMBIC_SERVICES[@]}"; do
        IFS='|' read -r container auto <<<"$entry"
        local out
        out="$(docker_cmd exec "$container" sh -c 'cd /app && alembic current 2>&1' 2>/dev/null || true)"
        if grep -q '(head)' <<<"$out"; then
            ok "$container: baza na najnowszej migracji ($(grep -m1 '(head)' <<<"$out" | awk '{print $1}'))"
        elif [[ "$auto" == "tak" ]]; then
            fail "$container: baza NIE jest na najnowszej migracji, choć kontener migruje sam - logi: docker logs $container | grep -i alembic"
        else
            warn "$container: baza nie jest na najnowszej migracji (ten serwis nie migruje sam). Najlepiej zrobić to z Windows; ewentualnie: docker exec $container alembic upgrade head"
        fi
    done

    local counts
    if counts="$(docker_cmd exec -i maia-projects python - <<'PY' 2>&1
import sqlite3
for db, table in [("users", "users"), ("sentences", "sentences"), ("todos", "tasks"), ("projects", "projects")]:
    c = sqlite3.connect(f"file:/app/db/{db}.db?mode=ro", uri=True)
    print(f"{db}: {c.execute(f'select count(*) from {table}').fetchone()[0]} rekordow")
PY
)"; then
        while read -r line; do ok "$line"; done <<<"$counts"
        if grep -q '^users: 0 ' <<<"$counts"; then
            fail "Baza users jest PUSTA - kontenery prawdopodobnie widzą zły katalog baz. STOP: docker compose down i sprawdź montowanie /mnt/windows"
        fi
    else
        warn "Nie udało się odczytać liczby rekordów: $counts"
    fi
}

check_public_access() {
    step "6. Dostęp z internetu (tunel Cloudflare)"
    local code
    code="$(curl -s -m 20 -o /dev/null -w '%{http_code}' --doh-url https://1.1.1.1/dns-query "$PUBLIC_CHECK_URL" 2>/dev/null || true)"
    if [[ "$code" == "200" ]]; then
        ok "$PUBLIC_CHECK_URL -> 200"
    else
        # Tunel potrzebuje chwili na zestawienie połączenia - jedna ponowna próba
        sleep 15
        code="$(curl -s -m 20 -o /dev/null -w '%{http_code}' --doh-url https://1.1.1.1/dns-query "$PUBLIC_CHECK_URL" 2>/dev/null || true)"
        if [[ "$code" == "200" ]]; then ok "$PUBLIC_CHECK_URL -> 200"
        else warn "Publiczny adres zwraca $code. Sprawdź: docker compose logs --tail 50 cloudflared"; fi
    fi
}

cleanup_docker() {
    step "7. Sprzątanie nieużywanych obrazów i cache budowania"
    if docker_cmd image prune -f >/dev/null 2>&1; then ok "Usunięto nieużywane obrazy"; else warn "docker image prune nie powiodło się"; fi
    if docker_cmd builder prune -af >/dev/null 2>&1; then ok "Usunięto cache budowania"; else warn "docker builder prune nie powiodło się"; fi
    docker_cmd system df 2>/dev/null | sed 's/^/    /' || true
}

# ------------------------------ start ------------------------------------------------
case "${1:-}" in
    --check) MODE="check" ;;
    --help | -h) usage; exit 0 ;;
    "") ;;
    *) printf 'Nieznana opcja: %s (użyj --help)\n' "$1"; exit 2 ;;
esac

mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/kiko-update-$TIMESTAMP.log"
# Wszystko (także błędy) trafia na ekran i do logu
exec > >(tee -a "$LOG_FILE") 2>&1
trap 'on_error $LINENO $?' ERR

printf 'KiKo - %s backendu na Kubuntu (%s)\n' "$([[ $MODE == check ]] && echo diagnoza || echo aktualizacja)" "$TIMESTAMP"

check_preconditions
if [[ "$MODE" == "update" ]]; then
    backup_databases
    rebuild_and_start
fi
wait_for_health
report_migrations_and_data
check_public_access
if [[ "$MODE" == "update" ]]; then cleanup_docker; fi
summary
if ((${#PROBLEMS[@]} > 0)); then exit 1; fi
exit 0
