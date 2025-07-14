# Stage 1: Build the web assets
FROM node:16-alpine as builder

# Set up the working directory
WORKDIR /app


# Install Clojure, Node.js and Yarn
RUN apk update && \
    apk add curl bash openjdk16-jdk git && \
    curl -L -o /tmp/clojure-installer.sh https://download.clojure.org/install/linux-install-1.11.1.1165.sh && \
    bash /tmp/clojure-installer.sh && \
    rm /tmp/clojure-installer.sh

# Copy package files and install dependencies
COPY package.json yarn.lock ./

RUN yarn install --frozen-lockfile

# Copy the rest of the application source code
COPY . .

# Compile the web assets for production
RUN yarn prod

# Stage 2: Serve the web assets with Nginx
FROM nginx:latest

# Copy the Nginx configuration file
COPY nginx-web.conf /etc/nginx/conf.d/default.conf

# Copy the built web assets from the builder stage
COPY --from=builder /app/resources/public /usr/share/nginx/html

# Expose the web server port
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
