@RestResource(urlMapping = 
'/manager_dashboard/*')
global class ManagerDashboardResource {
	@HttpGet
	global static void doGet() {

		CustomAuthentication ca = new CustomAuthentication(RestContext.request, RestContext.response);

		if(!ca.authenticate()) {

			ca.getResponse().send();

			return;

		}

		CustomResponse res = new CustomResponse(RestContext.response);

		Utente__c u = ca.getUser();
		Id userId = u.Utente_Master__c != null ? u.Utente_Master__c : u.Id;
		List<String> userPermissions = u.Azienda_Permessi_Visualizzazione__c != null ? u.Azienda_Permessi_Visualizzazione__c.split(';') : new List<String>();

		String brandId = RestContext.request.params.get('brandId');
		String zonesIds = RestContext.request.params.get('zonesIds');
		String rawRange = RestContext.request.params.get('range');

		/*Gruppo__c g = [SELECT Id, Gruppo_Master__c FROM Gruppo__c WHERE Id = :brandId LIMIT 1];

		 if(g.Gruppo_Master__c != null){
		 brandId = g.Gruppo_Master__c;
		 }*/

		List<Object> charts = new List<Object>();
		List<Gruppo__c> childGroups = UserResource.getUserGroupChildren(u.Id);
		System.debug('chidGroups: '+childGroups);
		childGroups = UserResource.filterGroupsByBrandId(childGroups, brandId);
		System.debug('chidGroups: '+childGroups);
		List<String> range;

		Gruppo__c brand = getBrandById(brandId);
		System.debug('chidGroups: '+childGroups);

		if(String.isNotBlank(zonesIds)) {

			childGroups = UserResource.getGroupsByIds(zonesIds.split(','));

		}
		System.debug('chidGroups: '+childGroups);

		if(String.isNotBlank(rawRange)) {

			range = rawRange.split(',');

		}

		BubbleChartData dealerMap = getDealerMap(brand, childGroups, userPermissions, ca.getAppId(), range);

		if(dealerMap != null && dealerMap.bubbleChartDots.size() > 0) {

			charts.add(dealerMap);

		}

		String barChartInfo = 'I set di quesiti che compongono gli indici sintetici della Dealer Map sono approfonditi nella <b>Business Dashboard</b> e <b>Motivation Dashboard</b>.<br/><br/>';
		barChartInfo += 'Nel grafico si riporta, per ciascuna tematica, la <b>media delle risposte dei Concessionari</b> appartenenti all\'area di competenza del Manager, confrontando i <b>risultati più recenti</b> rispetto a quelli del <b>periodo precedente</b> (secondo la frequenza di rilevazione del quesito).<br/><br/>';
		barChartInfo += 'É inoltre specificato se la domanda è in corso rilevazione, il cui risultato parziale comparirà al raggiungimento di un campione minimo di rappresentatività.<br/><br/>';
		barChartInfo += 'Cliccando su <b>ciascuna barra nel grafico</b> è possibile visualizzare la domanda estesa, il periodo puntuale di rilevazione e il campione di rispondenti.';

		List<String> chartsGroups = new List<String>{'Business Dashboard', 'Motivation Dashboard'};
		List<Object> businessAndMotivationDashboard = ManagerInsightResource.getInsight(brand, childGroups, 'Business & Motivation Dashboard', chartsGroups, userPermissions, barChartInfo);

		if(businessAndMotivationDashboard != null && businessAndMotivationDashboard.size() > 0) {

			charts.addAll(businessAndMotivationDashboard);

		}

		CustomTimeSeriesChart trend = getTrend(brand, childGroups, userPermissions, ca.getAppId(), range);

		if(trend != null && trend.series.size() > 0) {

			charts.add(trend);

		}

		res.setStatusCode(200);
		res.setBody(charts);

		res.send();
	}

	public static CustomTimeSeriesChart getTrend(Gruppo__c brand, List<Gruppo__c> childGroups, List<String> userPermissions, Id appId, List<String> range) {

		CustomTimeSeriesChart chart = new CustomTimeSeriesChart('Business & Motivation Trend', null, brand.Name, brand.Id, brand.Colore__c, 'xLabel', 'yLabel', null, null);

		chart.info = 'Il grafico di Trend mostra l\'evoluzione degli indici aggregati di Motivation (del Dealer) e di Business (con la Casa).<br/><br/>Le variabili che compongono tali indicatori sono visualizzabili nella sezione Business & Motivation Dashboard.';

		Set<Id> childGroupsIds = new Set<Id>();

		for(Gruppo__c cg : childGroups) {
			childGroupsIds.add(cg.Id);
		}

		Boolean newQuestions = QuestionResource.thereAreNewQuestions(childGroupsIds, 'Dealer Map');

		List<Raggruppamento__c> groupings = getDealerMapGroupingsByBrandIdAndUserPermissions(brand, userPermissions);
		List<Utente_Gruppo__c> usersGroups = getDealerGroupsToConsiderByBrandAndIds(brand, childGroupsIds);

		Set<Id> usersToAnalyze = new Set<Id>();

		for(Utente_Gruppo__c ug : usersGroups) {

			usersToAnalyze.add(ug.Utente__c);

		}
		//List<Domanda_questionario__c> questions = questionsByGroupings(groupings, range);

		List<QCustomPeriod> periods = new List<QCustomPeriod>();

		QCustomPeriod startPeriod = new QCustomPeriod(newQuestions, null);

		// Aggiunta per gestione del range.
		if(range != null && range.size() == 2) {

			Integer rangeEnd = Integer.valueOf(range[1]);

			if(rangeEnd > 0) {

				startPeriod = new QCustomPeriod(false, 1);

				for(Integer i = 0; i < rangeEnd * 2; i++) {

					startPeriod = startPeriod.getPrevious(1);

				}

			}

		}
		// Fine aggiunta per gestione del range.

		periods.add(startPeriod);

		Integer numberOfPeriods = 3;

		//Integer numberOfPeriods = range != null && range.size() > 0 ? range.size() : 3;

		if(range != null && range.size() == 2) {

			numberOfPeriods = ((Integer.valueOf(range[0])-Integer.valueOf(range[1]))+1) * 2;

			numberOfPeriods -= 1;

		}

		for(Integer i = 1; i < numberOfPeriods; i++) {

			periods.add(periods.get(i - 1).getPrevious(null));

		}

		System.debug(periods);

		List<Risposta_questionario__c> answers = getAnswersByGroupings(groupings, periods[periods.size()-1].startDateTime, periods[0].endDateTime);

		DateTime fromDateTime = periods[periods.size()-1].startDateTime;
		DateTime toDateTime = periods[0].endDateTime;

		String fromDateTimeFormatted = RCCUtils.dateFormat(fromDateTime.date());
		String toDateTimeFormatted = RCCUtils.dateFormat(toDateTime.date());

		chart.subTitle = '<div><strong>Evoluzione</strong> Dealer <strong>Motivation</strong> e <strong>Business</strong> con la Casa<br/>Media dei Dealer appartenenti all\'area di competenza del Manager vs media Italia<br/>(dal '+fromDateTimeFormatted+' al '+toDateTimeFormatted+')</div>';

		CustomTimeSeriesChartSerie zoneMotivationSerie = new CustomTimeSeriesChartSerie('zoneMotivationSerie', brand.Colore__c, null);
		zoneMotivationSerie.info = 'Motivation (media Dealer area competenza Manager selezionati nel filtro)';
		CustomTimeSeriesChartSerie zoneBussinessSerie = new CustomTimeSeriesChartSerie('zoneBussinessSerie', '#AAAAAA', null);
		zoneBussinessSerie.info = 'Business (media Dealer area competenza Manager selezionati nel filtro)';

		CustomTimeSeriesChartSerie totalMotivationSerie = new CustomTimeSeriesChartSerie('totalMotivationSerie', brand.Colore__c, new List<Integer>{8, 4});
		totalMotivationSerie.info = 'Motivation (media Dealer Italia)';
		CustomTimeSeriesChartSerie totalBussinessSerie = new CustomTimeSeriesChartSerie('totalBussinessSerie', '#AAAAAA', new List<Integer>{8, 4});
		totalBussinessSerie.info = 'Business (media Dealer Italia)';

		List<List<Decimal>> zoneMotivationValuesByPeriod = new List<List<Decimal>>();
		List<List<Decimal>> zoneBussinessValuesByPeriod = new List<List<Decimal>>();
		List<List<Decimal>> totalMotivationValuesByPeriod = new List<List<Decimal>>();
		List<List<Decimal>> totalBussinessValuesByPeriod = new List<List<Decimal>>();

		for(QCustomPeriod p : periods) {

			List<Decimal> zoneMotivationValues = new List<Decimal>();
			List<Decimal> zoneBussinessValues = new List<Decimal>();
			List<Decimal> totalMotivationValues = new List<Decimal>();
			List<Decimal> totalBussinessValues = new List<Decimal>();

			for(Risposta_questionario__c a : answers) {

				if(a.Data_Ora_Risposta__c >= p.startDateTime && a.Data_Ora_Risposta__c <= p.endDateTime) {

					if(a.Domanda_questionario__r.Raggruppamento__r.Genitore__r.Etichetta_Ridotta_EN__c == 'Motivation') {

						if(usersToAnalyze.contains(a.Utente__c)) {

							zoneMotivationValues.add(a.Valore_Numerico__c);

						}

						totalMotivationValues.add(a.Valore_Numerico__c);

					}
					else if(a.Domanda_questionario__r.Raggruppamento__r.Genitore__r.Etichetta_Ridotta_EN__c == 'Business') {

						if(usersToAnalyze.contains(a.Utente__c)) {

							zoneBussinessValues.add(a.Valore_Numerico__c);

						}

						totalBussinessValues.add(a.Valore_Numerico__c);

					}

				}

			}

			zoneMotivationValuesByPeriod.add(zoneMotivationValues);
			zoneBussinessValuesByPeriod.add(zoneBussinessValues);
			totalMotivationValuesByPeriod.add(totalMotivationValues);
			totalBussinessValuesByPeriod.add(totalBussinessValues);

		}

		for(Integer i = 0; i < periods.size(); i++) {

			QCustomPeriod p = periods[i];

			Long startTime = p.endDateTime.getTime();

			if(zoneMotivationValuesByPeriod[i].size() > 0) {

				zoneMotivationSerie.values.add(new CustomTimeSeriesChartSerieValue(startTime, calculateAvgFromList(zoneMotivationValuesByPeriod[i])));

			}
			else {

				zoneMotivationSerie.values.add(new CustomTimeSeriesChartSerieValue(startTime, null));

			}

			if(zoneBussinessValuesByPeriod[i].size() > 0) {

				zoneBussinessSerie.values.add(new CustomTimeSeriesChartSerieValue(startTime, calculateAvgFromList(zoneBussinessValuesByPeriod[i])));

			}
			else {

				zoneBussinessSerie.values.add(new CustomTimeSeriesChartSerieValue(startTime, null));

			}

			if(totalMotivationValuesByPeriod[i].size() > 0) {

				totalMotivationSerie.values.add(new CustomTimeSeriesChartSerieValue(startTime, calculateAvgFromList(totalMotivationValuesByPeriod[i])));

			}
			else {

				totalMotivationSerie.values.add(new CustomTimeSeriesChartSerieValue(startTime, null));

			}

			if(totalBussinessValuesByPeriod[i].size() > 0) {

				totalBussinessSerie.values.add(new CustomTimeSeriesChartSerieValue(startTime, calculateAvgFromList(totalBussinessValuesByPeriod[i])));

			}
			else {

				totalBussinessSerie.values.add(new CustomTimeSeriesChartSerieValue(startTime, null));

			}

		}

		chart.series.add(zoneMotivationSerie);
		chart.series.add(zoneBussinessSerie);
		chart.series.add(totalMotivationSerie);
		chart.series.add(totalBussinessSerie);

		return chart;
	}

	private static Double calculateAvgFromList(List<Decimal> numberList) {

		Decimal avg = 0;

		for(Decimal num : numberList) {

			avg += num;

		}

		return transpose(Double.valueOf(avg / numberList.size()));
	}

	private static Map<String, String> getColorsByAppId(Id appId) {

		Map<String, String> chartColors = new Map<String, String>();

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
		                                                 WHERE App__c = :appId AND Sezione__c = :'Grafici'];

		for(Configurazione_App__c c : appConfigurations) {

			chartColors.put(c.Chiave__c, c.Campo_Testuale__c);

		}

		return chartColors;
	}

	public static BubbleChartData getDealerMap(Gruppo__c brand, List<Gruppo__c> childGroups, List<String> userPermissions, Id appId, List<String> range) {

		String chartTitle = 'Dealer Map';

		Set<Id> childGroupsIds = new Set<Id>();

		for(Gruppo__c cg : childGroups) {
			childGroupsIds.add(cg.Id);
		}

		Map<String, String> chartColors = getColorsByAppId(appId);

		List<Raggruppamento__c> groupings = getDealerMapGroupingsByBrandIdAndUserPermissions(brand, userPermissions);

		List<String> labels = new List<String>();

		for(Raggruppamento__c r : groupings) {
			if(r.Genitore__r.Etichetta_Ridotta_EN__c != null && !labels.contains(r.Genitore__r.Etichetta_Ridotta_EN__c)) {
				labels.add(r.Genitore__r.Etichetta_Ridotta_EN__c);
			}
		}

		if(labels.size() != 2) {
			return null;
		}

		BubbleChartLabelsData chartLabels = new BubbleChartLabelsData(labels[0], labels[1]);

		List<Utente_Gruppo__c> usersGroups = getDealerGroupsToConsiderByBrandAndIds(brand, childGroupsIds);

		Set<Id> usersToAnalyze = new Set<Id>();

		for(Utente_Gruppo__c ug : usersGroups) {

			usersToAnalyze.add(ug.Utente__c);

		}

		Boolean newQuestions = QuestionResource.thereAreNewQuestions(childGroupsIds, 'Dealer Map');

		List<QCustomPeriod> periods = new List<QCustomPeriod>();
		List<Double> percents = new List<Double>();

		if(range != null && range.size() == 2) {

			Integer loops = ((Integer.valueOf(range[0])-Integer.valueOf(range[1]))+1) * 2;

			loops -= 1;

			for(Integer i = 0; i < loops; i++) {

				percents.add((((50.0 / loops) * (loops - i)) / 100.0)+0.1);

			}

		}
		else {

			percents.add(0.5);
			percents.add(0.3);
			percents.add(0.2);

		}

		QCustomPeriod startPeriod = new QCustomPeriod(newQuestions, percents[0]);

		// Aggiunta per gestione del range.
		if(range != null && range.size() == 2) {

			Integer rangeEnd = Integer.valueOf(range[1]);

			if(rangeEnd > 0) {

				startPeriod = new QCustomPeriod(false, percents[0]);

				for(Integer i = 0; i < (rangeEnd * 2)-1; i++) {

					startPeriod = startPeriod.getPrevious(1);

				}

			}

		}
		// Fine aggiunta per gestione del range.

		periods.add(startPeriod);

		for(Integer i = 1; i < percents.size(); i++) {

			periods.add(periods.get(i - 1).getPrevious(percents[i]));

		}

		System.debug(periods);

		List<Risposta_questionario__c> answers = getAnswersByUsersIdsAndGroupings(usersToAnalyze, groupings, periods[periods.size()-1].startDateTime, periods[0].endDateTime);

		List<Domanda_questionario__c> questions = questionsByGroupings(groupings, periods[periods.size()-1].startDateTime, periods[0].endDateTime);

		DateTime fromDateTime = periods[periods.size()-1].startDateTime;
		DateTime toDateTime = periods[0].endDateTime;

		String fromDateTimeFormatted = RCCUtils.dateFormat(fromDateTime.date());
		String toDateTimeFormatted = RCCUtils.dateFormat(toDateTime.date());
		String avgTo = toDateTime < System.today() ? toDateTimeFormatted : RCCUtils.dateFormat(System.today());

		String chartSubTitle = '<div><strong>Media Dealer</strong> rispondenti al '+avgTo+'<br/>(dal '+fromDateTimeFormatted+' al '+toDateTimeFormatted+')<br/>appartenenti all\'area di competenza del Manager</div>';

		BubbleChartData chart = new BubbleChartData(chartTitle, chartSubtitle, brand.Name, chartLabels);

		chart.brandId = brand.Id;
		chart.color = brand.Colore__c;

		//chart.post = 'Legenda:<br/>Trend Dealer rispetto al <data precedente> (precedente mese e mezzo considerato): negativo, stabile, positivo';

		chart.info = 'La <strong>Dealer Map</strong> monitora lo status dei Concessionari del Marchio secondo le risposte raccolte nell\'ultimo mese e mezzo.<br/><br/>';
		chart.info += 'Si compone degli indici sintetici di "<strong>Dealer Motivation</strong>" e "<strong>Business con la Casa</strong>" calcolati sul set di quesiti sotto riportati in Dashboard.<br/><br/>';
		chart.info += 'Ciascun Dealer rispondente, appartenente all\'area di competenza del Manager, è identificato da un punto nel grafico. A seconda del quadrante in cui si posiziona il Concessionario rispetto alla media del gruppo, compare nella <strong>Dealer List</strong> con un color coding da rosso a verde. Nella Dealer List sono elencati tutti i Concessionari appartenenti all\'area di competenza del Manager.';

		List<Dealer> dealers = new List<Dealer>();

		Set<Id> usersWithAnswers = new Set<Id>();

		//Set<Id> indexes = new Set<Id>();

		DateTime firstPeriodAnswerDateTime = null;

		System.debug(answers.size());

		for(Risposta_questionario__c a : answers) {

			if(firstPeriodAnswerDateTime == null || firstPeriodAnswerDateTime > a.Data_Ora_Risposta__c) {

				firstPeriodAnswerDateTime = a.Data_Ora_Risposta__c;

			}

			usersWithAnswers.add(a.Utente__c);

			// Creo il dealer solo se devo considerarlo nell'analisi
			if(!a.Utente__r.Non_Considerare_Analisi__c) {

				Dealer fd;

				// Cerco il dealer
				for(Dealer d : dealers) {

					if(a.Utente__c == d.id) {

						fd = d;

					}

				}

				// Se non trovo il dealer lo creo, con ragione sociale e Zona
				if(fd == null) {

					String groupName = '';

					for(Utente_Gruppo__c ug : usersGroups) {

						if(ug.Utente__c == a.Utente__c) {
							groupName = ug.Nome_Gruppo__c;
						}

					}

					fd = new Dealer(a.Utente__c, a.Utente__r.Ragione_Sociale__c, groupName, periods, questions, groupings);

					Map<String, Object> extras = new Map<String, Object>();

					extras.put('firstName', a.Utente__r.Nome__c);
					extras.put('lastName', a.Utente__r.Cognome__c);
					extras.put('companyName', a.Utente__r.Ragione_Sociale__c);
					extras.put('zipCode', a.Utente__r.Cap__c);
					extras.put('city', a.Utente__r.Citta__c);
					extras.put('seniority', a.Utente__r.CL_Anzianita__c);
					extras.put('revenue', a.Utente__r.CL_Fatturato__c);
					extras.put('sales', a.Utente__r.CL_Vendite__c);
					extras.put('manufacturerCode', a.Utente__r.COD_CASA__c);
					extras.put('email', a.Utente__r.Email__c);
					extras.put('legalOfficeAddress', a.Utente__r.Indirizzo_Sede_Legale__c);
					extras.put('commercialName', a.Utente__r.Nome_Commerciale__c);
					extras.put('province', a.Utente__r.Provincia__c);
					extras.put('region', a.Utente__r.Regione__c);

					fd.extras = extras;

					dealers.add(fd);

				}

				fd.addAnswer(new Answer(a.id, a.Domanda_questionario__c, a.Domanda_questionario__r.Raggruppamento__c, a.Domanda_questionario__r.Raggruppamento__r.Genitore__c, a.Domanda_questionario__r.Raggruppamento__r.Genitore__r.Priorita_Visualizzazione__c, (Double)a.Valore_Numerico__c, a.Domanda_questionario__r.Data_Ora_Inizio_Analisi__c, a.Domanda_questionario__r.Data_Ora_Fine_Analisi__c, (Double)a.Domanda_questionario__r.Raggruppamento__r.Peso_Genitore__c));

				//indexes.add(a.Domanda_questionario__r.Raggruppamento__r.Genitore__c);

			}

		}

		//System.debug(indexes);

		usersToAnalyze.removeAll(usersWithAnswers);

		List<Utente__c> usersWithoutAnswers = getUsersByIds(usersToAnalyze);

		for(Utente__c u : usersWithoutAnswers) {
			String groupName = '';

			for(Utente_Gruppo__c ug : usersGroups) {

				if(ug.Utente__c == u.Id) {
					groupName = ug.Nome_Gruppo__c;
				}

			}

			Dealer fd = new Dealer(u.Id, u.Ragione_Sociale__c, groupName, periods, questions, groupings);

			dealers.add(fd);
		}

		Long firstPeriodAnswerTimestamp = firstPeriodAnswerDateTime != null ? firstPeriodAnswerDateTime.getTime() : null;

		chart.extras = new Map<String, Object>{'firstPeriodAnswerDateTime' => firstPeriodAnswerTimestamp};

		for(Dealer d : dealers) {

			List<Double> values = d.getValues();
			//System.debug('Dealer: ' + d.Id + ' status: ' + d.getGrowingStatus());

			String color = chartColors.get('colore_giallo');
			Integer size = 1;
			Decimal status = d.getGrowingStatus();

			if(status < 0) {

				color = chartColors.get('colore_rosso');

			}
			else if(status > 0) {

				color = chartColors.get('colore_verde_scuro');

			}

			//System.debug(color);

			if(values.size() == 2) {

				BubbleChartDotData dot = new BubbleChartDotData(values[0], values[1], size, color);
				dot.label = d.companyName;
				dot.extra = d.groupName;
				dot.extras = d.extras;
				chart.addDot(dot);

			}
			else {

				BubbleChartDotData dot = new BubbleChartDotData(null, null, null, null);
				dot.label = d.companyName;
				dot.extra = d.groupName;
				dot.extras = d.extras;
				chart.addDot(dot);

			}

		}

		return chart;
	}

	private static Gruppo__c getBrandById(Id brandId) {

		return [SELECT Id, 
		               Genitore__c, 
		               Name, 
		               Tipologia__c, 
		               Sigla__c, 
		               Ordine__c, 
		               Url_Logo__c, 
		               Colore__c, 
		               Gruppo_Master__c, 
		               Gruppo_Master__r.Genitore__c, 
		               Campione_Minimo_Percentuale__c
		        FROM Gruppo__c
		        WHERE Id = :brandId
		        LIMIT 1];
	}

	private static List<Raggruppamento__c> getDealerMapGroupingsByBrandIdAndUserPermissions(Gruppo__c brand, List<String> userPermissions) {

		return [SELECT Id, 
		               Name, 
		               Genitore__r.Etichetta_IT__c, 
		               Genitore__r.Etichetta_EN__c, 
		               Gruppo__r.Name, 
		               Genitore__c, 
		               Gruppo__r.Colore__c, 
		               Genitore__r.Etichetta_Ridotta_IT__c, 
		               Genitore__r.Etichetta_Ridotta_EN__c, 
		               Genitore__r.Priorita_Visualizzazione__c, 
		               Peso_Genitore__c
		        FROM Raggruppamento__c
		        WHERE (Gruppo__c = :brand.Id OR Gruppo__c = :brand.Gruppo_Master__c) AND Genitore__r.Visualizzabile_Da_Manager_In__c = :'Dealer Map' AND Azienda_Permessi_Visualizzazione__c IN :userPermissions
		        ORDER BY Gruppo__r.Name];
	}

	private static List<Utente_Gruppo__c> getDealerGroupsToConsiderByBrandAndIds(Gruppo__c brand, Set<Id> groupsIds) {

		return [SELECT Id, 
		               Utente__c, 
		               Gruppo__c, 
		               Nome_Gruppo__c, 
		               Sigla_Gruppo__c, 
		               Name
		        FROM Utente_Gruppo__c
		        WHERE (Gruppo__r.Genitore__r.Genitore__c = :brand.Id OR Gruppo__r.Genitore__r.Genitore__c = :brand.Gruppo_Master__c) AND Utente__r.Non_Considerare_Analisi__c = false AND Utente__r.Tipologia__c = 'Dealer' AND Gruppo__c IN :groupsIds];
	}

	private static List<Risposta_questionario__c> getAnswersByUsersIdsAndGroupings(Set<Id> usersIds, List<Raggruppamento__c> groupings, DateTime fromDateTime, DateTime toDateTime) {

		/*DateTime currentDate = System.now();
		 DateTime rangeStart = currentDate.addMonths(-4);
		 DateTime rangeEnd = currentDate.addMonths(1);

		 if(range != null && range.size() == 2){

		 rangeStart = rangeStart.addMonths(-Integer.valueOf(range[0]));
		 rangeEnd = rangeEnd.addMonths(-Integer.valueOf(range[1]));

		 }*/

		DateTime rangeStart = fromDateTime;
		DateTime rangeEnd = toDateTime;

		return [SELECT Name, 
		               Utente__c, 
		               Valore_Numerico__c, 
		               Valore_Testuale__c, 
		               Valore_Testuale_Lungo__c, 
		               Domanda_questionario__r.Raggruppamento__c, 
		               Domanda_questionario__r.Raggruppamento__r.Genitore__c, 
		               Domanda_questionario__r.Raggruppamento__r.Gruppo__r.Name, 
		               Domanda_questionario__r.Raggruppamento__r.Peso_Genitore__c, 
		               Domanda_questionario__r.Data_Ora_Inizio__c, 
		               Domanda_questionario__r.Raggruppamento__r.Genitore__r.Priorita_Visualizzazione__c, 
		               Valore_Numerico_Per_Peso_Raggruppamento__c, 
		               Domanda_questionario__r.Data_Ora_Fine__c, 
		               Utente__r.Non_Considerare_Analisi__c, 
		               Domanda_questionario__r.Data_Ora_Inizio_Analisi__c, 
		               Domanda_questionario__r.Data_Ora_Fine_Analisi__c, 
		               Data_Ora_Risposta__c, 
		               Utente__r.Ragione_Sociale__c, 
		               Utente__r.Cap__c, 
		               Utente__r.Citta__c, 
		               Utente__r.CL_Anzianita__c, 
		               Utente__r.CL_Fatturato__c, 
		               Utente__r.CL_Vendite__c, 
		               Utente__r.COD_CASA__c, 
		               Utente__r.Email__c, 
		               Utente__r.Indirizzo_Sede_Legale__c, 
		               Utente__r.Nome_Commerciale__c, 
		               Utente__r.PIVA__c, 
		               Utente__r.Provincia__c, 
		               Utente__r.Regione__c, 
		               Utente__r.Nome__c, 
		               Utente__r.Cognome__c, 
		               Domanda_questionario__r.Raggruppamento__r.Genitore__r.Etichetta_Ridotta_EN__c
		        FROM Risposta_questionario__c
		        WHERE Domanda_questionario__r.Raggruppamento__c IN :groupings AND Utente__c IN :usersIds AND Utente__r.Non_Considerare_Analisi__c = false AND (Risposta_questionario__c.Valore_Numerico__c != null OR Risposta_questionario__c.Valore_Testuale__c != null) AND Domanda_questionario__r.Data_Ora_Inizio_Analisi__c >= :rangeStart AND Domanda_questionario__r.Data_Ora_Inizio_Analisi__c <= :rangeEnd
		        ORDER BY Domanda_questionario__r.Raggruppamento__r.Gruppo__r.Name DESC, Domanda_questionario__r.Raggruppamento__r.Genitore__r.Etichetta_IT__c ASC, Utente__c ASC, Domanda_questionario__r.Raggruppamento__c ASC];
		/* Backup per test
		 ORDER BY Domanda_questionario__r.Raggruppamento__r.Gruppo__r.Name ASC, Utente__c ASC, Domanda_questionario__r.Raggruppamento__c ASC]
		 */
	}

	private static List<Risposta_questionario__c> getAnswersByGroupings(List<Raggruppamento__c> groupings, DateTime fromDateTime, DateTime toDateTime) {

		//DateTime currentDate = System.now();
		DateTime rangeStart = fromDateTime;
		DateTime rangeEnd = toDateTime;

		return [SELECT Name, 
		               Utente__c, 
		               Valore_Numerico__c, 
		               Valore_Testuale__c, 
		               Valore_Testuale_Lungo__c, 
		               Domanda_questionario__r.Raggruppamento__c, 
		               Domanda_questionario__r.Raggruppamento__r.Genitore__c, 
		               Domanda_questionario__r.Raggruppamento__r.Gruppo__r.Name, 
		               Domanda_questionario__r.Raggruppamento__r.Peso_Genitore__c, 
		               Domanda_questionario__r.Data_Ora_Inizio__c, 
		               Domanda_questionario__r.Raggruppamento__r.Genitore__r.Priorita_Visualizzazione__c, 
		               Valore_Numerico_Per_Peso_Raggruppamento__c, 
		               Domanda_questionario__r.Data_Ora_Fine__c, 
		               Utente__r.Non_Considerare_Analisi__c, 
		               Domanda_questionario__r.Data_Ora_Inizio_Analisi__c, 
		               Domanda_questionario__r.Data_Ora_Fine_Analisi__c, 
		               Data_Ora_Risposta__c, 
		               Utente__r.Ragione_Sociale__c, 
		               Utente__r.Cap__c, 
		               Utente__r.Citta__c, 
		               Utente__r.CL_Anzianita__c, 
		               Utente__r.CL_Fatturato__c, 
		               Utente__r.CL_Vendite__c, 
		               Utente__r.COD_CASA__c, 
		               Utente__r.Email__c, 
		               Utente__r.Indirizzo_Sede_Legale__c, 
		               Utente__r.Nome_Commerciale__c, 
		               Utente__r.PIVA__c, 
		               Utente__r.Provincia__c, 
		               Utente__r.Regione__c, 
		               Utente__r.Nome__c, 
		               Utente__r.Cognome__c, 
		               Domanda_questionario__r.Raggruppamento__r.Genitore__r.Etichetta_Ridotta_EN__c
		        FROM Risposta_questionario__c
		        WHERE Domanda_questionario__r.Raggruppamento__c IN :groupings AND Utente__r.Non_Considerare_Analisi__c = false AND (Risposta_questionario__c.Valore_Numerico__c != null OR Risposta_questionario__c.Valore_Testuale__c != null) AND Domanda_questionario__r.Data_Ora_Inizio_Analisi__c >= :rangeStart AND Domanda_questionario__r.Data_Ora_Inizio_Analisi__c <= :rangeEnd
		        ORDER BY Domanda_questionario__r.Raggruppamento__r.Gruppo__r.Name DESC, Domanda_questionario__r.Raggruppamento__r.Genitore__r.Etichetta_IT__c ASC, Utente__c ASC, Domanda_questionario__r.Raggruppamento__c ASC];
		/* Backup per test
		 ORDER BY Domanda_questionario__r.Raggruppamento__r.Gruppo__r.Name ASC, Utente__c ASC, Domanda_questionario__r.Raggruppamento__c ASC
		 */
	}

	private static List<Domanda_questionario__c> questionsByGroupings(List<Raggruppamento__c> groupings, DateTime fromDateTime, DateTime toDateTime) {

		/*DateTime currentDate = System.now();
		 DateTime rangeStart = currentDate.addMonths(-4);
		 DateTime rangeEnd = currentDate.addMonths(1);

		 if(range != null && range.size() == 2){

		 rangeStart = rangeStart.addMonths(-Integer.valueOf(range[0]));
		 rangeEnd = rangeEnd.addMonths(-Integer.valueOf(range[1]));

		 }*/

		DateTime rangeStart = fromDateTime;
		DateTime rangeEnd = toDateTime;

		return [SELECT Id, 
		               Raggruppamento__c, 
		               Raggruppamento__r.Genitore__c, 
		               Data_Ora_Inizio_Analisi__c, 
		               Data_Ora_Fine_Analisi__c
		        FROM Domanda_questionario__c
		        WHERE Raggruppamento__c IN :groupings AND Data_Ora_Inizio_Analisi__c >= :rangeStart AND Data_Ora_Inizio_Analisi__c <= :rangeEnd];
	}

	private static List<Utente__c> getUsersByIds(Set<Id> usersIds) {

		return [SELECT Id, 
		               Ragione_Sociale__c
		        FROM Utente__c
		        WHERE Id IN :usersIds AND Non_Considerare_Analisi__c = :false];
	}

	class Answer {
		public String id;

		public String questionId;

		public String groupingId;

		public String indexId;

		public Decimal indexOrder;

		public Double numericValue;

		public DateTime startDateTime;

		public DateTime endDateTime;

		public Double weight;

		public Answer(String id, String questionId, String groupingId, String indexId, Decimal indexOrder, Double numericValue, DateTime startDateTime, DateTime endDateTime, Double weight) {
			this.id = id;
			this.questionId = questionId;
			this.groupingId = groupingId;
			this.indexId = indexId;
			this.indexOrder = indexOrder;
			this.numericValue = numericValue;
			this.startDateTime = startDateTime;
			this.endDateTime = endDateTime;
			this.weight = weight > 0 ? weight : 1;
		}
	}

	class Dealer {
		public String id;

		public String companyName;

		public String groupName;

		public List<Answer> answers = new List<Answer>();

		public List<Double> values = new List<Double>();

		public List<QCustomPeriod> periods;

		public List<Domanda_questionario__c> questions;

		public List<List<Answer>> answersByPeriod;

		public List<Set<Id>> answersIdsByPeriod;

		public List<List<Domanda_questionario__c>> questionsByPeriod;

		public List<Set<Id>> questionsIdsByPeriod;

		public List<Raggruppamento__c> indexes;

		public Map<String, Object> extras;

		public Dealer(String id, String companyName, String groupName, List<QCustomPeriod> periods, List<Domanda_questionario__c> questions, List<Raggruppamento__c> indexes) {
			this.id = id;
			this.companyName = companyName;
			this.groupName = groupName;
			this.periods = periods;
			this.questions = questions;
			this.answersByPeriod = new List<List<Answer>>();
			this.answersIdsByPeriod = new List<Set<Id>>();
			this.questionsByPeriod = new List<List<Domanda_questionario__c>>();
			this.questionsIdsByPeriod = new List<Set<Id>>();
			this.indexes = indexes;

			for(Integer i = 0; i < this.periods.size(); i++) {

				this.answersByPeriod.add(new List<Answer>());
				this.answersIdsByPeriod.add(new Set<Id>());

				this.questionsByPeriod.add(new List<Domanda_questionario__c>());
				this.questionsIdsByPeriod.add(new Set<Id>());

				QCustomPeriod p = this.periods[i];

				for(Domanda_questionario__c q : this.questions) {

					Datetime t = q.Data_Ora_Inizio_Analisi__c;

					if(!((q.Data_Ora_Inizio_Analisi__c < p.startDateTime && q.Data_Ora_Fine_Analisi__c < p.startDateTime) || (q.Data_Ora_Inizio_Analisi__c > p.endDateTime && q.Data_Ora_Fine_Analisi__c > p.endDateTime))) {

						this.questionsByPeriod[i].add(q);
						this.questionsIdsByPeriod[i].add(q.Id);

					}

				}

			}
		}

		public void addAnswer(Answer a) {

			for(Integer i = 0; i < this.periods.size(); i++) {

				if(this.questionsIdsByPeriod[i].contains(a.questionId)) {

					this.answersByPeriod[i].add(a);
					this.answersIdsByPeriod[i].add(a.Id);

				}

			}
		}

		public List<Double> getValues() {

			List<Double> values = new List<Double>();
			Map<String, List<Double>> valuesMap = new Map<String, List<Double>>();
			Map<String, Double> weightSum = new Map<String, Double>();
			List<Answer> totalAnswers = new List<Answer>();

			for(Integer i = 0; i < this.periods.size(); i++) {

				QCustomPeriod p = this.periods[i];

				for(Answer a : this.answersByPeriod[i]) {

					System.debug(a);

					if(!valuesMap.containsKey(a.indexId)) {

						valuesMap.put(a.indexId, new List<Double>());

					}

					if(!weightSum.containsKey(a.indexId)) {

						weightSum.put(a.indexId, 0);

					}

					valuesMap.get(a.indexId).add(a.numericValue * a.weight * p.weight);

					weightSum.put(a.indexId, weightSum.get(a.indexId)+a.weight * p.weight);

				}

			}

			//System.debug(valuesMap);

			for(String k : valuesMap.keySet()) {

				if(weightSum.get(k) > 0) {

					Double avg = calculateAverageFromList(valuesMap.get(k), weightSum.get(k));

					values.add(transposeWithZero(avg));

				}

			}

			return values;
		}

		public Map<String, List<Double>> getValuesMap() {

			Map<String, List<Double>> valuesMap = new Map<String, List<Double>>();

			for(Integer i = 0; i < this.periods.size(); i++) {

				for(Answer a : this.answersByPeriod[i]) {

					if(!valuesMap.containsKey(a.indexId)) {

						valuesMap.put(a.indexId, new List<Double>());

					}

					valuesMap.get(a.indexId).add(a.numericValue);

				}

			}

			return valuesMap;
		}

		public Decimal getGrowingStatus() {

			Map<String, List<Double>> valuesMap = getValuesMap();
			Decimal status = 0;

			Set<String> keys = valuesMap.keySet();

			for(String k : keys) {

				Decimal weight = 1;

				for(Raggruppamento__c index : this.indexes) {

					if(index.Genitore__c == k && index.Genitore__r.Priorita_Visualizzazione__c != null && index.Genitore__r.Priorita_Visualizzazione__c != 0) {

						weight = 1 / index.Genitore__r.Priorita_Visualizzazione__c;

					}

				}

				List<Double> values = valuesMap.get(k);

				if(values[0] < values[values.size()-1]) {

					status += 1 * weight;

				}
				else if(values[0] > values[values.size()-1]) {

					status -= 1 * weight;

				}

			}

			return status;
		}
	}

	private static Double calculateAverageFromList(List<Double> values, Double divider) {

		Double avg = 0;

		for(Double value : values) {
			avg += value;
		}

		return avg / (divider != null ? divider : values.size());
	}

	// Traspone un valore in una scala da 1 a 100
	public static Double transpose(Double value) {

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