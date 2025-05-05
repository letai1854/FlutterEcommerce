package demo.com.example.testserver.user.service;

import demo.com.example.testserver.user.dto.AddressDTO;
import demo.com.example.testserver.user.dto.AddressRequestDTO;
import demo.com.example.testserver.user.model.Address;
import demo.com.example.testserver.user.model.User;
import demo.com.example.testserver.user.repository.AddressRepository;
import demo.com.example.testserver.user.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import jakarta.transaction.Transactional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class AddressServiceImpl implements AddressService {

    private static final Logger logger = LoggerFactory.getLogger(AddressServiceImpl.class);

    @Autowired
    private AddressRepository addressRepository;

    @Autowired
    private UserRepository userRepository;

    @Override
    public List<AddressDTO> getUserAddresses(String userEmail) {
        User user = findUserByEmail(userEmail);
        List<Address> addresses = addressRepository.findByUser(user);
        return addresses.stream().map(AddressDTO::new).collect(Collectors.toList());
    }

    @Override
    @Transactional
    public AddressDTO addAddress(String userEmail, AddressRequestDTO requestDTO) {
        User user = findUserByEmail(userEmail);

        Address newAddress = new Address();
        newAddress.setUser(user);
        newAddress.setRecipientName(requestDTO.getRecipientName());
        newAddress.setPhoneNumber(requestDTO.getPhoneNumber());
        newAddress.setSpecificAddress(requestDTO.getSpecificAddress());
        newAddress.setDefault(requestDTO.getIsDefault());

        // If this new address is set as default, unset the current default
        if (Boolean.TRUE.equals(requestDTO.getIsDefault())) {
            addressRepository.unsetDefaultForUser(user);
        }

        Address savedAddress = addressRepository.save(newAddress);
        logger.info("Added new address with ID {} for user {}", savedAddress.getId(), userEmail);
        return new AddressDTO(savedAddress);
    }

    @Override
    @Transactional
    public AddressDTO updateAddress(String userEmail, Integer addressId, AddressRequestDTO requestDTO) {
        User user = findUserByEmail(userEmail);
        Address existingAddress = findAddressByIdAndUser(addressId, user);

        existingAddress.setRecipientName(requestDTO.getRecipientName());
        existingAddress.setPhoneNumber(requestDTO.getPhoneNumber());
        existingAddress.setSpecificAddress(requestDTO.getSpecificAddress());

        // Handle default status change
        boolean requestedDefault = Boolean.TRUE.equals(requestDTO.getIsDefault());
        if (requestedDefault && !Boolean.TRUE.equals(existingAddress.getDefault())) {
            // If requesting to set this as default and it's not already default
            addressRepository.unsetDefaultForUser(user);
            existingAddress.setDefault(true);
        } else if (!requestedDefault && Boolean.TRUE.equals(existingAddress.getDefault())) {
            // If requesting to unset default, but it's the current default
            // Prevent unsetting the only default? Or allow it? For now, allow it.
            // Consider adding logic if a user MUST have a default address.
            existingAddress.setDefault(false);
        }
        // If requestedDefault is false and it's already false, do nothing.
        // If requestedDefault is true and it's already true, do nothing.

        Address updatedAddress = addressRepository.save(existingAddress);
        logger.info("Updated address with ID {} for user {}", updatedAddress.getId(), userEmail);
        return new AddressDTO(updatedAddress);
    }

    @Override
    @Transactional
    public void deleteAddress(String userEmail, Integer addressId) {
        User user = findUserByEmail(userEmail);
        Address addressToDelete = findAddressByIdAndUser(addressId, user);

        // Prevent deleting the default address? Or handle reassigning default?
        if (Boolean.TRUE.equals(addressToDelete.getDefault())) {
            throw new IllegalArgumentException("Cannot delete the default address. Set another address as default first.");
        }

        // Remove the address from the user's collection.
        // Since orphanRemoval=true, Hibernate will delete the Address entity
        // when the collection change is persisted (e.g., during transaction commit/flush).
        user.removeAddress(addressToDelete);

        logger.info("Removed address with ID {} for user {}", addressId, userEmail);
    }

    @Override
    @Transactional
    public void setDefaultAddress(String userEmail, Integer addressId) {
        User user = findUserByEmail(userEmail);
        Address addressToSetDefault = findAddressByIdAndUser(addressId, user);

        if (!Boolean.TRUE.equals(addressToSetDefault.getDefault())) {
            // Unset the current default address for the user
            addressRepository.unsetDefaultForUser(user);

            // Set the new address as default
            addressToSetDefault.setDefault(true);
            addressRepository.save(addressToSetDefault);
            logger.info("Set address with ID {} as default for user {}", addressId, userEmail);
        } else {
            logger.info("Address with ID {} is already the default for user {}", addressId, userEmail);
        }
    }

    // Helper method to find user by email
    private User findUserByEmail(String email) {
        return userRepository.findActiveUserByEmail(email)
                .orElseThrow(() -> {
                    logger.warn("User not found or inactive: {}", email);
                    return new EntityNotFoundException("User not found or inactive: " + email);
                });
    }

    // Helper method to find address by ID and ensure it belongs to the user
    private Address findAddressByIdAndUser(Integer addressId, User user) {
        return addressRepository.findByIdAndUser(addressId, user)
                .orElseThrow(() -> {
                    logger.warn("Address not found with ID {} for user {}", addressId, user.getEmail());
                    return new EntityNotFoundException("Address not found with ID: " + addressId);
                });
    }
}
