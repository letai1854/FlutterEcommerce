package demo.com.example.testserver.order.dto;

import demo.com.example.testserver.order.model.Order;
import jakarta.validation.constraints.NotNull;

public class UpdateOrderStatusRequestDTO {

    @NotNull(message = "New status cannot be null")
    private Order.OrderStatus newStatus;

    private String adminNotes; // Optional notes from admin

    // Getters and Setters
    public Order.OrderStatus getNewStatus() {
        return newStatus;
    }

    public void setNewStatus(Order.OrderStatus newStatus) {
        this.newStatus = newStatus;
    }

    public String getAdminNotes() {
        return adminNotes;
    }

    public void setAdminNotes(String adminNotes) {
        this.adminNotes = adminNotes;
    }
}
