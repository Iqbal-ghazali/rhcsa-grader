#!/bin/bash
# =============================================================================
# setup-nfs-server.sh
# Setup NFS Server di Controller Node untuk Lab RHCSA EX200
#
# Controller : Rocky Linux 9
# IP Lab     : 172.24.10.100 (eth1)
# Hostname   : utility.example.com
#
# Soal Q8:
#   - remoteuserX home dir di-export via NFS
#   - NFS export path : /rhome/remoteuser5
#   - Node mount via autofs ke /rhome/remoteuser5
#   - Home dir harus writable oleh usernya
# =============================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info() { echo -e "${CYAN}[INFO]${NC} $*"; }
ok()   { echo -e "${GREEN}[ OK ]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
die()  { echo -e "${RED}[FAIL]${NC} $*"; exit 1; }
step() {
    echo ""
    echo -e "${BOLD}════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  $*${NC}"
    echo -e "${BOLD}════════════════════════════════════════════${NC}"
}

[[ $EUID -ne 0 ]] && die "Jalankan sebagai root."

CONTROLLER_IP="172.24.10.100"
LAB_NETWORK="172.24.10.0/24"
NFS_EXPORT_DIR="/rhome"
REMOTE_USER="remoteuser5"
REMOTE_USER_PASSWORD="trootent"
REMOTE_UID=5000

# =============================================================================
step "STEP 1 — Install nfs-utils"
# =============================================================================
info "Install nfs-utils..."
dnf install -y nfs-utils
[[ $? -ne 0 ]] && die "Gagal install nfs-utils."
ok "nfs-utils terinstall."

# =============================================================================
step "STEP 2 — Buat user remoteuser5 di controller"
# =============================================================================
# User harus ada di controller dengan UID yang sama supaya
# file ownership di NFS share konsisten saat di-mount di node
info "Cek user ${REMOTE_USER}..."
if id "${REMOTE_USER}" &>/dev/null; then
    warn "User ${REMOTE_USER} sudah ada, skip pembuatan."
else
    useradd -u ${REMOTE_UID} -m -d "${NFS_EXPORT_DIR}/${REMOTE_USER}" "${REMOTE_USER}"
    echo "${REMOTE_USER_PASSWORD}" | passwd --stdin "${REMOTE_USER}"
    ok "User ${REMOTE_USER} dibuat dengan UID ${REMOTE_UID}."
fi

# =============================================================================
step "STEP 3 — Buat & atur direktori NFS export"
# =============================================================================
info "Buat direktori export: ${NFS_EXPORT_DIR}/${REMOTE_USER}"
mkdir -p "${NFS_EXPORT_DIR}/${REMOTE_USER}"

info "Set ownership ke ${REMOTE_USER}..."
chown -R ${REMOTE_USER}:${REMOTE_USER} "${NFS_EXPORT_DIR}/${REMOTE_USER}"
chmod 700 "${NFS_EXPORT_DIR}/${REMOTE_USER}"
ok "Direktori ${NFS_EXPORT_DIR}/${REMOTE_USER} siap."

# =============================================================================
step "STEP 4 — Konfigurasi /etc/exports"
# =============================================================================
info "Tulis /etc/exports..."

# Hapus entry lama jika ada
grep -v "^${NFS_EXPORT_DIR}" /etc/exports > /tmp/exports.tmp 2>/dev/null || true
mv /tmp/exports.tmp /etc/exports

# Tambahkan export baru
cat >> /etc/exports << EOF

# RHCSA Lab — AutoFS NFS Export (Q8)
${NFS_EXPORT_DIR}/${REMOTE_USER}  ${LAB_NETWORK}(rw,sync,no_root_squash)
EOF

ok "/etc/exports ditulis."
info "Isi /etc/exports:"
cat /etc/exports

# =============================================================================
step "STEP 5 — Enable & start NFS server"
# =============================================================================
systemctl enable --now nfs-server
systemctl is-active --quiet nfs-server || die "nfs-server gagal start. Cek: journalctl -xe"
ok "nfs-server aktif."

# Apply export tanpa restart
exportfs -arv
ok "Export di-apply."

# =============================================================================
step "STEP 6 — Buka firewall untuk NFS"
# =============================================================================
if systemctl is-active --quiet firewalld; then
    firewall-cmd --permanent --add-service=nfs
    firewall-cmd --permanent --add-service=mountd
    firewall-cmd --permanent --add-service=rpc-bind
    firewall-cmd --reload
    ok "Firewall: nfs, mountd, rpc-bind dibuka."
else
    warn "firewalld tidak aktif — skip konfigurasi firewall."
fi

# =============================================================================
step "STEP 7 — Verifikasi export"
# =============================================================================
info "Daftar NFS export aktif:"
exportfs -v

echo ""
info "Test mount dari controller sendiri:"
showmount -e localhost

# =============================================================================
# SUMMARY
# =============================================================================
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║           NFS SERVER — SETUP SELESAI ✓                      ║${NC}"
echo -e "${BOLD}${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BOLD}${GREEN}║${NC}  NFS Server  : utility.example.com (${CONTROLLER_IP})"
echo -e "${BOLD}${GREEN}║${NC}  Export path : ${NFS_EXPORT_DIR}/${REMOTE_USER}"
echo -e "${BOLD}${GREEN}║${NC}  User        : ${REMOTE_USER} (UID ${REMOTE_UID})"
echo -e "${BOLD}${GREEN}║${NC}  Password    : ${REMOTE_USER_PASSWORD}"
echo -e "${BOLD}${GREEN}║${NC}  Allow       : ${LAB_NETWORK}"
echo -e "${BOLD}${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BOLD}${GREEN}║${NC}  Jawaban Q8 di node1 (autofs):${NC}"
echo -e "${BOLD}${GREEN}║${NC}"
echo -e "${BOLD}${GREEN}║${NC}  ${YELLOW}# 1. Install autofs${NC}"
echo -e "${BOLD}${GREEN}║${NC}  ${YELLOW}dnf install -y autofs nfs-utils${NC}"
echo -e "${BOLD}${GREEN}║${NC}"
echo -e "${BOLD}${GREEN}║${NC}  ${YELLOW}# 2. Buat user remoteuser5 dengan UID yang sama${NC}"
echo -e "${BOLD}${GREEN}║${NC}  ${YELLOW}useradd -u ${REMOTE_UID} -M -d /rhome/${REMOTE_USER} ${REMOTE_USER}${NC}"
echo -e "${BOLD}${GREEN}║${NC}"
echo -e "${BOLD}${GREEN}║${NC}  ${YELLOW}# 3. Edit /etc/auto.master — tambahkan:${NC}"
echo -e "${BOLD}${GREEN}║${NC}  ${YELLOW}/rhome  /etc/auto.rhome${NC}"
echo -e "${BOLD}${GREEN}║${NC}"
echo -e "${BOLD}${GREEN}║${NC}  ${YELLOW}# 4. Buat /etc/auto.rhome — isi:${NC}"
echo -e "${BOLD}${GREEN}║${NC}  ${YELLOW}${REMOTE_USER}  -rw,sync  utility.example.com:${NFS_EXPORT_DIR}/${REMOTE_USER}${NC}"
echo -e "${BOLD}${GREEN}║${NC}"
echo -e "${BOLD}${GREEN}║${NC}  ${YELLOW}# 5. Enable & start autofs${NC}"
echo -e "${BOLD}${GREEN}║${NC}  ${YELLOW}systemctl enable --now autofs${NC}"
echo -e "${BOLD}${GREEN}║${NC}"
echo -e "${BOLD}${GREEN}║${NC}  ${YELLOW}# 6. Test${NC}"
echo -e "${BOLD}${GREEN}║${NC}  ${YELLOW}su - ${REMOTE_USER}${NC}"
echo -e "${BOLD}${GREEN}║${NC}  ${YELLOW}pwd  # harusnya /rhome/${REMOTE_USER}${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
