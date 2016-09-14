## Do I feel lucky?' Well, do ya, punk?
*I know what you’re thinking: 'Did he get all of the coding rigth?' Well, to tell you the truth, in all this excitement, I’ve lost track myself.... you’ve got to ask yourself one question: 'Do I feel lucky?' Well, do you, punk?*

### What is this?
A quick and dirty tool to map tabular data (think of spreadsheets) with different column-names into a Darwin Core "event-core" structure. It takes as input a spreadsheet workbook (.xlsx) with the orginal data and in two sheets that must have a naming that starts on "event" and "occurrence", a sheet containing the mapping table called "mapping_table" describing the translation using a faul home brewed syntax, and sheet called transation_table" containing translation values (or be empty in case this is not called for in the translation_table. More explanation on the data input-formats as well as tech stuff is given below or at [DirtyHarry's git-hub site](https://github.com/andersfi/Shiny_DirtyHarry/blob/master/README.md). 

### What it is not!
This is not a data cleaning tool. Field values are parsed raw or translated, but without any sort of quality check. The input data must be clean with line one being the header line and all fields supposed to be numeric and integers containing numeric and integers values etc. If you are lucky, straight out errors in the input data will throw back errors and warning messages, or will cause the tool to happily crash. If you're not, errors are passed on to the output data and haunt mankind for eternity. Data qualiity check functionalty may be included later if we decide that this tool is remotely resembeling something usefull. 

### Input data requirements
The input data can contain input tables (a.k.a sheet in a spreadsheet workbook) that correspond to the classes "location", "event", "occurrence" and "measurement and fact". The tables must contain one or several columns that alone or together are unique and provide a linkage between the tables. The fields used for this mapping of relations between data must set to map to either "locationID", "eventID" or "occurrenceID" in the mapping table. i.e. if the input data have two tables, one describing the sampling events (e.g. gillnet efforth) and one describing occurrences (e.g. individual fish), the unique column in the sampling event (let's call it "gill_net_Nr") must be mapped to "eventID" and must exist with corresponding values also in the table constituting the occurrences. 

### Input mapping table requirements
A mapping table consist of five columns describing the term of the input data, what DwC term it should be mapped into, and possible translations and translation functions to apply. 

|source_term|destination_table|destination_term|translation_function|translation|
|---------------|--------------|----------------|-------------|-------------------|
|The column name as in the original data|The the table the data should be mapped to|The DwC term the data should be mapped to| The name of a translation function as described below. If this field is left blanc, the data are passed on raw (i.e. untransformed) to the output file| A string describing the translation function as described below|


### Translation function
|Function | Explanation |
|-------------------------------|-----------------------------------------------------------|
|| (left blanc) copies the original raw value of the column given in input_data_term into the new column given in in the column dwc_term|
|translate|Takes as input either a pipe separated list of replacements of the form ORIGINAL VALUE.1=REPLACEMENT VALUE.1&#124;ORIGINAL VALUE.2=REPLACEMENT VALUE.2, or a reference to a .csv file with replacements in tabular format. Indicate this by writing "translation_table.csv" in the tranlstion_function field. This file must consist of three columns named "destination_term" giving the name of the term mapped to, the original value and the translated value. Note, if the input consist of several variables the ORIGINAL VALUE must be given as a underscore (_) separated list of type value.column.1_value.column.2.|conditional_numeric_translation|the function "conditional_numeric_translation" takes as input a ifelse statement in R format. Note that character replacements must be in single quotes (i.e. ' instead of ") in order to make the internal R parsing to work properly - one of life's great mysteries. |
|fill_column_using| Fills all records in the new column with the text string given in translation|
|paste_values| Takes as input a column, or a pipe separated list of columns, that will be pasted into the new column. In case of multiple columns the output is a pipe separated list of values from the original columns. Additional arguments can be "prefix=SOME TEXT" or suffix=SOME TEXT" putting a fixed text string in front or back of the pasted values.| 
|generateUUID| generates and UUID to be used as ID field, based upon a column mapped to either "occurrenceID or "eventID" and unique across the respective input data tables.|
|xl_date_translate|Input values given as date formated spreadsheet cells are really only numbers (julian dates). To get this number into a data one have to assume a starting date. MS XL run on windows platform (also tested for LibreOffice Calc and gnumeric on ubuntu) assumes 1899-12-30 as the date of origin. This function simply tranform this number into a ISO formated date string. Warning - if you are on Mac rumors say that you have to readjust your dates one or two days backwards, or simply come up with a more inteligent way of handling your data (e.g. year,month,day format)|

### Input translation table requirements
A translation table consist of four columns describing the translation of data (i.e. using the "translate"" function), the usage of this is optional and are indicaded by setting translation_function field for the specific term to be translation_table. It's intended as a convinience tool where there are large lists of translation, e.g. species names or sampling protocols.   

|destination_term|source_table|orginal_value|translated_value|translation|
|---------------|--------------|----------------|-------------|-------------------|
|The column name the translation should map to|The column name the translation should map from (optional, this column does not do anything at the moment, but is good to have as a visual check)|the original|The orignal value as written in the input data| the value that the orginal value should be converted to|

### Rational
For the benefit of mankind we want data to be standardized as facilitate sharing, for the benefit of ourself we want them to be documented and structured in order to reuse them. For biodiversity data, DwC is and the DwC-Archive are commonly used standards, e.g. by [GBIF](http://www.gbif.org/%22GBIF%22). We also use that internally for projects aggregating large amount of data, such the [INVAFISH](https://osf.io/xs97g/wiki/home/%22INVAFISH%22) project. However, data are not collected in this way, for many reasons. Some of them are actually quite good - such that quickly noting down results in a messy field/lab situation requires the use of codes and abbreviations. 
