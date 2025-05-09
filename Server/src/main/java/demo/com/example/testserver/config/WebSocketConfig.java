package demo.com.example.testserver.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.ChannelRegistration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    private static final Logger logger = LoggerFactory.getLogger(WebSocketConfig.class);

    @Autowired
    private WebSocketAuthenticationInterceptor authenticationInterceptor;

    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        // Broker for broadcasting messages to clients subscribed to specific topics
        // Dòng này cho phép broker xử lý các destinations bắt đầu bằng "/topic" (như "/topic/product/{productId}/reviews")
        // và "/queue" (thường dùng cho tin nhắn user-specific).
        config.enableSimpleBroker("/topic", "/queue");
        // Prefix for messages bound for @MessageMapping annotated methods in controllers
        config.setApplicationDestinationPrefixes("/app");
        // config.setUserDestinationPrefix("/user"); // For user-specific messages if needed
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        // WebSocket handshake endpoint for clients to connect
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns("*") // Allow all origins for development, restrict in production
                .withSockJS(); // SockJS for fallback options if WebSocket is not available
        logger.info("WebSocket STOMP endpoint '/ws' configured with SockJS.");
    }

    @Override
    public void configureClientInboundChannel(ChannelRegistration registration) {
        // Add our custom authentication interceptor
        registration.interceptors(authenticationInterceptor);
        logger.info("Configured WebSocket authentication interceptor");
    }
}
