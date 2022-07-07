public class BritResult {
    
    String id;
    Decimal year;
    String code;
    String district;
    String brand;
    String month;
    String dealerName;
    String area;
    String color;
    String britGroup;
    String info;
    public List<BritAreaKpi> results = new List<BritAreaKpi>();
    
    /*public BritResult(BRiT_Risultati__c brit, Map<String, String> colors, List<BritAreaKpi> britArea){
        
        Map<Decimal, String> meseAlpha = new Map<Decimal, String>();
        meseAlpha.put(1, 'Gennaio');
        meseAlpha.put(2, 'Febbraio');
        meseAlpha.put(3, 'Marzo');
        meseAlpha.put(4, 'Aprile');
        meseAlpha.put(5, 'Maggio');
        meseAlpha.put(6, 'Giugno');
        meseAlpha.put(7, 'Luglio');
        meseAlpha.put(8, 'Agosto');
        meseAlpha.put(9, 'Settembre');
        meseAlpha.put(10, 'Ottobre');
        meseAlpha.put(11, 'Novembre');
        meseAlpha.put(12, 'Dicembre');
 
        this.id = brit.Id;
        this.year = brit.Anno__c;
        this.code = String.isNotBlank(brit.Cod_Casa__c) ? brit.Cod_Casa__c: '';
        this.district = String.isNotBlank(brit.Distretto__c) ? brit.Distretto__c : '';
        this.brand = String.isNotBlank(brit.Marchio__c) ? brit.Marchio__c : '';
        this.month = meseAlpha.get(brit.Mese__c);
        this.area = String.isNotBlank(brit.Zona__c) ? brit.Zona__c : '';
        this.color = colors.containsKey(brit.Marchio__c) ? colors.get(brit.Marchio__c) : '';
        this.britGroup = String.isNotBlank(brit.Gruppo__c) ? brit.Gruppo__c : '';
		this.info = 'In questa sezione sono presentati i risultati di performance della sua concessionaria, per mese e marca, a confronto con la media del gruppo di riferimento in Rete (calcolato sulla base del potenziale di mercato).';
   		this.results = britArea;
        this.dealerName = String.isNotBlank(brit.Nome_Dealer__c) ? brit.Nome_Dealer__c : '';
    }*/
    
    public BritResult(Id id, Decimal anno, String codCasa, String distretto, String marchio, Decimal mese, String zona, String gruppo, String nomeDealer, Map<String, String> colors, List<BritAreaKpi> britArea){
        
        Map<Decimal, String> meseAlpha = new Map<Decimal, String>();
        meseAlpha.put(1, 'Gennaio');
        meseAlpha.put(2, 'Febbraio');
        meseAlpha.put(3, 'Marzo');
        meseAlpha.put(4, 'Aprile');
        meseAlpha.put(5, 'Maggio');
        meseAlpha.put(6, 'Giugno');
        meseAlpha.put(7, 'Luglio');
        meseAlpha.put(8, 'Agosto');
        meseAlpha.put(9, 'Settembre');
        meseAlpha.put(10, 'Ottobre');
        meseAlpha.put(11, 'Novembre');
        meseAlpha.put(12, 'Dicembre');
 
        this.id = id;
        this.year = anno;
        this.code = String.isNotBlank(codCasa) ? codCasa : '';
        this.district = String.isNotBlank(distretto) ? distretto : '';
        this.brand = String.isNotBlank(marchio) ? marchio : '';
        this.month = meseAlpha.get(mese);
        this.area = String.isNotBlank(zona) ? zona : '';
        this.dealerName = String.isNotBlank(nomeDealer) ? nomeDealer : '';
        this.color = colors.containsKey(marchio) ? colors.get(marchio) : '';
        this.britGroup = String.isNotBlank(gruppo) ? gruppo : '';
		this.info = 'In questa sezione sono presentati i risultati di performance della sua concessionaria, per mese e marca, a confronto con la media del gruppo di riferimento in Rete (calcolato sulla base del potenziale di mercato).';
   		this.results = britArea;
        
    }
    
}