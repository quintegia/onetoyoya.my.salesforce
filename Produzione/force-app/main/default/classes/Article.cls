public class Article {
    
    public String id;
    public String author;
    public String title;
    public String excerpt;
    public String content;
    public String imageUrl;
    public String imageLink;
    public Long publishedDateTime;
    public List<String> tags = new List<String>();
    public List<String> brands = new List<String>();
    public List<ArticleComment> comments = new List<ArticleComment>();
    public List<ArticleLike> likes = new List<ArticleLike>();
    public List<ArticleView> views = new List<ArticleView>();
    public List<String> areas = new List<String>();
    public List<String> menu = new List<String>();
    public String attachment1;
    
    public Article(Articolo__c article){
        
        this.id = article.Id;
        this.author = article.Autore__r.Nome__c + ' ' + article.Autore__r.Cognome__c;
        this.title = article.Titolo__c;
        this.excerpt = article.Riassunto__c;
        this.content = article.Contenuto__c;
        this.imageUrl = article.Immagine_Di_Copertina__c;
        this.imageLink = article.Link_Immagine_Di_Copertina__c;
        this.publishedDateTime = article.Data_Ora_Pubblicazione__c.getTime();
        this.tags = article.Tag__c != null ? article.Tag__c.split(',') : tags;
        this.areas = article.Area__c != null ? article.Area__c.split(';') : areas;
        this.menu = article.Menu__c != null ? article.Menu__c.split(';') : menu;
        this.attachment1 = article.Allegato_1__c;
        
        for(Gruppo_Articolo__c articleGroup : article.Gruppi_Articoli__r){
            
            this.brands.add(articleGroup.Gruppo__r.Name);
            
        }
        
        for(Utente_Articolo__c userArticle : article.Utenti_Articoli__r){
            
            if('Commento'.equals(userArticle.Tipologia__c)){
                
                this.comments.add(new ArticleComment(userArticle));
                
            }else if('Like'.equals(userArticle.Tipologia__c)){
                
                this.likes.add(new ArticleLike(userArticle));
                
            }else if('Visualizzazione'.equals(userArticle.Tipologia__c)){
                
                this.views.add(new ArticleView(userArticle));
                
            }
            
        }
        
    }
    
}