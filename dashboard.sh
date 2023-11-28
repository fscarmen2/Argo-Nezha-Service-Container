#!/usr/bin/env bash

# 各变量默认值
GH_PROXY=https://mirror.ghproxy.com
WORK_DIR='/opt/nezha/dashboard'
TEMP_DIR='/tmp/nezha'
START_PORT='5000'
NEED_PORTS=3 # web , gRPC , gRPC proxy

trap "rm -rf $TEMP_DIR; echo -e '\n' ;exit 1" INT QUIT TERM EXIT

mkdir -p $TEMP_DIR

E[0]="Language:\n 1. English (default) \n 2. 简体中文"
C[0]="${E[0]}"
E[1]="Nezha Dashboard for VPS (https://github.com/fscarmen2/Argo-Nezha-Service-Containe).\n  - Goodbye docker!\n  - Goodbye port mapping!\n  - Goodbye IPv4/IPv6 Compatibility!"
C[1]="哪吒面板 VPS 特供版 (https://github.com/fscarmen2/Argo-Nezha-Service-Containe)\n  - 告别 Docker！\n  - 告别端口映射！\n  - 告别 IPv4/IPv6 兼容性！"
E[2]="Curren architecture \$(uname -m) is not supported. Feedback: [https://github.com/fscarmen2/Argo-Nezha-Service-Container/issues]"
C[2]="当前架构 \$(uname -m) 暂不支持,问题反馈:[https://github.com/fscarmen2/Argo-Nezha-Service-Container/issues]"
E[3]="Input errors up to 5 times.The script is aborted."
C[3]="输入错误达5次,脚本退出"
E[4]="The script must be run as root, you can enter sudo -i and then download and run again. Feedback:[https://github.com/fscarmen2/Argo-Nezha-Service-Container/issues]"
C[4]="必须以root方式运行脚本，可以输入 sudo -i 后重新下载运行，问题反馈:[https://github.com/fscarmen2/Argo-Nezha-Service-Container/issues]"
E[5]="The script supports Debian, Ubuntu, CentOS, Alpine or Arch systems only. Feedback: [https://github.com/fscarmen2/Argo-Nezha-Service-Container/issues]"
C[5]="本脚本只支持 Debian、Ubuntu、CentOS、Alpine 或 Arch 系统,问题反馈:[https://github.com/fscarmen2/Argo-Nezha-Service-Container/issues]"
E[6]="Curren operating system is \$SYS.\\\n The system lower than \$SYSTEM \${MAJOR[int]} is not supported. Feedback: [https://github.com/fscarmen2/Argo-Nezha-Service-Container/issues]"
C[6]="当前操作是 \$SYS\\\n 不支持 \$SYSTEM \${MAJOR[int]} 以下系统,问题反馈:[https://github.com/fscarmen2/Argo-Nezha-Service-Container/issues]"
E[7]="Install dependence-list:"
C[7]="安装依赖列表:"
E[8]="All dependencies already exist and do not need to be installed additionally."
C[8]="所有依赖已存在，不需要额外安装"
E[9]="Please enter Github login name as the administrator:"
C[9]="请输入 Github 登录名作为管理员:"
E[10]="About the GitHub Oauth2 application: create it at https://github.com/settings/developers, no review required, and fill in the http(s)://domain_or_IP/oauth2/callback \n Please enter the Client ID of the Oauth2 application:"
C[10]="关于 GitHub Oauth2 应用：在 https://github.com/settings/developers 创建，无需审核，Callback 填 http(s)://域名或IP/oauth2/callback \n 请输入 Oauth2 应用的 Client ID:"
E[11]="Please enter the Client Secret of the Oauth2 application:"
C[11]="请输入 Oauth2 应用的 Client Secret:"
E[12]="Please enter the Argo Json or Token (You can easily get the json at: https://fscarmen.cloudflare.now.cc):"
C[12]="请输入 Argo Json 或者 Token (用户通过以下网站轻松获取 json: https://fscarmen.cloudflare.now.cc):"
E[13]="Please enter the Argo domain name:"
C[13]="请输入 Argo 域名:"
E[14]="If you need to back up your database to Github regularly, please enter the name of your private Github repository, otherwise leave it blank:"
C[14]="如需要定时把数据库备份到 Github，请输入 Github 私库名，否则请留空:"
E[15]="Please enter the Github username for the database \(default \$GH_USER\):"
C[15]="请输入数据库的 Github 用户名 \(默认 \$GH_USER\):"
E[16]="Please enter the Github Email for the database:"
C[16]="请输入数据库的 Github Email:"
E[17]="Please enter a Github PAT:"
C[17]="请输入 Github PAT:"
E[18]="There are variables that are not set. Installation aborted. Feedback: [https://github.com/fscarmen2/Argo-Nezha-Service-Container/issues]"
C[18]="参数不齐，安装中止，问题反馈:[https://github.com/fscarmen2/Argo-Nezha-Service-Container/issues]"
E[19]="Exit"
C[19]="退出"
E[20]="Close Nezha dashboard"
C[20]="关闭哪吒面板"
E[21]="Open Nezha dashboard"
C[21]="开启哪吒面板"
E[22]="Argo authentication message does not match the rules, neither Token nor Json, script exits. Feedback:[https://github.com/fscarmen2/Argo-Nezha-Service-Container/issues]"
C[22]="Argo 认证信息不符合规则，既不是 Token，也是不是 Json，脚本退出，问题反馈:[https://github.com/fscarmen2/Argo-Nezha-Service-Container/issues]"
E[23]="Please enter the correct number"
C[23]="请输入正确数字"
E[24]="Choose:"
C[24]="请选择:"
E[25]="Curren architecture \$(uname -m) is not supported. Feedback: [https://github.com/fscarmen2/Argo-Nezha-Service-Container/issues]"
C[25]="当前架构 \$(uname -m) 暂不支持,问题反馈:[https://github.com/fscarmen2/Argo-Nezha-Service-Container/issues]"
E[26]="Not install"
C[26]="未安装"
E[27]="close"
C[27]="关闭"
E[28]="open"
C[28]="开启"
E[29]="Uninstall Nezha dashboard"
C[29]="卸载哪吒面板"
E[30]="Install fscarmen's VPS with Argo version (https://github.com/fscarmen2/Argo-Nezha-Service-Container)"
C[30]="安装 fscarmen 的 VPS argo 带远程备份版 (https://github.com/fscarmen2/Argo-Nezha-Service-Container)"
E[31]="successful"
C[31]="成功"
E[32]="failed"
C[32]="失败"
E[33]="Could not find \$NEED_PORTS free ports, script exits. Feedback:[https://github.com/fscarmen2/Argo-Nezha-Service-Container/issues]"
C[33]="找不到 \$NEED_PORTS 个可用端口，脚本退出，问题反馈:[https://github.com/fscarmen2/Argo-Nezha-Service-Container/issues]"
E[34]="Important!!! Please turn on gRPC at the Network of the relevant Cloudflare domain, otherwise the client data will not work! See the tutorial for details: [https://github.com/fscarmen2/Argo-Nezha-Service-Container]"
C[34]="重要!!! 请到 Cloudflare 相关域名的 Network 处打开 gRPC 功能，否则客户端数据不通!具体可参照教程: [https://github.com/fscarmen2/Argo-Nezha-Service-Container]"
E[35]="Please add two Public hostnames to Cloudnflare Tunnel: \\\n 1. ------------------------ \\\n Public hostname: \$ARGO_DOMAIN \\\n Path: proto.NezhaService \\\n Type: HTTPS \\\n URL: localhost:\$GRPC_PROXY_PORT \\\n Additional application settings ---\> TLS: Enable [No TLS Verify] and [HTTP2 connection] \\\n\\\n 2. ------------------------ \\\n Public hostname: \$ARGO_DOMAIN \\\n Type: HTTP \\\n URL: localhost:\$WEB_PORT"
C[35]="请在 Cloudnflare Tunnel 里增加两个 Public hostnames: \\\n 1. ------------------------ \\\n Public hostname: \$ARGO_DOMAIN \\\n Path: proto.NezhaService \\\n Type: HTTPS \\\n URL: localhost:\$GRPC_PROXY_PORT \\\n Additional application settings ---\> TLS: 开启 [No TLS Verify] 和 [HTTP2 connection] 这两处功能 \\\n\\\n 2. ------------------------ \\\n Public hostname: \$ARGO_DOMAIN \\\n Type: HTTP \\\n URL: localhost:\$WEB_PORT"
E[36]="Install applexad's VPS version (modified from official version) (https://github.com/applexad/nezhascript)"
C[36]="安装 applexad 的官方修改 VPS 版 (https://github.com/applexad/nezhascript)"
E[37]="Install Nezha's official docker version (https://github.com/naiba/nezha)"
C[37]="安装哪吒官方容器版 (https://github.com/naiba/nezha)"
E[38]="Downloading. Please wait a minute."
C[38]="下载中, 请稍等"
E[39]="Downloading the \${FAILED[*]} failed. Installation aborted. Feedback: [https://github.com/fscarmen2/Argo-Nezha-Service-Container/issues]"
C[39]="下载 \${FAILED[*]} 失败，安装中止，问题反馈:[https://github.com/fscarmen2/Argo-Nezha-Service-Container/issues]"

# 自定义字体彩色，read 函数
warning() { echo -e "\033[31m\033[01m$*\033[0m"; }  # 红色
error() { echo -e "\033[31m\033[01m$*\033[0m" && exit 1; } # 红色
info() { echo -e "\033[32m\033[01m$*\033[0m"; }   # 绿色
hint() { echo -e "\033[33m\033[01m$*\033[0m"; }   # 黄色
reading() { read -rp "$(info "$1")" "$2"; }
text() { grep -q '\$' <<< "${E[$*]}" && eval echo "\$(eval echo "\${${L}[$*]}")" || eval echo "\${${L}[$*]}"; }

# 选择中英语言
select_language() {
  if [ -z "$L" ]; then
    case $(cat $WORK_DIR/language 2>&1) in
      E ) L=E ;;
      C ) L=C ;;
      * ) [ -z "$L" ] && L=E && hint "\n $(text 0) \n" && reading " $(text 24) " LANGUAGE
      [ "$LANGUAGE" = 2 ] && L=C ;;
    esac
  fi
}

check_root() {
  [ "$(id -u)" != 0 ] && error "\n $(text 4) \n"
}

check_arch() {
  # 判断处理器架构
  case $(uname -m) in
    aarch64|arm64 )
      ARCH=arm64
      [ "$SYSTEM" = 'Alpine' ] && DASHBOARD_ARCH=musl-linux-arm64 || DASHBOARD_ARCH=linux-arm64
      ;;
    x86_64|amd64 )
      ARCH=amd64
      [ "$SYSTEM" = 'Alpine' ] && DASHBOARD_ARCH=musl-linux-amd64 || DASHBOARD_ARCH=linux-amd64
      ;;
    * ) error " $(text 25) "
  esac
}

# 检查可用 port 函数，要求三个
check_port() {
  until [ "$START_PORT" -gt 65530 ]; do
    if [ "$SYSTEM" = 'Alpine' ]; then
      netstat -an | awk '/:[0-9]+/{print $4}' | awk -F ":" '{print $NF}' | grep -q $START_PORT || FREE_PORT+=("$START_PORT")
    else
      lsof -i:$START_PORT >/dev/null 2>&1 || FREE_PORT+=("$START_PORT")
    fi
    [ "${#FREE_PORT[@]}" = $NEED_PORTS ] && break
    ((START_PORT++))
  done

  if  [ "${#FREE_PORT[@]}" = $NEED_PORTS ]; then
    GRPC_PROXY_PORT=${FREE_PORT[0]}
    WEB_PORT=${FREE_PORT[1]}
    GRPC_PORT=${FREE_PORT[2]}
  else
    error "\n $(text 33) \n"
  fi
}

# 查安装及运行状态，下标0: argo，下标1: app， 状态码: 0 未安装， 1 已安装未运行， 2 运行中
check_install() {
  STATUS=$(text 26) && [ -s /etc/systemd/system/nezha-dashboard.service ] && STATUS=$(text 27) && [ "$(systemctl is-active nezha-dashboard)" = 'active' ] && STATUS=$(text 28)

  if [ "$STATUS" = "$(text 26)" ]; then
    { wget -c ${GH_PROXY}https://github.com/applexad/nezha-binary-build/releases/latest/download/resource.tar.gz -qO- | tar xz -C $TEMP_DIR >/dev/null 2>&1; }&
    { wget -qO $TEMP_DIR/cloudflared ${GH_PROXY}https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$ARCH >/dev/null 2>&1 && chmod +x $TEMP_DIR/cloudflared >/dev/null 2>&1; }&
    { wget -c ${GH_PROXY}https://github.com/fscarmen2/Argo-Nezha-Service-Container/releases/download/grpcwebproxy/grpcwebproxy_linux_$ARCH.tar.gz -qO- | tar xz -C $TEMP_DIR >/dev/null 2>&1; }&
    { wget -qO $TEMP_DIR/app ${GH_PROXY}https://github.com/applexad/nezha-binary-build/releases/latest/download/dashboard-$DASHBOARD_ARCH >/dev/null 2>&1 && chmod +x $TEMP_DIR/app >/dev/null 2>&1; }&
  fi
}

# 为了适配 alpine，定义 cmd_systemctl 的函数
cmd_systemctl() {
  local ENABLE_DISABLE=$1
  if [ "$ENABLE_DISABLE" = 'enable' ]; then
    if [ "$SYSTEM" = 'Alpine' ]; then
      local TRY=5
      until [ $(systemctl is-active nezha-dashboard) = 'active' ]; do
        systemctl stop nezha-dashboard; sleep 1
        systemctl start nezha-dashboard
        ((TRY--))
        [ "$TRY" = 0 ] && break
      done
      cat > /etc/local.d/nezha-dashboard.start << EOF
#!/usr/bin/env bash

systemctl start nezha-dashboard
EOF
      chmod +x /etc/local.d/nezha-dashboard.start
      rc-update add local >/dev/null 2>&1
    else
      systemctl enable --now nezha-dashboard
    fi

  elif [ "$ENABLE_DISABLE" = 'disable' ]; then
    if [ "$SYSTEM" = 'Alpine' ]; then
      systemctl stop nezha-dashboard
      rm -f /etc/local.d/nezha-dashboard.start
    else
      systemctl disable --now nezha-dashboard
    fi
  fi
}

check_system_info() {
  [ -s /etc/os-release ] && SYS="$(grep -i pretty_name /etc/os-release | cut -d \" -f2)"
  [[ -z "$SYS" && $(type -p hostnamectl) ]] && SYS="$(hostnamectl | grep -i system | cut -d : -f2)"
  [[ -z "$SYS" && $(type -p lsb_release) ]] && SYS="$(lsb_release -sd)"
  [[ -z "$SYS" && -s /etc/lsb-release ]] && SYS="$(grep -i description /etc/lsb-release | cut -d \" -f2)"
  [[ -z "$SYS" && -s /etc/redhat-release ]] && SYS="$(grep . /etc/redhat-release)"
  [[ -z "$SYS" && -s /etc/issue ]] && SYS="$(grep . /etc/issue | cut -d '\' -f1 | sed '/^[ ]*$/d')"

  REGEX=("debian" "ubuntu" "centos|red hat|kernel|oracle linux|alma|rocky" "amazon linux" "arch linux" "alpine")
  RELEASE=("Debian" "Ubuntu" "CentOS" "CentOS" "Arch" "Alpine")
  EXCLUDE=("")
  MAJOR=("9" "16" "7" "7" "" "")
  PACKAGE_UPDATE=("apt -y update" "apt -y update" "yum -y update" "yum -y update" "pacman -Sy" "apk update -f")
  PACKAGE_INSTALL=("apt -y install" "apt -y install" "yum -y install" "yum -y install" "pacman -S --noconfirm" "apk add --no-cache")
  PACKAGE_UNINSTALL=("apt -y autoremove" "apt -y autoremove" "yum -y autoremove" "yum -y autoremove" "pacman -Rcnsu --noconfirm" "apk del -f")

  for int in "${!REGEX[@]}"; do [[ $(tr 'A-Z' 'a-z' <<< "$SYS") =~ ${REGEX[int]} ]] && SYSTEM="${RELEASE[int]}" && break; done
  [ -z "$SYSTEM" ] && error " $(text 5) "

  # 先排除 EXCLUDE 里包括的特定系统，其他系统需要作大发行版本的比较
  for ex in "${EXCLUDE[@]}"; do [[ ! $(tr 'A-Z' 'a-z' <<< "$SYS")  =~ $ex ]]; done &&
  [[ "$(echo "$SYS" | sed "s/[^0-9.]//g" | cut -d. -f1)" -lt "${MAJOR[int]}" ]] && error " $(text 6) "
}

check_dependencies() {
  # 如果是 Alpine，先升级 wget ，安装 systemctl-py 版
  if [ "$SYSTEM" = 'Alpine' ]; then
    CHECK_WGET=$(wget 2>&1 | head -n 1)
    grep -qi 'busybox' <<< "$CHECK_WGET" && ${PACKAGE_INSTALL[int]} wget >/dev/null 2>&1

    DEPS_CHECK=("bash" "rc-update" "git" "ss" "openssl" "python3")
    DEPS_INSTALL=("bash" "openrc" "git" "iproute2" "openssl" "python3")
    for ((g=0; g<${#DEPS_CHECK[@]}; g++)); do [ ! $(type -p ${DEPS_CHECK[g]}) ] && [[ ! "${DEPS[@]}" =~ "${DEPS_INSTALL[g]}" ]] && DEPS+=(${DEPS_INSTALL[g]}); done
    if [ "${#DEPS[@]}" -ge 1 ]; then
      info "\n $(text 7) ${DEPS[@]} \n"
      ${PACKAGE_UPDATE[int]} >/dev/null 2>&1
      ${PACKAGE_INSTALL[int]} ${DEPS[@]} >/dev/null 2>&1
    else
      info "\n $(text 8) \n"
    fi

    [ ! $(type -p systemctl) ] && wget https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl3.py -O /bin/systemctl && chmod a+x /bin/systemctl

  # 非 Alpine 系统安装的依赖
  else
    # 检测 Linux 系统的依赖，升级库并重新安装依赖
    DEPS_CHECK=("wget" "systemctl" "cron" "ss" "git" "timedatectl" "openssl")
    DEPS_INSTALL=("wget" "systemctl" "cron" "iproute2" "git" "timedatectl" "openssl")
    for ((g=0; g<${#DEPS_CHECK[@]}; g++)); do [ ! $(type -p ${DEPS_CHECK[g]}) ] && [[ ! "${DEPS[@]}" =~ "${DEPS_INSTALL[g]}" ]] && DEPS+=(${DEPS_INSTALL[g]}); done
    if [ "${#DEPS[@]}" -ge 1 ]; then
      info "\n $(text 7) ${DEPS[@]} \n"
      ${PACKAGE_UPDATE[int]} >/dev/null 2>&1
      ${PACKAGE_INSTALL[int]} ${DEPS[@]} >/dev/null 2>&1
    else
      info "\n $(text 8) \n"
    fi
  fi
}

# 申请自签证书
certificate() {
  openssl genrsa -out ${TEMP_DIR}/nezha.key 2048 >/dev/null 2>&1
  openssl req -new -subj "/CN=$ARGO_DOMAIN" -key ${TEMP_DIR}/nezha.key -out ${TEMP_DIR}/nezha.csr >/dev/null 2>&1
  openssl x509 -req -days 36500 -in ${TEMP_DIR}/nezha.csr -signkey ${TEMP_DIR}/nezha.key -out ${TEMP_DIR}/nezha.pem >/dev/null 2>&1
}

dashboard_variables() {
  [ -z "$GH_USER"] && reading " (1/9) $(text 9) " GH_USER
  [ -z "$GH_CLIENTID"] && reading "\n (2/9) $(text 10) " GH_CLIENTID
  [ -z "$GH_CLIENTSECRET"] && reading "\n (3/9) $(text 11) " GH_CLIENTSECRET
  local a=5
  until [[ "$ARGO_AUTH" =~ TunnelSecret || "$ARGO_AUTH" =~ ^[A-Z0-9a-z=]{120,250}$ || "$ARGO_AUTH" =~ .*cloudflared.*service[[:space:]]+install[[:space:]]+[A-Z0-9a-z=]{1,100} ]]; do
    [ "$a" = 0 ] && error "\n $(text 3) \n" || reading "\n (4/9) $(text 12) " ARGO_AUTH
    if [[ "$ARGO_AUTH" =~ TunnelSecret ]]; then
      ARGO_JSON=${ARGO_AUTH//[ ]/}
    elif [[ "$ARGO_AUTH" =~ ^[A-Z0-9a-z=]{120,250}$ ]]; then
      ARGO_TOKEN=$ARGO_AUTH
    elif [[ "$ARGO_AUTH" =~ .*cloudflared.*service[[:space:]]+install[[:space:]]+[A-Z0-9a-z=]{1,100} ]]; then
      ARGO_TOKEN=$(awk -F ' ' '{print $NF}' <<< "$ARGO_AUTH")
    else
      warning "\n $(text 22) \n"
    fi
    ((a--)) || true
  done

  # 处理可能输入的错误，去掉开头和结尾的空格，去掉最后的 :
  [ -z "$ARGO_DOMAIN"] && reading "\n (5/9) $(text 13) " ARGO_DOMAIN
  ARGO_DOMAIN=$(sed 's/[ ]*//g; s/:[ ]*//' <<< "$ARGO_DOMAIN")
  { certificate; }&

  [[ -z "$GH_USER" || -z "$GH_CLIENTID" || -z "$GH_CLIENTSECRET" || -z "$ARGO_AUTH" || -z "$ARGO_DOMAIN" ]] && error "\n $(text 18) "

  [ -z "$GH_REPO"] && reading "\n (6/9) $(text 14) " GH_REPO
  if [ -n "$GH_REPO" ]; then
    reading "\n (7/8) $(text 15) " GH_BACKUP_USER
    GH_BACKUP_USER=${GH_BACKUP_USER:-$GH_USER}
    [ -z "$GH_EMAIL"] && reading "\n (8/9) $(text 16) " GH_EMAIL
    [ -z "$GH_PAT"] && reading "\n (9/9) $(text 17) " GH_PAT
  fi
}

# 安装面板
install() {
  dashboard_variables

  check_port

  hint "\n $(text 38) "
  wait

  # 检测下载的文件或文件夹是否齐
  for f in ${TEMP_DIR}/{cloudflared,grpcwebproxy,app,resource,nezha.key,nezha.csr,nezha.pem}; do
    [ ! -s "$f" ] && FAILED+=("${f//${TEMP_DIR}\//}")
  done
  [ "${#FAILED[@]}" -gt 0 ] && error "\n $(text 39) "

  # 从临时文件夹复制已下载的所有到工作文件夹
  [ ! -d ${WORK_DIR}/data ] && mkdir -p ${WORK_DIR}/data
  cp -r $TEMP_DIR/{app,cloudflared,grpcwebproxy,resource,nezha.*} $WORK_DIR
  rm -rf $TEMP_DIR

  # 根据参数生成哪吒服务端配置文件
  if [ "$L" = 'C' ]; then
    DASHBOARD_LANGUAGE='zh-CN'
    if [ "$(date | awk '{print $(NF-1)}')" != 'CST' ]; then
      if [ "$SYSTEM" = 'Alpine' ]; then
          [ ! -s /usr/share/zoneinfo/Asia/Shanghai ] && apk add tzdata >/dev/null 2>&1
          cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
          echo "Asia/Shanghai" > /etc/timezone
      else
        timedatectl set-timezone Asia/Shanghai
      fi
    fi
  else
    DASHBOARD_LANGUAGE='en-US'
  fi

  cat > ${WORK_DIR}/data/config.yaml << EOF
debug: false
httpport: $WEB_PORT
language: $DASHBOARD_LANGUAGE
grpcport: $GRPC_PORT
grpchost: $ARGO_DOMAIN
proxygrpcport: 443
tls: true
oauth2:
  type: "github" #Oauth2 登录接入类型，github/gitlab/jihulab/gitee/gitea
  admin: "$GH_USER" #管理员列表，半角逗号隔开
  clientid: "$GH_CLIENTID" # 在 https://github.com/settings/developers 创建，无需审核 Callback 填 http(s)://域名或IP/oauth2/callback
  clientsecret: "$GH_CLIENTSECRET"
  endpoint: "" # 如gitea自建需要设置
site:
  brand: "Nezha Probe"
  cookiename: "nezha-dashboard" #浏览器 Cookie 字段名，可不改
  theme: "default"
EOF

  # 判断 ARGO_AUTH 为 json 还是 token
  # 如为 json 将生成 argo.json 和 argo.yml 文件
  if [ -n "$ARGO_JSON" ]; then
    ARGO_RUNS="${WORK_DIR}/cloudflared tunnel --edge-ip-version auto --config ${WORK_DIR}/argo.yml run"

    echo "$ARGO_JSON" > ${WORK_DIR}/argo.json

    cat > ${WORK_DIR}/argo.yml << EOF
tunnel: $(cut -d '"' -f12 <<< "$ARGO_JSON")
credentials-file: ${WORK_DIR}/argo.json
protocol: http2

ingress:
  - hostname: $ARGO_DOMAIN
    service: https://localhost:$GRPC_PROXY_PORT
    path: /proto.NezhaService/*
    originRequest:
      http2Origin: true
      noTLSVerify: true
  - hostname: $ARGO_DOMAIN
    service: http://localhost:$WEB_PORT
  - service: http_status:404
EOF

  # 如为 token 时
  elif [ -n "$ARGO_TOKEN" ]; then
    ARGO_RUNS="${WORK_DIR}/cloudflared tunnel --edge-ip-version auto --protocol http2 run --token ${ARGO_TOKEN}"
  fi

  # 生成应用启动停止脚本及进程守护
  cat > ${WORK_DIR}/run.sh << EOF
#!/usr/bin/env bash
SYSTEM=$SYSTEM

if [ "\$1" = 'start' ]; then
  cd ${WORK_DIR}

  nohup ${WORK_DIR}/grpcwebproxy --run_http_server=false --server_tls_cert_file=${WORK_DIR}/nezha.pem --server_tls_key_file=${WORK_DIR}/nezha.key --server_http_tls_port=$GRPC_PROXY_PORT --backend_addr=localhost:${GRPC_PORT} --backend_tls_noverify --server_http_max_read_timeout=300s --server_http_max_write_timeout=300s >/dev/null 2>&1 &

  nohup ${WORK_DIR}/app >/dev/null 2>&1 &

  $ARGO_RUNS

elif [ "\$1" = 'stop' ]; then
  [ "\$SYSTEM" = 'Alpine' ] && ps -ef | awk '/\/opt\/nezha\/dashboard\/(cloudflared|grpcwebproxy|app)/{print \$1}' | xargs kill -9 || ps -ef | awk '/\/opt\/nezha\/dashboard\/(cloudflared|grpcwebproxy|app)/{print \$2}' | xargs kill -9
fi
EOF

  cat > /etc/systemd/system/nezha-dashboard.service << EOF
[Unit]
Description=Nezha Argo for VPS
After=network.target
Documentation=https://github.com/fscarmen2/Argo-Nezha-Service-Container

[Service]
Type=simple
NoNewPrivileges=yes
TimeoutStartSec=0
ExecStart=${WORK_DIR}/run.sh start
ExecStopPost=${WORK_DIR}/run.sh stop
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

  # 生成定时备份数据库脚本，定时任务，删除 5 天前的备份
  cat > ${WORK_DIR}/backup.sh << EOF
#!/usr/bin/env bash

# backup.sh 传参 a 自动还原； 传参 m 手动还原； 传参 f 强制更新面板 app 文件及 cloudflared 文件，并备份数据至成备份库

GH_PAT=$GH_PAT
GH_BACKUP_USER=$GH_BACKUP_USER
GH_EMAIL=$GH_EMAIL
GH_REPO=$GH_REPO
SYSTEM=$SYSTEM
DASHBOARD_ARCH=$DASHBOARD_ARCH
ARCH=$ARCH
WORK_DIR=$WORK_DIR

warning() { echo -e "\033[31m\033[01m\$*\033[0m"; }  # 红色
error() { echo -e "\033[31m\033[01m\$*\033[0m" && exit 1; } # 红色
info() { echo -e "\033[32m\033[01m\$*\033[0m"; }   # 绿色
hint() { echo -e "\033[33m\033[01m\$*\033[0m"; }   # 黄色

cmd_systemctl() {
  local ENABLE_DISABLE=\$1
  if [ "\$ENABLE_DISABLE" = 'enable' ]; then
    if [ "\$SYSTEM" = 'Alpine' ]; then
      local TRY=5
      until [ \$(systemctl is-active nezha-dashboard) = 'active' ]; do
        systemctl stop nezha-dashboard; sleep 1
        systemctl start nezha-dashboard
        ((TRY--))
        [ "\$TRY" = 0 ] && break
      done
      cat > /etc/local.d/nezha-dashboard.start << ABC
#!/usr/bin/env bash

systemctl start nezha-dashboard
ABC
      chmod +x /etc/local.d/nezha-dashboard.start
      rc-update add local >/dev/null 2>&1
    else
      systemctl enable --now nezha-dashboard
    fi

  elif [ "\$ENABLE_DISABLE" = 'disable' ]; then
    if [ "\$SYSTEM" = 'Alpine' ]; then
      systemctl stop nezha-dashboard
      rm -f /etc/local.d/nezha-dashboard.start
    else
      systemctl disable --now nezha-dashboard
    fi
  fi
}

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
  hint "\n stop Nezha-dashboard \n"
  cmd_systemctl disable
  sleep 2
  if [ "\$(systemctl is-active nezha-dashboard)" = 'inactive' ]; then
    # 更新面板和 resource
    if [[ "\${DASHBOARD_UPDATE}\${FORCE_UPDATE}" =~ 'true' ]]; then
      hint "\n Renew dashboard app to \$DASHBOARD_LATEST \n"
      wget -O \$WORK_DIR/app \${GH_PROXY}https://github.com/applexad/nezha-binary-build/releases/latest/download/dashboard-\$DASHBOARD_ARCH
      wget -c \${GH_PROXY}https://github.com/applexad/nezha-binary-build/releases/latest/download/resource.tar.gz -qO- | tar xvz -C \$WORK_DIR
    fi

    # 更新 cloudflared
    if [[ "\${CLOUDFLARED_UPDATE}\${FORCE_UPDATE}" =~ 'true' ]]; then
      hint "\n Renew Cloudflared to \$CLOUDFLARED_LATEST \n"
      wget -O \$WORK_DIR/cloudflared \${GH_PROXY}https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-\$ARCH && chmod +x \$WORK_DIR/cloudflared
    fi

    # 克隆备份仓库，压缩备份文件，上传更新
    if [ "\$IS_BACKUP" = 'true' ]; then
      # 设置 git 环境变量，减少系统开支
      git config --global core.bigFileThreshold 1k
      git config --global core.compression 0
      git config --global advice.detachedHead false
      git config --global pack.threads 1
      git config --global pack.windowMemory 50m

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

  # 重启面板
  cmd_systemctl enable >/dev/null 2>&1; sleep 2
fi

[ "\$(systemctl is-active nezha-dashboard)" = 'active' ] && info "\n Done! \n" || error "\n Fail! \n"
EOF

  if [[ -n "$GH_BACKUP_USER" && -n "$GH_REPO" && -n "$GH_PAT" ]]; then
    # 生成还原数据脚本
    touch ${WORK_DIR}/dbfile
    cat > ${WORK_DIR}/restore.sh << EOF
#!/usr/bin/env bash

# restore.sh 传参 a 自动还原 README.md 记录的文件，当本地与远程记录文件一样时不还原； 传参 f 不管本地记录文件，强制还原成备份库里 README.md 记录的文件； 传参 dashboard-***.tar.gz 还原成备份库里的该文件；不带参数则要求选择备份库里的文件名

GH_PAT=$GH_PAT
GH_BACKUP_USER=$GH_BACKUP_USER
GH_REPO=$GH_REPO
SYSTEM=$SYSTEM
WORK_DIR=$WORK_DIR
TEMP_DIR=/tmp/restore_temp

trap "rm -rf \$TEMP_DIR; echo -e '\n' ;exit 1" INT QUIT TERM EXIT

mkdir -p \$TEMP_DIR

warning() { echo -e "\033[31m\033[01m\$*\033[0m"; }  # 红色
error() { echo -e "\033[31m\033[01m\$*\033[0m" && exit 1; } # 红色
info() { echo -e "\033[32m\033[01m\$*\033[0m"; }   # 绿色
hint() { echo -e "\033[33m\033[01m\$*\033[0m"; }   # 黄色

cmd_systemctl() {
  local ENABLE_DISABLE=\$1
  if [ "\$ENABLE_DISABLE" = 'enable' ]; then
    if [ "\$SYSTEM" = 'Alpine' ]; then
      local TRY=5
      until [ \$(systemctl is-active nezha-dashboard) = 'active' ]; do
        systemctl stop nezha-dashboard; sleep 1
        systemctl start nezha-dashboard
        ((TRY--))
        [ "\$TRY" = 0 ] && break
      done
      cat > /etc/local.d/nezha-dashboard.start << ABC
#!/usr/bin/env bash

systemctl start nezha-dashboard
ABC
      chmod +x /etc/local.d/nezha-dashboard.start
      rc-update add local >/dev/null 2>&1
    else
      systemctl enable --now nezha-dashboard
    fi

  elif [ "\$ENABLE_DISABLE" = 'disable' ]; then
    if [ "\$SYSTEM" = 'Alpine' ]; then
      systemctl stop nezha-dashboard
      rm -f /etc/local.d/nezha-dashboard.start
    else
      systemctl disable --now nezha-dashboard
    fi
  fi
}

ONLINE="\$(wget -qO- --header="Authorization: token \$GH_PAT" "https://raw.githubusercontent.com/\$GH_BACKUP_USER/\$GH_REPO/main/README.md" | sed "/^$/d" | head -n 1)"

# 若用户在 Github 的 README.md 里改了内容包含关键词 backup，则触发实时备份
grep -qi 'backup' <<< "\$ONLINE" && { \$WORK_DIR/backup.sh; exit 0; }

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
  hint "\n Stop Nezha-dashboard \n" && cmd_systemctl disable

  # 容器版的备份旧方案是 /dashboard 文件夹，新方案是备份工作目录 < WORK_DIR > 下的文件，此判断用于根据压缩包里的目录架构判断到哪个目录下解压，以兼容新旧备份方案
  FILE_LIST=\$(tar tzf \$TEMP_DIR/backup.tar.gz)
  FILE_PATH=\$(sed -n 's#\(.*/\)data/sqlite\.db.*#\1#gp' <<< "\$FILE_LIST")

  # 判断备份文件里是否有用户自定义主题，如有则一并解压
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
  hint "\n Start Nezha-dashboard \n" && cmd_systemctl enable >/dev/null 2>&1; sleep 5
fi

[ "\$(systemctl is-active nezha-dashboard)" = 'active' ] && info "\n Done! \n" || error "\n Fail! \n"
EOF

    # 生成定时任务，每天北京时间 4:00:00 备份一次，并重启 cron 服务; 每分钟自动检测在线备份文件里的内容
    if [ "$SYSTEM" = 'Alpine' ]; then
      grep -q "${WORK_DIR}/backup.sh" /var/spool/cron/crontabs/root || echo "0       4       *       *       *       bash ${WORK_DIR}/backup.sh a" >> /var/spool/cron/crontabs/root
      grep -q "${WORK_DIR}/restore.sh" /var/spool/cron/crontabs/root || echo "*       *       *       *       *       bash ${WORK_DIR}/restore.sh a" >> /var/spool/cron/crontabs/root
    else
      grep -q "${WORK_DIR}/backup.sh" /etc/crontab || echo "0 4 * * * root bash ${WORK_DIR}/backup.sh a" >> /etc/crontab
      grep -q "${WORK_DIR}/restore.sh" /etc/crontab || echo "* * * * * root bash ${WORK_DIR}/restore.sh a" >> /etc/crontab
      service cron restart >/dev/null 2>&1
    fi
  fi

  # 赋执行权给 sh  文件
  chmod +x ${WORK_DIR}/*.sh

  # 记录语言
  echo "$L" > ${WORK_DIR}/language

  # 运行哪吒面板
  cmd_systemctl enable
  sleep 5

  # 检测并显示结果
  if [ "$(systemctl is-active nezha-dashboard)" = 'active' ]; then
    [ -n "$ARGO_TOKEN" ] && hint "\n $(text 35) "
    warning "\n $(text 34) " && info "\n $(text 30) $(text 31)! \n"
  else
    error "\n $(text 30) $(text 32)! \n"
  fi
}

# 卸载
uninstall() {
  cmd_systemctl disable
  rm -rf /etc/systemd/system/nezha-dashboard.service ${WORK_DIR}
  if [ "$SYSTEM" = 'Alpine' ]; then
    sed -i "/\/opt\/nezha\/dashboard/d" /var/spool/cron/crontabs/root
  else
    sed -i "/\/opt\/nezha\/dashboard/d" /etc/crontab
    service cron restart >/dev/null 2>&1
  fi
  info "\n $(text 29) $(text 31) "
}

# 判断当前 Argo-X 的运行状态，并对应的给菜单和动作赋值
menu_setting() {
  OPTION[0]="0.  $(text 19)"
  ACTION[0]() { exit; }

  if [[ ${STATUS} =~ $(text 27)|$(text 28) ]]; then
    [ ${STATUS} = "$(text 28)" ] && OPTION[1]="1.  $(text 20) " || OPTION[1]="1.  $(text 21) "
    OPTION[2]="2.  $(text 29)"

    [[ ${STATUS} = "$(text 28)" ]] && ACTION[1]() { cmd_systemctl disable; [ "$(systemctl is-active nezha-dashboard)" = 'inactive' ] && info "\n $(text 20) $(text 31) " || error " $(text 20) $(text 32) "; }
    [[ ${STATUS} = "$(text 27)" ]] && ACTION[1]() { cmd_systemctl enable; [ "$(systemctl is-active nezha-dashboard)" = 'active' ] && info "\n $(text 21) $(text 31) " || error "\n $(text 21) $(text 32) "; }

   ACTION[2]() { uninstall; exit; }

  else
    OPTION[1]="1.  $(text 30)"
    OPTION[2]="2.  $(text 36)"
    OPTION[3]="3.  $(text 37)"

    ACTION[1]() { check_dependencies; install; exit; }
    [ "$L" = 'C' ] && ACTION[2]() { curl -L https://raw.fgit.cf/applexad/nezhascript/main/install.sh  -o nezha.sh && chmod +x nezha.sh && ./nezha.sh; exit; }
    [ "$L" = 'E' ] && ACTION[2]() { curl -L https://raw.fgit.cf/applexad/nezhascript/main/install_en.sh  -o nezha.sh && chmod +x nezha.sh && ./nezha.sh; exit; }
    [ "$L" = 'C' ] && ACTION[3]() { curl -L https://jihulab.com/nezha/dashboard/-/raw/master/script/install.sh -o nezha.sh && chmod +x nezha.sh && CN=true ./nezha.sh; exit; } || ACTION[3]() { curl -L https://raw.githubusercontent.com/naiba/nezha/master/script/install_en.sh  -o nezha.sh && chmod +x nezha.sh && sudo ./nezha.sh; exit; }
  fi
}

menu() {
  clear
  info " $(text 1) "
  echo -e '—————————————————————-\n'
  for ((a=1;a<${#OPTION[*]}; a++)); do hint "\n ${OPTION[a]} "; done
  hint "\n ${OPTION[0]} "
  reading "\n $(text 24) " CHOOSE

  # 输入必须是数字且少于等于最大可选项
  if grep -qE "^[0-9]$" <<< "$CHOOSE" && [ "$CHOOSE" -lt "${#OPTION[*]}" ]; then
    ACTION[$CHOOSE]
  else
    warning " $(text 23) [0-$((${#OPTION[*]}-1))] " && sleep 1 && menu
  fi
}

select_language
check_root
check_system_info
check_arch
check_install
menu_setting
menu
