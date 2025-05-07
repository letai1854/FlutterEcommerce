package demo.com.example.testserver.config;

import demo.com.example.testserver.user.model.Address;
import demo.com.example.testserver.user.model.User;
import demo.com.example.testserver.user.repository.UserRepository;
import demo.com.example.testserver.product.dto.CreateProductRequestDTO;
import demo.com.example.testserver.product.dto.CreateProductVariantDTO;
import demo.com.example.testserver.product.model.Brand;
import demo.com.example.testserver.product.model.Category;
import demo.com.example.testserver.product.repository.BrandRepository;
import demo.com.example.testserver.product.repository.CategoryRepository;
import demo.com.example.testserver.product.repository.ProductRepository;
import demo.com.example.testserver.product.service.ProductService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

@Component
public class DataInitializer implements CommandLineRunner {

    private static final Logger logger = LoggerFactory.getLogger(DataInitializer.class);

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private ProductService productService;

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private CategoryRepository categoryRepository;

    @Autowired
    private BrandRepository brandRepository;

    @Override
    @Transactional
    public void run(String... args) throws Exception {
        createAdminUser();
        createRegularUser();
        createSampleProducts();
    }

    private void createAdminUser() {
        String adminEmail = "admin@example.com";
        if (userRepository.findByEmail(adminEmail).isEmpty()) {
            User adminUser = new User();
            adminUser.setEmail(adminEmail);
            adminUser.setFullName("Admin User");
            adminUser.setPassword(passwordEncoder.encode("admin123"));
            adminUser.setRole(User.UserRole.quan_tri);
            adminUser.setStatus(User.UserStatus.kich_hoat);
            adminUser.setCustomerPoints(BigDecimal.ZERO);

            Address adminAddress = new Address();
            adminAddress.setRecipientName(adminUser.getFullName());
            adminAddress.setPhoneNumber("0123456789");
            adminAddress.setSpecificAddress("1 Admin Street, Admin City");
            adminAddress.setDefault(true);
            adminUser.addAddress(adminAddress);

            userRepository.save(adminUser);
            logger.info("Created admin user: {}", adminEmail);
        } else {
            logger.info("Admin user {} already exists.", adminEmail);
        }
    }

    private void createRegularUser() {
        String userEmail = "user@example.com";
        if (userRepository.findByEmail(userEmail).isEmpty()) {
            User regularUser = new User();
            regularUser.setEmail(userEmail);
            regularUser.setFullName("Regular User");
            regularUser.setPassword(passwordEncoder.encode("user123"));
            regularUser.setRole(User.UserRole.khach_hang);
            regularUser.setStatus(User.UserStatus.kich_hoat);
            regularUser.setCustomerPoints(BigDecimal.ZERO);

            Address userAddress = new Address();
            userAddress.setRecipientName(regularUser.getFullName());
            userAddress.setPhoneNumber("0987654321");
            userAddress.setSpecificAddress("1 User Street, User City");
            userAddress.setDefault(true);
            regularUser.addAddress(userAddress);

            userRepository.save(regularUser);
            logger.info("Created regular user: {}", userEmail);
        } else {
            logger.info("Regular user {} already exists.", userEmail);
        }
    }

    private Category getOrCreateCategory(String name, String imageUrl) {
        Optional<Category> existingCategory = categoryRepository.findByName(name);
        if (existingCategory.isPresent()) {
            return existingCategory.get();
        } else {
            Category newCategory = new Category();
            newCategory.setName(name);
            newCategory.setImageUrl(imageUrl);
            Category savedCategory = categoryRepository.save(newCategory);
            logger.info("Created category: {}", savedCategory.getName());
            return savedCategory;
        }
    }

    private Brand getOrCreateBrand(String name) {
        Optional<Brand> existingBrand = brandRepository.findByName(name);
        if (existingBrand.isPresent()) {
            return existingBrand.get();
        } else {
            Brand newBrand = new Brand();
            newBrand.setName(name);
            Brand savedBrand = brandRepository.save(newBrand);
            logger.info("Created brand: {}", savedBrand.getName());
            return savedBrand;
        }
    }

    private void createSampleProducts() {
        logger.info("Attempting to create sample products...");

        Category laptopsCategory = getOrCreateCategory("Laptops", "images/categories/laptops.png");
        Category pcComponentsCategory = getOrCreateCategory("PC Components", "images/categories/pc_components.png");
        Category accessoriesCategory = getOrCreateCategory("Accessories", "images/categories/accessories.png");

        Brand dellBrand = getOrCreateBrand("Dell");
        Brand asusBrand = getOrCreateBrand("Asus");
        Brand intelBrand = getOrCreateBrand("Intel");
        Brand nvidiaBrand = getOrCreateBrand("Nvidia");
        Brand amdBrand = getOrCreateBrand("AMD");
        Brand corsairBrand = getOrCreateBrand("Corsair");
        Brand logitechBrand = getOrCreateBrand("Logitech");

        String productName1 = "Dell XPS 15 Laptop";
        if (productRepository.findByName(productName1).isEmpty()) {
            CreateProductRequestDTO product1DTO = new CreateProductRequestDTO();
            product1DTO.setName(productName1);
            product1DTO.setDescription("High-performance laptop for professionals and creators. Stunning display and powerful internals.");
            product1DTO.setCategoryId(laptopsCategory.getId().longValue());
            product1DTO.setBrandId(dellBrand.getId().longValue());
            product1DTO.setMainImageUrl("images/products/dell_xps15_main.png");
            product1DTO.setImageUrls(Arrays.asList("images/products/dell_xps15_1.png", "images/products/dell_xps15_2.png"));
            product1DTO.setDiscountPercentage(new BigDecimal("5.00")); // Valid: 5%

            CreateProductVariantDTO variant1_1 = new CreateProductVariantDTO();
            variant1_1.setName("16GB RAM, 512GB SSD, FHD+");
            variant1_1.setSku("DELL-XPS15-16-512-FHD");
            variant1_1.setPrice(new BigDecimal("1799.99"));
            variant1_1.setStockQuantity(50);
            variant1_1.setVariantImageUrl("images/products/dell_xps15_variant1.png");

            CreateProductVariantDTO variant1_2 = new CreateProductVariantDTO();
            variant1_2.setName("32GB RAM, 1TB SSD, OLED 3.5K");
            variant1_2.setSku("DELL-XPS15-32-1TB-OLED");
            variant1_2.setPrice(new BigDecimal("2499.99"));
            variant1_2.setStockQuantity(30);

            product1DTO.setVariants(Arrays.asList(variant1_1, variant1_2));
            try {
                productService.createProduct(product1DTO);
                logger.info("Created product: {}", productName1);
            } catch (Exception e) {
                logger.error("Error creating product {}: {}", productName1, e.getMessage(), e);
            }
        } else {
            logger.info("Product {} already exists. Skipping creation.", productName1);
        }

        String productName2 = "Asus ROG Strix G16 Gaming Laptop";
        if (productRepository.findByName(productName2).isEmpty()) {
            CreateProductRequestDTO product2DTO = new CreateProductRequestDTO();
            product2DTO.setName(productName2);
            product2DTO.setDescription("Powerful gaming laptop with latest Intel CPU and Nvidia RTX GPU. High refresh rate display.");
            product2DTO.setCategoryId(laptopsCategory.getId().longValue());
            product2DTO.setBrandId(asusBrand.getId().longValue());
            product2DTO.setMainImageUrl("images/products/asus_rog_g16_main.png");
            product2DTO.setImageUrls(Collections.singletonList("images/products/asus_rog_g16_1.png"));
            product2DTO.setDiscountPercentage(new BigDecimal("10.00")); // Valid: 10%

            CreateProductVariantDTO variant2_1 = new CreateProductVariantDTO();
            variant2_1.setName("i7-13650HX, RTX 4060, 16GB RAM, 512GB SSD");
            variant2_1.setSku("ASUS-ROG16-I7-4060-16-512");
            variant2_1.setPrice(new BigDecimal("1599.00"));
            variant2_1.setStockQuantity(40);

            CreateProductVariantDTO variant2_2 = new CreateProductVariantDTO();
            variant2_2.setName("i9-13980HX, RTX 4070, 32GB RAM, 1TB SSD");
            variant2_2.setSku("ASUS-ROG16-I9-4070-32-1TB");
            variant2_2.setPrice(new BigDecimal("2199.00"));
            variant2_2.setStockQuantity(25);

            product2DTO.setVariants(Arrays.asList(variant2_1, variant2_2));
            try {
                productService.createProduct(product2DTO);
                logger.info("Created product: {}", productName2);
            } catch (Exception e) {
                logger.error("Error creating product {}: {}", productName2, e.getMessage(), e);
            }
        } else {
            logger.info("Product {} already exists. Skipping creation.", productName2);
        }

        String productName3 = "Intel Core i7-13700K CPU";
        if (productRepository.findByName(productName3).isEmpty()) {
            CreateProductRequestDTO product3DTO = new CreateProductRequestDTO();
            product3DTO.setName(productName3);
            product3DTO.setDescription("13th Gen Intel Core i7 desktop processor. Unlocked for overclocking.");
            product3DTO.setCategoryId(pcComponentsCategory.getId().longValue());
            product3DTO.setBrandId(intelBrand.getId().longValue());
            product3DTO.setMainImageUrl("images/products/intel_i7_13700k_main.png");
            product3DTO.setImageUrls(Collections.emptyList());
            // Explicitly set to null instead of omitting to make it clear
            product3DTO.setDiscountPercentage(null);

            CreateProductVariantDTO variant3_1 = new CreateProductVariantDTO();
            variant3_1.setName("Standard Boxed");
            variant3_1.setSku("INTEL-I7-13700K");
            variant3_1.setPrice(new BigDecimal("399.99"));
            variant3_1.setStockQuantity(100);

            product3DTO.setVariants(Collections.singletonList(variant3_1));
            try {
                productService.createProduct(product3DTO);
                logger.info("Created product: {}", productName3);
            } catch (Exception e) {
                logger.error("Error creating product {}: {}", productName3, e.getMessage(), e);
            }
        } else {
            logger.info("Product {} already exists. Skipping creation.", productName3);
        }

        String productName4 = "Nvidia GeForce RTX 4070 GPU";
        if (productRepository.findByName(productName4).isEmpty()) {
            CreateProductRequestDTO product4DTO = new CreateProductRequestDTO();
            product4DTO.setName(productName4);
            product4DTO.setDescription("NVIDIA GeForce RTX 4070 graphics card. Experience ultra-performance gaming and content creation.");
            product4DTO.setCategoryId(pcComponentsCategory.getId().longValue());
            product4DTO.setBrandId(nvidiaBrand.getId().longValue());
            product4DTO.setMainImageUrl("images/products/nvidia_rtx4070_main.png");
            product4DTO.setImageUrls(Collections.emptyList());
            product4DTO.setDiscountPercentage(new BigDecimal("2.50")); // Valid: 2.5%

            CreateProductVariantDTO variant4_1 = new CreateProductVariantDTO();
            variant4_1.setName("Founders Edition 12GB GDDR6X");
            variant4_1.setSku("NV-RTX4070-FE-12G");
            variant4_1.setPrice(new BigDecimal("599.00"));
            variant4_1.setStockQuantity(60);

            product4DTO.setVariants(Collections.singletonList(variant4_1));
            try {
                productService.createProduct(product4DTO);
                logger.info("Created product: {}", productName4);
            } catch (Exception e) {
                logger.error("Error creating product {}: {}", productName4, e.getMessage(), e);
            }
        } else {
            logger.info("Product {} already exists. Skipping creation.", productName4);
        }

        String productName5 = "Corsair Vengeance LPX 16GB DDR4 RAM";
        if (productRepository.findByName(productName5).isEmpty()) {
            CreateProductRequestDTO product5DTO = new CreateProductRequestDTO();
            product5DTO.setName(productName5);
            product5DTO.setDescription("High-performance DDR4 memory designed for overclocking on Intel and AMD DDR4 motherboards.");
            product5DTO.setCategoryId(pcComponentsCategory.getId().longValue());
            product5DTO.setBrandId(corsairBrand.getId().longValue());
            product5DTO.setMainImageUrl("images/products/corsair_ram_main.png");
            product5DTO.setImageUrls(Collections.emptyList());
            // Explicitly set to null instead of omitting
            product5DTO.setDiscountPercentage(null);

            CreateProductVariantDTO variant5_1 = new CreateProductVariantDTO();
            variant5_1.setName("2x8GB, 3200MHz, C16, Black");
            variant5_1.setSku("COR-LPX-16G-3200-BLK");
            variant5_1.setPrice(new BigDecimal("74.99"));
            variant5_1.setStockQuantity(150);

            product5DTO.setVariants(List.of(variant5_1));
            try {
                productService.createProduct(product5DTO);
                logger.info("Created product: {}", productName5);
            } catch (Exception e) {
                logger.error("Error creating product {}: {}", productName5, e.getMessage(), e);
            }
        } else {
            logger.info("Product {} already exists. Skipping creation.", productName5);
        }

        String productName6 = "Logitech G Pro X Superlight Mouse";
        if (productRepository.findByName(productName6).isEmpty()) {
            CreateProductRequestDTO product6DTO = new CreateProductRequestDTO();
            product6DTO.setName(productName6);
            product6DTO.setDescription("Ultra-lightweight wireless gaming mouse, designed with pros for pros.");
            product6DTO.setCategoryId(accessoriesCategory.getId().longValue());
            product6DTO.setBrandId(logitechBrand.getId().longValue());
            product6DTO.setMainImageUrl("images/products/logitech_gpro_main.png");
            product6DTO.setImageUrls(Collections.emptyList());
            // Ensure discount percentage is within valid range (0-50%)
            product6DTO.setDiscountPercentage(new BigDecimal("15.00")); // Valid: 15%

            CreateProductVariantDTO variant6_1 = new CreateProductVariantDTO();
            variant6_1.setName("Black");
            variant6_1.setSku("LOGI-GPROSL-BLK");
            variant6_1.setPrice(new BigDecimal("149.99"));
            variant6_1.setStockQuantity(80);

            CreateProductVariantDTO variant6_2 = new CreateProductVariantDTO();
            variant6_2.setName("White");
            variant6_2.setSku("LOGI-GPROSL-WHT");
            variant6_2.setPrice(new BigDecimal("149.99"));
            variant6_2.setStockQuantity(70);

            product6DTO.setVariants(List.of(variant6_1, variant6_2));
            try {
                productService.createProduct(product6DTO);
                logger.info("Created product: {}", productName6);
            } catch (Exception e) {
                logger.error("Error creating product {}: {}", productName6, e.getMessage(), e);
            }
        } else {
            logger.info("Product {} already exists. Skipping creation.", productName6);
        }

        logger.info("Sample product creation process finished.");
    }
}
