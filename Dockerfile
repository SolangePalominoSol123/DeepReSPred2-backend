# Using ubuntu image as base
FROM alpine:3.15.0
#FROM alpine:3.15.0

# Set working directory
#WORKDIR /app
# Copy all files from current directory to working dir in image
#COPY . .
# install node modules and build assets
#RUN yarn install && yarn build

# nginx state for serving content
#FROM nginx:stable-alpine-perl
# Set working directory to nginx asset directory
#WORKDIR /usr/share/nginx/html
# Remove default nginx static assets
#RUN rm -rf ./*
# Copy static assets from builder stage and configuration
#COPY --from=builder /app/dist .
#COPY ./nginx-config/default.conf /default.conf

# Startup to be executable
#ENTRYPOINT ["nginx", "-g", "daemon off;"]