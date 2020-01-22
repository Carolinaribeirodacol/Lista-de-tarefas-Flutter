import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main(){
  runApp(MaterialApp(
    home: Home(),
    ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final _toDoController = TextEditingController();

  List _toDoList = [];

  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;


  @override
  void initState() { // ctrl + o para selecionar o init state
    super.initState();

    _readData().then((data){
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  void _addToDo(){
    setState(() {
      Map <String, dynamic> newToDo = Map();
      newToDo["title"] = _toDoController.text;
      _toDoController.text = "";
      newToDo["ok"] = false; // inicializa o val da tarefa como falso porque ainda não foi concluída
      _toDoList.add(newToDo);
      _savedata();
    });
  }

  Future <Null> _refresh() async{
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a,b){
        if(a["ok"] && !b["ok"]) return 1;
        else if(!a["ok"] && b["ok"]) return -1;
        else return 0;
      });
      _savedata();
    });

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de tarefas"),
        backgroundColor: Colors.lightBlue,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _toDoController,
                    decoration: InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle: TextStyle(color: Colors.lightBlue)
                    ),
                  )
                ),
                RaisedButton(
                  color: Colors.lightBlue,
                  child: Text("ADD"),
                  textColor: Colors.white,
                  onPressed: _addToDo,
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(onRefresh: _refresh,
              child: ListView.builder( // builder é um construtor que permite ir criando a lista
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: _toDoList.length,
                  itemBuilder: buildItem),
            ),
          )
        ],
      ),
    );
  }

  Widget buildItem (context, index){
    return Dismissible( // permite arrastar os itens para apagar
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()), // saber qual item está excluindo
      // pega o tempo atual em milisegundos para saber qual está excluindo
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete_outline, color: Colors.white,),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"] ?
          Icons.check: Icons.error_outline),),
        onChanged: (c) { // chama função quando o status muda
          setState(() {
            _toDoList[index]["ok"] = c;
            _savedata();
          });
        },
      ),
      onDismissed: (direction){ // Pega o que removeu e salva
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);
          _savedata();

          final snack = SnackBar(
            content: Text("Tarefa \"${_lastRemoved["title"]}\" removida!"),
            action: SnackBarAction(label: "Desfazer", onPressed: (){
              setState(() { // utilizar sempre que for atualizar algo na tela
                _toDoList.insert(_lastRemovedPos, _lastRemoved);
                _savedata();
              });
            }),
          duration: Duration(seconds: 2),
          );
          Scaffold.of(context).removeCurrentSnackBar();    // ADICIONE ESTE COMANDO
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }


  Future<File> _getFile() async{
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/data.json');
  }

  Future<File> _savedata() async{
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async{
    try{
      final file = await _getFile();
      return file.readAsString();
    }catch(e){
      return null;
    }
  }
}

