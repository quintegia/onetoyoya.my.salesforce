@RestResource(urlMapping='/access_token/*')
global class AccessTokenResource {
    
    @HttpPost
    global static void getToken(String nickname, String password){
        
        CustomAuthentication ca = new CustomAuthentication(RestContext.request, RestContext.response);
        
        ca.authenticateWithNicknameAndPassword(nickname, password);
        
        if(ca != null && ca.getUser() != null && !ca.isStealth()){
        
            insert new Accesso__c(Utente__c = ca.getUser().Id);
            
        }
		
        ca.getResponse().send();
        
    }
    
}