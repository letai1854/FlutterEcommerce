package demo.com.example.testserver.repository;

import demo.com.example.testserver.model.PasswordResetToken;
import demo.com.example.testserver.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.stream.Stream;
import java.time.LocalDateTime;


@Repository
public interface PasswordResetTokenRepository extends JpaRepository<PasswordResetToken, Long> {

    // Find a token by its hash
    Optional<PasswordResetToken> findByTokenHash(String tokenHash);

    // Find a token associated with a specific user
    Optional<PasswordResetToken> findByUser(User user);

    // Find all expired tokens before a certain date (for cleanup jobs)
    Stream<PasswordResetToken> findAllByExpiryDateLessThan(LocalDateTime now);

    // Delete expired tokens before a certain date (for cleanup jobs)
    void deleteAllByExpiryDateLessThan(LocalDateTime now);

    // Delete a token by its hash
    void deleteByTokenHash(String tokenHash);
}
