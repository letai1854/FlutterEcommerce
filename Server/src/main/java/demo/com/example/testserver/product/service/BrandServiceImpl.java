package demo.com.example.testserver.product.service;

import demo.com.example.testserver.product.dto.BrandDTO;
import demo.com.example.testserver.product.dto.CreateBrandRequestDTO;
import demo.com.example.testserver.product.dto.UpdateBrandRequestDTO;
import demo.com.example.testserver.product.model.Brand;
import demo.com.example.testserver.product.repository.BrandRepository;
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
public class BrandServiceImpl implements BrandService {

    private static final Logger logger = LoggerFactory.getLogger(BrandServiceImpl.class);

    @Autowired
    private BrandRepository brandRepository;

    @Autowired
    private ModelMapper modelMapper; // Ensure ModelMapper bean is configured

    @Override
    @Transactional(readOnly = true)
    public List<BrandDTO> findAllBrands() {
        logger.info("Fetching all brands");
        return brandRepository.findAll().stream()
                .map(brand -> modelMapper.map(brand, BrandDTO.class))
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public BrandDTO findBrandById(Integer id) throws EntityNotFoundException {
        logger.info("Fetching brand by ID: {}", id);
        Brand brand = brandRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Brand not found with ID: " + id));
        return modelMapper.map(brand, BrandDTO.class);
    }

    @Override
    @Transactional
    public BrandDTO createBrand(CreateBrandRequestDTO requestDTO) throws IllegalArgumentException {
        logger.info("Attempting to create brand with name: {}", requestDTO.getName());
        if (brandRepository.existsByName(requestDTO.getName())) {
            logger.warn("Brand creation failed: Name '{}' already exists", requestDTO.getName());
            throw new IllegalArgumentException("Brand name '" + requestDTO.getName() + "' already exists.");
        }
        Brand brand = modelMapper.map(requestDTO, Brand.class);
        try {
            Brand savedBrand = brandRepository.save(brand);
            logger.info("Successfully created brand with ID: {}", savedBrand.getId());
            return modelMapper.map(savedBrand, BrandDTO.class);
        } catch (DataIntegrityViolationException e) {
            logger.error("Data integrity violation during brand creation for name: {}", requestDTO.getName(), e);
            throw new IllegalArgumentException("Could not create brand due to data constraint.", e);
        }
    }

    @Override
    @Transactional
    public BrandDTO updateBrand(Integer id, UpdateBrandRequestDTO requestDTO) throws EntityNotFoundException, IllegalArgumentException {
        logger.info("Attempting to update brand with ID: {}", id);
        Brand existingBrand = brandRepository.findById(id)
                .orElseThrow(() -> {
                    logger.warn("Brand update failed: Not found with ID: {}", id);
                    return new EntityNotFoundException("Brand not found with ID: " + id);
                });

        // Check if the new name conflicts with another existing brand
        brandRepository.findByName(requestDTO.getName()).ifPresent(brandWithSameName -> {
            if (!brandWithSameName.getId().equals(id)) {
                logger.warn("Brand update failed for ID {}: Name '{}' already exists for brand ID {}", id, requestDTO.getName(), brandWithSameName.getId());
                throw new IllegalArgumentException("Brand name '" + requestDTO.getName() + "' already exists.");
            }
        });

        // Update fields
        existingBrand.setName(requestDTO.getName());
        // Note: @PreUpdate in Brand entity handles updatedDate

        try {
            Brand updatedBrand = brandRepository.save(existingBrand);
            logger.info("Successfully updated brand with ID: {}", updatedBrand.getId());
            return modelMapper.map(updatedBrand, BrandDTO.class);
        } catch (DataIntegrityViolationException e) {
            logger.error("Data integrity violation during brand update for ID: {}", id, e);
            throw new IllegalArgumentException("Could not update brand due to data constraint.", e);
        }
    }

    @Override
    @Transactional
    public void deleteBrand(Integer id) throws EntityNotFoundException {
        logger.info("Attempting to delete brand with ID: {}", id);
        if (!brandRepository.existsById(id)) {
            logger.warn("Brand deletion failed: Not found with ID: {}", id);
            throw new EntityNotFoundException("Brand not found with ID: " + id);
        }
        try {
             // Consider checking if brand is linked to products before deleting
            // if (productRepository.existsByBrandId(id)) {
            //     throw new DataIntegrityViolationException("Cannot delete brand with ID " + id + " as it is linked to existing products.");
            // }
            brandRepository.deleteById(id);
            logger.info("Successfully deleted brand with ID: {}", id);
        } catch (DataIntegrityViolationException e) {
            logger.error("Data integrity violation during brand deletion for ID: {}. It might be linked to other entities.", id, e);
            throw new DataIntegrityViolationException("Cannot delete brand with ID " + id + " as it is linked to other data.", e);
        }
    }
}
