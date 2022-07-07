public class BritKpi {

    String kpi;
    String value;
    String benchmark;
    Decimal CondizioneMaggioreDi;

    /*public BritKpi(BRiT_KPI__c kpi, Decimal valueKpi, Decimal benchmarkKpi){
        
        this.kpi = kpi.KPI__c;
        this.value = (valueKpi != null) ? String.valueOf(valueKpi) : null;
        this.benchmark = (benchmarkKpi != null) ? String.valueOf(benchmarkKpi) : null;
        this.CondizioneMaggioreDi = (kpi.CondizioneMaggioreDi__c != null) ? kpi.CondizioneMaggioreDi__c : null;
        
    }*/
    
    public BritKpi(String kpi, Decimal condizione,  Decimal valueKpi, Decimal benchmarkKpi){
        
        this.kpi = kpi;
        this.value = (valueKpi != null) ? String.valueOf(valueKpi) : null;
        this.benchmark = (benchmarkKpi != null) ? String.valueOf(benchmarkKpi) : null;
        this.CondizioneMaggioreDi = condizione;
        
    }
    
}