@isTest
public class AppInfoResourceTest {
    
    static String endpoint = '/services/apexrest/app_info';
    
    @testSetup
    static void setup(){
        
        App__c app = new App__c();
        
        insert app;
        
        List<Configurazione_App__c> appConfigs = new List<Configurazione_App__c>();
        Configurazione_App__c appConfig = new Configurazione_App__c();
        
        appConfig.App__c = app.Id;
        appConfig.Chiave__c = 'chiave_testuale';
        appConfig.Sezione__c = 'Grafici';
        appConfig.Tipologia_Campo__c = 'Testuale';
        appConfig.Campo_Testuale__c = 'testo';
        
        appConfigs.add(appConfig);
        
        appConfig = new Configurazione_App__c();
        
        appConfig.App__c = app.Id;
        appConfig.Chiave__c = 'chiave_booleana';
        appConfig.Sezione__c = 'Grafici';
        appConfig.Tipologia_Campo__c = 'Booleano';
        appConfig.Campo_Booleano__c = true;
        
        appConfigs.add(appConfig);
        
        appConfig = new Configurazione_App__c();
        
        appConfig.App__c = app.Id;
        appConfig.Chiave__c = 'chiave_numerica';
        appConfig.Sezione__c = 'Grafici';
        appConfig.Tipologia_Campo__c = 'Numerico';
        appConfig.Campo_Numerico__c = 12;
        
        appConfigs.add(appConfig);
        
        appConfig = new Configurazione_App__c();
        
        appConfig.App__c = app.Id;
        appConfig.Chiave__c = 'chiave_data';
        appConfig.Sezione__c = 'Grafici';
        appConfig.Tipologia_Campo__c = 'Data';
        appConfig.Campo_Data__c = System.today();
        
        appConfigs.add(appConfig);
        
        appConfig = new Configurazione_App__c();
        
        appConfig.App__c = app.Id;
        appConfig.Chiave__c = 'chiave_data_ora';
        appConfig.Sezione__c = 'Grafici';
        appConfig.Tipologia_Campo__c = 'Data Ora';
        appConfig.Campo_Data_Ora__c = System.now();
        
        appConfigs.add(appConfig);
        
        insert appConfigs;
        
    }
    
    static App__c getApp(){
        
        return [SELECT Id FROM App__c LIMIT 1];
        
    }
    
    @isTest
    static void testGetAppInfoResourceWithoutAppId(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint;
        req.httpMethod = 'GET';
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        AppInfoResource.doGet();
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testGetAppInfoResourceWithAppId(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint;
        req.httpMethod = 'GET';
        
        req.addHeader('x-app-id', getApp().Id);
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        AppInfoResource.doGet();
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode == 200);
        System.assert(!body.containsIgnoreCase('error'));
        
    }

}