set -e
cat <<EOT >/tmp/xx
aaa
bbb
ccc
EOT

echo 1
set +e
a=`cat /tmp/xx |grep zzz`
echo 2
