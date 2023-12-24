#!/usr/bin/env bash

# 首次运行时执行以下流程，再次运行时存在 /etc/supervisor/conf.d/damon.conf 文件，直接到最后一步
if [ ! -s /etc/supervisor/conf.d/damon.conf ]; then

  # 设置 Github CDN 及若干变量
  GH_PROXY=https://mirror.ghproxy.com/
  GRPC_PROXY_PORT=443
  GRPC_PORT=5555
  WEB_PORT=80
  CADDY_HTTP_PORT=2052
  WORK_DIR=/dashboard

  # 如不分离备份的 github 账户，默认与哪吒登陆的 github 账户一致
  GH_BACKUP_USER=${GH_BACKUP_USER:-$GH_USER}

  error() { echo -e "\033[31m\033[01m$*\033[0m" && exit 1; } # 红色
  info() { echo -e "\033[32m\033[01m$*\033[0m"; }   # 绿色
  hint() { echo -e "\033[33m\033[01m$*\033[0m"; }   # 黄色

  # 如参数不齐全，容器退出，另外处理某些环境变量填错后的处理
  [[ -z "$GH_USER" || -z "$GH_CLIENTID" || -z "$GH_CLIENTSECRET" || -z "$ARGO_AUTH" || -z "$ARGO_DOMAIN" ]] && error " There are variables that are not set. "
  [[ "$ARGO_AUTH" =~ TunnelSecret ]] && grep -qv '"' <<< "$ARGO_AUTH" && ARGO_AUTH=$(sed 's@{@{"@g;s@[,:]@"\0"@g;s@}@"}@g' <<< "$ARGO_AUTH")  # Json 时，没有了"的处理
  [[ "$ARGO_AUTH" =~ ey[A-Z0-9a-z=]{120,250}$ ]] && ARGO_AUTH=$(awk '{print $NF}' <<< "$ARGO_AUTH") # Token 复制全部，只取最后的 ey 开始的
  [ -n "$GH_REPO" ] && grep -q '/' <<< "$GH_REPO" && GH_REPO=$(awk -F '/' '{print $NF}' <<< "$GH_REPO")  # 填了项目全路径的处理

  # 设置 DNS
  echo -e "nameserver 127.0.0.11\nnameserver 8.8.4.4\nnameserver 223.5.5.5\nnameserver 2001:4860:4860::8844\nnameserver 2400:3200::1\n" > /etc/resolv.conf

  # 设置 +8 时区 (北京时间)
  ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
  dpkg-reconfigure -f noninteractive tzdata

  # 判断处理器架构
  case $(uname -m) in
    aarch64|arm64 ) ARCH=arm64 ;;
    x86_64|amd64 ) ARCH=amd64 ;;
    armv7* ) ARCH=arm ;;
    * ) error " $(text 2) "
  esac

  # 用户选择使用 gRPC 反代方式: Nginx / Caddy / grpcwebproxy，默认为 Caddy；如需使用 grpcwebproxy，把 REVERSE_PROXY_MODE 的值设为 nginx 或 grpcwebproxy
  if [ "$REVERSE_PROXY_MODE" = 'grpcwebproxy' ]; then
    wget -c ${GH_PROXY}https://github.com/fscarmen2/Argo-Nezha-Service-Container/releases/download/grpcwebproxy/grpcwebproxy-linux-$ARCH.tar.gz -qO- | tar xz -C $WORK_DIR
    chmod +x $WORK_DIR/grpcwebproxy
    GRPC_PROXY_RUN="$WORK_DIR/grpcwebproxy --server_tls_cert_file=$WORK_DIR/nezha.pem --server_tls_key_file=$WORK_DIR/nezha.key --server_http_tls_port=$GRPC_PROXY_PORT --backend_addr=localhost:$GRPC_PORT --backend_tls_noverify --server_http_max_read_timeout=300s --server_http_max_write_timeout=300s"
  elif [ "$REVERSE_PROXY_MODE" = 'nginx' ]; then
    GRPC_PROXY_RUN='nginx -g "daemon off;"'
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
    server localhost:$GRPC_PORT;
    keepalive 1024;
  }
  server {
    listen 127.0.0.1:$GRPC_PROXY_PORT ssl http2;
    server_name $ARGO_DOMAIN;
    ssl_certificate          $WORK_DIR/nezha.pem;
    ssl_certificate_key      $WORK_DIR/nezha.key;
    underscores_in_headers on;
    location / {
      grpc_read_timeout 300s;
      grpc_send_timeout 300s;
      grpc_socket_keepalive on;
      grpc_pass grpc://grpcservers;
    }
    access_log  /dev/null;
    error_log   /dev/null;
  }
}
EOF
  else
    CADDY_LATEST=$(wget -qO- "https://api.github.com/repos/caddyserver/caddy/releases/latest" | awk -F [v\"] '/"tag_name"/{print $5}' || echo '2.7.6')
    wget -c ${GH_PROXY}https://github.com/caddyserver/caddy/releases/download/v${CADDY_LATEST}/caddy_${CADDY_LATEST}_linux_${ARCH}.tar.gz -qO- | tar xz -C $WORK_DIR caddy
    GRPC_PROXY_RUN="$WORK_DIR/caddy run --config $WORK_DIR/Caddyfile --watch"
    cat > $WORK_DIR/Caddyfile  << EOF
{
    http_port $CADDY_HTTP_PORT
}

:$GRPC_PROXY_PORT {
    reverse_proxy {
        to localhost:$GRPC_PORT
        transport http {
            versions h2c 2
        }
    }
    tls $WORK_DIR/nezha.pem $WORK_DIR/nezha.key
}
EOF
  fi

  # 下载需要的应用
  DASHBOARD_LATEST=$(wget -qO- "https://api.github.com/repos/naiba/nezha/releases/latest" | awk -F '"' '/"tag_name"/{print $4}')
  wget -O /tmp/dashboard.zip ${GH_PROXY}https://github.com/naiba/nezha/releases/download/$DASHBOARD_LATEST/dashboard-linux-$ARCH.zip
  unzip /tmp/dashboard.zip -d /tmp
  mv -f /tmp/dist/dashboard-linux-$ARCH $WORK_DIR/app
  wget -qO $WORK_DIR/cloudflared ${GH_PROXY}https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$ARCH
  wget -O $WORK_DIR/nezha-agent.zip ${GH_PROXY}https://github.com/nezhahq/agent/releases/latest/download/nezha-agent_linux_$ARCH.zip
  unzip $WORK_DIR/nezha-agent.zip -d $WORK_DIR/
  rm -rf $WORK_DIR/nezha-agent.zip /tmp/dist /tmp/dashboard.zip

  # 根据参数生成哪吒服务端配置文件
  [ ! -d data ] && mkdir data
  cat > ${WORK_DIR}/data/config.yaml << EOF
Debug: false
HTTPPort: $WEB_PORT
Language: zh-CN
GRPCPort: $GRPC_PORT
GRPCHost: $ARGO_DOMAIN
ProxyGRPCPort: $GRPC_PROXY_PORT
TLS: true
Oauth2:
  Type: "github" #Oauth2 登录接入类型，github/gitlab/jihulab/gitee/gitea ## Argo-容器版本只支持 github
  Admin: "$GH_USER" #管理员列表，半角逗号隔开
  ClientID: "$GH_CLIENTID" # 在 ${GH_PROXY}https://github.com/settings/developers 创建，无需审核 Callback 填 http(s)://域名或IP/oauth2/callback
  ClientSecret: "$GH_CLIENTSECRET"
  Endpoint: "" # 如gitea自建需要设置 ## Argo-容器版本只支持 github
site:
  Brand: "Nezha Probe"
  Cookiename: "nezha-dashboard" #浏览器 Cookie 字段名，可不改
  Theme: "default"
EOF

  # 下载包含本地数据的 sqlite.db 文件
  wget -P ${WORK_DIR}/data/ ${GH_PROXY}https://github.com/fscarmen2/Argo-Nezha-Service-Container/raw/main/sqlite.db

  # SSH path 与 GH_CLIENTSECRET 一样
  echo root:"$GH_CLIENTSECRET" | chpasswd root
  sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g;s/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
  service ssh restart

  # 判断 ARGO_AUTH 为 json 还是 token
  # 如为 json 将生成 argo.json 和 argo.yml 文件
  if [[ "$ARGO_AUTH" =~ TunnelSecret ]]; then
    ARGO_RUN="cloudflared tunnel --edge-ip-version auto --config $WORK_DIR/argo.yml run"

    echo "$ARGO_AUTH" > $WORK_DIR/argo.json

    cat > $WORK_DIR/argo.yml << EOF
tunnel: $(cut -d '"' -f12 <<< "$ARGO_AUTH")
credentials-file: $WORK_DIR/argo.json
protocol: http2

ingress:
  - hostname: $ARGO_DOMAIN
    service: https://localhost:$GRPC_PROXY_PORT
    path: /proto.NezhaService/*
    originRequest:
      http2Origin: true
      noTLSVerify: true
  - hostname: $ARGO_DOMAIN
    service: ssh://localhost:22
    path: /$GH_CLIENTID/*
  - hostname: $ARGO_DOMAIN
    service: http://localhost:$WEB_PORT
  - service: http_status:404
EOF

  # 如为 token 时
  elif [[ "$ARGO_AUTH" =~ ^ey[A-Z0-9a-z=]{120,250}$ ]]; then
    ARGO_RUN="cloudflared tunnel --edge-ip-version auto --protocol http2 run --token ${ARGO_AUTH}"
  fi

  # 生成自签署SSL证书
  openssl genrsa -out $WORK_DIR/nezha.key 2048
  openssl req -new -subj "/CN=$ARGO_DOMAIN" -key $WORK_DIR/nezha.key -out $WORK_DIR/nezha.csr
  openssl x509 -req -days 36500 -in $WORK_DIR/nezha.csr -signkey $WORK_DIR/nezha.key -out $WORK_DIR/nezha.pem

  # 生成 backup.sh 文件的步骤1 - 设置环境变量
  cat > $WORK_DIR/backup.sh << EOF
#!/usr/bin/env bash

# backup.sh 传参 a 自动还原； 传参 m 手动还原； 传参 f 强制更新面板 app 文件及 cloudflared 文件，并备份数据至成备份库

GH_PROXY=$GH_PROXY
GH_PAT=$GH_PAT
GH_BACKUP_USER=$GH_BACKUP_USER
GH_EMAIL=$GH_EMAIL
GH_REPO=$GH_REPO
ARCH=$ARCH
WORK_DIR=$WORK_DIR
DAYS=5
IS_DOCKER=1

########
EOF

  # 生成 backup.sh 文件的步骤2 - 在线获取 template/bakcup.sh 模板生成完整 backup.sh 文件
  wget -qO- ${GH_PROXY}https://raw.githubusercontent.com/fscarmen2/Argo-Nezha-Service-Container/main/template/backup.sh | sed '1,/^########/d' >> $WORK_DIR/backup.sh

  if [[ -n "$GH_BACKUP_USER" && -n "$GH_EMAIL" && -n "$GH_REPO" && -n "$GH_PAT" ]]; then
    # 生成 restore.sh 文件的步骤1 - 设置环境变量
    cat > $WORK_DIR/restore.sh << EOF
#!/usr/bin/env bash

# restore.sh 传参 a 自动还原 README.md 记录的文件，当本地与远程记录文件一样时不还原； 传参 f 不管本地记录文件，强制还原成备份库里 README.md 记录的文件； 传参 dashboard-***.tar.gz 还原成备份库里的该文件；不带参数则要求选择备份库里的文件名

GH_PROXY=$GH_PROXY
GH_PAT=$GH_PAT
GH_BACKUP_USER=$GH_BACKUP_USER
GH_REPO=$GH_REPO
WORK_DIR=$WORK_DIR
TEMP_DIR=/tmp/restore_temp
NO_ACTION_FLAG=/tmp/flag
IS_DOCKER=1

########
EOF

    # 生成 restore.sh 文件的步骤2 - 在线获取 template/restore.sh 模板生成完整 restore.sh 文件
    wget -qO- ${GH_PROXY}https://raw.githubusercontent.com/fscarmen2/Argo-Nezha-Service-Container/main/template/restore.sh | sed '1,/^########/d' >> $WORK_DIR/restore.sh
  fi

  # 生成 renew.sh 文件的步骤1 - 设置环境变量
  cat > $WORK_DIR/renew.sh << EOF
#!/usr/bin/env bash

GH_PROXY=$GH_PROXY
WORK_DIR=/dashboard
TEMP_DIR=/tmp/renew

########
EOF

  # 生成 renew.sh 文件的步骤2 - 在线获取 template/renew.sh 模板生成完整 renew.sh 文件
  wget -qO- ${GH_PROXY}https://raw.githubusercontent.com/fscarmen2/Argo-Nezha-Service-Container/main/template/renew.sh | sed '1,/^########/d' >> $WORK_DIR/renew.sh

  # 生成定时任务: 1.每天北京时间 3:30:00 更新备份和还原文件，2.每天北京时间 4:00:00 备份一次，并重启 cron 服务； 3.每分钟自动检测在线备份文件里的内容
  [ -z "$NO_AUTO_RENEW" ] && [ -s $WORK_DIR/renew.sh ] && ! grep -q "$WORK_DIR/renew.sh" /etc/crontab && echo "30 3 * * * root bash $WORK_DIR/renew.sh" >> /etc/crontab
  [ -s $WORK_DIR/backup.sh ] && ! grep -q "$WORK_DIR/backup.sh" /etc/crontab && echo "0 4 * * * root bash $WORK_DIR/backup.sh a" >> /etc/crontab
  [ -s $WORK_DIR/restore.sh ] && ! grep -q "$WORK_DIR/restore.sh" /etc/crontab && echo "* * * * * root bash $WORK_DIR/restore.sh a" >> /etc/crontab
  service cron restart

  # 生成 supervisor 进程守护配置文件
  cat > /etc/supervisor/conf.d/damon.conf << EOF
[supervisord]
nodaemon=true
logfile=/dev/null
pidfile=/run/supervisord.pid

[program:grpcproxy]
command=$GRPC_PROXY_RUN
autostart=true
autorestart=true
stderr_logfile=/dev/null
stdout_logfile=/dev/null

[program:nezha]
command=$WORK_DIR/app
autostart=true
autorestart=true
stderr_logfile=/dev/null
stdout_logfile=/dev/null

[program:agent]
command=$WORK_DIR/nezha-agent -s localhost:$GRPC_PORT -p abcdefghijklmnopqr
autostart=true
autorestart=true
stderr_logfile=/dev/null
stdout_logfile=/dev/null

[program:argo]
command=$WORK_DIR/$ARGO_RUN
autostart=true
autorestart=true
stderr_logfile=/dev/null
stdout_logfile=/dev/null
EOF

  # 赋执行权给 sh 及所有应用
  chmod +x $WORK_DIR/{cloudflared,nezha-agent,*.sh}

fi

# 运行 supervisor 进程守护
supervisord -c /etc/supervisor/supervisord.conf
