public class ArticleView {
    
    public String user; 
    public String userId;
    public String articleId;       
    
    public ArticleView(Utente_Articolo__c userArticle){
        
        this.user = userArticle.Utente__r.Nome__c + ' ' + userArticle.Utente__r.Cognome__c;
        this.userId = userArticle.Utente__c;
        this.articleId = userArticle.Articolo__c;
        
    }

}