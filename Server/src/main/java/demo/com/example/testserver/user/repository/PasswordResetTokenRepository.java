package demo.com.example.testserver.user.repository;

import java.time.LocalDateTime;
import java.util.Date;
import java.util.Optional;
import java.util.stream.Stream;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import demo.com.example.testserver.user.model.PasswordResetToken;
import demo.com.example.testserver.user.model.User;

@Repository
public interface PasswordResetTokenRepository extends JpaRepository<PasswordResetToken, Long> {

    // Find a token by its value
    Optional<PasswordResetToken> findByTokenHash(String tokenHash);

    // Find a token associated with a specific user
    Optional<PasswordResetToken> findByUser(User user);

    // Delete expired tokens before a certain date (for cleanup jobs)
    @Transactional
    void deleteByExpiryDateLessThan(Date now);

    // Find all expired tokens before a certain date (for cleanup jobs)
    Stream<PasswordResetToken> findAllByExpiryDateLessThan(LocalDateTime now);

    // Delete a token by its hash
    @Modifying
    @Query("DELETE FROM PasswordResetToken t WHERE t.tokenHash = :hashValue")
    void deleteByTokenHash(@Param("hashValue") String tokenHash);

    // Delete a token by user ID
    void deleteByUserId(Integer userId);
}
