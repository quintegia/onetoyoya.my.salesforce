@RestResource(urlMapping='/questions/*')
global class QuestionResource {
    
    @HttpPost
    global static void doPost(/*String id, String userId, String questionId, Integer numericValue, String textValue, String longTextValue*/){
                
        CustomAuthentication ca = new CustomAuthentication(RestContext.request, RestContext.response);
        
        if(!ca.authenticate()){
            
            ca.getResponse().send();
        
            return;
            
        }
        
        CustomResponse res = new CustomResponse(RestContext.response);
        
        //String jsonBody = RestContext.request.requestBody.toString();
                
        AnswerData userAnswer = new AnswerData();        
        Risposta_questionario__c newAnswer = new Risposta_questionario__c();
        
        if(RestContext.request.requestBody == null){  
            
            res.setStatusCode(500);
            res.setBody(new Map<String, Object>{'error' => 'Request body missing.'});
            res.send();
            
            return;
            
        }          
            
        String body = RestContext.request.requestBody.toString();
        
        if(String.isEmpty(body)){
            
            res.setStatusCode(500);
            res.setBody(new Map<String, Object>{'error' => 'Request body is empty.'});
            res.send();
            
            return;
            
        }
        
        try{
        
            userAnswer.fromJson(body);
            
        }catch(Exception ex){
            
            res.setStatusCode(500);
            res.setBody(new Map<String, Object>{'error' => 'Malformed json.'});
            res.send();
            
            return;
            
        }
        
        if(String.isEmpty(userAnswer.questionId)){
            
            res.setStatusCode(500);
            res.setBody(new Map<String, Object>{'error' => 'Question id is missing.'});
            res.send();
            
            return;
            
        }
        
        Domanda_questionario__c question = [SELECT Id, Tipologia__c, Obbligatoria__c FROM Domanda_questionario__c WHERE Id = :userAnswer.questionId LIMIT 1];
        
        if(question.Obbligatoria__c && userAnswer.numericValue == null && String.isBlank(userAnswer.textValue)){
            
            res.setStatusCode(500);
            res.setBody(new Map<String, Object>{'error' => 'Domanda obbligatoria'});
            res.send();
            
            return;
            
        }
        
        if('Radio con commento obbligatorio'.equalsIgnoreCase(question.Tipologia__c)){
            
            if(String.isBlank(userAnswer.longTextValue)){
                
                res.setStatusCode(500);
                res.setBody(new Map<String, Object>{'error' => 'Commento obbligatorio'});
                res.send();
                
                return;
                
            }
            
            
        }else if('Radio con commento obbligatorio se minore di 3'.equalsIgnoreCase(question.Tipologia__c)){
            
            if(String.isBlank(userAnswer.longTextValue) && userAnswer.numericValue < 3){
                
                res.setStatusCode(500);
                res.setBody(new Map<String, Object>{'error' => 'Commento obbligatorio'});
                res.send();
                
                return;
                
            }
            
        }
        
        userAnswer.userId = ca.getUser().Id;
        userAnswer.answerDateTime = System.now().getTime();
            
        newAnswer.Utente__c = userAnswer.userId;
        newAnswer.Domanda_questionario__c = userAnswer.questionId;
        newAnswer.Valore_Numerico__c = userAnswer.numericValue;
        newAnswer.Valore_Testuale__c = userAnswer.textValue;
        newAnswer.Valore_Testuale_Lungo__c = userAnswer.longTextValue;
        newAnswer.Data_Ora_Risposta__c = Datetime.newInstance(userAnswer.answerDateTime);
        
        if(!ca.isStealth() && (newAnswer.Valore_Numerico__c != null || newAnswer.Valore_Testuale__c != null)){
            insert newAnswer;
        }
        
        AnswerData answerData = new AnswerData();
        
        answerData.fromAnswer(newAnswer);
        
        res.setStatusCode(200);
        res.setBody(answerData);
        res.send();
        
        return;
        
    }
    
    @HttpGet
    global static void doGet(){
        
        String path = RestContext.request.requestURI.substring(RestContext.request.requestURI.lastIndexOf('/')+1);
        
        CustomAuthentication ca = new CustomAuthentication(RestContext.request, RestContext.response);
        
        if(!ca.authenticate()){
            
            ca.getResponse().send();
        
            return;
            
        }
        
        CustomResponse res = new CustomResponse(RestContext.response);
        
        Utente__c u = ca.getUser();
        Id userId = u.Id;
        
        if('get_count'.equals(path)){
            
            String target = RestContext.request.params.get('target');
            
            userId = u.Utente_Master__c != null ? u.Utente_Master__c : u.Id;
            
            res.setStatusCode(200);
            res.setBody(buildGetCountBody(getUserQuestionsCountByUserId(userId, target)));
            
        }else{
            
            List<Domanda_Questionario__c> userQuestions = findAllUserQuestionsByUserId(userId);
            List<Opzione_Domanda__c> questionsOptions = findQuestionsOptionsByQuestionsIds(userQuestions);
            
            res.setStatusCode(200);
            res.setBody(buildFindAllQuestionsBody(userQuestions, questionsOptions));
            
        }        
        
        res.send();
        
    }
    
    private static Object buildGetCountBody(Integer count){
        
        return new Map<String, Object>{'count' => count};
        
    }
    
    private static Object buildFindAllQuestionsBody(List<Domanda_Questionario__c> questions, List<Opzione_Domanda__c> questionsOptions){
        
        List<Object> jsonQuestions = new List<Object>();
        
        for(Domanda_Questionario__c q : questions){
            
            String brand = '';
            
            QuestionData newQuestion = new QuestionData(q, questionsOptions);
            
            if(String.isNotBlank(q.Raggruppamento__r.Gruppo__r.Name)){
                
                brand = q.Raggruppamento__r.Gruppo__r.Name.toLowerCase();
                
            }
            
            newQuestion.brand = brand;
            
            jsonQuestions.add(newQuestion);
            
        }
        
        return jsonQuestions;
        
    }
    
    private static List<Opzione_Domanda__c> findQuestionsOptionsByQuestionsIds(List<Domanda_Questionario__c> userQuestions){
        
        Set<Id> groupsIds = new Set<Id>();
        
        for(Domanda_Questionario__c question : userQuestions){
            
            groupsIds.add(question.Insieme_Opzioni_Domanda__c);
            
        }
        
        return [SELECT Id, Etichetta_Risultati_IT__c, Opzione_Domanda_IT__c, Valore_Numerico__c, Valore_Testuale__c, 
                Insieme_Opzioni_Domanda__c
                FROM Opzione_Domanda__c 
                WHERE Insieme_Opzioni_Domanda__c IN :groupsIds ORDER BY Ordine__c, Valore_Numerico__c DESC];
        
    }
    
    public static Integer getUserQuestionsCountByUserId(Id userId, String target){
        
        //Set<Id> groups = RCCUtils.findUserGroupsByUserId(userId, false);
        
        Set<Id> groups = new Set<Id>();
        
        List<Gruppo__c> userGroups = UserResource.getUserGroupAncestors(userId);
        
        for(Gruppo__c g : userGroups){
            
            groups.add(g.Id);
            
        }
        
        return countQuestionsByGroupIds(groups, userId, target);
        
    }
    
    public static Boolean thereAreNewQuestions(Set<Id> groupIds, String target){
        
        DateTime currentDateTime = System.now();
        Integer currentMonth = currentDateTime.month();
        Integer currentYear = currentDateTime.year();
        Integer currentDay = currentDateTime.day();
        
        Date periodStart = Date.newInstance(currentYear, currentMonth, currentDay >= 15 ? 15 : 1);
        Date periodEnd = Date.newInstance(periodStart.year(), periodStart.month(), currentDay >= 15 ? 1 : 15);
        
        periodEnd.addMonths(currentDay >= 15 ? 1 : 0);
        
        Integer counter = [SELECT COUNT() FROM Domanda_Questionario__c 
                           WHERE Raggruppamento__r.Gruppo__c IN :groupIds AND Obbligatoria_Per_Risultati__c != null
                           AND (Raggruppamento__r.Visualizzabile_Da_Dealer_In__c = :target OR Raggruppamento__r.Genitore__r.Visualizzabile_Da_Dealer_In__c = :target)
                           AND Data_Ora_Inizio__c <= :currentDatetime AND Data_Ora_Inizio__c >= :periodStart AND Data_Ora_Inizio__c <= :periodEnd];
        
        return counter > 0;
        
    }
    
    private static List<Domanda_Questionario__c> findAllUserQuestionsByUserId(Id userId){
        
        //Set<Id> groups = RCCUtils.findUserGroupsByUserId(userId, false);
        
        Set<Id> groups = new Set<Id>();
        
        List<Gruppo__c> userGroups = UserResource.getUserGroupAncestors(userId);
        
        for(Gruppo__c g : userGroups){
            
            groups.add(g.Id);
            
        }
        
        return findQuestionsByGroupIds(groups, userId);               
        
    }
    
    private static Integer countQuestionsByGroupIds(Set<Id> groupIds, Id userId, String target){
        
        Datetime currentDatetime = System.now();
        
        if(String.isBlank(target)){
        
            return [SELECT COUNT() FROM Domanda_Questionario__c 
                    WHERE Id NOT IN (SELECT Domanda_questionario__c FROM Risposta_questionario__c WHERE Utente__c = :userId) 
                    AND Raggruppamento__r.Gruppo__c IN :groupIds
                    AND Data_Ora_Inizio__c <= :currentDatetime AND Data_Ora_Fine__c >= :currentDatetime];
            
        }
        
        return [SELECT COUNT() FROM Domanda_Questionario__c 
                WHERE Id NOT IN (SELECT Domanda_questionario__c FROM Risposta_questionario__c WHERE Utente__c = :userId) 
                AND Raggruppamento__r.Gruppo__c IN :groupIds /* AND Obbligatoria__c = true */ AND Obbligatoria_Per_Risultati__c != null
                AND (Raggruppamento__r.Visualizzabile_Da_Dealer_In__c = :target OR Raggruppamento__r.Genitore__r.Visualizzabile_Da_Dealer_In__c = :target)
                AND Data_Ora_Inizio__c <= :currentDatetime AND Data_Ora_Fine__c >= :currentDatetime];
        
    }
    
    private static List<Domanda_Questionario__c> findQuestionsByGroupIds(Set<Id> groupIds, Id userId){
        
        Datetime currentDatetime = System.now();
        
        return [SELECT Id, Etichetta_IT__c, Domanda_IT__c, Questionario__c, Raggruppamento__c, Albero__c, Tipologia__c, Obbligatoria__c,
                Suggerimento__c, Data_Ora_Inizio__c, Data_Ora_Fine__c, Visibile__c, Considerare__c, Ordine__c, Insieme_Opzioni_Domanda__c,
                (SELECT Id, Utente__c FROM Risposte_questionario__r), Raggruppamento__r.Gruppo__r.Name, Raggruppamento__r.Gruppo__r.Colore__c
                FROM Domanda_Questionario__c 
                WHERE Id NOT IN (SELECT Domanda_questionario__c FROM Risposta_questionario__c WHERE Utente__c = :userId) 
                AND Raggruppamento__r.Gruppo__c IN :groupIds
                AND Data_Ora_Inizio__c <= :currentDatetime AND Data_Ora_Fine__c >= :currentDatetime
                ORDER BY Priorita__c ASC, Data_Ora_Inizio__c ASC, Ordine__c ASC];
        
    }
    
    public static List<Domanda_Questionario__c> getCurrentQuestionsByGroupIds(Set<Id> groupsIds){
        
        Datetime currentDatetime = System.now();
        
        List<Gruppo__c> groups = [SELECT Id, Gruppo_Master__c FROM Gruppo__c WHERE Id IN :groupsIds];
        
        for(Gruppo__c g : groups){
            if(g.Gruppo_Master__c != null){
                groupsIds.add(g.Gruppo_Master__c);
            }
        }
        
        return [SELECT Id, Etichetta_IT__c, Domanda_IT__c, Questionario__c, Raggruppamento__c, Albero__c, Tipologia__c, Obbligatoria__c,
                Suggerimento__c, Data_Ora_Inizio__c, Data_Ora_Fine__c, Visibile__c, Considerare__c, Ordine__c, Insieme_Opzioni_Domanda__c,
                (SELECT Id, Utente__c, Valore_Numerico__c FROM Risposte_questionario__r), Raggruppamento__r.Gruppo__r.Name, Raggruppamento__r.Gruppo__r.Colore__c, Raggruppamento__r.Etichetta_IT__c
                FROM Domanda_Questionario__c 
                WHERE Raggruppamento__r.Gruppo__c IN :groupsIds
                AND Data_Ora_Inizio__c <= :currentDatetime AND Data_Ora_Fine__c >= :currentDatetime
                ORDER BY Priorita__c ASC, Data_Ora_Inizio__c ASC, Ordine__c ASC];
        
    }
    
    public static List<Domanda_Questionario__c> getCurrentQuestionsByGroupIdsAndUserPermissions(Set<Id> groupsIds, List<String> userPermissions){
        
        Datetime currentDatetime = System.now();
        
        List<Gruppo__c> groups = [SELECT Id, Gruppo_Master__c FROM Gruppo__c WHERE Id IN :groupsIds];
        
        for(Gruppo__c g : groups){
            if(g.Gruppo_Master__c != null){
                groupsIds.add(g.Gruppo_Master__c);
            }
        }
        
        return [SELECT Id, Etichetta_IT__c, Domanda_IT__c, Questionario__c, Raggruppamento__c, Albero__c, Tipologia__c, Obbligatoria__c,
                Suggerimento__c, Data_Ora_Inizio__c, Data_Ora_Fine__c, Visibile__c, Considerare__c, Ordine__c, Insieme_Opzioni_Domanda__c,
                (SELECT Id, Utente__c, Valore_Numerico__c FROM Risposte_questionario__r), Raggruppamento__r.Gruppo__r.Name, Raggruppamento__r.Gruppo__r.Colore__c, Raggruppamento__r.Etichetta_IT__c
                FROM Domanda_Questionario__c 
                WHERE Raggruppamento__r.Gruppo__c IN :groupsIds
                AND Data_Ora_Inizio__c <= :currentDatetime AND Data_Ora_Fine__c >= :currentDatetime
                AND Raggruppamento__r.Azienda_Permessi_Visualizzazione__c IN :userPermissions
                ORDER BY Priorita__c ASC, Data_Ora_Inizio__c ASC, Ordine__c ASC];
        
    }

}