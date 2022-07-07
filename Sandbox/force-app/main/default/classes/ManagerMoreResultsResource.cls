@RestResource(urlMapping='/manager_more_results/*')
global class ManagerMoreResultsResource {
    
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
        
        Gruppo__c brand = getBrandById(brandId);
        
        /*Gruppo__c g = [SELECT Id, Gruppo_Master__c FROM Gruppo__c WHERE Id = :brandId LIMIT 1];
        
        if(g.Gruppo_Master__c != null){
            brandId = g.Gruppo_Master__c;
        }*/
        
        List<Object> charts = new List<Object>();
        
        List<Gruppo__c> childGroups = UserResource.getUserGroupChildren(u.Id);
        childGroups = UserResource.filterGroupsByBrandId(childGroups, brandId);
        
        if(String.isNotBlank(zonesIds)){
            
            childGroups = UserResource.getGroupsByIds(zonesIds.split(','));
            
        }
        
        List<Object> moreResults = getDealerMoreResults2(brand, childGroups, userPermissions);
        
        if(moreResults != null && moreResults.size() > 0){
            
            charts.addAll(moreResults);
            
        }
        
        res.setStatusCode(200);
        res.setBody(charts);
        
        res.send();
        
    }
    
    public static List<Object> getDealerMoreResults2(Gruppo__c brand, List<Gruppo__c> childGroups, List<String> userPermissions){
        
        List<Object> charts = new List<Object>();
        String chartTitle = 'More Results';
        DateTime currentDateTime = System.now();
        
        //Integer dealerCount = dealerCountByBrandId(brandId);
        Set<Id> dealers = getDealersByGroups(childGroups);
        Integer dealerCount = dealers.size();
        List<Raggruppamento__c> groupings = getGroupingsByBrand(brand, userPermissions);
        List<Domanda_questionario__c> questions = getQuestionsByGroupingsWithRange(groupings, System.now().addMonths(-6), System.now());
        List<Risposta_questionario__c> answers = getAnswersByQuestionsAndUserIds(questions, dealers);
        Map<Id, List<Opzione_Domanda__c>> questionsOptionsSetsByQuestionId = getQuestionsOptionsSetsByQuestions(questions);
        
        Map<String, Gruppo__c> brandsById = new Map<String, Gruppo__c>();
        
        Set<Id> allBrandsIds = new Set<Id>();
        
        Map<String, Map<String, List<Object>>> answersByGroupingIdAndQuestionId = new Map<String, Map<String, List<Object>>>();
        
        for(Risposta_questionario__c a : answers){
            
            Set<String> brandsIds = new Set<String>();
            String groupingId = a.Domanda_questionario__r.Raggruppamento__c;
            String questionId = a.Domanda_questionario__c;
            String groupingLabel = a.Domanda_questionario__r.Raggruppamento__r.Etichetta_IT__c;
            String questionLabel = a.Domanda_questionario__r.Domanda_IT__c;
            Decimal value = a.Valore_Numerico__c;
            String textValue = a.Valore_Testuale__c;
            Datetime startDate = a.Domanda_questionario__r.Data_Ora_Inizio__c;
            Datetime endDate = a.Domanda_questionario__r.Data_Ora_Fine__c;
            Datetime startAnalysisDate = a.Domanda_questionario__r.Data_Ora_Inizio_Analisi__c;
            Datetime endAnalysisDate = a.Domanda_questionario__r.Data_Ora_Fine_Analisi__c;
            String answerUserId = a.Utente__c;
            Boolean toConsider = !a.Utente__r.Non_Considerare_Analisi__c;
            
            if(!answersByGroupingIdAndQuestionId.containsKey(groupingId)){
                
                answersByGroupingIdAndQuestionId.put(groupingId, new Map<String, List<Object>>());
                
            }
            
            Map<String, List<Object>> byGrouping = answersByGroupingIdAndQuestionId.get(groupingId);              
            
            if(!byGrouping.containsKey(questionId)){
                
                byGrouping.put(questionId, new List<Object>());
                
            }
            
            List<Object> byQuestionId = byGrouping.get(questionId);
            
            byQuestionId.add(new Map<String, Object>{
                'groupingLabel' => groupingLabel,
                    'questionLabel' => questionLabel,
                    'value' => value,
                    'textValue' => textValue,
                    'startDate' => startDate,
                    'endDate' => endDate,
                    'startAnalysisDate' => startAnalysisDate,
                    'endAnalysisDate' => endAnalysisDate,
                    'answerUserId' => answerUserId,
                    'toConsider' => toConsider
                    });
            
        }
        
        String brandName = brand.Name;
        String brandColor = brand.Colore__c;
        
        for(String groupingId : answersByGroupingIdAndQuestionId.keySet()){
            
            Map<String, List<Object>> answersByQuestionId = answersByGroupingIdAndQuestionId.get(groupingId);
            Map<String, List<Object>> lastQuestionAnswers = new Map<String, List<Object>>();
            
            for(String questionId : answersByQuestionId.keySet()){
                
                List<Object> allAnswers = answersByQuestionId.get(questionId);
                Map<String, Decimal> options = new Map<String, Decimal>();
                
                Decimal minimumSampleSize = 0.1;
                
                if(brand != null && brand.Campione_Minimo_Percentuale__c != null){
                    
                    minimumSampleSize = brand.Campione_Minimo_Percentuale__c / 100.0;
                    
                }
                
                if(allAnswers.size() > dealerCount * minimumSampleSize && !lastQuestionAnswers.containsKey(questionId)){
                    
                    lastQuestionAnswers.put(questionId, allAnswers);
                    
                }
                
            }
            
            for(String questionId : lastQuestionAnswers.keySet()){
                
                String label = '';
                Datetime startDate = null;
                Datetime endDate = null;
                Map<String, Map<String, Decimal>> options = new Map<String,  Map<String, Decimal>>();
                Decimal total = 0;
                
                List<BarChartBarData> barChartBarDataList = new List<BarChartBarData>();
                
                List<Object> allAnswers = lastQuestionAnswers.get(questionId);
                
                for(Opzione_Domanda__c od : questionsOptionsSetsByQuestionId.get(questionId)){
                    
                    options.put(od.Etichetta_Risultati_IT__c, new Map<String, Decimal>{'sum' => 0, 'total' => 0});
                    Map<String, Decimal> option = options.get(od.Etichetta_Risultati_IT__c);
                    
                    for(Object o : allAnswers){
                        
                        Map<String, Object> m = (Map<String, Object>) o;
                        
                        Decimal value = (Decimal) m.get('value');
                        label = (String) m.get('questionLabel');
                        startDate = (Datetime) m.get('startDate');
                        endDate = (Datetime) m.get('endDate');
                        Boolean toConsider = (Boolean) m.get('toConsider');
                        
                        if(toConsider){
                            
                            if(od.Valore_Numerico__c == value){
                                
                                option.put('sum', option.get('sum') + 1);
                                total++;
                                
                            }
                            
                            option.put('total', option.get('total') + 1);
                            
                        }
                        
                    }
                    
                }
                
                String subLabel = '';
                Boolean running = false;
                
                if(endDate != null){
                    
                    subLabel = 'Ultimo aggiornamento: ' + RCCUtils.dateFormat(Date.valueOf(endDate));
                    
                    if(endDate >= System.now()){
                        
                        running = true;
                        
                    }
                    
                }
                
                BarChartData chart = new BarChartData(label, subLabel, brandName);
                chart.color = brandColor;
                
                chart.info = 'Per alcuni quesiti selezionati in questa sezione si presenta la <b>distribuzione di frequenza</b> dei risultati raccolti.<br/><br/>';
                chart.info += 'La data si riferisce al giorno di pubblicazione del quesito.<br/><br/>';
                chart.info += 'Se ancora attivo, si è invitati a rispondere per poter consultare i risultati aggiornati in tempo reale.';
                
                Decimal sample = (total / dealerCount * 100);
                
                chart.post = String.format('Campione {0}%', new List<String>{ String.valueOf(sample.setScale(0)) });
                
                if(running){
                    
                    chart.post += ' (Rilevazione in corso)';
                    
                }
                
                for(String k : options.keySet()){
                    
                    Map<String, Decimal> option = options.get(k);
                    Double percent = Double.valueOf(option.get('sum') / option.get('total')) * 100;
                    
                    BarChartBarData barChartBarData = new BarChartBarData(k, null, percent, '#CC0033');
                    
                    barChartBarDataList.add(barChartBarData);
                    
                }
                
                if(barChartBarDataList.size() > 0){
                    
                    chart.addBarChartBarListData(barChartBarDataList);
                    
                    charts.add(chart);
                    
                }
                
            }
            
        }
        
        return charts;
        
    }
    
    private static Gruppo__c getBrandById(Id brandId){
        
        return [SELECT Id, Name, Genitore__c, Tipologia__c, Ordine__c, Campione_Minimo_Percentuale__c, Colore__c, Gruppo_Master__c, Gruppo_Master__r.Genitore__c
                FROM Gruppo__c 
                WHERE Id = :brandId AND Tipologia__c = 'Marchio' ORDER BY Ordine__c ASC LIMIT 1];
        
    }
    
    private static List<Raggruppamento__c> getGroupingsByBrand(Gruppo__c brand, List<String> userPermissions){
        
        Set<Id> ids = new Set<Id>();
        
        ids.add(brand.Id);
        ids.add(brand.Genitore__c);
        ids.add(brand.Gruppo_Master__r.Genitore__c);
        ids.add(brand.Gruppo_Master__c);
        
        return [SELECT Id, Name
                FROM Raggruppamento__c 
                WHERE Gruppo__c IN :ids AND Visualizzabile_Da_Manager_In__c = 'More Results' AND Azienda_Permessi_Visualizzazione__c IN :userPermissions];
        
    }
    
    private static List<Domanda_questionario__c> getQuestionsByGroupingsWithRange(List<Raggruppamento__c> groupings, Datetime fromDateTime, Datetime toDateTime){
        
        return [SELECT Id, Data_Ora_Inizio__c, Data_Ora_Inizio_Analisi__c, Raggruppamento__c, Raggruppamento__r.Gruppo__c, Data_Ora_Fine_Analisi__c,
                Insieme_Opzioni_Domanda__c
                FROM Domanda_questionario__c 
                WHERE Raggruppamento__c IN :groupings AND Data_Ora_Inizio__c >= :fromDateTime AND Data_Ora_Inizio__c <= :toDateTime
                ORDER BY Data_Ora_Inizio__c DESC];
        
    }
    
    private static Integer dealerCountByBrandId(Gruppo__c brand){
        
        return [SELECT COUNT()
                FROM Utente_Gruppo__c 
                WHERE Utente__r.Tipologia__c = 'Dealer' AND Utente__r.Non_Considerare_Analisi__c = :false
                AND (Gruppo__r.Genitore__r.Genitore__c = :brand.Id OR Gruppo__r.Genitore__r.Genitore__c = :brand.Gruppo_Master__c)];
        
    }
    
    private static Set<Id> getDealersByGroups(List<Gruppo__c> groups){
        
        Set<Id> result = new Set<Id>();
        
        List<Utente_Gruppo__c> usersGroups = [SELECT Id, Utente__c, Gruppo__r.Genitore__r.Genitore__c
                                              FROM Utente_Gruppo__c 
                                              WHERE Utente__r.Tipologia__c = 'Dealer' AND Utente__r.Non_Considerare_Analisi__c = :false
                                              AND Gruppo__c IN :groups];
        
        // Totale rispondenti per marchio
        for(Utente_Gruppo__c userGroup : usersGroups){
            
            result.add(userGroup.Utente__c);
            
        }
        
        return result;
        
    }
    
    private static List<Risposta_Questionario__c> getAnswersByQuestionsAndUserIds(List<Domanda_questionario__c> questions, Set<Id> userIds){
        
        return [SELECT Utente__c, Domanda_Questionario__r.Raggruppamento__c, Domanda_Questionario__r.Data_Ora_Inizio__c,
                Domanda_Questionario__r.Data_Ora_Fine__c, Domanda_questionario__r.Raggruppamento__r.Etichetta_IT__c,
                Domanda_questionario__r.Raggruppamento__r.Gruppo__r.Name, Valore_Numerico__c, Valore_Testuale__c,
                Domanda_questionario__r.Raggruppamento__r.Gruppo__c, Domanda_questionario__r.Frequenza__c,
                Domanda_questionario__r.Domanda_IT__c, Domanda_Questionario__c, Utente__r.Non_Considerare_Analisi__c,
                Domanda_Questionario__r.Data_Ora_Inizio_Analisi__c, Domanda_Questionario__r.Data_Ora_Fine_Analisi__c,
                Domanda_Questionario__r.Name
                FROM Risposta_questionario__c
                WHERE Domanda_questionario__c IN :questions AND (Risposta_questionario__c.Valore_Numerico__c != null OR Risposta_questionario__c.Valore_Testuale__c != null )
                AND Utente__c IN :userIds
                ORDER BY Domanda_questionario__r.Raggruppamento__r.Gruppo__r.Ordine__c ASC, Domanda_Questionario__r.Data_Ora_Inizio__c DESC];
        
    }
    
    private static Map<Id, List<Opzione_Domanda__c>> getQuestionsOptionsSetsByQuestions(List<Domanda_questionario__c> questions){
        
        Map<Id, List<Opzione_Domanda__c>> results = new Map<Id, List<Opzione_Domanda__c>>();
        Set<Id> questionsOptionSetIds = new Set<Id>();
        
        for(Domanda_questionario__c q : questions){
            
            questionsOptionSetIds.add(q.Insieme_Opzioni_Domanda__c);
            
        }
        
        List<Insieme_Opzioni_Domanda__c> questionsOptionsSets = [SELECT Id, Name, 
                                                                 (SELECT Id, Etichetta_Risultati_IT__c, Valore_Testuale__c, Valore_Numerico__c
                                                                  FROM Opzioni_Domande__r
                                                                  ORDER BY Ordine__c ASC, Valore_Numerico__c DESC) 
                                                                 FROM Insieme_Opzioni_Domanda__c 
                                                                 WHERE Id IN :questionsOptionSetIds];
        
        for(Domanda_questionario__c q : questions){
            
            for(Insieme_Opzioni_Domanda__c questionOptionSet : questionsOptionsSets){
                
                if(q.Insieme_Opzioni_Domanda__c == questionOptionSet.Id){
                    
                    results.put(q.Id, questionOptionSet.Opzioni_Domande__r);
                    
                }
                
            }
            
        }
        
        return results;
        
    }
    
}