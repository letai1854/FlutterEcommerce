package demo.com.example.testserver.chat;

import demo.com.example.testserver.chat.dto.ConversationDTO;
import demo.com.example.testserver.chat.dto.MessageDTO;
import demo.com.example.testserver.chat.dto.SendMessageRequestDTO;
import demo.com.example.testserver.chat.model.Conversation;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.*;
import org.springframework.messaging.converter.MappingJackson2MessageConverter;
import org.springframework.messaging.simp.stomp.*;
import org.springframework.util.concurrent.ListenableFuture;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.socket.WebSocketHttpHeaders;
import org.springframework.web.socket.client.standard.StandardWebSocketClient;
import org.springframework.web.socket.messaging.WebSocketStompClient;

import javax.net.ssl.*;
import javax.swing.*;
import javax.swing.border.EmptyBorder;
import javax.swing.border.TitledBorder;
import javax.swing.text.*;
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
import java.util.*;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutionException;

public class AdminChatClient {
    private static final String WS_URL = "wss://localhost:8443/ws/websocket";
    private static final String API_URL = "https://localhost:8443";
    private static String jwtToken = "";
    private static SSLContext globalPermissiveSslContext;
    private static StompSession stompSession;
    private static final Map<Integer, ConversationDTO> activeConversations = new ConcurrentHashMap<>();
    private static Integer selectedConversationId = null;
    private static final Map<Integer, List<MessageDTO>> conversationMessages = new ConcurrentHashMap<>();
    
    // Swing GUI components
    private static JFrame mainFrame;
    private static JList<ConversationListItem> conversationsList;
    private static DefaultListModel<ConversationListItem> conversationsModel;
    private static JTextPane messagesTextPane;
    private static StyledDocument messagesDocument;
    private static JTextArea messageInputArea;
    private static JButton sendButton;
    private static JComboBox<StatusItem> statusComboBox;
    private static JButton refreshButton;
    private static JLabel statusLabel;
    private static SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
    private static Style customerStyle;
    private static Style adminStyle;
    private static Style systemStyle;

    public static void main(String[] args) {
        disableSslVerification();
        
        // Use SwingUtilities to ensure GUI creation happens on the Event Dispatch Thread
        SwingUtilities.invokeLater(() -> createAndShowGUI());
    }
    
    private static void createAndShowGUI() {
        try {
            // Set Look and Feel to system
            UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
        } catch (Exception e) {
            System.err.println("Could not set look and feel: " + e.getMessage());
        }
        
        // Create main frame
        mainFrame = new JFrame("Admin Chat Client");
        mainFrame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        mainFrame.setSize(1000, 700);
        mainFrame.setLayout(new BorderLayout());
        
        // Create panels
        JPanel leftPanel = new JPanel(new BorderLayout());
        JPanel rightPanel = new JPanel(new BorderLayout());
        JSplitPane splitPane = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT, leftPanel, rightPanel);
        splitPane.setDividerLocation(300);
        
        // Left panel - Conversations List
        conversationsModel = new DefaultListModel<>();
        conversationsList = new JList<>(conversationsModel);
        conversationsList.setCellRenderer(new ConversationCellRenderer());
        conversationsList.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        JScrollPane conversationsScrollPane = new JScrollPane(conversationsList);
        
        JPanel conversationsPanel = new JPanel(new BorderLayout());
        conversationsPanel.setBorder(BorderFactory.createTitledBorder("Conversations"));
        conversationsPanel.add(conversationsScrollPane, BorderLayout.CENTER);
        
        refreshButton = new JButton("Refresh Conversations");
        JPanel conversationButtonsPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
        conversationButtonsPanel.add(refreshButton);
        conversationsPanel.add(conversationButtonsPanel, BorderLayout.SOUTH);
        
        leftPanel.add(conversationsPanel, BorderLayout.CENTER);
        
        // Right panel - Top section for conversation details
        JPanel conversationDetailsPanel = new JPanel(new BorderLayout());
        conversationDetailsPanel.setBorder(BorderFactory.createTitledBorder("Conversation Details"));
        
        JPanel statusPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
        statusPanel.add(new JLabel("Status:"));
        
        statusComboBox = new JComboBox<>(new StatusItem[] {
                new StatusItem("moi", "NEW"),
                new StatusItem("dang_xu_ly", "PROCESSING"),
                new StatusItem("da_dong", "CLOSED")
        });
        statusComboBox.setEnabled(false);
        statusPanel.add(statusComboBox);
        
        JButton updateStatusButton = new JButton("Update Status");
        updateStatusButton.setEnabled(false);
        statusPanel.add(updateStatusButton);
        
        conversationDetailsPanel.add(statusPanel, BorderLayout.CENTER);
        
        // Right panel - Messages section
        messagesTextPane = new JTextPane();
        messagesTextPane.setEditable(false);
        messagesDocument = messagesTextPane.getStyledDocument();
        
        // Create styles for different message types
        customerStyle = messagesTextPane.addStyle("CustomerStyle", null);
        StyleConstants.setForeground(customerStyle, new Color(0, 100, 0));
        StyleConstants.setBold(customerStyle, true);
        
        adminStyle = messagesTextPane.addStyle("AdminStyle", null);
        StyleConstants.setForeground(adminStyle, new Color(0, 0, 160));
        StyleConstants.setBold(adminStyle, true);
        
        systemStyle = messagesTextPane.addStyle("SystemStyle", null);
        StyleConstants.setForeground(systemStyle, Color.GRAY);
        StyleConstants.setItalic(systemStyle, true);
        
        JScrollPane messagesScrollPane = new JScrollPane(messagesTextPane);
        messagesScrollPane.setBorder(BorderFactory.createTitledBorder("Messages"));
        
        // Bottom panel - Message input
        JPanel messageInputPanel = new JPanel(new BorderLayout());
        messageInputPanel.setBorder(BorderFactory.createTitledBorder("Send Message"));
        
        messageInputArea = new JTextArea(5, 20);
        messageInputArea.setLineWrap(true);
        messageInputArea.setWrapStyleWord(true);
        messageInputArea.setEnabled(false);
        JScrollPane messageInputScrollPane = new JScrollPane(messageInputArea);
        
        sendButton = new JButton("Send");
        sendButton.setEnabled(false);
        
        messageInputPanel.add(messageInputScrollPane, BorderLayout.CENTER);
        messageInputPanel.add(sendButton, BorderLayout.EAST);
        
        // Status bar at the bottom
        statusLabel = new JLabel("Please login...");
        statusLabel.setBorder(new EmptyBorder(5, 10, 5, 10));
        
        // Add components to right panel
        rightPanel.add(conversationDetailsPanel, BorderLayout.NORTH);
        rightPanel.add(messagesScrollPane, BorderLayout.CENTER);
        rightPanel.add(messageInputPanel, BorderLayout.SOUTH);
        
        // Add main components to the frame
        mainFrame.add(splitPane, BorderLayout.CENTER);
        mainFrame.add(statusLabel, BorderLayout.SOUTH);
        
        // Add event listeners
        conversationsList.addListSelectionListener(e -> {
            if (!e.getValueIsAdjusting()) {
                ConversationListItem selected = conversationsList.getSelectedValue();
                if (selected != null) {
                    selectConversation(selected.getConversationId());
                    statusComboBox.setEnabled(true);
                    updateStatusButton.setEnabled(true);
                    messageInputArea.setEnabled(true);
                    sendButton.setEnabled(true);
                    
                    // Set the status combobox to current status
                    ConversationDTO conversation = activeConversations.get(selected.getConversationId());
                    if (conversation != null) {
                        String currentStatus = conversation.getStatus().toString();
                        for (int i = 0; i < statusComboBox.getItemCount(); i++) {
                            if (statusComboBox.getItemAt(i).getValue().equals(currentStatus)) {
                                statusComboBox.setSelectedIndex(i);
                                break;
                            }
                        }
                    }
                }
            }
        });
        
        refreshButton.addActionListener(e -> {
            updateStatus("Refreshing conversations...");
            new Thread(() -> fetchAndSubscribeToActiveConversations()).start();
        });
        
        sendButton.addActionListener(e -> {
            if (selectedConversationId != null && !messageInputArea.getText().trim().isEmpty()) {
                sendMessageToSelectedConversation();
            }
        });
        
        updateStatusButton.addActionListener(e -> {
            if (selectedConversationId != null) {
                StatusItem selectedStatus = (StatusItem) statusComboBox.getSelectedItem();
                updateConversationStatus(selectedStatus.getValue());
            }
        });
        
        mainFrame.addWindowListener(new WindowAdapter() {
            @Override
            public void windowClosing(WindowEvent e) {
                if (stompSession != null && stompSession.isConnected()) {
                    stompSession.disconnect();
                    System.out.println("Disconnected from WebSocket server");
                }
                System.exit(0);
            }
        });
        
        // Display the frame
        mainFrame.setLocationRelativeTo(null);
        mainFrame.setVisible(true);
        
        // Show login dialog
        showLoginDialog();
    }
    
    private static void showLoginDialog() {
        JDialog loginDialog = new JDialog(mainFrame, "Admin Login", true);
        loginDialog.setLayout(new BorderLayout());
        loginDialog.setSize(400, 200);
        loginDialog.setLocationRelativeTo(mainFrame);
        
        JPanel loginPanel = new JPanel(new GridBagLayout());
        loginPanel.setBorder(new EmptyBorder(20, 20, 20, 20));
        GridBagConstraints gbc = new GridBagConstraints();
        gbc.fill = GridBagConstraints.HORIZONTAL;
        gbc.insets = new Insets(5, 5, 5, 5);
        
        JLabel emailLabel = new JLabel("Email:");
        JTextField emailField = new JTextField("admin@example.com", 20);
        
        JLabel passwordLabel = new JLabel("Password:");
        JPasswordField passwordField = new JPasswordField("admin123", 20);
        
        JButton loginButton = new JButton("Login");
        
        gbc.gridx = 0;
        gbc.gridy = 0;
        loginPanel.add(emailLabel, gbc);
        
        gbc.gridx = 1;
        gbc.gridy = 0;
        loginPanel.add(emailField, gbc);
        
        gbc.gridx = 0;
        gbc.gridy = 1;
        loginPanel.add(passwordLabel, gbc);
        
        gbc.gridx = 1;
        gbc.gridy = 1;
        loginPanel.add(passwordField, gbc);
        
        gbc.gridx = 0;
        gbc.gridy = 2;
        gbc.gridwidth = 2;
        gbc.anchor = GridBagConstraints.CENTER;
        loginPanel.add(loginButton, gbc);
        
        loginDialog.add(loginPanel, BorderLayout.CENTER);
        
        loginButton.addActionListener(e -> {
            try {
                updateStatus("Logging in...");
                String email = emailField.getText();
                String password = new String(passwordField.getPassword());
                jwtToken = loginAsAdmin(email, password);
                updateStatus("Login successful. Connecting to WebSocket...");
                loginDialog.dispose();
                
                // Connect to WebSocket after successful login
                connectToWebSocket();
            } catch (Exception ex) {
                JOptionPane.showMessageDialog(loginDialog, 
                        "Login failed: " + ex.getMessage(), 
                        "Login Error", 
                        JOptionPane.ERROR_MESSAGE);
            }
        });
        
        loginDialog.setVisible(true);
    }
    
    private static void connectToWebSocket() {
        new Thread(() -> {
            try {
                // Connect to WebSocket server
                WebSocketStompClient stompClient = createStompClient();
                StompHeaders connectHeaders = new StompHeaders();
                connectHeaders.add("Authorization", "Bearer " + jwtToken);

                ListenableFuture<StompSession> sessionFuture = stompClient.connect(
                        WS_URL,
                        new WebSocketHttpHeaders(),
                        connectHeaders,
                        new AdminSessionHandler());

                stompSession = sessionFuture.get();
                updateStatus("Connected to WebSocket server as Admin!");

                // Fetch and subscribe to all active conversations
                fetchAndSubscribeToActiveConversations();

                // Subscribe to new conversation notifications
                stompSession.subscribe("/topic/admin/conversations/new", new StompFrameHandler() {
                    @Override
                    public Type getPayloadType(StompHeaders headers) {
                        return ConversationDTO.class;
                    }

                    @Override
                    public void handleFrame(StompHeaders headers, Object payload) {
                        if (payload instanceof ConversationDTO) {
                            ConversationDTO newConversation = (ConversationDTO) payload;
                            SwingUtilities.invokeLater(() -> {
                                activeConversations.put(newConversation.getId(), newConversation);
                                updateConversationsList(); // Refresh the list
                                // Automatically subscribe to this new conversation's messages
                                subscribeToConversation(newConversation.getId());
                                
                                String notificationMessage = "New conversation #" + newConversation.getId() + 
                                                             " ('" + newConversation.getTitle() + "') started by " + 
                                                             newConversation.getCustomerFullName();
                                updateStatus(notificationMessage);
                                JOptionPane.showMessageDialog(mainFrame,
                                        notificationMessage,
                                        "New Conversation Alert",
                                        JOptionPane.INFORMATION_MESSAGE);
                                
                                // Optionally, select the new conversation if no other is selected
                                if (selectedConversationId == null) {
                                    for (int i = 0; i < conversationsModel.getSize(); i++) {
                                        if (conversationsModel.getElementAt(i).getConversationId().equals(newConversation.getId())) {
                                            conversationsList.setSelectedIndex(i);
                                            break;
                                        }
                                    }
                                }
                            });
                        }
                    }
                });
                updateStatus("Subscribed to new conversation alerts on /topic/admin/conversations/new");

            } catch (ExecutionException | InterruptedException e) {
                SwingUtilities.invokeLater(() -> {
                    updateStatus("Error connecting to WebSocket server: " + e.getMessage());
                    JOptionPane.showMessageDialog(mainFrame, 
                            "Error connecting to WebSocket: " + e.getMessage(), 
                            "Connection Error", 
                            JOptionPane.ERROR_MESSAGE);
                });
                e.printStackTrace();
            }
        }).start();
    }
    
    private static void selectConversation(Integer conversationId) {
        if (activeConversations.containsKey(conversationId)) {
            selectedConversationId = conversationId;
            ConversationDTO selected = activeConversations.get(selectedConversationId);
            updateStatus("Selected conversation #" + selectedConversationId + 
                      " - " + selected.getTitle() + 
                      " with " + selected.getCustomerFullName());
            
            // Fetch messages for this conversation
            new Thread(() -> fetchMessagesForConversation(conversationId)).start();
        }
    }

    private static void sendMessageToSelectedConversation() {
        if (selectedConversationId == null || messageInputArea.getText().trim().isEmpty()) {
            return;
        }

        String content = messageInputArea.getText().trim();
        SendMessageRequestDTO message = new SendMessageRequestDTO();
        message.setConversationId(selectedConversationId);
        message.setContent(content);

        try {
            stompSession.send("/app/chat.sendMessage/" + selectedConversationId, message);
            updateStatus("Message sent to conversation #" + selectedConversationId);
            
            // Clear the input area after sending
            messageInputArea.setText("");
            messageInputArea.requestFocus();
        } catch (Exception e) {
            updateStatus("Error sending message: " + e.getMessage());
            JOptionPane.showMessageDialog(mainFrame, 
                    "Error sending message: " + e.getMessage(), 
                    "Send Error", 
                    JOptionPane.ERROR_MESSAGE);
        }
    }

    private static void displayConversationMessages(int conversationId) {
        List<MessageDTO> messages = conversationMessages.get(conversationId);
        
        // Clear existing messages
        SwingUtilities.invokeLater(() -> {
            try {
                messagesDocument.remove(0, messagesDocument.getLength());
                
                // Display conversation info
                ConversationDTO conversation = activeConversations.get(conversationId);
                if (conversation != null) {
                    messagesDocument.insertString(
                            messagesDocument.getLength(),
                            "Conversation #" + conversationId + ": " + 
                            conversation.getTitle() + " with " + 
                            conversation.getCustomerFullName() + "\n\n",
                            systemStyle);
                }
                
                if (messages == null || messages.isEmpty()) {
                    messagesDocument.insertString(
                            messagesDocument.getLength(),
                            "No messages in this conversation yet.\n",
                            systemStyle);
                    return;
                }
                
                // Display messages
                for (MessageDTO msg : messages) {
                    String sender = msg.getSenderFullName();
                    boolean isAdmin = (conversation != null && 
                                    !msg.getSenderEmail().equals(conversation.getCustomerEmail()));
                    
                    String timeStr = msg.getSendTime() != null ? 
                                    dateFormat.format(msg.getSendTime()) : "";
                    
                    String header = (isAdmin ? "ADMIN: " : "CUSTOMER: ") + 
                                   sender + " [" + timeStr + "]\n";
                    
                    // Insert sender info
                    messagesDocument.insertString(
                            messagesDocument.getLength(),
                            header,
                            isAdmin ? adminStyle : customerStyle);
                    
                    // Insert message content (with normal style)
                    messagesDocument.insertString(
                            messagesDocument.getLength(),
                            msg.getContent() + "\n",
                            null);
                    
                    // Add image info if present
                    if (msg.getImageUrl() != null && !msg.getImageUrl().isEmpty()) {
                        messagesDocument.insertString(
                                messagesDocument.getLength(),
                                "[Image: " + msg.getImageUrl() + "]\n",
                                null);
                    }
                    
                    // Add separator
                    messagesDocument.insertString(
                            messagesDocument.getLength(),
                            "----------------------------------------\n",
                            null);
                }
                
                // Scroll to the bottom
                messagesTextPane.setCaretPosition(messagesDocument.getLength());
                
            } catch (BadLocationException e) {
                e.printStackTrace();
            }
        });
    }

    private static void updateConversationStatus(String newStatus) {
        if (selectedConversationId == null) {
            return;
        }

        try {
            // Call API to update status
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("Authorization", "Bearer " + jwtToken);

            String url = API_URL + "/api/chat/conversations/" + selectedConversationId + "/status?newStatus=" + newStatus;
            HttpEntity<String> entity = new HttpEntity<>(headers);

            new Thread(() -> {
                try {
                    RestTemplate restTemplate = new RestTemplate();
                    ResponseEntity<ConversationDTO> response = restTemplate.exchange(
                        url, HttpMethod.PATCH, entity, ConversationDTO.class);

                    if (response.getStatusCode() == HttpStatus.OK) {
                        SwingUtilities.invokeLater(() -> {
                            updateStatus("Conversation status updated successfully to " + newStatus);
                            ConversationDTO updatedConversation = response.getBody();
                            if (updatedConversation != null) {
                                activeConversations.put(updatedConversation.getId(), updatedConversation);
                                updateConversationsList();
                            }
                        });
                    } else {
                        SwingUtilities.invokeLater(() -> {
                            updateStatus("Failed to update conversation status. Response: " + response.getStatusCode());
                        });
                    }
                } catch (Exception e) {
                    SwingUtilities.invokeLater(() -> {
                        updateStatus("Error updating conversation status: " + e.getMessage());
                        JOptionPane.showMessageDialog(mainFrame, 
                                "Error updating status: " + e.getMessage(), 
                                "Status Update Error", 
                                JOptionPane.ERROR_MESSAGE);
                    });
                }
            }).start();
        } catch (Exception e) {
            updateStatus("Error updating conversation status: " + e.getMessage());
        }
    }

    private static void fetchAndSubscribeToActiveConversations() {
        try {
            // Get all active conversations for admin
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("Authorization", "Bearer " + jwtToken);

            String url = API_URL + "/api/chat/conversations/admin";
            HttpEntity<String> entity = new HttpEntity<>(headers);

            RestTemplate restTemplate = new RestTemplate();
            ResponseEntity<Map<String, Object>> response = restTemplate.exchange(
                url, HttpMethod.GET, entity, new ParameterizedTypeReference<Map<String, Object>>() {});

            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                Map<String, Object> pageResponse = response.getBody();
                List<Map<String, Object>> content = (List<Map<String, Object>>) pageResponse.get("content");

                if (content != null) {
                    // Clear existing conversations
                    Set<Integer> oldConversationIds = new HashSet<>(activeConversations.keySet());
                    activeConversations.clear();

                    for (Map<String, Object> convData : content) {
                        try {
                            ConversationDTO conv = new ConversationDTO();
                            
                            // Use safer conversion method for numeric fields
                            conv.setId(safeToInt(convData.get("id")));
                            conv.setCustomerId(safeToInt(convData.get("customerId")));
                            conv.setCustomerEmail((String) convData.get("customerEmail"));
                            conv.setCustomerFullName((String) convData.get("customerFullName"));
                            conv.setTitle((String) convData.get("title"));
                            
                            // Handle status enum
                            String status = (String) convData.get("status");
                            if (status != null) {
                                conv.setStatus(Conversation.ConversationStatus.valueOf(status));
                            }
                            
                            // Parse dates safely
                            if (convData.get("createdDate") != null) {
                                conv.setCreatedDate(safeToDate(convData.get("createdDate")));
                            }
                            if (convData.get("updatedDate") != null) {
                                conv.setUpdatedDate(safeToDate(convData.get("updatedDate")));
                            }
                            
                            // Handle lastMessage if present
                            Map<String, Object> lastMessageData = (Map<String, Object>) convData.get("lastMessage");
                            if (lastMessageData != null) {
                                MessageDTO lastMessage = new MessageDTO();
                                lastMessage.setId(safeToInt(lastMessageData.get("id")));
                                lastMessage.setConversationId(safeToInt(lastMessageData.get("conversationId")));
                                lastMessage.setSenderId(safeToInt(lastMessageData.get("senderId")));
                                lastMessage.setSenderEmail((String) lastMessageData.get("senderEmail"));
                                lastMessage.setSenderFullName((String) lastMessageData.get("senderFullName"));
                                lastMessage.setContent((String) lastMessageData.get("content"));
                                lastMessage.setImageUrl((String) lastMessageData.get("imageUrl"));
                                
                                if (lastMessageData.get("sendTime") != null) {
                                    lastMessage.setSendTime(safeToDate(lastMessageData.get("sendTime")));
                                }
                                
                                conv.setLastMessage(lastMessage);
                            }
                            
                            activeConversations.put(conv.getId(), conv);
                            
                            // Subscribe to conversation if not already subscribed
                            if (!oldConversationIds.contains(conv.getId())) {
                                subscribeToConversation(conv.getId());
                            }
                        } catch (Exception e) {
                            System.err.println("Error processing conversation data: " + e.getMessage());
                            e.printStackTrace();
                        }
                    }
                    
                    // Update the conversations list in the UI
                    SwingUtilities.invokeLater(() -> {
                        updateConversationsList();
                        updateStatus("Fetched " + activeConversations.size() + " conversations");
                    });
                }
            } else {
                SwingUtilities.invokeLater(() -> {
                    updateStatus("Failed to fetch conversations. Response: " + response.getStatusCode());
                });
            }
        } catch (Exception e) {
            SwingUtilities.invokeLater(() -> {
                updateStatus("Error fetching conversations: " + e.getMessage());
                e.printStackTrace();
            });
        }
    }
    
    private static void updateConversationsList() {
        // Update conversations list model
        conversationsModel.clear();
        
        List<ConversationDTO> sortedConversations = new ArrayList<>(activeConversations.values());
        sortedConversations.sort(Comparator.comparing(ConversationDTO::getUpdatedDate).reversed());
        
        for (ConversationDTO conv : sortedConversations) {
            conversationsModel.addElement(new ConversationListItem(conv));
        }
        
        // If we had a selected conversation, try to reselect it
        if (selectedConversationId != null) {
            for (int i = 0; i < conversationsModel.getSize(); i++) {
                if (conversationsModel.getElementAt(i).getConversationId().equals(selectedConversationId)) {
                    conversationsList.setSelectedIndex(i);
                    break;
                }
            }
        }
    }
    
    // Helper method to safely convert various types to Integer
    private static int safeToInt(Object value) {
        if (value == null) {
            return 0;
        }
        if (value instanceof Number) {
            return ((Number) value).intValue();
        }
        if (value instanceof String) {
            try {
                return Integer.parseInt((String) value);
            } catch (NumberFormatException e) {
                System.err.println("Warning: Could not parse string to integer: " + value);
                return 0;
            }
        }
        System.err.println("Warning: Unexpected type for integer conversion: " + value.getClass().getName());
        return 0;
    }
    
    // Helper method to safely convert various types to Date
    private static Date safeToDate(Object value) {
        if (value == null) {
            return new Date();
        }
        if (value instanceof Number) {
            return new Date(((Number) value).longValue());
        }
        if (value instanceof String) {
            String strValue = (String) value;
            try {
                // Try parsing as a long timestamp first
                return new Date(Long.parseLong(strValue));
            } catch (NumberFormatException e) {
                // Try parsing as ISO date format with different patterns
                try {
                    // For formats like "2025-05-09T07:14:07.000+00:00"
                    if (strValue.contains("+")) {
                        // Replace the timezone format from "+00:00" to "+0000" which SimpleDateFormat can handle
                        strValue = strValue.replaceAll("\\+([0-9]{2}):([0-9]{2})$", "+$1$2");
                    }
                    
                    // Try multiple date format patterns
                    SimpleDateFormat[] formatters = new SimpleDateFormat[] {
                        new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSXXX"),
                        new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ"),
                        new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"),
                        new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss")
                    };
                    
                    for (SimpleDateFormat formatter : formatters) {
                        try {
                            return formatter.parse(strValue);
                        } catch (Exception parseException) {
                            // Try next format
                        }
                    }
                    
                    System.err.println("Warning: Could not parse string to date: " + value);
                    return new Date();
                } catch (Exception e2) {
                    System.err.println("Warning: Could not parse string to date: " + value);
                    return new Date();
                }
            }
        }
        if (value instanceof Date) {
            return (Date) value;
        }
        System.err.println("Warning: Unexpected type for date conversion: " + value.getClass().getName());
        return new Date();
    }

    private static void subscribeToConversation(Integer conversationId) {
        try {
            String destination = "/topic/conversation/" + conversationId;
            stompSession.subscribe(destination, new AdminMessageHandler(conversationId));
            System.out.println("Subscribed to conversation: " + conversationId);
        } catch (Exception e) {
            System.err.println("Error subscribing to conversation " + conversationId + ": " + e.getMessage());
        }
    }

    private static void fetchMessagesForConversation(Integer conversationId) {
        try {
            updateStatus("Fetching messages for conversation #" + conversationId + "...");
            
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("Authorization", "Bearer " + jwtToken);

            String url = API_URL + "/api/chat/conversations/" + conversationId + "/messages";
            HttpEntity<String> entity = new HttpEntity<>(headers);

            RestTemplate restTemplate = new RestTemplate();
            ResponseEntity<Map<String, Object>> response = restTemplate.exchange(
                url, HttpMethod.GET, entity, new ParameterizedTypeReference<Map<String, Object>>() {});

            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                Map<String, Object> pageResponse = response.getBody();
                List<Map<String, Object>> content = (List<Map<String, Object>>) pageResponse.get("content");

                if (content != null) {
                    List<MessageDTO> messages = new ArrayList<>();
                    for (Map<String, Object> msgData : content) {
                        try {
                            MessageDTO msg = new MessageDTO();
                            msg.setId(safeToInt(msgData.get("id")));
                            msg.setConversationId(safeToInt(msgData.get("conversationId")));
                            msg.setSenderId(safeToInt(msgData.get("senderId")));
                            msg.setSenderEmail((String) msgData.get("senderEmail"));
                            msg.setSenderFullName((String) msgData.get("senderFullName"));
                            msg.setContent((String) msgData.get("content"));
                            msg.setImageUrl((String) msgData.get("imageUrl"));
                            
                            if (msgData.get("sendTime") != null) {
                                msg.setSendTime(safeToDate(msgData.get("sendTime")));
                            }
                            
                            messages.add(msg);
                        } catch (Exception e) {
                            System.err.println("Error processing message data: " + e.getMessage());
                            e.printStackTrace();
                        }
                    }
                    
                    // Sort messages by send time (oldest first)
                    messages.sort(Comparator.comparing(MessageDTO::getSendTime));
                    
                    conversationMessages.put(conversationId, messages);
                    updateStatus("Fetched " + messages.size() + " messages for conversation #" + conversationId);
                    
                    // Display messages
                    displayConversationMessages(conversationId);
                }
            } else {
                updateStatus("Failed to fetch messages. Response: " + response.getStatusCode());
            }
        } catch (Exception e) {
            updateStatus("Error fetching messages: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    private static String loginAsAdmin(String email, String password) {
        Map<String, String> loginRequest = new HashMap<>();
        loginRequest.put("email", email);
        loginRequest.put("password", password);
        
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        
        HttpEntity<Map<String, String>> requestEntity = new HttpEntity<>(loginRequest, headers);
        
        RestTemplate restTemplate = new RestTemplate();
        try {
            ResponseEntity<Map> response = restTemplate.postForEntity(
                    API_URL + "/api/users/login",
                    requestEntity, 
                    Map.class);
            
            if (response.getBody() != null && response.getBody().containsKey("token")) {
                return response.getBody().get("token").toString();
            } else {
                throw new RuntimeException("Failed to retrieve token from login response");
            }
        } catch (Exception e) {
            throw new RuntimeException("Login failed: " + e.getMessage(), e);
        }
    }

    private static void updateStatus(String message) {
        SwingUtilities.invokeLater(() -> {
            statusLabel.setText(message);
            System.out.println(message);  // Also log to console
        });
    }

    private static WebSocketStompClient createStompClient() {
        try {
            StandardWebSocketClient webSocketClient = new StandardWebSocketClient();
            
            if (globalPermissiveSslContext == null) {
                System.err.println("WARN: Global permissive SSLContext not initialized! Falling back to new instance.");
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

    // Custom list item for conversations
    private static class ConversationListItem {
        private final ConversationDTO conversation;
        
        public ConversationListItem(ConversationDTO conversation) {
            this.conversation = conversation;
        }
        
        public Integer getConversationId() {
            return conversation.getId();
        }
        
        public ConversationDTO getConversation() {
            return conversation;
        }
    }
    
    // Custom cell renderer for conversations list
    private static class ConversationCellRenderer extends DefaultListCellRenderer {
        @Override
        public Component getListCellRendererComponent(JList<?> list, Object value, 
                int index, boolean isSelected, boolean cellHasFocus) {
            
            JLabel label = (JLabel) super.getListCellRendererComponent(
                    list, value, index, isSelected, cellHasFocus);
            
            if (value instanceof ConversationListItem) {
                ConversationDTO conv = ((ConversationListItem) value).getConversation();
                
                // Format the status
                String status = conv.getStatus().toString();
                String statusDisplay = "";
                switch (status) {
                    case "moi":
                        statusDisplay = "NEW";
                        label.setForeground(Color.RED);
                        break;
                    case "dang_xu_ly":
                        statusDisplay = "PROCESSING";
                        label.setForeground(Color.BLUE);
                        break;
                    case "da_dong":
                        statusDisplay = "CLOSED";
                        label.setForeground(Color.GRAY);
                        break;
                    default:
                        statusDisplay = status;
                }
                
                // Format the display text
                String title = conv.getTitle() != null ? conv.getTitle() : "No Title";
                String customer = conv.getCustomerFullName() != null ? conv.getCustomerFullName() : "Unknown";
                
                // Get last message preview
                String lastMessagePreview = "";
                if (conv.getLastMessage() != null && conv.getLastMessage().getContent() != null) {
                    String content = conv.getLastMessage().getContent();
                    lastMessagePreview = content.substring(0, Math.min(20, content.length()));
                    if (content.length() > 20) lastMessagePreview += "...";
                }
                
                // Set the text
                label.setText(String.format("#%d - %s [%s] - %s - %s", 
                        conv.getId(), title, statusDisplay, customer, lastMessagePreview));
                
                // Set the tooltip
                label.setToolTipText(String.format(
                        "<html>ID: %d<br>Title: %s<br>Customer: %s<br>Status: %s<br>Last message: %s</html>",
                        conv.getId(), title, customer, statusDisplay, 
                        conv.getLastMessage() != null ? conv.getLastMessage().getContent() : "No messages"));
            }
            
            return label;
        }
    }
    
    // Status item for the status dropdown
    private static class StatusItem {
        private final String value;
        private final String displayName;
        
        public StatusItem(String value, String displayName) {
            this.value = value;
            this.displayName = displayName;
        }
        
        public String getValue() {
            return value;
        }
        
        @Override
        public String toString() {
            return displayName;
        }
    }

    private static class AdminSessionHandler implements StompSessionHandler {
        @Override
        public void afterConnected(StompSession session, StompHeaders connectedHeaders) {
            System.out.println("STOMP Session established for Admin");
        }

        @Override
        public void handleException(StompSession session, StompCommand command, StompHeaders headers, byte[] payload, Throwable exception) {
            updateStatus("Error handling STOMP command [" + command + "]: " + exception.getMessage());
            exception.printStackTrace();
        }

        @Override
        public void handleTransportError(StompSession session, Throwable exception) {
            updateStatus("Transport error: " + exception.getMessage());
            exception.printStackTrace();
            
            if (session == null || !session.isConnected()) {
                updateStatus("Connection lost. Attempting to reconnect...");
                // Could implement reconnection logic here
                
                SwingUtilities.invokeLater(() -> {
                    JOptionPane.showMessageDialog(mainFrame, 
                            "Connection to server lost. Please restart the application.", 
                            "Connection Error", 
                            JOptionPane.ERROR_MESSAGE);
                });
            }
        }

        @Override
        public Type getPayloadType(StompHeaders headers) {
            return Object.class;
        }

        @Override
        public void handleFrame(StompHeaders headers, Object payload) {
            updateStatus("Received system message: " + payload);
        }
    }

    private static class AdminMessageHandler implements StompFrameHandler {
        private final Integer conversationId;

        public AdminMessageHandler(Integer conversationId) {
            this.conversationId = conversationId;
        }

        @Override
        public Type getPayloadType(StompHeaders headers) {
            return MessageDTO.class;
        }

        @Override
        public void handleFrame(StompHeaders headers, Object payload) {
            if (payload instanceof MessageDTO) {
                MessageDTO message = (MessageDTO) payload;
                
                // Store message in our local collection
                List<MessageDTO> messages = conversationMessages.computeIfAbsent(conversationId, k -> new ArrayList<>());
                messages.add(message);
                
                // Get conversation details for better notification
                ConversationDTO conversation = activeConversations.get(conversationId);
                String conversationTitle = conversation != null ? conversation.getTitle() : "Unknown";
                
                // Check if this is from the customer (not from admin)
                boolean isFromCustomer = conversation != null && 
                                       message.getSenderEmail().equals(conversation.getCustomerEmail());
                
                // Update UI with new message
                SwingUtilities.invokeLater(() -> {
                    // If this is the currently displayed conversation, update the messages display
                    if (selectedConversationId != null && selectedConversationId.equals(conversationId)) {
                        displayConversationMessages(conversationId);
                    }
                    
                    // Show notification for customer messages
                    if (isFromCustomer) {
                        // Play a sound or flash the window title
                        Toolkit.getDefaultToolkit().beep();
                        
                        // Show a popup notification
                        if (selectedConversationId == null || !selectedConversationId.equals(conversationId)) {
                            JOptionPane.showMessageDialog(mainFrame,
                                    "New message from " + message.getSenderFullName() + 
                                    " in conversation #" + conversationId + " - " + conversationTitle + ":\n\n" +
                                    message.getContent(),
                                    "New Message",
                                    JOptionPane.INFORMATION_MESSAGE);
                        }
                        
                        updateStatus("New message from " + message.getSenderFullName() + 
                                    " in conversation #" + conversationId);
                    } else {
                        updateStatus("Admin " + message.getSenderFullName() + 
                                   " sent message to conversation #" + conversationId);
                    }
                    
                    // Update the conversation list to show latest message
                    updateConversationsList();
                });
            } else {
                SwingUtilities.invokeLater(() -> {
                    updateStatus("Received non-message update for conversation #" + conversationId + ": " + payload);
                });
            }
        }
    }
}
