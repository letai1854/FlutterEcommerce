package demo.com.example.testserver.user.security;

import java.util.Base64;
import java.util.Date;

import javax.crypto.SecretKey;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component; // Use Spring's UserDetails

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.MalformedJwtException;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.UnsupportedJwtException;
import io.jsonwebtoken.security.Keys;
import io.jsonwebtoken.security.SignatureException;
import jakarta.annotation.PostConstruct;

@Component
public class JwtTokenProvider {

    private static final Logger logger = LoggerFactory.getLogger(JwtTokenProvider.class);
    private static final int MIN_KEY_LENGTH_BYTES = 32; // 512 bits for HS512

    @Value("${jwt.secret}")
    private String jwtSecretString;

    @Value("${jwt.expiration-ms}")
    private int jwtExpirationInMs;

    private SecretKey jwtSecretKey;

    @PostConstruct
    public void init() {
        byte[] keyBytes;
        try {
             keyBytes = Base64.getDecoder().decode(jwtSecretString);
             logger.info("Successfully decoded JWT secret from Base64.");
        } catch (IllegalArgumentException e) {
             logger.warn("JWT Secret is not Base64 encoded. Using raw bytes. Ensure it's strong enough for HS512.");
             keyBytes = jwtSecretString.getBytes();
        }

        if (keyBytes.length < MIN_KEY_LENGTH_BYTES) {
            String errorMsg = String.format(
                "JWT Secret key size is %d bytes (%d bits), which is less than the minimum required %d bytes (%d bits) for HS512. This is insecure!",
                keyBytes.length, keyBytes.length * 8, MIN_KEY_LENGTH_BYTES, MIN_KEY_LENGTH_BYTES * 8
            );
            logger.error(errorMsg);
            // Throw an exception to prevent application startup with an insecure key
            throw new RuntimeException(errorMsg + " Please provide a sufficiently long and strong JWT secret.");
        }

        this.jwtSecretKey = Keys.hmacShaKeyFor(keyBytes);
        logger.info("JWT Secret Key initialized successfully.");
    }

    public String generateToken(Authentication authentication) {
        // Use UserDetails from Spring Security context
        UserDetails userPrincipal = (UserDetails) authentication.getPrincipal();
        return generateTokenFromUsername(userPrincipal.getUsername());
    }

     public String generateTokenFromUsername(String username) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + jwtExpirationInMs);

        return Jwts.builder()
                .setSubject(username)
                .setIssuedAt(now)
                .setExpiration(expiryDate)
                .signWith(jwtSecretKey, SignatureAlgorithm.HS256) // Use the SecretKey
                .compact();
    }

    public String getUsernameFromJWT(String token) {
        Claims claims = Jwts.parserBuilder()
                .setSigningKey(jwtSecretKey) // Use the SecretKey
                .build()
                .parseClaimsJws(token)
                .getBody();

        return claims.getSubject();
    }

    public boolean validateToken(String authToken) {
        try {
            Jwts.parserBuilder().setSigningKey(jwtSecretKey).build().parseClaimsJws(authToken);
            return true;
        } catch (SignatureException ex) {
            logger.error("Invalid JWT signature");
        } catch (MalformedJwtException ex) {
            logger.error("Invalid JWT token");
        } catch (ExpiredJwtException ex) {
            logger.error("Expired JWT token");
        } catch (UnsupportedJwtException ex) {
            logger.error("Unsupported JWT token");
        } catch (IllegalArgumentException ex) {
            logger.error("JWT claims string is empty.");
        }
        return false;
    }
}
