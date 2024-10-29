ARG NODE_VERSION=18

FROM node:${NODE_VERSION}-slim as build

ARG SOURCE_FOLDER
COPY ./${SOURCE_FOLDER} /app

WORKDIR /app
RUN npm install

# --- Simple audit (fail -> force fix -> check)
RUN npm audit || npm audit fix --force && npm audit

FROM node:${NODE_VERSION}-slim

COPY --from=build /app /app

WORKDIR /app

EXPOSE 3000/tcp
CMD ["node", "./bin/www"]
