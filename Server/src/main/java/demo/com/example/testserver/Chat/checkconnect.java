package demo.com.example.testserver.chat;

import demo.com.example.testserver.chat.dto.MessageDTO;
import demo.com.example.testserver.chat.dto.SendMessageRequestDTO;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.converter.MappingJackson2MessageConverter;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaders;
import org.springframework.messaging.simp.stomp.StompSession;
import org.springframework.messaging.simp.stomp.StompSessionHandler;
import org.springframework.util.concurrent.ListenableFuture;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.socket.WebSocketHttpHeaders;
import org.springframework.web.socket.client.standard.StandardWebSocketClient;
import org.springframework.web.socket.messaging.WebSocketStompClient;

import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;
import javax.net.ssl.SSLSession;
import javax.swing.*;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.lang.reflect.Type;
import java.security.KeyManagementException;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.security.cert.X509Certificate;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutionException;

// Simple DTO class for ProductReview (matching server structure for relevant fields)
class ProductReviewDTO {
    private Long id;
    private Long productId;
    private String reviewerName;
    private Integer rating;
    private String comment;
    private Date reviewDate;

    // Getters and setters (or ensure Jackson can deserialize)
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getProductId() { return productId; }
    public void setProductId(Long productId) { this.productId = productId; }
    public String getReviewerName() { return reviewerName; }
    public void setReviewerName(String reviewerName) { this.reviewerName = reviewerName; }
    public Integer getRating() { return rating; }
    public void setRating(Integer rating) { this.rating = rating; }
    public String getComment() { return comment; }
    public void setComment(String comment) { this.comment = comment; }
    public Date getReviewDate() { return reviewDate; }
    public void setReviewDate(Date reviewDate) { this.reviewDate = reviewDate; }

    @Override
    public String toString() {
        return "ProductReviewDTO{" +
               "id=" + id +
               ", productId=" + productId +
               ", reviewerName='" + reviewerName + '\'' +
               ", rating=" + rating +
               ", comment='" + comment + '\'' +
               ", reviewDate=" + reviewDate +
               '}';
    }
}

public class checkconnect {

    private static final String WS_URL = "wss://localhost:8443/ws/websocket";
    private static final String API_URL = "https://localhost:8443";
    private static final Integer CHAT_CONVERSATION_ID = 1; // Renamed for clarity
    private static final Long PRODUCT_ID_TO_SUBSCRIBE = 1L; // Example product ID for review subscription
    private static String jwtToken = "";
    private static SSLContext globalPermissiveSslContext;
    
    // GUI components
    private static JFrame mainFrame;
    private static JTextArea chatHistoryArea;
    private static JTextField messageField;
    private static JButton sendButton;
    private static JLabel statusLabel;
    private static JLabel connectionStatusLabel;
    private static StompSession stompSession;
    private static boolean isConnected = false;

    public static void main(String[] args) {
        // Set up the GUI first
        SwingUtilities.invokeLater(() -> createAndShowGUI());
        
        // Disable SSL verification
        disableSslVerification();
    }
    
    private static void createAndShowGUI() {
        // Create the main frame
        mainFrame = new JFrame("WebSocket Chat Client");
        mainFrame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        mainFrame.setSize(600, 500);
        mainFrame.setLayout(new BorderLayout(5, 5));
        
        // Add window close listener to disconnect gracefully
        mainFrame.addWindowListener(new WindowAdapter() {
            @Override
            public void windowClosing(WindowEvent e) {
                disconnectFromServer();
                super.windowClosing(e);
            }
        });
        
        // Create the components
        chatHistoryArea = new JTextArea();
        chatHistoryArea.setEditable(false);
        chatHistoryArea.setLineWrap(true);
        chatHistoryArea.setWrapStyleWord(true);
        
        JScrollPane scrollPane = new JScrollPane(chatHistoryArea);
        scrollPane.setVerticalScrollBarPolicy(JScrollPane.VERTICAL_SCROLLBAR_ALWAYS);
        
        messageField = new JTextField();
        sendButton = new JButton("Send");
        sendButton.setEnabled(false); // Disabled until connected
        
        // Status panel
        JPanel statusPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
        statusLabel = new JLabel("Status: Not connected");
        connectionStatusLabel = new JLabel("●");
        connectionStatusLabel.setForeground(Color.RED);
        statusPanel.add(connectionStatusLabel);
        statusPanel.add(statusLabel);
        
        // Message input panel
        JPanel inputPanel = new JPanel(new BorderLayout(5, 5));
        inputPanel.add(messageField, BorderLayout.CENTER);
        inputPanel.add(sendButton, BorderLayout.EAST);
        
        // Add components to the frame
        mainFrame.add(statusPanel, BorderLayout.NORTH);
        mainFrame.add(scrollPane, BorderLayout.CENTER);
        mainFrame.add(inputPanel, BorderLayout.SOUTH);
        
        // Button action
        sendButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                sendMessage();
            }
        });
        
        // Enter key in text field
        messageField.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                sendMessage();
            }
        });
        
        // Add connect button
        JButton connectButton = new JButton("Connect");
        connectButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                if (!isConnected) {
                    new Thread(() -> connectToServer()).start();
                } else {
                    appendToChat("System", "Already connected");
                }
            }
        });
        statusPanel.add(connectButton);
        
        // Display the frame
        mainFrame.setLocationRelativeTo(null);
        mainFrame.setVisible(true);
        
        // Append welcome message
        appendToChat("System", "Welcome to the WebSocket Chat Client");
        appendToChat("System", "Click 'Connect' to log in and start chatting");
    }
    
    private static void connectToServer() {
        SwingUtilities.invokeLater(() -> {
            statusLabel.setText("Status: Logging in...");
        });
        
        try {
            // Login process with dialog
            String[] credentials = promptLogin();
            if (credentials == null) {
                SwingUtilities.invokeLater(() -> {
                    statusLabel.setText("Status: Login cancelled");
                });
                return;
            }
            
            Map<String, String> loginRequest = new HashMap<>();
            loginRequest.put("email", credentials[0]);
            loginRequest.put("password", credentials[1]);
            
            // Setup headers
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            
            // Create HTTP entity
            HttpEntity<Map<String, String>> requestEntity = new HttpEntity<>(loginRequest, headers);
            
            // Make login request
            RestTemplate restTemplate = new RestTemplate();
            SwingUtilities.invokeLater(() -> {
                statusLabel.setText("Status: Authenticating...");
            });
            
            ResponseEntity<Map> response = restTemplate.postForEntity(
                    API_URL + "/api/users/login",
                    requestEntity,
                    Map.class);
            
            // Extract token
            if (response.getBody() != null && response.getBody().containsKey("token")) {
                jwtToken = response.getBody().get("token").toString();
                SwingUtilities.invokeLater(() -> {
                    statusLabel.setText("Status: Login successful, connecting to WebSocket...");
                });
                
                // Connect to WebSocket
                WebSocketStompClient stompClient = createStompClient();
                
                // Create STOMP headers with auth
                StompHeaders connectHeaders = new StompHeaders();
                connectHeaders.add("Authorization", "Bearer " + jwtToken);
                
                // Connect to WebSocket server
                ListenableFuture<StompSession> sessionFuture = stompClient.connect(
                        WS_URL,
                        new WebSocketHttpHeaders(),
                        connectHeaders,
                        new ChatSessionHandler());
                
                stompSession = sessionFuture.get();
                
                // Update UI for successful connection
                SwingUtilities.invokeLater(() -> {
                    statusLabel.setText("Status: Connected to server");
                    connectionStatusLabel.setForeground(Color.GREEN);
                    sendButton.setEnabled(true);
                    appendToChat("System", "Connected to WebSocket server");
                });
                
                isConnected = true;
                
                // Join the chat conversation
                StompHeaders joinChatHeaders = new StompHeaders();
                joinChatHeaders.setDestination("/app/chat.joinConversation/" + CHAT_CONVERSATION_ID);
                stompSession.send(joinChatHeaders, null);
                
                // Subscribe to chat conversation
                stompSession.subscribe("/topic/conversation/" + CHAT_CONVERSATION_ID, new ChatSessionHandler());
                SwingUtilities.invokeLater(() -> {
                    appendToChat("System", "Subscribed to chat conversation #" + CHAT_CONVERSATION_ID);
                });

                // Subscribe to product reviews for a specific product
                String productReviewTopic = "/topic/product/" + PRODUCT_ID_TO_SUBSCRIBE + "/reviews";
                stompSession.subscribe(productReviewTopic, new ChatSessionHandler());
                SwingUtilities.invokeLater(() -> {
                    appendToChat("System", "Subscribed to product reviews for product #" + PRODUCT_ID_TO_SUBSCRIBE + " on " + productReviewTopic);
                });

            } else {
                SwingUtilities.invokeLater(() -> {
                    statusLabel.setText("Status: Login failed");
                    appendToChat("System", "Failed to login: Invalid credentials");
                });
            }
        } catch (Exception e) {
            SwingUtilities.invokeLater(() -> {
                statusLabel.setText("Status: Connection error");
                connectionStatusLabel.setForeground(Color.RED);
                appendToChat("Error", "Failed to connect: " + e.getMessage());
                e.printStackTrace();
            });
        }
    }
    
    private static String[] promptLogin() {
        JTextField emailField = new JTextField("anhminh.gdev@gmail.com");
        JPasswordField passwordField = new JPasswordField("user123");
        
        Object[] message = {
            "Email:", emailField,
            "Password:", passwordField
        };
        
        int option = JOptionPane.showConfirmDialog(mainFrame, message, "Login", JOptionPane.OK_CANCEL_OPTION);
        if (option == JOptionPane.OK_OPTION) {
            return new String[]{
                emailField.getText(),
                new String(passwordField.getPassword())
            };
        }
        return null;
    }
    
    private static void sendMessage() {
        if (!isConnected || stompSession == null) {
            appendToChat("System", "Not connected to server");
            return;
        }
        
        String messageText = messageField.getText().trim();
        if (messageText.isEmpty()) {
            return;
        }
        
        try {
            SendMessageRequestDTO message = new SendMessageRequestDTO();
            message.setConversationId(CHAT_CONVERSATION_ID);
            message.setContent(messageText);
            
            // Send message
            stompSession.send("/app/chat.sendMessage/" + CHAT_CONVERSATION_ID, message);
            
            // Clear input field
            messageField.setText("");
            
            // We don't add the message to chat history here because
            // it will come back through the subscription
        } catch (Exception e) {
            appendToChat("Error", "Failed to send message: " + e.getMessage());
        }
    }
    
    private static void appendToChat(String sender, String message) {
        SwingUtilities.invokeLater(() -> {
            SimpleDateFormat sdf = new SimpleDateFormat("HH:mm:ss");
            String timestamp = sdf.format(new Date());
            chatHistoryArea.append("[" + timestamp + "] " + sender + ": " + message + "\n");
            
            // Auto-scroll to bottom
            chatHistoryArea.setCaretPosition(chatHistoryArea.getDocument().getLength());
        });
    }
    
    private static void disconnectFromServer() {
        if (isConnected && stompSession != null && stompSession.isConnected()) {
            try {
                stompSession.disconnect();
                isConnected = false;
            } catch (Exception e) {
                System.err.println("Error disconnecting: " + e.getMessage());
            }
        }
    }

    private static WebSocketStompClient createStompClient() {
        try {
            StandardWebSocketClient webSocketClient = new StandardWebSocketClient();
            
            if (globalPermissiveSslContext == null) {
                System.err.println("WARN: Global permissive SSLContext not initialized! Falling back to new instance (may cause SSL errors).");
                TrustManager[] fallbackTrustAllCerts = new TrustManager[]{
                    new X509TrustManager() {
                        public X509Certificate[] getAcceptedIssuers() { return new X509Certificate[0]; }
                        public void checkClientTrusted(X509Certificate[] certs, String authType) {}
                        public void checkServerTrusted(X509Certificate[] certs, String authType) {}
                    }
                };
                SSLContext fallbackSslContext = SSLContext.getInstance("TLS");
                fallbackSslContext.init(null, fallbackTrustAllCerts, new SecureRandom());
                webSocketClient.getUserProperties().put("org.apache.tomcat.websocket.SSL_CONTEXT", fallbackSslContext);
            } else {
                webSocketClient.getUserProperties().put("org.apache.tomcat.websocket.SSL_CONTEXT", globalPermissiveSslContext);
            }
            
            WebSocketStompClient stompClient = new WebSocketStompClient(webSocketClient);
            stompClient.setMessageConverter(new MappingJackson2MessageConverter());
            
            return stompClient;
        } catch (NoSuchAlgorithmException | KeyManagementException e) {
            throw new RuntimeException("Failed to create secure WebSocket client", e);
        }
    }

    // STOMP session handler to handle connection and messages
    private static class ChatSessionHandler implements StompSessionHandler {
        @Override
        public void afterConnected(StompSession session, StompHeaders connectedHeaders) {
            SwingUtilities.invokeLater(() -> {
                appendToChat("System", "STOMP Session established");
            });
        }

        @Override
        public void handleException(StompSession session, StompCommand command, StompHeaders headers, byte[] payload, Throwable exception) {
            SwingUtilities.invokeLater(() -> {
                appendToChat("Error", "Error handling STOMP command [" + command + "]: " + exception.getMessage());
                exception.printStackTrace();
            });
        }

        @Override
        public void handleTransportError(StompSession session, Throwable exception) {
            SwingUtilities.invokeLater(() -> {
                appendToChat("Error", "Transport error: " + exception.getMessage());
                statusLabel.setText("Status: Connection error");
                connectionStatusLabel.setForeground(Color.RED);
                sendButton.setEnabled(false);
                isConnected = false;
            });
            
            exception.printStackTrace();
            
            // Try to reconnect if this is a connection issue
            if (session == null || !session.isConnected()) {
                SwingUtilities.invokeLater(() -> {
                    appendToChat("System", "Connection lost. Please reconnect.");
                });
            }
        }

        @Override
        public Type getPayloadType(StompHeaders headers) {
            // Handle different message types based on destination
            String destination = headers.getDestination();
            if (destination != null) {
                if (destination.startsWith("/topic/errors")) {
                    return Map.class;
                }
                if (destination.startsWith("/topic/conversation/")) {
                    return MessageDTO.class; // Chat messages
                }
                if (destination.startsWith("/topic/product/") && destination.endsWith("/reviews")) {
                    return ProductReviewDTO.class; // Product reviews
                }
            }
            return Object.class; // Fallback for unknown types or system messages
        }

        @Override
        public void handleFrame(StompHeaders headers, Object payload) {
            if (payload instanceof MessageDTO) {
                MessageDTO message = (MessageDTO) payload;
                SwingUtilities.invokeLater(() -> {
                    appendToChat(message.getSenderFullName(), message.getContent());
                });
            } else if (payload instanceof ProductReviewDTO) {
                ProductReviewDTO review = (ProductReviewDTO) payload;
                SwingUtilities.invokeLater(() -> {
                    appendToChat("Product Review (Product ID: " + review.getProductId() + ")",
                        "By " + review.getReviewerName() + " (Rating: " + review.getRating() + "): " + review.getComment());
                });
            } else if (payload instanceof Map) {
                SwingUtilities.invokeLater(() -> {
                    appendToChat("System", "System message: " + payload);
                });
            } else {
                SwingUtilities.invokeLater(() -> {
                    appendToChat("System", "Received: " + payload);
                });
            }
        }
    }

    // Updated SSL verification disabling method to affect all connections
    private static void disableSslVerification() {
        try {
            TrustManager[] trustAllCerts = new TrustManager[]{
                new X509TrustManager() {
                    public X509Certificate[] getAcceptedIssuers() {
                        return new X509Certificate[0];
                    }
                    public void checkClientTrusted(X509Certificate[] certs, String authType) {}
                    public void checkServerTrusted(X509Certificate[] certs, String authType) {}
                }
            };
            
            SSLContext sc = SSLContext.getInstance("TLS");
            sc.init(null, trustAllCerts, new SecureRandom());
            
            globalPermissiveSslContext = sc;
            
            HttpsURLConnection.setDefaultSSLSocketFactory(sc.getSocketFactory());
            
            HostnameVerifier allHostsValid = (hostname, session) -> true;
            HttpsURLConnection.setDefaultHostnameVerifier(allHostsValid);
        } catch (Exception e) {
            e.printStackTrace();
            throw new RuntimeException("Failed to disable SSL verification", e);
        }
    }
}
