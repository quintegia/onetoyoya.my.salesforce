public class UserData {
    
    public String id;
    public String appId;
    public String accountId;
    public String zipCode;
    public String city;
    public String seniority;
    public String revenue;
    public String sales;
    public String manufacturerCode;
    public String lastName;
    public Long decommissioned;
    public String email;
    public String legalAddress;
    public String nickname;
    public String firstName;
    public String commercialName;
    public Boolean notConsiderInAnalysis;
    public String vatNumber;
    public String province;
    public String companyName;
    public String contactId;
    public String district;
    public String companyRole;
    public String role;
    public String profilePictureUrl;
    public String profilePicturePath;
    public Long privacyAcceptedAt;
    public List<String> brands = new List<String>();
    public List<String> groups = new List<String>();
    public Boolean slave = false;
    public List<GroupData> parentGroups;
    public List<GroupData> childGroups;
    
    public String deviceId;
    public String token;
    
    public Integer answeredQuestions;
    public Integer viewedArticles;
    public Integer receivedNotifications;
    
    public UserData(){}
    
    DateTime toDateTime(Date d){
        
        return DateTime.newInstance(d, Time.newInstance(0, 0, 0, 0));
        
    }
    
    public void fromUtente(Utente__c user){
        
        Long decommissioned;
        
        if(user.Dismesso__c != null){
            
            decommissioned = toDateTime(user.Dismesso__c).getTime();
            
        }
        
        this.id = user.Id;
        this.accountId = user.Azienda__c;
        //this.answeredQuestions = null;
        this.appId = user.App__c;
        //this.brands = null;
        //this.childGroups = null;
        this.city = user.Citta__c;
        this.commercialName = user.Nome_Commerciale__c;
        this.companyName = user.Ragione_Sociale__c;
        this.companyRole = user.Ruolo__c;
        this.contactId = user.Referente__c;
        this.decommissioned = decommissioned;
        //this.deviceId = null;
        //this.district = null;
        this.email = user.Email__c;
        this.firstName = user.Nome__c;
        this.lastName = user.Cognome__c;
        this.legalAddress = user.Indirizzo_Sede_Legale__c;
        this.manufacturerCode = user.COD_CASA__c;
        this.nickname = user.Nickname__c;
        this.notConsiderInAnalysis = user.Non_Considerare_Analisi__c;
        //this.parentGroups = null;
        this.privacyAcceptedAt = user.Data_Ora_Accettazione_Privacy__c != null ? user.Data_Ora_Accettazione_Privacy__c.getTime() : null;
        this.profilePictureUrl = user.URL_Foto__c;
        this.profilePicturePath = user.Riferimento_Immagine_Profilo__c;
        this.province = user.Provincia__c;
        //this.receivedNotifications = null;
        this.revenue = user.CL_Fatturato__c;
        this.role = user.Tipologia__c;
        this.sales = user.CL_Vendite__c;
        this.seniority = user.CL_Anzianita__c;
        this.slave = user.Utente_Master__c != null;
        //this.token = null;
        this.vatNumber = user.PIVA__c;
        //this.viewedArticles = null;
        this.zipCode = user.CAP__c;
        
    }
    
    public void fromUtenteChat(Utente_Chat__c userChat){
        
        Long decommissioned;
        
        if(userChat.Utente__r.Dismesso__c != null){
            
            decommissioned = toDateTime(userChat.Utente__r.Dismesso__c).getTime();
            
        }
        
        this.id = userChat.Utente__r.Id;
        this.accountId = userChat.Utente__r.Azienda__c;
        this.appId = userChat.Utente__r.App__c;
        this.city = userChat.Utente__r.Citta__c;
        this.commercialName = userChat.Utente__r.Nome_Commerciale__c;
        this.companyName = userChat.Utente__r.Ragione_Sociale__c;
        this.companyRole = userChat.Utente__r.Ruolo__c;
        this.contactId = userChat.Utente__r.Referente__c;
        this.decommissioned = decommissioned;
        this.email = userChat.Utente__r.Email__c;
        this.firstName = userChat.Utente__r.Nome__c;
        this.lastName = userChat.Utente__r.Cognome__c;
        this.legalAddress = userChat.Utente__r.Indirizzo_Sede_Legale__c;
        this.manufacturerCode = userChat.Utente__r.COD_CASA__c;
        this.nickname = userChat.Utente__r.Nickname__c;
        this.notConsiderInAnalysis = userChat.Utente__r.Non_Considerare_Analisi__c;
        this.privacyAcceptedAt = userChat.Utente__r.Data_Ora_Accettazione_Privacy__c != null ? userChat.Utente__r.Data_Ora_Accettazione_Privacy__c.getTime() : null;
        this.profilePictureUrl = userChat.Utente__r.URL_Foto__c;
        this.profilePicturePath = userChat.Utente__r.Riferimento_Immagine_Profilo__c;
        this.province = userChat.Utente__r.Provincia__c;
        this.revenue = userChat.Utente__r.CL_Fatturato__c;
        this.role = userChat.Utente__r.Tipologia__c;
        this.sales = userChat.Utente__r.CL_Vendite__c;
        this.seniority = userChat.Utente__r.CL_Anzianita__c;
        this.slave = userChat.Utente__r.Utente_Master__c != null;
        this.vatNumber = userChat.Utente__r.PIVA__c;
        this.zipCode = userChat.Utente__r.CAP__c;
        
    }
    
}