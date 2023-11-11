#!/usr/bin/env bash

# 如不分离备份的 github 账户，默认与哪吒登陆的 github 账户一致
GH_BACKUP_USER=${GH_BACKUP_USER:-$GH_USER}
WORK_DIR=/dashboard

error() { echo -e "\033[31m\033[01m$*\033[0m" && exit 1; } # 红色
info() { echo -e "\033[32m\033[01m$*\033[0m"; }   # 绿色
hint() { echo -e "\033[33m\033[01m$*\033[0m"; }   # 黄色

# 如参数不齐全，容器退出，另外处理某些环境变量填错后的处理
[[ -z "$GH_USER" || -z "$GH_CLIENTID" || -z "$GH_CLIENTSECRET" || -z "$ARGO_AUTH" || -z "$ARGO_DOMAIN" ]] && error " There are variables that are not set. "
[[ "$ARGO_AUTH" =~ TunnelSecret ]] && grep -qv '"' <<< "$ARGO_AUTH" && ARGO_AUTH=$(sed 's@{@{"@g;s@[,:]@"\0"@g;s@}@"}@g' <<< "$ARGO_AUTH")  # Json 时，没有了"的处理
[[ "$ARGO_AUTH" =~ ey[A-Z0-9a-z=]{120,250}$ ]] && ARGO_AUTH=$(awk '{print $NF}' <<< "$ARGO_AUTH") # Token 复制全部，只取最后的 ey 开始的
[ -n "$GH_REPO" ] && grep -q '/' <<< "$GH_REPO" && GH_REPO=$(awk -F '/' '{print $NF}' <<< "$GH_REPO")  # 填了项目全路径的处理

echo -e "nameserver 127.0.0.11\nnameserver 8.8.4.4\nnameserver 223.5.5.5\nnameserver 2001:4860:4860::8844\nnameserver 2400:3200::1\n" > /etc/resolv.conf

# 下载需要的应用
wget -c https://github.com/fscarmen2/Argo-Nezha-Service-Container/releases/download/grpcwebproxy/grpcwebproxy_linux_$(uname -m | sed "s#x86_64#amd64#; s#aarch64#arm64#").tar.gz -qO- | tar xz -C $WORK_DIR
wget -qO $WORK_DIR/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$(uname -m | sed "s#x86_64#amd64#; s#aarch64#arm64#")
wget -O $WORK_DIR/nezha-agent.zip https://github.com/nezhahq/agent/releases/latest/download/nezha-agent_linux_$(uname -m | sed "s#x86_64#amd64#; s#aarch64#arm64#").zip
unzip $WORK_DIR/nezha-agent.zip -d $WORK_DIR/

rm -f $WORK_DIR/nezha-agent.zip

# 根据参数生成哪吒服务端配置文件
[ ! -d data ] && mkdir data
cat > ${WORK_DIR}/data/config.yaml << EOF
debug: false
httpport: 80
language: zh-CN
grpcport: 5555
grpchost: $ARGO_DOMAIN
proxygrpcport: 443
tls: true
oauth2:
  type: "github" #Oauth2 登录接入类型，github/gitlab/jihulab/gitee/gitea ## Argo-容器版本只支持 github
  admin: "$GH_USER" #管理员列表，半角逗号隔开
  clientid: "$GH_CLIENTID" # 在 https://github.com/settings/developers 创建，无需审核 Callback 填 http(s)://域名或IP/oauth2/callback
  clientsecret: "$GH_CLIENTSECRET"
  endpoint: "" # 如gitea自建需要设置 ## Argo-容器版本只支持 github
site:
  brand: "Nezha Probe"
  cookiename: "nezha-dashboard" #浏览器 Cookie 字段名，可不改
  theme: "default"
EOF

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
    service: https://localhost:443
    path: /proto.NezhaService/*
    originRequest:
      http2Origin: true
      noTLSVerify: true
  - hostname: $ARGO_DOMAIN
    service: ssh://localhost:22
    path: /$GH_CLIENTID/*
  - hostname: $ARGO_DOMAIN
    service: http://localhost:80
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

# 生成定时备份数据库脚本，定时任务，删除 5 天前的备份
  cat > $WORK_DIR/backup.sh << EOF
#!/usr/bin/env bash

GH_PAT=$GH_PAT
GH_BACKUP_USER=$GH_BACKUP_USER
GH_EMAIL=$GH_EMAIL
GH_REPO=$GH_REPO
WORK_DIR=$WORK_DIR

warning() { echo -e "\033[31m\033[01m\$*\033[0m"; }  # 红色
error() { echo -e "\033[31m\033[01m\$*\033[0m" && exit 1; } # 红色
info() { echo -e "\033[32m\033[01m\$*\033[0m"; }   # 绿色
hint() { echo -e "\033[33m\033[01m\$*\033[0m"; }   # 黄色

# 手自动标志
[ "\$1" = 'a' ] && WAY=Scheduled || WAY=Manualed
[ "\$1" = 'f' ] && WAY=Manualed && FORCE_UPDATE=true

# 检查更新面板主程序 app 及 cloudflared
cd \$WORK_DIR
DASHBOARD_NOW=\$(./app -v)
DASHBOARD_LATEST=\$(wget -qO- "https://api.github.com/repos/applexad/nezha-binary-build/releases/latest" | awk -F '"' '/"tag_name"/{print \$4}')
[[ "\$DASHBOARD_LATEST" =~ ^v([0-9]{1,3}\.){2}[0-9]{1,3}\$ && "\$DASHBOARD_NOW" != "\$DASHBOARD_LATEST" ]] && DASHBOARD_UPDATE=true

CLOUDFLARED_NOW=\$(./cloudflared -v | awk '{for (i=0; i<NF; i++) if (\$i=="version") {print \$(i+1)}}')
CLOUDFLARED_LATEST=\$(wget -qO- https://api.github.com/repos/cloudflare/cloudflared/releases/latest | awk -F '"' '/tag_name/{print \$4}')
[[ "\$CLOUDFLARED_LATEST" =~ ^20[0-9]{2}\.[0-9]{1,2}\.[0-9]+\$ && "\$CLOUDFLARED_NOW" != "\$CLOUDFLARED_LATEST" ]] && CLOUDFLARED_UPDATE=true

# 检测是否有设置备份数据
if [[ -n "\$GH_REPO" && -n "\$GH_BACKUP_USER" && -n "\$GH_EMAIL" && -n "\$GH_PAT" ]]; then
  IS_PRIVATE="\$(wget -qO- --header="Authorization: token \$GH_PAT" https://api.github.com/repos/\$GH_BACKUP_USER/\$GH_REPO | sed -n '/"private":/s/.*:[ ]*\([^,]*\),/\1/gp')"
  if [ "\$?" != 0 ]; then
    warning "\n Could not connect to Github. Stop backup. \n"
  elif [ "\$IS_PRIVATE" != true ]; then
    warning "\n This is not exist nor a private repository. \n"
  else
    IS_BACKUP=true
  fi
fi

# 分步骤处理
if [[ "\${DASHBOARD_UPDATE}\${CLOUDFLARED_UPDATE}\${IS_BACKUP}\${FORCE_UPDATE}" =~ true ]]; then
  # 停掉面板才能备份
  hint "\n\$(supervisorctl stop agent nezha grpcwebproxy)\n"
  sleep 2
  if [ "\$(supervisorctl status nezha | awk '{print \$2}')" = 'STOPPED' ]; then
    # 更新面板和 resource
    if [[ "\${DASHBOARD_UPDATE}\${FORCE_UPDATE}" =~ 'true' ]]; then
      hint "\n Renew dashboard app to \$DASHBOARD_LATEST \n"
      wget -O \$WORK_DIR/app https://github.com/applexad/nezha-binary-build/releases/latest/download/dashboard-linux-\$(uname -m | sed "s#x86_64#amd64#; s#aarch64#arm64#")
      wget -c https://github.com/applexad/nezha-binary-build/releases/latest/download/resource.tar.gz -qO- | tar xvz -C \$WORK_DIR
    fi

    # 更新 cloudflared
    if [[ "\${CLOUDFLARED_UPDATE}\${FORCE_UPDATE}" =~ 'true' ]]; then
      hint "\n Renew Cloudflared to \$CLOUDFLARED_LATEST \n"
      wget -O \$WORK_DIR/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-\$ARCH && chmod +x \$WORK_DIR/cloudflared
    fi

    # 克隆备份仓库，压缩备份文件，上传更新
    if [ "\$IS_BACKUP" = 'true' ]; then
      # 克隆现有备份库
      [ -d /tmp/\$GH_REPO ] && rm -rf /tmp/\$GH_REPO
      git clone https://\$GH_PAT@github.com/\$GH_BACKUP_USER/\$GH_REPO.git --depth 1 --quiet /tmp/\$GH_REPO

      # 压缩备份数据，只备份 data/ 目录下的 config.yaml 和 sqlite.db； resource/ 目录下名字有 custom 的自定义主题文件夹
      TIME=\$(date "+%Y-%m-%d-%H:%M:%S")
      echo "↓↓↓↓↓↓↓↓↓↓ dashboard-\$TIME.tar.gz list ↓↓↓↓↓↓↓↓↓↓"
      find resource/ -type d -name "*custom*" | tar czvf /tmp/\$GH_REPO/dashboard-\$TIME.tar.gz -T- data/
      echo -e "↑↑↑↑↑↑↑↑↑↑ dashboard-\$TIME.tar.gz list ↑↑↑↑↑↑↑↑↑↑\n\n"

      # 更新备份 Github 库
      cd /tmp/\$GH_REPO
      [ -e ./.git/index.lock ] && rm -f ./.git/index.lock
      echo "dashboard-\$TIME.tar.gz" > README.md
      find ./ -name '*.gz' | sort | head -n -5 | xargs rm -f
      git config --global user.name \$GH_BACKUP_USER
      git config --global user.email \$GH_EMAIL
      git checkout --orphan tmp_work
      git add .
      git commit -m "\$WAY at \$TIME ."
      git push -f -u origin HEAD:main --quiet
      IS_BACKUP="\$?"
      cd ..
      rm -rf \$GH_REPO
      [ "\$IS_BACKUP" = 0 ] && echo "dashboard-\$TIME.tar.gz" > \$WORK_DIR/dbfile && info "\n Succeed to upload the backup files dashboard-\$TIME.tar.gz to Github.\n" || hint "\n Failed to upload the backup files dashboard-\$TIME.tar.gz to Github.\n"
      hint "\n Start Nezha-dashboard \n"
    fi
  fi
  hint "\n\$(supervisorctl start agent nezha grpcwebproxy)\n"; sleep 2
fi

[ \$(supervisorctl status all | grep -c "RUNNING") = \$(grep -c '\[program:.*\]' /etc/supervisor/conf.d/damon.conf) ] && info "\n Done! \n" || error "\n Fail! \n"
EOF

if [[ -n "$GH_BACKUP_USER" && -n "$GH_EMAIL" && -n "$GH_REPO" && -n "$GH_PAT" ]]; then
  # 生成还原数据脚本
  cat > $WORK_DIR/restore.sh << EOF
#!/usr/bin/env bash

# restore.sh 传参 a 自动还原 README.md 记录的文件，当本地与远程记录文件一样时不还原； 传参 f 不管本地记录文件，强制还原成备份库里 README.md 记录的文件； 传参 dashboard-***.tar.gz 还原成备份库里的该文件；不带参数则要求选择备份库里的文件名

GH_PAT=$GH_PAT
GH_BACKUP_USER=$GH_BACKUP_USER
GH_REPO=$GH_REPO
WORK_DIR=$WORK_DIR
TEMP_DIR=/tmp/restore_temp

trap "rm -rf \$TEMP_DIR; echo -e '\n' ;exit 1" INT QUIT TERM EXIT

mkdir -p \$TEMP_DIR

warning() { echo -e "\033[31m\033[01m\$*\033[0m"; }  # 红色
error() { echo -e "\033[31m\033[01m\$*\033[0m" && exit 1; } # 红色
info() { echo -e "\033[32m\033[01m\$*\033[0m"; }   # 绿色
hint() { echo -e "\033[33m\033[01m\$*\033[0m"; }   # 黄色

ONLINE="\$(wget -qO- --header="Authorization: token \$GH_PAT" "https://raw.githubusercontent.com/\$GH_BACKUP_USER/\$GH_REPO/main/README.md" | sed "/^$/d" | head -n 1)"

# 读取面板现配置信息
CONFIG_HTTPPORT=\$(grep '^httpport:' \$WORK_DIR/data/config.yaml)
CONFIG_LANGUAGE=\$(grep '^language:' \$WORK_DIR/data/config.yaml)
CONFIG_GRPCPORT=\$(grep '^grpcport:' \$WORK_DIR/data/config.yaml)
CONFIG_GRPCHOST=\$(grep '^grpchost:' \$WORK_DIR/data/config.yaml)
CONFIG_PROXYGRPCPORT=\$(grep '^proxygrpcport:' \$WORK_DIR/data/config.yaml)
CONFIG_TYPE=\$(sed -n '/type:/s/^[ ]\+//gp' \$WORK_DIR/data/config.yaml)
CONFIG_ADMIN=\$(sed -n '/admin:/s/^[ ]\+//gp' \$WORK_DIR/data/config.yaml)
CONFIG_CLIENTID=\$(sed -n '/clientid:/s/^[ ]\+//gp' \$WORK_DIR/data/config.yaml)
CONFIG_CLIENTSECRET=\$(sed -n '/clientsecret:/s/^[ ]\+//gp' \$WORK_DIR/data/config.yaml)

# 如 dbfile 不为空，即不是首次安装，记录当前面板的主题等信息
[ -s \$WORK_DIR/dbfile ] && CONFIG_BRAND=\$(sed -n '/brand:/s/^[ ]\+//gp' \$WORK_DIR/data/config.yaml) &&
CONFIG_COOKIENAME=\$(sed -n '/cookiename:/s/^[ ]\+//gp' \$WORK_DIR/data/config.yaml) &&
CONFIG_THEME=\$(sed -n '/theme:/s/^[ ]\+//gp' \$WORK_DIR/data/config.yaml)

if [ "\$1" = a ]; then
  [ "\$ONLINE" = "\$(cat \$WORK_DIR/dbfile)" ] && exit
  [[ "\$ONLINE" =~ tar\.gz$ && "\$ONLINE" != "\$(cat \$WORK_DIR/dbfile)" ]] && FILE="\$ONLINE" || exit
elif [ "\$1" = f ]; then
  [[ "\$ONLINE" =~ tar\.gz$ ]] && FILE="\$ONLINE" || exit
elif [[ "\$1" =~ tar\.gz$ ]]; then
  [[ "\$FILE" =~ http.*/.*tar.gz ]] && FILE=\$(awk -F '/' '{print \$NF}' <<< \$FILE) || FILE="\$1"
elif [ -z "\$1" ]; then
  BACKUP_FILE_LIST=(\$(wget -qO- --header="Authorization: token \$GH_PAT" https://api.github.com/repos/\$GH_BACKUP_USER/\$GH_REPO/contents/ | awk -F '"' '/"path".*tar.gz/{print \$4}' | sort -r))
  until [[ "\$CHOOSE" =~ ^[1-\${#BACKUP_FILE_LIST[@]}]$ ]]; do
    for i in \${!BACKUP_FILE_LIST[@]}; do echo " \$[i+1]. \${BACKUP_FILE_LIST[i]} "; done
    echo ""
    [ -z "\$FILE" ] && read -rp " Please choose the backup file [1-\${#BACKUP_FILE_LIST[@]}]: " CHOOSE
    [[ ! "\$CHOOSE" =~ ^[1-\${#BACKUP_FILE_LIST[@]}]$ ]] && echo -e "\n Error input!" && sleep 1
    ((j++)) && [ \$j -ge 5 ] && error "\n The choose has failed more than 5 times and the script exits. \n"
  done
  FILE=\${BACKUP_FILE_LIST[\$((CHOOSE-1))]}
fi

DOWNLOAD_URL=https://raw.githubusercontent.com/\$GH_BACKUP_USER/\$GH_REPO/main/\$FILE
wget --header="Authorization: token \$GH_PAT" --header='Accept: application/vnd.github.v3.raw' -O \$TEMP_DIR/backup.tar.gz "\$DOWNLOAD_URL"

if [ -e \$TEMP_DIR/backup.tar.gz ]; then
  hint "\n\$(supervisorctl stop agent nezha grpcwebproxy)\n"

  # 容器版的备份旧方案是 /dashboard 文件夹，新方案是备份工作目录 < WORK_DIR > 下的文件，此判断用于根据压缩包里的目录架构判断到哪个目录下解压，以兼容新旧备份方案
  FILE_LIST=\$(tar tzf \$TEMP_DIR/backup.tar.gz)
  FILE_PATH=\$(sed -n 's#\(.*/\)data/sqlite\.db.*#\1#gp' <<< "\$FILE_LIST")  

  # 判断备份文件里是否有用户自定义主题，如有则一并解压到临时文件夹
  CUSTOM_PATH=(\$(sed -n "/-custom/s#\$FILE_PATH\(.*-custom\)/.*#\1#gp" <<< "\$FILE_LIST" | sort -u))
  [ \${#CUSTOM_PATH[@]} -gt 0 ] && CUSTOM_FULL_PATH=(\$(for k in \${CUSTOM_PATH[@]}; do echo \${FILE_PATH}\${k}; done))
  echo "↓↓↓↓↓↓↓↓↓↓ Restore-file list ↓↓↓↓↓↓↓↓↓↓"
  tar xzvf \$TEMP_DIR/backup.tar.gz -C \$TEMP_DIR \${CUSTOM_FULL_PATH[@]} \${FILE_PATH}data
  echo -e "↑↑↑↑↑↑↑↑↑↑ Restore-file list ↑↑↑↑↑↑↑↑↑↑\n\n"

  # 还原面板配置的最新信息
  sed -i "s@httpport:.*@\$CONFIG_HTTPPORT@; s@language:.*@\$CONFIG_LANGUAGE@; s@^grpcport:.*@\$CONFIG_GRPCPORT@; s@grpchost:.*@\$CONFIG_GRPCHOST@; s@proxygrpcport:.*@\$CONFIG_PROXYGRPCPORT@; s@type:.*@\$CONFIG_TYPE@; s@admin:.*@\$CONFIG_ADMIN@; s@clientid:.*@\$CONFIG_CLIENTID@; s@clientsecret:.*@\$CONFIG_CLIENTSECRET@" \${TEMP_DIR}/\${FILE_PATH}data/config.yaml

  # 逻辑是安装首次使用备份文件里的主题信息，之后使用本地最新的主题信息
  [[ -n "\$CONFIG_BRAND && -n "\$CONFIG_COOKIENAME && -n "\$CONFIG_THEME" ]] &&
  sed -i "s@brand:.*@\$CONFIG_BRAND@; s@cookiename:.*@\$CONFIG_COOKIENAME@; s@theme:.*@\$CONFIG_THEME@" \${TEMP_DIR}/\${FILE_PATH}data/config.yaml

  # 复制临时文件到正式的工作文件夹
  cp -f \${TEMP_DIR}/\${FILE_PATH}data/* \${WORK_DIR}/data/
  [ -d \${TEMP_DIR}/\${FILE_PATH}resource ] && cp -rf \${TEMP_DIR}/\${FILE_PATH}resource \${WORK_DIR}
  rm -rf \${TEMP_DIR}

  # 在本地记录还原文件名
  echo "\$ONLINE" > \$WORK_DIR/dbfile
  rm -f \$TEMP_DIR/backup.tar.gz
  hint "\n\$(supervisorctl start agent nezha grpcwebproxy)\n"; sleep 2
fi

[ \$(supervisorctl status all | grep -c "RUNNING") = \$(grep -c '\[program:.*\]' /etc/supervisor/conf.d/damon.conf) ] && info "\n Done! \n" || error "\n Fail! \n"
EOF

  # 生成定时任务，每天北京时间 4:00:00 备份一次，并重启 cron 服务; 每分钟自动检测在线备份文件里的内容
  grep -q "$WORK_DIR/backup.sh" /etc/crontab || echo "0 4 * * * root bash $WORK_DIR/backup.sh a" >> /etc/crontab
  grep -q "$WORK_DIR/restore.sh" /etc/crontab || echo "* * * * * root bash $WORK_DIR/restore.sh a" >> /etc/crontab
  service cron restart
fi

# 生成 supervisor 进程守护配置文件
cat > /etc/supervisor/conf.d/damon.conf << EOF
[supervisord]
nodaemon=true
logfile=/dev/null
pidfile=/run/supervisord.pid

[program:grpcwebproxy]
command=$WORK_DIR/grpcwebproxy --server_tls_cert_file=$WORK_DIR/nezha.pem --server_tls_key_file=$WORK_DIR/nezha.key --server_http_tls_port=443 --backend_addr=localhost:5555 --backend_tls_noverify --server_http_max_read_timeout=300s --server_http_max_write_timeout=300s
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
command=$WORK_DIR/nezha-agent -s localhost:5555 -p abcdefghijklmnopqr
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
chmod +x $WORK_DIR/{grpcwebproxy,cloudflared,nezha-agent,*.sh}

# 运行 supervisor 进程守护
supervisord -c /etc/supervisor/supervisord.conf