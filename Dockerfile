FROM ghcr.io/naiba/nezha-dashboard

WORKDIR /dashboard

COPY files/* .

RUN apt-get update &&\
    apt-get -y install openssh-server curl wget iproute2 npm &&\
    npm install -g pm2 &&\
    wget -O cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb &&\
    dpkg -i cloudflared.deb &&\
    rm -f cloudflared.deb &&\
    chmod +x entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]