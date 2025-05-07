package demo.com.example.testserver.product.repository.elasticsearch;

import demo.com.example.testserver.product.dto.elasticsearch.ProductElasticsearchDTO;

import java.util.List;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
@ConditionalOnProperty(name = "spring.elasticsearch.enabled", havingValue = "true")
public interface ProductElasticsearchRepository extends ElasticsearchRepository<ProductElasticsearchDTO, Long> {

    List<ProductElasticsearchDTO> findByNameContaining(String name);
}
