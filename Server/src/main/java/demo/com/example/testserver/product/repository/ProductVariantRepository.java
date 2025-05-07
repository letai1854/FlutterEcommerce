package demo.com.example.testserver.product.repository;

import demo.com.example.testserver.product.model.ProductVariant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ProductVariantRepository extends JpaRepository<ProductVariant, Integer> {
    // Basic CRUD methods are inherited from JpaRepository
    // Add custom query methods here if needed in the future
}
