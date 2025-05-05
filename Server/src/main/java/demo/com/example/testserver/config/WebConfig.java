package demo.com.example.testserver.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.nio.file.Path;
import java.nio.file.Paths;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Value("${file.upload-dir}")
    private String uploadDir;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // This allows accessing files directly via /images/** if needed,
        // e.g., http://localhost:8080/images/your-image.jpg
        // Note: The ImageUploadController's GET endpoint provides more control.
        Path uploadPath = Paths.get(uploadDir);
        String uploadPathString = uploadPath.toAbsolutePath().toString();

        // Serve files from the upload directory under the /images/ path
        registry.addResourceHandler("/images/**")
                .addResourceLocations("file:" + uploadPathString + "/");

        // You might have other resource handlers here
        // registry.addResourceHandler("/static/**").addResourceLocations("classpath:/static/");
    }
}