# Both inputs are immutable multi-platform image manifests. The target JVM is a JDK,
# so the external observer can attach locally without exposing a remote JMX port.
FROM eclipse-temurin:21.0.10_7-jdk-jammy@sha256:25d1276565738d3c805e632a4542c3a7598866ef967f4def6544c15de3a74b14 AS jdk
FROM ortussolutions/commandbox@sha256:853b4f788a90b76b1a8fc6fce0dfad7ca92c4b38b4ebd030be507b1a7ac9e197
COPY --from=jdk /opt/java/openjdk /opt/java/openjdk
ENV JAVA_VERSION=jdk-21.0.10+7
WORKDIR /app
ENTRYPOINT []
CMD ["box", "server", "start", "--console", "--noSaveSettings"]
