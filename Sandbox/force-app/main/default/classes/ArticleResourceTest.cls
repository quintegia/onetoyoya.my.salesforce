@isTest
public class ArticleResourceTest {
    
    static String endpoint = '/services/apexrest/articles';
    
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
        user.Non_Considerare_Analisi__c = false;
        
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
        userGroup.Gruppo__c = brandGroup.Id;
        
        insert userGroup;
                
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
        userLike.Utente__c = user.Id;
        
        Utente_Articolo__c userView = new Utente_Articolo__c();
        
        userLike.Articolo__c = article.Id;
        userLike.Tipologia__c = 'Visualizzazione';
        userLike.Utente__c = user.Id;
        
        insert new List<Utente_Articolo__c>{userLike, userView};
        
        
        
    }
    
    static App__c getApp(){
        
        return [SELECT Id FROM App__c LIMIT 1];
        
    }
    
    static Utente__c getUser(){
        
        return [SELECT Id FROM Utente__c WHERE Nickname__c = 'nickname' LIMIT 1];
        
    }
    
    static Domanda_questionario__c getQuestion(){
        
        return [SELECT Id FROM Domanda_questionario__c LIMIT 1];
        
    }
    
    static Articolo__c getArticle(){
        
        return [SELECT Id FROM Articolo__c LIMIT 1];
        
    }
    
    @isTest
    static void testGetArticlesUnauthtenticated(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint;
        req.httpMethod = 'GET';
        
        req.requestBody = null;
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        ArticleResource.doGet();
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testGetArticles(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint;
        req.httpMethod = 'GET';
        
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
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
        
        req.requestBody = null;
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        ArticleResource.doGet();
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode == 200);
        System.assert(!body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testGetArticlesMenu(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint + '/menu';
        req.httpMethod = 'GET';
        
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
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
        
        req.requestBody = null;
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        ArticleResource.doGet();
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode == 200);
        System.assert(!body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testCountArticles(){
        
        Test.startTest();
        
        ArticleResource.countAllUserArticles(getUser().Id);
        
        Test.stopTest();
        
    }
    
    @isTest
    static void testFindArticleById(){
        
        Test.startTest();
        
        ArticleResource.findArticleById(getArticle().Id);
        
        Test.stopTest();
        
    }
    
    @isTest
    static void testGetLatestContent(){
        
        Utente__c u = getUser();
        
        List<Gruppo__c> childGroups = UserResource.getUserGroupChildren(u.Id);
        
        Set<Id> groupsIds = new Set<Id>();
        
        for(Gruppo__c g : childGroups){
            
            groupsIds.add(g.Id);
            
        }
        
        System.debug(groupsIds);
        
        Test.startTest();
        
        ArticleResource.getLatestContent(u.Id, groupsIds);
        
        Test.stopTest();
        
    }
    
    @isTest
    static void testGetMostLikedAndViwedContents(){
        
        Utente__c u = getUser();
        
        List<Gruppo__c> childGroups = UserResource.getUserGroupChildren(u.Id);
        
        Set<Id> groupsIds = new Set<Id>();
        
        for(Gruppo__c g : childGroups){
            
            groupsIds.add(g.Id);
            
        }
        
        Test.startTest();
        
        ArticleResource.getMostLikedAndViwedContents(u.Id, groupsIds);
        
        Test.stopTest();
        
    }
    
    @isTest
    static void testPostArticlesUnauthtenticated(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint;
        req.httpMethod = 'POST';
        
        req.requestBody = null;
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        ArticleResource.doPost('asdasd');
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testPostArticlesWithoutBody(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint;
        req.httpMethod = 'POST';
        
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
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
        
        req.requestBody = null;
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        ArticleResource.doPost('asdasd');
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testPostArticlesWithEmptyBody(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint;
        req.httpMethod = 'POST';
        
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
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
        
        req.requestBody = Blob.valueOf('');
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        ArticleResource.doPost('asdasd');
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testPostArticlesWithWrongBody(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint;
        req.httpMethod = 'POST';
        
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
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
        
        req.requestBody = Blob.valueOf('{ikuasdcgiuas""gdifasd}');
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        ArticleResource.doPost('asdasd');
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testPostArticleView(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint + '/' + getArticle().Id;
        req.httpMethod = 'POST';
        
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
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
        
        req.requestBody = Blob.valueOf('{ikuasdcgiuas""gdifasd}');
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        ArticleResource.doPost('view');
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode == 200);
        System.assert(!body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testPostArticleLike(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint + '/' + getArticle().Id;
        req.httpMethod = 'POST';
        
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
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
        
        req.requestBody = Blob.valueOf('{ikuasdcgiuas""gdifasd}');
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        ArticleResource.doPost('like');
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode == 200);
        System.assert(!body.containsIgnoreCase('error'));
        
    }

}