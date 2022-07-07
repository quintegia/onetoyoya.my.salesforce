@RestResource(urlMapping='/app_info/*')
global class AppInfoResource {
    
    @HttpGet
    global static void doGet(){
        
        String appId = RestContext.request.headers.get('x-app-id'); 
        
        CustomResponse res = new CustomResponse(RestContext.response);
                
        App__c app = null;
        
        try{
            
            app = [SELECT Id, Name, Versione__c, Apple_Store_Url__c, Google_Play_Store_Url__c, Versione_IOS__c, Versione_Android__c, Privacy_IT__c, Privacy_EN__c,
                   Contatto_Telefonico__c, Contatto_Email__c, Descrizione_IT__c, Descrizione_EN__c
                   FROM App__c 
                   WHERE Id = :appId LIMIT 1];
            
            AppInfoData appInfoData = new AppInfoData();
            appInfoData.id = app.Id;
            appInfoData.name = app.Name;
            appInfoData.version = app.Versione__c;
            appInfoData.appleStoreUrl = app.Apple_Store_Url__c;
            appInfoData.googlePlayStoreUrl = app.Google_Play_Store_Url__c;
            appInfoData.iosVersion = app.Versione_IOS__c;
            appInfoData.androidVersion = app.Versione_Android__c;
            appInfoData.privacyIt = app.Privacy_IT__c;
            appInfoData.privacyEn = app.Privacy_EN__c;
            appInfoData.descriptionIt = app.Descrizione_IT__c;
            appInfoData.descriptionEn = app.Descrizione_EN__c;
            appInfoData.phoneContact = app.Contatto_Telefonico__c;
            appInfoData.emailContact = app.Contatto_Email__c;
            appInfoData.configurations = getAppConfigurations(app.Id);
        
            res.setStatusCode(200);
            res.setBody(appInfoData);
            
        }catch(Exception ex){
            
            res.setStatusCode(500);
            res.setBody(new Map<String, Object>{'error' => 'App not found.'});
            
        }
        
        res.send();
        
    }
    
    private static Map<String, Object> getAppConfigurations(Id appId){
        
        Map<String, Object> configurations = new Map<String, Object>();
            
        List<Configurazione_App__c> appConfigurations = [SELECT Id, Name, App__c, Chiave__c, Sezione__c, Tipologia_Campo__c, Campo_Testuale__c, Campo_Numerico__c,
                                                         Campo_Booleano__c, Campo_Data__c, Campo_Data_Ora__c
                                                         FROM Configurazione_App__c
                                                         WHERE App__c = :appId];
        
        for(Configurazione_App__c ca : appConfigurations){
            
            if(!configurations.containsKey(ca.Sezione__c)){
                
                configurations.put(ca.Sezione__c, new Map<String, Object>());
                
            }
            
            Map<String, Object> row = (Map<String, Object>) configurations.get(ca.Sezione__c);
            
            if('Numerico'.equalsIgnoreCase(ca.Tipologia_Campo__c)){
            
                row.put(ca.Chiave__c, ca.Campo_Numerico__c);
                
            }else if('Testuale'.equalsIgnoreCase(ca.Tipologia_Campo__c)){
            
                row.put(ca.Chiave__c, ca.Campo_Testuale__c);
                
            }else if('Booleano'.equalsIgnoreCase(ca.Tipologia_Campo__c)){
            
                row.put(ca.Chiave__c, ca.Campo_Booleano__c);
                
            }else if('Data'.equalsIgnoreCase(ca.Tipologia_Campo__c)){
            
                row.put(ca.Chiave__c, ca.Campo_Data__c);
                
            }else if('Data Ora'.equalsIgnoreCase(ca.Tipologia_Campo__c)){
            
                row.put(ca.Chiave__c, ca.Campo_Data_Ora__c);
                
            }
            
        }
        
        return configurations;
        
    }
    
}