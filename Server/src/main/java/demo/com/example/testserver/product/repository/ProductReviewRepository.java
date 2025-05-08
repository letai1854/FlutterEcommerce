package demo.com.example.testserver.product.repository;

import demo.com.example.testserver.product.model.ProductReview;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ProductReviewRepository extends JpaRepository<ProductReview, Integer> {
}
