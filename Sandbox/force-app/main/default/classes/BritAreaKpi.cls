public class BritAreaKpi {

    String area;
  	String color;
  	public List<BritKpi> kpis = new List<BritKpi>();

    /*public BritAreaKpi(BRiT_Aree_KPI__c areaKpi, List<BritKpi> kpi){
        
        this.area = areaKpi.Area_KPI__c;
        this.color = String.isNotBlank(areaKpi.Color__c) ? areaKpi.Color__c: '';
        this.kpis = kpi;
    }*/
    public BritAreaKpi(String area, String color, List<BritKpi> kpi){
        
        this.area = area;
        this.color = color;
        this.kpis = kpi;
    }
    
    public String getArea(){
        return area;
    }
}