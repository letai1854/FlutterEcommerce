package demo.com.example.testserver.order.service.impl;

import demo.com.example.testserver.coupon.model.Coupon;
import demo.com.example.testserver.coupon.repository.CouponRepository;
import demo.com.example.testserver.order.dto.CreateOrderRequestDTO;
import demo.com.example.testserver.order.dto.OrderDetailRequestDTO;
import demo.com.example.testserver.order.dto.OrderDTO;
import demo.com.example.testserver.order.dto.OrderStatusHistoryDTO;
import demo.com.example.testserver.order.service.OrderMapper;
import demo.com.example.testserver.order.model.Order;
import demo.com.example.testserver.order.model.OrderDetail;
import demo.com.example.testserver.order.model.OrderStatusHistory;
import demo.com.example.testserver.order.repository.OrderRepository;
import demo.com.example.testserver.order.service.OrderService;
import demo.com.example.testserver.product.model.Product;
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
import java.util.Calendar;
import java.util.TimeZone;

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

    @Autowired
    private OrderMapper orderMapper; // Add the OrderMapper

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

        // Step 1: Calculate subtotal based on product prices, quantities, and individual product discounts
        for (OrderDetailRequestDTO itemDTO : requestDTO.getOrderDetails()) {
            ProductVariant variant = productVariantRepository.findById(itemDTO.getProductVariantId())
                    .orElseThrow(() -> new EntityNotFoundException("ProductVariant not found with ID: " + itemDTO.getProductVariantId()));

            if (variant.getStockQuantity() < itemDTO.getQuantity()) {
                throw new IllegalArgumentException("Insufficient stock for ProductVariant ID: " + variant.getId() + ". Requested: " + itemDTO.getQuantity() + ", Available: " + variant.getStockQuantity());
            }

            Product product = variant.getProduct();
            if (product == null) {
                throw new IllegalStateException("Product not found for ProductVariant ID: " + variant.getId());
            }

            BigDecimal mainProductDiscount = product.getDiscountPercentage();
            BigDecimal discountToApply = BigDecimal.ZERO; // Default to zero discount

            if (mainProductDiscount != null && mainProductDiscount.compareTo(BigDecimal.ZERO) > 0) {
                discountToApply = mainProductDiscount;
            }

            OrderDetail orderDetail = new OrderDetail();
            orderDetail.setOrder(order);
            orderDetail.setProductVariant(variant);
            orderDetail.setQuantity(itemDTO.getQuantity());
            orderDetail.setPriceAtPurchase(variant.getPrice()); 
            orderDetail.setProductDiscountPercentage(discountToApply); // Store the discount from the main product

            BigDecimal unitPrice = orderDetail.getPriceAtPurchase();
            BigDecimal currentItemDiscountPercentage = orderDetail.getProductDiscountPercentage();

            BigDecimal discountedUnitPrice;
            if (currentItemDiscountPercentage != null && currentItemDiscountPercentage.compareTo(BigDecimal.ZERO) > 0) {
                BigDecimal discountRate = currentItemDiscountPercentage.divide(new BigDecimal("100"), 4, RoundingMode.HALF_UP);
                BigDecimal effectivePriceFactor = BigDecimal.ONE.subtract(discountRate);
                discountedUnitPrice = unitPrice.multiply(effectivePriceFactor);
            } else {
                discountedUnitPrice = unitPrice;
            }
            
            BigDecimal lineTotal = discountedUnitPrice.multiply(new BigDecimal(orderDetail.getQuantity()))
                                                  .setScale(2, RoundingMode.HALF_UP);
            orderDetail.setLineTotal(lineTotal);

            subtotal = subtotal.add(lineTotal);
            order.getOrderDetails().add(orderDetail);

            variant.setStockQuantity(variant.getStockQuantity() - itemDTO.getQuantity());
            productVariantRepository.save(variant);
        }
        order.setSubtotal(subtotal);

        // Step 2: Apply coupon discount, if any
        BigDecimal couponDiscountValue = BigDecimal.ZERO;
        if (requestDTO.getCouponCode() != null && !requestDTO.getCouponCode().trim().isEmpty()) {
            Coupon coupon = couponRepository.findByCode(requestDTO.getCouponCode())
                    .orElseThrow(() -> new EntityNotFoundException("Coupon not found with code: " + requestDTO.getCouponCode()));
            if (coupon.getUsageCount() >= coupon.getMaxUsageCount()) {
                throw new IllegalArgumentException("Coupon " + requestDTO.getCouponCode() + " has reached its maximum usage limit.");
            }
            couponDiscountValue = coupon.getDiscountValue();
            order.setCoupon(coupon);
            order.setCouponDiscount(couponDiscountValue);
            coupon.setUsageCount(coupon.getUsageCount() + 1);
            couponRepository.save(coupon);
        }

        // Step 3: Apply points discount, if any
        BigDecimal numPointsToUse = requestDTO.getPointsToUse() != null ? requestDTO.getPointsToUse() : BigDecimal.ZERO;
        numPointsToUse = numPointsToUse.setScale(0, RoundingMode.DOWN);

        BigDecimal pointsDiscountAmount = BigDecimal.ZERO;
        boolean pointsUsed = false;

        if (numPointsToUse.compareTo(BigDecimal.ZERO) > 0) {
            if (user.getCustomerPoints() == null || user.getCustomerPoints().compareTo(numPointsToUse) < 0) {
                throw new IllegalArgumentException("User has insufficient points. Available: " +
                        (user.getCustomerPoints() != null ? user.getCustomerPoints().setScale(0, RoundingMode.DOWN) : BigDecimal.ZERO) +
                        ", Requested: " + numPointsToUse);
            }
            pointsDiscountAmount = numPointsToUse.multiply(ONE_POINT_VALUE_IN_VND);
            user.setCustomerPoints(user.getCustomerPoints().subtract(numPointsToUse));
            order.setPointsDiscount(pointsDiscountAmount);
            pointsUsed = true;
        }

        BigDecimal pointsEarned = subtotal.multiply(POINTS_EARNED_RATE).setScale(0, RoundingMode.DOWN);
        order.setPointsEarned(pointsEarned);
        
        if (pointsUsed) {
            userRepository.save(user); 
        }

        order.setShippingFee(requestDTO.getShippingFee() != null ? requestDTO.getShippingFee() : BigDecimal.ZERO);
        order.setTax(requestDTO.getTax() != null ? requestDTO.getTax() : BigDecimal.ZERO);

        BigDecimal totalAmount = subtotal
                .subtract(couponDiscountValue)
                .subtract(pointsDiscountAmount)
                .add(order.getShippingFee())
                .add(order.getTax());
        order.setTotalAmount(totalAmount.max(BigDecimal.ZERO));

        order.setOrderStatus(Order.OrderStatus.cho_xu_ly);
        order.setPaymentStatus(Order.PaymentStatus.chua_thanh_toan);

        OrderStatusHistory initialHistory = new OrderStatusHistory();
        initialHistory.setOrder(order);
        initialHistory.setStatus(order.getOrderStatus());
        initialHistory.setNotes("Order created successfully.");
        order.getStatusHistory().add(initialHistory);
        
        Order savedOrder = orderRepository.save(order);

        logger.info("Order created successfully with ID: {}", savedOrder.getId());

        return orderMapper.toOrderDTO(savedOrder);
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

        return orderPage.map(order -> orderMapper.toOrderDTO(order));
    }

    @Override
    @Transactional(readOnly = true)
    public OrderDTO getOrderByIdForCurrentUser(String userEmail, Integer orderId) {
        logger.info("Fetching order by ID: {} for user: {}", orderId, userEmail);
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new EntityNotFoundException("User not found with email: " + userEmail));

        Order order = orderRepository.findByIdAndUser(orderId, user)
                .orElseThrow(() -> new EntityNotFoundException("Order not found with ID: " + orderId + " for user: " + userEmail));
        return orderMapper.toOrderDTO(order);
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
                .map(history -> orderMapper.toOrderStatusHistoryDTO(history))
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

        if (order.getStatusHistory() == null) {
            order.setStatusHistory(new ArrayList<>());
        }
        order.getStatusHistory().add(historyEntry);

        if (newStatus == Order.OrderStatus.da_giao && oldStatus != Order.OrderStatus.da_giao) {
            User orderUser = order.getUser();
            if (orderUser != null && order.getPointsEarned() != null && order.getPointsEarned().compareTo(BigDecimal.ZERO) > 0) {
                BigDecimal currentPoints = orderUser.getCustomerPoints() != null ? orderUser.getCustomerPoints() : BigDecimal.ZERO;
                orderUser.setCustomerPoints(currentPoints.add(order.getPointsEarned()));
                userRepository.save(orderUser);
                logger.info("Awarded {} points to user {} for order {}. New total points: {}",
                        order.getPointsEarned(), orderUser.getEmail(), orderId, orderUser.getCustomerPoints());
                String currentNotes = historyEntry.getNotes();
                historyEntry.setNotes( (currentNotes != null ? currentNotes : "") + " Points awarded: " + order.getPointsEarned().setScale(0, RoundingMode.DOWN));
            }
        }

        if (newStatus == Order.OrderStatus.da_giao && order.getPaymentStatus() == Order.PaymentStatus.chua_thanh_toan) {
            order.setPaymentStatus(Order.PaymentStatus.da_thanh_toan);
            logger.info("Order ID: {} payment status updated to {} as order is delivered.", orderId, Order.PaymentStatus.da_thanh_toan);
            String currentNotes = historyEntry.getNotes();
            historyEntry.setNotes( (currentNotes != null ? currentNotes : "") + " Payment status updated to 'da_thanh_toan'.");
        }

        Order updatedOrder = orderRepository.save(order);
        logger.info("Order ID: {} status updated to {} by admin.", orderId, newStatus);
        return orderMapper.toOrderDTO(updatedOrder);
    }

    @Override
    @Transactional
    public OrderDTO cancelOrderForCurrentUser(String userEmail, Integer orderId) {
        logger.info("Attempting to cancel order ID: {} for user: {}", orderId, userEmail);
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalArgumentException("User not found with email: " + userEmail));

        Order order = orderRepository.findByIdAndUser(orderId, user)
                .orElseThrow(() -> new IllegalArgumentException("Order not found with ID: " + orderId + " for user: " + userEmail));

        if (!(order.getOrderStatus() == Order.OrderStatus.cho_xu_ly || order.getOrderStatus() == Order.OrderStatus.da_xac_nhan)) {
            throw new IllegalArgumentException("Order cannot be cancelled. Current status: " + order.getOrderStatus());
        }

        order.setOrderStatus(Order.OrderStatus.da_huy);

        OrderStatusHistory historyEntry = new OrderStatusHistory();
        historyEntry.setOrder(order);
        historyEntry.setStatus(Order.OrderStatus.da_huy);
        historyEntry.setNotes("Order cancelled by user.");
        historyEntry.setTimestamp(new Date());

        if (order.getStatusHistory() == null) {
            order.setStatusHistory(new ArrayList<>());
        }
        order.getStatusHistory().add(historyEntry);

        Order updatedOrder = orderRepository.save(order);
        logger.info("Order ID: {} cancelled successfully for user: {}", orderId, userEmail);
        return orderMapper.toOrderDTO(updatedOrder);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<OrderDTO> getOrdersForAdmin(Integer userId, Order.OrderStatus status, Date startDate, Date endDate, Pageable pageable) {
        logger.info("Admin fetching orders with filters - userId: {}, status: {}, startDate: {}, endDate: {}", 
                userId, status, startDate, endDate);
        
        Page<Order> orderPage;
        
        if (userId != null) {
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new EntityNotFoundException("User not found with ID: " + userId));
            
            if (status != null) {
                orderPage = orderRepository.findByUserAndOrderStatus(user, status, pageable);
            } else {
                orderPage = orderRepository.findByUser(user, pageable);
            }
        } else if (status != null) {
            orderPage = orderRepository.findByOrderStatus(status, pageable);
        } else {
            orderPage = orderRepository.findAll(pageable);
        }
        
        if (startDate != null && endDate != null) {
            // Adjust endDate to include the entire day in UTC
            Calendar calendar = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
            calendar.setTime(endDate);
            calendar.set(Calendar.HOUR_OF_DAY, 23);
            calendar.set(Calendar.MINUTE, 59);
            calendar.set(Calendar.SECOND, 59);
            calendar.set(Calendar.MILLISECOND, 999);
            Date adjustedEndDate = calendar.getTime();

            List<Order> filteredList = orderPage.getContent().stream()
                    .filter(order -> {
                        Date orderDate = order.getOrderDate();
                        return orderDate != null &&
                               (orderDate.after(startDate) || orderDate.equals(startDate)) &&
                               (orderDate.before(adjustedEndDate) || orderDate.equals(adjustedEndDate));
                    })
                    .collect(Collectors.toList());

            int start = (int) pageable.getOffset();
            int end = Math.min((start + pageable.getPageSize()), filteredList.size());

            if (start > filteredList.size()) {
                start = 0;
                end = 0;
            }

            List<Order> pageContent = (start < end) ? filteredList.subList(start, end) : new ArrayList<>();
            return new org.springframework.data.domain.PageImpl<>(
                    pageContent.stream().map(order -> orderMapper.toOrderDTO(order)).collect(Collectors.toList()),
                    pageable,
                    filteredList.size()
            );
        }

        return orderPage.map(order -> orderMapper.toOrderDTO(order));
    }
}
