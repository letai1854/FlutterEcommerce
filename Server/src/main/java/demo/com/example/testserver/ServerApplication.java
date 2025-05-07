package demo.com.example.testserver;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
// import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty; // Commented out or removed
import org.springframework.boot.builder.SpringApplicationBuilder;

@SpringBootApplication
// @ConditionalOnProperty(name = "spring.elasticsearch.enabled", havingValue = "true") // Removed this line
public class ServerApplication {

	public static void main(String[] args) {
		new SpringApplicationBuilder(ServerApplication.class)
				.lazyInitialization(true)
				.run(args);
	}

}
