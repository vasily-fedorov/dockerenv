#!/usr/bin/env -S docker build . --tag=pydev --network=host --file
ARG IMAGE=ubuntu:24.04
FROM $IMAGE AS base
ARG PYTHON_VERSION=3.12
ARG USER_ID=${UID}
ARG USER_NAME=${USER}
ARG PROJECT=src
ARG BUILD_ROOT_SH=tmp
ARG BUILD_USER_SH=tmp

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# install pyenv and python packages
ENV DEBIAN_FRONTEND=noninteractive
RUN rm -f /etc/apt/apt.conf.d/docker-clean ; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt update && apt -y install --no-install-recommends --no-install-suggests \
    adduser python3 bash python3-venv python3-pip gcc \
    build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev curl git \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

RUN adduser --disabled-password --uid $USER_ID $USER_NAME

# pyenv setup
USER $USER_NAME
ENV PYENV_ROOT=/home/$USER_NAME/.pyenv
ENV PATH=$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH
WORKDIR /home/$USER_NAME/${PROJECT}
RUN curl https://pyenv.run | bash && CC=gcc pyenv install $PYTHON_VERSION
RUN pyenv global $PYTHON_VERSION && pyenv rehash
RUN pyenv virtualenv $PYTHON_VERSION ${PROJECT}

# project build
USER root
WORKDIR /root
COPY ${BUILD_ROOT_SH} ./build.sh
RUN sh build.sh

USER $USER_NAME
WORKDIR /home/$USER_NAME/${PROJECT}
COPY ${BUILD_USER_SH} ./build.sh
RUN sh build.sh
COPY ./requirements.txt .
RUN pip install -r requirements.txt
RUN pip install debugpy

# Expose the port that the application listens on.
EXPOSE 8000
EXPOSE 5678
# Run the application.
CMD ${CMD}
