# Argo-Nezha-Service-Container

Nezha server over Argo tunnel 

Documentation: English version | [中文版](https://github.com/fscarmen2/Argo-Nezha-Service-Container/blob/main/README.md)

* * * *

# Catalog

- [Project Features](README.md#project-features)
- [Variables to be used](README.md#prepare-variables-to-be-used)
- [PaaS Deployment Example](README.md#paas-deployment-example)
- [VPS Deployment Example](README.md#vps-deployment-example)
- [Client Access](README.md#client-access)
- [SSH Access](README.md#ssh-access)
- [Auto Restore Backup](README.md#automatically-restore-backups)
- [Manual Restore Backup](README.md#manually-restore-the-backup)
- [Migrating data](README.md#migrating-data)
- [Main Directory Files and Descriptions](README.md#main-catalog-files-and-descriptions)
- [Acknowledgment of articles and projects by the following authors](README.md#acknowledgements-for-articles-and-projects-by)
- [Disclaimer](README.md#disclaimer)

* * *

## Project Features.
* Wider scope of application --- As long as there is a network connection, Nezha server can be installed, such as Nas Virtual Machine, Container PaaS, etc.
* Argo tunnel breaks through the restriction of requiring a public network portal --- The traditional Nezha requires two public network ports, one for panel visiting and the other for client reporting, this project uses Cloudflare Argo tunnels and uses intranet tunneling.
* IPv4 / v6 with higher flexibility --- The traditional Nezha needs to deal with IPv4/v6 compatibility between server and client, and also needs to resolve mismatches through tools such as warp. However, this project does not need to consider these issues at all, and can be docked arbitrarily, which is much more convenient and easy!
* One Argo tunnel for multiple domains and protocols --- Create an intranet-penetrating Argo tunnel for three domains (hostname) and protocols, which can be used for panel access (http), client reporting (tcp) and ssh (optional).
* Nginx reverse proxy gRPC data port --- with a certificate for tls termination, then Argo's tunnel configuration with https service pointing to this reverse proxy, enable http2 back to the source, grpc(nezha)->h2(nginx)->argo->cf cdn edge->agent
* Daily automatic backup --- every day at 04:00 BST, the entire Nezha panel folder is automatically backed up to a designated private github repository, including panel themes, panel settings, probe data and tunnel information, the backup retains nearly 5 days of data; the content is so important that it must be placed in the private repository.
* Automatic daily panel update -- the latest official panel version is automatically detected every day at 4:00 BST, and updated when there is an upgrade.
* Manual/automatic restore backup --- check the content of online restore file once a minute, and restore immediately when there is any update.
* Default built-in local probes --- can easily monitor their own server information
* More secure data --- Argo Tunnel uses TLS encrypted communication to securely transmit application traffic to the Cloudflare network, improving application security and reliability. In addition, Argo Tunnel protects against network threats such as IP leaks and DDoS attacks.

<img width="1298" alt="image" src="https://github.com/fscarmen2/Argo-Nezha-Service-Container/assets/92626977/6535a060-2138-4c72-9ffa-1175dc6f5c25.png">


## Prepare variables to be used
* Easily get Argo tunnel information through Cloudflare Json generation network: https://fscarmen.cloudflare.now.cc

<img width="772" alt="image" src="https://github.com/fscarmen2/Argo-Nezha-Service-Container/assets/92626977/98f2c80c-8d45-4c70-b46e-70f552e0b572">

* Visit Cloudflare website, add the domain name of the client reporting data (tcp) and ssh (optional) in the `DNS` record of the corresponding domain, and turn on Orange Cloud to enable CDN.

<img width="1629" alt="image" src="https://github.com/fscarmen2/Argo-Nezha-Service-Container/assets/92626977/39ecc388-e66b-44a2-a339-c80e9d7ed8e2">

<img width="1632" alt="image" src="https://github.com/fscarmen2/Argo-Nezha-Service-Container/assets/92626977/1ad2042e-46e6-41c3-9c16-14dc8699ee72">

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


## PaaS Deployment Example
Image `fscarmen/argo-nezha:latest`, supports amd64 and arm64 architectures.

Variables used 
  | Variable Name | Required | Remarks |
  | ------------ | ------ | ---- | 
  | GH_USER | Yes | github username for panel admin authorization | 
  | GH_CLIENTID | yes | apply on github |
  | GH_CLIENTSECRET | yes | apply on github |
  | GH_BACKUP_USER | No | The github username for backing up Nezha's server-side database on github, if not filled in, it is the same as the account GH_USER for panel management authorization |
  | GH_REPO | No | The github repository for backing up Nezha's server-side database files on github |
  | GH_EMAIL | No | github's mailbox for git push backups to remote repositories |
  | GH_PAT | No | github's PAT |
  | ARGO_JSON | Yes | Argo Json from https://fscarmen.cloudflare.now.cc |
  | DATA_DOMAIN | Yes | Client-server communication argo domain name |
  | WEB_DOMAIN | Yes | Panel argo domain |
  | SSH_DOMAIN | No | ssh for argo domain |
  | SSH_PASSWORD | no | password for ssh, only works after setting SSH_JSON, default password |

Koyeb

[![Deploy to Koyeb](https://www.koyeb.com/static/images/deploy/button.svg)](https://app.koyeb.com/deploy?type=docker&name=nezha&ports=80;http;/&env[GH_USER]=&env[GH_CLIENTID]=&env[GH_CLIENTSECRET]=&env[GH_REPO]=&env[GH_EMAIL]=&env[GH_PAT]=&env[ARGO_JSON]=&env[DATA_DOMAIN]=&env[WEB_DOMAIN]=&env[SSH_DOMAIN]=&env[SSH_PASSWORD]=&image=docker.io/fscarmen/argo-nezha)

<img width="927" alt="image" src="https://user-images.githubusercontent.com/92626977/231088411-fbac3e6e-a8a6-4661-bcf8-7c777aa8ffeb.png">
<img width="1011" alt="image" src="https://github.com/fscarmen2/Argo-Nezha-Service-Container/assets/92626977/61fad972-1be9-4e8d-829a-8faea0c8ed64">
<img width="763" alt="image" src="https://github.com/fscarmen2/Argo-Nezha-Service-Container/assets/92626977/ca294962-f10e-4f4c-b69c-9e95d3d25cac">
<img width="1214" alt="image" src="https://github.com/fscarmen2/Argo-Nezha-Service-Container/assets/92626977/ddabdf3a-ca63-4523-b839-62c4d4c0caf2">
<img width="881" alt="image" src="https://github.com/fscarmen2/Argo-Nezha-Service-Container/assets/92626977/e623f92d-878f-4eb8-9dfe-55b59770ba2f">


## VPS Deployment Example
* Note: ARGO_JSON= must be followed by single quotes, which cannot be removed.
* If the VPS is IPv6 only, please install WARP IPv4 or dual-stack first: https://github.com/fscarmen/warp
* The backup directory is the dashboard folder in the current path.

### docker deployment

```
docker run -dit \
           --name nezha_dashboard \
           --restart always \
           -e GH_USER=<fill in github username> \
           -e GH_EMAIL=<fill in github email> \
           -e GH_PAT=<fill in the obtained> \
           -e GH_REPO=<fill in customized> \
           -e GH_CLIENTID=<fill in acquired> \
           -e GH_CLIENTSECRET=<fill in acquired> \
           -e ARGO_JSON='<fill in acquired>' \
           -e WEB_DOMAIN=<fill in customized> \
           -e DATA_DOMAIN=<fill in customized> \
           -e SSH_DOMAIN=<fill in customized> \
           -e SSH_PASSWORD=<insert customized> \
           fscarmen/argo-nezha
```

### docker-compose deployment
```
version: '3.8'
services.
    argo-nezha.
        image: fscarmen/argo-nezha
        container_name: nezha_dashboard
        restart: always
        environment:
            - GH_USER=<fill in github username>
            - GH_EMAIL=<fill in your github email>
            - GH_PAT=<<fill in obtained>
            - GH_REPO=<fill in customized>
            - GH_CLIENTID=<fill in obtained>
            - GH_CLIENTSECRET=<fill in fetched>
            - ARGO_JSON='<fill in acquired>'
            - WEB_DOMAIN=<fill customized>
            - DATA_DOMAIN=<fill in customized>
            - SSH_DOMAIN=<insert customized>
            - SSH_PASSWORD=<fill customized>
```


## Client Access
Transfer via gRPC, no additional configuration required. Use the installation method given in the panel, for example
```
curl -L https://raw.githubusercontent.com/naiba/nezha/master/script/install.sh -o nezha.sh && chmod +x nezha.sh && sudo ./nezha.sh install_agent data.seales.nom.za 443 eAxO9IF519fKFODlW0 --tls
```


## SSH access
* Take macOS + WindTerm as an example, and other SSH tools depending on the one used, combined with the official documentation: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/use_cases/ssh /#2-connect-as-a-user
* Official cloudflared download: https://github.com/cloudflare/cloudflared/releases
* The following are examples of input commands
```
<filepath>/cloudflared access ssh --hostname ssh.seals.nom.za
```

<img width="828" alt="image" src="https://github.com/fscarmen2/Argo-Nezha-Service-Container/assets/92626977/25c7bd31-21b5-4684-b1cf-d6d6e0e85058">
<img width="830" alt="image" src="https://github.com/fscarmen2/Argo-Nezha-Service-Container/assets/92626977/20a8661c-90b8-4b77-a046-0a2e42d7fee5">
<img width="1201" alt="image" src="https://github.com/fscarmen2/Argo-Nezha-Service-Container/assets/92626977/3146b2e2-f988-487f-ab63-00218eb4d570">


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
.
|-- dashboard
|   |-- app                  # Nezha panel main program
|   |-- argo.json            # Argo tunnel json file, which records information about using the tunnel.
|   |-- argo.yml             # Argo tunnel yml file, used for streaming web, gRPC and ssh protocols under a single tunnel with different domains.
|   |-- backup.sh            # Backup data scripts
|   |-- data
|   |   |-- config.yaml      # Configuration for the Nezha panel, e.g. Github OAuth2 / gRPC domain / port / TLS enabled or not.
|   |   `-- sqlite.db        # SQLite database file that records all severs and cron settings for the panel.
|   |-- entrypoint.sh        # The main script, which is executed after the container is run.
|   |-- nezha-agent          # Nezha client, used to monitor the localhost.
|   |-- nezha.csr            # SSL/TLS certificate signing request
|   |-- nezha.key            # Private key information for SSL/TLS certificate.
|   |-- nezha.pem            # SSL/TLS Privacy Enhancement Email
|   `-- restore.sh           # Restore backup scripts
|-- dbfile                   # Record the name of the latest restore or backup file
`-- version                  # Record the current panel app version
```


## Acknowledgements for articles and projects by
* Robin, an enthusiastic sunrise crowd, for discussing the relationship between Nezha's server and client, which led to the birth of this project.
* Nezha website: https://nezha.wiki/ , TG Group: https://t.me/nezhamonitoring
* Common Poverty International Old Chinese Medicine: http://solitud.es/
* Akkia's Blog: https://blog.akkia.moe/
* HiFeng's Blog: https://www.hicairo.com/
* Intranet Penetration with Cloudflare Tunnel: https://blog.outv.im/2021/cloudflared-tunnel/
* How to add your own Runner host to GitHub Actions: https://cloud.tencent.com/developer/article/1756690
* github self-hosted runner addition and startup: https://blog.csdn.net/sinat_32188225/article/details/125978331


## Disclaimer
* This program is only for learning and understanding, non-profit purposes, please delete within 24 hours after downloading, not for any commercial purposes, text, data and images are copyrighted, if reproduced must indicate the source.
* Use of this program is subject to the deployment disclaimer. Use of this program must follow the deployment of the server location, the country and the user's country laws and regulations, the author of the program is not responsible for any misconduct of the user.