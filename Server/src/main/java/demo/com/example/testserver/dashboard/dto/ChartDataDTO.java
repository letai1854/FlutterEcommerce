package demo.com.example.testserver.dashboard.dto;

import java.util.List;

public class ChartDataDTO {
    private List<TimeSeriesDataPointDTO> revenueOverTime;
    private List<TimeSeriesDataPointDTO> ordersOverTime;
    private List<TimeSeriesDataPointDTO> productsSoldOverTime;

    public ChartDataDTO(List<TimeSeriesDataPointDTO> revenueOverTime,
                        List<TimeSeriesDataPointDTO> ordersOverTime,
                        List<TimeSeriesDataPointDTO> productsSoldOverTime) {
        this.revenueOverTime = revenueOverTime;
        this.ordersOverTime = ordersOverTime;
        this.productsSoldOverTime = productsSoldOverTime;
    }

    public List<TimeSeriesDataPointDTO> getRevenueOverTime() {
        return revenueOverTime;
    }

    public void setRevenueOverTime(List<TimeSeriesDataPointDTO> revenueOverTime) {
        this.revenueOverTime = revenueOverTime;
    }

    public List<TimeSeriesDataPointDTO> getOrdersOverTime() {
        return ordersOverTime;
    }

    public void setOrdersOverTime(List<TimeSeriesDataPointDTO> ordersOverTime) {
        this.ordersOverTime = ordersOverTime;
    }

    public List<TimeSeriesDataPointDTO> getProductsSoldOverTime() {
        return productsSoldOverTime;
    }

    public void setProductsSoldOverTime(List<TimeSeriesDataPointDTO> productsSoldOverTime) {
        this.productsSoldOverTime = productsSoldOverTime;
    }
}
