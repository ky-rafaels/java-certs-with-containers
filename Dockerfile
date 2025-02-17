FROM --platform=linux/amd64 cgr.dev/chainguard/maven:latest-dev AS builder

WORKDIR /work

COPY java-app/src /src
COPY java-app/pom.xml pom.xml

RUN mvn clean package 
# RUN REPOSITORY=$(mvn help:evaluate -Dexpression=settings.localRepository -q -DforceStdout) && rm -rf ${REPOSITORY}

FROM --platform=linux/amd64 cgr.dev/chainguard/jre:latest 
WORKDIR /app
COPY --from=builder /work/target/java-app-0.0.1-SNAPSHOT.jar .
CMD ["java", "-jar", "java-app-0.0.1-SNAPSHOT.jar"]
