package demo.com.example.testserver.product.dto;

import java.util.Date;

public class CategoryDTO {
    private Integer id;
    private String name;
    private String imageUrl;
    private Date createdDate;
    private Date updatedDate;

    // Constructors
    public CategoryDTO() {}

    public CategoryDTO(Integer id, String name, String imageUrl, Date createdDate, Date updatedDate) {
        this.id = id;
        this.name = name;
        this.imageUrl = imageUrl;
        this.createdDate = createdDate;
        this.updatedDate = updatedDate;
    }

    // Getters and Setters
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public Date getCreatedDate() {
        return createdDate;
    }

    public void setCreatedDate(Date createdDate) {
        this.createdDate = createdDate;
    }

    public Date getUpdatedDate() {
        return updatedDate;
    }

    public void setUpdatedDate(Date updatedDate) {
        this.updatedDate = updatedDate;
    }
}
