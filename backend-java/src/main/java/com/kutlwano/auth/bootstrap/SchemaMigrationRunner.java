package com.kutlwano.auth.bootstrap;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.core.io.FileSystemResource;
import org.springframework.jdbc.datasource.init.ResourceDatabasePopulator;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.io.File;
import java.util.Arrays;
import java.util.Comparator;

@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class SchemaMigrationRunner implements CommandLineRunner {

    private final DataSource dataSource;

    @Value("${app.schema.auto-run:false}")
    private boolean autoRun;

    @Value("${app.schema.path:/app/database}")
    private String schemaPath;

    public SchemaMigrationRunner(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    @Override
    public void run(String... args) {
        if (!autoRun) {
            System.out.println("SchemaMigrationRunner skipped: app.schema.auto-run=false");
            return;
        }

        File folder = new File(schemaPath);
        if (!folder.exists() || !folder.isDirectory()) {
            throw new IllegalStateException("Schema path not found: " + schemaPath);
        }

        File[] sqlFiles = folder.listFiles((dir, name) -> name.toLowerCase().endsWith(".sql"));
        if (sqlFiles == null || sqlFiles.length == 0) {
            throw new IllegalStateException("No SQL files found in: " + schemaPath);
        }

        Arrays.sort(sqlFiles, Comparator.comparing(File::getName));

        ResourceDatabasePopulator populator = new ResourceDatabasePopulator();
        populator.setContinueOnError(false);
        populator.setIgnoreFailedDrops(true);
        populator.setSqlScriptEncoding("UTF-8");

        for (File file : sqlFiles) {
            System.out.println("Applying SQL file: " + file.getName());
            populator.addScript(new FileSystemResource(file));
        }

        populator.execute(dataSource);

        System.out.println("SchemaMigrationRunner completed successfully.");
    }
}
