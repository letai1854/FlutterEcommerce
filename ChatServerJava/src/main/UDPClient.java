package main;
import java.io.IOException;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;
import java.net.SocketException;
import java.net.UnknownHostException;
import java.util.Scanner;

public class UDPClient {
    static CaesarCipher CaesarCipher = new CaesarCipher();

    private static final String SERVER_ADDRESS = "localhost";
    private static final int SERVER_PORT = 12345;

    public static void main(String[] args) {
        try (DatagramSocket socket = new DatagramSocket()) {
            InetAddress serverAddress = InetAddress.getByName(SERVER_ADDRESS);
            Scanner scanner = new Scanner(System.in);

            System.out.println("Enter text to encrypt and send to server (or type 'exit'):");
            String text = scanner.nextLine();

            while (!text.equalsIgnoreCase("exit")) {
                System.out.println("Enter Caesar key:");
                int key = scanner.nextInt();
                scanner.nextLine(); // Consume newline

                String encryptedText = CaesarCipher.encrypt(text, key);
                byte[] buffer = encryptedText.getBytes();

                DatagramPacket packet = new DatagramPacket(buffer, buffer.length, serverAddress, SERVER_PORT);
                socket.send(packet);

                System.out.println("Sent to server: " + encryptedText);

                // Receive response from server
                buffer = new byte[1024];
                packet = new DatagramPacket(buffer, buffer.length);
                socket.receive(packet);

                String response = new String(packet.getData(), 0, packet.getLength());
                System.out.println("Received from server: " + response);

                System.out.println("Enter text to encrypt and send to server (or type 'exit'):");
                text = scanner.nextLine();
            }

        } catch (SocketException e) {
            System.err.println("SocketException: " + e.getMessage());
        } catch (UnknownHostException e) {
            System.err.println("UnknownHostException: " + e.getMessage());
        } catch (IOException e) {
            System.err.println("IOException: " + e.getMessage());
        }
    }
}
