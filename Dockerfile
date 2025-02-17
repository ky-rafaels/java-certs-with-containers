FROM cgr.dev/chainguard/maven:latest-dev AS builder

WORKDIR /work

COPY java-app/src /src
COPY pom.xml pom.xml

RUN mvn clean install -Dmaven.test.skip=true 
# RUN REPOSITORY=$(mvn help:evaluate -Dexpression=settings.localRepository -q -DforceStdout) && rm -rf ${REPOSITORY}

FROM cgr.dev/chainguard/jre:latest 
WORKDIR /app
COPY --from=builder /work/target/demo-0.0.1-SNAPSHOT.jar .
CMD ["java", "-jar", "demo-0.0.1-SNAPSHOT.jar"]
