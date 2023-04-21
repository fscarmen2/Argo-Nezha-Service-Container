#!/usr/bin/env bash

# 如参数不齐全，容器退出，另外处理某些环境变量填错后的处理
[[ -z "$GH_USER" || -z "$GH_CLIENTID" || -z "$GH_CLIENTSECRET" || -z "$ARGO_JSON" || -z "$WEB_DOMAIN" || -z "$DATA_DOMAIN" ]] && echo " There are variables that are not set. " && exit 1
grep -qv '"' <<< $ARGO_JSON && ARGO_JSON=$(sed 's@{@{"@g;s@[,:]@"\0"@g;s@}@"}@g' <<< $ARGO_JSON)  # 没有了"的处理
[ -n "$GH_REPO" ] && grep -q '/' <<< $GH_REPO && GH_REPO=$(awk -F '/' '{print $NF}' <<< $GH_REPO)  # 填了项目全路径的处理

printf "nameserver 127.0.0.11\nnameserver 8.8.4.4\nnameserver 223.5.5.5\n" > /etc/resolv.conf

# 根据参数生成哪吒服务端配置文件
[ ! -d data ] && mkdir data
cat > ./data/config.yaml << EOF
debug: false
site:
  brand: Nezha Probe
  cookiename: nezha-dashboard
  theme: default
  customcode: "<script>\r\nwindow.onload = function(){\r\nvar avatar=document.querySelector(\".item img\")\r\nvar footer=document.querySelector(\"div.is-size-7\")\r\nfooter.innerHTML=\"Powered by $GH_USER\"\r\nfooter.style.visibility=\"visible\"\r\navatar.src=\"https://raw.githubusercontent.com/Orz-3/mini/master/Color/Global.png\"\r\navatar.style.visibility=\"visible\"\r\n}\r\n</script>"
  viewpassword: ""
oauth2:
  type: github
  admin: $GH_USER
  clientid: $GH_CLIENTID
  clientsecret: $GH_CLIENTSECRET
httpport: 80
grpcport: 5555
grpchost: $DATA_DOMAIN
proxygrpcport: 443
tls: true
enableipchangenotification: false
enableplainipinnotification: false
cover: 0
ignoredipnotification: ""
ignoredipnotificationserverids: {}
EOF

# 需要 argo ssh 的，设置变量 SSH_JSON 和 SH_PASSWORD
if [ -n "$SSH_DOMAIN" ]; then
  SSH_PASSWORD=${SSH_PASSWORD:-password}
  echo root:"$SSH_PASSWORD" | chpasswd root
  sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g;s/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
  service ssh restart
fi

# 根据 Json 生成相应隧道
echo "$ARGO_JSON" > /dashboard/argo.json

[ -z "$SSH_DOMAIN" ] && SSH_DISABLE=#

cat > /dashboard/argo.yml << EOF
tunnel: $(cut -d '"' -f12 <<< "$ARGO_JSON")
credentials-file: /dashboard/argo.json
protocol: http2

ingress:
  - hostname: $WEB_DOMAIN
    service: http://localhost:80
$SSH_DISABLE  - hostname: $SSH_DOMAIN
$SSH_DISABLE    service: ssh://localhost:22
  - hostname: $DATA_DOMAIN
    service: https://localhost:443
    originRequest:
      noTLSVerify: true
  - service: http_status:404
EOF

# 生成 nginx 配置文件 and 自签署SSL证书
openssl genrsa -out /dashboard/nezha.key 2048
openssl req -new -subj "/CN=$DATA_DOMAIN" -key nezha.key -out /dashboard/nezha.csr
openssl x509 -req -days 36500 -in /dashboard/nezha.csr -signkey /dashboard/nezha.key -out /dashboard/nezha.pem

cat > /etc/nginx/nginx.conf  << EOF
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
        worker_connections 768;
        # multi_accept on;
}

http {
  upstream grpcservers {
    server localhost:5555;
    keepalive 1024;
  }

  server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $DATA_DOMAIN;

    ssl_certificate          /dashboard/nezha.pem;
    ssl_certificate_key      /dashboard/nezha.key;

    underscores_in_headers on;

    location / {
      grpc_read_timeout 300s;
      grpc_send_timeout 300s;
      grpc_socket_keepalive on;
      grpc_pass grpc://grpcservers;
    }
  }
}
EOF

# 生成定时备份数据库文件，定时任务，删除 30 天前的备份
if [[ -n "$GH_USER" && -n "$GH_EMAIL" && -n "$GH_REPO" && -n "$GH_PAT" ]]; then
  cat > ./backup.sh << EOF
#!/usr/bin/env bash

cd /tmp
git clone https://$GH_PAT@github.com/$GH_USER/$GH_REPO.git
TIME=\$(date "+%Y-%m-%d-%H:%M:%S")
tar czvf $GH_REPO/dashboard-\$TIME.tar.gz /dashboard
cd $GH_REPO
find ./ -name '*.gz' | sort | head -n -30 | xargs rm -f
git config --global user.email $GH_EMAIL
git config --global user.name $GH_USER
git add .
git commit -m "Dashboard backup by crontab at \$TIME ."
git push
cd ..
rm -rf $GH_REPO
EOF

  # 生成定时任务，每天 0:00:00 备份一次，并重启 cron 服务
  echo "0 0 * * * root bash /dashboard/backup.sh" >> /etc/crontab
  service cron restart
fi

# 生成 supervisor 进程守护配置文件
cat > /etc/supervisor/conf.d/supervisor.conf << EOF
[supervisord]
nodaemon=true
logfile=/var/log/supervisord.log
pidfile=/run/supervisord.pid

[program:nginx]
command=nginx -g "daemon off;"
autostart=true
autorestart=true
stderr_logfile=/var/log/nginx.err.log
stdout_logfile=/var/log/nginx.out.log

[program:nezha]
command=/dashboard/app
autostart=true
autorestart=true
stderr_logfile=/var/log/nezha.err.log
stdout_logfile=/var/log/nezha.out.log

[program:argo]
command=cloudflared tunnel --edge-ip-version auto --config /dashboard/argo.yml run
autostart=true
autorestart=true
stderr_logfile=/var/log/web_argo.err.log
stdout_logfile=/var/log/web_argo.out.log
EOF

# 运行 supervisor 进程守护
supervisord -c /etc/supervisor/conf.d/supervisor.conf