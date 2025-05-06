package demo.com.example.testserver.order.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import demo.com.example.testserver.order.dto.*;
import demo.com.example.testserver.order.model.Order;
import demo.com.example.testserver.order.service.OrderService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.Date;
import java.util.List;

import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.is;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class OrderControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private OrderService orderService;

    @Autowired
    private ObjectMapper objectMapper;

    private CreateOrderRequestDTO createOrderRequestDTO;
    private OrderDTO orderDTO;
    private OrderDetailDTO orderDetailDTO;
    private OrderStatusHistoryDTO orderStatusHistoryDTO;
    private UpdateOrderStatusRequestDTO updateOrderStatusRequestDTO;

    private final String TEST_USER_EMAIL = "user@example.com";
    private final String ADMIN_USER_EMAIL = "admin@example.com";

    @BeforeEach
    void setUp() {
        orderDetailDTO = new OrderDetailDTO(1, "Test Product", "Variant A", "image.jpg", 2, new BigDecimal("50.00"), BigDecimal.ZERO, new BigDecimal("100.00"));

        orderDTO = new OrderDTO();
        orderDTO.setId(1);
        orderDTO.setOrderDate(new Date());
        orderDTO.setTotalAmount(new BigDecimal("100.00"));
        orderDTO.setOrderStatus(Order.OrderStatus.cho_xu_ly.name());
        orderDTO.setOrderDetails(List.of(orderDetailDTO));
        orderDTO.setRecipientName("Test User");
        orderDTO.setShippingAddress("123 Test St");

        OrderDetailRequestDTO orderDetailRequestDTO = new OrderDetailRequestDTO();
        orderDetailRequestDTO.setProductVariantId(1);
        orderDetailRequestDTO.setQuantity(2);

        createOrderRequestDTO = new CreateOrderRequestDTO();
        createOrderRequestDTO.setAddressId(1);
        createOrderRequestDTO.setPaymentMethod("COD");
        createOrderRequestDTO.setOrderDetails(List.of(orderDetailRequestDTO));

        orderStatusHistoryDTO = new OrderStatusHistoryDTO(Order.OrderStatus.cho_xu_ly.name(), "Order created", new Date());

        updateOrderStatusRequestDTO = new UpdateOrderStatusRequestDTO();
        updateOrderStatusRequestDTO.setNewStatus(Order.OrderStatus.dang_giao);
        updateOrderStatusRequestDTO.setAdminNotes("Order shipped by admin.");
    }

    @Test
    @WithMockUser(username = TEST_USER_EMAIL)
    void createOrder_validRequest_shouldReturnCreatedOrder() throws Exception {
        when(orderService.createOrder(eq(TEST_USER_EMAIL), any(CreateOrderRequestDTO.class))).thenReturn(orderDTO);

        mockMvc.perform(MockMvcRequestBuilders.post("/api/orders")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createOrderRequestDTO)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id", is(orderDTO.getId())))
                .andExpect(jsonPath("$.totalAmount", is(orderDTO.getTotalAmount().doubleValue())))
                .andExpect(jsonPath("$.orderStatus", is(Order.OrderStatus.cho_xu_ly.name())));
    }

    @Test
    @WithMockUser(username = TEST_USER_EMAIL)
    void getCurrentUserOrders_noStatus_shouldReturnOrders() throws Exception {
        Page<OrderDTO> orderPage = new PageImpl<>(List.of(orderDTO), PageRequest.of(0, 10), 1);
        when(orderService.getCurrentUserOrders(eq(TEST_USER_EMAIL), eq(null), any(Pageable.class))).thenReturn(orderPage);

        mockMvc.perform(MockMvcRequestBuilders.get("/api/orders/me")
                        .param("page", "0")
                        .param("size", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", hasSize(1)))
                .andExpect(jsonPath("$.content[0].id", is(orderDTO.getId())));
    }

    @Test
    @WithMockUser(username = TEST_USER_EMAIL)
    void getCurrentUserOrders_withStatus_shouldReturnFilteredOrders() throws Exception {
        Page<OrderDTO> orderPage = new PageImpl<>(List.of(orderDTO), PageRequest.of(0, 10), 1);
        when(orderService.getCurrentUserOrders(eq(TEST_USER_EMAIL), eq(Order.OrderStatus.cho_xu_ly), any(Pageable.class))).thenReturn(orderPage);

        mockMvc.perform(MockMvcRequestBuilders.get("/api/orders/me")
                        .param("status", Order.OrderStatus.cho_xu_ly.name())
                        .param("page", "0")
                        .param("size", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", hasSize(1)))
                .andExpect(jsonPath("$.content[0].orderStatus", is(Order.OrderStatus.cho_xu_ly.name())));
    }

    @Test
    @WithMockUser(username = TEST_USER_EMAIL)
    void getCurrentUserOrders_noOrders_shouldReturnNoContent() throws Exception {
        Page<OrderDTO> emptyPage = Page.empty(PageRequest.of(0, 10));
        when(orderService.getCurrentUserOrders(eq(TEST_USER_EMAIL), any(), any(Pageable.class))).thenReturn(emptyPage);

        mockMvc.perform(MockMvcRequestBuilders.get("/api/orders/me"))
                .andExpect(status().isNoContent());
    }

    @Test
    @WithMockUser(username = TEST_USER_EMAIL)
    void getOrderDetailsForCurrentUser_orderExists_shouldReturnOrder() throws Exception {
        when(orderService.getOrderByIdForCurrentUser(eq(TEST_USER_EMAIL), eq(orderDTO.getId()))).thenReturn(orderDTO);

        mockMvc.perform(MockMvcRequestBuilders.get("/api/orders/me/{orderId}", orderDTO.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id", is(orderDTO.getId())))
                .andExpect(jsonPath("$.orderDetails", hasSize(1)))
                .andExpect(jsonPath("$.orderDetails[0].productName", is(orderDetailDTO.getProductName())));
    }

    @Test
    @WithMockUser(username = TEST_USER_EMAIL)
    void getOrderStatusHistoryForCurrentUser_historyExists_shouldReturnHistory() throws Exception {
        when(orderService.getOrderStatusHistoryForCurrentUser(eq(TEST_USER_EMAIL), eq(orderDTO.getId()))).thenReturn(List.of(orderStatusHistoryDTO));

        mockMvc.perform(MockMvcRequestBuilders.get("/api/orders/me/{orderId}/history", orderDTO.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].status", is(orderStatusHistoryDTO.getStatus())));
    }

    @Test
    @WithMockUser(username = TEST_USER_EMAIL)
    void getOrderStatusHistoryForCurrentUser_noHistory_shouldReturnEmptyList() throws Exception {
        when(orderService.getOrderStatusHistoryForCurrentUser(eq(TEST_USER_EMAIL), eq(orderDTO.getId()))).thenReturn(Collections.emptyList());

        mockMvc.perform(MockMvcRequestBuilders.get("/api/orders/me/{orderId}/history", orderDTO.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(0)));
    }

    @Test
    @WithMockUser(username = ADMIN_USER_EMAIL, roles = {"ADMIN"})
    void updateOrderStatusByAdmin_validRequest_shouldReturnUpdatedOrder() throws Exception {
        OrderDTO updatedOrderDTO = new OrderDTO();
        updatedOrderDTO.setId(orderDTO.getId());
        updatedOrderDTO.setOrderStatus(Order.OrderStatus.dang_giao.name());
        updatedOrderDTO.setTotalAmount(orderDTO.getTotalAmount());
        // Populate other fields as necessary for the response

        when(orderService.updateOrderStatusByAdmin(
                eq(orderDTO.getId()),
                eq(Order.OrderStatus.dang_giao),
                eq("Order shipped by admin."))
        ).thenReturn(updatedOrderDTO);

        mockMvc.perform(MockMvcRequestBuilders.patch("/api/orders/{orderId}/status", orderDTO.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateOrderStatusRequestDTO)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id", is(orderDTO.getId())))
                .andExpect(jsonPath("$.orderStatus", is(Order.OrderStatus.dang_giao.name())));
    }
}
