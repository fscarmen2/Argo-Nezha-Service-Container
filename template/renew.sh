#!/usr/bin/env bash

# renew.sh 用于在线同步最新的 backup.sh 和 restore.sh 脚本

GH_PROXY=https://mirror.ghproxy.com/
WORK_DIR=
TEMP_DIR=

########

# 自定义字体彩色，read 函数
warning() { echo -e "\033[31m\033[01m$*\033[0m"; }  # 红色
error() { echo -e "\033[31m\033[01m$*\033[0m" && exit 1; } # 红色
info() { echo -e "\033[32m\033[01m$*\033[0m"; }   # 绿色
hint() { echo -e "\033[33m\033[01m$*\033[0m"; }   # 黄色

trap "rm -rf $TEMP_DIR; echo -e '\n' ;exit" INT QUIT TERM EXIT

mkdir -p $TEMP_DIR

# 在线更新 renew.sh，backup.sh 和 restore.sh 文件
for i in {renew,backup,restore}; do
  if [ -s $WORK_DIR/$i.sh ]; then
    sed -n '1,/^########/p' $WORK_DIR/$i.sh > $TEMP_DIR/$i.sh
    wget -qO- ${GH_PROXY}https://raw.githubusercontent.com/fscarmen2/Argo-Nezha-Service-Container/main/template/$i.sh | sed '1,/^########/d' >> $TEMP_DIR/$i.sh
    [ $(wc -l $TEMP_DIR/$i.sh | awk '{print $1}') -gt 20 ] && mv -f $TEMP_DIR/$i.sh $WORK_DIR/ && info "\n Update $i.sh Successful. \n" || warning "\n Update $i.sh failed.\n" 
  fi
done