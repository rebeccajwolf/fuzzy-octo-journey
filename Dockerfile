FROM python:3.10-slim-bullseye AS build

ENV DEBIAN_FRONTEND=noninteractive \
    TZ="America/New_York" \
    PYTHONUNBUFFERED=1 \
    RUN_ON_START="true"

RUN apt-get update && apt-get install -yq --no-install-recommends \
    git curl bash tzdata locales && apt-get clean

WORKDIR /app
RUN git clone -b debian https://github.com/rebeccajwolf/musical-octo-barnacle.git .
COPY . .
RUN python -m venv .venv && . .venv/bin/activate && pip install -r requirements.txt

COPY . .
RUN chown -R 1000:1000 /app



FROM selenium/standalone-chrome:128.0.6613.119-chromedriver-128.0.6613.119

ENV DEBIAN_FRONTEND=noninteractive \
    TZ="America/New_York" \
    PYTHONUNBUFFERED=1 \
    RUN_ON_START="true" \
    SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.2.33/supercronic-linux-amd64 \
    SUPERCRONIC_SHA1SUM=71b0d58cc53f6bd72cf2f293e09e294b79c666d8 \
    SUPERCRONIC=supercronic-linux-amd64 \
    PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/user/.local/bin:${PATH}"

WORKDIR /app

COPY --from=build /app/.venv /app/.venv
COPY --from=build /app/ .

USER root

RUN apt-get install -yq supervisor \
    && curl -fsSLO "$SUPERCRONIC_URL" \
    && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
    && chmod +x "$SUPERCRONIC" \
    && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
    && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic \
    && ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create user and set up workspace
RUN groupadd -g 1000 usergroup && useradd -m -u 1000 -g 1000 user

USER user
COPY --chown=user . .
RUN chmod +x /app/entrypoint.sh /app/run_daily.sh

EXPOSE 7860

ENTRYPOINT ["/app/entrypoint.sh"]

CMD ["sh", "-c", "/usr/bin/supervisord -n && \
    if [ \"$RUN_ON_START\" = \"true\" ]; then bash run_daily.sh >/proc/1/fd/1 2>/proc/1/fd/2; fi"]
