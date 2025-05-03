package demo.com.example.testserver.repository;

import demo.com.example.testserver.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Integer> {

    Optional<User> findByEmail(String email);

    // Find user by email, only if their status is 'kich_hoat'
    // Ensure the full path to the enum is correct if issues persist.
    @Query("SELECT u FROM User u WHERE u.email = :email AND u.status = demo.com.example.testserver.model.User$UserStatus.kich_hoat")
    Optional<User> findActiveUserByEmail(@Param("email") String email);

    // IMPORTANT: This query uses plain text password comparison.
    // It MUST be removed or updated when password hashing (e.g., BCrypt) is implemented.
    // The check should be done in the service/controller layer after fetching the user by email.
    @Deprecated // Mark as deprecated to highlight the security risk. DO NOT USE IN PRODUCTION.
    @Query("SELECT u FROM User u WHERE u.email = :email AND u.password = :password AND u.status = demo.com.example.testserver.model.User$UserStatus.kich_hoat")
    Optional<User> findActiveUserByEmailAndPassword(
        @Param("email") String email,
        @Param("password") String password // Plain text password - INSECURE
    );

    // Find all users whose status is 'kich_hoat'
    @Query("SELECT u FROM User u WHERE u.status = demo.com.example.testserver.model.User$UserStatus.kich_hoat")
    List<User> findAllActiveUsers();

    // Standard findById is provided by JpaRepository, but this explicit query works too.
    // @Query("SELECT u FROM User u WHERE u.id = :id")
    // Optional<User> findById(@Param("id") Integer id);

    // Potential future methods for password reset tokens:
    // Optional<User> findByPasswordResetToken(String token);
}
