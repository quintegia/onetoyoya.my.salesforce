public class QuestionOptionData {
    
    public String id;
    public String label;
    public String questionOption;
    public Decimal numericValue;
    public String textValue;
    
    public QuestionOptionData(Opzione_Domanda__c questionOption){
        
        this.id = questionOption.Id;
        this.label = questionOption.Etichetta_Risultati_IT__c;
        this.questionOption = questionOption.Opzione_Domanda_IT__c;
        this.numericValue = questionOption.Valore_Numerico__c;
        this.textValue = questionOption.Valore_Testuale__c;
        
    }
    
}