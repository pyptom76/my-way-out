#!/bin/sh

# Install V2/X2 binary and decompress binary
# mkdir /tmp/xray
# curl --retry 10 --retry-max-time 60 -L -H "Cache-Control: no-cache" -fsSL github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip -o /tmp/xray/xray.zip
# busybox unzip /tmp/xray/xray.zip -d /tmp/xray
# install -m 755 /tmp/xray/xray /usr/local/bin/runner
# install -m 755 /tmp/xray/geosite.dat /usr/local/bin/geosite.dat
# install -m 755 /tmp/xray/geoip.dat /usr/local/bin/geoip.dat
# runner -version
# rm -rf /tmp/xray


DIR_TMP="$(mktemp -d)"

# Get Ray executable release
wget -qO - https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip | busybox unzip -qd ${DIR_TMP} -

# Install Ray
EXEC=$(echo $RANDOM | md5sum | head -c 6; echo)
install -m 755 ${DIR_TMP}/xray /workdir/${EXEC}
rm -rf ${DIR_TMP}
wget -qO /workdir/geoip.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
wget -qO /workdir/geosite.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat

# Make configs
mkdir -p /etc/caddy/ /usr/share/caddy/
cat > /usr/share/caddy/robots.txt << EOF
User-agent: *
Disallow: /
EOF
curl --retry 10 --retry-max-time 60 -L -H "Cache-Control: no-cache" -fsSL $CADDYIndexPage -o /usr/share/caddy/index.html && unzip -qo /usr/share/caddy/index.html -d /usr/share/caddy/ && mv /usr/share/caddy/*/* /usr/share/caddy/
sed -e "1c :$PORT" -e "s/\$AUUID/$AUUID/g" -e "s/\$MYUUID-HASH/$(caddy hash-password --plaintext $AUUID)/g" /conf/Caddyfile >/etc/caddy/Caddyfile
sed -e "s/\$AUUID/$AUUID/g" -e "s/\$ParameterSSENCYPT/$ParameterSSENCYPT/g" /workdir/config.json >/usr/local/bin/config.json

# Remove temporary directory
rm -rf /conf

# Let's get start
exec 2>&1
exec /workdir/${EXEC} -config /usr/local/bin/config.json & /usr/bin/caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
