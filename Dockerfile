#!/usr/bin/env -S docker build . --tag=pydev --network=host --file
ARG IMAGE=ubuntu:24.04
FROM $IMAGE AS base
ARG PYTHON_VERSION=3.11.10
ARG USER_ID=1002
ARG USER_NAME=fvv
ARG PROJECT=.

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    adduser python3 bash python3-venv python3-pip gcc \
    build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev curl git \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev \
python3-debugpy
# https://github.com/pyenv/pyenv/wiki#suggested-build-environment
RUN adduser --disabled-password --uid $USER_ID $USER_NAME
WORKDIR /home/$USER_NAME
COPY ./build.sh ./build.sh
RUN sh build.sh
USER $USER_NAME
ENV PYENV_ROOT=/home/$USER_NAME/.pyenv
ENV PATH=$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH
WORKDIR /home/$USER_NAME/$PROJECT
RUN curl https://pyenv.run | bash && CC=gcc pyenv install $PYTHON_VERSION
RUN pyenv global $PYTHON_VERSION && pyenv rehash
COPY $PROJECT/requirements.txt .
RUN pyenv virtualenv $PYTHON_VERSION $PROJECT

#RUN pyenv activate $PROJECT
RUN pip install -r requirements.txt
RUN pip install debugpy
#RUN python manage.py migrate
# Expose the port that the application listens on.
EXPOSE 8000
EXPOSE 5678
# Run the application.
#ENTRYPOINT ["bash"]
#CMD ["-m","debugpy","--listen","0.0.0.0:5678", "manage.py", "runserver", "0.0.0.0:8000"]
CMD python manage.py migrate && python manage.py runserver 0.0.0.0:8000
#CMD ["python", "manage.py", "migrate","&&", "python", "manage.py" "runserver", "0.0.0.0:8000"]
