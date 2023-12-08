FROM debian

WORKDIR /dashboard

RUN apt-get update &&\
    apt-get -y install openssh-server wget iproute2 vim git cron unzip supervisor nginx &&\
    git config --global core.bigFileThreshold 1k &&\
    git config --global core.compression 0 &&\
    git config --global advice.detachedHead false &&\
    git config --global pack.threads 1 &&\
    git config --global pack.windowMemory 50m &&\
    apt-get clean &&\
    rm -rf /var/lib/apt/lists/* &&\
    echo "#!/usr/bin/env bash\n\n\
bash <(wget -qO- https://raw.githubusercontent.com/fscarmen2/Argo-Nezha-Service-Container/main/init.sh)" > entrypoint.sh &&\
    chmod +x entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]