package demo.com.example.testserver.user.dto;

import demo.com.example.testserver.user.model.Address;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Date;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AddressDTO {
    private Integer id;
    private String recipientName;
    private String phoneNumber;
    private String specificAddress;
    private Boolean isDefault;
    private Date createdDate;
    private Date updatedDate;

    // Constructor to map from Address entity
    public AddressDTO(Address address) {
        this.id = address.getId();
        this.recipientName = address.getRecipientName();
        this.phoneNumber = address.getPhoneNumber();
        this.specificAddress = address.getSpecificAddress();
        this.isDefault = address.getDefault();
        this.createdDate = address.getCreatedDate();
        this.updatedDate = address.getUpdatedDate();
    }
}
