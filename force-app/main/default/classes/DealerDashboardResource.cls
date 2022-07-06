@RestResource(urlMapping = 
'/dealer_dashboard/*')
global class DealerDashboardResource {
	static Map<String, String> defaultColors = new Map<String, String>{'red' => '#CC0033', 'orange' => '#FF7F00', 'yellow' => '#fdd835', 'green' => '#4caf50', 'darkGreen' => '#1b5e20', 'grey' => '#666666'};
	static Map<String, String> chartColors = new Map<String, String>();

	static Map<String, String> dealerMapColors = new Map<String, String>();

	private static void setColors(Id appId) {

		chartColors = new Map<String, String>();
		dealerMapColors = new Map<String, String>();

		List<Configurazione_App__c> appConfigurations = [SELECT Id, 
		                                                        Name, 
		                                                        App__c, 
		                                                        Chiave__c, 
		                                                        Sezione__c, 
		                                                        Tipologia_Campo__c, 
		                                                        Campo_Testuale__c, 
		                                                        Campo_Numerico__c, 
		                                                        Campo_Booleano__c, 
		                                                        Campo_Data__c, 
		                                                        Campo_Data_Ora__c
		                                                 FROM Configurazione_App__c
		                                                 WHERE App__c = :appId AND (Sezione__c = :'Dealer Map' OR Sezione__c = :'Grafici')];

		for(Configurazione_App__c ca : appConfigurations) {

			if('Dealer Map'.equalsIgnoreCase(ca.Sezione__c)) {

				dealerMapColors.put(ca.Chiave__c, ca.Campo_Testuale__c);

			}
			else if('Grafici'.equalsIgnoreCase(ca.Sezione__c)) {

				chartColors.put(ca.Chiave__c, ca.Campo_Testuale__c);

			}

		}
	}

	@HttpGet
	global static void doGet() {

		CustomAuthentication ca = new CustomAuthentication(RestContext.request, RestContext.response);

		if(!ca.authenticate()) {

			ca.getResponse().send();

			return;

		}

		CustomResponse res = new CustomResponse(RestContext.response);

		//Id userId = 'a4n0E000000n0wsQAA';

		Utente__c u = ca.getUser();
		Id userId = u.Utente_Master__c != null ? u.Utente_Master__c : u.Id;

		setColors(ca.getAppId());

		Set<Id> userBrandsIds = RCCUtils.findUserGroupsByUserId(userId, false);

		List<Object> charts = new List<Object>();

		List<Object> dealerMap = getDealerMap(userId, userBrandsIds);

		if(dealerMap != null && dealerMap.size() > 0) {

			charts.addAll(dealerMap);

		}

		List<Object> currentDealerInsight = getDealerInsight2(userId, userBrandsIds);

		if(currentDealerInsight != null && currentDealerInsight.size() > 0) {

			charts.addAll(currentDealerInsight);

		}

		res.setStatusCode(200);
		res.setBody(charts);

		res.send();
	}

	class Answer {
		public String brand;

		public String answerId;

		public String groupingId;

		public Double value;

		public Double weight;

		public DateTime startDateTime;

		public DateTime endDateTime;

		Answer(String brand, String answerId, String groupingId, Double value, Double weight, DateTime startDateTime, DateTime endDateTime) {

			this.brand = brand;
			this.answerId = answerId;
			this.groupingId = groupingId;
			this.value = value;
			this.weight = weight;
			this.startDateTime = startDateTime;
			this.endDateTime = endDateTime;
		}
	}

	class Dealer {
		public String dealerId;

		public List<Answer> answers;

		Dealer(String dealerId) {

			this.dealerId = dealerId;
			this.answers = new List<Answer>();
		}

		public Set<String> getBrands() {

			Set<String> brands = new Set<String>();

			for(Answer a : this.answers) {

				brands.add(a.brand);

			}

			return brands;
		}

		public Double getValue(String brand, String groupingId, List<CustomPeriod> periods, List<Domanda_questionario__c> questions) {

			Double valueTimesWeightSum = 0;
			Double weightSum = 0;

			List<Answer> answersToConsiderList = new List<Answer>();

			List<List<Answer>> answersByPeriod = new List<List<Answer>>();
			List<List<Domanda_questionario__c>> questionsByPeriod = new List<List<Domanda_questionario__c>>();

			// Percentuali di rilevanza delle risposte
			// Più fresco è il dato e maggiore peso ha
			List<Double> percents = new List<Double>{0.5, 0.3, 0.2};

			for(Integer i = 0; i < periods.size(); i++) {

				CustomPeriod p = periods[i];
				answersByPeriod.add(new List<Answer>());
				questionsByPeriod.add(new List<Domanda_questionario__c>());

				for(Answer a : this.answers) {

					if(a.brand == brand && !((a.startDateTime < p.startDate && a.endDateTime < p.startDate) || (a.startDateTime > p.endDate && a.endDateTime > p.endDate))) {

						answersByPeriod[i].add(a);

					}

				}

				for(Domanda_questionario__c q : questions) {

					if(q.Raggruppamento__r.Gruppo__r.Name == brand && !((q.Data_Ora_Inizio_Analisi__c < p.startDate && q.Data_Ora_Fine_Analisi__c < p.startDate) || (q.Data_Ora_Inizio_Analisi__c > p.endDate && q.Data_Ora_Fine_Analisi__c > p.endDate))) {

						questionsByPeriod[0].add(q);

					}

				}

			}

			System.debug('answersByPeriod.size(): '+answersByPeriod.size());
			System.debug('questionsByPeriod.size(): '+questionsByPeriod.size());

			if(answersByPeriod.size() >= questionsByPeriod.size()) {

				for(Integer i = 0; i < periods.size(); i++) {

					CustomPeriod p = periods[i];
					Double percent = percents[i];

					for(Answer a : answersByPeriod[i]) {

						Double weight = a.weight > 0 ? a.weight : 1;

						if(a.brand == brand && a.groupingId == groupingId && !((a.startDateTime < p.startDate && a.endDateTime < p.startDate) || (a.startDateTime > p.endDate && a.endDateTime > p.endDate))) {

							valueTimesWeightSum += a.value * weight * percent;
							weightSum += weight * percent;

						}

					}

				}

				if(valueTimesWeightSum > 0 && weightSum > 0) {

					Double result = valueTimesWeightSum / weightSum;

					return transposeWithZero(result);

				}

			}

			return null;

			/*
			// Per ogni periodo verifico verifico quante risposte ho dato a fronte del numero di domande di quel periodo
			// Se il numero di risposte è maggiore o uguale (teoricamente dovrebbe essere uguale) al numero di domande, allora lo considero nelle analisi
			// altrimenti lo scarto e non lo tengi in considerazione.
			 for(CustomPeriod p : periods){

			 List<Answer> periodAnswers = new List<Answer>();

			 for(Answer a : this.answers){

			 if(a.brand == brand &&
			 !((a.startDateTime < p.startDate && a.endDateTime < p.startDate) ||
			 (a.startDateTime > p.endDate && a.endDateTime > p.endDate))
			 ){

			//System.debug('a: ' + a);

			 periodAnswers.add(a);

			 }

			 }

			 Integer totalQuestions = 0;

			 for(Domanda_questionario__c q : questions){

			 if(q.Raggruppamento__r.Gruppo__r.Name == brand &&
			 !((q.Data_Ora_Inizio_Analisi__c < p.startDate && q.Data_Ora_Fine_Analisi__c < p.startDate) ||
			 (q.Data_Ora_Inizio_Analisi__c > p.endDate && q.Data_Ora_Fine_Analisi__c > p.endDate))
			 ){

			//System.debug('q: ' + q);

			 totalQuestions++;

			 }

			 }

			 if(periodAnswers.size() >= totalQuestions){

			 answersToConsiderList.addAll(periodAnswers);

			 }

			//System.debug('p: ' + p);
			//System.debug('periodAnswers: ' + periodAnswers.size());
			//System.debug('totalQuestions: ' + totalQuestions);

			 }

			 Integer i = 0;

			 for(CustomPeriod p : periods){

			 Double percent = percents.get(i);

			 for(Answer a : this.answers){

			 Double weight = a.weight > 0 ? a.weight : 1;

			 if(a.brand == brand &&
			 a.groupingId == groupingId &&
			 !((a.startDateTime < p.startDate && a.endDateTime < p.startDate) ||
			 (a.startDateTime > p.endDate && a.endDateTime > p.endDate))
			 ){

			 valueTimesWeightSum += a.value * weight * percent;
			 weightSum += weight * percent;

			 }

			 }

			 i++;

			 }

			 if(answersToConsiderList.size() > 0){

			 Double result = valueTimesWeightSum / weightSum;

			 return transpose(result);

			 }

			 return null;*/
		}

		public Double getDotSize(String userId) {

			Double dotSize = 1;

			if(userId == this.dealerId) {

				dotSize = 5;

			}

			return dotSize;
		}

		public String getDotColor(String brand, List<CustomPeriod> periods, List<Domanda_questionario__c> questions) {

			String dotColor = dealerMapColors.containsKey('colore_rosso') ? dealerMapColors.get('colore_rosso') : defaultColors.get('red');

			Integer counter = 0;

			for(CustomPeriod p : periods) {

				List<Answer> periodAnswers = new List<Answer>();

				for(Answer a : this.answers) {

					if(a.brand == brand && !((a.startDateTime < p.startDate && a.endDateTime < p.startDate) || (a.startDateTime > p.endDate && a.endDateTime > p.endDate))) {

						periodAnswers.add(a);

					}

				}

				Integer totalQuestions = 0;

				for(Domanda_questionario__c q : questions) {

					if(q.Raggruppamento__r.Gruppo__r.Name == brand && !((q.Data_Ora_Inizio_Analisi__c < p.startDate && q.Data_Ora_Fine_Analisi__c < p.startDate) || (q.Data_Ora_Inizio_Analisi__c > p.endDate && q.Data_Ora_Fine_Analisi__c > p.endDate))) {

						totalQuestions++;

					}

				}

				//System.debug('p: ' + p);
				//System.debug('periodAnswers: ' + periodAnswers.size());
				//System.debug('totalQuestions: ' + totalQuestions);

				if(periodAnswers.size() >= totalQuestions) {

					counter++;

				}

			}

			if(counter >= 3) {

				dotColor = dealerMapColors.containsKey('colore_verde_scuro') ? dealerMapColors.get('colore_verde_scuro') : defaultColors.get('darkGreen');

			}
			else if(counter >= 2) {

				dotColor = dealerMapColors.containsKey('colore_giallo') ? dealerMapColors.get('colore_giallo') : defaultColors.get('yellow');

			}

			return dotColor;
		}
	}

	class CustomPeriod {
		Date startDate;

		Date endDate;

		public void setStartDateBasedOnCurrentDate() {

			this.startDate = System.today();

			Integer targetDay = this.startDate.day() >= 15 ? 15 : 1;

			while(this.startDate.day() != targetDay) {

				this.startDate = this.startDate.addDays(-1);

			}
		}

		public void setStartDateAsPreviousPeriodBasedOnStartDate() {

			if(this.startDate != null) {

				this.startDate = this.startDate.addDays(-1);

				Integer targetDay = this.startDate.day() >= 15 ? 15 : 1;

				while(this.startDate.day() != targetDay) {

					this.startDate = this.startDate.addDays(-1);

				}

			}
		}

		public void setEndDateBasedOnStartDate() {

			if(this.startDate != null) {

				this.endDate = Date.newInstance(this.startDate.year(), this.startDate.month(), this.startDate.day());

				Integer targetDay = this.endDate.day() < 15 ? 15 : 1;

				while(this.endDate.day() != targetDay) {

					this.endDate = this.endDate.addDays(1);

				}

			}
		}
	}

	/********************************
	 ********************************
	 ********** DEALER MAP **********
	 ********************************
	 ********************************/
	// Genero le mappe per marchio
	public static List<Object> getDealerMap(Id userId, Set<Id> userBrandsIds) {

		String chartTitle = 'Dealer Map';

		List<Object> charts = new List<Object>();
		Set<Id> groupingsIds = new Set<Id>();
		List<String> indexes = new List<String>();
		List<String> indexesIds = new List<String>();

		List<Gruppo__c> brands = [SELECT Id, 
		                                 Name, 
		                                 Genitore__c, 
		                                 Tipologia__c
		                          FROM Gruppo__c
		                          WHERE Id IN :userBrandsIds AND Tipologia__c = 'Marchio'];

		// Recupero i raggruppamenti necessari a generare la mappa. (Business con TMI e Dealer Motivation)
		List<Raggruppamento__c> groupings = [SELECT Id, 
		                                            Name, 
		                                            Genitore__r.Etichetta_IT__c, 
		                                            Gruppo__r.Name, 
		                                            Genitore__c, 
		                                            Gruppo__r.Colore__c
		                                     FROM Raggruppamento__c
		                                     WHERE Gruppo__c IN :userBrandsIds AND Genitore__r.Visualizzabile_Da_Dealer_In__c = :chartTitle
		                                     ORDER BY Gruppo__r.Name DESC, Genitore__r.Etichetta_IT__c ASC];

		// Metto le etichette in una lista, mi servirà per popolare le labels della mappa.
		// TODO: Da inserire l'ordine nei raggruppamenti?
		for(Raggruppamento__c grouping : groupings) {

			if(!indexes.contains(grouping.Genitore__r.Etichetta_IT__c)) {
				indexes.add(grouping.Genitore__r.Etichetta_IT__c);
				indexesIds.add(grouping.Genitore__c);
			}

		}

		// Se ci sono più di 2 indici c'è qualcosa che non va...
		if(indexes.size() != 2) {

			return null;

		}

		// Creo il set degli id dei raggruppamenti
		for(Raggruppamento__c grouping : groupings) {

			System.debug('grouping: '+grouping);

			groupingsIds.add(grouping.Id);

		}

		Set<Id> questionsIds = new Set<Id>();

		// Imposto le date del periodo da prendere in considerazione.
		// Attualmente quindicinale.

		// Recupero mese corrente e giorno corrente per capire che periodo di riferimento prendere.

		CustomPeriod currentSubPeriod = new CustomPeriod();

		currentSubPeriod.setStartDateBasedOnCurrentDate();
		currentSubPeriod.setEndDateBasedOnStartDate();
		//currentSubPeriod.endDate = System.today();

		System.debug('currentSubPeriod: '+currentSubPeriod);

		// Verifico se in questo periodo è già partita una rilevazione altrimenti passo al periodo precedente.

		/*Integer numberOfQuestions = [SELECT COUNT()
		 FROM Domanda_questionario__c
		 WHERE Raggruppamento__c IN :groupingsIds
		 AND Data_Ora_Inizio_Analisi__c >= :currentSubPeriod.startDate AND Data_Ora_Inizio_Analisi__c <= :currentSubPeriod.endDate];*/

		Integer numberOfQuestions = [SELECT COUNT()
		                             FROM Domanda_Questionario__c
		                             WHERE Raggruppamento__c IN :groupingsIds /* AND Obbligatoria__c = true  AND Obbligatoria_Per_Risultati__c != 'Dealer Dashboard' */
		 AND (Raggruppamento__r.Visualizzabile_Da_Dealer_In__c = :chartTitle OR Raggruppamento__r.Genitore__r.Visualizzabile_Da_Dealer_In__c = :chartTitle)//AND Data_Ora_Inizio_Analisi__c >= :currentSubPeriod.startDate AND Data_Ora_Inizio_Analisi__c <= :System.now()
		 AND Data_Ora_Inizio__c <= :System.now() AND Data_Ora_Fine__c >= :System.now()];

		//System.debug(numberOfQuestions);
		//System.debug(currentSubPeriod);

		System.debug('numberOfQuestions: '+numberOfQuestions);

		List<CustomPeriod> periods = new List<CustomPeriod>();

		CustomPeriod currentPeriod = new CustomPeriod();

		currentPeriod.setStartDateBasedOnCurrentDate();

		if(numberOfQuestions == 0) {

			currentPeriod.setStartDateAsPreviousPeriodBasedOnStartDate();

		}

		currentPeriod.setEndDateBasedOnStartDate();

		//System.debug('currentPeriod: ' + currentPeriod);

		periods.add(currentPeriod);

		Date previusDate = Date.newInstance(currentPeriod.startDate.year(), currentPeriod.startDate.month(), currentPeriod.startDate.day());

		for(Integer i = 0; i < 2; i++) {

			CustomPeriod p = new CustomPeriod();

			p.startDate = previusDate;

			p.setStartDateAsPreviousPeriodBasedOnStartDate();
			p.setEndDateBasedOnStartDate();

			periods.add(p);

			previusDate = Date.newInstance(p.startDate.year(), p.startDate.month(), p.startDate.day());

		}

		//System.debug(periods);

		for(CustomPeriod p : periods) {

			System.debug(p);

		}

		CustomPeriod startPeriod = periods[periods.size()-1];
		CustomPeriod endPeriod = periods[0];

		System.debug('startPeriod.startDate: '+startPeriod.startDate);
		System.debug('endPeriod.endDate: '+endPeriod.endDate);

		DateTime fromDateTime = periods[periods.size()-1].startDate;
		DateTime toDateTime = periods[0].endDate;

		// Recupero tutte le domande che fanno parte dei raggruppamenti facenti parte degli indici.
		List<Domanda_questionario__c> questions = [SELECT Id, 
		                                                  Name, 
		                                                  Domanda_IT__c, 
		                                                  Data_Ora_Inizio__c, 
		                                                  Data_Ora_Fine__c, 
		                                                  Raggruppamento__r.Gruppo__r.Name, 
		                                                  Data_Ora_Inizio_Analisi__c, 
		                                                  Data_Ora_Fine_Analisi__c
		                                           FROM Domanda_questionario__c
		                                           WHERE Raggruppamento__c IN :groupingsIds/*AND Data_Ora_Inizio_Analisi__c >= :System.now().addMonths(-4)
		 AND Data_Ora_Fine_Analisi__c <= :System.now().addMonths(1)*/
		 AND Data_Ora_Inizio_Analisi__c >= :fromDateTime AND Data_Ora_Inizio_Analisi__c <= :toDateTime];

		System.debug('questions.size(): '+questions.size());
		//System.debug(startPeriod);
		//System.debug(endPeriod);

		Datetime startLimit = null;

		// Recupero gli id delle domande.
		for(Domanda_questionario__c question : questions) {

			System.debug('question: '+question);

			questionsIds.add(question.Id);

			if((startLimit == null || startLimit > question.Data_Ora_Inizio_Analisi__c) && question.Data_Ora_Inizio_Analisi__c != null) {

				startLimit = question.Data_Ora_Inizio_Analisi__c;

			}

		}

		System.debug('startLimit: '+startLimit);
		System.debug('questionsIds.size(): '+questionsIds.size());
		System.debug('questionsIds: '+questionsIds);

		List<Risposta_questionario__c> allUsersAnswers = [SELECT Name, 
		                                                         Utente__c, 
		                                                         Valore_Numerico__c, 
		                                                         Valore_Testuale__c, 
		                                                         Valore_Testuale_Lungo__c, 
		                                                         Domanda_questionario__r.Raggruppamento__c, 
		                                                         Domanda_questionario__r.Raggruppamento__r.Genitore__c, 
		                                                         Domanda_questionario__r.Raggruppamento__r.Gruppo__r.Name, 
		                                                         Domanda_questionario__r.Raggruppamento__r.Peso_Genitore__c, 
		                                                         Domanda_questionario__r.Data_Ora_Inizio__c, 
		                                                         Valore_Numerico_Per_Peso_Raggruppamento__c, 
		                                                         Domanda_questionario__r.Data_Ora_Fine__c, 
		                                                         Utente__r.Non_Considerare_Analisi__c, 
		                                                         Domanda_questionario__r.Data_Ora_Inizio_Analisi__c, 
		                                                         Domanda_questionario__r.Data_Ora_Fine_Analisi__c, 
		                                                         Data_Ora_Risposta__c
		                                                  FROM Risposta_questionario__c
		                                                  WHERE Domanda_questionario__c = :questionsIds AND (Risposta_questionario__c.Valore_Numerico__c != null OR Risposta_questionario__c.Valore_Testuale__c != null)
		                                                  ORDER BY Domanda_questionario__r.Raggruppamento__r.Gruppo__r.Name ASC, Utente__c ASC, Domanda_questionario__r.Raggruppamento__c ASC];

		List<Risposta_questionario__c> answers = new List<Risposta_questionario__c>();

		Id parentBrandId = null;

		for(Gruppo__c brand : brands) {

			parentBrandId = brand.Genitore__c;

			System.debug(brand.Name+' - '+brand.Id+' - '+brand.Genitore__c);

		}

		System.debug('allUsersAnswers.size()'+allUsersAnswers.size());

		for(Risposta_questionario__c r : allUsersAnswers) {

			System.debug(r.Domanda_questionario__r.Raggruppamento__r.Gruppo__r.Name+' - '+r.Domanda_questionario__r.Raggruppamento__r.Gruppo__c+' - '+parentBrandId);

			if(r.Domanda_questionario__r.Raggruppamento__r.Gruppo__c == parentBrandId) {

				for(Gruppo__c brand : brands) {

					Risposta_questionario__c newAnswer = r;

					newAnswer.Domanda_questionario__r.Raggruppamento__r.Gruppo__c = brand.Id;
					newAnswer.Domanda_questionario__r.Raggruppamento__r.Gruppo__r.Name = brand.Name;

					answers.add(newAnswer);

				}

			}
			else {

				answers.add(r);

			}

		}

		System.debug('answers.size(): '+answers.size());

		Datetime lastAnswerDateTime = null;

		Map<String, Dealer> dealers = new Map<String, Dealer>();

		for(Risposta_questionario__c answer : answers) {

			if(!answer.Utente__r.Non_Considerare_Analisi__c || answer.Utente__c == userId) {

				if(answer.Data_Ora_Risposta__c != null && (lastAnswerDateTime == null || lastAnswerDateTime.getTime() <= answer.Data_Ora_Risposta__c.getTime())) {

					lastAnswerDateTime = answer.Data_Ora_Risposta__c;

				}

				if(!dealers.containsKey(answer.Utente__c)) {

					Dealer d = new Dealer(answer.Utente__c);
					dealers.put(d.dealerId, d);

				}

				dealers.get(answer.Utente__c).answers.add(new Answer(answer.Domanda_questionario__r.Raggruppamento__r.Gruppo__r.Name, answer.Id, answer.Domanda_questionario__r.Raggruppamento__r.Genitore__c, Double.valueOf(answer.Valore_Numerico__c), Double.valueOf(answer.Domanda_questionario__r.Raggruppamento__r.Peso_Genitore__c), answer.Domanda_questionario__r.Data_Ora_Inizio_Analisi__c, answer.Domanda_questionario__r.Data_Ora_Fine_Analisi__c));

			}

		}

		String chartSubtitle = null;

		/*DateTime fromDateTime = periods[periods.size() - 1].startDate;
		 DateTime toDateTime = periods[0].endDate;*/

		String fromDateTimeFormatted = RCCUtils.dateFormat(fromDateTime.date());
		String toDateTimeFormatted = RCCUtils.dateFormat(toDateTime.date());

		//chartSubtitle = '<div>Media dei Dealer<br/>(dal ' + fromDateTimeFormatted + ' al ' + toDateTimeFormatted + ')</div>';

		if(lastAnswerDateTime != null) {

			chartSubtitle = 'Ultimo aggiornamento: '+RCCUtils.dateFormat(Date.newInstance(lastAnswerDateTime.year(), lastAnswerDateTime.month(), lastAnswerDateTime.day()));

		}

		//chartSubtitle = 'Ultimo aggiornamento: ' + RCCUtils.dateFormat(System.today()); //TODO Da sostituire con data ultima risposta

		// Imposto le etichette al grafico.
		BubbleChartLabelsData bubbleChartLabelsData = new BubbleChartLabelsData(indexes[0], indexes[1]);

		Map<String, BubbleChartData> bubbleCharts = new Map<String, BubbleChartData>();

		// Per ogni raggruppamento inizializzo la mappa con titolo, sottotitolo, marchio ed etichette.
		for(Raggruppamento__c grouping : groupings) {

			BubbleChartData bubbleChart = new BubbleChartData(chartTitle, chartSubtitle, grouping.Gruppo__r.Name, bubbleChartLabelsData);
			bubbleChart.color = grouping.Gruppo__r.Colore__c;

			bubbleChart.info = 'La <strong>Dealer Map</strong> monitora lo status dei Dealer del Marchio secondo le risposte raccolte nell\'ultimo mese e mezzo.<br /><br />'+'Si compone degli indici sintetici di \'Dealer Motivation\' e \'Business con TMI\' calcolati sulla base di un set specifico di quesiti.<br /><br />'+'Ciascun Dealer, identificato da un punto nel grafico, è colorato in base al grado di affidabilità del risultato medio (<strong>completezza</strong>), calcolato in base al numero di quesiti a cui ha risposto (scala da rosso meno completo, a verde più completo).<br /><br />'+'La tua <strong>posizione nel grafico</strong> è identificata dal pallino in evidenza.';

			bubbleCharts.put(grouping.Gruppo__r.Name, bubbleChart);

		}

		Set<String> currentUserBrandAnswers = new Set<String>();

		for(String dealerKey : dealers.keySet()) {

			Dealer d = dealers.get(dealerKey);
			Set<String> dealerBrands = d.getBrands();

			for(String brand : dealerBrands) {

				Double x = d.getValue(brand, indexesIds[0], periods, questions);
				Double y = d.getValue(brand, indexesIds[1], periods, questions);
				Double dotSize = d.getDotSize(userId);
				String dotColor = d.getDotColor(brand, periods, questions);

				System.debug('[VALUES] brand: '+brand+' dealerKey: '+dealerKey+' x: '+x+' - y: '+y+' - dotSize: '+dotSize+' - dotColor: '+dotColor);

				if(x != null && y != null) {

					bubbleCharts.get(brand).addDot(new BubbleChartDotData(x, y, dotSize, dotColor));

				}

			}

			if(d.dealerId == userId && d.getBrands().size() > 0) {

				currentUserBrandAnswers.addAll(d.getBrands());

			}

		}

		for(String brand : bubbleCharts.keySet()) {

			if(currentUserBrandAnswers.contains(brand)) {

				charts.add(bubbleCharts.get(brand));

			}

		}

		return charts;
	}

	/********************************
	 ********************************
	 ******** DEALER INSIGHT 2 ******
	 ********************************
	 ********************************/
	public static List<Object> getDealerInsight2(Id userId, Set<Id> userBrandsIds) {

		List<Object> charts = new List<Object>();
		String chartTitle = 'Dealer Insight';
		DateTime currentDateTime = System.now();

		Map<String, Integer> dealerCountByBrand = dealerCount();
		List<Gruppo__c> brands = getBrandsByGroupsIds(userBrandsIds);
		List<Raggruppamento__c> groupings = getGroupingsByGroupsIdsAndSectionName(userBrandsIds, chartTitle);
		List<Domanda_questionario__c> questions = getQuestionsByGroupingsWithRange(groupings, System.now().addMonths(-6), System.now());
		List<Risposta_questionario__c> answers = getAnswersByQuestions(questions);
		Map<Id, Set<Id>> usersBrands = getUsersBrands();

		Map<String, Gruppo__c> brandsById = new Map<String, Gruppo__c>();

		System.debug(dealerCountByBrand);
		System.debug(brands.size());
		System.debug(groupings.size());
		System.debug(questions.size());
		System.debug(answers.size());

		Set<Id> allBrandsIds = new Set<Id>();

		for(Gruppo__c b : brands) {

			allBrandsIds.add(b.Id);
			brandsById.put(b.Id, b);

		}

		Map<String, Map<String, Map<String, Map<String, List<Object>>>>> answersByBrandIdFrequencyGroupingIdAndQuestionId = new Map<String, Map<String, Map<String, Map<String, List<Object>>>>>();

		for(Risposta_questionario__c a : answers) {

			Set<String> brandsIds = new Set<String>();
			String frequency = a.Domanda_questionario__r.Frequenza__c;
			String groupingId = a.Domanda_questionario__r.Raggruppamento__c;
			String questionId = a.Domanda_questionario__c;
			String groupingLabel = a.Domanda_questionario__r.Raggruppamento__r.Etichetta_IT__c;
			String questionLabel = a.Domanda_questionario__r.Domanda_IT__c;
			Decimal value = a.Valore_Numerico__c;
			Datetime startDate = a.Domanda_questionario__r.Data_Ora_Inizio__c;
			Datetime endDate = a.Domanda_questionario__r.Data_Ora_Fine__c;
			Datetime startAnalysisDate = a.Domanda_questionario__r.Data_Ora_Inizio_Analisi__c;
			Datetime endAnalysisDate = a.Domanda_questionario__r.Data_Ora_Fine_Analisi__c;
			String answerUserId = a.Utente__c;
			Boolean toConsider = !a.Utente__r.Non_Considerare_Analisi__c;

			if(frequency == 'Mens.' || frequency == '15 gg') {

				frequency = 'Mensili';

			}
			else if(frequency == 'Trim.') {

				frequency = 'Trimestrali';

			}

			if(allBrandsIds.contains(a.Domanda_questionario__r.Raggruppamento__r.Gruppo__c)) {

				brandsIds.add(a.Domanda_questionario__r.Raggruppamento__r.Gruppo__c);

			}
			else {

				for(Gruppo__c b : brands) {

					brandsIds.add(b.Id);

				}

			}

			for(String brandId : brandsIds) {

				if(!answersByBrandIdFrequencyGroupingIdAndQuestionId.containsKey(brandId)) {

					answersByBrandIdFrequencyGroupingIdAndQuestionId.put(brandId, new Map<String, Map<String, Map<String, List<Object>>>>());

				}

				Map<String, Map<String, Map<String, List<Object>>>> byBrand = answersByBrandIdFrequencyGroupingIdAndQuestionId.get(brandId);

				if(!byBrand.containsKey(frequency)) {

					byBrand.put(frequency, new Map<String, Map<String, List<Object>>>());

				}

				Map<String, Map<String, List<Object>>> byFrequency = byBrand.get(frequency);

				if(!byFrequency.containsKey(groupingId)) {

					byFrequency.put(groupingId, new Map<String, List<Object>>());

				}

				Map<String, List<Object>> byGrouping = byFrequency.get(groupingId);

				if(!byGrouping.containsKey(questionId)) {

					byGrouping.put(questionId, new List<Object>());

				}

				List<Object> byQuestionId = byGrouping.get(questionId);

				if(usersBrands.containsKey(answerUserId) && usersBrands.get(answerUserId).contains(brandId)) {

					byQuestionId.add(new Map<String, Object>{'groupingLabel' => groupingLabel, 'questionLabel' => questionLabel, 'value' => value, 'startDate' => startDate, 'endDate' => endDate, 'startAnalysisDate' => startAnalysisDate, 'endAnalysisDate' => endAnalysisDate, 'answerUserId' => answerUserId, 'toConsider' => toConsider});

				}

			}

		}

		for(String brandId : answersByBrandIdFrequencyGroupingIdAndQuestionId.keySet()) {

			Map<String, Map<String, Map<String, List<Object>>>> answersByFrequencyGroupingIdAndQuestionId = answersByBrandIdFrequencyGroupingIdAndQuestionId.get(brandId);
			Integer brandDealerCount = dealerCountByBrand.get(brandId);
			Gruppo__c brand = brandsById.get(brandId);

			List<String> frequencies = new List<String>();
			frequencies.addAll(answersByFrequencyGroupingIdAndQuestionId.keySet());

			frequencies.sort();

			for(String frequency : frequencies) {

				String brandName = '';
				String brandColor = null;

				for(Gruppo__c b : brands) {

					if(b.Id == brandId) {

						brandName = b.Name;
						brandColor = b.Colore__c;

					}

				}

				BarChartData chart = new BarChartData('Insight '+frequency, null, brandName);
				chart.color = brandColor;

				chart.info = 'Gli <strong>Insight</strong> approfondiscono, con cadenza mensile o trimestrale, diversi ambiti relativi alla Dealer Motivation e al Business con TMI.<br/><br/>'+'Nel grafico viene riportata, per ciascuna tematica, <strong>la tua risposta a confronto con la media della rete.</strong> È inoltre evidenziata la data dell’ultima risposta raccolta e se la rilevazione è in corso. <strong>Cliccando nelle barre del grafico</strong> è possibile visualizzare la domanda estesa e il campione rispondenti.<br/><br/>'+'I risultati sono presentati al raggiungimento di un livello minimo del campione. Se non visualizzi alcuni tuoi risultati e il quesito è "in corso" puoi rispondere alle domande attive nella sezione “Quesiti”.';

				List<BarChartBarData> barChartBarDataUserList = new List<BarChartBarData>();
				List<BarChartBarData> barChartBarDataSampleList = new List<BarChartBarData>();

				Map<String, Map<String, List<Object>>> answersByGroupingIdAndQuestionId = answersByFrequencyGroupingIdAndQuestionId.get(frequency);

				for(String groupingId : answersByGroupingIdAndQuestionId.keySet()) {

					Map<String, List<Object>> answersByQuestionId = answersByGroupingIdAndQuestionId.get(groupingId);
					List<Object> lastQuestionAnswers = new List<Object>();

					for(String questionId : answersByQuestionId.keySet()) {

						List<Object> allAnswers = answersByQuestionId.get(questionId);
						Boolean addAnswers = false;

						for(Object o : allAnswers) {

							Map<String, Object> m = (Map<String, Object>)o;

							Datetime startDate = (Datetime)m.get('startDate');
							Datetime endDate = (Datetime)m.get('endDate');
							String answerUserId = (String)m.get('answerUserId');

							if((userId == answerUserId) || (startDate <= System.now() && endDate >= System.now())) {

								addAnswers = true;

							}

						}

						if(/*allAnswers.size() > brandDealerCount * (brand.Campione_Minimo_Percentuale__c / 100.0) && addAnswers && */lastQuestionAnswers.size() == 0) {

							lastQuestionAnswers.addAll(allAnswers);

						}

					}

					System.debug('lastQuestionAnswers: '+lastQuestionAnswers);

					Double userValue = 0;
					Double sampleAverage = 0;
					String groupingLabel = '';
					String questionLabel = '';
					Datetime startDate = null;
					Datetime endDate = null;

					Integer sampleSize = lastQuestionAnswers.size();

					if(sampleSize > 0) {

						for(Object o : lastQuestionAnswers) {

							Map<String, Object> m = (Map<String, Object>)o;

							groupingLabel = (String)m.get('groupingLabel');
							questionLabel = (String)m.get('questionLabel');
							startDate = (Datetime)m.get('startDate');
							endDate = (Datetime)m.get('endDate');
							Boolean toConsider = (Boolean)m.get('toConsider');

							Decimal value = (Decimal)m.get('value');
							String answerUserId = (String)m.get('answerUserId');

							if(answerUserId == userId) {

								userValue = value;

							}

							if(toConsider) {

								sampleAverage += value;

							}
							else {

								sampleSize--;

							}

						}

						if(sampleSize > 0) {

							sampleAverage /= sampleSize;
							sampleAverage = transpose(sampleAverage);

						}

						userValue = transpose(userValue);

						String startDateString = RCCUtils.dateFormat(Date.newInstance(startDate.year(), startDate.month(), startDate.day()));

						String endDateString = RCCUtils.dateFormat(Date.newInstance(endDate.year(), endDate.month(), endDate.day()));

						Boolean running = false;

						if(endDate > System.now()) {

							endDateString = RCCUtils.dateFormat(System.today());

							running = true;

						}

						List<String> endDateStringSplitted = endDateString.split(' ');
						Decimal percent = 100 * (Decimal.valueOf(sampleSize) / Decimal.valueOf(brandDealerCount));

						groupingLabel += '\nUltima risposta: '+endDateStringSplitted[0]+' '+endDateStringSplitted[1];

						String info = '<strong>Inizio rilevazione:</strong> '+startDateString+'<br/>'+'<strong>Termine rilevazione:</strong> '+RCCUtils.dateFormat(Date.newInstance(endDate.year(), endDate.month(), endDate.day()))+'<br/>'+'<strong>Rispondenti:</strong> '+String.valueOf(percent.setScale(0))+'%';

						if(running) {

							groupingLabel += '\n(Rilevazione in corso)';
							info += ' (Rilevazione in corso)';

						}

						if(userValue <= 0) {

							groupingLabel += ' *';
							info += ' *';

						}

						BarChartBarData barChartBarDataUser = new BarChartBarData(groupingLabel, null, Double.valueOf(userValue), getColorByValue(Double.valueOf(userValue)));

						barChartBarDataUser.extra = questionLabel;
						barChartBarDataUser.info = info;

						BarChartBarData barChartBarDataSample = new BarChartBarData(groupingLabel, null, Double.valueOf(sampleAverage), getColorByValue(Double.valueOf(sampleAverage)));

						barChartBarDataSample.extra = questionLabel;
						barChartBarDataSample.info = info;

						barChartBarDataUserList.add(barChartBarDataUser);

						if(userValue > 0) {

							barChartBarDataSampleList.add(barChartBarDataSample);

						}

					}

				}

				Boolean addChart = false;

				String noData = '* Il dato verrà visualizzato non appena saranno presenti delle risposte per questo indicatore.';

				if(barChartBarDataUserList.size() > 0) {

					chart.addBarChartBarListData(barChartBarDataUserList);
					chart.post = noData;
					addChart = true;

				}

				if(barChartBarDataSampleList.size() > 0) {

					chart.addBarChartBarListData(barChartBarDataSampleList);
					chart.post = noData;
					addChart = true;

				}

				if(addChart) {

					charts.add(chart);

				}

			}

		}

		return charts;
	}

	private static List<Gruppo__c> getBrandsByGroupsIds(Set<Id> groupsIds) {

		return [SELECT Id, 
		               Name, 
		               Genitore__c, 
		               Tipologia__c, 
		               Ordine__c, 
		               Campione_Minimo_Percentuale__c, 
		               Colore__c
		        FROM Gruppo__c
		        WHERE Id IN :groupsIds AND Tipologia__c = 'Marchio'];
	}

	private static List<Raggruppamento__c> getGroupingsByGroupsIdsAndSectionName(Set<Id> groupsIds, String section) {

		return [SELECT Id, 
		               Name
		        FROM Raggruppamento__c
		        WHERE Gruppo__c IN :groupsIds AND Visualizzabile_Da_Dealer_In__c = :section];
	}

	private static List<Domanda_questionario__c> getQuestionsByGroupingsWithRange(List<Raggruppamento__c> groupings, Datetime fromDateTime, Datetime toDateTime) {

		return [SELECT Id, 
		               Data_Ora_Inizio__c, 
		               Data_Ora_Inizio_Analisi__c, 
		               Raggruppamento__c, 
		               Raggruppamento__r.Gruppo__c, 
		               Data_Ora_Fine_Analisi__c
		        FROM Domanda_questionario__c
		        WHERE Raggruppamento__c IN :groupings AND Data_Ora_Inizio_Analisi__c >= :fromDateTime AND Data_Ora_Inizio_Analisi__c <= :toDateTime
		        ORDER BY Data_Ora_Inizio_Analisi__c DESC];
	}

	private static Map<String, Integer> dealerCount() {

		Map<String, Integer> result = new Map<String, Integer>();

		List<AggregateResult> usersGroupsAggregated = [SELECT COUNT(Id), Gruppo__r.Genitore__r.Genitore__c
		                                               FROM Utente_Gruppo__c
		                                               WHERE Utente__r.Tipologia__c = 'Dealer' AND Utente__r.Non_Considerare_Analisi__c = false
		                                               GROUP BY Gruppo__r.Genitore__r.Genitore__c];

		// Totale rispondenti per marchio
		for(AggregateResult ar : usersGroupsAggregated) {

			Id groupId = (Id)ar.get('Genitore__c');
			Integer counter = (Integer)ar.get('expr0');

			result.put(groupId, counter);

		}

		return result;
	}

	private static List<Risposta_Questionario__c> getAnswersByQuestions(List<Domanda_questionario__c> questions) {

		return [SELECT Utente__c, 
		               Domanda_Questionario__r.Raggruppamento__c, 
		               Domanda_Questionario__r.Data_Ora_Inizio__c, 
		               Domanda_Questionario__r.Data_Ora_Fine__c, 
		               Domanda_questionario__r.Raggruppamento__r.Etichetta_IT__c, 
		               Domanda_questionario__r.Raggruppamento__r.Gruppo__r.Name, 
		               Valore_Numerico__c, 
		               Domanda_questionario__r.Raggruppamento__r.Gruppo__c, 
		               Domanda_questionario__r.Frequenza__c, 
		               Domanda_questionario__r.Domanda_IT__c, 
		               Domanda_Questionario__c, 
		               Utente__r.Non_Considerare_Analisi__c, 
		               Domanda_Questionario__r.Data_Ora_Inizio_Analisi__c, 
		               Domanda_Questionario__r.Data_Ora_Fine_Analisi__c
		        FROM Risposta_questionario__c
		        WHERE Domanda_questionario__c IN :questions AND (Risposta_questionario__c.Valore_Numerico__c != null OR Risposta_questionario__c.Valore_Testuale__c != null)
		        ORDER BY Domanda_Questionario__r.Data_Ora_Inizio__c DESC];
	}

	private static Map<Id, Set<Id>> getUsersBrands() {

		Map<Id, Set<Id>> usersBrands = new Map<Id, Set<Id>>();

		List<Utente_Gruppo__c> usersGroups = [SELECT Utente__c, 
		                                             Gruppo__r.Genitore__r.Genitore__c
		                                      FROM Utente_Gruppo__c
		                                      WHERE Utente__r.Tipologia__c = 'Dealer' /*AND Utente__r.Non_Considerare_Analisi__c = false*/];

		for(Utente_Gruppo__c ug : usersGroups) {

			if(!usersBrands.containsKey(ug.Utente__c)) {

				usersBrands.put(ug.Utente__c, new Set<Id>());

			}

			usersBrands.get(ug.Utente__c).add(ug.Gruppo__r.Genitore__r.Genitore__c);

		}

		return usersBrands;
	}

	public static String getColorByValue(Double value) {

		if(value >= 0 && value < 20) {
			return chartColors.containsKey('colore_rosso') ? chartColors.get('colore_rosso') : defaultColors.get('red');
		}
		else if(value >= 20 && value < 40) {
			return chartColors.containsKey('colore_arancione') ? chartColors.get('colore_arancione') : defaultColors.get('orange');
		}
		else if(value >= 40 && value < 60) {
			return chartColors.containsKey('colore_verde_chiaro') ? chartColors.get('colore_giallo') : defaultColors.get('yellow');
		}
		else if(value >= 60 && value < 80) {
			return chartColors.containsKey('colore_verde_chiaro') ? chartColors.get('colore_verde_chiaro') : defaultColors.get('green');
		}
		else if(value >= 80 && value <= 100) {
			return chartColors.containsKey('colore_verde_scuro') ? chartColors.get('colore_verde_scuro') : defaultColors.get('darkGreen');
		}
		else {
			return defaultColors.get('grey');
		}
	}

	public static String autoBreakText(String text) {
		String label = '';
		List<String> pieces = text.split(' ');
		String partial = '';
		for(String piece : pieces) {
			partial += String.isEmpty(partial) ? ' ' : '';
			if((partial.length()+piece.length()) > 16) {
				label += '$partial\n';
				partial = piece;
			}
			else {
				partial += '$piece';
			}
		}
		label += partial;
		return label;
	}

	// Traspone un valore in una scala da 1 a 100
	private static Double transpose(Double value) {

		Double result = 0;

		if(value != null && value > 0) {

			result = (100 / (5 - 1)) * value - (100 / (5 - 1));

			if(result <= 0) {

				result = 5;

			}

		}

		return result;
	}

	// Traspone un valore in una scala da 1 a 100
	private static Double transposeWithZero(Double value) {

		Double result = 0;

		if(value != null && value > 0) {

			result = (100 / (5 - 1)) * value - (100 / (5 - 1));

		}

		return result;
	}
}