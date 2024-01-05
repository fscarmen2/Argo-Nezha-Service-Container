#!/usr/bin/env bash

# backup.sh 传参 a 自动还原； 传参 m 手动还原； 传参 f 强制更新面板 app 文件及 cloudflared 文件，并备份数据至成备份库

GH_PROXY=https://mirror.ghproxy.com/
GH_PAT=
GH_BACKUP_USER=
GH_EMAIL=
GH_REPO=
SYSTEM=
ARCH=
WORK_DIR=
DAYS=5
IS_DOCKER=

########

# version: 2023.12.31

warning() { echo -e "\033[31m\033[01m$*\033[0m"; }  # 红色
error() { echo -e "\033[31m\033[01m$*\033[0m" && exit 1; } # 红色
info() { echo -e "\033[32m\033[01m$*\033[0m"; }   # 绿色
hint() { echo -e "\033[33m\033[01m$*\033[0m"; }   # 黄色

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
      cat > /etc/local.d/nezha-dashboard.start << ABC
#!/usr/bin/env bash

systemctl start nezha-dashboard
ABC
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

# 手自动标志
[ "$1" = 'a' ] && WAY=Scheduled || WAY=Manualed
[ "$1" = 'f' ] && WAY=Manualed && FORCE_UPDATE=true

# 检查更新面板主程序 app 及 cloudflared
cd $WORK_DIR
DASHBOARD_NOW=$(./app -v)
DASHBOARD_LATEST=$(wget -qO- "https://api.github.com/repos/naiba/nezha/releases/latest" | awk -F '"' '/"tag_name"/{print $4}')
[[ "$DASHBOARD_LATEST" =~ ^v([0-9]{1,3}\.){2}[0-9]{1,3}$ && "$DASHBOARD_NOW" != "$DASHBOARD_LATEST" ]] && DASHBOARD_UPDATE=true

CLOUDFLARED_NOW=$(./cloudflared -v | awk '{for (i=0; i<NF; i++) if ($i=="version") {print $(i+1)}}')
CLOUDFLARED_LATEST=$(wget -qO- https://api.github.com/repos/cloudflare/cloudflared/releases/latest | awk -F '"' '/tag_name/{print $4}')
[[ "$CLOUDFLARED_LATEST" =~ ^20[0-9]{2}\.[0-9]{1,2}\.[0-9]+$ && "$CLOUDFLARED_NOW" != "$CLOUDFLARED_LATEST" ]] && CLOUDFLARED_UPDATE=true

# 检测是否有设置备份数据
if [[ -n "$GH_REPO" && -n "$GH_BACKUP_USER" && -n "$GH_EMAIL" && -n "$GH_PAT" ]]; then
  IS_PRIVATE="$(wget -qO- --header="Authorization: token $GH_PAT" https://api.github.com/repos/$GH_BACKUP_USER/$GH_REPO | sed -n '/"private":/s/.*:[ ]*\([^,]*\),/\1/gp')"
  if [ "$?" != 0 ]; then
    warning "\n Could not connect to Github. Stop backup. \n"
  elif [ "$IS_PRIVATE" != true ]; then
    warning "\n This is not exist nor a private repository. \n"
  else
    IS_BACKUP=true
  fi
fi

# 分步骤处理
if [[ "${DASHBOARD_UPDATE}${CLOUDFLARED_UPDATE}${IS_BACKUP}${FORCE_UPDATE}" =~ true ]]; then
  # 更新面板和 resource
  if [[ "${DASHBOARD_UPDATE}${FORCE_UPDATE}" =~ 'true' ]]; then
    hint "\n Renew dashboard app to $DASHBOARD_LATEST \n"
    wget -O /tmp/dashboard.zip ${GH_PROXY}https://github.com/naiba/nezha/releases/download/$DASHBOARD_LATEST/dashboard-linux-$ARCH.zip
    unzip /tmp/dashboard.zip -d /tmp
    if [ -s /tmp/dist/dashboard-linux-$ARCH ]; then
      info "\n Restart Nezha Dashboard \n"
      if [ "$IS_DOCKER" = 1 ]; then
        supervisorctl stop nezha >/dev/null 2>&1
        mv -f /tmp/dist/dashboard-linux-$ARCH $WORK_DIR/app
        supervisorctl start nezha >/dev/null 2>&1
      else
        cmd_systemctl disable >/dev/null 2>&1
        mv -f /tmp/dist/dashboard-linux-$ARCH $WORK_DIR/app
        cmd_systemctl enable >/dev/null 2>&1
      fi
    fi
    rm -rf /tmp/dist /tmp/dashboard.zip
  fi

  # 处理 v0.15.17 之后自定义主题静态链接的路径问题，删除原 resource 下的非 custom 文件夹及文件
  [ -d $WORK_DIR/resource/static/theme-custom ] && mv -f $WORK_DIR/resource/static/theme-custom $WORK_DIR/resource/static/custom
  [ -s $WORK_DIR/resource/template/theme-custom/header.html ] && sed -i 's#/static/theme-custom/#/static-custom/#g' $WORK_DIR/resource/template/theme-custom/header.html
  if [ -d $WORK_DIR/resource ]; then
    find $WORK_DIR/resource ! -path "$WORK_DIR/resource/*/*custom*" -type f -delete
    find $WORK_DIR/resource ! -path "$WORK_DIR/resource/*/*custom*" -type d -empty -delete
  fi

  # 更新 cloudflared
  if [[ "${CLOUDFLARED_UPDATE}${FORCE_UPDATE}" =~ 'true' ]]; then
    hint "\n Renew Cloudflared to $CLOUDFLARED_LATEST \n"
    wget -O /tmp/cloudflared ${GH_PROXY}https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$ARCH && chmod +x /tmp/cloudflared
    if [ -s /tmp/cloudflared ]; then
      info "\n Restart Argo \n"
      if [ "$IS_DOCKER" = 1 ]; then
        supervisorctl stop argo >/dev/null 2>&1
        mv -f /tmp/cloudflared $WORK_DIR/
      else
        cmd_systemctl disable >/dev/null 2>&1
        mv -f /tmp/cloudflared $WORK_DIR/
        cmd_systemctl enable >/dev/null 2>&1
      fi
    fi
  fi

  # 克隆备份仓库，压缩备份文件，上传更新
  if [ "$IS_BACKUP" = 'true' ]; then
    # 设置 git 环境变量，减少系统开支
    if [ "$IS_DOCKER" != 1 ]; then
      git config --global core.bigFileThreshold 1k
      git config --global core.compression 0
      git config --global advice.detachedHead false
      git config --global pack.threads 1
      git config --global pack.windowMemory 50m
    fi

    # 克隆现有备份库
    [ -d /tmp/$GH_REPO ] && rm -rf /tmp/$GH_REPO
    git clone https://$GH_PAT@github.com/$GH_BACKUP_USER/$GH_REPO.git --depth 1 --quiet /tmp/$GH_REPO

    # 压缩备份数据，只备份 $WORK_DIR/data/ 目录下的 config.yaml 和 sqlite.db； $WORK_DIR/resource/ 目录下名字有 custom 的自定义主题文件夹
    if [ -d /tmp/$GH_REPO ]; then
      TIME=$(date "+%Y-%m-%d-%H:%M:%S")
      echo "↓↓↓↓↓↓↓↓↓↓ dashboard-$TIME.tar.gz list ↓↓↓↓↓↓↓↓↓↓"
      find $WORK_DIR/resource/ -type d -name "*custom*" | tar czvf /tmp/$GH_REPO/dashboard-$TIME.tar.gz -T- $WORK_DIR/data/
      echo -e "↑↑↑↑↑↑↑↑↑↑ dashboard-$TIME.tar.gz list ↑↑↑↑↑↑↑↑↑↑\n\n"

      # 更新备份 Github 库，删除 5 天前的备份
      cd /tmp/$GH_REPO
      [ -e ./.git/index.lock ] && rm -f ./.git/index.lock
      echo "dashboard-$TIME.tar.gz" > README.md
      find ./ -name '*.gz' | sort | head -n -$DAYS | xargs rm -f
      git config --global user.name $GH_BACKUP_USER
      git config --global user.email $GH_EMAIL
      git checkout --orphan tmp_work
      git add .
      git commit -m "$WAY at $TIME ."
      git push -f -u origin HEAD:main --quiet
      IS_UPLOAD="$?"
      cd ..
      rm -rf $GH_REPO
      [ "$IS_UPLOAD" = 0 ] && echo "dashboard-$TIME.tar.gz" > $WORK_DIR/dbfile && info "\n Succeed to upload the backup files dashboard-$TIME.tar.gz to Github.\n" || hint "\n Failed to upload the backup files dashboard-$TIME.tar.gz to Github.\n"
    fi
  fi
fi

if [ "$IS_DOCKER" = 1 ]; then
  [ $(supervisorctl status all | grep -c "RUNNING") = $(grep -c '\[program:.*\]' /etc/supervisor/conf.d/damon.conf) ] && info "\n All programs started! \n" || error "\n Failed to start program! \n"
else
  [ "$(systemctl is-active nezha-dashboard)" = 'active' ] && info "\n Nezha dashboard started! \n" || error "\n Failed to start Nezha dashboard! \n"
fi
