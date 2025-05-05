package demo.com.example.testserver.product.repository;

import demo.com.example.testserver.product.model.Brand;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface BrandRepository extends JpaRepository<Brand, Integer> {
    Optional<Brand> findByName(String name); // Find by name for uniqueness checks
    boolean existsByName(String name); // Check if name exists
}
