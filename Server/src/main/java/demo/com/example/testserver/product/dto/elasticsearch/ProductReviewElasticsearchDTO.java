package demo.com.example.testserver.product.dto.elasticsearch;

import org.springframework.data.elasticsearch.annotations.Field;
import org.springframework.data.elasticsearch.annotations.FieldType;

import java.util.Date;

public class ProductReviewElasticsearchDTO {

    @Field(type = FieldType.Integer)
    private Integer id;

    @Field(type = FieldType.Text, analyzer = "standard")
    private String reviewerName; // Combined from User or anonymous

    @Field(type = FieldType.Byte)
    private Byte rating;

    @Field(type = FieldType.Text, analyzer = "standard")
    private String comment;

    @Field(type = FieldType.Date)
    private Date reviewTime;

    // Getters and Setters
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getReviewerName() {
        return reviewerName;
    }

    public void setReviewerName(String reviewerName) {
        this.reviewerName = reviewerName;
    }

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

    public Date getReviewTime() {
        return reviewTime;
    }

    public void setReviewTime(Date reviewTime) {
        this.reviewTime = reviewTime;
    }
}
