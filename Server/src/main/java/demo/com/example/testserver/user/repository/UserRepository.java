package demo.com.example.testserver.user.repository;

import java.util.Date; // Import Date
import java.util.List;
import java.util.Optional;

import org.springframework.data.domain.Page; // Import Page
import org.springframework.data.domain.Pageable; // Import Pageable
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import demo.com.example.testserver.user.model.User;

@Repository
public interface UserRepository extends JpaRepository<User, Integer> {

    Optional<User> findByEmail(String email);

    boolean existsByEmail(String email);

    // Find user by email, only if their status is 'kich_hoat'
    @Query("SELECT u FROM User u WHERE u.email = :email AND u.status = demo.com.example.testserver.user.model.User.UserStatus.kich_hoat")
    Optional<User> findActiveUserByEmail(@Param("email") String email);

    // Find active user by email and password (Potentially problematic - password check should be done via PasswordEncoder)
    // Corrected Query: Use parameter binding for status
    @Query("SELECT u FROM User u WHERE u.email = :email AND u.password = :password AND u.status = :status")
    Optional<User> findActiveUserByEmailAndPassword(
        @Param("email") String email,
        @Param("password") String password,
        @Param("status") User.UserStatus status
    );

    // Find all users
    @Query("SELECT u FROM User u")
    List<User> findAllActiveUsers();

    // Find users with pagination and filtering by email and creation date range
    @Query("SELECT u FROM User u WHERE " +
           "(:email IS NULL OR LOWER(u.email) LIKE LOWER(CONCAT('%', :email, '%'))) AND " +
           "(:startDate IS NULL OR u.createdDate >= :startDate) AND " +
           "(:endDate IS NULL OR u.createdDate <= :endDate)")
    Page<User> findAllWithFilters(
        @Param("email") String email,
        @Param("startDate") Date startDate,
        @Param("endDate") Date endDate,
        Pageable pageable
    );

    // Potential future methods for password reset tokens:
    Optional<User> findByPasswordResetToken(String token);
}
