package demo.com.example.testserver.product.repository.elasticsearch;

import demo.com.example.testserver.product.dto.elasticsearch.ProductElasticsearchDTO;
import demo.com.example.testserver.config.ElasticsearchConnectionCondition; // Add this import

import java.util.List;

import org.springframework.context.annotation.Conditional; // Add this import
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
@Conditional(ElasticsearchConnectionCondition.class) // Add this annotation back
public interface ProductElasticsearchRepository extends ElasticsearchRepository<ProductElasticsearchDTO, Long> {

    List<ProductElasticsearchDTO> findByNameContaining(String name);
}
