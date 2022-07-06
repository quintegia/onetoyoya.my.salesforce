@isTest
public class ManagerHomeResourceTest {
    
    static String endpoint = '/services/apexrest/manager_home';
    
    @testSetup
    static void setup(){
        
        TMI_RCC__c settings = new TMI_RCC__c();
        
        settings.Secret_Key__c = 'secret';
        
        insert settings;
        
        App__c app = new App__c();
        
        insert app;
        
        Utente__c author = new Utente__c();
        
        author.Nickname__c = 'author';
        author.Password__c = 'author';
        author.App__c = app.Id;
        
        insert author;
        
        Utente__c user = new Utente__c();
        
        user.Nickname__c = 'nickname';
        user.Password__c = 'password';
        user.App__c = app.Id;
        user.Tipologia__c = 'Manager';
        user.Azienda_Permessi_Visualizzazione__c = 'TMI';
        
        insert user;
        
        Utente__c user2 = new Utente__c();
        
        user2.Nickname__c = 'nickname2';
        user2.Password__c = 'password2';
        user2.App__c = app.Id;
        user2.Tipologia__c = 'Dealer';
        user.Azienda_Permessi_Visualizzazione__c = 'TMI';
        
        insert user2;
        
        Gruppo__c mainGroup = new Gruppo__c();
        
        mainGroup.Name = 'Main';
        
        insert mainGroup;
        
        Gruppo__c brandGroup = new Gruppo__c();
        
        brandGroup.Name = 'Brand 1';
        brandGroup.Tipologia__c = 'Marchio';
        brandGroup.Genitore__c = mainGroup.Id;
        
        insert brandGroup;
        
        Gruppo__c districtGroup = new Gruppo__c();
        
        districtGroup.Name = 'District 1';
        districtGroup.Tipologia__c = 'Zona';
        districtGroup.Genitore__c = brandGroup.Id;
        
        insert districtGroup;
        
        Gruppo__c zoneGroup = new Gruppo__c();
        
        zoneGroup.Name = 'Zone 1';
        zoneGroup.Tipologia__c = 'Zona';
        zoneGroup.Genitore__c = districtGroup.Id;
        
        insert zoneGroup;
        
        Utente_Gruppo__c userGroup = new Utente_Gruppo__c();
        
        userGroup.Utente__c = user.Id;
        userGroup.Gruppo__c = brandGroup.Id;
        
        insert userGroup;
        
        Utente_Gruppo__c userGroup2 = new Utente_Gruppo__c();
        
        userGroup2.Utente__c = user2.Id;
        userGroup2.Gruppo__c = zoneGroup.Id;
        
        insert userGroup2;
        
        Questionario__c survey = new Questionario__c();
        
        survey.Name = 'test';
        
        insert survey;
        
        Raggruppamento__c index1 = new Raggruppamento__c();
        
        index1.Gruppo__c = brandGroup.Id;
        index1.Visualizzabile_Da_Manager_In__c = 'Dealer Map';
        index1.Tipologia__c = 'Indice';
        index1.Etichetta_Ridotta_EN__c = 'Motivation';
        index1.Peso_Genitore__c = 1;
        index1.Azienda_Permessi_Visualizzazione__c = 'TMI';
        
        insert index1;
        
        Raggruppamento__c index2 = new Raggruppamento__c();
        
        index2.Gruppo__c = brandGroup.Id;
        index2.Visualizzabile_Da_Manager_In__c = 'Dealer Map';
        index2.Tipologia__c = 'Indice';
        index2.Etichetta_Ridotta_EN__c = 'Business';
        index2.Peso_Genitore__c = 1;
        index2.Azienda_Permessi_Visualizzazione__c = 'TMI';
        
        insert index2;
        
        Raggruppamento__c grouping1 = new Raggruppamento__c();
        
        grouping1.Gruppo__c = brandGroup.Id;
        grouping1.Visualizzabile_Da_Manager_In__c = 'Dealer Map';
        grouping1.Genitore__c = index1.Id;
        grouping1.Peso_Genitore__c = 1;
        grouping1.Azienda_Permessi_Visualizzazione__c = 'TMI';
        
        insert grouping1;
        
        Raggruppamento__c grouping2 = new Raggruppamento__c();
        
        grouping2.Gruppo__c = brandGroup.Id;
        grouping2.Visualizzabile_Da_Manager_In__c = 'Dealer Map';
        grouping2.Genitore__c = index2.Id;
        grouping2.Peso_Genitore__c = 1;
        grouping2.Azienda_Permessi_Visualizzazione__c = 'TMI';
        
        insert grouping2;
        
        Domanda_Questionario__c question = new Domanda_Questionario__c();
        
        question.Questionario__c = survey.Id;
        question.Data_Ora_Inizio__c = System.now().addDays(-5);
        question.Data_Ora_Fine__c = System.now().addDays(-1);
        question.Raggruppamento__c = grouping1.Id;
        question.Data_Ora_Inizio_Analisi__c = System.now().addDays(-5);
        question.Data_Ora_Fine_Analisi__c = System.now().addDays(-1);
        question.Frequenza__c = 'Mens.';
        
        insert question;
        
        Domanda_Questionario__c question2 = new Domanda_Questionario__c();
        
        question2.Questionario__c = survey.Id;
        question2.Data_Ora_Inizio__c = System.now().addDays(-5);
        question2.Data_Ora_Fine__c = System.now().addDays(-1);
        question2.Raggruppamento__c = grouping2.Id;
        question2.Data_Ora_Inizio_Analisi__c = System.now().addDays(-5);
        question2.Data_Ora_Fine_Analisi__c = System.now().addDays(-1);
        question2.Frequenza__c = 'Trim.';
        
        insert question2;
        
        Risposta_questionario__c answer = new Risposta_questionario__c();
        
        answer.Domanda_questionario__c = question.Id;
        answer.Utente__c = user2.Id;
        answer.Valore_Numerico__c = 1;
        answer.Data_Ora_Risposta__c = System.now();
        
        insert answer;
        
        Risposta_questionario__c answer2 = new Risposta_questionario__c();
        
        answer2.Domanda_questionario__c = question2.Id;
        answer2.Utente__c = user2.Id;
        answer2.Valore_Numerico__c = 5;
        answer2.Data_Ora_Risposta__c = System.now();
        
        insert answer2;      
        
        Raggruppamento__c grouping3 = new Raggruppamento__c();
        
        grouping3.Gruppo__c = brandGroup.Id;
        grouping3.Name = 'grouping3';
        grouping3.Visualizzabile_Da_Manager_In__c = 'Dealer Map';
        grouping3.Genitore__c = index2.Id;
        grouping3.Peso_Genitore__c = 1;
        grouping3.Azienda_Permessi_Visualizzazione__c = 'TMI';
        
        insert grouping3;     
        
        Raggruppamento__c grouping4 = new Raggruppamento__c();
        
        grouping4.Gruppo__c = brandGroup.Id;
        grouping4.Name = 'grouping4';
        grouping4.Visualizzabile_Da_Manager_In__c = 'Dealer Map';
        grouping4.Genitore__c = index2.Id;
        grouping4.Peso_Genitore__c = 1;
        grouping4.Azienda_Permessi_Visualizzazione__c = 'TMI';
        
        insert grouping4;
        
        Domanda_Questionario__c question3 = new Domanda_Questionario__c();
        
        question3.Questionario__c = survey.Id;
        question3.Data_Ora_Inizio__c = System.now().addDays(-5);
        question3.Data_Ora_Fine__c = System.now().addDays(1);
        question3.Raggruppamento__c = grouping3.Id;
        question3.Data_Ora_Inizio_Analisi__c = System.now().addDays(-5);
        question3.Data_Ora_Fine_Analisi__c = System.now().addDays(1);
        question3.Frequenza__c = 'Trim.';
        
        insert question3;
        
        Domanda_Questionario__c question4 = new Domanda_Questionario__c();
        
        question4.Questionario__c = survey.Id;
        question4.Data_Ora_Inizio__c = System.now().addDays(-5);
        question4.Data_Ora_Fine__c = System.now().addDays(1);
        question4.Raggruppamento__c = grouping4.Id;
        question4.Data_Ora_Inizio_Analisi__c = System.now().addDays(-5);
        question4.Data_Ora_Fine_Analisi__c = System.now().addDays(1);
        question4.Frequenza__c = 'Mens.';
        
        insert question4;
        
        Risposta_questionario__c answer3 = new Risposta_questionario__c();
        
        answer3.Domanda_questionario__c = question3.Id;
        answer3.Utente__c = user2.Id;
        answer3.Valore_Numerico__c = 1;
        answer3.Data_Ora_Risposta__c = System.now();
        
        insert answer3;
        
        Risposta_questionario__c answer4 = new Risposta_questionario__c();
        
        answer4.Domanda_questionario__c = question4.Id;
        answer4.Utente__c = user2.Id;
        answer4.Valore_Numerico__c = 5;
        answer4.Data_Ora_Risposta__c = System.now();
        
        insert answer4;
        
        Risposta_questionario__c answer5 = new Risposta_questionario__c();
        
        answer5.Domanda_questionario__c = question3.Id;
        answer5.Utente__c = user2.Id;
        answer5.Valore_Numerico__c = 1;
        answer5.Data_Ora_Risposta__c = System.now();
        
        insert answer5;
        
        Risposta_questionario__c answer6 = new Risposta_questionario__c();
        
        answer6.Domanda_questionario__c = question4.Id;
        answer6.Utente__c = user2.Id;
        answer6.Valore_Numerico__c = 5;
        answer6.Data_Ora_Risposta__c = System.now();
        
        insert answer6;
        
        Articolo__c article = new Articolo__c();
        
        article.Contenuto__c = 'content';
        article.Titolo__c = 'title';
        article.Tag__c = 'tag1,tag2';
        article.Autore__c = author.Id;
        article.Data_Ora_Pubblicazione__c = System.now();
        article.Riassunto__c = 'excerpt';
        article.Tipologia__c = 'Articolo';
        article.Menu__c = 'Toyota;Lexus';
        
        insert article;
        
        Gruppo_Articolo__c contentGroup = new Gruppo_Articolo__c();
        
        contentGroup.Articolo__c = article.Id;
        contentGroup.Gruppo__c = brandGroup.Id;
        
        insert contentGroup;
        
        Utente_Articolo__c userLike = new Utente_Articolo__c();
        
        userLike.Articolo__c = article.Id;
        userLike.Tipologia__c = 'Like';
        userLike.Utente__c = user2.Id;
        
        Utente_Articolo__c userView = new Utente_Articolo__c();
        
        userLike.Articolo__c = article.Id;
        userLike.Tipologia__c = 'Visualizzazione';
        userLike.Utente__c = user2.Id;
        
        insert new List<Utente_Articolo__c>{userLike, userView};
        
    }
    
    static App__c getApp(){
        
        return [SELECT Id FROM App__c LIMIT 1];
        
    }
    
    static Utente__c getUser(){
        
        return [SELECT Id FROM Utente__c WHERE Nickname__c = 'nickname' LIMIT 1];
        
    }
    
    static Gruppo__c getGroup(){
        
        return [SELECT Id FROM Gruppo__c LIMIT 1];
        
    }
    
    @isTest
    static void testAuthenticated(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        String brandId = [SELECT Id FROM Gruppo__c WHERE Tipologia__c = 'Marchio' LIMIT 1].Id;
        
        System.debug(brandId);
        
        req.requestURI = endpoint;
        req.httpMethod = 'GET';
        
        req.addParameter('brandId', brandId);
        
        RestContext.request = req;
        RestContext.response= res;
        
        Dispositivo__c device = new Dispositivo__c();
        
        device.Dispositivo__c = 'deviceId';
        device.Firebase_Token__c = 'firebaseToken';
        device.Token__c = jwt.encode(new Map<String, Object>{'id' => getUser().Id}, 60 * 5);
        device.Utente__c = getUser().Id;
        
        insert device;
        
        req.addHeader('x-bearer-token', jwt.encode(null, 60));
        req.addHeader('x-device-id', 'deviceId');
        req.addHeader('x-firebase-token', 'firebaseToken');
        req.addHeader('x-auth-token', device.Token__c);
        req.addHeader('x-app-id', getApp().Id);
        
        Test.startTest();
        
        ManagerHomeResource.doGet();
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode == 200);
        System.assert(!body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testUnauthenticated(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        JWT jwt = new JWT();
        jwt.setKey('wrong secret');
        
        req.requestURI = endpoint;
        req.httpMethod = 'GET';
        
        RestContext.request = req;
        RestContext.response= res;
        
        Dispositivo__c device = new Dispositivo__c();
        
        device.Dispositivo__c = 'deviceId';
        device.Firebase_Token__c = 'firebaseToken';
        device.Token__c = jwt.encode(new Map<String, Object>{'id' => getUser().Id}, 60 * 5);
        device.Utente__c = getUser().Id;
        
        insert device;
        
        req.addHeader('x-bearer-token', jwt.encode(null, 60));
        req.addHeader('x-device-id', 'deviceId');
        req.addHeader('x-firebase-token', 'firebaseToken');
        req.addHeader('x-auth-token', device.Token__c);
        req.addHeader('x-app-id', getApp().Id);
        
        Test.startTest();
        
        ManagerHomeResource.doGet();
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }

}