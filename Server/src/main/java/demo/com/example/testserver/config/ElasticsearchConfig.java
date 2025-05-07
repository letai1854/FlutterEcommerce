package demo.com.example.testserver.config;

import co.elastic.clients.elasticsearch.ElasticsearchClient;
import co.elastic.clients.json.jackson.JacksonJsonpMapper;
import co.elastic.clients.transport.ElasticsearchTransport;
import co.elastic.clients.transport.rest_client.RestClientTransport;
import org.apache.http.HttpHost;
import org.apache.http.auth.AuthScope;
import org.apache.http.auth.UsernamePasswordCredentials;
import org.apache.http.client.CredentialsProvider;
import org.apache.http.impl.client.BasicCredentialsProvider;
import org.elasticsearch.client.RestClient;
import org.elasticsearch.client.RestClientBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Conditional;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.elasticsearch.core.ElasticsearchOperations;
import org.springframework.data.elasticsearch.client.elc.ElasticsearchTemplate;
import org.springframework.data.elasticsearch.repository.config.EnableElasticsearchRepositories;
import org.springframework.util.StringUtils;

import java.net.URI;
import java.net.URISyntaxException;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Elasticsearch configuration that only gets activated if spring.elasticsearch.enabled=true
 * AND Elasticsearch server is reachable. This configuration provides the necessary beans
 * for Spring Data Elasticsearch when the condition is met.
 */
@Configuration @Conditional(ElasticsearchConnectionCondition.class) // This is key 
@EnableElasticsearchRepositories(basePackages = "demo.com.example.testserver.product.repository.elasticsearch") 
public class ElasticsearchConfig {

    private static final Logger logger = LoggerFactory.getLogger(ElasticsearchConfig.class);

    @Value("${spring.elasticsearch.uris}")
    private String elasticsearchUris;

    @Value("${spring.elasticsearch.username:#{null}}")
    private String username;

    @Value("${spring.elasticsearch.password:#{null}}")
    private String password;

    public ElasticsearchConfig() {
        logger.info("ElasticsearchConfig bean is being created (condition met).");
    }

    @Bean
    public RestClient getRestClient() {
        logger.info("Creating Elasticsearch RestClient for URIs: {}", elasticsearchUris);
        List<HttpHost> httpHosts = Arrays.stream(elasticsearchUris.split(","))
                .map(uriString -> {
                    try {
                        URI uri = new URI(uriString.trim());
                        return new HttpHost(uri.getHost(), uri.getPort(), uri.getScheme());
                    } catch (URISyntaxException e) {
                        logger.error("Invalid Elasticsearch URI format: {}", uriString, e);
                        throw new RuntimeException("Invalid Elasticsearch URI format", e);
                    }
                })
                .collect(Collectors.toList());

        RestClientBuilder builder = RestClient.builder(httpHosts.toArray(new HttpHost[0]));

        if (StringUtils.hasText(username) && StringUtils.hasText(password)) {
            final CredentialsProvider credentialsProvider = new BasicCredentialsProvider();
            credentialsProvider.setCredentials(AuthScope.ANY, new UsernamePasswordCredentials(username, password));
            builder.setHttpClientConfigCallback(httpClientBuilder ->
                    httpClientBuilder.setDefaultCredentialsProvider(credentialsProvider)
            );
            logger.info("Configuring Elasticsearch RestClient with basic authentication.");
        }

        return builder.build();
    }

    @Bean
    public ElasticsearchTransport getElasticsearchTransport() {
        logger.info("Creating ElasticsearchTransport.");
        return new RestClientTransport(getRestClient(), new JacksonJsonpMapper());
    }

    @Bean
    public ElasticsearchClient getElasticsearchClient() {
        logger.info("Creating ElasticsearchClient.");
        return new ElasticsearchClient(getElasticsearchTransport());
    }

    @Bean
    public ElasticsearchOperations elasticsearchTemplate() {
        logger.info("Creating ElasticsearchTemplate.");
        return new ElasticsearchTemplate(getElasticsearchClient());
    }
}
