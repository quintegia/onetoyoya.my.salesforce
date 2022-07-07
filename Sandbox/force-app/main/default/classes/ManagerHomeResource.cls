@RestResource(urlMapping='/manager_home/*')
global class ManagerHomeResource {
    
    @HttpGet
    global static void doGet(){
        
        CustomAuthentication ca = new CustomAuthentication(RestContext.request, RestContext.response);
        
        if(!ca.authenticate()){
             
            ca.getResponse().send();
            
            return;
            
        } 
        
        CustomResponse res = new CustomResponse(RestContext.response);
        
        Utente__c u = ca.getUser();
        List<String> userPermissions = u.Azienda_Permessi_Visualizzazione__c != null ? u.Azienda_Permessi_Visualizzazione__c.split(';') : new List<String>();
        
        List<Gruppo__c> childGroups = UserResource.getUserGroupChildren(u.Id);
        List<Gruppo__c> parentGroups = UserResource.getUserGroupAncestors(u.Id);
        
        Set<Id> groupsIds = new Set<Id>();
        Set<Id> parentGroupsIds = new Set<Id>();
        Set<Id> allGroupsIds = new Set<Id>();
        
        for(Gruppo__c g : childGroups){
            
            groupsIds.add(g.Id);
            if(g.Gruppo_Master__c != null){
                groupsIds.add(g.Gruppo_Master__c);
            }
            
        }
        
        allGroupsIds.addAll(groupsIds);
        
        for(Gruppo__c g : parentGroups){
            
            parentGroupsIds.add(g.Id);
            if(g.Gruppo_Master__c != null){
                parentGroupsIds.add(g.Gruppo_Master__c);
            }
            
        }
        
        allGroupsIds.addAll(parentGroupsIds);
        
        List<Utente_Gruppo__c> usersGroups = UserResource.getActiveUsersGroupsByGroupsIds(groupsIds);
        
        List<Object> widgets = new List<Object>();
        
        widgets.add(getMapData(u, groupsIds, usersGroups, userPermissions));
        widgets.add(getContentsData(u, groupsIds, userPermissions));
        widgets.add(getQuestionsData(u, allGroupsIds, usersGroups, userPermissions));
        widgets.add(getLastestCommentsData(u, groupsIds, usersGroups, userPermissions));
        widgets.add(getAppInfoData(u, groupsIds, usersGroups, userPermissions));
        widgets.add(getLastestInsightsData(u, groupsIds, usersGroups, userPermissions));
        
        res.setBody(widgets);
        res.setStatusCode(200);
        res.send();
        
    }
    
    private static List<Domanda_questionario__c> getBusinessAndMotivationQuestions(Set<Id> groupsIds, List<String> userPermissions, DateTime fromDateTime, DateTime toDateTime){
        
        List<Domanda_questionario__c> questions = [SELECT Id, Raggruppamento__r.Genitore__r.Etichetta_IT__c 
                                                   FROM Domanda_questionario__c 
                                                   WHERE Raggruppamento__r.Genitore__r.Tipologia__c = 'Indice' AND 
                                                   Raggruppamento__r.Genitore__r.Visualizzabile_Da_Manager_In__c = 'Dealer Map' 
                                                   //AND Data_Ora_Fine__c >= :System.now().addMonths(-6) AND Data_Ora_Fine__c <= :System.now()
                                                   AND Raggruppamento__r.Azienda_Permessi_Visualizzazione__c IN :userPermissions
                                                   AND Data_Ora_Inizio_Analisi__c >= :fromDateTime AND Data_Ora_Inizio_Analisi__c <= :toDateTime
                                                   ORDER BY Data_Ora_Fine__c DESC];
        
        return questions;
        
    }
    
    private static List<Risposta_questionario__c> getAnswersByQuestionsAndUsers(List<Domanda_questionario__c> questions, Set<Id> usersIds, List<String> userPermissions){
        
        return [SELECT Id, Utente__c, Domanda_questionario__r.Raggruppamento__r.Genitore__c, Valore_Numerico__c, Domanda_questionario__r.Raggruppamento__r.Genitore__r.Etichetta_Ridotta_IT__c,
                Domanda_questionario__r.Raggruppamento__r.Gruppo__c, Domanda_questionario__r.Raggruppamento__r.Gruppo__r.Name, Domanda_questionario__c, Domanda_questionario__r.Raggruppamento__c,
                Domanda_questionario__r.Raggruppamento__r.Ordine_Risultati_Manager__c, Domanda_questionario__r.Data_Ora_Inizio__c, Domanda_questionario__r.Data_Ora_Fine__c,
                Domanda_questionario__r.Raggruppamento__r.Genitore__r.Etichetta_Ridotta_EN__c, Domanda_questionario__r.Raggruppamento__r.Peso_Genitore__c,
                Domanda_questionario__r.Data_Ora_Inizio_Analisi__c, Domanda_questionario__r.Data_Ora_Fine_Analisi__c
                FROM Risposta_questionario__c 
                WHERE Domanda_questionario__c = :questions AND Utente__c IN :usersIds
                AND Domanda_questionario__r.Raggruppamento__r.Azienda_Permessi_Visualizzazione__c IN :userPermissions
                AND (Risposta_questionario__c.Valore_Numerico__c != null OR Risposta_questionario__c.Valore_Testuale__c != null)
                AND Utente__r.Non_Considerare_Analisi__c = false
                ORDER BY Domanda_questionario__r.Raggruppamento__r.Gruppo__r.Ordine__c ASC, Domanda_questionario__r.Data_Ora_Fine__c DESC];
        
    }
    
    private static List<Risposta_questionario__c> getCommentsByUsers(Set<Id> usersIds, List<String> userPermissions){
        
        List<Risposta_questionario__c> answers =  [SELECT Id, Utente__c, Domanda_questionario__r.Raggruppamento__r.Genitore__c, Valore_Numerico__c, 
                                                   Domanda_questionario__r.Raggruppamento__r.Genitore__r.Etichetta_Ridotta_IT__c,
                                                   Domanda_questionario__r.Raggruppamento__r.Gruppo__c, Domanda_questionario__r.Raggruppamento__r.Gruppo__r.Name, 
                                                   Domanda_questionario__c, Domanda_questionario__r.Raggruppamento__c, 
                                                   Domanda_questionario__r.Raggruppamento__r.Ordine_Risultati_Manager__c, Domanda_questionario__r.Data_Ora_Inizio__c, 
                                                   Domanda_questionario__r.Data_Ora_Fine__c, Domanda_questionario__r.Raggruppamento__r.Genitore__r.Etichetta_Ridotta_EN__c, 
                                                   Valore_Testuale_Lungo__c, Domanda_questionario__r.Domanda_IT__c, Utente__r.Nome__c, Utente__r.Cognome__c,
                                                   Data_Ora_Risposta__c, Utente__r.Ragione_Sociale__c
                                                   FROM Risposta_questionario__c 
                                                   WHERE Utente__c IN :usersIds AND Data_Ora_Risposta__c >= :System.now().addDays(-15)
                                                   AND Domanda_questionario__r.Raggruppamento__r.Azienda_Permessi_Visualizzazione__c IN :userPermissions
                                                   ORDER BY Data_Ora_Risposta__c DESC];
        
        List<Risposta_questionario__c> comments = new List<Risposta_questionario__c>();
        
        for(Risposta_questionario__c a : answers){
            
            if(a.Valore_Testuale_Lungo__c != null && a.Valore_Testuale_Lungo__c.length() > 1 && comments.size() < 10){
                
                comments.add(a);
                
            }
            
        }
        
        return comments;
        
    }
    
    private static List<Accesso__c> getUsersAccesses(Set<Id> usersIds){
        
        return [SELECT Id, Utente__c, Utente__r.Nome__c, Utente__r.Cognome__c, Utente__r.Ragione_Sociale__c, CreatedDate
                FROM Accesso__c 
                WHERE Utente__c IN :usersIds AND Utente__r.Non_Considerare_Analisi__c = false AND CreatedDate >= :System.now().addMonths(-1)
                ORDER BY CreatedDate DESC];
        
    }
    
    private static Map<String, Object> getMapData(Utente__c u, Set<Id> groupsIds, List<Utente_Gruppo__c> usersGroups, List<String> userPermissions){
        
        List<Object> out = new List<Object>();
        
        List<QCustomPeriod> periods = new List<QCustomPeriod>();
        List<Double> percents = new List<Double>();
        
        percents.add(0.5);
        percents.add(0.3);
        percents.add(0.2);
        
        Boolean newQuestions = QuestionResource.thereAreNewQuestions(groupsIds, 'Dealer Map');
        
        QCustomPeriod startPeriod = new QCustomPeriod(newQuestions, percents[0]);
        periods.add(startPeriod);
        
        for(Integer i = 1; i < percents.size(); i++){
            
            periods.add(periods.get(i - 1).getPrevious(percents[i]));
            
        }            
        
        List<Domanda_questionario__c> questions = getBusinessAndMotivationQuestions(groupsIds, userPermissions, periods[periods.size() - 1].startDateTime, periods[0].endDateTime);
        
        Set<Id> usersIds = new Set<Id>();
        
        for(Utente_Gruppo__c ug: usersGroups){
            
            usersIds.add(ug.Utente__c);
            
		}
        
        List<Risposta_questionario__c> answers = getAnswersByQuestionsAndUsers(questions, usersIds, userPermissions);
        
        Map<String, Decimal> sum = new Map<String, Decimal>();
        Map<String, Decimal> count = new Map<String, Decimal>();
        Map<String, String> labels = new Map<String, String>();
        Map<String, String> brands = new Map<String, String>();
        Map<String, Decimal> groupingsOrders = new Map<String, Decimal>();
        Map<String, String> groupingsIds = new Map<String, String>();
        Map<String, String> groupingsQuestions = new Map<String, String>();
        Map<String, Set<String>> groupingsQuestionsMap = new Map<String, Set<String>>();
        
        DateTime oldestQuestionDate = periods[periods.size() - 1].startDateTime;
        DateTime newestQuestionDate = periods[0].endDateTime;
        
        System.debug(answers.size());
        
        for(Risposta_questionario__c a : answers){
                        
            for(QCustomPeriod p : periods){
                
                if(!((a.Domanda_questionario__r.Data_Ora_Inizio_Analisi__c < p.startDateTime && a.Domanda_questionario__r.Data_Ora_Fine_Analisi__c < p.startDateTime) || 
                     (a.Domanda_questionario__r.Data_Ora_Inizio_Analisi__c > p.endDateTime && a.Domanda_questionario__r.Data_Ora_Fine_Analisi__c > p.endDateTime))){
                         
                         /*if(!groupingsQuestions.containsKey(a.Domanda_questionario__r.Raggruppamento__c)){
                             groupingsQuestions.put(a.Domanda_questionario__r.Raggruppamento__c, a.Domanda_questionario__c);
                         }*/
                         
                         if(!groupingsQuestionsMap.containsKey(a.Domanda_questionario__r.Raggruppamento__c)){
                             groupingsQuestionsMap.put(a.Domanda_questionario__r.Raggruppamento__c, new Set<String>());
                         }
                         
                         groupingsQuestionsMap.get(a.Domanda_questionario__r.Raggruppamento__c).add(a.Domanda_questionario__c);
                         
                         //if(groupingsQuestions.get(a.Domanda_questionario__r.Raggruppamento__c) == a.Domanda_questionario__c){
                         if(groupingsQuestionsMap.get(a.Domanda_questionario__r.Raggruppamento__c).contains(a.Domanda_questionario__c)){
                             
                             String key = a.Domanda_questionario__r.Raggruppamento__r.Genitore__c;                
                             String label = a.Domanda_questionario__r.Raggruppamento__r.Genitore__r.Etichetta_Ridotta_EN__c;
                             String brandId = a.Domanda_questionario__r.Raggruppamento__r.Gruppo__c;
                             String brand = a.Domanda_questionario__r.Raggruppamento__r.Gruppo__r.Name;
                             Decimal groupingOrder = a.Domanda_questionario__r.Raggruppamento__r.Ordine_Risultati_Manager__c;
                             
                             key += brandId;
                             
                             if(!groupingsIds.containsKey(key)){
                                 groupingsIds.put(key, a.Domanda_questionario__r.Raggruppamento__r.Genitore__c);
                             }                
                             
                             if(!sum.containsKey(key)){
                                 sum.put(key, 0);
                             }
                             
                             if(!count.containsKey(key)){
                                 count.put(key, 0);
                             }
                             
                             groupingsOrders.put(key, groupingOrder);
                             labels.put(key, label);
                             brands.put(key, brand);
                             
                             sum.put(key, sum.get(key) + (a.Valore_Numerico__c * a.Domanda_questionario__r.Raggruppamento__r.Peso_Genitore__c * p.weight));
                             count.put(key, count.get(key) + (a.Domanda_questionario__r.Raggruppamento__r.Peso_Genitore__c * p.weight));
                             
                             //sum.put(key, sum.get(key) + a.Valore_Numerico__c);
                             //count.put(key, count.get(key) + 1);
                             
                         }
                         
                     }          
                
            }
            
        }
            
        System.debug(sum);
        System.debug(count);
        System.debug(labels);
        System.debug(brands);
        
        for(String k : sum.keySet()){
            
            Map<String, Object> o = new Map<String, Object>();
            
            o.put('id', k);
            o.put('groupingId', groupingsIds.get(k));
            o.put('groupingOrder', groupingsOrders.get(k));
            o.put('label', labels.get(k));
            o.put('brand', brands.get(k));
            o.put('avg', ManagerDashboardResource.transpose(Double.valueOf(sum.get(k) / count.get(k))));            
            
            out.add(o);
            
        }
        
        Map<String, Object> extra = new Map<String, Object>();
        
        extra.put('title_it', 'Media indicatori Dealer Map');
        if(oldestQuestionDate != null){
            extra.put('period_start_time', oldestQuestionDate.getTime());
        }
        if(oldestQuestionDate != null){
            extra.put('period_end_time', newestQuestionDate.getTime());
        }
        
        String descriptionIt = '';
        
        if(oldestQuestionDate != null && newestQuestionDate != null){
        
        	extra.put('description_it', 'Media dealer di competenza periodo\ndal ' + RCCUtils.dateFormat(oldestQuestionDate.date()) + ' al ' + RCCUtils.dateFormat(newestQuestionDate.date()));
        
        }
        
        return new Map<String, Object>{'type' => 'map', 'data' => out, 'extra' => extra};
        
    }
    
    private static Map<String, Object> getContentsData(Utente__c u, Set<Id> groupsIds, List<String> userPermissions){
                
        List<Object> out = new List<Object>();
        
        List<Articolo__c> contents = new List<Articolo__c>();        
        List<String> sections = new List<String>();
        
        contents.add(ArticleResource.getLatestContent(u.Id, groupsIds));
        
        if(contents.size() > 0){
            sections.add('La news più recente');
        }
        
        contents.addAll(ArticleResource.getMostLikedAndViwedContents(u.Id, groupsIds));
        
        if(contents.size() > 1){
            sections.add('La news con più like');
            sections.add('La news più vista');
        }
        
        Integer counter = 0;
        
        for(Articolo__c c : contents){
            
            if(c != null){
                
                Map<String, Object> content = new Map<String, Object>();
                
                Integer likes = 0;
                Integer views = 0;
                
                for(Utente_Articolo__c uc : c.Utenti_Articoli__r){
                    
                    if('Like'.equals(uc.Tipologia__c)){
                        likes++;
                    }else if('Visualizzazione'.equals(uc.Tipologia__c)){
                        views++;
                    }
                    
                }
                
                content.put('id', c.Id);
                content.put('section', sections[counter]);
                content.put('imageUrl', c.Immagine_Di_Copertina__c);
                content.put('title', c.Titolo__c);
                content.put('excerpt', c.Riassunto__c);
                content.put('likeCount', likes);
                content.put('viewCount', views);
                content.put('publishDate', c.Data_Ora_Pubblicazione__c.getTime());
                
                out.add(content);
                
            }
            
            counter++;
            
        }
        
        return new Map<String, Object>{'type' => 'contents', 'data' => out};
        
    }
    
    private static Map<String, Object> getQuestionsData(Utente__c u, Set<Id> groupsIds, List<Utente_Gruppo__c> usersGroups, List<String> userPermissions){        
                
        List<Domanda_questionario__c> questions = QuestionResource.getCurrentQuestionsByGroupIdsAndUserPermissions(groupsIds, userPermissions);
        List<Object> out = new List<Object>();
        Set<Id> usersIds = new Set<Id>();
        Map<Id, Integer> groupSize = new Map<Id, Integer>();
        
        for(Utente_Gruppo__c ug : usersGroups){
            
            usersIds.add(ug.Utente__c);
            
            if(!groupSize.containsKey(ug.Gruppo__r.Genitore__r.Genitore__c)){
            	groupSize.put(ug.Gruppo__r.Genitore__r.Genitore__c, 0);
            }
            
            groupSize.put(ug.Gruppo__r.Genitore__r.Genitore__c, groupSize.get(ug.Gruppo__r.Genitore__r.Genitore__c) + 1);
            
        }
        
        for(Domanda_questionario__c q : questions){
            
            Map<String, Object> question = new Map<String, Object>();
            
            Integer answeredCount = 0;      
            Integer size = groupSize.get(q.Raggruppamento__r.Gruppo__c);
            
            if(size == null || size == 0){
                
                size = usersIds.size();
                
            }
            
            Decimal partialAvg = 0;
            
            for(Risposta_questionario__c r : q.Risposte_questionario__r){
                
                if(usersIds.contains(r.Utente__c)){
                    answeredCount++;
                    partialAvg += r.Valore_Numerico__c;
                }
                
            }
            
            if(answeredCount != 0){
            
            	partialAvg /= answeredCount;
                
            }
            
            question.put('groupingLabel', q.Raggruppamento__r.Etichetta_IT__c);
            question.put('questionLabel', q.Domanda_IT__c);
            question.put('answeredCount', answeredCount);
            question.put('totalCount', size);
            question.put('partialAvg', ManagerDashboardResource.transpose(Double.valueOf(partialAvg)));
            question.put('brand', q.Raggruppamento__r.Gruppo__r.Name);
            
            out.add(question);
            
        }
        
        return new Map<String, Object>{'type' => 'questions', 'data' => out};
        
    }
    
    private static Map<String, Object> getLastestCommentsData(Utente__c u, Set<Id> groupsIds, List<Utente_Gruppo__c> usersGroups, List<String> userPermissions){
        
        List<Object> out = new List<Object>();
        Set<Id> usersIds = new Set<Id>();
        
        for(Utente_Gruppo__c ug : usersGroups){
            
            usersIds.add(ug.Utente__c);
            
        }
        
        List<Risposta_questionario__c> comments = getCommentsByUsers(usersIds, userPermissions);
        
        Map<Id, CommentsQuestion> commentsQuestionsMap = new Map<Id, CommentsQuestion>();
        
        List<CommentsQuestion> commentsQuestionList = new List<CommentsQuestion>();
        
        for(Risposta_questionario__c a : comments){
            
            CommentsQuestion current;
            
            if(!commentsQuestionsMap.containsKey(a.Domanda_questionario__r.Raggruppamento__c)){
                
                current = new CommentsQuestion(a.Domanda_questionario__r.Domanda_IT__c, a.Domanda_questionario__r.Raggruppamento__r.Gruppo__r.Name);
                commentsQuestionsMap.put(a.Domanda_questionario__r.Raggruppamento__c, current);
                
            }else{
                
                current = commentsQuestionsMap.get(a.Domanda_questionario__r.Raggruppamento__c);
                
            }
            
            current.comments.add(new CommentsComment(a.Valore_Testuale_Lungo__c, a.Utente__r.Nome__c + ' ' + a.Utente__r.Cognome__c, a.Utente__r.Ragione_Sociale__c, a.Domanda_questionario__r.Raggruppamento__r.Gruppo__r.Name, a.Valore_Numerico__c, a.Data_Ora_Risposta__c.getTime()));
                        
        }
        
        for(Id questionId : commentsQuestionsMap.keySet()){
            
            commentsQuestionList.add(commentsQuestionsMap.get(questionId));
            
        }
        
        return new Map<String, Object>{'type' => 'comments', 'data' => commentsQuestionList};
            
    }
    
    class CommentsQuestion{
        
        String label;
        String brand;
        List<CommentsComment> comments = new List<CommentsComment>();
        
        CommentsQuestion(String label, String brand){
            this.label = label;
            this.brand = brand;
        }
        
    }
    
    class CommentsComment{
        
        String comment;
        String name;
        String companyName;
        String brand;
        Decimal value;
        Long timestamp;
        
        CommentsComment(String comment, String name, String companyName, String brand, Decimal value, Long timestamp){
            
            this.comment = comment;
            this.name = name;
            this.companyName = companyName;
            this.brand = brand;
            this.value = value;
            this.timestamp = timestamp;
            
        }
        
    }
    
    private static Map<String, Object> getAppInfoData(Utente__c u, Set<Id> groupsIds, List<Utente_Gruppo__c> usersGroups, List<String> userPermissions){
        
        List<Object> out = new List<Object>();
        Set<Id> usersIds = new Set<Id>();
        
        for(Utente_Gruppo__c ug : usersGroups){
            
            usersIds.add(ug.Utente__c);
            
        }
        
        List<Accesso__c> usersAccessesList = getUsersAccesses(usersIds);
        Accesses accesses = new Accesses();
        
        accesses.total = usersIds.size();
        
        for(Accesso__c access : usersAccessesList){
            
            accesses.setAccess(access);         
            
        }
        
        return new Map<String, Object>{'type' => 'app_usage', 'data' => accesses};
            
    }
    
    class AccessUser{
        
        Id id;
        String firstName;
        String lastName;
        String companyName;
        Long lastAccess;
        
        AccessUser(Id id, String firstName, String lastName, String companyName, Long lastAccess){
            
            this.id = id;
            this.firstName = firstName;
            this.lastName = lastName;
            this.companyName = companyName;
            this.lastAccess = lastAccess;
            
        }
        
        
    }
    
    class Accesses{
        
        List<AccessUser> lastMonth;
        List<AccessUser> lastWeek;
        List<AccessUser> lastDay;
        Decimal total;
        
        Accesses(){
            
            this.lastMonth = new List<AccessUser>();
            this.lastWeek = new List<AccessUser>();
            this.lastDay = new List<AccessUser>();
            this.total = 0;
            
        }
        
        void setAccess(Accesso__c access){
            
            AccessUser user = new AccessUser(access.Utente__c, access.Utente__r.Nome__c, access.Utente__r.Cognome__c, access.Utente__r.Ragione_Sociale__c, access.CreatedDate.getTime());
            
            if(!userInList(access.Utente__c, lastMonth)){
                
                lastMonth.add(user);
                
            }
            
            if(!userInList(access.Utente__c, lastWeek) && access.CreatedDate > System.now().addDays(-7)){
                
                lastWeek.add(user);
                
            }
            
            if(!userInList(access.Utente__c, lastDay) && access.CreatedDate > System.now().addDays(-1)){
                
                lastDay.add(user);
                
            }
            
        }
        
        Boolean userInList(Id userId, List<AccessUser> userList){
            
            Boolean found = false;
            
            for(AccessUser u : userList){
                
                if(u.id == userId){
                    
                    found = true;
                    
                }
                
            }
            
            return found;
            
        }
        
    }
    
    private static Map<String, Object> getLastestInsightsData(Utente__c u, Set<Id> groupsIds, List<Utente_Gruppo__c> usersGroups, List<String> userPermissions){
        
        List<Object> out = new List<Object>();
        
        return new Map<String, Object>{'type' => 'insights', 'data' => out};
            
    }

}