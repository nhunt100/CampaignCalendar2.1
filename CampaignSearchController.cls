public with sharing class CampaignGanttController {
    
    // code for initiating all of the public variables 
    
    // the soql without the order and limit
    private String soql {get;set;}
    
    // the lists of possible filter values
    public List<SelectOption> camTypes {get;set;}
    public List<SelectOption> camSegments {get;set;}
    public List<SelectOption> camSources {get;set;}
    public List<SelectOption> camRegions {get;set;}
    public List<SelectOption> camCountries {get;set;}
    public List<SelectOption> camOwners {get;set;}
    public List<SelectOption> camClouds {get;set;}
    
    // the lists of selected values for each camapign filter
    public String[] typeValues {get;set;}
    public String[] segmentValues {get;set;}
    public String[] sourceValues {get;set;}
    public String[] regionValues {get;set;}
    public String[] countryValues {get;set;}
    public String[] ownerValues {get;set;}
    public String[] cloudValues {get;set;}
    
    
    public Boolean quantityAdded {get;set;}
    
    public String checkedFilters {get;set;}
    
    String dtFormat = 'd MMM yyyy'; 
    
    public list<calEvent> calendarEvents {get;set;}
    
    public String searchBox {get;set;}
    
    public Integer quarter {get;set;}
    
    public Integer year {get;set;}
    
    public Boolean quarterOrYear {get;set;}
    // true = annual, false = quartly
    
    
    // code for altering the views and the soql
    // the current sort direction. defaults to asc
    public String sortDir {
        get  { if (sortDir == null) {  sortDir = 'asc'; } return sortDir;  }
        set;
    }
    
    // the current field to sort by. defaults to start date
    public String sortField {
        get  { if (sortField == null) {sortField = 'StartDate'; } return sortField;  }
        set;
    }
    
    // format the soql for display on the visualforce page
    public String debugSoql {
        get { return soql + ' order by ' + sortField + ' ' + sortDir; }
        set;
    }
    
    // toggles the sorting of query from asc<-->desc
    public void toggleSort() {
        // simply toggle the direction
        sortDir = sortDir.equals('asc') ? 'desc' : 'asc';
        // run the query again
        eventLoad();
    }
    
    // constructor for CampaignGanttContoller 
    public CampaignGanttController() {
        quantityAdded = false;
        quarterOrYear = false;
        
        typeValues = new String[0];
        segmentValues = new String[0];
        sourceValues = new String[0];
        regionValues = new String[0];
        countryValues = new String[0];
        ownerValues = new String[0];
        cloudValues = new String[0];
        soql = 'select Id, Name, StartDate, EndDate, Region__c, Type,  Product__c, Country__c, Segment__c, Campaign_Source_Type__c, Owner.Name, Description, Status, Expected_Pipeline__c, Net_New_Pipeline__c, Net_New_ACV__c from campaign where IsActive = true AND StartDate != null AND EndDate != null ';
        checkedFilters = ' ';
        
        eventLoad(); 
        
        camTypes = buildFilterTotal('Type');
        camSegments = buildFilterTotal('Segment');
        camSources = buildFilterTotal('Source');
        camRegions = buildFilterTotal('Region');
        camCountries = buildFilterTotal('Country');
        camOwners = buildFilterTotal('Owner');
        camClouds = buildFilterTotal('Cloud');
        
        quantityAdded = true;
    }
    
    
    // the class that represents the events for the calendar and list
    public class calEvent {
        public String title {get;set;}
        public Boolean allDay {get;set;}
        public String startString {get;set;}
        public String endString {get;set;}
        public String url {get;set;}
        public String className {get;set;}
        
        public String descriptionCamp {get;set;}
        public String regionCamp {get;set;}
        public String segmentCamp {get;set;}
        public String typeCamp {get;set;}
        public String sourceCamp {get;set;}
        public String countryCamp {get;set;}
        public String ownerCamp {get;set;}
        public String cloudCamp {get;set;}
        public String statusCamp {get;set;}
        
        public Decimal expPipeCamp {get;set;}
        public Decimal newPipeCamp {get;set;}
        public Decimal newACVCamp {get;set;}
        
    }  
    
    // Methods for building the events for the calendar and list
    public void eventLoad() {
        calendarEvents = new list<calEvent>();
        for(Campaign campaigns : Database.query(soql + ' order by ' + sortField + ' ' + sortDir )){
            
            DateTime startDT = campaigns.StartDate;
            DateTime endDT = campaigns.EndDate;
            calEvent campEvent = new calEvent();
            
            campEvent.title = campaigns.Name;
            campEvent.allDay = true;
            campEvent.startString = startDT.format(dtFormat);
            campEvent.endString = endDT.format(dtFormat);
            campEvent.url = '/' + campaigns.Id;
            campEvent.className = eventClass(campaigns.Type);
            
            campEvent.descriptionCamp = campaigns.Description;
            campEvent.regionCamp = campaigns.Region__c;
            campEvent.segmentCamp = campaigns.Segment__c;
            campEvent.typeCamp = campaigns.Type;
            campEvent.sourceCamp = campaigns.Campaign_Source_Type__c;
            campEvent.countryCamp = campaigns.Country__c;
            campEvent.ownerCamp = campaigns.Owner.Name;
            campEvent.cloudCamp = campaigns.Product__c;
            campEvent.statusCamp = campaigns.Status;
            
            
            campEvent.expPipeCamp = campaigns.Expected_Pipeline__c;
            campEvent.newPipeCamp = campaigns.Net_New_Pipeline__c;
            campEvent.newACVCamp = campaigns.Net_New_ACV__c;
            
            calendarEvents.add(campEvent);
        }
    }
    
    // method that assignes an event with a specific class string for colouring on the calendar
    public String eventClass(String typeValue){
        String tempString = 'type-';
        typeValue = typeValue.toLowerCase();
        typeValue = typeValue.replace(' ', '_');
        tempString += typeValue;
        return tempString;
    }
    
    // methods for building the new query and searching it
    
    // method that build on the query based on the check boxes selected
    // uses either the IN or the INCLUDES operators based on the field type
    public void buildFilterQuery(String fieldName, String operator, String[] xValues, List<SelectOption> camX, Boolean isQuery){
        Boolean hasCondition = false;
        
        if(isQuery){
            soql += 'AND '; 
        }
        
        String tempQuery ='';
        if((!hasCondition)&&(!xValues.isEmpty())){
            hasCondition = true;
            String tempString = xValues[0];
            Integer tempInt = Integer.valueOf(tempString);
            String hold = camX[tempInt].getLabel();
            hold = removeQuantity(hold);
            tempQuery += fieldName+' '+operator+'(\'' + hold + '\'';
        }
        for(Integer x=1; x < xValues.size(); x++){
            String tempString = xValues[x];
            Integer tempInt = Integer.valueOf(tempString);
            String hold = camX[tempInt].getLabel();
            hold = removeQuantity(hold);
            tempQuery +=',\'' + hold +'\'';
        }
        if(hasCondition)
            tempQuery += ') ';
        if(isQuery){
            soql +=  tempQuery;  
        }else  checkedFilters += tempQuery;
        
    }
    
    // runs the search with parameters
    public PageReference runSearch() {
        soql = 'select Id, Name, StartDate, EndDate, Region__c, Type,  Product__c, Country__c, Segment__c, Campaign_Source_Type__c, Owner.Name, Description, Status, Expected_Pipeline__c, Net_New_Pipeline__c, Net_New_ACV__c from campaign where IsActive = true AND StartDate != null AND EndDate != null ';
        checkedFilters = ' ';
        
        if((quarter != 0) && (quarter != null) && (year != null)){
            String EOQ = endOfQuarterString(quarter, year);
            String SOQ = startOfQuarterString(quarter, year);
            soql += 'AND (StartDate <= '+EOQ+' AND EndDate >= '+SOQ+') ';
            checkedFilters += 'FY' + year + ' ';
            if(!quarterOrYear){
                checkedFilters += 'Q' + quarter + ' ';
            }
        }
        
        if(!String.isEmpty(searchBox)){
            checkedFilters += ' Searchbox (\'' +String.escapeSingleQuotes(searchBox)+ '\') ';
            soql += ' AND Name LIKE \''+String.escapeSingleQuotes(searchBox)+'%\' ';
        }
        
        if(!regionValues.isEmpty()){
            buildFilterQuery('Region', '', regionValues, camRegions, false); // dropdown IN
            buildFilterQuery('Region__c', 'IN', regionValues, camRegions, true); // dropdown IN 
        }
        if(!segmentValues.isEmpty()){
            buildFilterQuery('Segment', '', segmentValues, camSegments, false);
            buildFilterQuery('Segment__c', 'INCLUDES', segmentValues, camSegments, true);// multi INCLUDES
        }
        if(!typeValues.isEmpty()){
            buildFilterQuery('Type', '', typeValues, camTypes, false); // dropdown IN
            buildFilterQuery('Type', 'IN', typeValues, camTypes, true); // dropdown IN
        }
        if(!sourceValues.isEmpty()){
            buildFilterQuery('Campaign Source', '', sourceValues, camSources, false); // dropdown IN 
            buildFilterQuery('Campaign_Source_Type__c', 'IN', sourceValues, camSources, true); // dropdown IN 
        }
        if(!countryValues.isEmpty()){
            buildFilterQuery('Country', '', countryValues, camCountries, false); // text IN
            buildFilterQuery('Country__c', 'IN', countryValues, camCountries, true); // text IN
        }
        if(!ownerValues.isEmpty()){
            buildFilterQuery('Owner', '', ownerValues, camOwners, false); // automatic text IN
            buildFilterQuery('Owner.Name', 'IN', ownerValues, camOwners, true); // automatic text IN
        }
        if(!cloudValues.isEmpty()){
            if(cloudValues[0] != '0')
                cloudValues.add('0');
            buildFilterQuery('Cloud', '', cloudValues, camClouds, false); // multi INCLUDES
            buildFilterQuery('Product__c', 'INCLUDES', cloudValues, camClouds, true); // multi INCLUDES
        }
        // run the query again
        eventLoad();
        
        // rebuilds the queries
        camTypes = buildFilterTotal('Type');
        camSegments = buildFilterTotal('Segment');
        camSources = buildFilterTotal('Source');
        camRegions = buildFilterTotal('Region');
        camCountries = buildFilterTotal('Country');
        camOwners = buildFilterTotal('Owner');
        camClouds = buildFilterTotal('Cloud');
        return null;
    }
    
    
    // methods for builing the filters 
    // build all filter
    public List<SelectOption> buildFilterTotal(String fieldName){
        List<SelectOption> filtersValueAndQuantity = new List<SelectOption>();
        String[] filterValues = buildAllFilterValues(fieldName);
        
        String[] filtersNoDuplicates = new String[0];
        if(quantityAdded == false){
            filtersNoDuplicates = removeDuplicated(filterValues);
        } else {
            filtersNoDuplicates = addOldFilterValues(fieldName);
        }
        for(Integer x = 0; x < filtersNoDuplicates.size(); x++){
            filtersNoDuplicates[x] = buildFilterQuantity(filterValues, filtersNoDuplicates[x]);
        }
        filtersValueAndQuantity = buildSelectOptions(filtersNoDuplicates);
        return filtersValueAndQuantity;
    }
    
    public String[] addOldFilterValues(String fieldName){
        String[] listOldFilters = new String[0];
        if(fieldName == 'Region'){
            if(!camRegions.isEmpty()){
                for(Integer x = 0; x < camRegions.size(); x++){
                    listOldFilters.add(camRegions[x].getLabel());
                }
            }
        }else if(fieldName == 'Segment'){
            if(!camSegments.isEmpty()){
                for(Integer x = 0; x < camSegments.size(); x++){
                    listOldFilters.add(camSegments[x].getLabel());
                }
            }
        }else if(fieldName == 'Type'){
            for(Integer x = 0; x < camTypes.size(); x++){
                listOldFilters.add(camTypes[x].getLabel());
            }
        }else if(fieldName == 'Source'){
            for(Integer x = 0; x < camSources.size(); x++){
                listOldFilters.add(camSources[x].getLabel());
            }
        }else if(fieldName == 'Country'){
            for(Integer x = 0; x < camCountries.size(); x++){
                listOldFilters.add(camCountries[x].getLabel());
            }
        }else if(fieldName == 'Owner'){
            for(Integer x = 0; x < camOwners.size(); x++){
                listOldFilters.add(camOwners[x].getLabel());
            }
        }else if(fieldName == 'Cloud'){
            for(Integer x = 0; x < camClouds.size(); x++){
                listOldFilters.add(camClouds[x].getLabel());
            }
        }
        return listOldFilters;
    }
    
    // build long list of filters
    public String[] buildAllFilterValues(String fieldName){
        String[] listAllFilters = new String[0];
        
        if(fieldName == 'Region'){
            for(Integer x = 0; x < calendarEvents.size(); x++){
                if(!String.isBlank(calendarEvents[x].regionCamp)){
                    String[] temp = calendarEvents[x].regionCamp.split(';');
                    while(!temp.isEmpty()){
                        listAllFilters.add(temp[0]);
                        temp.remove(0);
                    }
                }
            }
        }else if(fieldName == 'Segment'){
            for(Integer x = 0; x < calendarEvents.size(); x++){
                if(!String.isBlank(calendarEvents[x].segmentCamp)){
                    String[] temp = calendarEvents[x].segmentCamp.split(';');
                    while(!temp.isEmpty()){
                        listAllFilters.add(temp[0]);
                        temp.remove(0);
                    }
                }
            }
        }else if(fieldName == 'Type'){
            for(Integer x = 0; x < calendarEvents.size(); x++){
                if(!String.isBlank(calendarEvents[x].typeCamp)){
                    String[] temp = calendarEvents[x].typeCamp.split(';');
                    while(!temp.isEmpty()){
                        listAllFilters.add(temp[0]);
                        temp.remove(0);
                    }                    
                }
            }
        }else if(fieldName == 'Source'){
            for(Integer x = 0; x < calendarEvents.size(); x++){
                if(!String.isBlank(calendarEvents[x].sourceCamp)){
                    listAllFilters.add(calendarEvents[x].sourceCamp);
                }
            }
        }else if(fieldName == 'Country'){
            for(Integer x = 0; x < calendarEvents.size(); x++){
                if(!String.isBlank(calendarEvents[x].countryCamp)){
                    listAllFilters.add(calendarEvents[x].countryCamp);
                }
            }
        }else if(fieldName == 'Owner'){
            for(Integer x = 0; x < calendarEvents.size(); x++){
                if(!String.isBlank(calendarEvents[x].ownerCamp)){
                    listAllFilters.add(calendarEvents[x].ownerCamp);
                }
            }
        }else if(fieldName == 'Cloud'){
            for(Integer x = 0; x < calendarEvents.size(); x++){
                if(!String.isBlank(calendarEvents[x].cloudCamp)){
                    String[] temp = calendarEvents[x].cloudCamp.split(';');
                    while(!temp.isEmpty()){
                        listAllFilters.add(temp[0]);
                        temp.remove(0);
                    }
                }
            }
        }
        return listAllFilters;
    }
    
    // remove duplicated
    public String[] removeDuplicated(String[] listTextField){
        String[] result = new String[0];
        Set<String> myset = new Set<String>();
        myset.addAll(listTextField);
        result.addAll(myset);
        result.sort();
        return result;
    }
    
    // remove quantity text
    public String removeQuantity(String filterWithoutQuantity){
        String[] splitString = filterWithoutQuantity.split(' \\(');
        filterWithoutQuantity = splitString[0];
        return filterWithoutQuantity;
    }
    
    // add on quantity text 
    public String buildFilterQuantity(String[] listOfFilters, String singleFilter){  
        singleFilter = removeQuantity(singleFilter);
        Integer filterQuantityValue = 0;
        for(Integer y= 0; y < listOfFilters.size(); y++){
            If(singleFilter == listOfFilters[y]) 
                filterQuantityValue++;
        }
        singleFilter += ' (' + filterQuantityValue + ')';
        return singleFilter;
    }
    
    // build SelectOptions
    public List<SelectOption> buildSelectOptions(String[] result){
        List<SelectOption> camField = new SelectOption[0];
        Integer x = 0;
        while(!result.IsEmpty()){
            camField.add(new SelectOption(string.valueof(x), result[0]));
            result.remove(0);
            x++;
        }
        return camField;
    }
    
    // get the value of the serarch box via JS
    public void getSearchValue(){
        searchBox = Apexpages.currentPage().getParameters().get('searchBox');
        runSearch(); 
    }
    
    // Functionality to add on the quartly query
    public void getDateFromJS(){
        quarter = Integer.valueOf(Apexpages.currentPage().getParameters().get('currentQuarter'));
        year = Integer.valueOf(Apexpages.currentPage().getParameters().get('currentYear'));
        runSearch(); 
    }
    
    
    public String startOfQuarterString(Integer quarter, Integer year){
        if((quarter != null) && (year != null)){
            // start of Quarter
            year--;
            if(quarterOrYear){
                return '20' + year + '-02-01';
            } else if(quarter == 1){
                return '20' + year + '-02-01';
            } else if(quarter == 2){
                return '20' + year + '-05-01';
            } else if(quarter == 3){
                return '20' + year + '-08-01';
            } else {
                return '20' + year + '-11-01';
            }
        }
        return '';
    }
    public String endOfQuarterString(Integer quarter, Integer year){ 
        if((quarter != null) && (year != null)){
            // end of Quarter
            year--;
            if(quarterOrYear){
                year++;
                return '20' + year + '-01-31';
            } else if(quarter == 1){
                return '20' + year + '-04-30';
            } else if(quarter == 2){
                return '20' + year + '-07-31';
            } else if(quarter == 3){
                return '20' + year + '-10-31';
            } else {
                year++;
                return '20' + year + '-01-31';
            }
        }
        return '';
    }
    
    // toggles the list views range from quarter<-->year
    public void toggleQuarterYear() {
        if(quarterOrYear){
            quarterOrYear = false;
        } else {
            quarterOrYear = true;
        } 
    }
    
}