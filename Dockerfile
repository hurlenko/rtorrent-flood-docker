ARG NODE_IMAGE=node:10-alpine

FROM ${NODE_IMAGE} as nodebuild


ENV FLOOD_DIR /usr/src/flood
WORKDIR ${FLOOD_DIR}

# Generate node_modules
# COPY package.json ./package.json
# COPY package-lock.json ./package-lock.json
RUN apk add --no-cache --virtual=build-dependencies \
  git \
  python \
  build-base \
  && git clone https://github.com/jfurrow/flood.git \
  && cd flood \
  && cp -R package.json package-lock.json client shared server ../ \
  && cd ../ \
  && npm install \
  && apk del --purge build-dependencies
  # && cp flood/config.docker.js ./config.js \
RUN npm run build \
  && npm install natives@1.1.6 \
  && npm prune --production \
  && rm -rf flood

# Build static assets and remove devDependencies.
# COPY client ./client
# COPY shared ./shared
# COPY config.docker.js ./config.js
# RUN npm run build && \
  # npm prune --production
# COPY server ./server

# Install runtime dependencies.
# RUN apk --no-cache add \
#   mediainfo

# # Hints for consumers of the container.
# EXPOSE 3000
# VOLUME ["/data"]



ENV PUID 0
ENV PGID 0

# Install rtorrent and su-exec
# Create necessary folders
# Forward Info & Error logs to std{out,err} (à la nginx)
RUN apk add --no-cache --update \
  mediainfo\
  rtorrent \
  su-exec \
  s6 \
  && mkdir -p \
  /dist \
  /config \
  /session \
  /socket \
  /watch/load \
  /watch/start \
  /downloads \
  && ln -sf /dev/stdout /var/log/rtorrent-info.log \
  && ln -sf /dev/stderr /var/log/rtorrent-error.log

VOLUME ["/config", "/session", "/socket", "/watch", "/downloads", "/data"]
# webui
EXPOSE 3000
# DHT, incoming connections
EXPOSE 49160/udp 49161/udp 49161/tcp

# Copy distribution rTorrent config for bootstrapping and entrypoint
COPY ./root /

RUN chmod +x /init /usr/local/bin/* /etc/s6.d/*/* /etc/s6.d/.s6-svscan/*

CMD ["/init"]