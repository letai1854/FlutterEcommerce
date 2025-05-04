package demo.com.example.testserver.common.controller;

import demo.com.example.testserver.common.service.ImageStorageService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.core.io.ClassPathResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.test.context.support.WithMockUser; // Import WithMockUser
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Comparator;
import java.util.stream.Stream;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.assertj.core.api.Assertions.assertThat;


@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test") // Optional: Use if you have specific test configurations
@TestPropertySource(properties = "file.upload-dir=./target/test-uploads/images") // Use a specific test upload dir
public class ImageUploadControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ImageStorageService imageStorageService; // Inject service for potential cleanup or direct interaction if needed

    // Use a fixed test directory managed by TestPropertySource
    private static final Path testUploadDirPath = Paths.get("./target/test-uploads/images");

    @BeforeEach
    void setUp() throws IOException {
        // Ensure the test directory is clean before each test
        if (Files.exists(testUploadDirPath)) {
            try (Stream<Path> walk = Files.walk(testUploadDirPath)) {
                walk.sorted(Comparator.reverseOrder())
                    .forEach(path -> {
                        try {
                            Files.delete(path);
                        } catch (IOException e) {
                            System.err.println("Failed to delete path: " + path + " - " + e.getMessage());
                        }
                    });
            }
        }
        Files.createDirectories(testUploadDirPath);
    }

    @AfterEach
    void tearDown() throws IOException {
         // Clean up after each test (optional, BeforeEach might be sufficient)
        if (Files.exists(testUploadDirPath)) {
             try (Stream<Path> walk = Files.walk(testUploadDirPath)) {
                walk.sorted(Comparator.reverseOrder())
                    .forEach(path -> {
                        try {
                            // Avoid deleting the root test dir itself if needed across tests, just its contents
                            if (!path.equals(testUploadDirPath)) {
                                Files.delete(path);
                            }
                        } catch (IOException e) {
                             System.err.println("Failed to delete path during teardown: " + path + " - " + e.getMessage());
                        }
                    });
            }
        }
    }


    @Test
    @WithMockUser // Simulate an authenticated user for this test
    void uploadImage_Success() throws Exception {
        // Arrange: Load the test image from classpath resources
        ClassPathResource resource = new ClassPathResource("testimage/test.jpg");
        assertThat(resource.exists()).isTrue(); // Make sure the test image exists

        MockMultipartFile mockFile = new MockMultipartFile(
                "file", // Parameter name expected by the controller
                "test.jpg", // Original filename
                MediaType.IMAGE_JPEG_VALUE,
                resource.getInputStream());

        // Act & Assert
        MvcResult result = mockMvc.perform(multipart("/api/images/upload").file(mockFile))
                .andExpect(status().isCreated()) // Expect 201 Created
                // Use contentTypeCompatibleWith to handle potential charset parameters
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.imagePath", startsWith("/api/images/"))) // Check if path starts correctly
                .andExpect(jsonPath("$.imagePath", endsWith(".jpg"))) // Check if extension is preserved
                .andReturn();

        // Verify file was actually saved
        String imagePath = result.getResponse().getContentAsString().split(":")[1].replace("\"", "").replace("}", "");
        String filename = imagePath.substring(imagePath.lastIndexOf('/') + 1);
        Path savedFilePath = testUploadDirPath.resolve(filename);
        assertThat(Files.exists(savedFilePath)).isTrue();
    }

    @Test
    @WithMockUser // Simulate an authenticated user for the upload part
    void serveFile_Success() throws Exception {
        // Arrange: First upload a file (requires authentication)
        ClassPathResource resource = new ClassPathResource("testimage/test.jpg");
        MockMultipartFile mockFile = new MockMultipartFile("file", "test-serve.jpg", MediaType.IMAGE_JPEG_VALUE, resource.getInputStream());

        MvcResult uploadResult = mockMvc.perform(multipart("/api/images/upload").file(mockFile))
                .andExpect(status().isCreated())
                .andReturn();

        String imagePath = uploadResult.getResponse().getContentAsString().split(":")[1].replace("\"", "").replace("}", "");
        String filename = imagePath.substring(imagePath.lastIndexOf('/') + 1);

        // Act & Assert: Request the uploaded file (GET is public, no @WithMockUser needed here, but doesn't hurt)
        mockMvc.perform(get("/api/images/{filename}", filename))
                .andExpect(status().isOk())
                // Use contentTypeCompatibleWith to handle potential charset parameters
                .andExpect(content().contentTypeCompatibleWith(MediaType.IMAGE_JPEG))
                .andExpect(header().string(HttpHeaders.CONTENT_LENGTH, greaterThan("0"))); // Check file is not empty
    }

    @Test
    void serveFile_NotFound() throws Exception {
        // Arrange: A filename that doesn't exist
        String nonExistentFilename = "non-existent-image.png";

        // Act & Assert
        mockMvc.perform(get("/api/images/{filename}", nonExistentFilename))
                .andExpect(status().isNotFound()); // Expect 404 Not Found
    }

     @Test
     @WithMockUser // Simulate an authenticated user for this test
    void uploadImage_EmptyFile() throws Exception {
        // Arrange
        MockMultipartFile mockFile = new MockMultipartFile(
                "file",
                "empty.txt",
                MediaType.TEXT_PLAIN_VALUE,
                new byte[0]); // Empty content

        // Act & Assert
        mockMvc.perform(multipart("/api/images/upload").file(mockFile))
                .andExpect(status().isBadRequest()) // Expect 400 Bad Request
                .andExpect(jsonPath("$.imagePath", containsString("Upload failed: Failed to store empty file.")));
    }
}