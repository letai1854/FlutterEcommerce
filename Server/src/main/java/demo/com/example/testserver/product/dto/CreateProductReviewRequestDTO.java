package demo.com.example.testserver.product.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;

public class CreateProductReviewRequestDTO {

    @Min(value = 1, message = "Rating must be at least 1")
    @Max(value = 5, message = "Rating must be at most 5")
    private Byte rating; // Nullable, as anonymous users can't rate

    @Size(max = 1000, message = "Comment cannot exceed 1000 characters")
    private String comment; // Nullable

    @Size(max = 100, message = "Anonymous reviewer name cannot exceed 100 characters")
    private String reviewerName; // For anonymous users

    // Getters and Setters
    public Byte getRating() {
        return rating;
    }

    public void setRating(Byte rating) {
        this.rating = rating;
    }

    public String getComment() {
        return comment;
    }

    public void setComment(String comment) {
        this.comment = comment;
    }

    public String getReviewerName() {
        return reviewerName;
    }

    public void setReviewerName(String anonymousReviewerName) {
        this.reviewerName = anonymousReviewerName;
    }
}
