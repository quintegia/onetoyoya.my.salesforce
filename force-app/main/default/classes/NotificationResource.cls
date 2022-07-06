@RestResource(urlMapping='/notifications/*')
global class NotificationResource {
    
    @HttpGet
    global static void doGet(){
        
        CustomAuthentication ca = new CustomAuthentication(RestContext.request, RestContext.response);
        
        if(!ca.authenticate()){
            
            ca.getResponse().send();
        
            return;
            
        }
        
        CustomResponse res = new CustomResponse(RestContext.response);
        
        Utente__c user = ca.getUser();
        
        List<NotificationData> notifications = new List<NotificationData>();
        
        Integer questionCount = QuestionResource.getUserQuestionsCountByUserId(user.Id, null);
        Integer contentsCount = ArticleResource.countAllUserArticles(user.Id);
        Integer contentsCovid19Count = ArticleResource.countAllUserCovid19Articles(user.Id);
        Integer countAllUserDocumentsArticles = ArticleResource.countAllUserDocumentsArticles(user.Id);
        
        if(user.Tipologia__c == 'Dealer' && user.Utente_Master__c == null){
        
        	notifications.add(new NotificationData('questions_screen', questionCount));
            
        }
        
        notifications.add(new NotificationData('articles_screen', contentsCount));
        notifications.add(new NotificationData('covid_19_screen', contentsCovid19Count));
        //notifications.add(new NotificationData('documents_screen', countAllUserDocumentsArticles));
        
        res.setBody(notifications);
        
        res.send();
        
    }

}