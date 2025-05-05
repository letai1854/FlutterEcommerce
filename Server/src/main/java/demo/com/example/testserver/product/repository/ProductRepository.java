package demo.com.example.testserver.product.repository;

import demo.com.example.testserver.product.model.Product;

import java.util.Date;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

@Repository
public interface ProductRepository extends JpaRepository<Product, Long>, JpaSpecificationExecutor<Product> { // Changed Integer to Long
    // JpaSpecificationExecutor is added to support dynamic queries using Specifications
}
