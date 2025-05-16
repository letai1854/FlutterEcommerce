package demo.com.example.testserver.order.service;

import demo.com.example.testserver.order.dto.CreateOrderRequestDTO;
import demo.com.example.testserver.order.dto.OrderDTO;
import demo.com.example.testserver.order.dto.OrderStatusHistoryDTO;
import demo.com.example.testserver.order.model.Order;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.util.List;
import java.util.Date; // Import Date

public interface OrderService {
    
    /**
     * Creates a new order for the given user
     * 
     * @param userEmail Email of the user creating the order
     * @param requestDTO Order creation request data
     * @return The created order details
     */
    OrderDTO createOrder(String userEmail, CreateOrderRequestDTO requestDTO);
    
    /**
     * Retrieves orders for the current user with optional status filtering
     * 
     * @param userEmail Email of the current user
     * @param status Optional status filter
     * @param pageable Pagination information
     * @return Page of orders for the user
     */
    Page<OrderDTO> getCurrentUserOrders(String userEmail, Order.OrderStatus status, Pageable pageable);
    
    /**
     * Gets a specific order by ID for the current user
     * 
     * @param userEmail Email of the current user
     * @param orderId ID of the order to retrieve
     * @return The requested order details
     */
    OrderDTO getOrderByIdForCurrentUser(String userEmail, Integer orderId);
    
    /**
     * Gets the status history for a specific order
     * 
     * @param userEmail Email of the current user
     * @param orderId ID of the order
     * @return List of status history entries
     */
    List<OrderStatusHistoryDTO> getOrderStatusHistoryForCurrentUser(String userEmail, Integer orderId);
    
    /**
     * Updates an order's status (admin only operation)
     * 
     * @param orderId ID of the order to update
     * @param newStatus New status to set
     * @param adminNotes Optional admin notes about the status change
     * @return Updated order details
     */
    OrderDTO updateOrderStatusByAdmin(Integer orderId, Order.OrderStatus newStatus, String adminNotes);
    
    /**
     * Cancels an order for the current user
     * 
     * @param userEmail Email of the current user
     * @param orderId ID of the order to cancel
     * @return Updated order details
     */
    OrderDTO cancelOrderForCurrentUser(String userEmail, Integer orderId);
    
    /**
     * Retrieves orders for admin with optional filters
     * 
     * @param searchOrderId Optional order ID to search
     * @param status Optional status filter
     * @param startDate Optional start date filter
     * @param endDate Optional end date filter
     * @param pageable Pagination information
     * @return Page of orders for admin
     */
    Page<OrderDTO> getOrdersForAdmin(Integer searchOrderId, Order.OrderStatus status, Date startDate, Date endDate, Pageable pageable);
    
    /**
     * Gets a specific order by ID for admin users
     * 
     * @param orderId ID of the order to retrieve
     * @return The requested order details
     */
    OrderDTO getOrderByIdForAdmin(Integer orderId);
}
