@RestResource(urlMapping='/refresh_token/*')
global class RefreshTokenResource {
    
    @HttpPost
    global static void getToken(){
        
        CustomAuthentication ca = new CustomAuthentication(RestContext.request, RestContext.response);
        
        ca.authenticateWithToken();
        
        if(ca != null && ca.getUser() != null && !ca.isStealth()){
        
            insert new Accesso__c(Utente__c = ca.getUser().Id);
            
        }
		
        ca.getResponse().send();
        
    }
    
}