public class BubbleChartDotData {
    
    public Double size;
    public Double x;
    public Double y;
    public String color;
    public String info;
    public String extra;
    public String label;
    public Map<String, Object> extras;
    
    public BubbleChartDotData(Double x, Double y, Double size, String color){
        
        this.size = size;
        this.x = x;
        this.y = y;
        this.color = color;
        
    }
    
}