package demo.com.example.testserver.coupon.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import demo.com.example.testserver.common.exception.DuplicateResourceException;
import demo.com.example.testserver.coupon.dto.CouponResponseDTO;
import demo.com.example.testserver.coupon.dto.CreateCouponRequestDTO;
import demo.com.example.testserver.coupon.service.CouponService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Arrays;
import java.util.Collections;
import java.util.Date;
import java.util.List;

import static org.hamcrest.Matchers.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class CouponControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private CouponService couponService;

    @Autowired
    private ObjectMapper objectMapper;

    private CouponResponseDTO coupon1;
    private CouponResponseDTO coupon2;
    private CreateCouponRequestDTO createRequest;
    private CouponResponseDTO createdCoupon;

    @BeforeEach
    void setUp() {
        Date now = new Date();
        Date yesterday = Date.from(Instant.now().minus(1, ChronoUnit.DAYS));

        coupon1 = new CouponResponseDTO(1, "SALE1", new BigDecimal("10000.00"), 100, 10, yesterday);
        coupon2 = new CouponResponseDTO(2, "SALE2", new BigDecimal("20000.00"), 50, 5, now);

        createRequest = new CreateCouponRequestDTO();
        createRequest.setCode("NEWC1");
        createRequest.setDiscountValue(new BigDecimal("5000.00"));
        createRequest.setMaxUsageCount(200);

        createdCoupon = new CouponResponseDTO(3, "NEWC1", new BigDecimal("5000.00"), 200, 0, now);
    }

    // --- Tests for POST /api/coupons ---

    @Test
    void createCoupon_validInput_shouldReturnCreatedCoupon() throws Exception {
        when(couponService.createCoupon(any(CreateCouponRequestDTO.class))).thenReturn(createdCoupon);

        mockMvc.perform(MockMvcRequestBuilders.post("/api/coupons")
                        .with(user("admin").roles("ADMIN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createRequest)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id", is(createdCoupon.getId())))
                .andExpect(jsonPath("$.code", is(createdCoupon.getCode())))
                .andExpect(jsonPath("$.discountValue", is(createdCoupon.getDiscountValue().doubleValue())))
                .andExpect(jsonPath("$.maxUsageCount", is(createdCoupon.getMaxUsageCount())))
                .andExpect(jsonPath("$.usageCount", is(0)));
    }

    @Test
    void createCoupon_invalidInput_shouldReturnBadRequest() throws Exception {
        CreateCouponRequestDTO invalidRequest = new CreateCouponRequestDTO(); // Missing fields
        invalidRequest.setCode("SHORT"); // Invalid code length/pattern

        mockMvc.perform(MockMvcRequestBuilders.post("/api/coupons")
                        .with(user("admin").roles("ADMIN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalidRequest)))
                .andExpect(status().isBadRequest());
        // Optionally check for specific error messages if needed
    }

    @Test
    void createCoupon_duplicateCode_shouldReturnConflict() throws Exception {
        when(couponService.createCoupon(any(CreateCouponRequestDTO.class)))
                .thenThrow(new DuplicateResourceException("Mã coupon '" + createRequest.getCode() + "' đã tồn tại."));

        mockMvc.perform(MockMvcRequestBuilders.post("/api/coupons")
                        .with(user("admin").roles("ADMIN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createRequest)))
                .andExpect(status().isConflict()); // 409 Conflict for duplicate
    }

    @Test
    void createCoupon_unauthorized_shouldReturnForbidden() throws Exception {
        mockMvc.perform(MockMvcRequestBuilders.post("/api/coupons")
                        .with(user("user").roles("USER")) // Non-admin user
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createRequest)))
                .andExpect(status().isForbidden());
    }

    // --- Tests for GET /api/coupons (Admin Search) ---

    @Test
    void getCoupons_noFilters_shouldReturnAllCoupons() throws Exception {
        List<CouponResponseDTO> allCoupons = Arrays.asList(coupon1, coupon2);
        when(couponService.searchCoupons(eq(null), eq(null), eq(null))).thenReturn(allCoupons);

        mockMvc.perform(MockMvcRequestBuilders.get("/api/coupons")
                        .with(user("admin").roles("ADMIN"))
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)))
                .andExpect(jsonPath("$[0].code", is(coupon1.getCode())))
                .andExpect(jsonPath("$[1].code", is(coupon2.getCode())));
    }

    @Test
    void getCoupons_withCodeFilter_shouldReturnMatchingCoupons() throws Exception {
        String searchCode = "SALE1";
        List<CouponResponseDTO> filteredCoupons = List.of(coupon1);
        when(couponService.searchCoupons(eq(searchCode), eq(null), eq(null))).thenReturn(filteredCoupons);

        mockMvc.perform(MockMvcRequestBuilders.get("/api/coupons")
                        .param("code", searchCode)
                        .with(user("admin").roles("ADMIN"))
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].code", is(searchCode)));
    }

    @Test
    void getCoupons_withDateFilter_shouldReturnMatchingCoupons() throws Exception {
        Date startDate = Date.from(Instant.now().minus(2, ChronoUnit.DAYS));
        Date endDate = Date.from(Instant.now().minus(12, ChronoUnit.HOURS)); // Includes coupon1
        List<CouponResponseDTO> filteredCoupons = List.of(coupon1);
        // Use any(Date.class) instead of eq() for date parameters
        when(couponService.searchCoupons(eq(null), any(Date.class), any(Date.class))).thenReturn(filteredCoupons);

        mockMvc.perform(MockMvcRequestBuilders.get("/api/coupons")
                        .param("startDate", startDate.toInstant().toString().substring(0, 10)) // Format as YYYY-MM-DD
                        .param("endDate", endDate.toInstant().toString().substring(0, 10))   // Format as YYYY-MM-DD
                        .with(user("admin").roles("ADMIN"))
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk()) // Should now pass
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].id", is(coupon1.getId())));
    }

    @Test
    void getCoupons_withAllFilters_shouldReturnMatchingCoupons() throws Exception {
        String searchCode = "SALE2";
        Date startDate = Date.from(Instant.now().minus(1, ChronoUnit.DAYS));
        Date endDate = Date.from(Instant.now().plus(1, ChronoUnit.DAYS));
        List<CouponResponseDTO> filteredCoupons = List.of(coupon2);
        // Use any(Date.class) instead of eq() for date parameters
        when(couponService.searchCoupons(eq(searchCode), any(Date.class), any(Date.class))).thenReturn(filteredCoupons);

        mockMvc.perform(MockMvcRequestBuilders.get("/api/coupons")
                        .param("code", searchCode)
                        .param("startDate", startDate.toInstant().toString().substring(0, 10))
                        .param("endDate", endDate.toInstant().toString().substring(0, 10))
                        .with(user("admin").roles("ADMIN"))
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].id", is(coupon2.getId())));
    }

    @Test
    void getCoupons_noResults_shouldReturnNoContent() throws Exception {
        when(couponService.searchCoupons(any(), any(), any())).thenReturn(Collections.emptyList());

        mockMvc.perform(MockMvcRequestBuilders.get("/api/coupons")
                        .param("code", "NONEXISTENT")
                        .with(user("admin").roles("ADMIN"))
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isNoContent());
    }

    @Test
    void getCoupons_unauthorized_shouldReturnForbidden() throws Exception {
        mockMvc.perform(MockMvcRequestBuilders.get("/api/coupons")
                        .with(user("user").roles("USER")) // Non-admin user
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isForbidden());
    }

    // --- Tests for GET /api/coupons/available ---

    @Test
    void getAvailableCoupons_shouldReturnAvailableCoupons() throws Exception {
        // Assume both coupons are available (usageCount < maxUsageCount)
        List<CouponResponseDTO> availableCoupons = Arrays.asList(coupon2, coupon1); // Sorted by discount desc
        when(couponService.getAvailableCouponsSortedByDiscount()).thenReturn(availableCoupons);

        mockMvc.perform(MockMvcRequestBuilders.get("/api/coupons/available")
                        .with(user("user").roles("USER")) // Add authentication
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)))
                .andExpect(jsonPath("$[0].id", is(coupon2.getId()))) // Highest discount first
                .andExpect(jsonPath("$[1].id", is(coupon1.getId())));
    }

    @Test
    void getAvailableCoupons_noAvailable_shouldReturnNoContent() throws Exception {
        when(couponService.getAvailableCouponsSortedByDiscount()).thenReturn(Collections.emptyList());

        mockMvc.perform(MockMvcRequestBuilders.get("/api/coupons/available")
                        .with(user("user").roles("USER")) // Add authentication
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isNoContent());
    }
}