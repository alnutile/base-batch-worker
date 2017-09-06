FROM python

#https://github.com/shipping-docker/dockerized-app/blob/master/docker/app/Dockerfile
MAINTAINER Alfred Nutile

RUN pip install requests

WORKDIR /app
CMD ["python", "--help"]

COPY packaged /app