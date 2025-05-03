package demo.com.example.testserver.coupon.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.util.Date;
import java.util.List;

import demo.com.example.testserver.order.model.Order;

@Entity
@Table(name = "ma_giam_gia")
public class Coupon {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "ma_code", nullable = false, unique = true, length = 10)
    private String code;

    @Column(name = "gia_tri_giam", nullable = false, precision = 12, scale = 2)
    private BigDecimal discountValue;

    @Column(name = "so_lan_su_dung_toi_da", nullable = false)
    private Integer maxUsageCount = 10;

    @Column(name = "so_lan_da_su_dung", nullable = false)
    private Integer usageCount = 0;

    @Column(name = "ngay_tao", updatable = false)
    @Temporal(TemporalType.TIMESTAMP)
    private Date createdDate;

    @OneToMany(mappedBy = "coupon")
    private List<Order> orders;

    // Lifecycle Callbacks
    @PrePersist
    protected void onCreate() {
        createdDate = new Date();
    }

    // Constructors
    public Coupon() {}

    // Getters and Setters
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public BigDecimal getDiscountValue() {
        return discountValue;
    }

    public void setDiscountValue(BigDecimal discountValue) {
        this.discountValue = discountValue;
    }

    public Integer getMaxUsageCount() {
        return maxUsageCount;
    }

    public void setMaxUsageCount(Integer maxUsageCount) {
        this.maxUsageCount = maxUsageCount;
    }

    public Integer getUsageCount() {
        return usageCount;
    }

    public void setUsageCount(Integer usageCount) {
        this.usageCount = usageCount;
    }

    public Date getCreatedDate() {
        return createdDate;
    }

    public void setCreatedDate(Date createdDate) {
        this.createdDate = createdDate;
    }

     public List<Order> getOrders() {
        return orders;
    }

    public void setOrders(List<Order> orders) {
        this.orders = orders;
    }
}
