package demo.com.example.testserver.config;

import org.apache.http.HttpHost;
import org.apache.http.auth.AuthScope;
import org.apache.http.auth.UsernamePasswordCredentials;
import org.apache.http.client.CredentialsProvider;
import org.apache.http.impl.client.BasicCredentialsProvider;
import org.elasticsearch.client.Request;
import org.elasticsearch.client.Response;
import org.elasticsearch.client.RestClient;
import org.elasticsearch.client.RestClientBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Condition;
import org.springframework.context.annotation.ConditionContext;
import org.springframework.core.type.AnnotatedTypeMetadata;
import org.springframework.util.StringUtils;

import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;

public class ElasticsearchConnectionCondition implements Condition {

    private static final Logger logger = LoggerFactory.getLogger(ElasticsearchConnectionCondition.class);

    @Override
    public boolean matches(ConditionContext context, AnnotatedTypeMetadata metadata) {
        String enabledProperty = context.getEnvironment().getProperty("spring.elasticsearch.enabled");
        if (!"true".equalsIgnoreCase(enabledProperty)) {
            logger.info("Elasticsearch integration is disabled via spring.elasticsearch.enabled=false.");
            return false;
        }

        String urisString = context.getEnvironment().getProperty("spring.elasticsearch.uris");
        if (!StringUtils.hasText(urisString)) {
            logger.warn("spring.elasticsearch.uris is not configured. Cannot check Elasticsearch status. Assuming unavailable.");
            return false;
        }

        // Naive parsing for the first URI, assuming http/https scheme
        // For robust parsing, consider Spring's existing client builder infrastructure if accessible here,
        // or a more comprehensive URI parsing logic.
        String[] uris = urisString.split(",");
        HttpHost[] httpHosts = new HttpHost[uris.length];
        try {
            for (int i = 0; i < uris.length; i++) {
                URI uri = new URI(uris[i].trim());
                httpHosts[i] = new HttpHost(uri.getHost(), uri.getPort(), uri.getScheme());
            }
        } catch (URISyntaxException e) {
            logger.error("Invalid Elasticsearch URI format in spring.elasticsearch.uris: {}", urisString, e);
            return false;
        }
        
        String username = context.getEnvironment().getProperty("spring.elasticsearch.username");
        String password = context.getEnvironment().getProperty("spring.elasticsearch.password");

        RestClientBuilder builder = RestClient.builder(httpHosts);

        if (StringUtils.hasText(username) && StringUtils.hasText(password)) {
            final CredentialsProvider credentialsProvider = new BasicCredentialsProvider();
            credentialsProvider.setCredentials(AuthScope.ANY, new UsernamePasswordCredentials(username, password));
            builder.setHttpClientConfigCallback(httpClientBuilder -> 
                httpClientBuilder.setDefaultCredentialsProvider(credentialsProvider)
            );
        }
        
        try (RestClient restClient = builder.build()) {
            logger.debug("Attempting to connect to Elasticsearch at {} to check status...", urisString);
            Request esRequest = new Request("GET", "/"); // Ping equivalent, renamed variable
            Response response = restClient.performRequest(esRequest);
            int statusCode = response.getStatusLine().getStatusCode();
            boolean success = statusCode >= 200 && statusCode < 300;
            
            if (success) {
                logger.info("ElasticsearchConnectionCondition: Successfully connected to Elasticsearch at {} (status: {}). Returning true.", urisString, statusCode);
                return true;
            } else {
                logger.warn("ElasticsearchConnectionCondition: Failed to connect to Elasticsearch at {} (status: {}). Returning false.", urisString, statusCode);
                return false;
            }
        } catch (IOException e) {
            logger.warn("ElasticsearchConnectionCondition: Elasticsearch is configured as enabled but is not reachable at {} due to IOException: {}. Returning false.", urisString, e.getMessage());
            // Log less of the stack trace for common connection errors to reduce noise, but indicate it happened.
            logger.debug("Full IOException stack trace:", e); 
            return false;
        } catch (Exception e) {
            logger.error("ElasticsearchConnectionCondition: An unexpected error occurred while trying to connect to Elasticsearch at {}: {}. Returning false.", urisString, e.getMessage(), e);
            return false;
        }
    }
}
