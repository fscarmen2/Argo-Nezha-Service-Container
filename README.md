# Argo-Nezha-Service-Container

Nezha server on container PaaS
为容器平台部署哪吒服务端

* * *

# 目录

- [项目特点](README.md#项目特点)
- [部署](README.md#部署)
- [鸣谢下列作者的文章和项目](README.md#鸣谢下列作者的文章和项目)
- [免责声明](README.md#免责声明)

* * *

## 项目特点:
* 适用于通过 dockerhub 上已有的镜像或 Dockerfile 来建实例的平台上部署哪吒服务端
* 使用 CloudFlare 的 Argo 隧道，建立三条内网穿透的 Argo 隧道，分别用于访问面板，客户端上报数据和 ssh（可选）之用，特别适合没有公网 IP 的容器 PaaS。当然你也可以部署在 Nas 等
* Argo 隧道使用TLS加密通信，可以将应用程序流量安全地传输到Cloudflare网络，提高了应用程序的安全性和可靠性。此外，Argo Tunnel也可以防止IP泄露和DDoS攻击等网络威胁。

## 部署:
### 镜像 `fscarmen/argo-nezha:latest`

1. 获取面板,客户端与服务端的通信，ssh（可选）用的Argo 隧道 Json，可以通过 Cloudflare Json 生成网轻松获取: https://fscarmen.cloudflare.now.cc

<img width="688" alt="image" src="https://user-images.githubusercontent.com/62703343/224388718-6adf22d0-01d3-46a0-8063-bc0a2210795f.png">

2. 根据面板 argo 域名，获取 Github 的 Client ID 和密钥，详细可以参数官方教程: https://nezha.wiki/guide/dashboard.html#%E8%8E%B7%E5%8F%96-github-jihulab-%E7%9A%84-client-id-%E5%92%8C%E5%AF%86%E9%92%A5

* 申请: https://github.com/settings/developers

<img width="688" alt="image" src="https://user-images.githubusercontent.com/92626977/230728087-6c9029e6-4b84-4d69-9a16-f0b67e19e128.png">

3. 根据平台的规则，填好环境变量(variables)部署即可

* 部署 PaaS 用到的变量 
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

## 鸣谢下列作者的文章和项目:
* 哪吒官网: https://nezha.wiki/ , TG 群： https://t.me/nezhamonitoring
* 热心的朝阳群众 Robin，讨论哪吒服务端与客户端的关系，从而诞生了此项目
* 用 Cloudflare Tunnel 进行内网穿透: https://blog.outv.im/2021/cloudflared-tunnel/

## 免责声明:
* 本程序仅供学习了解, 非盈利目的，请于下载后 24 小时内删除, 不得用作任何商业用途, 文字、数据及图片均有所属版权, 如转载须注明来源。
* 使用本程序必循遵守部署免责声明。使用本程序必循遵守部署服务器所在地、所在国家和用户所在国家的法律法规, 程序作者不对使用者任何不当行为负责。