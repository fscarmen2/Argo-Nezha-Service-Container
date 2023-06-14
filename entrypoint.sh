#!/usr/bin/env bash

# 如不分离备份的 github 账户，默认与哪吒登陆的 github 账户一致
GH_BACKUP_USER=${GH_BACKUP_USER:-$GH_USER}

error() { echo -e "\033[31m\033[01m$*\033[0m" && exit 1; } # 红色
info() { echo -e "\033[32m\033[01m$*\033[0m"; }   # 绿色
hint() { echo -e "\033[33m\033[01m$*\033[0m"; }   # 黄色

# 如参数不齐全，容器退出，另外处理某些环境变量填错后的处理
[[ -z "$GH_USER" || -z "$GH_CLIENTID" || -z "$GH_CLIENTSECRET" || -z "$ARGO_JSON" || -z "$WEB_DOMAIN" || -z "$DATA_DOMAIN" ]] && error " There are variables that are not set. "
grep -qv '"' <<< $ARGO_JSON && ARGO_JSON=$(sed 's@{@{"@g;s@[,:]@"\0"@g;s@}@"}@g' <<< $ARGO_JSON)  # 没有了"的处理
[ -n "$GH_REPO" ] && grep -q '/' <<< $GH_REPO && GH_REPO=$(awk -F '/' '{print $NF}' <<< $GH_REPO)  # 填了项目全路径的处理

echo -e "nameserver 127.0.0.11\nnameserver 8.8.4.4\nnameserver 223.5.5.5\nnameserver 2001:4860:4860::8844\nnameserver 2400:3200::1\n" > /etc/resolv.conf

# 根据参数生成哪吒服务端配置文件
[ ! -d data ] && mkdir data
cat > /dashboard/data/config.yaml << EOF
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
protocol: h2mux

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

# 生成备份和恢复脚本
if [[ -n "$GH_BACKUP_USER" && -n "$GH_EMAIL" && -n "$GH_REPO" && -n "$GH_PAT" ]]; then
  # 生成定时备份数据库脚本，定时任务，删除 30 天前的备份
  cat > /dashboard/backup.sh << EOF
#!/usr/bin/env bash

GH_PAT=$GH_PAT
GH_BACKUP_USER=$GH_BACKUP_USER
GH_EMAIL=$GH_EMAIL
GH_REPO=$GH_REPO

error() { echo -e "\033[31m\033[01m\$*\033[0m" && exit 1; } # 红色
info() { echo -e "\033[32m\033[01m\$*\033[0m"; }   # 绿色
hint() { echo -e "\033[33m\033[01m\$*\033[0m"; }   # 黄色

[ "\$(wget -qO- --header="Authorization: token \$GH_PAT" https://api.github.com/repos/\$GH_BACKUP_USER/\$GH_REPO | grep -oPm1 '(?<="private": ).*(?=,)')" != true ] && error "\n This is not exist nor a private repository and the script exits. \n"

[ -n "\$1" ] && WAY=Scheduled || WAY=Manualed

# 克隆现有备份库
cd /tmp
git clone https://\$GH_PAT@github.com/\$GH_BACKUP_USER/\$GH_REPO.git

# 停掉面板才能备份
hint "\n \$(supervisorctl stop nezha) \n"
sleep 3

# github 备份并重启面板
if [[ \$(supervisorctl status nezha) =~ STOPPED ]]; then
  TIME=\$(date "+%Y-%m-%d-%H:%M:%S")
  tar czvf \$GH_REPO/dashboard-\$TIME.tar.gz /dashboard
  hint "\n \$(supervisorctl start nezha) \n"
  cd \$GH_REPO
  [ -e ./.git/index.lock ] && rm -f ./.git/index.lock
  echo "dashboard-\$TIME.tar.gz" > /dbfile
  echo "dashboard-\$TIME.tar.gz" > README.md
  find ./ -name '*.gz' | sort | head -n -8 | xargs rm -f
  git config --global user.email \$GH_EMAIL
  git config --global user.name \$GH_BACKUP_USER
  git checkout --orphan tmp_work
  git add .
  git commit -m "\$WAY at \$TIME ."
  git push -f -u  origin  HEAD:main
  cd ..
  rm -rf \$GH_REPO
fi

[[ \$(supervisorctl status nezha) =~ RUNNING ]] && info "\n Done! \n" || error "\n Fail! \n"
EOF

  # 生成还原数据脚本
  cat > /dashboard/restore.sh << EOF
#!/usr/bin/env bash

GH_PAT=$GH_PAT
GH_BACKUP_USER=$GH_BACKUP_USER
GH_REPO=$GH_REPO

error() { echo -e "\033[31m\033[01m\$*\033[0m" && exit 1; } # 红色
info() { echo -e "\033[32m\033[01m\$*\033[0m"; }   # 绿色
hint() { echo -e "\033[33m\033[01m\$*\033[0m"; }   # 黄色

if [ "\$1" = a ]; then
  ONLINE="\$(wget -qO- --header="Authorization: token \$GH_PAT" "https://raw.githubusercontent.com/\$GH_BACKUP_USER/\$GH_REPO/main/README.md" | sed "/^$/d" | head -n 1)"
  [ "\$ONLINE" = "\$(cat /dbfile)" ] && exit
  [[ "\$ONLINE" =~ tar\.gz$ && "\$ONLINE" != "\$(cat /dbfile)" ]] && FILE="\$ONLINE" && echo "\$FILE" > /dbfile || exit
elif [[ "\$1" =~ tar\.gz$ ]]; then
  FILE="\$1"
fi

until [[ -n "\$FILE" || "\$i" = 5 ]]; do
  [ -z "\$FILE" ] && read -rp ' Please input the backup file name (*.tar.gz): ' FILE
  ((i++)) || true
done

if [ -n "\$FILE" ]; then
  [[ "\$FILE" =~ http.*/.*tar.gz ]] && FILE=\$(awk -F '/' '{print \$NF}' <<< \$FILE)
else
  error "\n The input has failed more than 5 times and the script exits. \n"
fi

DOWNLOAD_URL=https://raw.githubusercontent.com/\$GH_BACKUP_USER/\$GH_REPO/main/\$FILE
wget --header="Authorization: token \$GH_PAT" --header='Accept: application/vnd.github.v3.raw' -O /tmp/backup.tar.gz "\$DOWNLOAD_URL"

if [ -e /tmp/backup.tar.gz ]; then
  hint "\n \$(supervisorctl stop nezha) \n"
  tar xzvf /tmp/backup.tar.gz --exclude='dashboard/*.sh' -C /
  rm -f /tmp/backup.tar.gz
  hint "\n \$(supervisorctl start nezha) \n"
fi

[[ \$(supervisorctl status nezha) =~ RUNNING ]] && info "\n Done! \n" || error "\n Fail! \n"
EOF

  # 生成定时任务，每天北京时间 4:00:00 备份一次，并重启 cron 服务; 每分钟自动检测在线备份文件里的内容
  grep -q '/dashboard/backup.sh' /etc/crontab || echo "0 4 * * * root bash /dashboard/backup.sh a" >> /etc/crontab
  grep -q '/dashboard/restore.sh' /etc/crontab || echo "* * * * * root bash /dashboard/restore.sh a" >> /etc/crontab
  service cron restart
fi

# 生成 supervisor 进程守护配置文件
cat > /etc/supervisor/conf.d/damon.conf << EOF
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

[program:agent]
command=/dashboard/nezha-agent -s localhost:5555 -p abcdefghijklmnopqr
autostart=true
autorestart=true
stderr_logfile=/var/log/agent.err.log
stdout_logfile=/var/log/agent.out.log

[program:argo]
command=cloudflared tunnel --edge-ip-version auto --config /dashboard/argo.yml run
autostart=true
autorestart=true
stderr_logfile=/var/log/web_argo.err.log
stdout_logfile=/var/log/web_argo.out.log
EOF

# 赋执行权给 sh  文件
chmod +x /dashboard/*.sh

# 运行 supervisor 进程守护
supervisord -c /etc/supervisor/supervisord.conf
