# syntax=docker/dockerfile:1
ARG PYTHON_VERSION=3.11.10
FROM python:${PYTHON_VERSION}-slim AS base
ARG USER_ID
ARG USER_NAME

# Prevents Python from writing pyc files.
ENV PYTHONDONTWRITEBYTECODE=1

# Keeps Python from buffering stdout and stderr to avoid situations where
# the application crashes without emitting any logs due to buffering.
ENV PYTHONUNBUFFERED=1

# Create a non-privileged user that the app will run under.
RUN <<EOF
    adduser --disabled-password --uid $USER_ID $USER_NAME
EOF
# Download dependencies as a separate step to take advantage of Docker's caching.
# Leverage a cache mount to /root/.cache/pip to speed up subsequent builds.
# Leverage a bind mount to requirements.txt to avoid having to copy them into
# into this layer.
#RUN --mount=type=cache,target=/root/.cache/pip \
#    --mount=type=bind,source=requirements.txt,target=requirements.txt \
#    python -m pip install -r requirements.txt
WORKDIR /tmp
COPY ./build.sh ./build.sh
RUN sh build.sh
# Copy the source code into the container.

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY $PROJECT/requirements.txt .
RUN pip install -r requirements.txt
#COPY ./requirements.txt ./requirements.txt
#RUN pip install -r requirements.txt
WORKDIR /usr/src
# Switch to the non-privileged user to run the application.
USER $USER_NAME

# Expose the port that the application listens on.
EXPOSE 8000

# Run the application.
ENTRYPOINT ["python"]
CMD ["manage.py", "runserver", "0.0.0.0:8000"]
#CMD ["main.py"]
