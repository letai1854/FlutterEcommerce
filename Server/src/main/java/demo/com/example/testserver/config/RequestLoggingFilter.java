package demo.com.example.testserver.config;

import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.util.Collections;
import java.util.stream.Collectors;

@Component
@Order(Ordered.HIGHEST_PRECEDENCE) // Đảm bảo filter này chạy sớm
public class RequestLoggingFilter implements Filter {

    private static final Logger logger = LoggerFactory.getLogger(RequestLoggingFilter.class);

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        String path = httpRequest.getRequestURI();
        String method = httpRequest.getMethod();
        String queryString = httpRequest.getQueryString();
        String remoteAddr = httpRequest.getRemoteAddr();

        logger.info("Incoming request: Method={}, URI={}, QueryString=[{}], RemoteAddr={}",
                method,
                path,
                queryString == null ? "" : queryString,
                remoteAddr);

        if (path.startsWith("/ws")) {
            String upgradeHeader = httpRequest.getHeader("Upgrade");
            String connectionHeader = httpRequest.getHeader("Connection");
            logger.info("Request to WebSocket path /ws detected. Headers: Upgrade=[{}], Connection=[{}]",
                    upgradeHeader, connectionHeader);

            // Log all headers for /ws requests for detailed debugging
            String headers = Collections.list(httpRequest.getHeaderNames())
                    .stream()
                    .map(headerName -> headerName + ": [" + Collections.list(httpRequest.getHeaders(headerName)).stream().collect(Collectors.joining(", ")) + "]")
                    .collect(Collectors.joining("; "));
            logger.debug("All headers for /ws request: {}", headers);
        }

        chain.doFilter(request, response);
    }

    // Implement init and destroy methods if needed, otherwise leave empty
    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        // Initialization code, if any
    }

    @Override
    public void destroy() {
        // Cleanup code, if any
    }
}
