package demo.com.example.testserver.config;

import demo.com.example.testserver.user.security.JwtTokenProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

import java.util.List;

@Component
public class WebSocketAuthenticationInterceptor implements ChannelInterceptor {

    private static final Logger logger = LoggerFactory.getLogger(WebSocketAuthenticationInterceptor.class);

    @Autowired
    private JwtTokenProvider tokenProvider;

    @Autowired
    private UserDetailsService userDetailsService;

    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
        
        if (accessor != null && StompCommand.CONNECT.equals(accessor.getCommand())) {
            logger.debug("Processing WebSocket CONNECT command");
            
            // Extract authorization header
            List<String> authorization = accessor.getNativeHeader("Authorization");
            String token = null;
            
            if (authorization != null && !authorization.isEmpty()) {
                String bearerToken = authorization.get(0);
                if (StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
                    token = bearerToken.substring(7);
                    logger.debug("WebSocket JWT token found in headers");
                }
            }
            
            if (token != null && tokenProvider.validateToken(token)) {
                try {
                    // Changed from getUserEmailFromToken to getUsernameFromToken
                    String username = tokenProvider.getUsernameFromJWT(token);
                    logger.info("WebSocket authenticated for user: {}", username);
                    
                    UserDetails userDetails = userDetailsService.loadUserByUsername(username);
                    UsernamePasswordAuthenticationToken authentication = 
                            new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());
                    
                    // Set authentication in accessor for this WebSocket session
                    accessor.setUser(authentication);
                    SecurityContextHolder.getContext().setAuthentication(authentication);
                    
                    logger.debug("WebSocket authentication successful for {}", username);
                } catch (Exception e) {
                    logger.error("WebSocket authentication failed: {}", e.getMessage(), e);
                }
            } else {
                logger.warn("WebSocket connection attempted without valid authentication");
            }
        }
        
        return message;
    }
}
