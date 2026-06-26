FROM maven:3.9.8-eclipse-temurin-21 AS builder

WORKDIR /app

COPY pom.xml .
COPY src ./src
COPY database ./database
COPY migrate ./migrate

RUN mvn clean package -DskipTests

FROM eclipse-temurin:21-jre

WORKDIR /app

RUN apt-get update && apt-get install -y postgresql-client && rm -rf /var/lib/apt/lists/*

COPY database ./database
COPY migrate/run-migrations.sh ./run-migrations.sh
COPY --from=builder /app/target/app.jar app.jar

RUN chmod +x ./run-migrations.sh

ENTRYPOINT ["./run-migrations.sh"]
