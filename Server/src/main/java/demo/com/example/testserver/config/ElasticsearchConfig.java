package demo.com.example.testserver.config;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.elasticsearch.repository.config.EnableElasticsearchRepositories;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Elasticsearch configuration that only gets activated when spring.elasticsearch.enabled=true
 */
@Configuration
@ConditionalOnProperty(name = "spring.elasticsearch.enabled", havingValue = "true")
@EnableElasticsearchRepositories(basePackages = "demo.com.example.testserver.product.repository.elasticsearch")
public class ElasticsearchConfig {
    
    private static final Logger logger = LoggerFactory.getLogger(ElasticsearchConfig.class);
    
    public ElasticsearchConfig() {
        logger.info("Elasticsearch integration enabled");
    }
}
