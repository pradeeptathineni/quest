# Version 19 of node allows for many use cases
# https://www.docker.com/blog/how-to-use-the-node-docker-official-image/
# 19.8-bullseye-slim has the lowest amount of vulnerabilities according to docker scan
FROM node:19.8-bullseye-slim

# Removing unneeded development dependencies reduces image bloat
# RUN npm prune --omit=dev

# Incorporate secret word
ENV SECRET_WORD "TwelveFactor"

# Create and change work directory
WORKDIR /usr/src/app

# Copy app package.json
COPY ../package.json .

# Install dependencies
RUN npm install

# Copy app directory
COPY . .

# Expose ports
EXPOSE 3000

# Start node app
CMD ["npm", "run", "start"]