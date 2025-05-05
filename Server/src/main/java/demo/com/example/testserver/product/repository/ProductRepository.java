package demo.com.example.testserver.product.repository;

import demo.com.example.testserver.product.model.Product;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

@Repository
public interface ProductRepository extends JpaRepository<Product, Long>, JpaSpecificationExecutor<Product> { // Changed Integer to Long
    // JpaSpecificationExecutor is added to support dynamic queries using Specifications

    // Add custom query methods if needed, for example:
    // List<Product> findByCategory(Category category);
    // Optional<Product> findByName(String name);
}
