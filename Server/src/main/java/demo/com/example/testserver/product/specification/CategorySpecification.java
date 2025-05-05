package demo.com.example.testserver.product.specification;

import demo.com.example.testserver.product.model.Category;
import org.springframework.data.jpa.domain.Specification;
import jakarta.persistence.criteria.Predicate;
import java.util.Date;

public class CategorySpecification {

    public static Specification<Category> createdDateGreaterThanOrEqual(Date date) {
        return (root, query, criteriaBuilder) ->
                criteriaBuilder.greaterThanOrEqualTo(root.get("createdDate"), date);
    }

    public static Specification<Category> createdDateLessThan(Date date) {
        return (root, query, criteriaBuilder) ->
                criteriaBuilder.lessThan(root.get("createdDate"), date);
    }

    // Add other specifications if needed (e.g., by name)
    public static Specification<Category> nameContains(String name) {
        return (root, query, criteriaBuilder) -> {
            if (name == null || name.isEmpty()) {
                return criteriaBuilder.conjunction(); // Always true if name is not provided
            }
            return criteriaBuilder.like(criteriaBuilder.lower(root.get("name")), "%" + name.toLowerCase() + "%");
        };
    }
}
