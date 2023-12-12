# Argo-Nezha-Service-Container

Nezha server over Argo tunnel

Documentation: English version | [中文版](https://github.com/fscarmen2/Argo-Nezha-Service-Container/blob/main/README.md)

* * * *

# Catalog

- [Project Features](README_EN.md#project-features)
- [How to get Argo authentication: json or token](README_EN.md#How-to-get-Argo-authentication-json-or-token)
- [Variables to be used](README_EN.md#prepare-variables-to-be-used)
- [PaaS Deployment Example](README_EN.md#paas-deployment-example)
- [VPS Deployment Method 1 --- docker](README_EN.md#vps-deployment-method-1-----docker)
- [VPS Deployment Method 2 --- hosts](README_EN.md#vps-deployment-method-2-----hosts)
- [Client Access](README_EN.md#client-access)
- [SSH Access](README_EN.md#ssh-access)
- [Manual Backup data](README_EN.md#manual-backup-data)
- [Manual Rerew backup and restore scrpits](README_EN.md#manual-renew-backup-and-restore-scrpits)
- [Auto Restore Backup](README_EN.md#automatically-restore-backups)
- [Manual Restore Backup](README_EN.md#manually-restore-the-backup)
- [Migrating data](README_EN.md#migrating-data)
- [Main Directory Files and Descriptions](README_EN.md#main-catalog-files-and-descriptions)
- [Acknowledgment of articles and projects by the following authors](README_EN.md#acknowledgements-for-articles-and-projects-by)
- [Disclaimer](README_EN.md#disclaimer)

* * *

## Project Features.
* Wider scope of application --- As long as there is a network connection, Nezha server can be installed, such as LXC, OpenVZ VPS, Nas Virtual Machine, Container PaaS, etc.
* Argo tunnel breaks through the restriction of requiring a public network portal --- The traditional Nezha requires two public network ports, one for panel visiting and the other for client reporting, this project uses Cloudflare Argo tunnels and uses intranet tunneling.
* IPv4 / v6 with higher flexibility --- The traditional Nezha needs to deal with IPv4/v6 compatibility between server and client, and also needs to resolve mismatches through tools such as warp. However, this project does not need to consider these issues at all, and can be docked arbitrarily, which is much more convenient and easy!
* One Argo tunnel for multiple domains and protocols --- Create an intranet-penetrating Argo tunnel for three domains (hostname) and protocols, which can be used for panel access (http), client reporting (tcp) and ssh (optional).
* Grpc Proxy reverse proxy gRPC data port --- with a certificate for tls termination, then Argo's tunnel configuration with https service pointing to this reverse proxy, enable http2 back to the source, grpc(nezha)->Grpc Proxy->h2(argo)->cf cdn edge->agent
* Daily automatic backup --- every day at 04:00 BST, the entire Nezha panel folder is automatically backed up to a designated private github repository, including panel themes, panel settings, probe data and tunnel information, the backup retains nearly 5 days of data; the content is so important that it must be placed in the private repository.
* Automatically update the control panel and scripts daily - Check for the latest official control panel version and backup/restore script at 04:00 every day. If an upgrade is available, perform an automatic update.
* Manual/automatic restore backup --- check the content of online restore file once a minute, and restore immediately when there is any update.
* Default built-in local probes --- can easily monitor their own server information

<img width="1609" alt="image" src="https://github.com/fscarmen2/Argo-Nezha-Service-Container/assets/92626977/4893c3cd-5055-468f-8138-6c5460bdd1e4">


## Prepare variables to be used
* Visit the Cloudflare website, select the domain name you want to use, and turn on the `network` option to turn the `gRPC` switch on.

<img width="1605" alt="image" src="https://github.com/fscarmen2/Argo-Nezha-Service-Container/assets/92626977/533133dc-ab46-43ff-8eec-0b57d776e4a9">

* Get github authentication license: https://github.com/settings/applications/new

Add `https://` to the beginning of the panel's domain name and `/oauth2/callback` to the end of the callback address.

<img width="1031" alt="image" src="https://github.com/fscarmen2/Argo-Nezha-Service-Container/assets/92626977/b3218cca-171d-4869-8ff9-7a569d01234a">
<img width="1023" alt="image" src="https://github.com/fscarmen2/Argo-Nezha-Service-Container/assets/92626977/c8e6370d-4307-4b88-b490-ce960b694541">

* Get a PAT (Personal Access Token) for github: https://github.com/settings/tokens/new

<img width="1368" alt="image" src="https://github.com/fscarmen2/Argo-Nezha-Service-Container/assets/92626977/96b09a43-910c-41c8-b407-1090d81ce728">
<img width="1542" alt="image" src="https://github.com/fscarmen2/Argo-Nezha-Service-Container/assets/92626977/b2bf7d3e-2370-4e12-b01d-7cfb9f2d3115">

* Create a private github repository for backups: https://github.com/new

<img width="716" alt="image" src="https://github.com/fscarmen2/Argo-Nezha-Service-Container/assets/92626977/499fb58d-9dc7-4b3f-84d7-d709d679ec80">


## How to get Argo authentication: json or token
Argo tunnel authentication methods include json and token, use one of the two methods. The former is recommended because the script will handle all the Argo tunnel parameters and paths, while the latter needs to be set manually on the Cloudflare website and is prone to errors.

### (Methods 1 - Json):
#### Easily get Argo tunnel json information through Cloudflare Json Generation Network: https://fscarmen.cloudflare.now.cc

<img width="862" alt="image" src="https://github.com/fscarmen2/Argo-Nezha-Service-Container/assets/92626977/7bf8fefd-328f-43a1-ada6-4472904e8adb">

### (Methods 2 - Token): Manually generate Argo tunnel token information via Cloudflare website.
#### Go to the cf website: https://dash.cloudflare.com/
* Go to zero trust and generate token tunnel and message.
* The data path 443/https is proto.
* ssh path 22/ssh for < client id >.

<img width="1672" alt="image" src="https://github.com/fscarmen2/Argo-Nezha-Service-Container/assets/92626977/c2952ef2-7a3d-4242-84bc-3cbada1d337c">
<img width="1652" alt="image" src="https://github.com/fscarmen2/Argo-Nezha-Service-Container/assets/92626977/89b2b758-e550-413d-aa3e-216d226da7f4">
<img width="1463" alt="image" src="https://github.com/fscarmen2/Argo-Nezha-Service-Container/assets/92626977/9f77e26b-a25d-4ff0-8425-1085708e19c3">
<img width="1342" alt="image" src="https://github.com/fscarmen2/Argo-Nezha-Service-Container/assets/92626977/538707e1-a17b-4a0f-a8c0-63d0c7bc96aa">
<img width="1020" alt="image" src="https://github.com/fscarmen2/Argo-Nezha-Service-Container/assets/92626977/9f5778fd-aa94-4fda-9d85-552b68f6d530">
<img width="1652" alt="image" src="https://github.com/fscarmen2/Argo-Nezha-Service-Container/assets/92626977/d0fba15c-f41b-4ee4-bea3-f0506d9b2d23">
<img width="1401" alt="image" src="https://github.com/fscarmen2/Argo-Nezha-Service-Container/assets/92626977/ed3d0849-da78-4fd5-9510-d410afc5e6af">


## PaaS Deployment Example
Image `fscarmen/argo-nezha:latest`, supports amd64 and arm64 architectures.

Variables used
  | Variable Name | Required | Remarks |
  | ------------ | ------ | ---- |
  | GH_USER            | Yes | github username for panel admin authorization |
  | GH_CLIENTID        | yes | apply on github |
  | GH_CLIENTSECRET    | yes | apply on github |
  | GH_BACKUP_USER     | No | The github username for backing up Nezha's server-side database on github, if not filled in, it is the same as the account GH_USER for panel management authorization |
  | GH_REPO            | No | The github repository for backing up Nezha's server-side database files on github |
  | GH_EMAIL           | No | github's mailbox for git push backups to remote repositories |
  | GH_PAT             | No | github's PAT |
  | REVERSE_PROXY_MODE | No | If you want to use Nginx or gRPCwebProxy instead of Caddy for reverse proxying, set this value to `nginx` or `grpcwebproxy` |
  | ARGO_AUTH          | Yes | Argo Json from https://fscarmen.cloudflare.now.cc<br>Argo token from Cloudflare official website  |
  | ARGO_DOMAIN        | Yes | Argo domain |
  | NO_AUTO_RENEW      | No | The latest backup and restore scripts are synchronized online regularly every day. If you don't need this feature, set this variable and assign it a value of `1` |

Koyeb

[![Deploy to Koyeb](https://www.koyeb.com/static/images/deploy/button.svg)](https://app.koyeb.com/deploy?type=docker&name=nezha&ports=80;http;/&env[GH_USER]=&env[GH_CLIENTID]=&env[GH_CLIENTSECRET]=&env[GH_REPO]=&env[GH_EMAIL]=&env[GH_PAT]=&env[ARGO_AUTH]=&env[ARGO_DOMAIN]=&image=docker.io/fscarmen/argo-nezha)

<img width="927" alt="image" src="https://user-images.githubusercontent.com/92626977/231088411-fbac3e6e-a8a6-4661-bcf8-7c777aa8ffeb.png">
<img width="1011" alt="image" src="https://github.com/fscarmen2/Argo-Nezha-Service-Container/assets/92626977/61fad972-1be9-4e8d-829a-8faea0c8ed64">
<img width="854" alt="image" src="https://github.com/fscarmen2/Argo-Nezha-Service-Container/assets/92626977/655c889e-3037-46d7-ab00-3e6085e86f66">
<img width="1214" alt="image" src="https://github.com/fscarmen2/Argo-Nezha-Service-Container/assets/92626977/ddabdf3a-ca63-4523-b839-62c4d4c0caf2">
<img width="881" alt="image" src="https://github.com/fscarmen2/Argo-Nezha-Service-Container/assets/92626977/e623f92d-878f-4eb8-9dfe-55b59770ba2f">


## VPS Deployment Method 1 --- docker
* Note: ARGO_DOMAIN= must be followed by single quotes, which cannot be removed.
* If the VPS is IPv6 only, please install WARP IPv4 or dual-stack first: https://github.com/fscarmen/warp
* The backup directory is the dashboard folder in the current path.

### docker deployment

```
docker run -dit \
           --name nezha_dashboard \
           --pull always \
           --restart always \
           -e GH_USER=<fill in github username> \
           -e GH_EMAIL=<fill in github email> \
           -e GH_PAT=<fill in the obtained> \
           -e GH_REPO=<fill in customized> \
           -e GH_CLIENTID=<fill in acquired> \
           -e GH_CLIENTSECRET=<fill in acquired> \
           -e ARGO_AUTH='<Fill in the fetched Argo json or token>' \
           -e ARGO_DOMAIN=<fill in customized> \
           -e GH_BACKUP_USER=<Optional, Optional, Optional! If it is consistent with GH_USER, you can leave it blank> \
           -e REVERSE_PROXY_MODE=<Optional, Optional, Optional! If you want to use Nginx or gRPCwebProxy instead of Caddy for reverse proxying, set this value to `nginx` or `grpcwebproxy`> \
           -e NO_AUTO_RENEW=<Optional, Optional, Optional! If you don't need synchronized online, set this variable and assign it a value of `1`>
           fscarmen/argo-nezha
```

### docker-compose deployment
```
version: '3.8'
services.
    argo-nezha.
        image: fscarmen/argo-nezha
        --pull always
        container_name: nezha_dashboard
        restart: always
        environment:
            - GH_USER=<fill in github username>
            - GH_EMAIL=<fill in your github email>
            - GH_PAT=<<fill in obtained>
            - GH_REPO=<fill in customized>
            - GH_CLIENTID=<fill in obtained>
            - GH_CLIENTSECRET=<fill in fetched>
            - ARGO_AUTH='<Fill in the fetched Argo json or token>'
            - ARGO_DOMAIN=<fill in customized>
            - GH_BACKUP_USER=<Optional, Optional, Optional! If it is consistent with GH_USER, you can leave it blank>
            - REVERSE_PROXY_MODE=<Optional, Optional, Optional! If you want to use Nginx or gRPCwebProxy instead of Caddy for reverse proxying, set this value to `nginx` or `grpcwebproxy>
            - NO_AUTO_RENEW=<Optional, Optional, Optional! If you don't need synchronized online, set this variable and assign it a value of `1`>
```


## VPS Deployment Method 2 --- hosts
```
bash <(wget -qO- https://raw.githubusercontent.com/fscarmen2/Argo-Nezha-Service-Container/main/dashboard.sh)
```


## Client Access
Transfer via gRPC, no additional configuration required. Use the installation method given in the panel, for example
```
curl -L https://raw.githubusercontent.com/naiba/nezha/master/script/install.sh -o nezha.sh && chmod +x nezha.sh && sudo ./nezha.sh install_agent data.seales.nom.za 443 eAxO9IF519fKFODlW0 --tls
```


## SSH access
* Take macOS + WindTerm as an example, and other SSH tools depending on the one used, combined with the official documentation: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/use_cases/ssh /#2-connect-as-a-user
* Official cloudflared download: https://github.com/cloudflare/cloudflared/releases
* The following are examples of input commands.
  SSH user: root， SSH password：<GH_CLIENTSECRET>
```
<filepath>/cloudflared access ssh --hostname ssh.seals.nom.za/<GH_CLIENTID>
```

<img width="1189" alt="image" src="https://github.com/fscarmen2/Argo-Nezha-Service-Container/assets/92626977/0aeb3939-51c7-47ac-a7fd-25a8a01d3df5">
<img width="840" alt="image" src="https://github.com/fscarmen2/Argo-Nezha-Service-Container/assets/92626977/16961ade-aafc-4132-92a1-aa218e0fead9">
<img width="1201" alt="image" src="https://github.com/fscarmen2/Argo-Nezha-Service-Container/assets/92626977/3146b2e2-f988-487f-ab63-00218eb4d570">


## Manually backing up your data
Method 1: Change the contents of the `README.md` file in the Github backup repository to `backup`

<img width="970" alt="image" src="https://github.com/fscarmen2/Argo-Nezha-Service-Container/assets/92626977/c5b6bc4b-e69c-48ce-97d4- 3f9be88515f3">

Method 2: After ssh, run `/dashboard/backup.sh` for container version; `/opt/nezha/dashboard/backup.sh` for VPS host version.


## Manual Rerew backup and restore scrpits

After ssh, run `/dashboard/renew.sh` for container version; `/opt/nezha/dashboard/renew.sh` for VPS host version.


## Automatically restore backups
* Change the name of the file to be restored to `README.md` in the github backup repository, the timer service will check for updates every minute and record the last synchronized filename in the local `/dbfile` to compare with the online file content.

The following is an example of restoring a file with the name `dashboard-2023-04-23-13:08:37.tar.gz`.

! [image](https://user-images.githubusercontent.com/92626977/233822466-c24e94f6-ba8a-47c9-b77d-aa62a56cc929.png)


## Manually restore the backup
* ssh into the container and run, tar.gz filename from the github backup repository, format: dashboard-2023-04-22-21:42:10.tar.gz
```
bash /dashboard/restore.sh <filename>
```
<img width="1209" alt="image" src="https://user-images.githubusercontent.com/92626977/233792709-fb37b79c-c755-4db1-96ec-1039309ff932.png">


## Migrating data
* Backup the `/dashboard` folder of the original Nezha and zip it up to `dashboard.tar.gz` file.
```
tar czvf dashboard.tar.gz /dashboard
```
* Download the file and put it into a private repository, the name of the repository should be exactly the same as <GH_REPO>, and edit the contents of README.md of the repository to `dashboard.tar.gz`.
* Deploy the new Nezha in this project, and fill in the variables completely. After the deployment is done, the auto-restore script will check every minute, and will restore automatically if it finds any new content, the whole process will take about 3 minutes.


## Main catalog files and descriptions
```
/dashboard/
|-- app                  # Nezha panel main program
|-- argo.json            # Argo tunnel json file, which records information about using the tunnel.
|-- argo.yml             # Argo tunnel yml file, used for streaming web, gRPC and ssh protocols under a single tunnel with different domains.
|-- backup.sh            # Backup data scripts
|-- restore.sh           # Restore backup scripts
|-- renew.sh             # Scripts to update backup and restore files online
|-- dbfile               # Record the name of the latest restore or backup file
|-- resource             # Folders of information on panel themes, languages, flags, etc.
|-- data
|   |-- config.yaml      # Configuration for the Nezha panel, e.g. Github OAuth2 / gRPC domain / port / TLS enabled or not.
|   `-- sqlite.db        # SQLite database file that records all severs and cron settings for the panel.
|-- entrypoint.sh        # The main script, which is executed after the container is run.
|-- nezha.csr            # SSL/TLS certificate signing request
|-- nezha.key            # Private key information for SSL/TLS certificate.
|-- nezha.pem            # SSL/TLS certificate file.
|-- cloudflared          # Cloudflare Argo tunnel main program.
|-- grpcwebproxy         # gRPC reverse proxy main program.
|-- caddy                # Caddy main program.
|-- Caddyfile            # Caddy config file.
`-- nezha-agent          # Nezha client, used to monitor the localhost.
```


## Acknowledgements for articles and projects by
* Robin, an enthusiastic sunrise crowd, for discussing the relationship between Nezha's server and client, which led to the birth of this project.
* Nezha website: https://nezha.wiki/ , TG Group: https://t.me/nezhamonitoring
* Common Poverty International Old Chinese Medicine: http://solitud.es/
* Akkia's Blog: https://blog.akkia.moe/
* Ayaka's Blog: https://blog.xn--pn1aul.org/
* HiFeng's Blog: https://www.hicairo.com/
* Intranet Penetration with Cloudflare Tunnel: https://blog.outv.im/2021/cloudflared-tunnel/
* How to add your own Runner host to GitHub Actions: https://cloud.tencent.com/developer/article/1756690
* github self-hosted runner addition and startup: https://blog.csdn.net/sinat_32188225/article/details/125978331
* How to export a file from a Docker image: https://www.pkslow.com/archives/extract-files-from-docker-image
* grpcwebproxy: https://github.com/improbable-eng/grpc-web/tree/master/go/grpcwebproxy
* Applexad's binary of Nezha's officially dashboard: https://github.com/applexad/nezha-binary-build


## Disclaimer
* This program is only for learning and understanding, non-profit purposes, please delete within 24 hours after downloading, not for any commercial purposes, text, data and images are copyrighted, if reproduced must indicate the source.
* Use of this program is subject to the deployment disclaimer. Use of this program must follow the deployment of the server location, the country and the user's country laws and regulations, the author of the program is not responsible for any misconduct of the user.