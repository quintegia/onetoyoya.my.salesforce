public class QCustomPeriod{
        
        public DateTime startDateTime;
        public DateTime endDateTime;
        public Double weight;
        
        public QCustomPeriod(Boolean previous, Double weight){
        
            DateTime currentDateTime = System.now();
            Integer startYear = currentDateTime.year();
            Integer startMonth = currentDateTime.month();
            Integer startDay = currentDateTime.day() >= 15 ? 15 : 1;
            
            if(previous && startDay < 15){
                startDay = 15;
                startMonth--;
                if(startMonth < 1){
                    startMonth = 12;
                    startYear--;
                }
            }
        
            DateTime periodStart = DateTime.newInstance(startYear, startMonth, startDay);
            
            Integer endYear = startYear;
            Integer endMonth = startMonth;
            Integer endDay = startDay >= 15 ? 1 : 15;
            
            if(endDay < 15){
                endMonth++;
                if(endMonth > 12){
                    endMonth = 1;
                    endYear++;
                }
            }
            
            //System.debug(endDay);
            
            DateTime periodEnd = DateTime.newInstance(endYear, endMonth, endDay);
            
            this.startDateTime = periodStart;
            this.endDateTime = periodEnd;
            
            this.weight = weight;
            
        }
        
        public QCustomPeriod getPrevious(Double weight){
            
            QCustomPeriod p = this.clone();
            
            p.endDateTime = p.startDateTime;
            
            Integer startYear = p.endDateTime.year();
            Integer startMonth = p.endDateTime.month();
            Integer startDay = p.endDateTime.day() >= 15 ? 1 : 15;
            
            if(startDay >= 15){
                startMonth--;
                if(startMonth < 1){
                    startMonth = 12;
                    startYear--;
                }
            }
            
            p.startDateTime = Datetime.newInstance(startYear, startMonth, startDay);
            
            p.weight = weight;
            
            return p;
            
        }
        
    }