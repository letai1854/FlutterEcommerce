package demo.com.example.testserver.product.repository;

import demo.com.example.testserver.product.model.Category;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor; // Import this
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
// Extend JpaSpecificationExecutor
public interface CategoryRepository extends JpaRepository<Category, Integer>, JpaSpecificationExecutor<Category> {
    Optional<Category> findByName(String name); // Find by name for uniqueness checks
    boolean existsByName(String name); // Check if name exists
}
