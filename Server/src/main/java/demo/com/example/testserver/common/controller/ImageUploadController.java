package demo.com.example.testserver.common.controller;

import demo.com.example.testserver.common.dto.ImageUploadResponse;
import demo.com.example.testserver.common.service.ImageStorageService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;
import java.nio.file.Files;

@RestController
@RequestMapping("/api/images")
@CrossOrigin(origins = "*") // Allow requests from any origin
public class ImageUploadController {

    private static final Logger logger = LoggerFactory.getLogger(ImageUploadController.class);

    @Autowired
    private ImageStorageService imageStorageService;

    @PostMapping("/upload")
    public ResponseEntity<ImageUploadResponse> uploadImage(@RequestParam("file") MultipartFile file) {
        try {
            String filename = imageStorageService.store(file);
            logger.info("File uploaded successfully: {}", filename);

            // Construct the relative path for the client to use
            // This path corresponds to the GET endpoint below
            String relativeImagePath = "/api/images/" + filename;

            // Optionally, construct the full URL (useful if client needs it directly)
            // String fileDownloadUri = ServletUriComponentsBuilder.fromCurrentContextPath()
            //         .path("/api/images/")
            //         .path(filename)
            //         .toUriString();
            // logger.info("File download URI: {}", fileDownloadUri);

            return ResponseEntity.status(HttpStatus.CREATED)
                                 .body(new ImageUploadResponse(relativeImagePath));

        } catch (IllegalArgumentException e) {
            logger.warn("Upload failed: {}", e.getMessage());
            return ResponseEntity.badRequest().body(new ImageUploadResponse("Upload failed: " + e.getMessage()));
        } catch (Exception e) {
            logger.error("Could not store file: {}", file.getOriginalFilename(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                                 .body(new ImageUploadResponse("Could not upload the file: " + file.getOriginalFilename() + "!"));
        }
    }

    @GetMapping("/{filename:.+}")
    public ResponseEntity<Resource> serveFile(@PathVariable String filename) {
        try {
            Resource file = imageStorageService.loadAsResource(filename);
            String contentType = Files.probeContentType(file.getFile().toPath());
            if (contentType == null) {
                contentType = "application/octet-stream"; // Default content type if detection fails
            }
            logger.debug("Serving file: {} with content type: {}", filename, contentType);

            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType(contentType))
                    // Optional: Add header to suggest filename for download
                    // .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + file.getFilename() + "\"")
                    .body(file);
        } catch (RuntimeException | IOException e) {
            logger.error("Could not serve file {}: {}", filename, e.getMessage());
            return ResponseEntity.notFound().build();
        }
    }
}