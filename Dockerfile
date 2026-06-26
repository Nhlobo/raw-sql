FROM eclipse-temurin:21-jre

WORKDIR /app

RUN apt-get update && apt-get install -y postgresql-client && rm -rf /var/lib/apt/lists/*

COPY database ./database
COPY migrate/run-migrations.sh ./run-migrations.sh
COPY app.jar ./app.jar

RUN chmod +x ./run-migrations.sh

ENTRYPOINT ["./run-migrations.sh"]
