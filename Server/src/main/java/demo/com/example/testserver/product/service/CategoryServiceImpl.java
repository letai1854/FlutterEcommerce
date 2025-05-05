package demo.com.example.testserver.product.service;

import demo.com.example.testserver.product.dto.CategoryDTO;
import demo.com.example.testserver.product.dto.CreateCategoryRequestDTO;
import demo.com.example.testserver.product.dto.UpdateCategoryRequestDTO;
import demo.com.example.testserver.product.model.Category;
import demo.com.example.testserver.product.repository.CategoryRepository;
import jakarta.persistence.EntityNotFoundException;
import org.modelmapper.ModelMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class CategoryServiceImpl implements CategoryService {

    private static final Logger logger = LoggerFactory.getLogger(CategoryServiceImpl.class);

    @Autowired
    private CategoryRepository categoryRepository;

    @Autowired
    private ModelMapper modelMapper; // Ensure ModelMapper bean is configured

    @Override
    @Transactional(readOnly = true)
    public List<CategoryDTO> findAllCategories() {
        logger.info("Fetching all categories");
        return categoryRepository.findAll().stream()
                .map(category -> modelMapper.map(category, CategoryDTO.class))
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public CategoryDTO findCategoryById(Integer id) throws EntityNotFoundException {
        logger.info("Fetching category by ID: {}", id);
        Category category = categoryRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Category not found with ID: " + id));
        return modelMapper.map(category, CategoryDTO.class);
    }

    @Override
    @Transactional
    public CategoryDTO createCategory(CreateCategoryRequestDTO requestDTO) throws IllegalArgumentException {
        logger.info("Attempting to create category with name: {}", requestDTO.getName());
        if (categoryRepository.existsByName(requestDTO.getName())) {
            logger.warn("Category creation failed: Name '{}' already exists", requestDTO.getName());
            throw new IllegalArgumentException("Category name '" + requestDTO.getName() + "' already exists.");
        }
        Category category = modelMapper.map(requestDTO, Category.class);
        try {
            Category savedCategory = categoryRepository.save(category);
            logger.info("Successfully created category with ID: {}", savedCategory.getId());
            return modelMapper.map(savedCategory, CategoryDTO.class);
        } catch (DataIntegrityViolationException e) {
            // Catch potential constraint violations not caught by existsByName (though less likely with check)
            logger.error("Data integrity violation during category creation for name: {}", requestDTO.getName(), e);
            throw new IllegalArgumentException("Could not create category due to data constraint.", e);
        }
    }

    @Override
    @Transactional
    public CategoryDTO updateCategory(Integer id, UpdateCategoryRequestDTO requestDTO) throws EntityNotFoundException, IllegalArgumentException {
        logger.info("Attempting to update category with ID: {}", id);
        Category existingCategory = categoryRepository.findById(id)
                .orElseThrow(() -> {
                     logger.warn("Category update failed: Not found with ID: {}", id);
                     return new EntityNotFoundException("Category not found with ID: " + id);
                });

        // Check if the new name conflicts with another existing category
        categoryRepository.findByName(requestDTO.getName()).ifPresent(categoryWithSameName -> {
            if (!categoryWithSameName.getId().equals(id)) {
                logger.warn("Category update failed for ID {}: Name '{}' already exists for category ID {}", id, requestDTO.getName(), categoryWithSameName.getId());
                throw new IllegalArgumentException("Category name '" + requestDTO.getName() + "' already exists.");
            }
        });

        // Update fields
        existingCategory.setName(requestDTO.getName());
        existingCategory.setImageUrl(requestDTO.getImageUrl());
        // Note: @PreUpdate in Category entity handles updatedDate

        try {
            Category updatedCategory = categoryRepository.save(existingCategory);
            logger.info("Successfully updated category with ID: {}", updatedCategory.getId());
            return modelMapper.map(updatedCategory, CategoryDTO.class);
        } catch (DataIntegrityViolationException e) {
            logger.error("Data integrity violation during category update for ID: {}", id, e);
            throw new IllegalArgumentException("Could not update category due to data constraint.", e);
        }
    }

    @Override
    @Transactional
    public void deleteCategory(Integer id) throws EntityNotFoundException {
        logger.info("Attempting to delete category with ID: {}", id);
        if (!categoryRepository.existsById(id)) {
            logger.warn("Category deletion failed: Not found with ID: {}", id);
            throw new EntityNotFoundException("Category not found with ID: " + id);
        }
        try {
            // Consider checking if category is linked to products before deleting
            // if (productRepository.existsByCategoryId(id)) {
            //     throw new DataIntegrityViolationException("Cannot delete category with ID " + id + " as it is linked to existing products.");
            // }
            categoryRepository.deleteById(id);
            logger.info("Successfully deleted category with ID: {}", id);
        } catch (DataIntegrityViolationException e) {
            // Catch cases where deletion violates constraints (e.g., foreign key if not checked above)
            logger.error("Data integrity violation during category deletion for ID: {}. It might be linked to other entities.", id, e);
            throw new DataIntegrityViolationException("Cannot delete category with ID " + id + " as it is linked to other data.", e);
        }
    }
}
