package main;
import java.io.IOException;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;
import java.net.SocketException;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;
public class UDPServer {
    static CaesarCipher CaesarCipher = new CaesarCipher();
    static DatabaseManager dbManager = new DatabaseManager();

    private static final int SERVER_PORT = 12345;

    public static void main(String[] args) {
        try (DatagramSocket socket = new DatagramSocket(SERVER_PORT)) {
            System.out.println("UDP Server started on port " + SERVER_PORT);

            byte[] buffer = new byte[1024];

            Connection connection = dbManager.connect();

            while (true) {
                DatagramPacket packet = new DatagramPacket(buffer, buffer.length);
                socket.receive(packet);

                InetAddress clientAddress = packet.getAddress();
                int clientPort = packet.getPort();

                String encryptedText = new String(packet.getData(), 0, packet.getLength());
                System.out.println("Received from client: " + encryptedText);

                // Assuming the key is sent along with the encrypted text, separated by a comma
                String[] parts = encryptedText.split(",");
                int key = 3; // Default key
                String textToDecrypt = encryptedText;

                try {
                    if (parts.length == 2) {
                        textToDecrypt = parts[0];
                        key = Integer.parseInt(parts[1]);
                    }
                } catch (NumberFormatException e) {
                    System.err.println("Invalid key format. Using default key.");
                }

                String decryptedText = CaesarCipher.decrypt(textToDecrypt, key);

                // Count character frequency
                Map<Character, Integer> charFrequency = countCharFrequency(decryptedText);
                System.out.println("Character frequency: " + charFrequency);

                // Save to database
                String charFrequencyString = charFrequency.toString();
                dbManager.saveMessage(encryptedText, encryptedText, decryptedText, key, charFrequencyString);

                // Send response back to client
                String response = "Character frequency: " + charFrequencyString;
                buffer = response.getBytes();
                packet = new DatagramPacket(buffer, buffer.length, clientAddress, clientPort);
                socket.send(packet);
            }

        } catch (SocketException e) {
            System.err.println("SocketException: " + e.getMessage());
        } catch (IOException e) {
            System.err.println("IOException: " + e.getMessage());
        } catch (SQLException e) {
            System.err.println("SQLException: " + e.getMessage());
        } finally {
            // Disconnect from database
            if (dbManager != null) {
               dbManager.disconnect();
            }
        }
    }

    private static Map<Character, Integer> countCharFrequency(String text) {
        Map<Character, Integer> charFrequency = new HashMap<>();
        for (char ch : text.toCharArray()) {
            if (Character.isLetter(ch)) {
                charFrequency.put(ch, charFrequency.getOrDefault(ch, 0) + 1);
            }
        }
        return charFrequency;
    }
}
