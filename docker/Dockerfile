ARG BASE_IMAGE=br:fm-default-fmdeps
FROM $BASE_IMAGE

# Install jq, locales, and configure locales.
RUN sudo apt-get update -y -q \
 && sudo apt-get install -y -q jq locales \
 && sudo apt-get clean \
 && sudo rm -rf /var/lib/apt/lists/* \
 && sudo sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
 && sudo locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Copy the whole workspace to [/home/coq/skylabs-fm].
COPY docker/latest.tar.gz /home/coq/latest.tar.gz

# Extract the workspace from the archive, deleting the archive.
WORKDIR /home/coq
RUN tar -xf latest.tar.gz
RUN rm latest.tar.gz

# Building and installing everything from the workspace root.
WORKDIR /home/coq/latest
RUN dune build --display=short @install
RUN dune install
WORKDIR /home/coq

# Copying the metadata and removing the workspace files after install.
RUN cp latest/skylabs-fm_commit_hash.txt .
RUN rm -rf latest
