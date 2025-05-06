package demo.com.example.testserver.user.repository;

import demo.com.example.testserver.user.model.Address;
import demo.com.example.testserver.user.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AddressRepository extends JpaRepository<Address, Integer> {

    List<Address> findByUser(User user);

    Optional<Address> findByIdAndUser(Integer id, User user);

    Optional<Address> findByUserAndIsDefaultTrue(User user);

    // Custom query to unset the default flag for all addresses of a user
    @Modifying // Indicates that this query modifies the database
    @Query("UPDATE Address a SET a.isDefault = false WHERE a.user = :user AND a.isDefault = true")
    void unsetDefaultForUser(@Param("user") User user);
}
