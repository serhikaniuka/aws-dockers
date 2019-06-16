#please build before nginx image with command "docker build -t nginx1.16 ./"

FROM nginx1.16

LABEL maintainer="Serhiy Kanyuka <serhiy@kanyuka.info>"

COPY conf/kanyuka_info.conf /etc/nginx/sites-enabled/kanyuka_info.conf
COPY conf/krechet_net.conf /etc/nginx/sites-enabled/krechet_net.conf
COPY conf/nginx.conf /etc/nginx/nginx.conf

EXPOSE 80 443 7443 8443

CMD ["nginx", "-g", "daemon off;"]
