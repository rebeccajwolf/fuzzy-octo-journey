FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive \
    TZ="America/New_York" \
    PYTHONUNBUFFERED=1 \
    RUN_ON_START="true"

ARG CHROME_VERSION="128.0.6613.119-1"

USER root


RUN apt-get update && \
    apt-get upgrade -yq && \
    apt-get install -qqy --no-install-recommends \
    xvfb \
    git \
    bash \
    tzdata \
    locales \
    dbus \
    wget \
    curl \
    gnupg \
    unzip \
    fonts-liberation \
    libappindicator3-1 \
    jq \
    libffi-dev \
    zlib1g-dev \
    liblzma-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libnss3 \
    libxss1 \
    libatk-bridge2.0-0 \
    libgtk-3-0 \
    libgbm-dev \
    python3-dev \
    python3-pip \
    python3-venv \
    supervisor \
    coreutils


RUN ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata


RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -

RUN wget -q -O /tmp/chrome.deb https://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_${CHROME_VERSION}_amd64.deb && \
	apt-get install -yq /tmp/chrome.deb && \
	rm /tmp/chrome.deb && \
	google-chrome --version




RUN useradd -m -u 1000 user

ENV PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/user/.local/bin:${PATH}"
USER user
WORKDIR /app
RUN git clone -b debian https://github.com/rebeccajwolf/musical-octo-barnacle.git .
RUN python3 -m venv .venv && . .venv/bin/activate
COPY --chown=user:user . /app
RUN /app/.venv/bin/pip install -r requirements.txt

USER root
RUN LATEST_CHROMEDRIVER_URL=$(curl -s https://googlechromelabs.github.io/chrome-for-testing/128.0.6613.119.json | jq -r '.downloads.chromedriver[0].url') \
    && wget -q -O /tmp/chromedriver.zip $LATEST_CHROMEDRIVER_URL \
    && unzip /tmp/chromedriver.zip -d /usr/bin/ \
    && mv /usr/bin/chromedriver-linux64/chromedriver /app/chromedriver \
    && chmod +x /app/chromedriver \
    && rm /tmp/chromedriver.zip
  
RUN chown -R user:user /app
RUN chown -R user:user /var/log
USER user
RUN chmod +x /app/entrypoint.sh

# Set the entrypoint to our entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]