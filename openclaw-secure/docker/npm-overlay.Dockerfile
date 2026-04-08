ARG BASE_IMAGE=openclaw-secure:local
FROM ${BASE_IMAGE}

ARG OPENCLAW_NPM_VERSION=11.11.1
ARG MESSYVIRGO_CLI_VERSION=latest
USER root
RUN npm install -g "npm@${OPENCLAW_NPM_VERSION}" \
  && npm install -g "@messyvirgo/cli@${MESSYVIRGO_CLI_VERSION}"
USER node
