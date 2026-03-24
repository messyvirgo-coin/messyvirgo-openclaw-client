ARG BASE_IMAGE=openclaw-secure:local
FROM ${BASE_IMAGE}

ARG OPENCLAW_NPM_VERSION=11.11.1
USER root
RUN npm install -g "npm@${OPENCLAW_NPM_VERSION}" "mcporter"
RUN mv /usr/local/bin/mcporter /usr/local/bin/mcporter-real \
  && printf '%s\n' \
    '#!/usr/bin/env bash' \
    'exec /usr/local/bin/mcporter-real --config /home/node/.openclaw/mcporter.json "$@"' \
    > /usr/local/bin/mcporter \
  && chmod 0755 /usr/local/bin/mcporter
USER node
