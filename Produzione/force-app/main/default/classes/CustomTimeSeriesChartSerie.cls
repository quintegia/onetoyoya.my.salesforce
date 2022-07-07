public class CustomTimeSeriesChartSerie {
    
    public String id;
    public List<Integer> pattern;
    public String color;
    public List<CustomTimeSeriesChartSerieValue> values;
    public Map<String, Object> extras;
    public String info;
    
    public CustomTimeSeriesChartSerie(String id, String color, List<Integer> pattern){
        
        this.id = id;
        this.pattern = pattern;
        this.color = color;
        this.values = new List<CustomTimeSeriesChartSerieValue>();
        this.extras = new Map<String, Object>();
        
    }

}