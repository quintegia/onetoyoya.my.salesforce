@RestResource(urlMapping='/articles/*')
global class ArticleResource{
    
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
        
        String action = RestContext.request.requestURI.substring(RestContext.request.requestURI.lastIndexOf('/') + 1);
        
        if('menu'.equalsIgnoreCase(action)){
            
            res.setBody(getUserArticlesMenu(userId));
            
        }else{
            
            if(String.isNotBlank(action)){
            
                try{
                    
                    Id articleId = action;
                    
                    Articolo__c article = findArticleById(articleId);
                    
                    res.setBody(new Article(article));
                    res.send();
                    
                    return;
                    
                }catch(Exception ex){}
                
            }
        
            Boolean featured = false;
            Boolean random = false;
            List<String> contentTypes = new List<String>{'Articolo'};
            String menu = null;
            Integer resultsLimit = 10;
            Integer resultsOffset = 0;
            
            try{
                
                featured = RestContext.request.params.get('featured') == 'true';
            	contentTypes = new List<String>{'Articolo'};
                
            }catch(Exception ex){ }
            
            try{
                
                String articleType = RestContext.request.params.get('type');
                
                if(articleType != null && String.isNotBlank(articleType)){
                    contentTypes = new List<String>{articleType};
                        if(articleType == 'Road2Tokyo'){
                            random = true;
                        }
                }
                
            }catch(Exception ex){ }
            
            try{
                
                if(RestContext.request.params.get('road2Tokyo') == 'true'){
                    contentTypes = new List<String>{'Road2Tokyo'};
                    random = true;
                }
                
            }catch(Exception ex){ }
            
            try{
                
                menu = RestContext.request.params.get('menu');
                
            }catch(Exception ex){ }
            
            try{
                
                resultsLimit = Integer.valueOf(RestContext.request.params.get('limit'));
                
            }catch(Exception ex){ }
            
            try{
                
                resultsOffset = Integer.valueOf(RestContext.request.params.get('offset'));
                
            }catch(Exception ex){ }
            
            String groupId;
            
            try{
                
                groupId = RestContext.request.params.get('groupId');
                
            }catch(Exception ex){ }
            
            List<Articolo__c> articles = findAllUserArticles(userId, featured, menu, resultsLimit, resultsOffset, contentTypes, random, groupId);
            List<Object> response = new List<Object>();
            
            for(Articolo__c article: articles){
                
                response.add(new Article(article));
                
            }
            
            res.setBody(response);
            
        }
        
        res.send();
        
    }
    
    @HttpPost
    global static void doPost(String action){
        
        CustomAuthentication ca = new CustomAuthentication(RestContext.request, RestContext.response);
        
        if(!ca.authenticate()){
            
            ca.getResponse().send();
        
            return;
            
        }
        
        String articleId = RestContext.request.requestURI.substring(RestContext.request.requestURI.lastIndexOf('/')+1);        
        
        CustomResponse res = new CustomResponse(RestContext.response);
        
        Id userId = ca.getUser().Id;
        
        if('view'.equals(action)){
            
            Integer userViews = [SELECT COUNT() FROM Utente_Articolo__c WHERE Articolo__c = :articleId AND Tipologia__c = 'Visualizzazione' AND Utente__c = :userId];
            
            if(userViews == 0 && articleId != null){
                
                Utente_Articolo__c userView = new Utente_Articolo__c();
                
                userView.Articolo__c = articleId;
                userView.Utente__c = userId;
                userView.Tipologia__c = 'Visualizzazione';
                
                if(!ca.isStealth()){
                    insert userView;
                }
                
            }
            
            List<Utente_Articolo__c> usersViews = [SELECT Id, Utente__r.Nome__c, Utente__r.Cognome__c, Utente__c, Articolo__c
                                                   FROM Utente_Articolo__c 
                                                   WHERE Articolo__c = :articleId AND Tipologia__c = 'Visualizzazione' AND Utente__r.Utente_Demo__c = false];
        
            List<ArticleView> response = new List<ArticleView>();
            
            for(Utente_articolo__c userView : usersViews){
                
                response.add(new ArticleView(userView));
                
            }
            
            res.setBody(response);
            
            res.send();
            
            return;
            
        }else if('like'.equals(action) && articleId != null){
            
            try{
                
                Utente_Articolo__c userLike = [SELECT Id FROM Utente_Articolo__c WHERE Articolo__c = :articleId AND Tipologia__c = 'Like' AND Utente__c = :userId LIMIT 1];
                
                
                if(!ca.isStealth()){
                    
                    delete userLike;
                    
                }
                
            }catch(Exception ex){
                
                Utente_Articolo__c userLike = new Utente_Articolo__c();
                
                userLike.Articolo__c = articleId;
                userLike.Utente__c = userId;
                userLike.Tipologia__c = 'Like';
                
                if(!ca.isStealth()){
                    insert userLike;
                }
                
            }
            
            List<Utente_Articolo__c> usersLikes = [SELECT Id, Utente__r.Nome__c, Utente__r.Cognome__c, Utente__c, Articolo__c
                                                   FROM Utente_Articolo__c 
                                                   WHERE Articolo__c = :articleId AND Tipologia__c = 'Like' AND Utente__r.Utente_Demo__c = false];
        
            List<ArticleLike> response = new List<ArticleLike>();
            
            for(Utente_articolo__c userLike : usersLikes){
                
                response.add(new ArticleLike(userLike));
                
            }
            
            res.setBody(response);
            
            res.send();
            
            return;
            
        }
        
        res.setStatusCode(500);
        res.setBody(new Map<String, Object>{'error' => 'Invalid Request.'});
        res.send();
        
        return;
        
    }
    
    static List<Articolo__c> findAllUserArticles(Id userId, Boolean featured, String menu, Integer resultsLimit, Integer resultsOffset, List<String> contentTypes, Boolean random, String groupId){
        
        Set<Id> groups = new Set<Id>();
        
        List<Gruppo__c> userGroups = UserResource.getAllRelatedUserGroups(userId);
        
        for(Gruppo__c g : userGroups){
            
            if(String.isNotBlank(groupId)){
                
                if(groupId == g.Id){
            
            		groups.add(g.Id);
                    
                }
                
            }else{
            
                groups.add(g.Id);
                
                if(g.Gruppo_Master__c != null){
                    
                    groups.add(g.Gruppo_Master__c);
                    
                }
                
            }
            
        }
        
        //Set<Id> groups = RCCUtils.findUserGroupsByUserId(userId, false);
        Datetime currentDateTime = System.now();
        
        if(contentTypes == null || contentTypes.size() == 0){
            contentTypes = new List<String>{ 'Articolo' };
        }
        
        String query = 'SELECT Id, Autore__r.Nome__c, Autore__r.Cognome__c, Titolo__c, Contenuto__c, Immagine_Di_Copertina__c, Area__c, Menu__c, '
            + 'Data_Ora_Pubblicazione__c, Tag__c, Riassunto__c, Link_Immagine_Di_Copertina__c, '
            + '(SELECT Id, Genitore__c, Pubblico__c, Testo__c, Tipologia__c, Utente__c, Articolo__c, Utente__r.Nome__c, Utente__r.Cognome__c FROM Utenti_Articoli__r WHERE Tipologia__c IN (\'Like\', \'Visualizzazione\') AND (NOT Utente__r.Ragione_Sociale__c  LIKE \'%quintegia%\')), '
            + '(SELECT Id, Gruppo__r.Name FROM Gruppi_Articoli__r), Allegato_1__c '
            + 'FROM Articolo__c '
            + 'WHERE Id IN (SELECT Articolo__c FROM Gruppo_Articolo__c WHERE Gruppo__c IN :groups) AND Data_Ora_Pubblicazione__c <= :currentDateTime '
            + 'AND Tipologia__c IN :contentTypes ';
        
        if(featured){
            
            query += 'AND In_Evidenza_Fino_A__c >= :currentDateTime ';
            
        }
        
        if(String.isNotBlank(menu)){
            
            query += 'AND Menu__c includes(:menu) ';
            
        }
        
        if(!random){
        
        	query += 'ORDER BY Data_Ora_Pubblicazione__c DESC LIMIT :resultsLimit OFFSET :resultsOffset';
            
        }
        
        List<Articolo__c> contents = Database.query(query);
        
        if(random && contents.size() > 1){
            contents = (List<Articolo__c>) shuffle(contents);
        }
        
        return contents;
        
    }
    
    public static List<Object> shuffle(List<Object> objectList){
     
        Object obj;
        integer randomIndex;
        integer currentIndex = objectList.size();
         
        while (currentIndex != 0) {
            randomIndex = integer.valueOf(Math.floor(Math.random() * currentIndex));
            currentIndex -= 1;
            obj = objectList[currentIndex];
            objectList[currentIndex] = objectList[randomIndex];
            objectList[randomIndex] = obj;
        }
        
        return objectList;
    }
    
    public static Articolo__c findArticleById(Id articleId){
        
        try{
            
            return [SELECT Id, Autore__r.Nome__c, Autore__r.Cognome__c, Titolo__c, Contenuto__c, Immagine_Di_Copertina__c, Area__c, Menu__c,
                    Data_Ora_Pubblicazione__c, Tag__c, Riassunto__c, Link_Immagine_Di_Copertina__c,
                    (SELECT Id, Genitore__c, Pubblico__c, Testo__c, Tipologia__c, Utente__c, Articolo__c, Utente__r.Nome__c, Utente__r.Cognome__c FROM Utenti_Articoli__r), 
                    Allegato_1__c
                    FROM Articolo__c WHERE Id = :articleId];
            
        }catch(Exception ex){
            return null;
        }
        
    }
    
    private static List<String> getUserArticlesMenu(Id userId){
        
        List<String> menuItems = new List<String>{};
        
        Set<Id> groups = new Set<Id>();
        
        List<Gruppo__c> userGroups = UserResource.getAllRelatedUserGroups(userId);
        
        for(Gruppo__c g : userGroups){
            
            groups.add(g.Id);
            
            if(g.Gruppo_Master__c != null){
                
            	groups.add(g.Gruppo_Master__c);
                
            }
            
        }
        
        //Set<Id> groups = RCCUtils.findUserGroupsByUserId(userId, false);
        Datetime currentDateTime = System.now();
        
        List<Articolo__c> articles = [SELECT Menu__c
                                      FROM Articolo__c 
                                      WHERE Id IN (SELECT Articolo__c FROM Gruppo_Articolo__c WHERE Gruppo__c IN :groups) AND Tipologia__c = 'Articolo'
                                      AND Data_Ora_Pubblicazione__c <= :currentDateTime];
        
        for(Articolo__c a : articles){
            
            List<String> labels = a.Menu__c.split(';');
            
            for(String l : labels){
                
                if(!menuItems.contains(l)){
                    
                    menuItems.add(l);
                    
                }
                
            }
            
        }
        
        return menuItems;
        
    }
    
    public static Integer countAllUserArticles(Id userId){
        
        return countAllUserArticlesByType(userId, new Set<String>{'Articolo'});
        
    }
    
    public static Integer countAllUserCovid19Articles(Id userId){
        
        return countAllUserArticlesByType(userId, new Set<String>{'COVID19'});
        
    }
    
    public static Integer countAllUserDocumentsArticles(Id userId){
        
        return countAllUserArticlesByType(userId, new Set<String>{'Circolare'});
        
    }
    
    public static Integer countAllUserArticlesByType(Id userId, Set<String> articlesTypes){
        
        Set<Id> groups = new Set<Id>();
        
        List<Gruppo__c> userGroups = UserResource.getAllRelatedUserGroups(userId);
        
        for(Gruppo__c g : userGroups){
            
            groups.add(g.Id);
            
            if(g.Gruppo_Master__c != null){
                
            	groups.add(g.Gruppo_Master__c);
                
            }
            
        }
        
        //Set<Id> groups = RCCUtils.findUserGroupsByUserId(userId, false);
        
        return [SELECT COUNT()
                FROM Articolo__c
                WHERE Id NOT IN (SELECT Articolo__c FROM Utente_Articolo__c WHERE Utente__c = :userId)
                AND Id IN (SELECT Articolo__c FROM Gruppo_Articolo__c WHERE Gruppo__c IN :groups)
                AND Data_Ora_Pubblicazione__c >= :System.now().addMonths(-1) AND Data_Ora_Pubblicazione__c <= :System.now()
                AND Tipologia__c IN :articlesTypes];
        
    }
    
    public static Articolo__c getLatestContent(Id userId, Set<Id> groupsIds){
        
        List<Gruppo__c> groups = [SELECT Id, Gruppo_Master__c FROM Gruppo__c WHERE Id IN :groupsIds];
        
        for(Gruppo__c g : groups){
            if(g.Gruppo_Master__c != null){
                groupsIds.add(g.Gruppo_Master__c);
            }
        }
        
        try{
            
            return [SELECT Id, Autore__r.Nome__c, Autore__r.Cognome__c, Titolo__c, Contenuto__c, Immagine_Di_Copertina__c, Area__c, Menu__c, 
                    Data_Ora_Pubblicazione__c, Tag__c, Riassunto__c, Link_Immagine_Di_Copertina__c,
                    (SELECT Id, Tipologia__c FROM Utenti_Articoli__r WHERE Tipologia__c IN ('Like', 'Visualizzazione') AND (NOT Utente__r.Ragione_Sociale__c  LIKE '%quintegia%') AND Utente__r.Utente_Demo__c = false), 
                    Allegato_1__c
                    FROM Articolo__c
                    WHERE Id IN (SELECT Articolo__c FROM Gruppo_Articolo__c WHERE Gruppo__c IN :groupsIds)
                    AND Tipologia__c IN ('Articolo', 'COVID19') AND Data_Ora_Pubblicazione__c <= :System.now()
                    ORDER BY Data_Ora_Pubblicazione__c DESC
                    LIMIT 1];
            
        }catch(Exception ex){
            return null;
        }
        
    }
    
    public static List<Articolo__c> getMostLikedAndViwedContents(Id userId, Set<Id> groupsIds){
        
        Articolo__c mostViewedContent;
        Articolo__c mostLikedContent;
        
        List<Articolo__c> contents =  [SELECT Id, Autore__r.Nome__c, Autore__r.Cognome__c, Titolo__c, Contenuto__c, Immagine_Di_Copertina__c, Area__c, Menu__c, 
                                       Data_Ora_Pubblicazione__c, Tag__c, Riassunto__c, Link_Immagine_Di_Copertina__c,
                                       (SELECT Id, Tipologia__c FROM Utenti_Articoli__r  WHERE Tipologia__c IN ('Like', 'Visualizzazione') AND (NOT Utente__r.Ragione_Sociale__c  LIKE '%quintegia%') AND Utente__r.Utente_Demo__c = false)
                                       FROM Articolo__c
                                       WHERE Id IN (SELECT Articolo__c FROM Gruppo_Articolo__c WHERE Gruppo__c IN :groupsIds)
                                       AND Tipologia__c = 'Articolo' AND Data_Ora_Pubblicazione__c <= :System.now()
                                       ORDER BY Data_Ora_Pubblicazione__c];
        
        Integer likes = 0;
        Integer views = 0;
        
        for(Articolo__c c : contents){
            
            Integer contentLikes = 0;
            Integer contentViews = 0;
            
            for(Utente_Articolo__c uc : c.Utenti_Articoli__r){
                
                if('Like'.equals(uc.Tipologia__c)){
                    contentLikes++;
                }else if('Visualizzazione'.equals(uc.Tipologia__c)){
                    contentViews++;
                }
                
            }
            
            if(contentLikes >= likes){
                likes = contentLikes;
                mostLikedContent = c;
            }
            
            if(contentViews >= views){
                views = contentViews;
                mostViewedContent = c;
            }
            
        }
        
        return new List<Articolo__c>{ mostLikedContent, mostViewedContent };
        
    }

}