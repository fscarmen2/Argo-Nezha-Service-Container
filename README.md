# Argo-Nezha-Service-Container

Nezha server over Argo tunnel 
使用 Argo 隧道的哪吒服务端

* * *

# 目录

- [项目特点](README.md#项目特点)
- [准备需要用的变量](README.md#准备需要用的变量)
- [PaaS 部署实例](README.md#PaaS-部署实例)
- [VPS 部署实例](README.md#VPS-部署实例)
- [客户端接入](README.md#客户端接入)
- [鸣谢下列作者的文章和项目](README.md#鸣谢下列作者的文章和项目)
- [免责声明](README.md#免责声明)

* * *

## 项目特点:
### 优点:
* 适用范围更广 --- 只要能连通网络，就能安装哪吒服务端，如 Nas 虚拟机 , Container PaaS 等
* Argo 隧道突破需要公网入口的限制 --- 传统的哪吒需要有两个，一个用于面板的访问，另一个用于客户端上报数据，本项目借用 Cloudflare Argo 隧道，使用内网穿透的办法
* IPv4 / v6 具备更高的灵活性 --- 传统哪吒需要处理服务端和客户端的 IPv4/v6 兼容性问题，还需要通过 warp 等工具来解决不对应的情况。然而，本项目可以完全不需要考虑这些问题，可以任意对接，更加方便和简便
* 一条 Argo 隧道分流多个域名和协议 --- 建立一条内网穿透的 Argo 隧道，即可分流三个域名(hostname)和协议(protocal)，分别用于面板的访问(http)，客户端上报数据(tcp)和 ssh（可选）
* Nginx 反向代理的 gRPC 数据端口，配上证书做 tls 终结，然后 Argo 的隧道配置用 https 服务指向这个反向代理，启用http2回源，grpc(nezha)->h2(nginx)->argo->cf cdn edge->agent
* 数据更安全 --- Argo 隧道使用TLS加密通信，可以将应用程序流量安全地传输到 Cloudflare 网络，提高了应用程序的安全性和可靠性。此外，Argo Tunnel也可以防止IP泄露和DDoS攻击等网络威胁。


## 准备需要用的变量
* 通过 Cloudflare Json 生成网轻松获取 Argo 隧道信息: https://fscarmen.cloudflare.now.cc

<img width="1040" alt="image" src="https://user-images.githubusercontent.com/92626977/231084930-02e3c2de-c52b-420d-b39c-9f135d040b3b.png">

* 到 Cloudflare 官方，在相应的域名 DNS 记录里加上客户端上报数据(tcp)和 ssh（可选）的域名

<img width="1666" alt="image" src="https://user-images.githubusercontent.com/92626977/231087110-85ddab87-076b-45c9-97d1-c8b051dcb5b0.png">

<img width="1627" alt="image" src="https://user-images.githubusercontent.com/92626977/231087714-e5a45eb9-bc47-4c38-8f5b-a4a9fb492d0d.png">

* 获取 github 认证授权: https://github.com/settings/applications/new

面板域名加上 `https://` 开头，回调地址再加上 `/oauth2/callback` 结尾

<img width="916" alt="image" src="https://user-images.githubusercontent.com/92626977/231099071-b6676f2f-6c7b-4e2f-8411-c134143cab24.png">

<img width="1122" alt="image" src="https://user-images.githubusercontent.com/92626977/231086319-1b625dc6-713b-4a62-80b1-cc5b2b7ef3ca.png">

## PaaS 部署实例
镜像 `fscarmen/argo-nezha:latest` ， 支持 amd64 和 arm64 架构

用到的变量 
  | 变量名        | 是否必须  | 备注 |
  | ------------ | ------   | ---- |
  | ADMIN        | 是 | github 的用户名，用于面板管理授权 |
  | CLIENTID     | 是 | 在 github 上申请 |
  | CLIENTSECRET | 是 | 在 github 上申请 |
  | ARGO_JSON    | 是 | 从 https://fscarmen.cloudflare.now.cc 获取的 Argo Json |
  | DATA_DOMAIN  | 是 | 客户端与服务端的通信 argo 域名 |
  | WEB_DOMAIN   | 是 | 面板 argo 域名 |
  | SSH_DOMAIN   | 否 | ssh 用的 argo 域名 |
  | SSH_PASSWORD | 否 | ssh 的密码，只有在设置 SSH_JSON 后才生效，默认值 password |

1.Koyeb

<img width="927" alt="image" src="https://user-images.githubusercontent.com/92626977/231088411-fbac3e6e-a8a6-4661-bcf8-7c777aa8ffeb.png">
<img width="750" alt="image" src="https://user-images.githubusercontent.com/92626977/231088973-7134aefd-4c80-4559-8e40-17c3be11d27d.png">
<img width="1044" alt="image" src="https://user-images.githubusercontent.com/92626977/231090751-4629c60f-8529-4870-a586-06479c7c6517.png">
<img width="1187" alt="image" src="https://user-images.githubusercontent.com/92626977/231092893-c8f017a2-ee0e-4e28-bee3-7343158f0fa7.png">
<img width="500" alt="image" src="https://user-images.githubusercontent.com/92626977/231094144-df6715bc-c611-47ce-a529-03c43f38102e.png">


## VPS 部署实例
* 注意: ARGO_JSON= 后面需要有单引号，不能去掉
```
docker run -dit \
           --name nezha_dashboard \
           --restart always \
           -e ADMIN=<填 github 用户名> \
           -e CLIENTID=<填获取的>  \
           -e CLIENTSECRET=<填获取的> \
           -e ARGO_JSON='<填获取的>' \
           -e WEB_DOMAIN=<填自定义的> \
           -e DATA_DOMAIN=<填自定义的> \
           -e SSH_DOMAIN=<填自定义的> \
           -e SSH_PASSWORD=<填自定义的> \
           fscarmen/argo-nezha
```

### 客户端接入
通过gRPC传输，无需额外配置。使用面板给到的安装方式，举例
```
curl -L https://raw.githubusercontent.com/naiba/nezha/master/script/install.sh -o nezha.sh && chmod +x nezha.sh && sudo ./nezha.sh install_agent data.seales.nom.za 443 eAxO9IF519fKFODlW0 --tls
```


## 鸣谢下列作者的文章和项目:
* 热心的朝阳群众 Robin，讨论哪吒服务端与客户端的关系，从而诞生了此项目
* 哪吒官网: https://nezha.wiki/ , TG 群: https://t.me/nezhamonitoring
* 黑歌: http://solitud.es/
* Akkia's Blog: https://blog.akkia.moe/
* 用 Cloudflare Tunnel 进行内网穿透: https://blog.outv.im/2021/cloudflared-tunnel/

## 免责声明:
* 本程序仅供学习了解, 非盈利目的，请于下载后 24 小时内删除, 不得用作任何商业用途, 文字、数据及图片均有所属版权, 如转载须注明来源。
* 使用本程序必循遵守部署免责声明。使用本程序必循遵守部署服务器所在地、所在国家和用户所在国家的法律法规, 程序作者不对使用者任何不当行为负责。