@RestResource(urlMapping='/britresult/*')
global class BritResultResource {
    
    @HttpGet
    global static void doGet(){
        
        String device = RestContext.request.headers.get('x-device-id');
        system.debug(device);
        
        CustomAuthentication ca = new CustomAuthentication(RestContext.request, RestContext.response);
        
        if(!ca.authenticate()){
            
            ca.getResponse().send();
        
            return;
            
        }
        
        if(ca != null && ca.getUser() != null && !ca.isStealth()) {
			insert new Accesso__c(Utente__c = ca.getUser().Id, Tipologia__c = 'Brit');
		}
        
        CustomResponse res = new CustomResponse(RestContext.response);
        
        Utente__c u = ca.getUser();
        List<String> codici = u.COD_CASA__c.split(',');

        // recupero i KPI da visualizzare
        List<BRiT_Visualizzazioni__c> visualizzati = [SELECT Cod_KPI__c, Mese__c, Anno__c, Marchio__c FROM BRiT_Visualizzazioni__c];
        system.debug(visualizzati);
        
        Map<String, String> daVisualizzare = new Map<String,String>();
        for(BRiT_Visualizzazioni__c visualizzato : visualizzati){
            String chiaveVis = visualizzato.Anno__c + visualizzato.Mese__c + visualizzato.Marchio__c + visualizzato.Cod_KPI__c;
            daVisualizzare.put(chiaveVis,chiaveVis);
        }
        
        // struttura di appoggio Map<keyConcatenato, BritResult> --> keyConcatenato = brit1.Anno__c+brit1.Mese__c+brit1.Cod_Casa__c+brit1.Marchio__c
        // struttura di appoggio Map<keyArea, String> --> keyConcatenato+keyArea
        // sttuttura di appoggio Map<keyBrit, String> --> keyConcatenato+keyArea+keyBrit
        
        // for BRiT_Risultati__c
        // 	controllo se esiste un valore per Map<keyConcatenato>
        // 		se esiste prendo il BritResult dalla map
        // 		se non esiste creo un nuovo Map<keyConcatenato, BritResult>
        // 		hai il BritResult
        // 			controllo se nella mappa BritAreaKpi di questo BritResult c'è già la chiave corrente Map<keyArea>
        // 				se si prendo Map<keyArea>
        // 				ma se no creo nuovo campo Map<keyArea, new BritAreaKpi ...
        // 					controllo se nella mappa BritKpi esiste già un Map<keyBrit>
        // 						se si prendo Map<keyBrit>
        // 						se no creo Map<keyBrit, new BritKpi
        
        List<BRiT_Risultati__c> brits = [SELECT id, Anno__c, Benchmark__c, Cod_Casa__c, Cod_KPI__c, Cod_KPI__r.id, Cod_KPI__r.Name, Cod_KPI__r.Ordine__c, Cod_KPI__r.KPI__c,
                                         Cod_KPI__r.Cod_Area_KPI__c, Cod_KPI__r.CondizioneMaggioreDi__c, Cod_KPI__r.Cod_Area_KPI__r.Color__c, Cod_KPI__r.Cod_Area_KPI__r.Ordine__c, Cod_KPI__r.Cod_Area_KPI__r.Area_KPI__c,
                                         Distretto__c, Gruppo__c, Marchio__c, Mese__c, Nome_Dealer__c, Non_visualizzare__c, 
                                         Value__c, Zona__c FROM BRiT_Risultati__c WHERE Cod_Casa__c in :codici AND Non_visualizzare__c = false
                                         ORDER BY /*Cod_Casa__c DESC, */Marchio__c DESC, Anno__c DESC, Mese__c DESC, Cod_KPI__r.Cod_Area_KPI__r.Ordine__c ASC, Cod_KPI__r.Ordine__c ASC];
        
        // recupero i colori
        Set<String> marchi = new Set<String>();
        Set<String> gruppi = new Set<String>();
        for(BRiT_Risultati__c marchio : brits){
            marchi.add(marchio.Marchio__c);
            gruppi.add(marchio.Gruppo__c);
        }
        List<Gruppo__c> colors = [SELECT Name, Colore__c FROM Gruppo__c WHERE Name IN :marchi AND Tipologia__c = 'Marchio' ];
        Map<String, String> marchioColore = new Map<String, String>();
        for(Gruppo__c color : colors){
            if(!marchioColore.containsKey(color.Name))
            	marchioColore.put(color.Name, color.Colore__c);
        }
        
        
        Map<String, BritResult> britresults = new Map<String, BritResult>();
        Map<String, String> areas = new Map<String, String>();
        Map<String, String> kpis = new Map<String, String>();
        
        for(BRiT_Risultati__c brit : brits){
            
            String chiavebrit = brit.Anno__c + brit.Mese__c + brit.Cod_Casa__c + brit.Marchio__c;
            String chiavearea = brit.Anno__c + brit.Mese__c + brit.Cod_Casa__c + brit.Marchio__c + brit.Cod_KPI__r.Cod_Area_KPI__c;
            String chiavekpi = brit.Anno__c + brit.Mese__c + brit.Cod_Casa__c + brit.Marchio__c + brit.Cod_KPI__r.Cod_Area_KPI__c + brit.Cod_KPI__c;
            String chiaveDaVisualizzare = brit.Anno__c + brit.Mese__c + brit.Marchio__c + brit.Cod_KPI__c;
            
            if(daVisualizzare.get(chiaveDaVisualizzare) != null) {
                // le kpi sono sempre nuove
                BritKpi kpi = new BritKpi(brit.Cod_KPI__r.KPI__c, brit.Cod_KPI__r.CondizioneMaggioreDi__c, brit.Value__c, brit.Benchmark__c);
                kpis.put(chiavekpi, brit.Cod_KPI__r.KPI__c);       
                
                if(areas.get(chiavearea) == null){
                    // non ho ancora creato l'area, quindi la creo
                    List<BritKpi> kpiList = new List<BritKpi>();
                    kpiList.add(kpi);
                    BritAreaKpi areakpi = new BritAreaKpi(brit.Cod_KPI__r.Cod_Area_KPI__r.Area_KPI__c, brit.Cod_KPI__r.Cod_Area_KPI__r.Color__c, kpiList);
                    
                    // controllo se il britresult esiste già
                    if(britresults.get(chiavebrit) == null){
                        //creo il nuovo britresult e ci butto sentro l'area
                        BritResult br = new BritResult(brit.id, brit.Anno__c, brit.Cod_Casa__c, brit.Distretto__c, brit.Marchio__c, brit.Mese__c, brit.Zona__c, brit.Gruppo__c, brit.Nome_Dealer__c, marchioColore, new List<BritAreaKpi>());
                        br.results.add(areakpi);
                        areas.put(chiavearea, brit.Cod_KPI__r.Cod_Area_KPI__c); 
                        britresults.put(chiavebrit, br);
                        
                    } else {
                        // aggiungo l'area a un britresult esistente
                        BritResult br = britresults.get(chiavebrit);
                        br.results.add(areakpi);
                        areas.put(chiavearea, brit.Cod_KPI__r.Cod_Area_KPI__c); 
                    }
                    
                } else {
                    // l'area esiste già, devo trovare quella giusta e andare a inserirci il nuovo kpi
                    BritResult britResultEsistente = britresults.get(chiavebrit);
                    List<BritAreaKpi> britAreaList = britResultEsistente.results;
                    for(BritAreaKpi bak : britAreaList){
                        if(bak.getArea() == brit.Cod_KPI__r.Cod_Area_KPI__r.Area_KPI__c){
                            bak.kpis.add(kpi);    
                        }
                    }    
                }
            }
        }
        

        // costruisco la lista dei risultati
        List<BritResult> returnList = new List<BritResult>();
        for (String key : britresults.keySet()) {
            returnList.add(britresults.get(key));
        }
        


        res.setStatusCode(200);
        res.setBody(returnList);
        
        res.send();
        
    }

}