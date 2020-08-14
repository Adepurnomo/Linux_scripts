#ADJUSMETN YOUR DOMAIN
LDAPSEARCH=/opt/zimbra/common/bin/ldapsearch
ZMPROV=/opt/zimbra/bin/zmprov
DOMAIN_NAME="example.co.id"
TIMESTAMP=`date +%N`
TMP_DIR=/tmp
ADS_TMP=$TMP_DIR/users_ads_$TIMESTAMP.lst
ZCS_TMP=$TMP_DIR/users_zcs_$TIMESTAMP.lst
DIF_TMP=$TMP_DIR/users_dif_$TIMESTAMP.lst
ADS_TMP_CEK=$TMP_DIR/users_ads_cek_$TIMESTAMP.lst

#SERVER AD
LDAP_SERVER="ldap://jkt-dc0.example.co.id:389"
DOMAIN="jkt-dc0.example.co.id"

# OUnya nanti disesuiakan dengan AD
BASEDN="dc=example,dc=co,dc=id"
BINDDN="CN=administrator,CN=Users,DC=example,DC=co,DC=id"
BINDPW="123"
FILTER="(&(sAMAccountName=*)(objectClass=user)(givenName=*))"
FIELDS="mail"

#CEK PING DARI AD
CEK_PING=$(ping $DOMAIN -c 6 | grep "received" | awk '{print $4}')

#CEK TELNET KE PORT AD
#CEK_TELNET=$(telnet $DOMAIN 389 | grep "connected |)

#CEK QUERY USER DARI AD
$LDAPSEARCH -x -H $LDAP_SERVER -b $BASEDN -D "$BINDDN" -w $BINDPW "$FILTER" $FIELDS | \
  grep "@$DOMAIN_NAME" | \
  awk '{print $2}' | \
  sort > $ADS_TMP_CEK
CEK_ADS=$(cat $ADS_TMP_CEK | wc -l)

#JALANKAN PROSES SINKRON JIKA MENDAPAT PING REPLY DARI AD & BERHASIL QUERY USER DARI AD
if [ $CEK_PING == 6 ] && [ $CEK_ADS -gt 0 ];
then

# Extract users from ADS
echo -n "Quering ADS... "
$LDAPSEARCH -x -H $LDAP_SERVER -b $BASEDN -D "$BINDDN" -w $BINDPW "$FILTER" $FIELDS | \
  grep "@$DOMAIN_NAME" | \
  awk '{print $2}' | \
  sort > $ADS_TMP
echo "Found `cat $ADS_TMP | wc -l` users ($ADS_TMP)"

# Extract users from ZCS
echo -n "Quering ZCS... "
$ZMPROV -l getAllAccounts $DOMAIN_NAME |\
sort > $ZCS_TMP
echo "Found `cat $ZCS_TMP | wc -l` users ($ZCS_TMP)"
 
# Generate diff
echo "Generating diff file ($DIF_TMP)"
diff -u $ZCS_TMP $ADS_TMP | grep "$DOMAIN_NAME" > $DIF_TMP

# Clean up users list
rm -f $ADS_TMP $ZCS_TMP

# Delete old users
echo -n "Old users: "
cat $DIF_TMP | grep ^- | wc -l
for i in $(cat $DIF_TMP | grep ^- | sed s/^-//g);
do
  echo -n " - Closed $i ";
  $ZMPROV ModifyAccount $i zimbraAccountStatus closed > /dev/null;
  RES=$?
  if [ "$RES" == "0" ]; then echo "[Ok]"; else echo "[Err]"; fi
done

# Clean up diff list
rm -f $DIF_TMP

fi
