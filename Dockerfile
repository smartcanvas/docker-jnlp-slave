FROM jenkinsci/slave
MAINTAINER Fabio Franco Uechi <fuechi@ciandt.com>

COPY jenkins-slave /usr/local/bin/jenkins-slave

USER root

ENV CLOUDSDK_CORE_DISABLE_PROMPTS=1
ARG GCLOUD_SDK_VERSION=138.0.0
ENV GCLOUD_SDK_URL=https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz
ENV CLOUDSDK_PYTHON_SITEPACKAGES 1
RUN echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers

RUN cd /opt \
	&& wget -q -O - $GCLOUD_SDK_URL |tar zxf - \
	&& /bin/bash -l -c "/opt/google-cloud-sdk/install.sh --usage-reporting=true --path-update=true --bash-completion=true --rc-path=/.bashrc --additional-components app-engine-java app-engine-python app kubectl alpha beta gcd-emulator pubsub-emulator cloud-datastore-emulator app-engine-go bigtable && exit" \
	&& /bin/bash -l -c "/opt/google-cloud-sdk/bin/gcloud --quiet config set component_manager/disable_update_check true && exit" \
	&& rm -rf /opt/google-cloud-sdk/.install/.backup

# Disable updater completely.
# Running `gcloud components update` doesn't really do anything in a union FS.
# Changes are lost on a subsequent run.
RUN sed -i -- 's/\"disable_updater\": false/\"disable_updater\": true/g' /opt/google-cloud-sdk/lib/googlecloudsdk/core/config.json

ENV PATH /opt/google-cloud-sdk/bin:$PATH

ENV DOCKER_BUCKET get.docker.com
ENV DOCKER_VERSION 1.12.5
ENV DOCKER_SHA256 0058867ac46a1eba283e2441b1bb5455df846144f9d9ba079e97655399d4a2c6

RUN set -x \
	&& curl -fSL "https://${DOCKER_BUCKET}/builds/Linux/x86_64/docker-${DOCKER_VERSION}.tgz" -o docker.tgz \
	&& echo "${DOCKER_SHA256} *docker.tgz" | sha256sum -c - \
	&& tar -xzvf docker.tgz \
	&& mv docker/* /usr/local/bin/ \
	&& rmdir docker \
	&& rm docker.tgz \
	&& docker -v

USER jenkins

# Metadata params
ARG VERSION
ARG VCS_REF
ARG BUILD_DATE

# Metadata
LABEL org.label-schema.vendor="Smart Canvas" \
      org.label-schema.url="http://smartcanvas.com" \
      org.label-schema.name="Jenkins slave" \
      org.label-schema.description="Jenkins slave with gcloud and docker pre installed" \    
      org.label-schema.version="${VERSION}" \
      org.label-schema.vcs-url="https://github.com/smartcanvas/docker-jnlp-slave.git" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.docker.schema-version="1.0"


ENTRYPOINT ["jenkins-slave"]