FROM nginx:stable-alpine-slim

# Kopieer static site
COPY anna-static/ /usr/share/nginx/html/

# Kopieer nginx.conf
COPY nginx.conf /etc/nginx/nginx.conf

# Rechten
RUN chown -R nginx:nginx /etc/nginx /usr/share/nginx/html

USER nginx
