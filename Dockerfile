FROM jenkinsci/slave
MAINTAINER Fabio Franco Uechi <fuechi@ciandt.com>

COPY jenkins-slave /usr/local/bin/jenkins-slave

USER root

ENV CLOUDSDK_CORE_DISABLE_PROMPTS=1
ARG GCLOUD_SDK_VERSION=126.0.0
ENV GCLOUD_SDK_URL=https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz
ENV CLOUDSDK_PYTHON_SITEPACKAGES 1
RUN echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers

RUN cd /opt \
	&& wget -q -O - $GCLOUD_SDK_URL |tar zxf - \
	&& /bin/bash -l -c "/opt/google-cloud-sdk/install.sh --usage-reporting=true --path-update=true --bash-completion=true --rc-path=/.bashrc --disable-installation-options && exit" \
	&& /bin/bash -l -c "/opt/google-cloud-sdk/bin/gcloud --quiet config set component_manager/disable_update_check true && exit" \
	&& rm -rf /opt/google-cloud-sdk/.install/.backup

ENV PATH /opt/google-cloud-sdk/bin:$PATH

ENV DOCKER_BUCKET get.docker.com
ENV DOCKER_VERSION 1.12.1
ENV DOCKER_SHA256 05ceec7fd937e1416e5dce12b0b6e1c655907d349d52574319a1e875077ccb79

RUN set -x \
	&& curl -fSL "https://${DOCKER_BUCKET}/builds/Linux/x86_64/docker-${DOCKER_VERSION}.tgz" -o docker.tgz \
	&& echo "${DOCKER_SHA256} *docker.tgz" | sha256sum -c - \
	&& tar -xzvf docker.tgz \
	&& mv docker/* /usr/local/bin/ \
	&& rmdir docker \
	&& rm docker.tgz \
	&& docker -v

USER jenkins

ENTRYPOINT ["jenkins-slave"]