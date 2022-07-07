@RestResource(urlMapping='/brit/*')
global class BritResource {
    
    @HttpGet
    global static void doGet(){
        
        /*String yearMonth = RestContext.request.requestURI.substring(RestContext.request.requestURI.lastIndexOf('/')+1);
        String year = yearMonth.substring(0, 4);
        String month = yearMonth.substring(4, 6);*/
        
        String device = RestContext.request.headers.get('x-device-id');
        system.debug(device);
        
        CustomAuthentication ca = new CustomAuthentication(RestContext.request, RestContext.response);
        
        if(!ca.authenticate()){
            
            ca.getResponse().send();
        
            return;
            
        }
        
        CustomResponse res = new CustomResponse(RestContext.response);
        
        Dispositivo__c dis = [SELECT Utente__r.COD_CASA__c FROM Dispositivo__c WHERE Dispositivo__c = :device LIMIT 1];
        
        system.debug(dis.Utente__r.COD_CASA__c);
        
        List<String> codici = dis.Utente__r.COD_CASA__c.split(',');
        
        // recupero i brit dell'utente
        List<BRIT__c> brits = [SELECT id, Anno__c, Codice__c, CUSTOMER_CENTRICITY_Connected_Car__c, CUSTOMER_CENTRICITY_Customer_Retention__c, Distretto__c, Marchio__c, Mese__c, Nome_dealer__c, Gruppo__c,
                               PEOPLE_Digital_Customer_Advisor__c, PEOPLE_Employee_Engagement_Survey__c, PRECOND_ACCESSO_Perf_AS_more_95__c, PRECOND_ACCESSO_Perf_NPS_more_75__c, PRECOND_ACCESSO_Perf_Sales_more_95__c, 
                               PRECOND_ACCESSO_Perf_Veicoli_Comm__c, SOST_DEL_BUSINESS_Penetr_KINTO_ONE__c, SOST_DEL_BUSINESS_Penetrazione_TCM__c, SOST_DEL_BUSINESS_VCA__c, SOST_DEL_BUSINESS_We_Hybrid_Insurance__c,
                               TOYOTA_WAY_Gestione_Lead__c, TOYOTA_WAY_Qualita_dati_clienti__c, Zona__c FROM BRIT__c WHERE /*Anno__c = :year AND Mese__c = :month AND*/ Codice__c in :codici
                               ORDER BY Anno__c DESC, Mese__c DESC, Marchio__c DESC];
        
        Set<String> marchi = new Set<String>();
        Set<String> gruppi = new Set<String>();
        for(BRIT__c marchio : brits){
            marchi.add(marchio.Marchio__c);
            gruppi.add(marchio.Gruppo__c);
        }
        
        List<BRIT__c> benchmarks = [SELECT id, Anno__c, Codice__c, CUSTOMER_CENTRICITY_Connected_Car__c, CUSTOMER_CENTRICITY_Customer_Retention__c, Distretto__c, Marchio__c, Mese__c, Nome_dealer__c, Gruppo__c,
                               PEOPLE_Digital_Customer_Advisor__c, PEOPLE_Employee_Engagement_Survey__c, PRECOND_ACCESSO_Perf_AS_more_95__c, PRECOND_ACCESSO_Perf_NPS_more_75__c, PRECOND_ACCESSO_Perf_Sales_more_95__c, 
                               PRECOND_ACCESSO_Perf_Veicoli_Comm__c, SOST_DEL_BUSINESS_Penetr_KINTO_ONE__c, SOST_DEL_BUSINESS_Penetrazione_TCM__c, SOST_DEL_BUSINESS_VCA__c, SOST_DEL_BUSINESS_We_Hybrid_Insurance__c,
                               TOYOTA_WAY_Gestione_Lead__c, TOYOTA_WAY_Qualita_dati_clienti__c, Zona__c FROM BRIT__c WHERE Codice__c = '' and Gruppo__c in :gruppi
                               ORDER BY Anno__c DESC, Mese__c DESC, Marchio__c DESC];
        
        List<Gruppo__c> colors = [SELECT Name, Colore__c FROM Gruppo__c WHERE Name IN :marchi AND Tipologia__c = 'Marchio' ];
        Map<String, String> marchioColore = new Map<String, String>();
        for(Gruppo__c color : colors){
            if(!marchioColore.containsKey(color.Name))
            	marchioColore.put(color.Name, color.Colore__c);
        }
        
        List<Brit> returnList = new List<Brit>();
        for(BRIT__c brit : brits){
            returnList.add(new Brit(brit, marchioColore));
        }
        
        for(BRIT__c benchmark : benchmarks){
            returnList.add(new Brit(benchmark, marchioColore));
        }

        res.setStatusCode(200);
        res.setBody(returnList);
        
        res.send();
        
    }

}