public class CustomTimeSeriesChart {
    
    public final String chartType = 'timeSeriesChart';
    public String title;
    public String subTitle;
    public String info;
    public String brand;
    public String brandId;
    public String color;
    public String pre;
    public String post;
    public Map<String, Object> extras;
    public List<CustomTimeSeriesChartSerie> series;
    public String xLabel;
    public String yLabel;
    
    public CustomTimeSeriesChart(String title, String subtitle, String brand, String brandId, String color, String xLabel, String yLabel, String pre, String post){
        
        this.title = title;
        this.subtitle = subtitle;
        this.brand = brand;
        this.color = brandId;
        this.color = color;
        this.xLabel = xLabel;
        this.yLabel = yLabel;
        this.pre = pre;
        this.post = post;
        this.extras = new Map<String, Object>();
        this.series = new List<CustomTimeSeriesChartSerie>();
        
    }

}