FROM cgr.dev/chainguard/maven:latest-dev AS builder

WORKDIR /work
COPY ./spring-petclinic/* /work

RUN mvn clean install -Dmaven.test.skip=true -Djava.compiler=NONE

FROM cgr.dev/chainguard/jdk:latest 
WORKDIR /app
COPY ./spring-petclinic/target/*.jar ./java.jar
EXPOSE 8080 8443
CMD ["java", "-jar", "java.jar"]