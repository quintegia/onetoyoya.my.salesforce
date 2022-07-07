public class QuestionData {
    
    public String id;
    public String brand;
    public String surveyId;
    public String groupingId;
    public String tree;
    public String question;
    public String label;
    public String questionType;
    public String helpText;
    public Long startDateTime;
    public Long endDateTime;
    public Boolean additional;
    public Boolean visible;
    public Boolean mandatory;
    public Boolean toConsider;
    public Decimal order;
    public Decimal totalAnswers;
    public List<QuestionOptionData> options = new List<QuestionOptionData>();
    public String color;
    
    public QuestionData(Domanda_questionario__c question, List<Opzione_Domanda__c> questionsOptions){
        
        this.id = question.Id;
        this.surveyId = question.Questionario__c;
        this.groupingId = question.Raggruppamento__c;
        this.tree = question.Albero__c;
        this.question = question.Domanda_IT__c;
        this.label = question.Etichetta_IT__c;
        this.questionType = question.Tipologia__c;
        this.helpText = question.Suggerimento__c;
        this.color = question.Raggruppamento__r.Gruppo__r.Colore__c;
        
        if(question.Data_Ora_Inizio__c != null){
            
        	this.startDateTime = question.Data_Ora_Inizio__c.getTime();
            
        }
        
        if(question.Data_Ora_Fine__c != null){
            
        	this.endDateTime = question.Data_Ora_Fine__c.getTime();
            
        }
        
        this.visible = question.Visibile__c;
        this.mandatory = question.Obbligatoria__c;
        this.toConsider = question.Considerare__c;
        this.order = question.Ordine__c;
        
        if(question.Risposte_questionario__r != null){
        
            this.totalAnswers = question.Risposte_questionario__r.size();
            
        }
        
        for(Opzione_Domanda__c qo : questionsOptions){
            
            if(qo.Insieme_Opzioni_Domanda__c != null && question.Insieme_Opzioni_Domanda__c != null && qo.Insieme_Opzioni_Domanda__c == question.Insieme_Opzioni_Domanda__c){
                
                this.options.add(new QuestionOptionData(qo));
                
            }
            
        }
        
    }
    
}