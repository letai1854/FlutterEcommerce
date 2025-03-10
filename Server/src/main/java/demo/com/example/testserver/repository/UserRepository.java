package demo.com.example.testserver.repository;

import demo.com.example.testserver.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Integer> {
    
    Optional<User> findByEmail(String email);

    @Query("SELECT u FROM User u WHERE u.email = :email AND u.password = :password AND u.status = true")
    Optional<User> findActiveUserByEmailAndPassword(
        @Param("email") String email, 
        @Param("password") String password
    );
    
    @Query("SELECT u FROM User u WHERE u.status = true")
    List<User> findAllActiveUsers();

    @Query("SELECT u FROM User u WHERE u.id = :id")
    Optional<User> findById(@Param("id") Integer id);
}
