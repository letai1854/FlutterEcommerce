package demo.com.example.testserver.user.service;

import demo.com.example.testserver.user.dto.AddressDTO;
import demo.com.example.testserver.user.dto.AddressRequestDTO;

import java.util.List;

public interface AddressService {

    List<AddressDTO> getUserAddresses(String userEmail);

    AddressDTO addAddress(String userEmail, AddressRequestDTO requestDTO);

    AddressDTO updateAddress(String userEmail, Integer addressId, AddressRequestDTO requestDTO);

    void deleteAddress(String userEmail, Integer addressId);

    void setDefaultAddress(String userEmail, Integer addressId);
}
