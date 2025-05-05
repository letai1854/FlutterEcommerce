package demo.com.example.testserver.common.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.UUID;

@Service
public class ImageStorageService {

    private static final Logger logger = LoggerFactory.getLogger(ImageStorageService.class);

    @Value("${file.upload-dir}")
    private String uploadDir;

    private Path rootLocation;

    @PostConstruct
    public void init() {
        try {
            // Store the absolute, normalized path from the start
            this.rootLocation = Paths.get(uploadDir).toAbsolutePath().normalize();
            Files.createDirectories(this.rootLocation);
            logger.info("Image storage directory created/initialized at: {}", this.rootLocation);
        } catch (IOException e) {
            logger.error("Could not initialize storage location: {}", uploadDir, e);
            throw new RuntimeException("Could not initialize storage location", e);
        }
    }

    public String store(MultipartFile file) {
        if (file.isEmpty()) {
            throw new IllegalArgumentException("Failed to store empty file.");
        }

        // Clean the original filename (though we use UUID, it's good practice)
        String originalFilename = StringUtils.cleanPath(file.getOriginalFilename());
        String fileExtension = "";
        try {
            if (originalFilename.contains(".")) {
                fileExtension = originalFilename.substring(originalFilename.lastIndexOf("."));
            }
            // Generate a unique filename to avoid collisions
            String uniqueFilename = UUID.randomUUID().toString() + fileExtension;

            // Resolve the unique filename against the absolute root location
            Path destinationFile = this.rootLocation.resolve(uniqueFilename);

            // Security check: Compare the parent of the destination path with the root location
            // Both should be absolute and normalized now.
            if (!destinationFile.getParent().equals(this.rootLocation)) {
                // This check prevents storing files outside the intended directory
                logger.error("Security check failed: Destination parent {} does not match root location {}", destinationFile.getParent(), this.rootLocation);
                throw new SecurityException(
                    String.format("Cannot store file outside current directory. Target: %s, Parent: %s, Root: %s",
                                  destinationFile, destinationFile.getParent(), this.rootLocation));
            }

            try (InputStream inputStream = file.getInputStream()) {
                Files.copy(inputStream, destinationFile, StandardCopyOption.REPLACE_EXISTING);
                logger.info("Stored file: {}", uniqueFilename);
                return uniqueFilename; // Return the unique filename
            }
        } catch (IOException e) {
            logger.error("Failed to store file {}: {}", originalFilename, e.getMessage(), e);
            throw new RuntimeException("Failed to store file " + originalFilename, e);
        }
    }

    public Path load(String filename) {
        // Resolve against the absolute root location
        return this.rootLocation.resolve(filename);
    }

    public Resource loadAsResource(String filename) {
        try {
            Path file = load(filename);
            Resource resource = new UrlResource(file.toUri());
            if (resource.exists() && resource.isReadable()) { // Ensure both exist and are readable
                return resource;
            } else {
                logger.warn("Could not read file: {} (exists: {}, readable: {})", filename, resource.exists(), resource.isReadable());
                // Throw a more specific exception perhaps, or stick to RuntimeException
                throw new RuntimeException("Could not read file: " + filename);
            }
        } catch (MalformedURLException e) {
            logger.error("Could not read file due to MalformedURLException: {}", filename, e);
            throw new RuntimeException("Could not read file: " + filename, e);
        }
    }
}