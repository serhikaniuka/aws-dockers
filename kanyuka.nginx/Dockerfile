#please build before nginx image with command "docker build -t nginx1.16 ./"

FROM nginx1.16

LABEL maintainer="Serhiy Kanyuka <serhiy@kanyuka.info>"

EXPOSE 80 443 7443 8443

CMD ["nginx", "-g", "daemon off;"]
