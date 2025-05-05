package demo.com.example.testserver.common.dto;

public class ImageUploadResponse {
    private String imagePath; // Relative path or filename

    public ImageUploadResponse(String imagePath) {
        this.imagePath = imagePath;
    }

    // Getter
    public String getImagePath() {
        return imagePath;
    }

    // Setter (optional)
    public void setImagePath(String imagePath) {
        this.imagePath = imagePath;
    }
}