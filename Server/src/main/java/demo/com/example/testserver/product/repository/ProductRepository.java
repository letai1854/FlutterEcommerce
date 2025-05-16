package demo.com.example.testserver.product.repository;

import demo.com.example.testserver.product.model.Product;

import java.util.Date;
import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

@Repository
public interface ProductRepository extends JpaRepository<Product, Long>, JpaSpecificationExecutor<Product> {
    Optional<Product> findByName(String name);

    /**
     * Find products using MySQL's MATCH AGAINST for full-text search
     */
    @Query(value = "SELECT * FROM san_pham WHERE MATCH(ten_san_pham, mo_ta) AGAINST(:searchTerm IN BOOLEAN MODE)",
           nativeQuery = true)
    List<Product> findByFullTextSearch(@Param("searchTerm") String searchTerm);

    /**
     * Paged version of the full-text search.
     * Spring Data JPA will append the ORDER BY clause based on the Pageable's Sort object.
     */
    @Query(value = "SELECT * FROM san_pham WHERE MATCH(ten_san_pham, mo_ta) AGAINST(:searchTerm IN BOOLEAN MODE)",
           countQuery = "SELECT count(*) FROM san_pham WHERE MATCH(ten_san_pham, mo_ta) AGAINST(:searchTerm IN BOOLEAN MODE)",
           nativeQuery = true)
    Page<Product> findByFullTextSearch(@Param("searchTerm") String searchTerm, Pageable pageable);
}
