package demo.com.example.testserver.order.service;

import demo.com.example.testserver.order.dto.OrderDTO;
import demo.com.example.testserver.order.dto.OrderDetailDTO;
import demo.com.example.testserver.order.dto.OrderStatusHistoryDTO;
import demo.com.example.testserver.order.model.Order;
import demo.com.example.testserver.order.model.OrderDetail;
import demo.com.example.testserver.order.model.OrderStatusHistory;
import demo.com.example.testserver.product.model.Product;
import demo.com.example.testserver.product.model.ProductVariant;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.stream.Collectors;

@Component
public class OrderMapper {

    public OrderDTO toOrderDTO(Order order) {
        if (order == null) {
            return null;
        }

        OrderDTO dto = new OrderDTO();
        dto.setId(order.getId());
        dto.setOrderDate(order.getOrderDate());
        dto.setUpdatedDate(order.getUpdatedDate());
        dto.setRecipientName(order.getRecipientName());
        dto.setRecipientPhoneNumber(order.getRecipientPhoneNumber());
        dto.setShippingAddress(order.getShippingAddress());
        dto.setSubtotal(order.getSubtotal());
        dto.setCouponDiscount(order.getCouponDiscount());
        dto.setPointsDiscount(order.getPointsDiscount());
        dto.setShippingFee(order.getShippingFee());
        dto.setTax(order.getTax());
        dto.setTotalAmount(order.getTotalAmount());
        dto.setPaymentMethod(order.getPaymentMethod());
        dto.setPaymentStatus(order.getPaymentStatus().name());
        dto.setOrderStatus(order.getOrderStatus().name());
        dto.setPointsEarned(order.getPointsEarned());
        
        // Set coupon code if coupon exists
        if (order.getCoupon() != null) {
            dto.setCouponCode(order.getCoupon().getCode());
        }
        
        // Map order details
        if (order.getOrderDetails() != null) {
            List<OrderDetailDTO> orderDetailDTOs = order.getOrderDetails().stream()
                    .map(this::toOrderDetailDTO)
                    .collect(Collectors.toList());
            dto.setOrderDetails(orderDetailDTOs);
        }
        
        return dto;
    }

    public OrderDetailDTO toOrderDetailDTO(OrderDetail orderDetail) {
        if (orderDetail == null) {
            return null;
        }
        
        OrderDetailDTO dto = new OrderDetailDTO();
        
        ProductVariant variant = orderDetail.getProductVariant();
        if (variant != null) {
            dto.setProductVariantId(variant.getId());
            dto.setVariantName(variant.getName());
            dto.setPriceAtPurchase(orderDetail.getPriceAtPurchase());
            dto.setProductDiscountPercentage(orderDetail.getProductDiscountPercentage());
            
            // Get product information
            Product product = variant.getProduct();
            if (product != null) {
                dto.setProductName(product.getName());
                
                // Set imageUrl - first try to get variant image, then product's main image,
                // then first product image if any
                if (variant.getVariantImageUrl() != null && !variant.getVariantImageUrl().isEmpty()) {
                    dto.setImageUrl(variant.getVariantImageUrl());
                } else if (product.getMainImageUrl() != null && !product.getMainImageUrl().isEmpty()) {
                    dto.setImageUrl(product.getMainImageUrl());
                } else if (product.getImages() != null && !product.getImages().isEmpty()) {
                    dto.setImageUrl(product.getImages().get(0).getImageUrl());
                }
            }
        }
        
        dto.setQuantity(orderDetail.getQuantity());
        dto.setLineTotal(orderDetail.getLineTotal());
        
        return dto;
    }

    public OrderStatusHistoryDTO toOrderStatusHistoryDTO(OrderStatusHistory history) {
        if (history == null) {
            return null;
        }
        
        return new OrderStatusHistoryDTO(
            history.getStatus().name(),
            history.getNotes(),
            history.getTimestamp()
        );
    }
}
