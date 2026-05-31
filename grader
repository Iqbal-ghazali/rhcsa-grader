cat > /usr/local/bin/grade << 'EOF'

#!/bin/bash

# ============================================================
#  RHCSA EX200 - Auto Grader
#  Penilaian berdasarkan objektif soal, bukan sub-komponen
# ============================================================

quiz=$1

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0

pass() {
    echo -e "  ${GREEN}✔ PASS${RESET}  $1"
    ((PASS_COUNT++))
}

fail() {
    echo -e "  ${RED}✘ FAIL${RESET}  $1"
    ((FAIL_COUNT++))
}

header() {
    echo ""
    echo -e "${YELLOW}${BOLD}╔══════════════════════════════════════════════╗${RESET}"
    printf "${YELLOW}${BOLD}  %-44s${RESET}\n" "$1"
    echo -e "${YELLOW}${BOLD}╚══════════════════════════════════════════════╝${RESET}"
}

print_summary() {
    local total=$((PASS_COUNT + FAIL_COUNT))
    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}  HASIL AKHIR${RESET}"
    echo -e "${BOLD}╚══════════════════════════════════════════════╝${RESET}"
    echo -e "  ${GREEN}✔ PASS : ${PASS_COUNT}${RESET}"
    echo -e "  ${RED}✘ FAIL : ${FAIL_COUNT}${RESET}"
    echo -e "  ${CYAN}  TOTAL: ${total} objektif${RESET}"
    if [ "$FAIL_COUNT" -eq 0 ]; then
        echo -e "\n  ${GREEN}${BOLD}🎉 Semua objektif LULUS!${RESET}"
    elif [ "$PASS_COUNT" -gt "$FAIL_COUNT" ]; then
        echo -e "\n  ${YELLOW}⚡ Hampir! Ada beberapa objektif yang belum terpenuhi.${RESET}"
    else
        echo -e "\n  ${RED}💪 Masih banyak objektif yang belum terpenuhi.${RESET}"
    fi
    echo ""
}

grade_quiz() {
local quiz="$1"
case "$quiz" in

# ─────────────────────────────────────────────
# Q1: Konfigurasi network sesuai parameter yang diminta
# ─────────────────────────────────────────────
quiz-01)
    header "QUIZ 01 — Network Configuration"

    if ip addr show 2>/dev/null | grep -q "172.24.10.10"; then
        pass "IP address 172.24.10.10 terset"
    else
        fail "IP address 172.24.10.10 tidak ditemukan"
    fi

    if ip route 2>/dev/null | grep -q "172.24.10.254"; then
        pass "Default gateway 172.24.10.254 sudah benar"
    else
        fail "Gateway 172.24.10.254 tidak ada di routing table"
    fi

    if grep -q "172.24.10.254" /etc/resolv.conf 2>/dev/null; then
        pass "DNS nameserver 172.24.10.254 terset"
    else
        fail "DNS 172.24.10.254 tidak ada di /etc/resolv.conf"
    fi

    if hostname 2>/dev/null | grep -qx "node1.domainX.example.com"; then
        pass "Hostname node1.domainX.example.com sudah benar"
    else
        fail "Hostname tidak sesuai (saat ini: $(hostname 2>/dev/null))"
    fi
    ;;

# ─────────────────────────────────────────────
# Q2: Repo harus dari URL yang diminta dan bisa digunakan
# Objektif: BaseOS & AppStream dari content.example.com bisa dipakai
# ─────────────────────────────────────────────
quiz-02)
    header "QUIZ 02 — YUM Repository"

    # Cek BaseOS: URL harus dari content.example.com dan repo aktif + bisa fetch metadata
    _baseos_url=$(grep -r "content.example.com.*BaseOS\|BaseOS.*content.example.com" \
        /etc/yum.repos.d/ 2>/dev/null | grep "^.*baseurl\|^.*mirrorlist" | head -1)
    _baseos_enabled=$(awk '/\[/{repo=$0} /baseurl.*content\.example\.com.*BaseOS/{found=1} 
        found && /enabled/{print; found=0}' /etc/yum.repos.d/*.repo 2>/dev/null | grep -v "enabled=0")

    if grep -rl "content.example.com.*BaseOS\|content\.example\.com/.*BaseOS\|BaseOS" \
        /etc/yum.repos.d/ 2>/dev/null | xargs grep -l "content.example.com" 2>/dev/null | grep -q . \
        && dnf repolist 2>/dev/null | grep -qi "baseos" \
        && dnf makecache --repo="$(dnf repolist 2>/dev/null | grep -i baseos | awk '{print $1}' | head -1)" >/dev/null 2>&1; then
        pass "Repo BaseOS dari content.example.com aktif dan bisa digunakan"
    else
        fail "Repo BaseOS tidak terkonfigurasi dari content.example.com atau tidak bisa digunakan"
    fi

    # Cek AppStream: sama, harus dari URL yang diminta
    if grep -rl "content.example.com.*AppStream\|content\.example\.com/.*AppStream\|AppStream" \
        /etc/yum.repos.d/ 2>/dev/null | xargs grep -l "content.example.com" 2>/dev/null | grep -q . \
        && dnf repolist 2>/dev/null | grep -qi "appstream" \
        && dnf makecache --repo="$(dnf repolist 2>/dev/null | grep -i appstream | awk '{print $1}' | head -1)" >/dev/null 2>&1; then
        pass "Repo AppStream dari content.example.com aktif dan bisa digunakan"
    else
        fail "Repo AppStream tidak terkonfigurasi dari content.example.com atau tidak bisa digunakan"
    fi
    ;;

# ─────────────────────────────────────────────
# Q3: Web server berjalan di port 82, SELinux tidak menghalangi
# Objektif: konten /var/www/html bisa diakses via port 82, autostart
# ─────────────────────────────────────────────
quiz-03)
    header "QUIZ 03 — SELinux Web Server (Port 82)"

    # Objektif utama: httpd harus running dan enabled
    if systemctl is-active httpd >/dev/null 2>&1 && systemctl is-enabled httpd >/dev/null 2>&1; then
        pass "httpd aktif dan enabled saat boot"
    else
        fail "httpd tidak aktif atau tidak enabled saat boot"
    fi

    # Objektif: port 82 diizinkan di SELinux dan httpd listen di 82
    if semanage port -l 2>/dev/null | grep "http_port_t" | grep -qw "82" \
        && grep -rq "Listen 82" /etc/httpd/conf/ /etc/httpd/conf.d/ 2>/dev/null; then
        pass "Port 82 dikonfigurasi benar (SELinux + httpd config)"
    else
        fail "Port 82 belum dikonfigurasi dengan benar"
    fi

    # Objektif: konten benar-benar bisa diakses
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:82 2>/dev/null | grep -q "^[23]"; then
        pass "Konten web dapat diakses di port 82"
    else
        fail "Konten web tidak dapat diakses di port 82"
    fi
    ;;

# ─────────────────────────────────────────────
# Q4: User & group sesuai spesifikasi soal
# Objektif dinilai per user/group sesuai requirement
# ─────────────────────────────────────────────
quiz-04)
    header "QUIZ 04 — User & Group Management"

    # Objektif: group sysadms ada
    if getent group sysadms >/dev/null 2>&1; then
        pass "Group sysadms ada"
    else
        fail "Group sysadms tidak ada"
    fi

    # Objektif: natasha ada, member sysadms, password trootent
    if id natasha >/dev/null 2>&1 \
        && id natasha 2>/dev/null | grep -q "sysadms" \
        && echo "trootent" | su -c "true" natasha 2>/dev/null; then
        pass "User natasha: ada, member sysadms, password benar"
    else
        fail "User natasha: tidak memenuhi semua syarat (ada + member sysadms + password trootent)"
    fi

    # Objektif: harry ada, member sysadms, password trootent
    if id harry >/dev/null 2>&1 \
        && id harry 2>/dev/null | grep -q "sysadms" \
        && echo "trootent" | su -c "true" harry 2>/dev/null; then
        pass "User harry: ada, member sysadms, password benar"
    else
        fail "User harry: tidak memenuhi semua syarat (ada + member sysadms + password trootent)"
    fi

    # Objektif: sarah ada, nologin shell, TIDAK member sysadms, password trootent
    if getent passwd sarah >/dev/null 2>&1 \
        && getent passwd sarah 2>/dev/null | cut -d: -f7 | grep -q "/sbin/nologin" \
        && ! id sarah 2>/dev/null | grep -q "sysadms"; then
        pass "User sarah: ada, shell nologin, bukan member sysadms"
    else
        fail "User sarah: tidak memenuhi semua syarat (ada + nologin + bukan member sysadms)"
    fi
    ;;

# ─────────────────────────────────────────────
# Q5: Cron job sesuai spesifikasi — setiap 2 menit, logger, pesan exact
# Objektif: satu cron entry yang memenuhi semua syarat
# ─────────────────────────────────────────────
quiz-05)
    header "QUIZ 05 — Cron Job (user natasha)"

    if crontab -u natasha -l 2>/dev/null | grep -q "^\*/2 \* \* \* \*.*logger.*EX200 in progress"; then
        pass "Cron natasha: */2 * * * * logger \"EX200 in progress\" terkonfigurasi"
    else
        fail "Cron natasha tidak sesuai spesifikasi (*/2 * * * * logger \"EX200 in progress\")"
    fi
    ;;

# ─────────────────────────────────────────────
# Q6: Direktori kolaboratif dengan semua syarat terpenuhi
# Objektif: /home/manager, group sysadms, permission 2770
# ─────────────────────────────────────────────
quiz-06)
    header "QUIZ 06 — Collaborative Directory"

    if [ -d /home/manager ] \
        && [ "$(stat -c '%G' /home/manager 2>/dev/null)" = "sysadms" ] \
        && [ "$(stat -c '%a' /home/manager 2>/dev/null)" = "2770" ]; then
        pass "Directory /home/manager: ada, group sysadms, permission 2770"
    else
        fail "Directory /home/manager tidak memenuhi semua syarat (ada + group sysadms + 2770)"
    fi
    ;;

# ─────────────────────────────────────────────
# Q7: NTP harus sinkron KE server yang diminta (utility.example.com)
# Objektif: chrony aktif, sumber adalah utility.example.com, status sinkron
# ─────────────────────────────────────────────
quiz-07)
    header "QUIZ 07 — NTP (utility.example.com)"

    # Cek server yang dikonfigurasi harus utility.example.com
    if ! grep -q "utility.example.com" /etc/chrony.conf 2>/dev/null; then
        fail "NTP server bukan utility.example.com (tidak sesuai soal)"
    # Cek chronyd aktif
    elif ! systemctl is-active chronyd >/dev/null 2>&1; then
        fail "chronyd tidak aktif"
    # Cek benar-benar sinkron ke utility.example.com
    elif chronyc sources 2>/dev/null | grep -q "utility.example.com"; then
        pass "NTP sinkron ke utility.example.com"
    else
        fail "NTP dikonfigurasi ke utility.example.com tapi belum tersinkronisasi"
    fi
    ;;

# ─────────────────────────────────────────────
# Q8: AutoFS mount home directory dari NFS server yang diminta
# Objektif: autofs aktif, mount dari utility.example.com:/rhome, writable
# ─────────────────────────────────────────────
quiz-08)
    header "QUIZ 08 — AutoFS (NFS Home Directory)"

    # Cek autofs aktif dan enabled
    if ! systemctl is-active autofs >/dev/null 2>&1 || ! systemctl is-enabled autofs >/dev/null 2>&1; then
        fail "autofs tidak aktif atau tidak enabled"
    # Cek konfigurasi mengarah ke utility.example.com dengan path /rhome
    elif grep -r "utility.example.com" /etc/auto.* 2>/dev/null | grep -q "/rhome" \
        || grep -r "172.24.10.100" /etc/auto.* 2>/dev/null | grep -q "/rhome"; then
        pass "AutoFS aktif, terkonfigurasi mount dari utility.example.com:/rhome"
    else
        fail "AutoFS aktif tapi konfigurasi tidak sesuai (harus utility.example.com:/rhome)"
    fi
    ;;

# ─────────────────────────────────────────────
# Q9: Image container dibuat dari Containerfile yang diminta, nama 'monitor'
# Objektif: image 'monitor' ada di podman
# ─────────────────────────────────────────────
quiz-09)
    header "QUIZ 09 — Container Image (monitor)"

    if podman images --format "{{.Repository}}" 2>/dev/null | grep -q "^monitor$\|/monitor$\|^localhost/monitor$" || grep -q "monitor" /home/athena/.local/share/containers/storage/overlay-images/images.json 2>/dev/null; then
        pass "Image 'monitor' tersedia di podman"
    else
        fail "Image 'monitor' tidak ditemukan di podman"
    fi
    ;;

# ─────────────────────────────────────────────
# Q10: Container service dengan semua syarat: nama, volume mapping, systemd user service
# Objektif: semua syarat terpenuhi sekaligus
# ─────────────────────────────────────────────
quiz-10)
    header "QUIZ 10 — Container Service (ascii2pdf)"

    # Cek systemd user service enabled dan aktif
    if ! systemctl --user is-enabled container-ascii2pdf.service >/dev/null 2>&1 \
        || ! systemctl --user is-active container-ascii2pdf.service >/dev/null 2>&1; then
        fail "Service container-ascii2pdf.service tidak enabled atau tidak aktif"
    # Cek volume mapping sesuai soal
    elif podman inspect ascii2pdf 2>/dev/null | grep -q "/opt/incoming" \
        && podman inspect ascii2pdf 2>/dev/null | grep -q "/opt/outgoing"; then
        pass "Container ascii2pdf: service enabled+aktif, volume mapping /opt/incoming & /opt/outgoing benar"
    else
        fail "Container ascii2pdf: service ok tapi volume mapping tidak sesuai soal"
    fi
    ;;

# ─────────────────────────────────────────────
# Q11: User alex dengan UID yang diminta
# Objektif: user ada dengan UID 3456
# ─────────────────────────────────────────────
quiz-11)
    header "QUIZ 11 — User alex (UID 3456)"

    if id alex >/dev/null 2>&1 && id alex 2>/dev/null | grep -q "uid=3456("; then
        pass "User alex ada dengan UID 3456"
    else
        fail "User alex tidak ada atau UID bukan 3456 (saat ini: $(id -u alex 2>/dev/null || echo 'user tidak ada'))"
    fi
    ;;

# ─────────────────────────────────────────────
# Q12: Semua file milik user harry dikumpulkan ke /root/harry-files
# Objektif: direktori ada dan berisi file
# ─────────────────────────────────────────────
quiz-12)
    header "QUIZ 12 — Files Owned by harry"

    if [ -d /root/harry-files ] && [ -n "$(ls -A /root/harry-files 2>/dev/null)" ]; then
        pass "/root/harry-files ada dan berisi file"
    else
        fail "/root/harry-files tidak ada atau kosong"
    fi
    ;;

# ─────────────────────────────────────────────
# Q13: String 'ich' dari /usr/share/dict/words disimpan ke /root/lines
# Objektif: hasil grep identik dengan sumbernya
# ─────────────────────────────────────────────
quiz-13)
    header "QUIZ 13 — Grep 'ich' ke /root/lines"

    if [ -f /root/lines ] \
        && [ -f /usr/share/dict/words ] \
        && diff <(grep "ich" /usr/share/dict/words) /root/lines >/dev/null 2>&1; then
        pass "/root/lines berisi hasil grep 'ich' dari /usr/share/dict/words"
    else
        fail "/root/lines tidak ada atau isinya tidak sesuai dengan grep 'ich' /usr/share/dict/words"
    fi
    ;;

# ─────────────────────────────────────────────
# Q14: Archive /usr/local ke /root/backup.tar.bz2 dengan bzip2
# Objektif: file ada, bzip2, berisi /usr/local
# ─────────────────────────────────────────────
quiz-14)
    header "QUIZ 14 — Backup Archive (bzip2)"

    if [ -f /root/backup.tar.bz2 ] \
        && file /root/backup.tar.bz2 2>/dev/null | grep -qi "bzip2" \
        && tar -tjf /root/backup.tar.bz2 2>/dev/null | grep -q "usr/local"; then
        pass "/root/backup.tar.bz2 ada, bzip2, berisi /usr/local"
    else
        fail "/root/backup.tar.bz2 tidak ada, bukan bzip2, atau tidak berisi /usr/local"
    fi
    ;;

# ─────────────────────────────────────────────
# Q15: Cari file di /usr/share ukuran >30k <50k, simpan ke /mnt/freespace/search.txt
# Objektif: file ada, tidak kosong, isinya sesuai hasil find yang diminta
# ─────────────────────────────────────────────
quiz-15)
    header "QUIZ 15 — Find Files 30K–50K di /usr/share"

    if [ ! -f /mnt/freespace/search.txt ] || [ ! -s /mnt/freespace/search.txt ]; then
        fail "/mnt/freespace/search.txt tidak ada atau kosong"
    else
        # Bandingkan isi dengan hasil find yang seharusnya
        _expected=$(find /usr/share -size +30k -size -50k 2>/dev/null | sort)
        _actual=$(sort /mnt/freespace/search.txt 2>/dev/null)
        if [ "$_expected" = "$_actual" ]; then
            pass "/mnt/freespace/search.txt berisi hasil find yang benar"
        else
            fail "/mnt/freespace/search.txt ada tapi isinya tidak sesuai hasil find /usr/share -size +30k -size -50k"
        fi
    fi
    ;;

*)
    echo -e "${RED}Quiz '$quiz' tidak dikenal.${RESET}"
    ;;
esac
}

run_all() {
    PASS_COUNT=0
    FAIL_COUNT=0
    for q in quiz-{01..15}; do
        grade_quiz "$q"
    done
    print_summary
}

case "$quiz" in
    all)
        echo -e "\n${BOLD}${CYAN}╔══════════════════════════════════════════════════════╗${RESET}"
        echo -e "${BOLD}${CYAN}   RHCSA EX200 — Full Exam Grader                      ${RESET}"
        echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════╝${RESET}"
        run_all
        ;;
    quiz-*)
        PASS_COUNT=0
        FAIL_COUNT=0
        grade_quiz "$quiz"
        print_summary
        ;;
    "")
        echo -e "\n${BOLD}Usage:${RESET}"
        echo -e "  ${CYAN}grade quiz-01${RESET}"
        echo -e "  ${CYAN}grade quiz-15${RESET}"
        echo -e "  ${CYAN}grade all${RESET}"
        echo ""
        ;;
    *)
        echo -e "${RED}Quiz '$quiz' tidak dikenal.${RESET}"
        ;;
esac
EOF

chmod +x /usr/local/bin/grade
