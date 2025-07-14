# Stage 1: Build the application
FROM openjdk:16-jdk-slim as builder

# Install Node.js, Yarn, and Clojure
RUN apt-get update && \
    apt-get install -y curl bash git && \
    curl -sL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn && \
    curl -L -o /tmp/clojure-installer.sh https://download.clojure.org/install/linux-install-1.11.1.1165.sh && \
    bash /tmp/clojure-installer.sh && \
    rm /tmp/clojure-installer.sh

# Set up the working directory
WORKDIR /app

# Copy package files and install dependencies
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# Copy the rest of the application source code
COPY . .

# Compile the server code and create the uberjar
RUN yarn server:compile
RUN yarn server:uberjar

# Stage 2: Create the final image
FROM openjdk:16

# Create the application directory
RUN mkdir -p /srv/athens/db

# Copy the built JAR and the run script from the builder stage
COPY --from=builder /app/target/athens-lan-party-standalone.jar /srv/athens/
COPY --from=builder /app/script/docker-run-lan-party.sh /srv/athens/

# Set the working directory
WORKDIR /srv/athens/

# Expose the application port
EXPOSE 3010

# Set the command to run the application
CMD ["/srv/athens/docker-run-lan-party.sh"]
