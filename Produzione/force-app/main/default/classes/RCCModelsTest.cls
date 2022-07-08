@isTest
public class RCCModelsTest {
    
    @testSetup
    static void setup(){
        
        TMI_RCC__c settings = new TMI_RCC__c();
        
        settings.Secret_Key__c = 'secret';
        
        insert settings;
        
        App__c app = new App__c();
        
        insert app;
        
        Utente__c user = new Utente__c();
        
        user.Nickname__c = 'nickname';
        user.Password__c = 'password';
        user.App__c = app.Id;
        
        insert user;
        
        Gruppo__c mainGroup = new Gruppo__c();
        
        mainGroup.Name = 'Main';
        
        insert mainGroup;
        
        Gruppo__c brandGroup = new Gruppo__c();
        
        brandGroup.Name = 'Brand 1';
        brandGroup.Tipologia__c = 'Marchio';
        brandGroup.Genitore__c = mainGroup.Id;
        
        insert brandGroup;
        
        Gruppo__c zoneGroup = new Gruppo__c();
        
        zoneGroup.Name = 'Zone 1';
        zoneGroup.Tipologia__c = 'Zona';
        zoneGroup.Genitore__c = brandGroup.Id;
        
        insert zoneGroup;
        
        Utente_Gruppo__c userGroup = new Utente_Gruppo__c();
        
        userGroup.Utente__c = user.Id;
        userGroup.Gruppo__c = zoneGroup.Id;
        
        insert userGroup;
        
    }
    
    static App__c getApp(){
        
        return [SELECT Id FROM App__c LIMIT 1];
        
    }
    
    static Utente__c getUser(){
        
        return [SELECT Id FROM Utente__c LIMIT 1];
        
    }
    
    static Gruppo__c getGroup(){
        
        return [SELECT Id FROM Gruppo__c LIMIT 1];
        
    }
    
    @isTest
    static void testAppInfoData(){
        
        AppInfoData appInfoData = new AppInfoData();
        
    }
    
    @isTest
    static void testUserData(){
        
        UserData userData = new UserData();
        
    }
    
    @isTest
    static void testArticle(){
        
        Utente__c user = getUser();
        
        Articolo__c newArticle = new Articolo__c();
        
        newArticle.Titolo__c = 'Titolo';
        newArticle.Contenuto__c = 'Contenuto';
        newArticle.Immagine_Di_Copertina__c = 'https://www.quintegia.it/test.png';
        newArticle.Data_Ora_Pubblicazione__c = System.now();
        newArticle.Tag__c = 'tag';
        newArticle.Autore__c = user.Id;
        
        insert newArticle;
        
        Gruppo_Articolo__c articleGroup = new Gruppo_Articolo__c();
        
        articleGroup.Articolo__c = newArticle.Id;
        articleGroup.Gruppo__c = getGroup().Id;
        
        insert articleGroup;
        
        Utente_Articolo__c userLike = new Utente_Articolo__c();
        
        userLike.Articolo__c = newArticle.Id;
        userLike.Tipologia__c = 'Like';
        userLike.Utente__c = user.Id;
        
        insert userLike;
        
        ArticleLike articleLike = new ArticleLike(userLike);
        
        Utente_Articolo__c userView = new Utente_Articolo__c();
        
        userView.Articolo__c = newArticle.Id;
        userView.Tipologia__c = 'Visualizzazione';
        userView.Utente__c = user.Id;
        
        insert userView;
        
        ArticleView articleView = new ArticleView(userView);
        
        Utente_Articolo__c userComment = new Utente_Articolo__c();
        
        userComment.Articolo__c = newArticle.Id;
        userComment.Tipologia__c = 'Commento';
        userComment.Utente__c = user.Id;
        
        insert userComment;
        
        ArticleComment articleComment = new ArticleComment(userComment);
        
        Articolo__c foundArticle = [SELECT Id, Autore__r.Nome__c, Autore__r.Cognome__c, Titolo__c, Contenuto__c, Immagine_Di_Copertina__c, Data_Ora_Pubblicazione__c, Tag__c, 
                                    Riassunto__c,Link_Immagine_Di_Copertina__c, Area__c, Menu__c,
                                    (SELECT Id, Genitore__c, Pubblico__c, Testo__c, Tipologia__c, Utente__c, Articolo__c, Utente__r.Nome__c, Utente__r.Cognome__c FROM Utenti_Articoli__r),
                                    (SELECT Id, Gruppo__r.Name FROM Gruppi_Articoli__r)
                                    FROM Articolo__c LIMIT 1];
        
        Article article = new Article(foundArticle);
        
    }
    
    @isTest
    static void testNotificationData(){
        
        NotificationData notificationData = new NotificationData('screen', 0);
        
    }
    
    @isTest
    static void testQuestionData(){
        
        Insieme_Opzioni_Domanda__c questionOptionSet = new Insieme_Opzioni_Domanda__c();
        
        insert questionOptionSet;
        
        Domanda_questionario__c question = new Domanda_questionario__c();
        
        question.Insieme_Opzioni_Domanda__c = questionOptionSet.Id;
        question.Data_Ora_Inizio__c = System.now();
        question.Data_Ora_Fine__c = System.now().addDays(1);
        
        insert question;
        
        Opzione_Domanda__c questionOption = new Opzione_Domanda__c();
        
        questionOption.Insieme_Opzioni_Domanda__c = questionOptionSet.Id;
        
        insert questionOption;
        
        QuestionData questionData = new QuestionData(question, new List<Opzione_Domanda__c>{questionOption});
        
    }
    
    @isTest
    static void testQuestionOptionData(){
        
        Opzione_Domanda__c questionOption = new Opzione_Domanda__c();
        
        insert questionOption;
        
        QuestionOptionData questionOptionData = new QuestionOptionData(questionOption);
        
    }
    
    @isTest
    static void testBubbleChartData(){
        
        BubbleChartLabelsData labels = new BubbleChartLabelsData('a', 'b');
        
        BubbleChartDotData dot = new BubbleChartDotData(3,3,3, null);
        BubbleChartDotData dot2 = new BubbleChartDotData(2,2,2, null);
        BubbleChartDotData dot3 = new BubbleChartDotData(1,1,1, null);
        BubbleChartDotData dot4 = new BubbleChartDotData(4,4,4, null);
        
        BubbleChartData chart = new BubbleChartData('title', 'subtitle', 'brand', labels);
        
        chart.addDot(dot);
        chart.addDot(dot2);
        chart.addDot(dot3);
        chart.addDot(dot4);
        
    }
    
    @isTest
    static void testBarChartData(){
        
        BarChartBarData bar = new BarChartBarData('label','subLabel',3, null);
        BarChartBarData bar2 = new BarChartBarData('label','subLabel',1, null);
        BarChartBarData bar3 = new BarChartBarData('label','subLabel',6, null);
        BarChartBarData bar4 = new BarChartBarData('label','subLabel',2, null);
        
        BarChartData chart = new BarChartData('title', 'subTitle', 'brand');
        
        chart.addBarChartBarListData(new List<BarChartBarData>{bar, bar2});
        chart.addBarChartBarListData(new List<BarChartBarData>{bar3, bar4});
        
    }
    
    @isTest
    static void testAnswerData(){
        
        Domanda_questionario__c question = new Domanda_questionario__c();
        
        question.Data_Ora_Inizio__c = System.now();
        question.Data_Ora_Fine__c = System.now().addDays(1);
        
        insert question;
        
        Risposta_questionario__c answer = new Risposta_questionario__c();
        
        answer.Utente__c = getUser().Id;
        answer.Domanda_questionario__c = question.Id;
        answer.Data_Ora_Risposta__c = System.now();
        
        insert answer;
        
        AnswerData answerData = new AnswerData();
        
        answerData.fromAnswer(answer);
        //answerData.fromJson('{1235234');
        answerData.fromJson('{"id":"1235"}');
        
    }

}