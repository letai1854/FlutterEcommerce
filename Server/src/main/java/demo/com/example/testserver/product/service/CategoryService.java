package demo.com.example.testserver.product.service;

import demo.com.example.testserver.product.dto.CategoryDTO;
import demo.com.example.testserver.product.dto.CreateCategoryRequestDTO;
import demo.com.example.testserver.product.dto.UpdateCategoryRequestDTO;
import jakarta.persistence.EntityNotFoundException;

import java.util.List;

public interface CategoryService {
    List<CategoryDTO> findAllCategories();
    CategoryDTO findCategoryById(Integer id) throws EntityNotFoundException;
    CategoryDTO createCategory(CreateCategoryRequestDTO requestDTO) throws IllegalArgumentException;
    CategoryDTO updateCategory(Integer id, UpdateCategoryRequestDTO requestDTO) throws EntityNotFoundException, IllegalArgumentException;
    void deleteCategory(Integer id) throws EntityNotFoundException;
}
