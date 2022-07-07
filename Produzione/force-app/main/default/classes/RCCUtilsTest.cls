@isTest
public class RCCUtilsTest {
    
    @testSetup
    static void setup(){
        
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
    
    @isTest
    static void testFindExisingUserById(){
        
        Utente__c found = RCCUtils.findUserById(getUser().Id);
        System.assert(found != null);
        
    }
    
    @isTest
    static void testFindNotExisingUserById(){
        
        Utente__c user = new Utente__c();
        user.Nickname__c = 'nickname2';
        user.Password__c = 'password2';
        user.App__c = getApp().Id;
        
        insert user;
        
        delete user;
        
        Utente__c found = RCCUtils.findUserById(user.Id);
        System.assert(found == null);
        
    }
    
    @isTest
    static void testFindUserBrandsByUserId(){
        
        List<Gruppo__c> userBrands = RCCUtils.findUserBrandsByUserId(getUser().Id);
        System.assert(userBrands.size() > 0);
        
    }
    
    @isTest
    static void testDateFormat(){
        
        String formattedDate = RCCUtils.dateFormat(Date.newInstance(1987, 6, 26));
        System.assertEquals(formattedDate, '26 Giugno 1987');
        
    }

}