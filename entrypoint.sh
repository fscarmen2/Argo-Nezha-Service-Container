#!/usr/bin/env bash

# 如参数不齐全，容器退出
[[ -z "$WEB_JSON" || -z "$SERVER_JSON" ]] && echo " Variables of WEB_JSON and SERVER_JSON Variables are required. " && exit 1

printf "nameserver 127.0.0.11\nnameserver 8.8.4.4\nnameserver 223.5.5.5\n" > /etc/resolv.conf

# 根据参数生成哪吒服务端配置文件
[ ! -d data ] && mkdir data
cat > ./data/config.yaml << EOF
debug: false
site:
  brand: VPS Probe
  cookiename: nezha-dashboard
  theme: default
  customcode: "<script>\r\nwindow.onload = function(){\r\nvar avatar=document.querySelector(\".item
    img\")\r\nvar footer=document.querySelector(\"div.is-size-7\")\r\nfooter.innerHTML=\"Powered
    by $ADMIN\"\r\nfooter.style.visibility=\"visible\"\r\navatar.src=\"https://raw.githubusercontent.com/Orz-3/mini/master/Color/Global.png\"\r\navatar.style.visibility=\"visible\"\r\n}\r\n</script>"
  viewpassword: ""
oauth2:
  type: github
  admin: $ADMIN
  clientid: $CLIENTID
  clientsecret: $CLIENTSECRET
httpport: 80
grpcport: 5555
grpchost: $GRPCHOST
proxygrpcport: 0
tls: false
enableipchangenotification: false
enableplainipinnotification: false
cover: 0
ignoredipnotification: ""
ignoredipnotificationserverids: {}
EOF

# 需要 argo ssh 的，设置变量 SSH_JSON 和 SH_PASSWORD
if [ -n "$SSH_JSON" ]; then
  SSH_PASSWORD=${SSH_PASSWORD:-password}
  echo root:"$SSH_PASSWORD" | chpasswd root
  sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g;s/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
  service ssh restart
fi

# 根据 Json 生成相应隧道
JSON=("$WEB_JSON" "$SERVER_JSON" "$SSH_JSON")
FILE=("web" "server" "ssh")
for ((i=0; i<${#JSON[@]}; i++)); do
  [ -n "${JSON[i]}" ] && echo "${JSON[i]}" > ${FILE[i]}.json &&
  echo -e "tunnel: $(cut -d\" -f12 <<< "${JSON[i]}")\ncredentials-file: /dashboard/${FILE[i]}.json" > ${FILE[i]}.yml
done

# 生成 supervisor 进程守护配置文件
cat > /etc/supervisor/conf.d/supervisor.conf << EOF
[supervisord]
nodaemon=true
logfile=/var/log/supervisord.log
pidfile=/run/supervisord.pid

[program:nezha]
command=/dashboard/app
autostart=true
autorestart=true
stderr_logfile=/var/log/nezha.err.log
stdout_logfile=/var/log/nezha.out.log
user=root

[program:web_argo]
command=cloudflared tunnel --edge-ip-version auto --config /dashboard/web.yml --url http://localhost:80 run
autostart=true
autorestart=true
stderr_logfile=/var/log/web_argo.err.log
stdout_logfile=/var/log/web_argo.out.log
user=root

[program:server_argo]
command=cloudflared tunnel --edge-ip-version auto --config /dashboard/server.yml --url tcp://localhost:5555 run
autostart=true
autorestart=true
stderr_logfile=/var/log/server_argo.err.log
stdout_logfile=/var/log/server_argo.out.log
user=root
EOF

[ -n "$SSH_JSON" ] && cat >> /etc/supervisor/conf.d/supervisor.conf << EOF

[program:ssh_argo]
command=cloudflared tunnel --edge-ip-version auto --config /dashboard/ssh.yml --url ssh://localhost:22 run
autostart=true
autorestart=true
stderr_logfile=/var/log/ssh_argo.err.log
stdout_logfile=/var/log/ssh_argo.out.log
user=root
EOF

# 运行 supervisor 进程守护
supervisord -c /etc/supervisor/conf.d/supervisor.conf
