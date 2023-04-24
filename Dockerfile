FROM ghcr.io/naiba/nezha-dashboard

WORKDIR /dashboard

COPY entrypoint.sh /dashboard/

COPY sqlite.db /dashboard/data/

RUN apt-get update &&\
    apt-get -y install openssh-server wget iproute2 vim git cron unzip supervisor nginx &&\
    wget -O nezha-agent.zip https://github.com/naiba/nezha/releases/latest/download/nezha-agent_linux_$(uname -m | sed "s#x86_64#amd64#; s#aarch64#arm64#").zip &&\
    unzip nezha-agent.zip &&\
    wget -O cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$(uname -m | sed "s#x86_64#amd64#; s#aarch64#arm64#").deb &&\
    dpkg -i cloudflared.deb &&\
    rm -f nezha-agent.zip cloudflared.deb &&\
    touch /dbfile &&\
    chmod +x entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]