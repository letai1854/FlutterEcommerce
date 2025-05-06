package demo.com.example.testserver.order.dto;

import java.util.Date;

public class OrderStatusHistoryDTO {
    private String status;
    private String notes;
    private Date timestamp;

    // Constructors, Getters, and Setters
    public OrderStatusHistoryDTO() {}

    public OrderStatusHistoryDTO(String status, String notes, Date timestamp) {
        this.status = status;
        this.notes = notes;
        this.timestamp = timestamp;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getNotes() {
        return notes;
    }

    public void setNotes(String notes) {
        this.notes = notes;
    }

    public Date getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(Date timestamp) {
        this.timestamp = timestamp;
    }
}
