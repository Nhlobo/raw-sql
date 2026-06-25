FROM postgres:16
WORKDIR /app
COPY database ./database
COPY migrate/run-migrations.sh ./run-migrations.sh
RUN chmod +x ./run-migrations.sh
CMD ["./run-migrations.sh"]
COPY run-migrations.sh ./run-migrations.sh
RUN chmod +x ./run-migrations.sh
ENTRYPOINT ["./run-migrations.sh"]
