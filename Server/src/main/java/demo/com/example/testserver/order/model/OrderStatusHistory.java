package demo.com.example.testserver.order.model;

import jakarta.persistence.*;
import java.util.Date;

@Entity
@Table(name = "lich_su_trang_thai_don_hang")
public class OrderStatusHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "don_hang_id", nullable = false)
    private Order order;

    @Column(name = "trang_thai", nullable = false)
    @Enumerated(EnumType.STRING)
    private Order.OrderStatus status; // Reuse OrderStatus enum

    @Column(name = "ghi_chu", columnDefinition = "TEXT")
    private String notes;

    @Column(name = "thoi_gian_cap_nhat", updatable = false)
    @Temporal(TemporalType.TIMESTAMP)
    private Date timestamp;

    // Lifecycle Callbacks
    @PrePersist
    protected void onCreate() {
        timestamp = new Date();
    }

    // Constructors
    public OrderStatusHistory() {}

    // Getters and Setters
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Order getOrder() {
        return order;
    }

    public void setOrder(Order order) {
        this.order = order;
    }

    public Order.OrderStatus getStatus() {
        return status;
    }

    public void setStatus(Order.OrderStatus status) {
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
