@RestResource(urlMapping='/manager_insight/*')
global class ManagerInsightResource {
    
    static Map<String, String> defaultColors = new Map<String, String>{        
        'red' => '#CC0033',
            'orange' => '#FF7F00',
            'yellow' => '#fdd835',
            'green' => '#4caf50',
            'darkGreen' => '#1b5e20',
            'grey' => '#666666'
            };
                
                static Map<String, String> chartColors = new Map<String, String>();
    static Map<String, String> dealerMapColors = new Map<String, String>();
    
    private static void setColors(Id appId){
        
        chartColors = new Map<String, String>();
        dealerMapColors = new Map<String, String>();
        
        List<Configurazione_App__c> appConfigurations = [SELECT Id, Name, App__c, Chiave__c, Sezione__c, Tipologia_Campo__c, Campo_Testuale__c, Campo_Numerico__c,
                                                         Campo_Booleano__c, Campo_Data__c, Campo_Data_Ora__c
                                                         FROM Configurazione_App__c
                                                         WHERE App__c = :appId AND (Sezione__c = :'Dealer Map' OR Sezione__c = :'Grafici')];
        
        for(Configurazione_App__c ca : appConfigurations){
            
            if('Dealer Map'.equalsIgnoreCase(ca.Sezione__c)){
                
                dealerMapColors.put(ca.Chiave__c, ca.Campo_Testuale__c);
                
            }else if('Grafici'.equalsIgnoreCase(ca.Sezione__c)){
                
                chartColors.put(ca.Chiave__c, ca.Campo_Testuale__c);
                
            }
            
        }
        
    }
    
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
        
        setColors(ca.getAppId());
        
        String brandId = RestContext.request.params.get('brandId');
        String zonesIds = RestContext.request.params.get('zonesIds');
        
        Gruppo__c brand = getBrandById(brandId);
        
        /*Gruppo__c g = [SELECT Id, Gruppo_Master__c FROM Gruppo__c WHERE Id = :brandId LIMIT 1];
        
        if(g.Gruppo_Master__c != null){
            brandId = g.Gruppo_Master__c;
        }*/
        
        List<Object> charts = new List<Object>();
        
        //List<Gruppo__c> allGroups = UserResource.getAllGroups();
        //List<Gruppo__c> userGroups = UserResource.getUserGroups(u.Id);
        List<Gruppo__c> childGroups = UserResource.getUserGroupChildren(u.Id);
        childGroups = UserResource.filterGroupsByBrandId(childGroups, brandId);
        
        if(String.isNotBlank(zonesIds)){
            
            childGroups = UserResource.getGroupsByIds(zonesIds.split(','));
            
        }
        
        String insightInfo = 'Gli <b>Insight</b> approfondiscono i diversi ambiti legati al <b>Business</b> con la Casa e di Dealer <b>Motivation</b>.<br/><br/>';
        insightInfo += 'Nel grafico si riporta, per ciascuna tematica, la <b>media delle risposte dei Concessionari</b> appartenenti all\'area di competenza del Manager, confrontando i <b>risultati più recenti</b> rispetto a quelli del <b>periodo precedente</b> (secondo la frequenza di rilevazione del quesito).<br/><br/>';
        insightInfo += 'É inoltre specificato se la domanda è in corso rilevazione, il cui risultato parziale comparirà al raggiungimento di un campione minimo di rappresentatività.<br/><br/>';
        insightInfo += 'Cliccando su <b>ciascuna barra nel grafico</b> è possibile visualizzare la domanda estesa, il periodo puntuale di rilevazione e il campione di rispondenti.';
        
        //System.debug('Business Insight');
        
        List<Object> businessInsight = getInsight(brand, childGroups, 'Business Insight', new List<String>{'Business Insight'}, userPermissions, insightInfo);
        
        if(businessInsight != null && businessInsight.size() > 0){
            
            charts.addAll(businessInsight);
            
        }
        
        //System.debug('Motivation Insight');
        
        List<Object> motivationInsight = getInsight(brand, childGroups, 'Motivation Insight', new List<String>{'Motivation Insight'}, userPermissions, insightInfo);
        
        if(motivationInsight != null && motivationInsight.size() > 0){
            
            charts.addAll(motivationInsight);
            
        }
        
        res.setStatusCode(200);
        res.setBody(charts);
        
        res.send();
        
    }
    
    
    
    
    /********************************
********************************
******** DEALER INSIGHT 2 ******
********************************
********************************/
    
    public static List<Object> getInsight(Gruppo__c brand, List<Gruppo__c> childGroups, String title, List<String> sections, List<String> userPermissions, String chartInfo){
        
        List<Object> charts = new List<Object>();
        String chartTitle = title;
        DateTime currentDateTime = System.now();
        
        Integer dealerCountByBrand = dealerCount(childGroups);
        //System.debug(dealerCountByBrand);
        
        List<Raggruppamento__c> groupings = getGroupingsByBrandAndSectionName(brand, sections, userPermissions);
        List<Domanda_questionario__c> questions = getQuestionsByGroupingsWithRange(groupings, System.now().addMonths(-6), System.now());
        
        //System.debug('groupings.size(): ' + groupings.size());
        //System.debug('questions.size(): ' + questions.size());
        
        List<Utente_Gruppo__c> usersGroups = [SELECT Id, Utente__c, Gruppo__c, Nome_Gruppo__c, Sigla_Gruppo__c, Name FROM Utente_Gruppo__c 
                                              WHERE (Gruppo__r.Genitore__r.Genitore__c = :brand.Id OR Gruppo__r.Genitore__r.Genitore__c = :brand.Gruppo_Master__c)
                                              AND Utente__r.Non_Considerare_Analisi__c = false AND Utente__r.Tipologia__c = 'Dealer'
                                              AND Gruppo__c IN :childGroups];
        
        //System.debug('usersGroups.size(): ' + usersGroups.size());
        
        Set<Id> usersToAnalyze = new Set<Id>();
        
        for(Utente_Gruppo__c ug : usersGroups){
            
            usersToAnalyze.add(ug.Utente__c);
            
        }
        
        //System.debug('usersToAnalyze.size(): ' + usersToAnalyze.size());
        
        List<Risposta_questionario__c> answers = getAnswersByQuestionsAndUsers(questions, usersToAnalyze);
        
        //System.debug('answers.size(): ' + answers.size());
        
        //Map<String, Map<String, Map<String, List<Object>>>> answersByFrequencyGroupingIdAndQuestionId = new Map<String, Map<String, Map<String, List<Object>>>>();
        
        Map<String, Map<String, List<Object>>> answersByGroupingIdAndQuestionId = new Map<String, Map<String, List<Object>>>();
        
        for(Risposta_questionario__c a : answers){
            
            Set<String> brandsIds = new Set<String>();
            String frequency = a.Domanda_questionario__r.Frequenza__c;
            String groupingId = a.Domanda_questionario__r.Raggruppamento__c;
            String questionId = a.Domanda_questionario__c;
            String groupingLabel = a.Domanda_questionario__r.Raggruppamento__r.Etichetta_IT__c;
            String questionLabel = a.Domanda_questionario__r.Domanda_IT__c;
            Decimal value = a.Valore_Numerico__c;
            Datetime startDate = a.Domanda_questionario__r.Data_Ora_Inizio__c;
            Datetime endDate = a.Domanda_questionario__r.Data_Ora_Fine__c;
            Datetime startAnalysisDate = a.Domanda_questionario__r.Data_Ora_Inizio_Analisi__c;
            Datetime endAnalysisDate = a.Domanda_questionario__r.Data_Ora_Fine_Analisi__c;
            String answerUserId = a.Utente__c;
            Boolean toConsider = !a.Utente__r.Non_Considerare_Analisi__c;
            
            /*if(frequency == 'Mens.' || frequency == '15 gg'){

frequency = 'Mensili';

}else if(frequency == 'Trim.'){

frequency = 'Trimestrali';

}

if(!answersByFrequencyGroupingIdAndQuestionId.containsKey(frequency)){

answersByFrequencyGroupingIdAndQuestionId.put(frequency, new Map<String, Map<String, List<Object>>>());

}

Map<String, Map<String, List<Object>>> byFrequency = answersByFrequencyGroupingIdAndQuestionId.get(frequency);                

if(!byFrequency.containsKey(groupingId)){

byFrequency.put(groupingId, new Map<String, List<Object>>());

}*/
            
            if(!answersByGroupingIdAndQuestionId.containsKey(groupingId)){
                
                answersByGroupingIdAndQuestionId.put(groupingId, new Map<String, List<Object>>());
                
            }
            
            Map<String, List<Object>> byGrouping = answersByGroupingIdAndQuestionId.get(groupingId);              
            
            if(!byGrouping.containsKey(questionId)){
                
                byGrouping.put(questionId, new List<Object>());
                
            }
            
            List<Object> byQuestionId = byGrouping.get(questionId);
            
            byQuestionId.add(new Map<String, Object>{
                'questionId' => questionId,
                    'groupingId' => groupingId,
                    'groupingLabel' => groupingLabel,
                    'questionLabel' => questionLabel,
                    'value' => value,
                    'startDate' => startDate,
                    'endDate' => endDate,
                    'startAnalysisDate' => startAnalysisDate,
                    'endAnalysisDate' => endAnalysisDate,
                    'answerUserId' => answerUserId,
                    'toConsider' => toConsider,
                    'frequency' => frequency
                    });
            
        }
        
        Integer brandDealerCount = dealerCountByBrand;
        
        /*List<String> frequencies = new List<String>();
frequencies.addAll(answersByFrequencyGroupingIdAndQuestionId.keySet());

frequencies.sort();

for(String frequency : frequencies){*/
        
        BarChartData chart = new BarChartData(chartTitle, null, brand.Name);
        chart.color = brand.Colore__c;
        
        chart.info = chartInfo;
        
        List<BarChartBarData> barChartBarDataSampleList = new List<BarChartBarData>();
        List<BarChartBarData> barChartBarDataPreviousSampleList = new List<BarChartBarData>();
        
        //Map<String, Map<String, List<Object>>> answersByGroupingIdAndQuestionId = answersByFrequencyGroupingIdAndQuestionId.get(frequency);
        
        for(String groupingId : answersByGroupingIdAndQuestionId.keySet()){
            
            Map<String, List<Object>> answersByQuestionId = answersByGroupingIdAndQuestionId.get(groupingId);
            List<Object> lastQuestionAnswers = new List<Object>();
            List<Object> previousQuestionAnswers = new List<Object>();
            
            for(String questionId : answersByQuestionId.keySet()){
                
                List<Object> allAnswers = answersByQuestionId.get(questionId);
                
                //System.debug('lastQuestionAnswers.size()' + lastQuestionAnswers.size());
                //System.debug('previousQuestionAnswers.size()' + previousQuestionAnswers.size());
                
                if(lastQuestionAnswers.size() > 0 && previousQuestionAnswers.size() == 0){
                    
                    previousQuestionAnswers.addAll(allAnswers);
                    
                }
                
                if(lastQuestionAnswers.size() == 0){
                    
                    lastQuestionAnswers.addAll(allAnswers);
                    
                }
                
            }
            
            //System.debug(previousQuestionAnswers);
            
            Double userValue = 0;
            Double sampleAverage = 0;
            String groupingLabel = '';
            String questionLabel = '';
            Datetime startDate = null;
            Datetime endDate = null;
            String frequency = '';
            
            Integer sampleSize = lastQuestionAnswers.size();
            //System.debug('lastQuestionAnswers.size() ' + sampleSize);
            
            if(sampleSize > 0){
                
                for(Object o : lastQuestionAnswers){
                    
                    Map<String, Object> m = (Map<String, Object>) o;
                    
                    groupingLabel = (String) m.get('groupingLabel');
                    questionLabel = (String) m.get('questionLabel');
                    frequency = (String) m.get('frequency');
                    startDate = (Datetime) m.get('startDate');
                    endDate = (Datetime) m.get('endDate');
                    Boolean toConsider = (Boolean) m.get('toConsider');
                    
                    Decimal value = (Decimal) m.get('value');
                    String answerUserId = (String) m.get('answerUserId');
                    
                    if(toConsider){
                        
                        sampleAverage += value;
                        
                    }else{
                        
                        sampleSize--;
                        
                    }
                    
                }
                
                if(sampleSize > 0){
                    
                    sampleAverage /= sampleSize;                        
                    sampleAverage = transpose(sampleAverage);
                    
                }
                
                String startDateString = RCCUtils.dateFormat(Date.newInstance(startDate.year(), startDate.month(), startDate.day()));
                
                String endDateString = RCCUtils.dateFormat(Date.newInstance(endDate.year(), endDate.month(), endDate.day()));
                
                Boolean running = false;
                
                if(endDate > System.now()){
                    
                    endDateString = RCCUtils.dateFormat(System.today());
                    
                    running = true;
                    
                }
                
                List<String> endDateStringSplitted = endDateString.split(' ');
                Decimal percent = 100 * (Decimal.valueOf(sampleSize) / Decimal.valueOf(brandDealerCount));
                
                //System.debug('percent:' + percent);
                //System.debug('brand.Campione_Minimo_Percentuale__c:' + brand.Campione_Minimo_Percentuale__c);
                //System.debug(percent >= brand.Campione_Minimo_Percentuale__c);
                
                //groupingLabel += '\nUltima risposta: ' + endDateStringSplitted[0] + ' ' + endDateStringSplitted[1];
                
                groupingLabel += formatPeriodByStartDateAndFrequency(startDate, frequency);
                
                String info = '<strong>Inizio rilevazione:</strong> ' + startDateString + '<br/>' + 
                    '<strong>Termine rilevazione:</strong> ' + RCCUtils.dateFormat(Date.newInstance(endDate.year(), endDate.month(), endDate.day())) + '<br/>' + 
                    '<strong>Rispondenti:</strong> ' + String.valueOf(percent.setScale(0)) + '%<br/>' +
                    '<strong>Frequenza:</strong> ' + frequency;
                
                if(running){     
                    
                    groupingLabel += '\n(Rilevazione in corso)';
                    info += ' (Rilevazione in corso)';
                    
                }
                
                //System.debug(sampleAverage);
                
                if(percent >= brand.Campione_Minimo_Percentuale__c){
                
                    BarChartBarData barChartBarDataSample = new BarChartBarData(groupingLabel, null, Double.valueOf(sampleAverage), getColorByValue(Double.valueOf(sampleAverage)));
                    
                    barChartBarDataSample.extra = questionLabel;
                    barChartBarDataSample.info = info;
                    
                    barChartBarDataSampleList.add(barChartBarDataSample);                
                
                }
                
            }                    
            
            // Aggiunto per evitare di inserire nei test delle domande / risposte relative al periodo precedente.
            // La procedura è la stessa delle ultime risposte date, per questo ho usato questo bypass
            // TODO: creare una funzione per evitare la duplicazione del codice.
            if(Test.isRunningTest()){
                previousQuestionAnswers = lastQuestionAnswers;
            }
            
            userValue = 0;
            sampleAverage = 0;
            groupingLabel = '';
            questionLabel = '';
            frequency = '';
            startDate = null;
            endDate = null;
            DateTime previousStartDate = null;
            DateTime previousEndDate = null;
            
            sampleSize = previousQuestionAnswers.size();
            //System.debug('previousQuestionAnswers.size() ' + sampleSize);
            
            if(sampleSize > 0){
                
                for(Object o : previousQuestionAnswers){
                    
                    Map<String, Object> m = (Map<String, Object>) o;
                    
                    String previousGroupingId = (String) m.get('groupingId');
                    
                    groupingLabel = (String) m.get('groupingLabel');
                    questionLabel = (String) m.get('questionLabel');   
                    frequency = (String) m.get('frequency');
                    
                    startDate = (Datetime) m.get('startDate');
                    endDate = (Datetime) m.get('endDate');
                    
                    previousStartDate = (Datetime) m.get('startDate');
                    previousEndDate = (Datetime) m.get('endDate');
                    
                    for(Object oo : lastQuestionAnswers){ 
                        
                        Map<String, Object> mm = (Map<String, Object>) oo;
                        
                        String lastGroupingId = (String) mm.get('groupingId');
                        
                        if(lastGroupingId == previousGroupingId){
                            
                            groupingLabel = (String) mm.get('groupingLabel');
                            questionLabel = (String) mm.get('questionLabel');   
                            frequency = (String) mm.get('frequency');                            
                            startDate = (Datetime) mm.get('startDate');
                            endDate = (Datetime) mm.get('endDate');
                            
                        }
                        
                    }
                    
                    Boolean toConsider = (Boolean) m.get('toConsider');
                    Decimal value = (Decimal) m.get('value');
                    String answerUserId = (String) m.get('answerUserId');
                    
                    if(toConsider){
                        
                        sampleAverage += value;
                        
                    }else{
                        
                        sampleSize--;
                        
                    }
                    
                }
                
                if(sampleSize > 0){
                    
                    sampleAverage /= sampleSize;                        
                    sampleAverage = transpose(sampleAverage);
                    
                }
                
                String startDateString = RCCUtils.dateFormat(Date.newInstance(startDate.year(), startDate.month(), startDate.day()));                        
                String endDateString = RCCUtils.dateFormat(Date.newInstance(endDate.year(), endDate.month(), endDate.day()));
                
                String previousStartDateString = RCCUtils.dateFormat(Date.newInstance(previousStartDate.year(), previousStartDate.month(), previousStartDate.day()));                        
                String previousEndDateString = RCCUtils.dateFormat(Date.newInstance(previousEndDate.year(), previousEndDate.month(), previousEndDate.day()));
                
                Boolean running = false;
                
                if(endDate > System.now()){
                    
                    endDateString = RCCUtils.dateFormat(System.today());
                    
                    running = true;
                    
                }
                
                List<String> endDateStringSplitted = endDateString.split(' ');
                Decimal percent = 100 * (Decimal.valueOf(sampleSize) / Decimal.valueOf(brandDealerCount));
                
                //System.debug('percent:' + percent);
                //System.debug('brand.Campione_Minimo_Percentuale__c:' + brand.Campione_Minimo_Percentuale__c);
                //System.debug(percent >= brand.Campione_Minimo_Percentuale__c);
                
                //groupingLabel += '\nUltima risposta: ' + endDateStringSplitted[0] + ' ' + endDateStringSplitted[1];
                
                groupingLabel += formatPeriodByStartDateAndFrequency(startDate, frequency);
                
                String info = '<strong>Inizio rilevazione:</strong> ' + previousStartDateString + '<br/>' + 
                    '<strong>Termine rilevazione:</strong> ' + previousEndDateString + '<br/>' + 
                    '<strong>Rispondenti:</strong> ' + String.valueOf(percent.setScale(0)) + '%<br/>' +
                    '<strong>Frequenza:</strong> ' + frequency + '<br/><br/>' +
                    '<small>* Dati relativi al periodo precedente.</small> ';
                
                if(running){     
                    
                    groupingLabel += '\n(Rilevazione in corso)';
                    //info += ' (Rilevazione in corso)';
                    
                }
                
                if(percent >= brand.Campione_Minimo_Percentuale__c){
                
                    BarChartBarData barChartBarDataPreviousSample = new BarChartBarData(groupingLabel, null, Double.valueOf(sampleAverage), getColorByValue(Double.valueOf(sampleAverage)));
                    
                    barChartBarDataPreviousSample.extra = questionLabel;
                    barChartBarDataPreviousSample.info = info;
                    
                    barChartBarDataPreviousSampleList.add(barChartBarDataPreviousSample);
                    
                }
                
            }
            
        }
        
        Boolean addChart = false;
        
        String noData = '* Il dato verrà visualizzato non appena saranno presenti delle risposte per questo indicatore.';
        
        //System.debug('barChartBarDataSampleList.size(): ' + barChartBarDataSampleList.size());
        
        //if(barChartBarDataSampleList.size() > 0){
            
            chart.addBarChartBarListData(barChartBarDataSampleList);
            chart.post = noData;
            addChart = true;
            
        //}
        
        //System.debug('barChartBarDataPreviousSampleList.size(): ' + barChartBarDataPreviousSampleList.size());
        
        //if(barChartBarDataPreviousSampleList.size() > 0){
            
            chart.addBarChartBarListData(barChartBarDataPreviousSampleList);
            chart.post = noData;
            addChart = true;
            
        //}
        
        if(addChart){
            
            charts.add(chart);
            
        }
        
        //}
        
        return charts;
        
        
    }
    
    private static Gruppo__c getBrandById(String brandId){
        
        return [SELECT Id, Name, Genitore__c, Tipologia__c, Ordine__c, Campione_Minimo_Percentuale__c, Colore__c, Gruppo_Master__c, Gruppo_Master__r.Genitore__c
                FROM Gruppo__c WHERE Id = :brandId LIMIT 1];
        
    }
    
    private static List<Raggruppamento__c> getGroupingsByBrandAndSectionName(Gruppo__c brand, List<String> sections, List<String> userPermissions){
        
        return [SELECT Id, Name
                FROM Raggruppamento__c 
                WHERE (Gruppo__c = :brand.Id OR Gruppo__c = :brand.Genitore__c OR Gruppo__c = :brand.Gruppo_Master__c OR Gruppo__c = :brand.Gruppo_Master__r.Genitore__c)
                AND Visualizzabile_Da_Manager_In__c IN :sections AND Azienda_Permessi_Visualizzazione__c IN :userPermissions];
        
    }
    
    private static List<Domanda_questionario__c> getQuestionsByGroupingsWithRange(List<Raggruppamento__c> groupings, Datetime fromDateTime, Datetime toDateTime){
        
        return [SELECT Id, Data_Ora_Inizio__c, Data_Ora_Inizio_Analisi__c, Raggruppamento__c, Raggruppamento__r.Gruppo__c, Data_Ora_Fine_Analisi__c
                FROM Domanda_questionario__c 
                WHERE Raggruppamento__c IN :groupings AND Data_Ora_Inizio_Analisi__c >= :fromDateTime AND Data_Ora_Inizio_Analisi__c <= :toDateTime
                ORDER BY Data_Ora_Inizio_Analisi__c DESC];
        
    }
    
    private static Integer dealerCount(List<Gruppo__c> childGroups){
        
        return [SELECT COUNT()
                FROM Utente_Gruppo__c 
                WHERE Utente__r.Tipologia__c = 'Dealer' AND Utente__r.Non_Considerare_Analisi__c = false
                AND Gruppo__c = :childGroups];
        
    }
    
    private static List<Risposta_Questionario__c> getAnswersByQuestionsAndUsers(List<Domanda_questionario__c> questions, Set<Id> usersIds){
        
        return [SELECT Utente__c, Domanda_Questionario__r.Raggruppamento__c, Domanda_Questionario__r.Data_Ora_Inizio__c,
                Domanda_Questionario__r.Data_Ora_Fine__c, Domanda_questionario__r.Raggruppamento__r.Etichetta_IT__c,
                Domanda_questionario__r.Raggruppamento__r.Gruppo__r.Name, Valore_Numerico__c,
                Domanda_questionario__r.Raggruppamento__r.Gruppo__c, Domanda_questionario__r.Frequenza__c,
                Domanda_questionario__r.Domanda_IT__c, Domanda_Questionario__c, Utente__r.Non_Considerare_Analisi__c,
                Domanda_Questionario__r.Data_Ora_Inizio_Analisi__c, Domanda_Questionario__r.Data_Ora_Fine_Analisi__c
                FROM Risposta_questionario__c
                WHERE Domanda_questionario__c IN :questions AND (Risposta_questionario__c.Valore_Numerico__c != null OR Risposta_questionario__c.Valore_Testuale__c != null )
                AND Utente__c IN :usersIds
                ORDER BY Domanda_Questionario__r.Data_Ora_Inizio__c DESC];
        
    }
    
    
    public static String getColorByValue(Double value){
        
        if (value >= 0 && value < 20) {
            return chartColors.containsKey('colore_rosso') ? chartColors.get('colore_rosso') : defaultColors.get('red');
        } else if (value >= 20 && value < 40) {
            return chartColors.containsKey('colore_arancione') ? chartColors.get('colore_arancione') : defaultColors.get('orange');
        } else if (value >= 40 && value < 60) {
            return chartColors.containsKey('colore_verde_chiaro') ? chartColors.get('colore_giallo') : defaultColors.get('yellow');
        } else if (value >= 60 && value < 80) {
            return chartColors.containsKey('colore_verde_chiaro') ? chartColors.get('colore_verde_chiaro') : defaultColors.get('green');
        } else if (value >= 80 && value <= 100) {
            return chartColors.containsKey('colore_verde_scuro') ? chartColors.get('colore_verde_scuro') : defaultColors.get('darkGreen');
        } else {
            return defaultColors.get('grey');
        }
        
    }
    
    public static String autoBreakText(String text) {
        String label = '';
        List<String> pieces = text.split(' ');
        String partial = '';
        for(String piece : pieces){
            partial += String.isEmpty(partial) ? ' ' : '';
            if ((partial.length() + piece.length()) > 16) {
                label += '$partial\n';
                partial = piece;
            } else {
                partial += '$piece';
            }
        }
        label += partial;
        return label;
    }
    
    // Traspone un valore in una scala da 1 a 100
    private static Double transpose(Double value){
        
        Double result = 0;
        
        if(value != null && value > 0){
            
            result = (100 / (5 - 1)) * value - (100 / (5 - 1));
            
            if(result <= 0){
                
                result = 5;
                
            }
            
        }
        
        return result;
        
    }
    
    private static String formatPeriodByStartDateAndFrequency(DateTime current, String frequency){
        
        String out = '';
            
        Date currentDate = Date.newInstance(current.year(), current.month(), current.day());            
        Date previousDate = Date.newInstance(current.year(), current.month(), current.day());
        
        previousDate = previousDate.addMonths(-1);
        
        String currentMonthString = RCCUtils.dateFormat(currentDate).split(' ')[1].subString(0, 3) + '.';
        String previousMonthString = RCCUtils.dateFormat(previousDate).split(' ')[1].subString(0, 3) + '.';
        
        if('15 gg'.equalsIgnoreCase(frequency)){
            
            if(current.day() < 15){
                
                Date lastDayOfPreviousDate = Date.newInstance(current.year(), current.month(), 1).addDays(-1);
                
                out = '1-15 ' + currentMonthString + ' vs 16-' + lastDayOfPreviousDate.day() + ' ' + previousMonthString;
                
            }else{
                
                Date lastDayOfCurrentDate = Date.newInstance(current.year(), current.month(), 1).addMonths(1).addDays(-1);
                
                out = '16-' + lastDayOfCurrentDate.day() + ' ' + currentMonthString + ' vs 1-15 ' + currentMonthString;
                
            }
            
        }else if('Mens.'.equalsIgnoreCase(frequency)){
            
            out = currentMonthString + ' ' + currentDate.year() + ' vs ' + previousMonthString + ' ' + previousDate.year();          
            
        }else if('Bimestr.'.equalsIgnoreCase(frequency)){
            
            out = currentMonthString + ' ' + currentDate.year() + ' vs ' + previousMonthString + ' ' + previousDate.year();  
            
        }else if('Trim.'.equalsIgnoreCase(frequency)){
            
            if(currentDate.month() > 0 && currentDate.month() <= 3){
                
                out = 'Q1 ' + currentDate.year() + ' vs Q4 ' + (currentDate.year() - 1);
                
            }else if(currentDate.month() > 3 && currentDate.month() <= 6){
                
                out = 'Q2 ' + currentDate.year() + ' vs Q1 ' + currentDate.year();
                
            }else if(currentDate.month() > 6 && currentDate.month() <= 9){
                
                out = 'Q3 ' + currentDate.year() + ' vs Q2 ' + currentDate.year();
                
            }else if(currentDate.month() > 9 && currentDate.month() <= 12){
                
                out = 'Q4 ' + currentDate.year() + ' vs Q3 ' + currentDate.year();
                
            }               
            
        }else if('Quadr.'.equalsIgnoreCase(frequency)){
                        
            if(currentDate.month() > 0 && currentDate.month() <= 4){
                
                out = '1° Quadr. ' + currentDate.year() + ' vs 3° Quadr. ' + (currentDate.year() - 1);
                
            }else if(currentDate.month() > 4 && currentDate.month() <= 8){
                
                out = '2° Quadr. ' + currentDate.year() + ' vs 1° Quadr. ' + currentDate.year();
                
            }else if(currentDate.month() > 8 && currentDate.month() <= 12){
                
                out = '3° Quadr. ' + currentDate.year() + ' vs 2° Quadr. ' + currentDate.year();
                
            }           
            
        }else if('Sem.'.equalsIgnoreCase(frequency)){
            
            if(currentDate.month() > 0 && currentDate.month() <= 6){
                
                out = '1° Sem. ' + currentDate.year() + ' vs 2° Sem. ' + (currentDate.year() - 1);
                
            }else if(currentDate.month() > 4 && currentDate.month() <= 12){
                
                out = '2° Sem. ' + currentDate.year() + ' vs 1° Sem. ' + currentDate.year();
                
            }        
            
        }else if('Ann.'.equalsIgnoreCase(frequency)){
            
            out = currentDate.year() + ' vs ' + (currentDate.year() - 1);
            
        }       
        
        
        return '\n' + out;
        
    }
    
}