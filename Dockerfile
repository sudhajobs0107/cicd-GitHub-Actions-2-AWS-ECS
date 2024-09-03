# Stage 1: Build the application using an Apache server
FROM ubuntu as build

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y apache2 apache2-utils \
    && apt-get clean

RUN echo "Hello Fam From Sudha Yadav" > /var/www/html/index.html

# Stage 2: Set up Nginx as a reverse proxy
FROM nginx:alpine

# Copy the built application from the first stage
COPY --from=build /var/www/html /usr/share/nginx/html

# Remove the default Nginx configuration file
RUN rm /etc/nginx/conf.d/default.conf

# Add your custom Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
