@isTest
public class BritResourceTest {
  
    static String endpoint = '/services/apexrest/britresult';
    
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
        user.COD_CASA__c = '000467';
        
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
        
        BRiT_Aree_KPI__c ba = new BRiT_Aree_KPI__c();
        ba.Area_KPI__c = 'People';
        ba.Color__c = 'AABBCC';
        ba.Ordine__c = 1;
        insert ba;
        
        BRiT_Aree_KPI__c ba2 = new BRiT_Aree_KPI__c();
        ba2.Area_KPI__c = 'Altra roba';
        ba2.Color__c = 'AABBCC';
        ba2.Ordine__c = 2;
        insert ba2;
        
        BRiT_KPI__c bki = new BRiT_KPI__c();
        bki.CondizioneMaggioreDi__c = 10;
        bki.Cod_Area_KPI__c = ba.id;
        bki.Ordine__c = 1;
        bki.KPI__c = 'Perf. Sales';
        insert bki;
        
        BRiT_KPI__c bki2 = new BRiT_KPI__c();
        bki2.CondizioneMaggioreDi__c = 10;
        bki2.Cod_Area_KPI__c = ba.id;
        bki2.Ordine__c = 2;
        bki2.KPI__c = 'Perf. Sales asdasdasd';
        insert bki2;
        
        BRiT_KPI__c bki3 = new BRiT_KPI__c();
        bki3.CondizioneMaggioreDi__c = 10;
        bki3.Cod_Area_KPI__c = ba2.id;
        bki3.Ordine__c = 3;
        bki3.KPI__c = 'Perf. Sales yuiyuiyui';
        insert bki3;
        
        BRiT_Risultati__c br = new BRiT_Risultati__c();
        br.Anno__c = 2021;
        br.Cod_Casa__c = '000467';
        br.Distretto__c = '3';
        br.Marchio__c = 'Toyota';
        br.Mese__c = 3;
        br.Nome_dealer__c = 'Zerocento';
        br.Zona__c = 'F';
        br.Benchmark__c = 75;
        br.Gruppo__c = 'asd';
        br.Marchio__c = 'Toyota';
        br.Non_visualizzare__c = false;
        br.Value__c = 12;
        br.Cod_KPI__c = bki.id;
        insert br;
        
        BRiT_Risultati__c br2 = new BRiT_Risultati__c();
        br2.Anno__c = 2021;
        br2.Cod_Casa__c = '000467';
        br2.Distretto__c = '3';
        br2.Marchio__c = 'Toyota';
        br2.Mese__c = 3;
        br2.Nome_dealer__c = 'Zerocento';
        br2.Zona__c = 'F';
        br2.Benchmark__c = 75;
        br2.Gruppo__c = 'asd';
        br2.Marchio__c = 'Toyota';
        br2.Non_visualizzare__c = false;
        br2.Value__c = 12;
        br2.Cod_KPI__c = bki2.id;
        insert br2;
        
        BRiT_Risultati__c br3 = new BRiT_Risultati__c();
        br3.Anno__c = 2021;
        br3.Cod_Casa__c = '000467';
        br3.Distretto__c = '3';
        br3.Marchio__c = 'Toyota';
        br3.Mese__c = 3;
        br3.Nome_dealer__c = 'Zerocento';
        br3.Zona__c = 'F';
        br3.Benchmark__c = 75;
        br3.Gruppo__c = 'asd';
        br3.Marchio__c = 'Toyota';
        br3.Non_visualizzare__c = false;
        br3.Value__c = 12;
        br3.Cod_KPI__c = bki2.id;
        insert br3;
        
        BRiT_Risultati__c br4 = new BRiT_Risultati__c();
        br4.Anno__c = 2021;
        br4.Cod_Casa__c = '000467';
        br4.Distretto__c = '3';
        br4.Marchio__c = 'Toyota';
        br4.Mese__c = 3;
        br4.Nome_dealer__c = 'Zerocento';
        br4.Zona__c = 'F';
        br4.Benchmark__c = 75;
        br4.Gruppo__c = 'asd';
        br4.Marchio__c = 'Toyota';
        br4.Non_visualizzare__c = false;
        br4.Value__c = 12;
        br4.Cod_KPI__c = bki3.id;
        insert br4;
        
        BRiT_Visualizzazioni__c bv = new BRiT_Visualizzazioni__c();
        bv.Anno__c = 2021;
        bv.Cod_KPI__c = bki.id;
        bv.Marchio__c = 'Toyota';
        bv.Mese__c = 3;
        insert bv;
        
        BRiT_Visualizzazioni__c bv2 = new BRiT_Visualizzazioni__c();
        bv2.Anno__c = 2021;
        bv2.Cod_KPI__c = bki2.id;
        bv2.Marchio__c = 'Toyota';
        bv2.Mese__c = 3;
        insert bv2;
        
        BRiT_Visualizzazioni__c bv3 = new BRiT_Visualizzazioni__c();
        bv3.Anno__c = 2021;
        bv3.Cod_KPI__c = bki3.id;
        bv3.Marchio__c = 'Toyota';
        bv3.Mese__c = 3;
        insert bv3;
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

    @isTest//(SeeAllData=true)
    static void testGetBrit(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint; // + '/202103';
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
        
        BritResultResource.doGet();
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode == 200);
        System.assert(!body.containsIgnoreCase('error'));
        
    }
 

}