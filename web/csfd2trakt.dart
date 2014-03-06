import 'dart:html';
import 'package:csvparser/csvparser.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:utf/utf.dart';

String userName;
String passwordSHA1;

String urlOmdbapi = "http://www.omdbapi.com/";
String urlSendOtecfura = "http://www.otecfura.cz/csfd2trakt/send.php";

var csvData;
var numberOfOmdbResponses=0;
HttpRequest request;

List<FilmCSFD> dataList=new List<FilmCSFD>();
List<String> imdbList= new List<String>();
InputElement btn;

class FilmCSFD{
  String imdbID;
  String name;
  String year;
  String grade;
  String seen;
  
  Map toJson() { 
      Map map = new Map();
      map["imdbID"] = imdbID;
      map["name"] = name;
      map["year"] = year;
      map["grade"] = grade;
      map["seen"] = seen;
      return map;
    }  
}

void main() {
  btn=querySelector("#bigbutton");
  btn.onClick.listen((MouseEvent me) {
    imdbList.clear();
    //btn.disabled=true;
    getUserName();
    getSHA1Password();
    getCSVData();
    getImdbID();
  });
}

void getUserName(){
  InputElement userNameElement=querySelector("#name");
  userName=userNameElement.value;
}

void getSHA1Password(){
  InputElement passwordNameElement=querySelector("#password");
  var toEncrypt = new SHA1();
  toEncrypt.add(encodeUtf8(passwordNameElement.value));
  passwordSHA1 = CryptoUtils.bytesToHex(toEncrypt.close());
}

void getCSVData(){
  TextAreaElement dataElement=querySelector("#csvData");
  csvData=dataElement.value;
}

void getImdbID() {
  CsvParser cp = new CsvParser(csvData, seperator:";", quotemark:"\""); 
  while(cp.moveNext()){ 
    FilmCSFD oneFilm = new FilmCSFD();
    List<String> oneFilmStringList=cp.getLineAsList();
    
    oneFilm.name=oneFilmStringList.elementAt(0);
    oneFilm.year=oneFilmStringList.elementAt(2);
    
    int grade=oneFilmStringList.elementAt(3).length;
    if(grade==6){
      grade=0;
    }
    
    oneFilm.grade=grade.toString();
    oneFilm.seen=oneFilmStringList.elementAt(5);
    
    dataList.add(oneFilm);
  }
  
  for(FilmCSFD film in dataList){
    loadImdbIDFromWeb(film);
  }
}

void loadImdbIDFromWeb(FilmCSFD film) {
  String jsonData = urlOmdbapi + '?t=' + film.name + '&y=' + film.year;
  querySelector("#testText").text=jsonData;
  var request = HttpRequest.getString(jsonData).then(onDataLoaded);
}

void onDataLoaded(String responseText) {
  Map parsedMap = JSON.decode(responseText);
  String imdbIdString = parsedMap["imdbID"];
  querySelector("#testText").text=imdbIdString;
  imdbList.add(imdbIdString);
  print(imdbList);
  if(dataList.length-1==numberOfOmdbResponses){
    numberOfOmdbResponses=0;
    saveImdbIdToList();
    saveDataToTrakt();
  }else{
    numberOfOmdbResponses++;
  }
}

void saveImdbIdToList(){
  for(int i=0; i<imdbList.length; i++){
    dataList[i].imdbID=imdbList[i];
  }
}

void saveDataToTrakt() {
  request = new HttpRequest();
  
  var mapData = new Map();
  mapData["username"] = userName;
  mapData["password"] = passwordSHA1;
  mapData["movies"] = dataList;
    
  
  var encodedData = JSON.encode(mapData);
  request.onReadyStateChange.listen(onData);
  request.open("POST", urlSendOtecfura, async:false);
  request.send(encodedData);
}

void onData(_) {
  querySelector("#testText").text=request.responseText;
}