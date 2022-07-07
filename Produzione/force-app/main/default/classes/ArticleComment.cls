public class ArticleComment {
    
    public String text;
    public String user;
    
    public ArticleComment(Utente_Articolo__c userArticle){
        
        this.user = userArticle.Utente__r.Nome__c + ' ' + userArticle.Utente__r.Cognome__c;
        this.text = userArticle.Testo__c;
        
    }
    
}