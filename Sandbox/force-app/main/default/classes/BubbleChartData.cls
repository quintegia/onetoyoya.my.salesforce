public class BubbleChartData{
    
    public String title;
    public String subTitle;
    public String brand;
    public String brandId;
    public final String chartType = 'bubbleChart';
    public List<BubbleChartDotData> bubbleChartDots = new List<BubbleChartDotData>();
    public BubbleChartDotData max;
    public BubbleChartDotData min;
    public BubbleChartDotData avg;
    public BubbleChartLabelsData labels;
    public String pre;
    public String post;
    public String info;
    public String color;
    public Map<String, Object> extras;
    
    public BubbleChartData(String title, String subtitle, String brand, BubbleChartLabelsData labels){
        
        this.brand = brand;
        this.title = title;
        this.subTitle = subTitle;
        this.labels = labels;
        
    }
    
    public void addDot(BubbleChartDotData dot){
        
        Integer listSize = this.bubbleChartDots.size();
        
        if(listSize == 0){
        
        	this.bubbleChartDots.add(dot);
            
        }else{
            
            Boolean added = false;
        
            for(Integer i = 0; i < listSize; i++){
                
                if(!added && dot.size < this.bubbleChartDots[i].size){
                    
                    this.bubbleChartDots.add(i, dot);
                    
                    added = true;
                    
                }
                
            }
            
            if(!added){
                
                this.bubbleChartDots.add(dot);
                
            }
            
        }
        
        this.setMax();
        this.setMin();
        this.setAvg();
    }
    
    public void setMax(){
        
        this.max = new BubbleChartDotData(0, 0, 0, null);
        
        for(BubbleChartDotData dot : this.bubbleChartDots){
            
            if(dot.x != null && dot.y != null){
                
                if(dot.x > max.x){
                    this.max.x = dot.x;
                }
                
                if(dot.y > max.y){
                    this.max.y = dot.y;
                }
                
                if(dot.size > max.size){
                    this.max.size = dot.size;
                }
                
            }
            
        }
        
    }
    
    public void setMin(){
        
        this.min = null;
        
        for(BubbleChartDotData dot : this.bubbleChartDots){
            
            if(dot.x != null && dot.y != null){
                
                if(this.min == null){
                    this.min = dot.clone();
                }
                
                if(dot.x < min.x){
                    this.avg.x = dot.x;
                }
                
                if(dot.y < min.y){
                    this.min.y = dot.y;
                }
                
                if(dot.size < max.size){
                    this.min.size = dot.size;
                }
                
            }
            
        }
        
    }
    
    public void setAvg(){
        
        this.avg = new BubbleChartDotData(0, 0, 0, null);
        Integer sample = 0;
        
        for(BubbleChartDotData dot : this.bubbleChartDots){
            
            if(dot.x != null && dot.y != null){
                
                this.avg.x += dot.x;                
                this.avg.y += dot.y;                
                this.avg.size += dot.size;
                sample++;
                
            }
            
        }
        
        if(sample != 0){
        
            this.avg.x /= sample;                
            this.avg.y /= sample;                
            this.avg.size /= sample;
            
        }
        
    }
    
}