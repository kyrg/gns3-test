#!/bin/bash


# ====================================================
# 2. ΕΙΣΑΓΩΓΗ & ΕΛΕΓΧΟΣ ΣΤΟΙΧΕΙΩΝ ΦΟΙΤΗΤΗ
# ====================================================
echo "=================================================="
echo "       ΕΙΣΑΓΩΓΗ ΣΤΟΙΧΕΙΩΝ ΦΟΙΤΗΤΗ / ΧΡΗΣΤΗ        "
echo "=================================================="
read -p "Ονοματεπώνυμο: " STUDENT_NAME
read -p "Αριθμός Μητρώου (Α.Μ.): " STUDENT_AM
read -p "Email: " STUDENT_EMAIL
echo ""

if [ -z "$STUDENT_NAME" ] || [ -z "$STUDENT_AM" ] || [ -z "$STUDENT_EMAIL" ]; then
    echo "Σφάλμα: Όλα τα πεδία είναι υποχρεωτικά."
    exit 1
fi


# Χρώματα για την έξοδο στο τερματικό
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0

# Ορισμός του ονόματος αρχείου με βάση το Α.Μ. του φοιτητή
REPORT_FILE="2nd_Ergasia_${STUDENT_AM}.txt"
RAW_REPORT=$(mktemp)

# Αυτόματος καθαρισμός των προσωρινών αρχείων κατά την έξοδο
trap 'rm -f "$RAW_REPORT" "$REPORT_FILE"' EXIT

# Διοχέτευση όλης της εξόδου (stdout & stderr) στην οθόνη και στο προσωρινό αρχείο
exec > >(tee -a "$RAW_REPORT") 2>&1

check_result() {
    local desc="$1"
    local status="$2"
    if [ "$status" -eq 0 ]; then
        echo -e "[ ${GREEN}PASS${NC} ] $desc"
        ((PASSED++))
    else
        echo -e "[ ${RED}FAIL${NC} ] $desc"
        ((FAILED++))
    fi
}

echo "=================================================="
echo "    ΕΛΕΓΧΟΣ ΥΛΟΠΟΙΗΣΗΣ FIREWALL & APACHE CHECKS   "
echo "=================================================="
echo "Φοιτητής/τρια : $STUDENT_NAME"
echo "Α.Μ.          : $STUDENT_AM"
echo "Email         : $STUDENT_EMAIL"
echo "Ημερομηνία/Ώρα: $(date)"
echo "Hostname      : $(hostname)"

# ----------------------------------------------------
# 3. ΕΞΩΤΕΡΙΚΗ IP & SERIAL ΔΙΣΚΩΝ
# ----------------------------------------------------
echo "--------------------------------------------------"
echo "ΣΤΟΙΧΕΙΑ ΣΥΣΤΗΜΑΤΟΣ (IP & ΔΙΣΚΟΙ)"
echo "--------------------------------------------------"

EXTERNAL_IP=$(curl -s --connect-timeout 5 https://ifconfig.me || curl -s --connect-timeout 5 https://api.ipify.org || echo "Δεν βρέθηκε")
echo "Εξωτερική IP: $EXTERNAL_IP"

echo "Serial Numbers Δίσκων:"
lsblk -d -o NAME,SERIAL,MODEL,SIZE -e 7,11 | grep -v "^NAME" | while read -r line; do
    echo "   - $line"
done
echo "--------------------------------------------------"

IPT_SAVE=$(iptables-save)

# 1. Πολιτική OUTPUT ACCEPT
echo "$IPT_SAVE" | grep -q "^:OUTPUT ACCEPT"
check_result "Πολιτική OUTPUT: ACCEPT" $?

# 2. Πολιτική INPUT DROP
echo "$IPT_SAVE" | grep -q "^:INPUT DROP"
check_result "Πολιτική INPUT: DROP" $?

# 3. Απόρριψη INVALID πακέτων
echo "$IPT_SAVE" | grep -E "INPUT.*-m (conntrack|state) --(ctstate|state) INVALID.*-j DROP" > /dev/null
check_result "Κανόνας απόρριψης INVALID πακέτων" $?

# 4. Αποδοχή τοπικής κίνησης (lo)
echo "$IPT_SAVE" | grep -E "INPUT.*-i lo.*-j ACCEPT" > /dev/null
check_result "Αποδοχή τοπικής κίνησης στη διεπαφή lo" $?

# 5. Αποδοχή ESTABLISHED, RELATED
echo "$IPT_SAVE" | grep -E "INPUT.*-m (conntrack|state) --(ctstate|state) .*(ESTABLISHED|RELATED).*-j ACCEPT" > /dev/null
check_result "Αποδοχή ESTABLISHED, RELATED συνδέσεων" $?

# 6. SSH από Πανεπιστήμιο Πατρών (150.140.0.0/16)
echo "$IPT_SAVE" | grep -E "INPUT.*-s 150.140.0.0/16.*--dport 22.*-j ACCEPT" > /dev/null
check_result "SSH πρόσβαση από Παν. Πατρών (150.140.0.0/16)" $?

# 7. SSH από εσωτερικό δίκτυο (192.168.0.0/16)
echo "$IPT_SAVE" | grep -E "INPUT.*-s 192.168.0.0/16.*--dport 22.*-j ACCEPT" > /dev/null
check_result "SSH πρόσβαση από εσωτερικό δίκτυο (192.168.0.0/16)" $?

# 8. Port Forwarding (Port 80 -> 8080 στο NAT PREROUTING)
echo "$IPT_SAVE" | grep -E "PREROUTING.*--dport 80.*REDIRECT --to-ports? 8080" > /dev/null
check_result "Port Forwarding: Θύρα 80 -> 8080 (NAT PREROUTING REDIRECT)" $?

# 9. Αποδοχή κίνησης στη θύρα 8080
echo "$IPT_SAVE" | grep -E "INPUT.*--dport 8080.*-j ACCEPT" > /dev/null
check_result "Αποδοχή εισερχόμενης κίνησης στη θύρα 8080" $?

# 10. ICMP Echo Request Rate Limit (1/s, burst 5)
echo "$IPT_SAVE" | grep -E "INPUT.*-p icmp.*--icmp-type (8|echo-request).*-m limit --limit 1/(s|sec) --limit-burst 5.*-j ACCEPT" > /dev/null
check_result "Περιορισμός ICMP Echo Request (1/s, burst 5)" $?

# 11. Syslog Logging (Prefix: 'IPTables-Dropped: ', Limit: 5/min)
echo "$IPT_SAVE" | grep -E "LOG --log-prefix \"IPTables-Dropped: \".*--limit 5/min" > /dev/null
check_result "Logging μη επιτρεπόμενης κίνησης (Prefix: 'IPTables-Dropped: ', Limit: 5/min)" $?

# 12. REJECT με TCP RST για TCP θύρες
echo "$IPT_SAVE" | grep -E "INPUT.*-p tcp.*-j REJECT --reject-with tcp-reset" > /dev/null
check_result "Απάντηση με TCP RST σε αποκλεισμένες TCP θύρες" $?

# 13. REJECT με ICMP Unreachable για λοιπές θύρες
echo "$IPT_SAVE" | grep -E "INPUT.*-j REJECT --reject-with icmp-port-unreachable" > /dev/null
check_result "Απάντηση με ICMP Port Unreachable για λοιπές αποκλεισμένες θύρες" $?

# 14. Εγκατάσταση και λειτουργία Apache
systemctl is-active --quiet apache2
check_result "Λειτουργία υπηρεσίας Apache (active)" $?

# 15. Ακρόαση Apache στη θύρα 8080
ss -tlpn | grep -q ":8080.*apache2"
check_result "Ο Apache ακούει στη θύρα 8080 (αντί για την 80)" $?

echo "=================================================="
echo -e "Αποτελέσματα: ${GREEN}$PASSED PASS${NC} / ${RED}$FAILED FAIL${NC}"
echo "=================================================="

if [ "$FAILED" -eq 0 ]; then
    echo -e "${GREEN}Όλες οι απαιτήσεις της εργασίας έχουν υλοποιηθεί επιτυχώς!${NC}"
else
    echo -e "${RED}Υπάρχουν παραλείψεις ή λάθη στους κανόνες. Παρακαλώ διορθώστε τα FAIL.${NC}"
fi

# ----------------------------------------------------
# 4. ΜΕΤΑΦΟΡΤΩΣΗ ΑΝΑΦΟΡΑΣ ΣΤΟ NEXTCLOUD (WEBDAV)
# ----------------------------------------------------
cp "$RAW_REPORT" "$REPORT_FILE"

echo ""
echo "[+] Αποστολή αναφοράς ($REPORT_FILE) στο Nextcloud WebDAV..."

WEBDAV_BASE_URL="https://nextcloud.ceid.upatras.gr/public.php/webdav"
AUTH_PASS="zpF3siabk5Q4Fex:Q5u-QjY'g0"

TARGET_URL="${WEBDAV_BASE_URL}/${REPORT_FILE}"

# 1. Προσπάθεια DELETE για άρση τυχόν προηγούμενου κλειδώματος
curl -s -k -X DELETE -u "$AUTH_PASS" "$TARGET_URL" >/dev/null 2>&1
sleep 1

# 2. Upload με PUT
HTTP_CODE=$(curl -o /dev/null -w "%{http_code}" -s -k -T "$REPORT_FILE" -u "$AUTH_PASS" \
    -H 'X-Requested-With: XMLHttpRequest' \
    -H 'Overwrite: T' \
    "$TARGET_URL")

# Αν το αρχείο παραμένει κλειδωμένο στο Nextcloud (HTTP 423), αυτόματο fallback σε νέο όνομα ώστε να μην αποτύχει η υποβολή!
if [ "$HTTP_CODE" -eq 423 ]; then
    echo "[!] Το αρχείο '$REPORT_FILE' είναι κλειδωμένο στο Nextcloud (HTTP 423)."
    ALT_FILE="3rd_Ergasia_${STUDENT_AM}_new.txt"
    cp "$REPORT_FILE" "$ALT_FILE"
    TARGET_URL="${WEBDAV_BASE_URL}/${ALT_FILE}"
    echo "[+] Αυτόματη υποβολή με εναλλακτικό όνομα: $ALT_FILE ..."

    curl -s -k -X DELETE -u "$AUTH_PASS" "$TARGET_URL" >/dev/null 2>&1
    sleep 1

    HTTP_CODE=$(curl -o /dev/null -w "%{http_code}" -s -k -T "$ALT_FILE" -u "$AUTH_PASS" \
        -H 'X-Requested-With: XMLHttpRequest' \
        -H 'Overwrite: T' \
        "$TARGET_URL")
    
    if [ "$HTTP_CODE" -eq 201 ] || [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 204 ]; then
        REPORT_FILE="$ALT_FILE"
    fi
fi

if [ "$HTTP_CODE" -eq 201 ] || [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 204 ]; then
    echo "[✓] Η αναφορά ($REPORT_FILE) ανέβηκε επιτυχώς στο Nextcloud! (HTTP Status: $HTTP_CODE)"
else
    echo "[!] Σφάλμα κατά την αποστολή στο Nextcloud (HTTP Status: $HTTP_CODE)."
    echo "[i] Διαγνωστικό μήνυμα WebDAV:"
    curl -s -k -T "$REPORT_FILE" -u "$AUTH_PASS" -H 'X-Requested-With: XMLHttpRequest' "$TARGET_URL"
fi

# Το trap διαγράφει όλα τα τοπικά αρχεία ($RAW_REPORT, $REPORT_FILE, $ALT_FILE) αυτόματα κατά την έξοδο.

