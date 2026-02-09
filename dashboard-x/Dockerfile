# X Monitor Dashboard — minimal Node 20 image
FROM node:20-alpine
WORKDIR /app
COPY server.js ./
COPY public ./public/
ENV NODE_ENV=production
EXPOSE 18788
ENV DASHBOARD_X_PORT=18788
CMD ["node", "server.js"]
