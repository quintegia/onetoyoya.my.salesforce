@isTest
public class QuestionResourceTest {
    
    static String endpoint = '/services/apexrest/questions';
    
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
                
        Insieme_Opzioni_Domanda__c questionOptionSet = new Insieme_Opzioni_Domanda__c();
        
        insert questionOptionSet;
        
        Raggruppamento__c grouping = new Raggruppamento__c();
        
        grouping.Etichetta_IT__c = 'grouping';
        grouping.Gruppo__c = brandGroup.Id;
        
        insert grouping;
        
        Domanda_questionario__c question = new Domanda_questionario__c();
        
        question.Insieme_Opzioni_Domanda__c = questionOptionSet.Id;
        question.Data_Ora_Inizio__c = System.now();
        question.Data_Ora_Fine__c = System.now().addDays(1);
        question.Raggruppamento__c = grouping.Id;
        question.Obbligatoria__c = true;
        
        insert question;
        
        question = new Domanda_questionario__c();
        
        question.Insieme_Opzioni_Domanda__c = questionOptionSet.Id;
        question.Data_Ora_Inizio__c = System.now();
        question.Data_Ora_Fine__c = System.now().addDays(1);
        question.Raggruppamento__c = grouping.Id;
        question.Tipologia__c = 'Radio con commento obbligatorio';
        
        insert question;
        
        question = new Domanda_questionario__c();
        
        question.Insieme_Opzioni_Domanda__c = questionOptionSet.Id;
        question.Data_Ora_Inizio__c = System.now();
        question.Data_Ora_Fine__c = System.now().addDays(1);
        question.Raggruppamento__c = grouping.Id;
        question.Tipologia__c = 'Radio con commento obbligatorio se minore di 3';
        
        insert question;
        
        Opzione_Domanda__c questionOption = new Opzione_Domanda__c();
        
        questionOption.Insieme_Opzioni_Domanda__c = questionOptionSet.Id;
        
        insert questionOption;
        
    }
    
    static App__c getApp(){
        
        return [SELECT Id FROM App__c LIMIT 1];
        
    }
    
    static Utente__c getUser(){
        
        return [SELECT Id FROM Utente__c LIMIT 1];
        
    }
    
    static List<Domanda_questionario__c> getQuestions(){
        
        return [SELECT Id FROM Domanda_questionario__c];
        
    }
    
    @isTest
    static void testGetQuestions(){
        
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
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        QuestionResource.doGet();
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        //System.assertEquals('expected value', actual, 'Value is incorrect');
        
    }
    
    @isTest
    static void testGetCount(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint + '/get_count';
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
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        QuestionResource.doGet();
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        //System.assertEquals('expected value', actual, 'Value is incorrect');
        
    }
    
    @isTest
    static void testStoreAnswerEmptyQuestionId(){
        
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
        
        req.requestBody = Blob.valueOf('{"questionId":"","numericValue":5,"textValue":"text", "longTextValue": "asuidhfiuashdfias"}');
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        QuestionResource.doPost();
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        //System.assertEquals('expected value', actual, 'Value is incorrect');
        
    } 
    
    @isTest
    static void testStoreAnswerAWithoutValues(){
        
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
        
        req.requestBody = Blob.valueOf('{"questionId":"' + getQuestions()[0].Id + '","numericValue": null,"textValue":"", "longTextValue": ""}');
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        QuestionResource.doPost();
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        //System.assertEquals('expected value', actual, 'Value is incorrect');
        
    } 
    
    @isTest
    static void testStoreAnswerA(){
        
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
        
        req.requestBody = Blob.valueOf('{"questionId":"' + getQuestions()[0].Id + '","numericValue":5,"textValue":"text", "longTextValue": "asuidhfiuashdfias"}');
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        QuestionResource.doPost();
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        //System.assertEquals('expected value', actual, 'Value is incorrect');
        
    } 
    
    @isTest
    static void testStoreAnswerB(){
        
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
        
        req.requestBody = Blob.valueOf('{"questionId":"' + getQuestions()[1].Id + '","numericValue":5,"textValue":"text", "longTextValue": ""}');
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        QuestionResource.doPost();
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        //System.assertEquals('expected value', actual, 'Value is incorrect');
        
    } 
    
    @isTest
    static void testStoreAnswerC(){
        
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
        
        req.requestBody = Blob.valueOf('{"questionId":"' + getQuestions()[2].Id + '","numericValue":2,"textValue":"text", "longTextValue": ""}');
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        QuestionResource.doPost();
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        //System.assertEquals('expected value', actual, 'Value is incorrect');
        
    } 
    
    @isTest
    static void testStoreAnswerWithoutBody(){
        
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
        
        QuestionResource.doPost();
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        //System.assertEquals('expected value', actual, 'Value is incorrect');
        
    }
    
    @isTest
    static void testStoreAnswerWithEmptyBody(){
        
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
        
        QuestionResource.doPost();
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        //System.assertEquals('expected value', actual, 'Value is incorrect');
        
    }
    
    @isTest
    static void testStoreAnswerWithWrongJsonBody(){
        
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
        
        req.requestBody = Blob.valueOf('{3423tfwf');
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        QuestionResource.doPost();
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        //System.assertEquals('expected value', actual, 'Value is incorrect');
        
    }

}