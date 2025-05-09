package demo.com.example.testserver.order.service.impl;

import demo.com.example.testserver.coupon.model.Coupon;
import demo.com.example.testserver.coupon.repository.CouponRepository;
import demo.com.example.testserver.order.dto.CreateOrderRequestDTO;
import demo.com.example.testserver.order.dto.OrderDetailRequestDTO;
import demo.com.example.testserver.order.dto.OrderDTO;
import demo.com.example.testserver.order.dto.OrderStatusHistoryDTO;
import demo.com.example.testserver.order.model.Order;
import demo.com.example.testserver.order.model.OrderDetail;
import demo.com.example.testserver.order.model.OrderStatusHistory;
import demo.com.example.testserver.order.repository.OrderRepository;
import demo.com.example.testserver.order.service.OrderService;
import demo.com.example.testserver.product.model.ProductVariant;
import demo.com.example.testserver.product.repository.ProductVariantRepository;
import demo.com.example.testserver.user.model.Address;
import demo.com.example.testserver.user.model.User;
import demo.com.example.testserver.user.repository.AddressRepository;
import demo.com.example.testserver.user.repository.UserRepository;
import demo.com.example.testserver.common.service.EmailService;
import jakarta.persistence.EntityNotFoundException;
import org.modelmapper.ModelMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class OrderServiceImpl implements OrderService {

    private static final Logger logger = LoggerFactory.getLogger(OrderServiceImpl.class);
    private static final BigDecimal POINTS_EARNED_RATE = new BigDecimal("0.0001"); // 100 points per 1,000,000 VND spent
    private static final BigDecimal ONE_POINT_VALUE_IN_VND = new BigDecimal("1000"); // 1 point = 1000 VND

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ProductVariantRepository productVariantRepository;

    @Autowired
    private AddressRepository addressRepository;

    @Autowired
    private CouponRepository couponRepository;

    @Autowired
    private ModelMapper modelMapper;

    @Autowired
    private EmailService emailService;

    @Override
    @Transactional
    public OrderDTO createOrder(String userEmail, CreateOrderRequestDTO requestDTO) {
        logger.info("Attempting to create order for user: {} with request: {}", userEmail, requestDTO);

        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new EntityNotFoundException("User not found with email: " + userEmail));

        Address shippingAddress = addressRepository.findByIdAndUser(requestDTO.getAddressId(), user)
                .orElseThrow(() -> new EntityNotFoundException("Shipping address not found or does not belong to user. Address ID: " + requestDTO.getAddressId()));

        Order order = new Order();
        order.setUser(user);
        order.setRecipientName(shippingAddress.getRecipientName());
        order.setRecipientPhoneNumber(shippingAddress.getPhoneNumber());
        order.setShippingAddress(shippingAddress.getSpecificAddress()); // Assuming getFullAddress() combines street, city etc.
        order.setPaymentMethod(requestDTO.getPaymentMethod());
        // Initialize lists
        order.setOrderDetails(new ArrayList<>());
        order.setStatusHistory(new ArrayList<>());


        BigDecimal subtotal = BigDecimal.ZERO;

        for (OrderDetailRequestDTO itemDTO : requestDTO.getOrderDetails()) {
            ProductVariant variant = productVariantRepository.findById(itemDTO.getProductVariantId())
                    .orElseThrow(() -> new EntityNotFoundException("ProductVariant not found with ID: " + itemDTO.getProductVariantId()));

            if (variant.getStockQuantity() < itemDTO.getQuantity()) {
                throw new IllegalArgumentException("Insufficient stock for ProductVariant ID: " + variant.getId() + ". Requested: " + itemDTO.getQuantity() + ", Available: " + variant.getStockQuantity());
            }

            OrderDetail orderDetail = new OrderDetail();
            orderDetail.setOrder(order);
            orderDetail.setProductVariant(variant);
            orderDetail.setQuantity(itemDTO.getQuantity());
            orderDetail.setPriceAtPurchase(variant.getPrice()); // Assuming ProductVariant has getPrice()
            orderDetail.setProductDiscountPercentage(variant.getDiscountPercentage()); // Assuming ProductVariant has getDiscountPercentage()

            BigDecimal discountedPrice = orderDetail.getPriceAtPurchase().multiply(
                BigDecimal.ONE.subtract(orderDetail.getProductDiscountPercentage().divide(new BigDecimal("100"), 2, RoundingMode.HALF_UP))
            );
            BigDecimal lineTotal = discountedPrice.multiply(new BigDecimal(orderDetail.getQuantity()));
            orderDetail.setLineTotal(lineTotal);

            subtotal = subtotal.add(lineTotal);
            order.getOrderDetails().add(orderDetail);

            variant.setStockQuantity(variant.getStockQuantity() - itemDTO.getQuantity());
            productVariantRepository.save(variant);
        }
        order.setSubtotal(subtotal);

        BigDecimal couponDiscountValue = BigDecimal.ZERO;
        if (requestDTO.getCouponCode() != null && !requestDTO.getCouponCode().trim().isEmpty()) {
            Coupon coupon = couponRepository.findByCode(requestDTO.getCouponCode())
                    .orElseThrow(() -> new EntityNotFoundException("Coupon not found with code: " + requestDTO.getCouponCode()));
            // TODO: Add more coupon validation (expiry, usage limits, applicability)
            if (coupon.getUsageCount() >= coupon.getMaxUsageCount()) {
                throw new IllegalArgumentException("Coupon " + requestDTO.getCouponCode() + " has reached its maximum usage limit.");
            }
            couponDiscountValue = coupon.getDiscountValue(); // Assuming fixed value discount
            order.setCoupon(coupon);
            order.setCouponDiscount(couponDiscountValue);
            coupon.setUsageCount(coupon.getUsageCount() + 1);
            couponRepository.save(coupon);
        }

        BigDecimal numPointsToUse = requestDTO.getPointsToUse() != null ? requestDTO.getPointsToUse() : BigDecimal.ZERO;
        numPointsToUse = numPointsToUse.setScale(0, RoundingMode.DOWN); // Ensure whole points are used

        BigDecimal pointsDiscountAmount = BigDecimal.ZERO;
        boolean pointsUsed = false;

        if (numPointsToUse.compareTo(BigDecimal.ZERO) > 0) {
            if (user.getCustomerPoints() == null || user.getCustomerPoints().compareTo(numPointsToUse) < 0) {
                throw new IllegalArgumentException("User has insufficient points. Available: " +
                        (user.getCustomerPoints() != null ? user.getCustomerPoints().setScale(0, RoundingMode.DOWN) : BigDecimal.ZERO) +
                        ", Requested: " + numPointsToUse);
            }
            pointsDiscountAmount = numPointsToUse.multiply(ONE_POINT_VALUE_IN_VND); // Convert number of points to VND value
            user.setCustomerPoints(user.getCustomerPoints().subtract(numPointsToUse)); // Deduct number of points
            order.setPointsDiscount(pointsDiscountAmount); // Set monetary discount on order
            pointsUsed = true;
        }

        // Calculate potential points earned for this order and store them in the order.
        // Points will be actually awarded to the user when the order is marked as 'da_giao'.
        BigDecimal pointsEarned = subtotal.multiply(POINTS_EARNED_RATE).setScale(0, RoundingMode.DOWN);
        order.setPointsEarned(pointsEarned); // Store number of points earned in this order
        
        // Save user only if points were used (or other user-specific modifications occurred).
        // Earned points are not added to user's balance at this stage.
        if (pointsUsed) {
            userRepository.save(user); 
        }

        // Assuming shippingFee and tax are fixed or calculated simply for now
        order.setShippingFee(requestDTO.getShippingFee() != null ? requestDTO.getShippingFee() : BigDecimal.ZERO); // Or fetch from config/logic
        order.setTax(requestDTO.getTax() != null ? requestDTO.getTax() : BigDecimal.ZERO); // Or fetch from config/logic

        BigDecimal totalAmount = subtotal
                .subtract(couponDiscountValue)
                .subtract(pointsDiscountAmount)
                .add(order.getShippingFee())
                .add(order.getTax());
        order.setTotalAmount(totalAmount.max(BigDecimal.ZERO)); // Ensure total is not negative

        order.setOrderStatus(Order.OrderStatus.cho_xu_ly);
        // TODO: Set payment status based on payment method (e.g., COD -> chua_thanh_toan, Online -> pending/success)
        order.setPaymentStatus(Order.PaymentStatus.chua_thanh_toan); // Default

        OrderStatusHistory initialHistory = new OrderStatusHistory();
        initialHistory.setOrder(order);
        initialHistory.setStatus(order.getOrderStatus());
        initialHistory.setNotes("Order created successfully.");
        // Timestamp will be set by @PrePersist in OrderStatusHistory
        order.getStatusHistory().add(initialHistory);
        
        Order savedOrder = orderRepository.save(order); // Cascades to OrderDetail and OrderStatusHistory

        logger.info("Order created successfully with ID: {}", savedOrder.getId());

        // // Send order confirmation email
        // try {
        //     emailService.sendOrderConfirmationEmail(
        //             user.getEmail(),
        //             user.getFullName(),
        //             savedOrder.getId(),
        //             savedOrder.getTotalAmount()
        //     );
        // } catch (Exception e) {
        //     logger.error("Failed to send order confirmation email for order ID {}: {}", savedOrder.getId(), e.getMessage(), e);
        //     // Do not fail the order creation if email sending fails, just log it.
        // }

        return modelMapper.map(savedOrder, OrderDTO.class);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<OrderDTO> getCurrentUserOrders(String userEmail, Order.OrderStatus status, Pageable pageable) {
        logger.info("Fetching orders for user: {}, status: {}, pageable: {}", userEmail, status, pageable);
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new EntityNotFoundException("User not found with email: " + userEmail));

        Page<Order> orderPage;
        if (status != null) {
            orderPage = orderRepository.findByUserAndOrderStatus(user, status, pageable);
        } else {
            orderPage = orderRepository.findByUser(user, pageable);
        }

        return orderPage.map(order -> modelMapper.map(order, OrderDTO.class));
    }

    @Override
    @Transactional(readOnly = true)
    public OrderDTO getOrderByIdForCurrentUser(String userEmail, Integer orderId) {
        logger.info("Fetching order by ID: {} for user: {}", orderId, userEmail);
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new EntityNotFoundException("User not found with email: " + userEmail));

        Order order = orderRepository.findByIdAndUser(orderId, user)
                .orElseThrow(() -> new EntityNotFoundException("Order not found with ID: " + orderId + " for user: " + userEmail));
        return modelMapper.map(order, OrderDTO.class);
    }

    @Override
    @Transactional(readOnly = true)
    public List<OrderStatusHistoryDTO> getOrderStatusHistoryForCurrentUser(String userEmail, Integer orderId) {
        logger.info("Fetching order status history for order ID: {} for user: {}", orderId, userEmail);
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new EntityNotFoundException("User not found with email: " + userEmail));

        Order order = orderRepository.findByIdAndUser(orderId, user)
                .orElseThrow(() -> new EntityNotFoundException("Order not found with ID: " + orderId + " for user: " + userEmail));

        return order.getStatusHistory().stream()
                .map(history -> modelMapper.map(history, OrderStatusHistoryDTO.class))
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public OrderDTO updateOrderStatusByAdmin(Integer orderId, Order.OrderStatus newStatus, String adminNotes) {
        logger.info("Admin updating status for order ID: {} to {} with notes: {}", orderId, newStatus, adminNotes);
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new EntityNotFoundException("Order not found with ID: " + orderId));

        Order.OrderStatus oldStatus = order.getOrderStatus();
        order.setOrderStatus(newStatus);

        OrderStatusHistory historyEntry = new OrderStatusHistory();
        historyEntry.setOrder(order);
        historyEntry.setStatus(newStatus);
        historyEntry.setNotes(adminNotes != null ? adminNotes : "Order status updated by admin.");
        // Timestamp will be set by @PrePersist

        if (order.getStatusHistory() == null) {
            order.setStatusHistory(new ArrayList<>());
        }
        order.getStatusHistory().add(historyEntry);

        // Award points if order is marked as delivered and wasn't already delivered
        if (newStatus == Order.OrderStatus.da_giao && oldStatus != Order.OrderStatus.da_giao) {
            User orderUser = order.getUser();
            // Ensure pointsEarned is not null and user's current points are initialized
            if (orderUser != null && order.getPointsEarned() != null && order.getPointsEarned().compareTo(BigDecimal.ZERO) > 0) {
                BigDecimal currentPoints = orderUser.getCustomerPoints() != null ? orderUser.getCustomerPoints() : BigDecimal.ZERO;
                orderUser.setCustomerPoints(currentPoints.add(order.getPointsEarned()));
                userRepository.save(orderUser);
                logger.info("Awarded {} points to user {} for order {}. New total points: {}",
                        order.getPointsEarned(), orderUser.getEmail(), orderId, orderUser.getCustomerPoints());
                // Append to notes that points were awarded
                String currentNotes = historyEntry.getNotes();
                historyEntry.setNotes( (currentNotes != null ? currentNotes : "") + " Points awarded: " + order.getPointsEarned().setScale(0, RoundingMode.DOWN));
            }
        }
        // TODO: Implement other side effects of status changes (e.g., payment processing, notifications)

        Order updatedOrder = orderRepository.save(order);
        logger.info("Order ID: {} status updated to {} by admin.", orderId, newStatus);
        return modelMapper.map(updatedOrder, OrderDTO.class);
    }

    @Override
    @Transactional
    public OrderDTO cancelOrderForCurrentUser(String userEmail, Integer orderId) {
        logger.info("Attempting to cancel order ID: {} for user: {}", orderId, userEmail);
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalArgumentException("User not found with email: " + userEmail));

        Order order = orderRepository.findByIdAndUser(orderId, user)
                .orElseThrow(() -> new IllegalArgumentException("Order not found with ID: " + orderId + " for user: " + userEmail));

        // Check if order is in a cancellable state
        if (!(order.getOrderStatus() == Order.OrderStatus.cho_xu_ly || order.getOrderStatus() == Order.OrderStatus.da_xac_nhan)) {
            throw new IllegalArgumentException("Order cannot be cancelled. Current status: " + order.getOrderStatus());
        }

        order.setOrderStatus(Order.OrderStatus.da_huy);

        OrderStatusHistory historyEntry = new OrderStatusHistory();
        historyEntry.setOrder(order);
        historyEntry.setStatus(Order.OrderStatus.da_huy);
        historyEntry.setNotes("Order cancelled by user.");
        historyEntry.setTimestamp(new Date()); // Or let @PrePersist handle it if configured in OrderStatusHistory

        if (order.getStatusHistory() == null) {
            order.setStatusHistory(new ArrayList<>());
        }
        order.getStatusHistory().add(historyEntry);

        Order updatedOrder = orderRepository.save(order);
        logger.info("Order ID: {} cancelled successfully for user: {}", orderId, userEmail);
        return modelMapper.map(updatedOrder, OrderDTO.class);
    }
}
