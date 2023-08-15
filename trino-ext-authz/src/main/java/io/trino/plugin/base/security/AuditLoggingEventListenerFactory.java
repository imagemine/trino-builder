package io.trino.plugin.base.security;

import io.trino.spi.eventlistener.EventListener;
import io.trino.spi.eventlistener.EventListenerFactory;
import io.trino.spi.eventlistener.QueryCompletedEvent;
import io.trino.spi.eventlistener.QueryCreatedEvent;
import io.trino.spi.eventlistener.QueryFailureInfo;
import io.trino.spi.eventlistener.SplitCompletedEvent;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.ZoneId;
import java.util.*;
import java.util.stream.Collectors;

enum AuditLogLevel {
    DEBUG {
        @Override
        public int levelValue() {
            return 0;
        }
    }, INFO {
        @Override
        public int levelValue() {
            return 1;
        }
    }, ERROR {
        @Override
        public int levelValue() {
            return 2;
        }
    };

    public abstract int levelValue();

}


public class AuditLoggingEventListenerFactory implements EventListenerFactory {
    @Override
    public String getName() {
        return "auditlog";
    }

    @Override
    public EventListener create(Map<String, String> config) {
        OutputStream os;
        AuditLogLevel auditLevel;
        try {
            String level = config.getOrDefault("log.level", "INFO");
            auditLevel = AuditLogLevel.valueOf(level.toUpperCase());
            String target = config.getOrDefault("target", "stdout");

            if ("file".equalsIgnoreCase(target)) {
                String path = config.getOrDefault("path", "/tmp/out.log");
                os = new FileOutputStream(new File(path));
            } else {
                os = System.out;
            }
        } catch (IOException ioe) {
            throw new RuntimeException("could not initialise audit logger", ioe);
        }
        return new LoggingEventListener(os, auditLevel);
    }
}

class AttributeLogger {
    private static final byte[] NEW_LINE = "\n".getBytes(StandardCharsets.UTF_8);
    private Map<String, Object> attributes = new TreeMap<>();
    private final OutputStream fso;

    private AttributeLogger(OutputStream fso) {
        this.fso = fso;
    }

    public AttributeLogger withAttribute(String name, Object value) {
        this.attributes.put(name, value);
        return this;
    }

    public void log() {
        List<String> snippets = new ArrayList<>();
        for (Map.Entry<String, Object> entry : attributes.entrySet()) {
            snippets.add("\"".concat(entry.getKey()).concat("\":\"").concat(entry.getValue().toString()).concat("\""));
        }
        byte[] data = snippets.stream().collect(Collectors.joining(",", "{", "}")).getBytes(StandardCharsets.UTF_8);
        try {
            fso.write(data);
            fso.write(NEW_LINE);
            fso.flush();
        } catch (IOException ioe) {
            System.err.printf("{\"logger\": \"auditlog\", \"level\":\"ERROR\", \"message\": \"oops with output stream, cause: %s\"}\n", ioe.getMessage());
        }
    }

    public static AttributeLogger newInstance(OutputStream fso) {
        return new AttributeLogger(fso);
    }
}


class LoggingEventListener implements EventListener {
    private final OutputStream fso;
    private final AuditLogLevel level;

    LoggingEventListener(OutputStream fso, AuditLogLevel level) {
        this.fso = fso;
        this.level = level;
    }

    @Override
    public void queryCreated(QueryCreatedEvent queryCreatedEvent) {
        if (level.levelValue() < AuditLogLevel.INFO.levelValue()) {
            return;
        }
        AttributeLogger.newInstance(fso)
                .withAttribute("level", "INFO")
                .withAttribute("phase", "created")
                .withAttribute("query", queryCreatedEvent.getMetadata().getQuery())
                .withAttribute("query_id", queryCreatedEvent.getMetadata().getQueryId())
                .withAttribute("catalog", queryCreatedEvent.getContext().getCatalog().orElse(""))
                .withAttribute("schema", queryCreatedEvent.getContext().getSchema().orElse(""))
                .withAttribute("principal", queryCreatedEvent.getContext().getPrincipal().orElse(""))
                .withAttribute("user", queryCreatedEvent.getContext().getUser())
                .withAttribute("time", queryCreatedEvent.getCreateTime().atZone(ZoneId.systemDefault()))
                .log();
    }


    @Override
    public void queryCompleted(QueryCompletedEvent queryCompletedEvent) {
        if (level.levelValue() < AuditLogLevel.INFO.levelValue()) {
            return;
        }
        AttributeLogger builder = AttributeLogger.newInstance(fso)
                .withAttribute("level", "INFO")
                .withAttribute("phase", "completed")
                .withAttribute("query", queryCompletedEvent.getMetadata().getQuery())
                .withAttribute("query_id", queryCompletedEvent.getMetadata().getQueryId())
                .withAttribute("catalog", queryCompletedEvent.getContext().getCatalog().orElse(""))
                .withAttribute("schema", queryCompletedEvent.getContext().getSchema().orElse(""))
                .withAttribute("principal", queryCompletedEvent.getContext().getPrincipal().orElse(""))
                .withAttribute("user", queryCompletedEvent.getContext().getUser())
                .withAttribute("time", queryCompletedEvent.getCreateTime().atZone(ZoneId.systemDefault()))
                .withAttribute("execution_time", queryCompletedEvent.getStatistics().getExecutionTime().orElse(Duration.ZERO).toMillis())
                .withAttribute("cpu_time", queryCompletedEvent.getStatistics().getCpuTime().toMillis())
                .withAttribute("analysis_time", queryCompletedEvent.getStatistics().getAnalysisTime().orElse(Duration.ZERO).toMillis())
                .withAttribute("rows", queryCompletedEvent.getStatistics().getOutputRows());

        if (queryCompletedEvent.getFailureInfo().isPresent()) {
            QueryFailureInfo failure = queryCompletedEvent.getFailureInfo().get();
            builder.withAttribute("error_code", failure.getErrorCode().getName());
            builder.withAttribute("message", failure.getFailureMessage().orElse(""));
            builder.withAttribute("failure_type", failure.getFailureType().orElse(""));
            builder.withAttribute("failure_host", failure.getFailureHost().orElse(""));
            builder.withAttribute("status", "failure");
        } else {
            builder.withAttribute("status", "success");
        }

        builder.log();
    }

    @Override
    public void splitCompleted(SplitCompletedEvent splitCompletedEvent) {

    }
}
