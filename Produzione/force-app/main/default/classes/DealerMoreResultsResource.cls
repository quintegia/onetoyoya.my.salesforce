@RestResource(urlMapping='/dealer_more_results/*')
global class DealerMoreResultsResource{
    
    @HttpGet
    global static void doGet(){
        
        CustomAuthentication ca = new CustomAuthentication(RestContext.request, RestContext.response);
        
        if(!ca.authenticate()){
            
            ca.getResponse().send();
            
            return;
            
        }
        
        CustomResponse res = new CustomResponse(RestContext.response);
        
        //Id userId = 'a4n0E000000n0wsQAA';
        
        Utente__c u = ca.getUser();
        Id userId = u.Utente_Master__c != null ? u.Utente_Master__c : u.Id;
        
        List<Gruppo__c> userBrands = RCCUtils.findUserBrandsByUserId(userId);        
        Set<Id> userBrandsIds = RCCUtils.findUserGroupsByUserId(userId, false);
        
        List<Object> moreResults = new List<Object>();
        
        //moreResults.addAll(getDealerMoreResults(userId, userBrands));
        moreResults.addAll(getDealerMoreResults2(userId, userBrandsIds));
        
        res.setStatusCode(200);
        res.setBody(moreResults);
        
        res.send();
        
    }
    
    public static List<Object> getDealerMoreResults2(Id userId, Set<Id> userBrandsIds){
        
        List<Object> charts = new List<Object>();
        String chartTitle = 'More Results';
        DateTime currentDateTime = System.now();
        
        Map<String, Integer> dealerCountByBrand = dealerCount();
        Map<String, Set<Id>> dealersByBrand = getDealersByBrand();
        List<Gruppo__c> brands = getBrandsByGroupsIds(userBrandsIds);
        List<Raggruppamento__c> groupings = getGroupingsByGroupsIdsAndSectionName(userBrandsIds, chartTitle);
        List<Domanda_questionario__c> questions = getQuestionsByGroupingsWithRange(groupings, System.now().addMonths(-6), System.now());
        List<Risposta_questionario__c> answers = getAnswersByQuestions(questions);
        Map<Id, List<Opzione_Domanda__c>> questionsOptionsSetsByQuestionId = getQuestionsOptionsSetsByQuestions(questions);
        
        Map<String, Gruppo__c> brandsById = new Map<String, Gruppo__c>();
        
        System.debug(dealerCountByBrand);
        System.debug(brands.size());
        System.debug(groupings.size());
        System.debug(questions.size());
        System.debug(answers.size());
        
        Set<Id> allBrandsIds = new Set<Id>();
        
        for(Gruppo__c b : brands){
            
            allBrandsIds.add(b.Id);
            brandsById.put(b.Id, b);
            
        }
        
        Map<String, Map<String, Map<String, Map<String, List<Object>>>>> answersByBrandIdFrequencyGroupingIdAndQuestionId = new Map<String, Map<String, Map<String, Map<String, List<Object>>>>>();
        
        for(Risposta_questionario__c a : answers){
            
            Set<String> brandsIds = new Set<String>();
            String frequency = 'all';
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
            
            if(allBrandsIds.contains(a.Domanda_questionario__r.Raggruppamento__r.Gruppo__c)){
                
                brandsIds.add(a.Domanda_questionario__r.Raggruppamento__r.Gruppo__c);
                
            }else{
                
                for(Gruppo__c b : brands){
                    
                    brandsIds.add(b.Id);
                    
                }
                
            }
            
            /*if(a.Domanda_questionario__r.Name == 'DTMI-000237'){
                
                System.debug(a);
                System.debug(a.Domanda_questionario__r);
                System.debug(a.Domanda_questionario__r.Raggruppamento__r);
                System.debug(a.Domanda_questionario__r.Raggruppamento__r.Gruppo__r);
                System.debug(allBrandsIds);
                System.debug(brandsIds);
                
            }*/
            
            for(String brandId : brandsIds){
                
                if(!answersByBrandIdFrequencyGroupingIdAndQuestionId.containsKey(brandId)){
                    
                    answersByBrandIdFrequencyGroupingIdAndQuestionId.put(brandId, new Map<String, Map<String, Map<String, List<Object>>>>());
                    
                }
                
                Map<String, Map<String, Map<String, List<Object>>>> byBrand = answersByBrandIdFrequencyGroupingIdAndQuestionId.get(brandId);
                
                if(!byBrand.containsKey(frequency)){
                    
                    byBrand.put(frequency, new Map<String, Map<String, List<Object>>>());
                    
                }
                
                Map<String, Map<String, List<Object>>> byFrequency = byBrand.get(frequency);                
                
                if(!byFrequency.containsKey(groupingId)){
                    
                    byFrequency.put(groupingId, new Map<String, List<Object>>());
                    
                }
                
                Map<String, List<Object>> byGrouping = byFrequency.get(groupingId);              
                
                if(!byGrouping.containsKey(questionId)){
                    
                    byGrouping.put(questionId, new List<Object>());
                    
                }
                
                List<Object> byQuestionId = byGrouping.get(questionId);
                
                if(dealersByBrand.get(brandId).contains(a.Utente__c) || userId == a.Utente__c){
                
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
                
            }
            
        }
        
        for(String brandId : answersByBrandIdFrequencyGroupingIdAndQuestionId.keySet()){
            
            Map<String, Map<String, Map<String, List<Object>>>> answersByFrequencyGroupingIdAndQuestionId = answersByBrandIdFrequencyGroupingIdAndQuestionId.get(brandId);
            Integer brandDealerCount = dealerCountByBrand.get(brandId);
            Gruppo__c brand = brandsById.get(brandId);
            
            for(String frequency : answersByFrequencyGroupingIdAndQuestionId.keySet()){
                
                String brandName = '';
                String brandColor = null;
                
                for(Gruppo__c b : brands){
                    
                    if(b.Id == brandId){
                        
                        brandName = b.Name;
                        brandColor = b.Colore__c;
                        
                    }
                    
                }
                
                Map<String, Map<String, List<Object>>> answersByGroupingIdAndQuestionId = answersByFrequencyGroupingIdAndQuestionId.get(frequency);
                
                for(String groupingId : answersByGroupingIdAndQuestionId.keySet()){
                    
                    Map<String, List<Object>> answersByQuestionId = answersByGroupingIdAndQuestionId.get(groupingId);
                    Map<String, List<Object>> lastQuestionAnswers = new Map<String, List<Object>>();
                    
                    for(String questionId : answersByQuestionId.keySet()){
                        
                        List<Object> allAnswers = answersByQuestionId.get(questionId);
                        Boolean addAnswers = false;
                        Map<String, Decimal> options = new Map<String, Decimal>();
                        
                        System.debug('allAnswers.size():' + allAnswers.size());
                        
                        for(Object o : allAnswers){
                            
                            Map<String, Object> m = (Map<String, Object>) o;
                            
                            Datetime startDate = (Datetime) m.get('startDate');
                            Datetime endDate = (Datetime) m.get('endDate');
                            String answerUserId = (String) m.get('answerUserId');
                            
                            if((userId == answerUserId) || (startDate <= System.now() && endDate >= System.now())){
                                
                                addAnswers = true;
                                
                            }
                            
                        }
                        
                        System.debug('addAnswers:' + addAnswers);
                        
                        Decimal minimumSampleSize = 0.1;
                        
                        if(brand != null && brand.Campione_Minimo_Percentuale__c != null){
                            
                            minimumSampleSize = brand.Campione_Minimo_Percentuale__c / 100.0;
                            
                        }
                        
                        if(allAnswers.size() > brandDealerCount * minimumSampleSize && addAnswers && !lastQuestionAnswers.containsKey(questionId)){
                            
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
                        
                        //total = allAnswers.size();
                        
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
                        
                        chart.info = 'In questa sezione sono disponibili <strong>altri risultati</strong> raccolti, consultabili quando raggiunto un campione sufficiente di risposte.<br/><br/>'
                            + 'La data si riferisce al giorno di pubblicazione del quesito.<br/><br/>'
                            + 'Se ancora attivo, si è invitati a rispondere per poter consultare i risultati aggiornati in tempo reale.';
                        
                        Decimal sample = (total / brandDealerCount * 100);
                        
                        System.debug('total: ' + total);
                        System.debug('brandDealerCount: ' + brandDealerCount);
                        System.debug('sample: ' + sample);
                        
                        /*if(sample >= 100){
                            
                            sample = 100;
                            
                        }*/
                        
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
                
            }
            
        }
        
        return charts;
        
    }
    
    private static List<Gruppo__c> getBrandsByGroupsIds(Set<Id> groupsIds){
        
        return [SELECT Id, Name, Genitore__c, Tipologia__c, Ordine__c, Campione_Minimo_Percentuale__c, Colore__c 
                FROM Gruppo__c 
                WHERE Id IN :groupsIds AND Tipologia__c = 'Marchio' ORDER BY Ordine__c ASC];
        
    }
    
    private static List<Raggruppamento__c> getGroupingsByGroupsIdsAndSectionName(Set<Id> groupsIds, String section){
        
        return [SELECT Id, Name
                FROM Raggruppamento__c 
                WHERE Gruppo__c IN :groupsIds AND Visualizzabile_Da_Dealer_In__c = :section];
        
    }
    
    private static List<Domanda_questionario__c> getQuestionsByGroupingsWithRange(List<Raggruppamento__c> groupings, Datetime fromDateTime, Datetime toDateTime){
        
        return [SELECT Id, Data_Ora_Inizio__c, Data_Ora_Inizio_Analisi__c, Raggruppamento__c, Raggruppamento__r.Gruppo__c, Data_Ora_Fine_Analisi__c,
                Insieme_Opzioni_Domanda__c
                FROM Domanda_questionario__c 
                WHERE Raggruppamento__c IN :groupings AND Data_Ora_Inizio_Analisi__c >= :fromDateTime AND Data_Ora_Inizio_Analisi__c <= :toDateTime
                ORDER BY Data_Ora_Inizio_Analisi__c DESC];
        
    }
    
    private static Map<String, Integer> dealerCount(){
        
        Map<String, Integer> result = new Map<String, Integer>();
        
        List<AggregateResult> usersGroupsAggregated = [SELECT COUNT(Id), Gruppo__r.Genitore__r.Genitore__c
                                                       FROM Utente_Gruppo__c 
                                                       WHERE Utente__r.Tipologia__c = 'Dealer' AND Utente__r.Non_Considerare_Analisi__c = :false
                                                       GROUP BY Gruppo__r.Genitore__r.Genitore__c];
        
        // Totale rispondenti per marchio
        for(AggregateResult ar : usersGroupsAggregated){
            
            Id groupId = (Id) ar.get('Genitore__c');
            Integer counter = (Integer) ar.get('expr0');
            
            result.put(groupId, counter);
            
        }
        
        return result;
        
    }
    
    private static Map<String, Set<Id>> getDealersByBrand(){
        
        Map<String, Set<Id>> result = new Map<String, Set<Id>>();
        
        List<Utente_Gruppo__c> usersGroups = [SELECT Id, Utente__c, Gruppo__r.Genitore__r.Genitore__c
                                              FROM Utente_Gruppo__c 
                                              WHERE Utente__r.Tipologia__c = 'Dealer' AND Utente__r.Non_Considerare_Analisi__c = :false];
        
        // Totale rispondenti per marchio
        for(Utente_Gruppo__c userGroup : usersGroups){
            
            if(!result.containsKey(userGroup.Gruppo__r.Genitore__r.Genitore__c)){
                
                result.put(userGroup.Gruppo__r.Genitore__r.Genitore__c, new Set<Id>());
                
            }
            
            result.get(userGroup.Gruppo__r.Genitore__r.Genitore__c).add(userGroup.Utente__c);
            
        }
        
        return result;
        
    }
    
    private static List<Risposta_Questionario__c> getAnswersByQuestions(List<Domanda_questionario__c> questions){
        
        return [SELECT Utente__c, Domanda_Questionario__r.Raggruppamento__c, Domanda_Questionario__r.Data_Ora_Inizio__c,
                Domanda_Questionario__r.Data_Ora_Fine__c, Domanda_questionario__r.Raggruppamento__r.Etichetta_IT__c,
                Domanda_questionario__r.Raggruppamento__r.Gruppo__r.Name, Valore_Numerico__c, Valore_Testuale__c,
                Domanda_questionario__r.Raggruppamento__r.Gruppo__c, Domanda_questionario__r.Frequenza__c,
                Domanda_questionario__r.Domanda_IT__c, Domanda_Questionario__c, Utente__r.Non_Considerare_Analisi__c,
                Domanda_Questionario__r.Data_Ora_Inizio_Analisi__c, Domanda_Questionario__r.Data_Ora_Fine_Analisi__c,
                Domanda_Questionario__r.Name
                FROM Risposta_questionario__c
                WHERE Domanda_questionario__c IN :questions AND (Risposta_questionario__c.Valore_Numerico__c != null OR Risposta_questionario__c.Valore_Testuale__c != null )
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