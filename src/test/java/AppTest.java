import com.example.Application;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class AppTest {

    @Test
    void testApp() {
        Application app = new Application();
        assertEquals("OK", app.getStatus());
    }
}
