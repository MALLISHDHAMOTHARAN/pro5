#!/bin/bash

# ============================================================
# Linux Security Assignment
# Secure Departmental Directory
# ============================================================

set -e

# -----------------------------
# Configuration
# -----------------------------

GROUP_NAME="students"

USER1="student1"
USER2="student2"
UNAUTHORIZED="unauthorized"

BASE_DIR="/opt/department"
STUDENT_DIR="/opt/department/students"
TEST_FILE="/opt/department/students/student_info.txt"

# Select an appropriate SELinux type for your implementation.
SELINUX_TYPE="httpd_sys_content_t"

# Select/document an appropriate SELinux boolean.
SELINUX_BOOLEAN="httpd_enable_homedirs"


echo "======================================"
echo " Linux Security Assignment"
echo "======================================"

# ------------------------------------------------------------
# TODO 1: Check that the script is running as root
# ------------------------------------------------------------
echo "[1] Checking root privileges..."

if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run as root." >&2
  exit 1
fi

# ------------------------------------------------------------
# TODO 2: Check SELinux status
# ------------------------------------------------------------
echo "[2] Checking SELinux..."

if command -v getenforce >/dev/null 2>&1; then
  STATUS=$(getenforce)
  if [ "$STATUS" != "Enforcing" ]; then
    echo "Error: SELinux must be enabled and in Enforcing mode (Current mode: $STATUS)." >&2
    exit 1
  fi
else
  echo "Error: SELinux tools not found." >&2
  exit 1
fi

# ------------------------------------------------------------
# TODO 3: Create the students group
# ------------------------------------------------------------
echo "[3] Creating group: ${GROUP_NAME}"

if ! getent group "${GROUP_NAME}" >/dev/null 2>&1; then
  groupadd "${GROUP_NAME}"
  echo "Group ${GROUP_NAME} created."
else
  echo "Group ${GROUP_NAME} already exists."
fi

# ------------------------------------------------------------
# TODO 4: Create users
# ------------------------------------------------------------
echo "[4] Creating users..."

for USER in "${USER1}" "${USER2}"; do
  if ! id -u "${USER}" >/dev/null 2>&1; then
    useradd -g "${GROUP_NAME}" "${USER}"
    echo "User ${USER} created and added to group ${GROUP_NAME}."
  else
    usermod -aG "${GROUP_NAME}" "${USER}"
    echo "User ${USER} updated."
  fi
done

if ! id -u "${UNAUTHORIZED}" >/dev/null 2>&1; then
  useradd "${UNAUTHORIZED}"
  echo "User ${UNAUTHORIZED} created without assignment to ${GROUP_NAME}."
else
  echo "User ${UNAUTHORIZED} already exists."
fi

# ------------------------------------------------------------
# TODO 5: Create departmental directory
# ------------------------------------------------------------
echo "[5] Creating directory..."

mkdir -p "${STUDENT_DIR}"

# ------------------------------------------------------------
# TODO 6: Configure ownership and permissions
# ------------------------------------------------------------
echo "[6] Configuring ownership and permissions..."

# Set ownership to root:students
chown root:"${GROUP_NAME}" "${STUDENT_DIR}"

# Set permissions to 2770 (SGID enabled, rwx for owner and group, none for others)
chmod 2770 "${STUDENT_DIR}"

# ------------------------------------------------------------
# TODO 7: Create test file
# ------------------------------------------------------------
echo "[7] Creating test file..."

echo "Welcome to the Secure Departmental Directory!" > "${TEST_FILE}"
chown root:"${GROUP_NAME}" "${TEST_FILE}"
chmod 660 "${TEST_FILE}"

# ------------------------------------------------------------
# TODO 8: Configure persistent SELinux file context
# ------------------------------------------------------------
echo "[8] Configuring SELinux file context..."

# Ensure policycoreutils-python (or policycoreutils-python-utils) is installed for semanage
if ! command -v semanage >/dev/null 2>&1; then
  echo "Installing policycoreutils management tools..."
  if command -v dnf >/dev/null 2>&1; then
    dnf install -y policycoreutils-python-utils
  elif command -v yum >/dev/null 2>&1; then
    yum install -y policycoreutils-python
  fi
fi

# Add persistent SELinux context rule for the directory and its contents
semanage fcontext -a -t "${SELINUX_TYPE}" "${STUDENT_DIR}(/.*)?" || semanage fcontext -m -t "${SELINUX_TYPE}" "${STUDENT_DIR}(/.*)?"

# Apply the context recursively
restorecon -R -v "${STUDENT_DIR}"

# ------------------------------------------------------------
# TODO 9: Configure SELinux boolean
# ------------------------------------------------------------
echo "[9] Configuring SELinux boolean..."

setsebool -P "${SELINUX_BOOLEAN}" on

# ------------------------------------------------------------
# TODO 10: Verification
# ------------------------------------------------------------
echo "[10] Verification"

echo
echo "Users:"
id "${USER1}" || true
id "${USER2}" || true
id "${UNAUTHORIZED}" || true

echo
echo "Directory:"
ls -ld "${STUDENT_DIR}" || true

echo
echo "SELinux context:"
ls -Zd "${STUDENT_DIR}" || true

echo
echo "SELinux status:"
getenforce || true

echo
echo "Selected SELinux boolean:"
if [ -n "${SELINUX_BOOLEAN}" ]; then
  getsebool "${SELINUX_BOOLEAN}" || true
else
  echo "TODO: Set SELINUX_BOOLEAN"
fi

echo
echo "======================================"
echo " Script completed"
echo "======================================"
