# RPM Scan Agent

LoongArch64 Jenkins inbound agent for RPM vulnerability scans with
`cve-bin-tool`.

本组件是 `scan-service` 扫描服务栈的一部分。
镜像构建、容器启动与运行时配置都由上级目录的 `docker-compose.yml` 与
`.env` 统一管理。

Persistent host data（路径来自 `scan-service/.env` 的「宿主机目录」分区）：

~~~text
RPM_SCAN_CVE_DB_HOST_PATH             漏洞库，挂到容器 /data/cve-db
RPM_SCAN_AGENT_WORKSPACE_HOST_PATH    agent 工作目录，挂到容器 /home/jenkins/agent
RPM_SCAN_INPUT_HOST_PATH              待扫描 RPM，只读挂到容器 /scan-input
~~~

## 配置

运行时配置位于 `scan-service/.env` 的 `rpm-scan-agent` 分区，由 compose
注入容器：

~~~text
JENKINS_URL=http://<jenkins-host>:18080
RPM_SCAN_AGENT_NAME=rpm-scan-agent-01
RPM_SCAN_AGENT_SECRET=<inbound agent secret>
CVE_UPDATE_MODE=never
SCAN_RESULTS_PORTAL_URL=http://scan-results-portal:8080
~~~

`JENKINS_AGENT_JAR_URL`（构建镜像时下载 agent.jar 用）位于 `scan-service/.env`
的「外部 Jenkins」分区。

## 启动

在 `scan-service` 目录执行：

~~~bash
docker compose up -d --build rpm-scan-agent
~~~

## Jenkins 侧

在 Jenkins 上创建 permanent agent `rpm-scan-agent-01`，标签为 `rpm-scan`，
并把其 inbound-agent secret 写入 `scan-service/.env` 的
`RPM_SCAN_AGENT_SECRET`。
