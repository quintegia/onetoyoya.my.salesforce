public class AnswerData {
    
    public String id;
    public String userId;
    public String questionId;
    public Decimal numericValue;
    public String textValue;
    public String longTextValue;
    public Long answerDateTime;
    
    public AnswerData(){ }
    
    public void fromAnswer(Risposta_questionario__c answer){
        
        this.id = answer.Id;
        this.userId = answer.Utente__c;
        this.questionId = answer.Domanda_questionario__c;
        this.numericValue = answer.Valore_Numerico__c;
        this.textValue = answer.Valore_Testuale__c;
        this.longTextValue = answer.Valore_Testuale_Lungo__c;
        this.answerDateTime = answer.Data_Ora_Risposta__c.getTime();
        
    }
    
    public void fromJson(String jsonString){
        
        Map<String, Object> decoded = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
            
        this.id = decoded.containsKey('id') ? (String) decoded.get('id') : null;
        this.userId = decoded.containsKey('userId') ? (String) decoded.get('userId') : null;
        this.questionId = decoded.containsKey('questionId') ? (String) decoded.get('questionId') : null;
        this.numericValue = decoded.containsKey('numericValue') ? (Decimal) decoded.get('numericValue') : null;
        this.textValue = decoded.containsKey('textValue') ? (String) decoded.get('textValue') : null;
        this.longTextValue = decoded.containsKey('longTextValue') ? (String) decoded.get('longTextValue') : null;
        this.answerDateTime = decoded.containsKey('answerDateTime') ? (Long) decoded.get('answerDateTime') : null;
        
    }

}