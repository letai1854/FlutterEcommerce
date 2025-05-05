package demo.com.example.testserver.product.service;

import demo.com.example.testserver.product.dto.CategoryDTO;
import demo.com.example.testserver.product.dto.CreateCategoryRequestDTO;
import demo.com.example.testserver.product.dto.UpdateCategoryRequestDTO;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.Date;
import java.util.List;

public interface CategoryService {
    Page<CategoryDTO> findCategories(Pageable pageable, Date startDate, Date endDate);
    CategoryDTO findCategoryById(Integer id) throws EntityNotFoundException;
    CategoryDTO createCategory(CreateCategoryRequestDTO requestDTO) throws IllegalArgumentException;
    CategoryDTO updateCategory(Integer id, UpdateCategoryRequestDTO requestDTO) throws EntityNotFoundException, IllegalArgumentException;
    void deleteCategory(Integer id) throws EntityNotFoundException;
}
