public class Brit {
    
    public String id;
    public String year;
    public String code;
    public String customerCentricityConnectedCar;
    public String customerCentricityCustomerRetention;
    public String district;
    public String brand;
    public String month;
    public String dealerName;
    public String peopleDigitalCustomerAdvisor;
    public String peopleEmployeeEngagementSurvey;
    public String precondAccessoPerfAsMore95;
    public String precondAccessoPerfNpsMore75;
    public String precondAccessoPerfSalesMore95;
    public String precondAccessoPerfVeicoliComm;
    public String sostDelBusinessPenetrKintoOne;
    public String sostDelBusinessPenetrazioneTcm;
    public String sostDelBusinessVca;
    public String sostDelBusinessWeHybridInsurance;
    public String ToyotaWayGestioneLead;
    public String ToyotaWayQualitaDatiClienti;
    public String area;
    public String color;
    public String britGroup;
    public String info;
    
    public Brit(Brit__c brit, Map<String, String> colors){
        
        Map<String, String> meseAlpha = new Map<String, String>();
        meseAlpha.put('01', 'Gennaio');
        meseAlpha.put('02', 'Febbraio');
        meseAlpha.put('03', 'Marzo');
        meseAlpha.put('04', 'Aprile');
        meseAlpha.put('05', 'Maggio');
        meseAlpha.put('06', 'Giugno');
        meseAlpha.put('07', 'Luglio');
        meseAlpha.put('08', 'Agosto');
        meseAlpha.put('09', 'Settembre');
        meseAlpha.put('10', 'Ottobre');
        meseAlpha.put('11', 'Novembre');
        meseAlpha.put('12', 'Dicembre');
 
        this.id = brit.Id;
        this.year = String.isNotBlank(brit.Anno__c) ? brit.Anno__c : '';
        this.code = String.isNotBlank(brit.Codice__c) ? brit.Codice__c: '';
        this.customerCentricityConnectedCar = String.isNotBlank(String.valueOf(brit.CUSTOMER_CENTRICITY_Connected_Car__c)) ? String.valueOf(brit.CUSTOMER_CENTRICITY_Connected_Car__c) : '';
        this.customerCentricityCustomerRetention = String.isNotBlank(String.valueOf(brit.CUSTOMER_CENTRICITY_Customer_Retention__c)) ? String.valueOf(brit.CUSTOMER_CENTRICITY_Customer_Retention__c) : '';
        this.district = String.isNotBlank(brit.Distretto__c) ? brit.Distretto__c : '';
        this.brand = String.isNotBlank(brit.Marchio__c) ? brit.Marchio__c : '';
        this.month = String.isNotBlank(brit.Mese__c) ? meseAlpha.get(brit.Mese__c) : '';
        this.dealerName = String.isNotBlank(brit.Nome_dealer__c) ? brit.Nome_dealer__c : '';
        this.peopleDigitalCustomerAdvisor = String.isNotBlank(String.valueOf(brit.PEOPLE_Digital_Customer_Advisor__c)) ? String.valueOf(brit.PEOPLE_Digital_Customer_Advisor__c) : '';
        this.peopleEmployeeEngagementSurvey = String.isNotBlank(String.valueOf(brit.PEOPLE_Employee_Engagement_Survey__c)) ? String.valueOf(brit.PEOPLE_Employee_Engagement_Survey__c) : '';
        this.precondAccessoPerfAsMore95 = String.isNotBlank(String.valueOf(brit.PRECOND_ACCESSO_Perf_AS_more_95__c)) ? String.valueOf(brit.PRECOND_ACCESSO_Perf_AS_more_95__c) : '';
        this.precondAccessoPerfNpsMore75 = String.isNotBlank(String.valueOf(brit.PRECOND_ACCESSO_Perf_NPS_more_75__c)) ? String.valueOf(brit.PRECOND_ACCESSO_Perf_NPS_more_75__c) : '';
        this.precondAccessoPerfSalesMore95 = String.isNotBlank(String.valueOf(brit.PRECOND_ACCESSO_Perf_Sales_more_95__c)) ? String.valueOf(brit.PRECOND_ACCESSO_Perf_Sales_more_95__c) : '';
        this.precondAccessoPerfVeicoliComm = String.isNotBlank(String.valueOf(brit.PRECOND_ACCESSO_Perf_Veicoli_Comm__c)) ? String.valueOf(brit.PRECOND_ACCESSO_Perf_Veicoli_Comm__c) : '';
        this.sostDelBusinessPenetrKintoOne = String.isNotBlank(String.valueOf(brit.SOST_DEL_BUSINESS_Penetr_KINTO_ONE__c)) ? String.valueOf(brit.SOST_DEL_BUSINESS_Penetr_KINTO_ONE__c) : '';
        this.sostDelBusinessPenetrazioneTcm = String.isNotBlank(String.valueOf(brit.SOST_DEL_BUSINESS_Penetrazione_TCM__c)) ? String.valueOf(brit.SOST_DEL_BUSINESS_Penetrazione_TCM__c) : '';
        this.sostDelBusinessVca = String.isNotBlank(String.valueOf(brit.SOST_DEL_BUSINESS_VCA__c)) ? String.valueOf(brit.SOST_DEL_BUSINESS_VCA__c) : '';
        this.sostDelBusinessWeHybridInsurance = String.isNotBlank(String.valueOf(brit.SOST_DEL_BUSINESS_We_Hybrid_Insurance__c)) ? String.valueOf(brit.SOST_DEL_BUSINESS_We_Hybrid_Insurance__c) : '';
        this.ToyotaWayGestioneLead = String.isNotBlank(String.valueOf(brit.TOYOTA_WAY_Gestione_Lead__c)) ? String.valueOf(brit.TOYOTA_WAY_Gestione_Lead__c) : '';
        this.ToyotaWayQualitaDatiClienti = String.isNotBlank(String.valueOf(brit.TOYOTA_WAY_Qualita_dati_clienti__c)) ? String.valueOf(brit.TOYOTA_WAY_Qualita_dati_clienti__c) : '';
        this.area = String.isNotBlank(brit.Zona__c) ? brit.Zona__c : '';
        this.color = colors.containsKey(brit.Marchio__c) ? colors.get(brit.Marchio__c) : '';
        this.britGroup = String.isNotBlank(brit.Gruppo__c) ? brit.Gruppo__c : '';
		this.info = 'In questa sezione sono presentati i risultati di performance della sua concessionaria, per mese e marca, a confronto con la media del gruppo di riferimento in Rete (calcolato sulla base del potenziale di mercato).';

    }
    
}