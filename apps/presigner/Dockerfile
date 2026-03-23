ARG PYTHON_VERSION='3.13'
ARG COMPONENT='presigner'

FROM ghcr.io/astral-sh/uv:python${PYTHON_VERSION}-trixie AS builder
ENV \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_NO_DEV=1
WORKDIR /app
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --locked --no-install-project

FROM public.ecr.aws/docker/library/python:${PYTHON_VERSION}-trixie
# Setup tini + system user
ARG TINI_VERSION='v0.19.0'
ARG TARGETARCH
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-${TARGETARCH} /tini
RUN chmod +x /tini && useradd -m -r bot
# Copy the application from the builder
COPY --from=builder --chown=bot:bot /app /app
# Copy entrypoint + source
COPY --chown=bot:bot scripts/entrypoint.sh /app/entrypoint.sh
ARG COMPONENT
COPY --chown=bot:bot src/${COMPONENT} /app/${COMPONENT}
USER bot
ARG GIT_HASH
ENV GIT_HASH=${GIT_HASH:-local} PORT=80 COMPONENT=${COMPONENT} PATH="/app/.venv/bin:$PATH"

ENTRYPOINT ["/tini", "--"]
CMD ["/app/entrypoint.sh"]
