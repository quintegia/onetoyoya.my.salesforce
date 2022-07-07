public class CustomTimeSeriesChartSerieValue {
    
    public Long x;
    public Double y;
    public Map<String, Object> extras;
    
    public CustomTimeSeriesChartSerieValue(Long x, Double y){
        
        this.x = x;
        this.y = y;
        this.extras = new Map<String, Object>();
        
    }

}