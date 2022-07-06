public class BarChartData{
    
    public String title;
    public String subTitle;
    public String brand;
    public final String chartType = 'barChart';
    public List<List<BarChartBarData>> barChartBarListData = new List<List<BarChartBarData>>();
    public List<BarChartBarData> max;
    public List<BarChartBarData> min;
    public List<BarChartBarData> avg;
    public String pre;
    public String post;
    public String info;
    public String color;
    
    public BarChartData(String title, String subTitle, String brand){
        
        this.brand = brand;
        this.title = title;
        this.subTitle = subTitle;
        
    }
    
    public void addBarChartBarListData(List<BarChartBarData> barChartBarListData){
        
        this.barChartBarListData.add(barChartBarListData);
        
        this.setMax();
        this.setMin();
        this.setAvg();
    }
    
    public void setMax(){
        
        this.max = new List<BarChartBarData>();
        
        for(List<BarChartBarData> barChartBarList : this.barChartBarListData){
            
            BarChartBarData maxBarChartBarData = new BarChartBarData('max', null, 0, null);
            
            if(barChartBarList != null){
                
                for(BarChartBarData barChartBarData : barChartBarList){
                    
                    maxBarChartBarData.value = barChartBarData.value > maxBarChartBarData.value ? barChartBarData.value : maxBarChartBarData.value;
                    
                }
                
                this.max.add(maxBarChartBarData);
                
            }
            
        }
        
    }
    
    public void setMin(){
        
        this.min = new List<BarChartBarData>();
        
        for(List<BarChartBarData> barChartBarList : this.barChartBarListData){
            
            BarChartBarData minBarChartBarData;
            
            if(barChartBarList != null){
                
                for(BarChartBarData barChartBarData : barChartBarList){
                    
                    if(minBarChartBarData == null){
                        
                        minBarChartBarData = barChartBarData.clone();
                        minBarChartBarData.label = 'min';
                        
                    }
                    
                    minBarChartBarData.value = barChartBarData.value < minBarChartBarData.value ? barChartBarData.value : minBarChartBarData.value;
                    
                }
                
                this.min.add(minBarChartBarData);
                
            }
            
        }
        
    }
    
    public void setAvg(){
        
        this.avg = new List<BarChartBarData>();
        
        Integer i = 0;
        
        for(List<BarChartBarData> barChartBarList : this.barChartBarListData){
            
            if(this.barChartBarListData[i].size() > 0){
            
            BarChartBarData avgBarChartBarData = new BarChartBarData('avg', null, 0, null);
            
                if(barChartBarList != null){
                    
                    for(BarChartBarData barChartBarData : barChartBarList){
                        
                        avgBarChartBarData.value += barChartBarData.value;
                        
                    }
                    
                    avgBarChartBarData.value /= this.barChartBarListData[i].size();
                    
                    this.avg.add(avgBarChartBarData);
                    
                }
                
            }
            
            i++;
            
        }
        
    }
    
}