package demo.com.example.testserver.order.controller;

import demo.com.example.testserver.order.dto.CreateOrderRequestDTO;
import demo.com.example.testserver.order.dto.OrderDTO;
import demo.com.example.testserver.order.dto.OrderStatusHistoryDTO;
import demo.com.example.testserver.order.dto.UpdateOrderStatusRequestDTO; // Import new DTO
import demo.com.example.testserver.order.model.Order;
import demo.com.example.testserver.order.service.OrderService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort; // Import Sort
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import org.springframework.format.annotation.DateTimeFormat; // Import DateTimeFormat

import java.util.List;
import java.util.Date; // Import Date

@RestController
@RequestMapping("/api/orders")
@CrossOrigin(origins = "*")
public class OrderController {

    private static final Logger logger = LoggerFactory.getLogger(OrderController.class);
    private static final long GMT_PLUS_7_OFFSET_MILLIS = 7 * 60 * 60 * 1000;

    @Autowired
    private OrderService orderService;

    private void adjustDatesToGmtPlus7(OrderDTO dto) {
        if (dto == null) {
            return;
        }
        if (dto.getOrderDate() != null) {
            dto.setOrderDate(new Date(dto.getOrderDate().getTime() + GMT_PLUS_7_OFFSET_MILLIS));
        }
        if (dto.getUpdatedDate() != null) {
            dto.setUpdatedDate(new Date(dto.getUpdatedDate().getTime() + GMT_PLUS_7_OFFSET_MILLIS));
        }
    }

    @PostMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> createOrder(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody CreateOrderRequestDTO requestDTO) {
        if (userDetails == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("User not authenticated.");
        }
        try {
            OrderDTO createdOrder = orderService.createOrder(userDetails.getUsername(), requestDTO);
            adjustDatesToGmtPlus7(createdOrder); // Adjust dates
            logger.info("Order created successfully with ID: {} for user: {}", createdOrder.getId(), userDetails.getUsername());
            return new ResponseEntity<>(createdOrder, HttpStatus.CREATED);
        } catch (IllegalArgumentException e) {
            logger.warn("Failed to create order for user {}: {}", userDetails.getUsername(), e.getMessage());
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            logger.error("Error creating order for user {}: {}", userDetails.getUsername(), e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("An unexpected error occurred while creating the order.");
        }
    }

    @GetMapping("/me")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> getCurrentUserOrders(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam(required = false) Order.OrderStatus status,
            @PageableDefault(size = 10, sort = "orderDate", direction = Sort.Direction.DESC) Pageable pageable) {
        if (userDetails == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("User not authenticated.");
        }
        try {
            Page<OrderDTO> ordersPage = orderService.getCurrentUserOrders(userDetails.getUsername(), status, pageable);
            ordersPage.getContent().forEach(this::adjustDatesToGmtPlus7); // Adjust dates for each order in page
            if (ordersPage.isEmpty()) {
                return ResponseEntity.noContent().build();
            }
            return ResponseEntity.ok(ordersPage);
        } catch (Exception e) {
            logger.error("Error fetching orders for user {}: {}", userDetails.getUsername(), e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("An unexpected error occurred while fetching orders.");
        }
    }

    @GetMapping("/me/{orderId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> getOrderDetailsForCurrentUser(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Integer orderId) {
        if (userDetails == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("User not authenticated.");
        }
        try {
            // Check if user has ADMIN role
            boolean isAdmin = userDetails.getAuthorities().stream()
                .anyMatch(auth -> auth.getAuthority().equals("ROLE_ADMIN"));
            
            OrderDTO order;
            if (isAdmin) {
                // If admin, get order regardless of ownership
                order = orderService.getOrderByIdForAdmin(orderId);
                logger.info("Admin {} accessed order ID {}", userDetails.getUsername(), orderId);
            } else {
                // If not admin, only get the order if it belongs to the user
                order = orderService.getOrderByIdForCurrentUser(userDetails.getUsername(), orderId);
                logger.info("User {} accessed their order ID {}", userDetails.getUsername(), orderId);
            }
            
            adjustDatesToGmtPlus7(order); // Adjust dates
            return ResponseEntity.ok(order);
        } catch (IllegalArgumentException | jakarta.persistence.EntityNotFoundException e) {
            logger.warn("Order with ID {} not found for user {}: {}", orderId, userDetails.getUsername(), e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (Exception e) {
            logger.error("Error fetching order ID {} for user {}: {}", orderId, userDetails.getUsername(), e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("An unexpected error occurred while fetching the order.");
        }
    }

    @GetMapping("/me/{orderId}/history")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> getOrderStatusHistoryForCurrentUser(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Integer orderId) {
        if (userDetails == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("User not authenticated.");
        }
        try {
            List<OrderStatusHistoryDTO> history = orderService.getOrderStatusHistoryForCurrentUser(userDetails.getUsername(), orderId);
            if (history.isEmpty()) {
                return ResponseEntity.ok(history); // Return empty list if no history, or 404 if order not found by service
            }
            return ResponseEntity.ok(history);
        } catch (IllegalArgumentException e) { // Or a custom NotFoundException
            logger.warn("Could not retrieve status history for order ID {} for user {}: {}", orderId, userDetails.getUsername(), e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (Exception e) {
            logger.error("Error fetching status history for order ID {} for user {}: {}", orderId, userDetails.getUsername(), e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("An unexpected error occurred while fetching order status history.");
        }
    }

    @PatchMapping("/me/{orderId}/cancel")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> cancelOrderForCurrentUser(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Integer orderId) {
        if (userDetails == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("User not authenticated.");
        }
        try {
            OrderDTO cancelledOrder = orderService.cancelOrderForCurrentUser(userDetails.getUsername(), orderId);
            adjustDatesToGmtPlus7(cancelledOrder); // Adjust dates
            logger.info("User {} cancelled order ID {}", userDetails.getUsername(), orderId);
            return ResponseEntity.ok(cancelledOrder);
        } catch (IllegalArgumentException e) {
            logger.warn("Failed to cancel order ID {} for user {}: {}", orderId, userDetails.getUsername(), e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(e.getMessage());
        } catch (Exception e) {
            logger.error("Error cancelling order ID {} for user {}: {}", orderId, e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("An unexpected error occurred while cancelling the order.");
        }
    }

    @PatchMapping("/{orderId}/status")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> updateOrderStatusByAdmin(
            @PathVariable Integer orderId,
            @Valid @RequestBody UpdateOrderStatusRequestDTO requestDTO) {
        try {
            OrderDTO updatedOrder = orderService.updateOrderStatusByAdmin(orderId, requestDTO.getNewStatus(), requestDTO.getAdminNotes());
            adjustDatesToGmtPlus7(updatedOrder); // Adjust dates
            logger.info("Admin updated status for order ID {} to {}", orderId, requestDTO.getNewStatus());
            return ResponseEntity.ok(updatedOrder);
        } catch (IllegalArgumentException e) { // e.g., Order not found, invalid status transition
            logger.warn("Failed to update status for order ID {}: {}", orderId, e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(e.getMessage());
        } catch (Exception e) {
            logger.error("Error updating status for order ID {}: {}", orderId, e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("An unexpected error occurred while updating order status.");
        }
    }

    @GetMapping("/admin/search")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getOrdersForAdmin(
            @RequestParam(required = false) Integer searchOrderId,
            @RequestParam(required = false) Order.OrderStatus status,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) Date startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) Date endDate,
            @PageableDefault(size = 10, sort = "orderDate", direction = Sort.Direction.DESC) Pageable pageable) {
        try {
            // Basic validation for date range
            if ((startDate != null && endDate == null) || (startDate == null && endDate != null)) {
                return ResponseEntity.badRequest().body("Both startDate and endDate must be provided for date range filtering, or neither.");
            }
            if (startDate != null && endDate != null && startDate.after(endDate)) {
                return ResponseEntity.badRequest().body("startDate cannot be after endDate.");
            }

            Page<OrderDTO> ordersPage = orderService.getOrdersForAdmin(searchOrderId, status, startDate, endDate, pageable);
            ordersPage.getContent().forEach(this::adjustDatesToGmtPlus7); // Adjust dates for each order in page
            if (ordersPage.isEmpty()) {
                return ResponseEntity.noContent().build();
            }
            return ResponseEntity.ok(ordersPage);
        } catch (IllegalArgumentException e) {
            logger.warn("Invalid argument for admin order search: {}", e.getMessage());
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            logger.error("Error during admin order search: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("An unexpected error occurred while searching orders.");
        }
    }

    @GetMapping("/admin/{orderId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getOrderDetailsForAdmin(@PathVariable Integer orderId) {
        try {
            OrderDTO order = orderService.getOrderByIdForAdmin(orderId);
            adjustDatesToGmtPlus7(order); // Adjust dates
            return ResponseEntity.ok(order);
        } catch (IllegalArgumentException | jakarta.persistence.EntityNotFoundException e) {
            logger.warn("Order with ID {} not found for admin access: {}", orderId, e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (Exception e) {
            logger.error("Error fetching order ID {} for admin: {}", orderId, e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("An unexpected error occurred while fetching the order.");
        }
    }
}
