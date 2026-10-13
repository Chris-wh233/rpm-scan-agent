FROM lcr.loongnix.cn/library/openjdk:21-jdk

ARG CVE_BIN_TOOL_RELEASE=20260930
ARG CVE_BIN_TOOL_ARCHIVE=cve-bin-tool-20260930-la64-py314.tar.gz
ARG CVE_BIN_TOOL_SHA256=bb1664cb7dc884d6e665fa7c47388653ea56853c629a947fc19b0e744bacf23c
ARG JENKINS_AGENT_JAR_URL=http://10.130.43.224:18080/jnlpJars/agent.jar

ENV PATH="/cve-bin-tool/.venv/bin:${PATH}" \
    HOME=/home/jenkins \
    JENKINS_AGENT_WORKDIR=/home/jenkins/agent \
    XDG_CACHE_HOME=/data/cve-db

USER root

RUN printf '%s\n' \
      'deb http://mirrors.ustc.edu.cn/debian unstable main' \
      > /etc/apt/sources.list && \
    rm -f /etc/apt/sources.list.d/debian.sources && \
    apt-get -o Acquire::Retries=5 update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      bash \
      ca-certificates \
      cpio \
      curl \
      file \
      gzip \
      python3 \
      rpm \
      rpm2cpio \
      tar \
      unzip \
      xz-utils \
      zstd && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /cve-bin-tool /usr/share/jenkins && \
    curl --fail --location --retry 5 \
      --output /tmp/cve-bin-tool.tar.gz \
      "https://github.com/loongarch64-releases/cve-bin-tool/releases/download/${CVE_BIN_TOOL_RELEASE}/${CVE_BIN_TOOL_ARCHIVE}" && \
    echo "${CVE_BIN_TOOL_SHA256}  /tmp/cve-bin-tool.tar.gz" | sha256sum --check - && \
    tar -xzf /tmp/cve-bin-tool.tar.gz -C /cve-bin-tool && \
    rm -f /tmp/cve-bin-tool.tar.gz && \
    curl --fail --location --retry 5 \
      --output /usr/share/jenkins/agent.jar \
      "${JENKINS_AGENT_JAR_URL}"

ARG AGENT_UID=1000
ARG AGENT_GID=1000
RUN groupadd --gid ${AGENT_GID} jenkins && \
    useradd --uid ${AGENT_UID} --gid ${AGENT_GID} --create-home --shell /bin/bash jenkins && \
    mkdir -p \
      /home/jenkins/agent \
      /data/cve-db && \
    chown -R jenkins:jenkins /home/jenkins /data/cve-db

COPY scripts/run-rpm-scan /usr/local/bin/run-rpm-scan
COPY scripts/send-rpm-event /usr/local/bin/send-rpm-event
COPY scripts/jenkins-agent-entrypoint /usr/local/bin/jenkins-agent-entrypoint

RUN chmod 0755 \
      /usr/local/bin/run-rpm-scan \
      /usr/local/bin/send-rpm-event \
      /usr/local/bin/jenkins-agent-entrypoint

USER jenkins
WORKDIR /home/jenkins/agent

# 下载 cve 库（也可通过第一次扫描时自动下载）
# cve-bin-tool -u now

ENTRYPOINT ["jenkins-agent-entrypoint"]
