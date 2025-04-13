package main;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;

public class DatabaseManager {

    private static final String DB_URL = "jdbc:mysql://localhost:3306/chat_db";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "";

    private Connection conn;

    public Connection connect() throws SQLException {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
            System.out.println("Connected to database");
            return conn;
        } catch (ClassNotFoundException e) {
            throw new SQLException("MySQL JDBC Driver not found", e);
        }
    }

    public void disconnect() {
        if (conn != null) {
            try {
                conn.close();
                System.out.println("Disconnected from database");
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }

    public void saveMessage(String originalText, String encryptedText, String decryptedText, int key, String charFrequency) {
        String sql = "INSERT INTO messages (original_text, encrypted_text, decrypted_text, caesar_key, char_frequency) VALUES (?, ?, ?, ?, ?)";
        try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, originalText);
            pstmt.setString(2, encryptedText);
            pstmt.setString(3, decryptedText);
            pstmt.setInt(4, key);
            pstmt.setString(5, charFrequency);
            pstmt.executeUpdate();
            System.out.println("Message saved to database");
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    public static void main(String[] args) throws SQLException {
        DatabaseManager dbManager = new DatabaseManager();
        Connection connection = dbManager.connect();
        if (connection != null) {
            dbManager.saveMessage("Hello", "Khoor", "Hello", 3, "{e=1, h=1, l=2, o=1}");
            dbManager.disconnect();
        }
    }
}
