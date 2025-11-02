FROM node:24 AS builder

WORKDIR /src

COPY ./website/ /src/

RUN npm install
RUN npm run build
RUN ls -lah /src/dist

FROM nginx:1.29.3-alpine-slim

COPY --from=builder /src/dist/*  /usr/share/nginx/html