@RestResource(urlMapping='/manager_suggestions/*')
global class ManagerSuggestionsResource {
    
    @HttpGet
    global static void doGet(){
        
        CustomAuthentication ca = new CustomAuthentication(RestContext.request, RestContext.response);
        
        if(!ca.authenticate()){
            
            ca.getResponse().send();
            
            return;
            
        }
        
        CustomResponse res = new CustomResponse(RestContext.response);
        
        Utente__c u = ca.getUser();
        Id userId = u.Utente_Master__c != null ? u.Utente_Master__c : u.Id;
        List<String> userPermissions = u.Azienda_Permessi_Visualizzazione__c != null ? u.Azienda_Permessi_Visualizzazione__c.split(';') : new List<String>();
        
        String brandId = RestContext.request.params.get('brandId');
        String zonesIds = RestContext.request.params.get('zonesIds');
        String sentimentsString = RestContext.request.params.get('sentiments');
        
        /*Gruppo__c g = [SELECT Id, Gruppo_Master__c FROM Gruppo__c WHERE Id = :brandId LIMIT 1];
        
        if(g.Gruppo_Master__c != null){
            brandId = g.Gruppo_Master__c;
        }*/
        
        Gruppo__c brand = [SELECT Id, Genitore__c, Name, Tipologia__c, Sigla__c, Ordine__c, Url_Logo__c, Colore__c, Gruppo_Master__c
                           FROM Gruppo__c WHERE Id = :brandId];
        
        List<Object> suggestions = new List<Object>();
        
        //List<Gruppo__c> allGroups = UserResource.getAllGroups();
        //List<Gruppo__c> userGroups = UserResource.getUserGroups(u.Id);
        List<Gruppo__c> childGroups = UserResource.getUserGroupChildren(u.Id);
        childGroups = UserResource.filterGroupsByBrandId(childGroups, brandId);
        
        if(String.isNotBlank(zonesIds)){
            
            childGroups = UserResource.getGroupsByIds(zonesIds.split(','));
            
        }
        
        List<String> sentiments = String.isNotBlank(sentimentsString) ? sentimentsString.split(',') : new List<String>();
        List<Integer> sentimentsInt = new List<Integer>();
        
        for(String s: sentiments){
            sentimentsInt.add(Integer.valueOf(s));
        }
        
        suggestions.addAll(getSuggestions(brand, childGroups, sentimentsInt, userPermissions));
        
        res.setStatusCode(200);
        res.setBody(suggestions);
        
        res.send();
        
    }
    
    public static List<Object> getSuggestions(Gruppo__c brand, List<Gruppo__c> childGroups, List<Integer> sentiments, List<String> userPermissions){
                
        Set<Id> childGroupsIds = new Set<Id>();
        
        for(Gruppo__c cg : childGroups){
            childGroupsIds.add(cg.Id);
        }
        
        List<Utente_Gruppo__c> usersGroups = [SELECT Id, Utente__c, Gruppo__r.Name, Name FROM Utente_Gruppo__c 
                                              WHERE Gruppo__r.Genitore__r.Genitore__c = :brand.Id 
                                              AND Utente__r.Non_Considerare_Analisi__c = false AND Utente__r.Tipologia__c = 'Dealer'
                                              AND Gruppo__c IN :childGroupsIds];
        
        Set<Id> usersToAnalyze = new Set<Id>();
        
        for(Utente_Gruppo__c ug : usersGroups){
            
            usersToAnalyze.add(ug.Utente__c);
            
        }
        
        Set<Integer> values = new Set<Integer>();
        
        if(sentiments.size() <= 0){
            values.add(1);
            values.add(2);
            values.add(3);
            values.add(4);
            values.add(5);
        }
        
        if(sentiments.contains(-1)){
            values.add(1);
            values.add(2);
        }
        
        if(sentiments.contains(0)){
            values.add(3);
        }
        
        if(sentiments.contains(1)){
            values.add(4);
            values.add(5);
        }
        
        List<Risposta_questionario__c> answers = [SELECT Name, Utente__c, Valore_Numerico__c, Valore_Testuale__c, Valore_Testuale_Lungo__c, Domanda_questionario__r.Raggruppamento__c,
                                                  Domanda_questionario__r.Raggruppamento__r.Genitore__c, Domanda_questionario__r.Raggruppamento__r.Gruppo__r.Name,
                                                  Domanda_questionario__r.Raggruppamento__r.Peso_Genitore__c, Domanda_questionario__r.Data_Ora_Inizio__c,
                                                  Valore_Numerico_Per_Peso_Raggruppamento__c, Domanda_questionario__r.Data_Ora_Fine__c, Utente__r.Non_Considerare_Analisi__c,
                                                  Domanda_questionario__r.Data_Ora_Inizio_Analisi__c, Domanda_questionario__r.Data_Ora_Fine_Analisi__c, Data_Ora_Risposta__c,
                                                  Utente__r.Ragione_Sociale__c, Domanda_questionario__r.Raggruppamento__r.Gruppo__c, Domanda_questionario__r.Raggruppamento__r.Name,
                                                  Domanda_questionario__r.Domanda_IT__c, Domanda_questionario__r.Raggruppamento__r.Etichetta_IT__c,
                                                  Domanda_questionario__r.Raggruppamento__r.Gruppo__r.Genitore__c, Domanda_questionario__r.Raggruppamento__r.Gruppo__r.Tipologia__c,
                                                  Utente__r.Name, Utente__r.Nome__c, Utente__r.Cognome__c, Domanda_questionario__r.Raggruppamento__r.Gruppo__r.Colore__c
                                                  FROM Risposta_questionario__c
                                                  WHERE Utente__c = :usersToAnalyze AND Valore_Numerico__c = :values
                                                  AND (Valore_Numerico__c != null OR Valore_Testuale__c != null)
                                                  AND Data_Ora_Risposta__c >= :System.now().addMonths(-6) AND Data_Ora_Risposta__c <= :System.now()
                                                  AND (Domanda_questionario__r.Raggruppamento__r.Gruppo__r.Tipologia__c = 'Casa Auto'
                                                       OR Domanda_questionario__r.Raggruppamento__r.Gruppo__c = :brand.Id
                                                       OR Domanda_questionario__r.Raggruppamento__r.Gruppo__c = :brand.Gruppo_Master__c)
                                                  AND Domanda_questionario__r.Raggruppamento__r.Azienda_Permessi_Visualizzazione__c IN :userPermissions
                                                  ORDER BY Domanda_questionario__r.Data_Ora_Inizio__c DESC, Data_Ora_Risposta__c DESC];
        
        List<SuggestionGrouping> suggestionGrouping = new List<SuggestionGrouping>();

        for(Risposta_questionario__c a : answers){
            
            if(String.isNotBlank(a.Valore_Testuale_Lungo__c) && a.Valore_Testuale_Lungo__c.length() > 3){
            
                SuggestionGrouping sg;
                
                for(SuggestionGrouping s : suggestionGrouping){
                    if(s.id == a.Domanda_questionario__r.Raggruppamento__c){
                        sg = s;
                    }
                }
                
                if(sg == null){
                    
                    sg = new SuggestionGrouping(a.Domanda_questionario__r.Raggruppamento__c, a.Domanda_questionario__r.Raggruppamento__r.Etichetta_IT__c);
                    sg.color = a.Domanda_questionario__r.Raggruppamento__r.Gruppo__r.Colore__c;
                    suggestionGrouping.add(sg);
                    
                }
                
                SuggestionQuestion sq;
                
                for(SuggestionQuestion s : sg.questions){
                    if(s.id == a.Domanda_questionario__c){
                        sq = s;
                    }
                }
                
                if(sq == null){
                    
                    Long questionStartDateTime = a.Domanda_questionario__r.Data_Ora_Inizio__c != null ? a.Domanda_questionario__r.Data_Ora_Inizio__c.getTime() : null;
                    Long questionEndDateTime = a.Domanda_questionario__r.Data_Ora_Fine__c != null ? a.Domanda_questionario__r.Data_Ora_Fine__c.getTime() : null;
                    
                    sq = new SuggestionQuestion(a.Domanda_questionario__c, a.Domanda_questionario__r.Domanda_IT__c, questionStartDateTime, questionEndDateTime);
                    sg.questions.add(sq);
                    
                }
                
                SuggestionAnswer sa = new SuggestionAnswer(a.Id, a.Valore_Testuale_Lungo__c, a.Valore_Numerico__c, a.Data_Ora_Risposta__c.getTime());
                
                for(Utente_Gruppo__c ug : usersGroups){
            
                    if(ug.Utente__c == a.Utente__c){
                        
                        sa.label = '<strong>' + a.Utente__r.Nome__c + ' ' + a.Utente__r.Cognome__c + '</strong> - [' + ug.Gruppo__r.Name + ']<br/>' + sa.label;
                        
                    }
                    
                }
                
                sq.answers.add(sa);
                sg.positive += sa.value > 3 ? 1 : 0;
                sg.negative += sa.value < 3 ? 1 : 0;
                sg.neutral += sa.value == 3 ? 1 : 0;
                
            }
        }
        
        String info = 'Le <b>suggestion</b> sono indicazioni fornite dai Concessionari, espresse rilasciando un <b>commento ai quesiti</b> sottoposti.<br/><br/>';
        info += 'Per ciascun ambito si riportano in evidenza il numero di commenti <b>positivi</b> (verde), <b>neutrali</b> (giallo) o <b>negativi</b> (rosso) rilasciati nei periodi di rilevazione considerati.<br/><br/>';
        info += 'L\'ordine delle tematiche e dei commenti seguono la logica del più recente.<br/><br/>';
        info += 'Gli ambiti identificati con color coding \'grigio\' rappresentano aree comuni ai marchi Toyota e Lexus, per le quali è stato rilevato un unico quesito non diversificato per marchio.';
        
        for(SuggestionGrouping sg : suggestionGrouping){
            sg.info = info;
        }
        
        return suggestionGrouping;
        
    }
    
    class SuggestionGrouping{
        
        public String id;
        public String label;
        public String info;
        public String color;
        public Integer positive = 0;
        public Integer negative = 0;
        public Integer neutral = 0;
        public List<SuggestionQuestion> questions = new List<SuggestionQuestion>();
        
        SuggestionGrouping(String id, String label){
			this.id = id;
			this.label = label;       
        }
        
    }
    
    class SuggestionQuestion{
        
        public String id;
        public String label;
        public Long startTimestamp;
        public Long endTimestamp;
        public List<SuggestionAnswer> answers = new List<SuggestionAnswer>();
        
        SuggestionQuestion(String id, String label, Long startTimestamp, Long endTimestamp){
			this.id = id;
			this.label = label;     
			this.startTimestamp = startTimestamp;
			this.endTimestamp = endTimestamp;
        }
        
    }
    
    class SuggestionAnswer{
        
        public String id;
        public String label;
        public Decimal value;
        public Long timestamp;
        
        SuggestionAnswer(String id, String label, Decimal value, Long timestamp){
			this.id = id;
			this.label = label;
			this.value = value;
			this.timestamp = timestamp;            
        }
        
    }

}