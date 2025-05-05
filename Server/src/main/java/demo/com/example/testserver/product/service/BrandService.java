package demo.com.example.testserver.product.service;

import demo.com.example.testserver.product.dto.BrandDTO;
import demo.com.example.testserver.product.dto.CreateBrandRequestDTO;
import demo.com.example.testserver.product.dto.UpdateBrandRequestDTO;
import jakarta.persistence.EntityNotFoundException;

import java.util.List;

public interface BrandService {
    List<BrandDTO> findAllBrands();
    BrandDTO findBrandById(Integer id) throws EntityNotFoundException;
    BrandDTO createBrand(CreateBrandRequestDTO requestDTO) throws IllegalArgumentException;
    BrandDTO updateBrand(Integer id, UpdateBrandRequestDTO requestDTO) throws EntityNotFoundException, IllegalArgumentException;
    void deleteBrand(Integer id) throws EntityNotFoundException;
}
