
# Stage 1
FROM alpine:latest AS build

# Install the Hugo go app.
RUN apk add --update hugo go git

WORKDIR /opt/HugoApp

# Copy Hugo config into the container Workdir.
COPY ./ .

# Run Hugo in the Workdir to generate HTML.
RUN hugo --minify --gc

# Stage 2
#FROM nginx:1.25-alpine
FROM cgr.dev/chainguard/nginx:latest

# Set workdir to the NGINX default dir.
WORKDIR /usr/share/nginx/html

# Copy HTML from previous build into the Workdir.
COPY --from=build /opt/HugoApp/public .

# Expose port 80
EXPOSE 8080/tcp
EXPOSE 8443/tcp
