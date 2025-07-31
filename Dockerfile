FROM node:20-slim AS dev
ENV NODE_NO_WARNINGS=1
RUN apt update && \
    apt install -y g++ git libimagequant-dev libpng-dev make pkg-config && \
    npm install -g @quasar/cli @quasar/icongenie && \
    mkdir /app && chown node:node /app
WORKDIR /app
USER node
ENV PORT=9000
EXPOSE $PORT
VOLUME [ "/app" ]
CMD [ "quasar", "dev", "-m", "spa" ]

FROM node:20-slim AS build
RUN npm install -g @quasar/cli
WORKDIR /app
COPY . .
RUN npm install --omit-dev
ENV CALLMYBOT_BOT_ID=9XU87bsY4VT645dC5gTyuT
ENV CALLMYBOT_URL=https://widget.callmybot.app/index.js
ENV NODE_ENV=production
RUN quasar build -m spa

FROM nginx:alpine
RUN rm /usr/share/nginx/html/index.html
COPY --from=build /app/dist/spa /usr/share/nginx/html
