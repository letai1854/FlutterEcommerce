package demo.com.example.testserver.user.controller;

import demo.com.example.testserver.user.dto.AddressDTO;
import demo.com.example.testserver.user.dto.AddressRequestDTO;
import demo.com.example.testserver.user.service.AddressService;
import jakarta.persistence.EntityNotFoundException;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/addresses")
@CrossOrigin(origins = "*") // Allow requests from any origin
public class AddressController {

    private static final Logger logger = LoggerFactory.getLogger(AddressController.class);

    @Autowired
    private AddressService addressService;

    // Get all addresses for the current user
    @GetMapping("/me")
    public ResponseEntity<?> getCurrentUserAddresses(@AuthenticationPrincipal UserDetails userDetails) {
        if (userDetails == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Authentication required.");
        }
        String userEmail = userDetails.getUsername();
        try {
            List<AddressDTO> addresses = addressService.getUserAddresses(userEmail);
            if (addresses.isEmpty()) {
                return ResponseEntity.noContent().build();
            }
            return ResponseEntity.ok(addresses);
        } catch (EntityNotFoundException e) {
            logger.warn("Attempt to get addresses for non-existent/inactive user: {}", userEmail);
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (Exception e) {
            logger.error("Error fetching addresses for user {}", userEmail, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("An error occurred while fetching addresses.");
        }
    }

    // Add a new address for the current user
    @PostMapping("/me")
    public ResponseEntity<?> addAddressForCurrentUser(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody AddressRequestDTO requestDTO) {
        if (userDetails == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Authentication required.");
        }
        String userEmail = userDetails.getUsername();
        try {
            AddressDTO newAddress = addressService.addAddress(userEmail, requestDTO);
            return ResponseEntity.status(HttpStatus.CREATED).body(newAddress);
        } catch (EntityNotFoundException e) {
            logger.warn("Attempt to add address for non-existent/inactive user: {}", userEmail);
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (Exception e) {
            logger.error("Error adding address for user {}", userEmail, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("An error occurred while adding the address.");
        }
    }

    // Update an existing address for the current user
    @PutMapping("/me/{addressId}")
    public ResponseEntity<?> updateAddressForCurrentUser(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Integer addressId,
            @Valid @RequestBody AddressRequestDTO requestDTO) {
        if (userDetails == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Authentication required.");
        }
        String userEmail = userDetails.getUsername();
        try {
            AddressDTO updatedAddress = addressService.updateAddress(userEmail, addressId, requestDTO);
            return ResponseEntity.ok(updatedAddress);
        } catch (EntityNotFoundException e) {
            logger.warn("Address update failed: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (IllegalArgumentException e) {
            logger.warn("Invalid argument during address update for user {}: {}", userEmail, e.getMessage());
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            logger.error("Error updating address {} for user {}", addressId, userEmail, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("An error occurred while updating the address.");
        }
    }

     // Delete an address for the current user
    @DeleteMapping("/me/{addressId}")
    public ResponseEntity<?> deleteAddressForCurrentUser(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Integer addressId) {
        if (userDetails == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Authentication required.");
        }
        String userEmail = userDetails.getUsername();
        try {
            addressService.deleteAddress(userEmail, addressId);
            return ResponseEntity.noContent().build();
        } catch (EntityNotFoundException e) {
            logger.warn("Address deletion failed: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (IllegalArgumentException e) {
            logger.warn("Invalid argument during address deletion for user {}: {}", userEmail, e.getMessage());
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            logger.error("Error deleting address {} for user {}", addressId, userEmail, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("An error occurred while deleting the address.");
        }
    }

    // Set an address as default for the current user
    @PatchMapping("/me/{addressId}/default")
    public ResponseEntity<?> setDefaultAddressForCurrentUser(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Integer addressId) {
        if (userDetails == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Authentication required.");
        }
        String userEmail = userDetails.getUsername();
        try {
            addressService.setDefaultAddress(userEmail, addressId);
            return ResponseEntity.ok().body("Address set as default successfully.");
        } catch (EntityNotFoundException e) {
            logger.warn("Set default address failed: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (Exception e) {
            logger.error("Error setting default address {} for user {}", addressId, userEmail, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("An error occurred while setting the default address.");
        }
    }
}
