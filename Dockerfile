FROM java:8-jdk-alpine
MAINTAINER Fabio Franco Uechi <fuechi@ciandt.com>

ENV HOME /home/jenkins
ENV JENKINS_REMOTING_VERSION=2.60
RUN adduser -S -h $HOME jenkins jenkins

RUN apk add --update --no-cache curl \
  && curl --create-dirs -sSLo /usr/share/jenkins/slave.jar http://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${JENKINS_REMOTING_VERSION}/remoting-${JENKINS_REMOTING_VERSION}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/slave.jar 

COPY jenkins-slave /usr/local/bin/jenkins-slave

USER root

ENV CLOUDSDK_CORE_DISABLE_PROMPTS=1
ENV GCLOUD_SDK_VERSION=116.0.0
ENV GCLOUD_SDK_URL=https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz
ENV CLOUDSDK_PYTHON_SITEPACKAGES 1
RUN echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers

RUN apk add --no-cache python && \
    python -m ensurepip && \
    rm -rf /usr/lib/python*/ensurepip && \
    pip install --upgrade pip setuptools && \
    rm -rf /root/.cache

RUN apk add --update --no-cache openssl bash \
 && rm -rf /var/cache/apk/* \
 && mkdir /opt && cd /opt \
 && wget -q -O - $GCLOUD_SDK_URL |tar zxf - \
 && /bin/bash -l -c "/opt/google-cloud-sdk/install.sh --usage-reporting=true --path-update=true --bash-completion=true --rc-path=/.bashrc --disable-installation-options && exit" \
 && /bin/bash -l -c "/opt/google-cloud-sdk/bin/gcloud --quiet config set component_manager/disable_update_check true && exit" \
 && rm -rf /opt/google-cloud-sdk/.install/.backup

RUN apk add --update --no-cache git

ENV PATH /opt/google-cloud-sdk/bin:$PATH

USER jenkins

VOLUME /home/jenkins
WORKDIR /home/jenkins

ENTRYPOINT ["jenkins-slave"]