package demo.com.example.testserver.product.repository;

import org.springframework.data.domain.Sort;
import java.util.stream.Collectors;

public class NativeQuerySortHelper {

    public static String getSortClause(Sort sort) {
        if (sort == null || sort.isUnsorted()) {
            return "ngay_tao DESC"; // Default sort for san_pham table
        }
        return sort.get()
            .map(order -> {
                String property = order.getProperty();
                String sqlColumn;
                // Map entity property names to actual SQL column names
                switch (property.toLowerCase()) {
                    case "createddate":
                    case "newest": // "newest" is an alias for createdDate
                        sqlColumn = "ngay_tao";
                        break;
                    case "name":
                        sqlColumn = "ten_san_pham";
                        break;
                    case "averagerating":
                    case "rating": // "rating" is an alias for averageRating
                        sqlColumn = "average_rating";
                        break;
                    case "variantzeroprice": // This is used by ProductSortBuilder for "price"
                    case "price":
                        sqlColumn = "variant_zero_price"; // Assuming this column exists and is suitable for general price sort
                        break;
                    // Add other property-to-column mappings as needed
                    default:
                        // Fallback to property name if no specific mapping, or default to a known column
                        // For safety, default to a known sortable column if property is unrecognized
                        sqlColumn = "ngay_tao"; // Default fallback column
                }
                return sqlColumn + " " + (order.isAscending() ? "ASC" : "DESC");
            })
            .collect(Collectors.joining(", "));
    }
}
