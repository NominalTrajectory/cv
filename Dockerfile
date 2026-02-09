FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    texlive-latex-base \
    texlive-latex-extra \
    texlive-xetex \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    lmodern \
    imagemagick \
    git \
    ca-certificates \
    make \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY src/fonts /usr/local/share/fonts/
RUN fc-cache -f -v

WORKDIR /work
