#!/usr/bin/env -S docker build . --tag=dockerenv --network=host --file
ARG IMAGE=ubuntu:24.04
FROM $IMAGE AS base
ARG PYTHON_VERSION=3.12
ARG USER_ID=${UID}
ARG USER_NAME=${USER}
ARG BUILD_SH=""


ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive

RUN rm -f /etc/apt/apt.conf.d/docker-clean ; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

# pyenv setup
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt update && apt -y install --no-install-recommends --no-install-suggests \
    adduser sudo python3 bash python3-venv python3-pip gcc \
    build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev curl git \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
RUN adduser --disabled-password --uid $USER_ID $USER_NAME && adduser $USER_NAME sudo
RUN echo "$USER_NAME ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers.d/$USER_NAME
USER $USER_NAME
ENV PYENV_ROOT=/home/$USER_NAME/.pyenv
ENV PATH=$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH
WORKDIR /workspace
RUN curl https://pyenv.run | bash && CC=gcc pyenv install $PYTHON_VERSION
RUN pyenv global $PYTHON_VERSION && pyenv rehash
RUN pyenv virtualenv $PYTHON_VERSION workspace

# project build
USER $USER_NAME
COPY . .
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    sh $BUILD_SH

# Expose the port that the application listens on.
EXPOSE 8000
EXPOSE 5678
# Run the application.
CMD ${CMD}
