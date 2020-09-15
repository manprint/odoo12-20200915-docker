FROM ubuntu:18.04
LABEL mantainer="Fabio Pierri"

ENV container docker
ENV DEBIAN_FRONTEND noninteractive

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN set -xev; \
        apt-get update \
        && apt-get upgrade -y \
        && apt-get install -y \
            ca-certificates \
            dirmngr \
            fonts-noto-cjk \
            gnupg \
            node-less \
            python3 \
            python3-dev \
            libsasl2-dev \
            libldap2-dev \
            libssl-dev \
            python3-pip \
            python3-phonenumbers \
            python3-pyldap \
            python3-qrcode \
            python3-renderpm \
            python3-setuptools \
            python3-vobject \
            python3-watchdog \
            python3-babel \
            python3-decorator \
            python3-docutils \
            python3-feedparser \
            python3-gevent \
            python3-html2text \
            python3-jinja2 \
            python3-libsass \
            python3-lxml \
            python3-mako \
            python3-mock \
            python3-ofxparse \
            python3-passlib \
            python3-psutil \
            python3-psycopg2 \
            python3-pydot \
            python3-pyparsing \
            python3-pypdf2 \
            python3-reportlab \
            python3-requests \
            python3-serial \
            python3-suds \
            python3-usb \
            python3-vatnumber \
            python3-werkzeug \
            python3-xlsxwriter \
            python3-chardet \
            python3-xlrd \
            python3-codicefiscale \
            python3-pyxb \
            python3-asn1crypto \
            python3-unidecode \
            python3-rsa \
            python3-suds \
            python3-tz \
            python3-tzlocal \
            python3-pika \
            libxml2 \
            libxml2-dev \
            libxslt-dev \
            xz-utils \
            nano \
            wget \
            sudo \
            curl \
            locales \
            tzdata \
            iputils-ping \
            net-tools \
            telnet \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*

# Setup timezone and locale
ENV TZ=Europe/Rome

RUN set -xev; \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone

RUN set -xev && \
    dpkg-reconfigure --frontend=noninteractive tzdata && \
    sed -i -e 's/# it_IT.UTF-8 UTF-8/it_IT.UTF-8 UTF-8/' /etc/locale.gen && \
    echo 'LANG="it_IT.UTF-8"'>/etc/default/locale && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=it_IT.UTF-8

ENV LANG it_IT.UTF-8
ENV LANGUAGE it_IT.UTF-8
ENV LC_ALL it_IT.UTF-8

RUN set -xev; \
    wget http://ftp.it.debian.org/debian/pool/main/libj/libjpeg-turbo/libjpeg62-turbo_1.5.2-2+b1_amd64.deb; \
    apt install /libjpeg62-turbo_1.5.2-2+b1_amd64.deb

RUN set -xev; \
        apt-get update \
        && curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.stretch_amd64.deb \
        && echo '7e35a63f9db14f93ec7feeb0fce76b30c08f2057 wkhtmltox.deb' | sha1sum -c - \
        && apt-get install -y ./wkhtmltox.deb \
        && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# install latest postgresql-client-10
RUN set -xev; \
    echo 'deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main' > etc/apt/sources.list.d/pgdg.list \
    && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - \
    && sudo apt-get update \
    && apt-get install -y postgresql-client-10 \
    && rm -rf /var/lib/apt/lists/*

# install node8
RUN set -xev; \
    curl -sL https://deb.nodesource.com/setup_8.x -o nodesource_setup.sh; \
    bash nodesource_setup.sh

RUN set -xev; \
    apt-get update \
    && apt-get install -y nodejs build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN set -xev; npm install -g rtlcss

# Install Odoo
ENV ODOO_VERSION 12.0
ARG ODOO_RELEASE=20200915
ARG ODOO_SHA=88c54e723d325532500862182e7f1140d1ad8f69
RUN set -xev; \
        curl -o odoo.deb -sSL http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/odoo_${ODOO_VERSION}.${ODOO_RELEASE}_all.deb \
        && echo "${ODOO_SHA} odoo.deb" | sha1sum -c - \
        && dpkg --force-depends -i odoo.deb \
        && apt-get update \
        && apt-get -y install -f \
        && rm -rf /var/lib/apt/lists/* odoo.deb

# Copy entrypoint script and Odoo configuration file
COPY ./entrypoint.sh /
COPY ./odoo.conf /etc/odoo/
RUN set -xev; chown odoo /etc/odoo/odoo.conf

# Install python requirements with pip user odoo
COPY ./requirements.txt /requirements.txt
USER odoo
RUN set -xev; pip3 install -r /requirements.txt
USER root

# Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
RUN set -xev; \
    mkdir -p /mnt/extra-addons \
    && chown -R odoo /mnt/extra-addons

VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Expose Odoo services
EXPOSE 8069 8071 8072

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

COPY wait-for-psql.py /usr/local/bin/wait-for-psql.py

# Set default user when running the container
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
