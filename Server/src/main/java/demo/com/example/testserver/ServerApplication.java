package demo.com.example.testserver;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.boot.web.servlet.context.ServletWebServerInitializedEvent;
import org.springframework.context.ApplicationListener;
import org.springframework.core.env.Environment;

@SpringBootApplication
public class ServerApplication implements ApplicationListener<ServletWebServerInitializedEvent> {

    private static final Logger logger = LoggerFactory.getLogger(ServerApplication.class);

    @Autowired
    private Environment environment;

    public static void main(String[] args) {
        new SpringApplicationBuilder(ServerApplication.class)
                .lazyInitialization(true)
                .run(args);
    }

    @Override
    public void onApplicationEvent(ServletWebServerInitializedEvent event) {
        int port = event.getWebServer().getPort();
        String httpProtocol = "http";
        String wsProtocol = "ws";

        boolean sslEnabled = environment.getProperty("server.ssl.key-store") != null ||
                             (environment.getProperty("server.ssl.enabled") != null && environment.getProperty("server.ssl.enabled").equalsIgnoreCase("true"));

        if (sslEnabled) {
            httpProtocol = "https";
            wsProtocol = "wss";
        }
        
        logger.info("Spring Boot application started. Server is listening on port: {}", port);
        logger.info("Application accessible at {}://localhost:{}/", httpProtocol, port);
        logger.info("WebSocket endpoint should be available at {}://localhost:{}/ws", wsProtocol, port);
    }
}
